import { describe, expect, it } from "vitest";
import { formatSource } from "../src/formatter";

describe("KonadoScript formatter", () => {
	it("normalizes structural indentation", () => {
		const source = [
			"branch intro",
			"actor show Kona normal at 3",
			"if %love == 0:",
			'"Kona" "Hello"',
			"else:",
			'"Kona" "Again"',
			"endif",
		].join("\n");

		expect(formatSource(source, "\t")).toBe(
			[
				"branch intro",
				"\tactor show Kona normal at 3",
				"\tif %love == 0:",
				'\t\t"Kona" "Hello"',
				"\telse:",
				'\t\t"Kona" "Again"',
				"\tendif",
			].join("\n"),
		);
	});

	it("preserves dialogue and comments verbatim", () => {
		const source = '  "Kona"   "a # b \\\\"quoted\\\\"" voice_01  # note';

		expect(formatSource(source, "\t")).toContain(
			'"Kona"   "a # b \\\\"quoted\\\\"" voice_01',
		);
		expect(formatSource(source, "\t")).toContain("# note");
	});

	it("formats a screen-text closing line with a stable ID", () => {
		const source = 'screentext {\n"Opening"\n} [id=opening]';

		expect(formatSource(source, "\t")).toBe(
			'screentext {\n\t"Opening"\n} [id=opening]',
		);
	});

	it("keeps choice filters while normalizing spacing", () => {
		const source = 'choice   "Gift"   ->  gift  if  %love  >=  5  once';

		expect(formatSource(source, "\t")).toBe(
			'choice "Gift" -> gift if %love >= 5 once',
		);
	});
});
