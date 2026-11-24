import { readdirSync, readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";
import {
	analyzeDocument,
	editDistance,
	extractReferences,
	referencesForLine,
	tokenizeLine,
} from "../src/language";

describe("KonadoScript tokenizer", () => {
	it("keeps comments inside strings and strips actual comments", () => {
		const tokens = tokenizeLine('"Kona" "value #1" voice_01 # comment');

		expect(tokens.map((token) => token.text)).toEqual([
			"Kona",
			"value #1",
			"voice_01",
		]);
	});

	it("reports whether a quoted token is closed", () => {
		expect(tokenizeLine('"closed"')[0]?.closed).toBe(true);
		expect(tokenizeLine('"open')[0]?.closed).toBe(false);
	});
});

describe("KonadoScript semantic references", () => {
	it("does not classify screen text as an actor", () => {
		expect(referencesForLine('    "Full-screen text"', 2, true)).toEqual(
			[],
		);
	});

	it("extracts variables embedded in dialogue strings", () => {
		const references = extractReferences(
			'"Kona" "Round=$round, reward=$bonus and love=%love"',
		);

		expect(
			references
				.filter((reference) => reference.kind === "variables")
				.map((reference) => reference.name),
		).toEqual(["$round", "$bonus", "%love"]);
	});

	it("distinguishes actors, speaker variables, and interpolated labels", () => {
		const references = extractReferences(
			[
				'Kona "Static"',
				'$speaker "Dynamic"',
				'"Guest $index" "Label"',
			].join("\n"),
		);

		expect(references).toEqual(
			expect.arrayContaining([
				expect.objectContaining({ kind: "actors", name: "Kona" }),
				expect.objectContaining({
					kind: "variables",
					name: "$speaker",
				}),
				expect.objectContaining({ kind: "variables", name: "$index" }),
			]),
		);
		expect(
			references.some(
				(reference) =>
					reference.kind === "actors" &&
					reference.name === "Guest $index",
			),
		).toBe(false);
	});

	it("does not treat named dialogue parameters as voice resources", () => {
		const parameterOnly = extractReferences(
			'Kona "Hello" [speed=2.0] [id=intro]',
		);
		const withVoice = extractReferences(
			'Kona "Hello" voice_01 [speed = 2.0]',
		);

		expect(
			parameterOnly.some((reference) => reference.kind === "voices"),
		).toBe(false);
		expect(withVoice).toEqual(
			expect.arrayContaining([
				expect.objectContaining({ kind: "voices", name: "voice_01" }),
			]),
		);
	});

	it("extracts actor state scope and branch roles", () => {
		const references = extractReferences(
			[
				"actor show Kona normal at 3",
				'choice "Continue" -> next',
				"branch next",
			].join("\n"),
		);

		expect(references).toEqual(
			expect.arrayContaining([
				expect.objectContaining({ kind: "actors", name: "Kona" }),
				expect.objectContaining({
					kind: "states",
					name: "normal",
					scopeName: "Kona",
				}),
				expect.objectContaining({
					kind: "branches",
					name: "next",
					role: "reference",
				}),
				expect.objectContaining({
					kind: "branches",
					name: "next",
					role: "definition",
				}),
			]),
		);
	});

	it("classifies call targets as branch references", () => {
		const references = extractReferences(
			["call shared_scene", "branch shared_scene"].join("\n"),
		);

		expect(references).toEqual(
			expect.arrayContaining([
				expect.objectContaining({
					kind: "branches",
					name: "shared_scene",
					role: "reference",
				}),
				expect.objectContaining({
					kind: "branches",
					name: "shared_scene",
					role: "definition",
				}),
			]),
		);
	});
});

describe("KonadoScript diagnostics", () => {
	it("accepts every bundled sample script", () => {
		const sampleRoot = resolve(process.cwd(), "../../sample");
		const scripts = readdirSync(sampleRoot, {
			recursive: true,
			withFileTypes: true,
		}).filter((entry) => entry.isFile() && entry.name.endsWith(".ks"));

		const failures = scripts.flatMap((entry) => {
			const filePath = `${entry.parentPath}/${entry.name}`;
			return analyzeDocument(readFileSync(filePath, "utf8"))
				.filter((diagnostic) => diagnostic.severity === "error")
				.map(
					(diagnostic) =>
						`${filePath}:${diagnostic.line + 1} ${diagnostic.message}`,
				);
		});

		expect(failures).toEqual([]);
	});

	it("accepts representative valid syntax", () => {
		const source = [
			"screentext {",
			'\t"Full-screen text with $score"',
			"} [id=opening]",
			"background bg_end fade",
			"actor show Kona normal at 3",
			'Kona "Hello, %player_name!" voice_01 [speed=1.25] [id=intro]',
			'Kona "Parameter only" [interval = 0.02]',
			'$speaker "Selected dynamically"',
			'"Guest $round" "Text label with interpolation"',
			"if %love == 0:",
			'\t"Kona" "Hello"',
			"else:",
			'\t"Kona" "Again"',
			"endif",
			'choice "Leave" -> exit_choice',
			"branch exit_choice",
			"\tend",
		].join("\n");

		expect(analyzeDocument(source)).toEqual([]);
	});

	it("validates KonadoScript 2.8 named parameters", () => {
		const valid = [
			"screentext {",
			'\t"Opening"',
			"} [id=opening]",
			'Kona "Fast dialogue" [speed=1.5] [id=intro_line]',
			"actor show Kona normal at 3 [duration=0.25]",
			"background bg_end fade [duration=0]",
			"if %love == 1 [id=ending_check]:",
			"\tend",
			"endif",
		].join("\n");
		expect(analyzeDocument(valid)).toEqual([]);

		const invalid = analyzeDocument(
			[
				"screentext {",
				'\t"Opening"',
				"} [speed=2]",
				'Kona "Conflict" [speed=1.0] [interval=0.03]',
				"actor show Kona normal at 3 [speed=2]",
				"background bg_end fade [duration=-1]",
				"end [id=not valid]",
				'choice "First" -> first [id=choice_group]',
				'choice "Second" -> second [id=choice_group]',
				"branch first",
				"\tend",
				"branch second",
				"\tend",
			].join("\n"),
		);
		const codes = invalid.map((diagnostic) => diagnostic.code);
		expect(codes).toContain("syntax.named_parameter_conflict");
		expect(codes).toContain("syntax.named_parameter_unknown");
		expect(codes).toContain("syntax.named_parameter_range");
		expect(codes).toContain("syntax.named_parameter");
		expect(codes).toContain("syntax.choice_group_parameter");
		expect(codes).toContain("semantic.duplicate_instruction_id");
	});

	it("accepts subroutines and choice filters", () => {
		const source = [
			"call shared_scene",
			'choice "Gift" -> gift if %love >= 5',
			'choice "Rumor" -> rumor once',
			'choice "Secret" -> secret once if %love == 10',
			"return",
			"",
			"branch shared_scene",
			"\treturn",
			"branch gift",
			"\tend",
			"branch rumor",
			"\tend",
			"branch secret",
			"\tend",
		].join("\n");

		expect(analyzeDocument(source)).toEqual([]);
	});

	it("rejects malformed call and choice filters", () => {
		const codes = analyzeDocument(
			[
				"call",
				"return extra",
				'choice "Gift" -> gift if',
				'choice "Rumor" -> rumor once once',
				'choice "Secret" -> secret if %love >= 1 if %love == 2',
			].join("\n"),
		).map((diagnostic) => diagnostic.code);

		expect(codes).toContain("syntax.arguments");
		expect(codes).toContain("syntax.return");
		expect(codes).toContain("syntax.choice_condition");
		expect(codes).toContain("syntax.choice_once");
	});

	it("offers ranked fixes for misspelled commands", () => {
		const diagnostics = analyzeDocument("endif_typo");

		expect(diagnostics[0]).toMatchObject({
			code: "syntax.unrecognized",
			severity: "error",
		});
		expect(diagnostics[0]?.fixes?.length).toBeLessThanOrEqual(3);
	});

	it("detects missing conditional and screen-text terminators", () => {
		const diagnostics = analyzeDocument(
			'if %love == 0:\n\tscreentext {\n\t\t"Text"',
		);
		const codes = diagnostics.map((diagnostic) => diagnostic.code);

		expect(codes).toContain("syntax.if_missing_endif");
		expect(codes).toContain("syntax.screentext_missing_close");
	});

	it("offers a branch creation fix", () => {
		const diagnostic = analyzeDocument('choice "Continue" -> missing').find(
			(item) => item.code === "semantic.missing_branch",
		);

		expect(diagnostic?.fixes?.[0]?.edits[0]?.newText).toContain(
			"branch missing",
		);
	});
});

describe("edit distance", () => {
	it("ranks nearby command spellings", () => {
		expect(editDistance("bakground", "background")).toBe(1);
	});
});
