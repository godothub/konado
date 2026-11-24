import {
	BACKGROUND_EFFECTS,
	CAMERA_TRANSITIONS,
	CONTEXT_KEYWORDS,
	ROOT_KEYWORDS,
	commandKey,
	namedParametersForCommand,
} from "./catalog";

export interface Token {
	text: string;
	start: number;
	end: number;
	quoted: boolean;
	closed: boolean;
}

export type SymbolKind =
	| "actors"
	| "states"
	| "motions"
	| "backgrounds"
	| "bgms"
	| "sfx"
	| "voices"
	| "cameras"
	| "branches"
	| "variables"
	| "signals"
	| "achievements"
	| "scripts";

export interface SymbolReference {
	kind: SymbolKind;
	name: string;
	line: number;
	start: number;
	end: number;
	role: "definition" | "reference";
	scopeName?: string;
	optional?: boolean;
}

export interface TextEditSpec {
	line: number;
	start: number;
	end: number;
	newText: string;
}

export interface QuickFixSpec {
	title: string;
	titleZh: string;
	edits: TextEditSpec[];
	preferred?: boolean;
}

export interface DiagnosticSpec {
	code: string;
	severity: "error" | "warning";
	line: number;
	start: number;
	end: number;
	message: string;
	messageZh: string;
	fixes?: QuickFixSpec[];
}

export interface IndexedDefinition {
	kind: SymbolKind;
	name: string;
	uri: string;
	line: number;
	start: number;
	end: number;
	targetUri?: string;
	scopeName?: string;
}

export interface ProjectSnapshot {
	definitions(kind: SymbolKind, name?: string): readonly IndexedDefinition[];
	values(kind: SymbolKind, scopeName?: string): readonly string[];
	hasUri(uri: string): boolean;
}

interface NamedParameter {
	name: string;
	value: string;
	start: number;
	end: number;
}

interface ParsedStatementParameters {
	base: string;
	parameters: NamedParameter[];
	malformedStart?: number;
}

const IDENTIFIER = /^[\p{L}_][\p{L}\p{N}_-]*$/u;
const VARIABLE = /^[%$][\p{L}_][\p{L}\p{N}_-]*$/u;
const NUMBER = /^[-+]?(?:\d+(?:\.\d+)?|\.\d+)$/;
const INTEGER = /^[-+]?\d+$/;
const COMPARISON = /^(?:==|!=|>=|<=|>|<)$/;
const RES_PATH = /^res:\/\/\S+\.ks$/;

const ROOT_SET = new Set<string>(ROOT_KEYWORDS);
const ACTOR_ACTIONS = new Set<string>(CONTEXT_KEYWORDS.actor);
const AUDIO_TYPES = new Set<string>(CONTEXT_KEYWORDS.play);
const CAMERA_ACTIONS = new Set<string>(CONTEXT_KEYWORDS.cam);
const ASYNC_CAMERA_ACTIONS = new Set<string>(CONTEXT_KEYWORDS.asyncam);
const ACHIEVEMENT_ACTIONS = new Set<string>(CONTEXT_KEYWORDS.achievement);
const EFFECTS = new Set<string>(BACKGROUND_EFFECTS);
const TRANSITIONS = new Set<string>(CAMERA_TRANSITIONS);

export function splitCodeAndComment(line: string): {
	code: string;
	comment: string;
	commentStart: number;
} {
	let quoted = false;
	let escaped = false;
	for (let index = 0; index < line.length; index += 1) {
		const character = line[index];
		if (escaped) {
			escaped = false;
			continue;
		}
		if (character === "\\" && quoted) {
			escaped = true;
			continue;
		}
		if (character === '"') {
			quoted = !quoted;
			continue;
		}
		if (character === "#" && !quoted) {
			return {
				code: line.slice(0, index),
				comment: line.slice(index),
				commentStart: index,
			};
		}
	}
	return { code: line, comment: "", commentStart: line.length };
}

export function tokenizeLine(line: string): Token[] {
	const { code } = splitCodeAndComment(line);
	const tokens: Token[] = [];
	let index = 0;
	while (index < code.length) {
		if (/\s/u.test(code[index] ?? "")) {
			index += 1;
			continue;
		}
		const start = index;
		if (code[index] === '"') {
			index += 1;
			let escaped = false;
			let closed = false;
			while (index < code.length) {
				const character = code[index];
				if (escaped) {
					escaped = false;
				} else if (character === "\\") {
					escaped = true;
				} else if (character === '"') {
					index += 1;
					closed = true;
					break;
				}
				index += 1;
			}
			tokens.push({
				text: code.slice(start + 1, closed ? index - 1 : index),
				start,
				end: index,
				quoted: true,
				closed,
			});
			continue;
		}
		if (code.startsWith("->", index)) {
			tokens.push({
				text: "->",
				start,
				end: index + 2,
				quoted: false,
				closed: true,
			});
			index += 2;
			continue;
		}
		while (index < code.length && !/\s/u.test(code[index] ?? "")) {
			if (code.startsWith("->", index)) {
				break;
			}
			index += 1;
		}
		tokens.push({
			text: code.slice(start, index),
			start,
			end: index,
			quoted: false,
			closed: true,
		});
	}
	return tokens;
}

function reference(
	tokens: readonly Token[],
	tokenIndex: number,
	kind: SymbolKind,
	line: number,
	role: SymbolReference["role"] = "reference",
	scopeName?: string,
): SymbolReference | undefined {
	const token = tokens[tokenIndex];
	if (!token || token.text.length === 0) {
		return undefined;
	}
	return {
		kind,
		name: token.text,
		line,
		start: token.start + (token.quoted ? 1 : 0),
		end: token.end - (token.quoted && token.closed ? 1 : 0),
		role,
		scopeName,
	};
}

function variablesInLine(line: string, lineNumber: number): SymbolReference[] {
	const results: SymbolReference[] = [];
	const { code } = splitCodeAndComment(line);
	for (const match of code.matchAll(/[%$][\p{L}_][\p{L}\p{N}_-]*/gu)) {
		const start = match.index;
		const name = match[0];
		results.push({
			kind: "variables",
			name,
			line: lineNumber,
			start,
			end: start + name.length,
			role: /^(?:\s*)(?:set|add|sub|mul|div)\s/u.test(code)
				? "definition"
				: "reference",
		});
	}
	return results;
}

export function referencesForLine(
	line: string,
	lineNumber: number,
	insideScreenText = false,
): SymbolReference[] {
	const tokens = tokenizeLine(line);
	const results = variablesInLine(line, lineNumber);
	const root = tokens[0]?.text.replace(/:$/u, "");
	if (!root || insideScreenText) {
		return results;
	}
	const add = (value: SymbolReference | undefined): void => {
		if (value) {
			results.push(value);
		}
	};
	switch (root) {
		case "branch":
			add(reference(tokens, 1, "branches", lineNumber, "definition"));
			break;
		case "choice":
			add(reference(tokens, 3, "branches", lineNumber));
			break;
		case "jump_branch":
			add(reference(tokens, 1, "branches", lineNumber));
			break;
		case "call":
			add(reference(tokens, 1, "branches", lineNumber));
			break;
		case "jump":
			add(reference(tokens, 1, "scripts", lineNumber));
			break;
		case "background":
			add(reference(tokens, 1, "backgrounds", lineNumber));
			break;
		case "play":
			if (tokens[1]?.text === "bgm") {
				add(reference(tokens, 2, "bgms", lineNumber));
			} else if (tokens[1]?.text === "sfx") {
				add(reference(tokens, 2, "sfx", lineNumber));
			}
			break;
		case "actor": {
			const actorName = tokens[2]?.text;
			add(reference(tokens, 2, "actors", lineNumber));
			if (tokens[1]?.text === "show" || tokens[1]?.text === "change") {
				add(
					reference(
						tokens,
						3,
						"states",
						lineNumber,
						"reference",
						actorName,
					),
				);
			} else if (tokens[1]?.text === "motion") {
				add(
					reference(
						tokens,
						3,
						"motions",
						lineNumber,
						"reference",
						actorName,
					),
				);
			}
			break;
		}
		case "cam":
		case "asyncam":
			if (tokens[1]?.text === "move") {
				add(reference(tokens, 2, "cameras", lineNumber));
			}
			break;
		case "signal":
			add(reference(tokens, 1, "signals", lineNumber, "definition"));
			break;
		case "waitsignal":
			add(reference(tokens, 1, "signals", lineNumber));
			break;
		case "achievement":
			add(reference(tokens, 2, "achievements", lineNumber, "definition"));
			break;
		default:
			if (isDialogueTokens(tokens)) {
				if (!VARIABLE.test(tokens[0]?.text ?? "")) {
					const quotedSpeaker = tokens[0]?.quoted === true;
					const interpolatedSpeaker =
						quotedSpeaker &&
						/[%$][\p{L}_][\p{L}\p{N}_-]*/u.test(
							tokens[0]?.text ?? "",
						);
					const speaker = interpolatedSpeaker
						? undefined
						: reference(tokens, 0, "actors", lineNumber);
					if (speaker && quotedSpeaker) {
						speaker.optional = true;
					}
					add(speaker);
				}
				if (hasDialogueVoiceToken(tokens)) {
					add(reference(tokens, 2, "voices", lineNumber));
				}
			}
	}
	return deduplicateReferences(results);
}

function isDialogueTokens(tokens: readonly Token[]): boolean {
	if (tokens.length < 2 || !tokens[1]?.quoted) {
		return false;
	}
	const first = tokens[0];
	return Boolean(
		first?.quoted ||
		VARIABLE.test(first?.text ?? "") ||
		!ROOT_SET.has(first?.text ?? ""),
	);
}

function hasDialogueVoiceToken(tokens: readonly Token[]): boolean {
	return tokens.length >= 3 && !tokens[2]?.text.startsWith("[");
}

function firstUnquotedBracket(content: string): number {
	let quoted = false;
	let escaped = false;
	for (let index = 0; index < content.length; index += 1) {
		const character = content[index];
		if (escaped) {
			escaped = false;
			continue;
		}
		if (quoted && character === "\\") {
			escaped = true;
			continue;
		}
		if (character === '"') {
			quoted = !quoted;
			continue;
		}
		if (!quoted && character === "[") {
			return index;
		}
	}
	return -1;
}

function parseStatementParameters(content: string): ParsedStatementParameters {
	const parameterStart = firstUnquotedBracket(content);
	if (parameterStart < 0) {
		return { base: content, parameters: [] };
	}
	const parameters: NamedParameter[] = [];
	const suffix = content.slice(parameterStart);
	const pattern =
		/\s*\[\s*([\p{L}_][\p{L}\p{N}_-]*)\s*=\s*([^\s\[\]]+)\s*\]/uy;
	let offset = 0;
	while (offset < suffix.length) {
		pattern.lastIndex = offset;
		const match = pattern.exec(suffix);
		if (!match) {
			if (/^\s*$/u.test(suffix.slice(offset))) {
				break;
			}
			if (
				parameters.length > 0 &&
				/^\s*:\s*$/u.test(suffix.slice(offset))
			) {
				return {
					base: `${content.slice(0, parameterStart).trimEnd()}:`,
					parameters,
				};
			}
			return {
				base: content.slice(0, parameterStart).trimEnd(),
				parameters,
				malformedStart: parameterStart + offset,
			};
		}
		const whole = match[0];
		const leadingWhitespace = whole.length - whole.trimStart().length;
		parameters.push({
			name: match[1] ?? "",
			value: match[2] ?? "",
			start: parameterStart + offset + leadingWhitespace,
			end: parameterStart + pattern.lastIndex,
		});
		offset = pattern.lastIndex;
	}
	return {
		base: content.slice(0, parameterStart).trimEnd(),
		parameters,
	};
}

function statementCommand(tokens: readonly Token[]): string {
	if (isDialogueTokens(tokens)) {
		return "dialogue";
	}
	return commandKey(tokens.map((token) => token.text));
}

function validateNamedParameters(
	line: number,
	tokens: readonly Token[],
	parsed: ParsedStatementParameters,
	diagnostics: DiagnosticSpec[],
	commandOverride?: string,
): void {
	if (parsed.malformedStart !== undefined) {
		diagnostics.push({
			code: "syntax.named_parameter",
			severity: "error",
			line,
			start: parsed.malformedStart,
			end: Math.max(parsed.malformedStart + 1, parsed.base.length),
			message:
				"Expected a trailing named parameter in the form [name=value].",
			messageZh: "命名参数应位于语句末尾并写成 [名称=值]。",
		});
		return;
	}
	if (parsed.parameters.length === 0) {
		return;
	}
	const command = commandOverride ?? statementCommand(tokens);
	const allowed = namedParametersForCommand(command);
	const seen = new Set<string>();
	for (const parameter of parsed.parameters) {
		if (seen.has(parameter.name)) {
			diagnostics.push({
				code: "syntax.named_parameter_duplicate",
				severity: "error",
				line,
				start: parameter.start,
				end: parameter.end,
				message: `Named parameter '${parameter.name}' is duplicated.`,
				messageZh: `命名参数“${parameter.name}”重复。`,
			});
			continue;
		}
		seen.add(parameter.name);
		const definition = allowed[parameter.name];
		if (!definition) {
			diagnostics.push({
				code: "syntax.named_parameter_unknown",
				severity: "error",
				line,
				start: parameter.start,
				end: parameter.end,
				message: `Named parameter '${parameter.name}' is not valid for this statement.`,
				messageZh: `命名参数“${parameter.name}”不适用于当前语句。`,
			});
			continue;
		}
		if (
			definition.type === "identifier" &&
			!IDENTIFIER.test(parameter.value)
		) {
			diagnostics.push({
				code: "syntax.named_parameter_value",
				severity: "error",
				line,
				start: parameter.start,
				end: parameter.end,
				message: `Named parameter '${parameter.name}' requires an identifier.`,
				messageZh: `命名参数“${parameter.name}”必须使用有效标识符。`,
			});
			continue;
		}
		if (definition.type === "number") {
			if (!NUMBER.test(parameter.value)) {
				diagnostics.push({
					code: "syntax.named_parameter_value",
					severity: "error",
					line,
					start: parameter.start,
					end: parameter.end,
					message: `Named parameter '${parameter.name}' requires a number.`,
					messageZh: `命名参数“${parameter.name}”必须是数字。`,
				});
				continue;
			}
			const value = Number(parameter.value);
			if (
				definition.minimum !== undefined &&
				value < definition.minimum
			) {
				diagnostics.push({
					code: "syntax.named_parameter_range",
					severity: "error",
					line,
					start: parameter.start,
					end: parameter.end,
					message: `Named parameter '${parameter.name}' cannot be less than ${definition.minimum}.`,
					messageZh: `命名参数“${parameter.name}”不能小于 ${definition.minimum}。`,
				});
			}
			if (
				definition.exclusiveMinimum !== undefined &&
				value <= definition.exclusiveMinimum
			) {
				diagnostics.push({
					code: "syntax.named_parameter_range",
					severity: "error",
					line,
					start: parameter.start,
					end: parameter.end,
					message: `Named parameter '${parameter.name}' must be greater than ${definition.exclusiveMinimum}.`,
					messageZh: `命名参数“${parameter.name}”必须大于 ${definition.exclusiveMinimum}。`,
				});
			}
		}
	}
	if (seen.has("speed") && seen.has("interval")) {
		const parameter = parsed.parameters.find(
			(item) => item.name === "interval",
		);
		if (parameter) {
			diagnostics.push({
				code: "syntax.named_parameter_conflict",
				severity: "error",
				line,
				start: parameter.start,
				end: parameter.end,
				message:
					"Dialogue parameters 'speed' and 'interval' cannot be used together.",
				messageZh: "对话参数“speed”和“interval”不能同时设置。",
			});
		}
	}
	if (
		seen.has("duration") &&
		["cam", "asyncam"].includes(tokens[0]?.text ?? "")
	) {
		const action = tokens[1]?.text;
		const positionalIndex =
			action === "move" ? 4 : action === "reset" ? 3 : 2;
		const positional = tokens[positionalIndex];
		if (
			positional &&
			NUMBER.test(positional.text) &&
			Number(positional.text) > 0
		) {
			const parameter = parsed.parameters.find(
				(item) => item.name === "duration",
			);
			if (parameter) {
				diagnostics.push({
					code: "syntax.named_parameter_conflict",
					severity: "error",
					line,
					start: parameter.start,
					end: parameter.end,
					message:
						"Camera duration cannot be set both positionally and by [duration=...].",
					messageZh:
						"镜头时长不能同时使用位置参数和 [duration=...] 设置。",
				});
			}
		}
	}
}

export function extractReferences(source: string): SymbolReference[] {
	const results: SymbolReference[] = [];
	let insideScreenText = false;
	source.split(/\r?\n/u).forEach((line, lineNumber) => {
		const tokens = tokenizeLine(line);
		const content = splitCodeAndComment(line).code.trim();
		results.push(...referencesForLine(line, lineNumber, insideScreenText));
		if (
			!insideScreenText &&
			tokens[0]?.text === "screentext" &&
			content.endsWith("{")
		) {
			insideScreenText = true;
		} else if (insideScreenText && tokens[0]?.text === "}") {
			insideScreenText = false;
		}
	});
	return results;
}

function deduplicateReferences(
	references: SymbolReference[],
): SymbolReference[] {
	const seen = new Set<string>();
	return references.filter((item) => {
		const key = `${item.kind}:${item.line}:${item.start}:${item.end}`;
		if (seen.has(key)) {
			return false;
		}
		seen.add(key);
		return true;
	});
}

function diagnostic(
	line: number,
	token: Token | undefined,
	code: string,
	message: string,
	messageZh: string,
	fixes?: QuickFixSpec[],
): DiagnosticSpec {
	return {
		code,
		severity: "error",
		line,
		start: token?.start ?? 0,
		end: Math.max(token?.end ?? 1, (token?.start ?? 0) + 1),
		message,
		messageZh,
		fixes,
	};
}

function replaceTokenFix(
	line: number,
	token: Token,
	replacement: string,
	title: string,
	titleZh: string,
): QuickFixSpec {
	return {
		title,
		titleZh,
		preferred: true,
		edits: [
			{ line, start: token.start, end: token.end, newText: replacement },
		],
	};
}

function closestValues(
	value: string,
	candidates: readonly string[],
	maximum = 3,
): string[] {
	return [...candidates]
		.map((candidate) => ({
			candidate,
			distance: editDistance(value, candidate),
		}))
		.filter(
			({ distance }) =>
				distance <= Math.max(2, Math.floor(value.length / 2)),
		)
		.sort(
			(left, right) =>
				left.distance - right.distance ||
				left.candidate.localeCompare(right.candidate),
		)
		.slice(0, maximum)
		.map(({ candidate }) => candidate);
}

export function editDistance(left: string, right: string): number {
	const previous = Array.from(
		{ length: right.length + 1 },
		(_, index) => index,
	);
	for (let leftIndex = 1; leftIndex <= left.length; leftIndex += 1) {
		const current = [leftIndex];
		for (let rightIndex = 1; rightIndex <= right.length; rightIndex += 1) {
			current[rightIndex] = Math.min(
				(current[rightIndex - 1] ?? 0) + 1,
				(previous[rightIndex] ?? 0) + 1,
				(previous[rightIndex - 1] ?? 0) +
					(left[leftIndex - 1] === right[rightIndex - 1] ? 0 : 1),
			);
		}
		previous.splice(0, previous.length, ...current);
	}
	return previous[right.length] ?? 0;
}

function requireCount(
	diagnostics: DiagnosticSpec[],
	line: number,
	tokens: readonly Token[],
	expected: number,
	signature: string,
): boolean {
	if (tokens.length === expected) {
		return true;
	}
	const token = tokens[Math.min(tokens.length - 1, expected)] ?? tokens[0];
	diagnostics.push(
		diagnostic(
			line,
			token,
			"syntax.arguments",
			`Expected: ${signature}`,
			`应为：${signature}`,
		),
	);
	return false;
}

function validateCommand(
	line: number,
	content: string,
	tokens: readonly Token[],
	diagnostics: DiagnosticSpec[],
): void {
	const root = tokens[0]?.text.replace(/:$/u, "") ?? "";
	if (!ROOT_SET.has(root)) {
		const token = tokens[0];
		const fixes = token
			? closestValues(root, ROOT_KEYWORDS).map((candidate) =>
					replaceTokenFix(
						line,
						token,
						candidate,
						`Replace with '${candidate}'`,
						`替换为“${candidate}”`,
					),
				)
			: undefined;
		diagnostics.push(
			diagnostic(
				line,
				token,
				"syntax.unrecognized",
				`Unrecognized syntax: ${root}`,
				`无法识别的语法：${root}`,
				fixes,
			),
		);
		return;
	}

	switch (root) {
		case "screentext":
			if (tokens.length !== 2 || tokens[1]?.text !== "{") {
				diagnostics.push(
					diagnostic(
						line,
						tokens[1] ?? tokens[0],
						"syntax.screentext_open",
						"A screen-text block must start with 'screentext {'.",
						"全屏文本块必须以“screentext {”开始。",
					),
				);
			}
			break;
		case "showtextbox":
		case "hidetextbox":
			if (
				tokens.length > 2 ||
				(tokens[1] && !NUMBER.test(tokens[1].text))
			) {
				diagnostics.push(
					diagnostic(
						line,
						tokens[1] ?? tokens[0],
						"syntax.duration",
						`${root} accepts one optional non-negative duration.`,
						`${root} 只接受一个可选的非负动画时长。`,
					),
				);
			} else if (tokens[1] && Number(tokens[1].text) < 0) {
				diagnostics.push(
					diagnostic(
						line,
						tokens[1],
						"syntax.duration",
						"Duration cannot be negative.",
						"动画时长不能为负数。",
					),
				);
			}
			break;
		case "waitsignal":
		case "signal":
		case "jump_branch":
		case "call":
		case "branch":
			requireCount(diagnostics, line, tokens, 2, `${root} <name>`);
			break;
		case "jump":
			if (
				requireCount(
					diagnostics,
					line,
					tokens,
					2,
					"jump <res://path/to/script.ks>",
				)
			) {
				const path = tokens[1];
				if (path && !RES_PATH.test(path.text)) {
					diagnostics.push(
						diagnostic(
							line,
							path,
							"syntax.jump_path",
							"Jump target must be an exported res:// KonadoScript path.",
							"跳转目标必须是会被导出的 res:// KonadoScript 路径。",
						),
					);
				}
			}
			break;
		case "background":
			if (tokens.length < 2 || tokens.length > 3) {
				requireCount(
					diagnostics,
					line,
					tokens,
					2,
					"background <background_name> [transition]",
				);
			} else if (tokens[2] && !EFFECTS.has(tokens[2].text)) {
				const token = tokens[2];
				diagnostics.push(
					diagnostic(
						line,
						token,
						"syntax.background_effect",
						`Unknown background transition '${token.text}'.`,
						`未知的背景转场“${token.text}”。`,
						closestValues(token.text, BACKGROUND_EFFECTS).map(
							(candidate) =>
								replaceTokenFix(
									line,
									token,
									candidate,
									`Replace with '${candidate}'`,
									`替换为“${candidate}”`,
								),
						),
					),
				);
			}
			break;
		case "actor":
			validateActor(line, tokens, diagnostics);
			break;
		case "play":
			if (
				!requireCount(
					diagnostics,
					line,
					tokens,
					3,
					"play <bgm|sfx> <resource_name>",
				)
			) {
				break;
			}
			if (tokens[1] && !AUDIO_TYPES.has(tokens[1].text)) {
				diagnostics.push(
					diagnostic(
						line,
						tokens[1],
						"syntax.audio_type",
						"Audio type must be 'bgm' or 'sfx'.",
						"音频类型必须为“bgm”或“sfx”。",
					),
				);
			}
			break;
		case "stop":
			if (tokens.length > 2 || (tokens[1] && tokens[1].text !== "bgm")) {
				diagnostics.push(
					diagnostic(
						line,
						tokens[1],
						"syntax.stop",
						"Expected: stop bgm",
						"应为：stop bgm",
					),
				);
			}
			break;
		case "choice":
			validateChoice(line, tokens, diagnostics);
			break;
		case "if":
			validateIf(line, content, tokens, diagnostics);
			break;
		case "else":
			if (content !== "else:") {
				diagnostics.push(
					diagnostic(
						line,
						tokens[0],
						"syntax.else",
						"Expected: else:",
						"应为：else:",
						[
							{
								title: "Replace with 'else:'",
								titleZh: "替换为“else:”",
								preferred: true,
								edits: [
									{
										line,
										start: 0,
										end: content.length,
										newText: "else:",
									},
								],
							},
						],
					),
				);
			}
			break;
		case "endif":
		case "end":
		case "return":
			if (tokens.length !== 1) {
				diagnostics.push(
					diagnostic(
						line,
						tokens[1],
						`syntax.${root}`,
						`Expected: ${root}`,
						`应为：${root}`,
						[
							{
								title: `Replace with '${root}'`,
								titleZh: `替换为“${root}”`,
								preferred: true,
								edits: [
									{
										line,
										start: 0,
										end: content.length,
										newText: root,
									},
								],
							},
						],
					),
				);
			}
			break;
		case "set":
			if (
				tokens.length < 3 ||
				tokens.length > 4 ||
				!VARIABLE.test(tokens[1]?.text ?? "") ||
				(tokens.length === 4 && tokens[2]?.text !== "=")
			) {
				diagnostics.push(
					diagnostic(
						line,
						tokens[1] ?? tokens[0],
						"syntax.variable",
						"Expected: set <%variable|$variable> [=] <value>",
						"应为：set <%变量|$变量> [=] <值>",
					),
				);
			}
			break;
		case "add":
		case "sub":
		case "mul":
		case "div":
			if (
				!requireCount(
					diagnostics,
					line,
					tokens,
					3,
					`${root} <%variable|$variable> <value>`,
				)
			) {
				break;
			}
			if (!VARIABLE.test(tokens[1]?.text ?? "")) {
				diagnostics.push(
					diagnostic(
						line,
						tokens[1],
						"syntax.variable",
						"A variable must begin with '%' or '$'.",
						"变量必须以“%”或“$”开头。",
					),
				);
			}
			break;
		case "achievement":
			validateAchievement(line, tokens, diagnostics);
			break;
		case "cam":
		case "asyncam":
			validateCamera(line, tokens, diagnostics);
			break;
	}
}

function validateActor(
	line: number,
	tokens: readonly Token[],
	diagnostics: DiagnosticSpec[],
): void {
	const action = tokens[1];
	if (!action || !ACTOR_ACTIONS.has(action.text)) {
		const fixes = action
			? closestValues(action.text, CONTEXT_KEYWORDS.actor).map(
					(candidate) =>
						replaceTokenFix(
							line,
							action,
							candidate,
							`Replace with '${candidate}'`,
							`替换为“${candidate}”`,
						),
				)
			: undefined;
		diagnostics.push(
			diagnostic(
				line,
				action,
				"syntax.actor_action",
				"Actor action must be show, exit, change, move, or motion.",
				"actor 操作必须为 show、exit、change、move 或 motion。",
				fixes,
			),
		);
		return;
	}
	const signatures: Record<string, number> = {
		exit: 3,
		change: 4,
		move: 4,
		motion: 4,
		show: 6,
	};
	if (
		!requireCount(
			diagnostics,
			line,
			tokens,
			signatures[action.text] ?? 3,
			`actor ${action.text} ...`,
		)
	) {
		return;
	}
	if (action.text === "show") {
		if (tokens[4]?.text !== "at" || !NUMBER.test(tokens[5]?.text ?? "")) {
			diagnostics.push(
				diagnostic(
					line,
					tokens[4] ?? tokens[3],
					"syntax.actor_position",
					"Expected: actor show <actor> <state> at <position>",
					"应为：actor show <角色> <状态> at <位置>",
				),
			);
		}
	} else if (action.text === "move" && !NUMBER.test(tokens[3]?.text ?? "")) {
		diagnostics.push(
			diagnostic(
				line,
				tokens[3],
				"syntax.actor_position",
				"Actor position must be numeric.",
				"演员位置必须是数字。",
			),
		);
	}
}

function validateIf(
	line: number,
	content: string,
	tokens: readonly Token[],
	diagnostics: DiagnosticSpec[],
): void {
	if (!content.endsWith(":")) {
		diagnostics.push(
			diagnostic(
				line,
				tokens.at(-1),
				"syntax.if_colon",
				"A conditional line must end with ':'.",
				"条件语句必须以“:”结尾。",
				[
					{
						title: "Add missing ':'",
						titleZh: "补充缺失的“:”",
						preferred: true,
						edits: [
							{
								line,
								start: content.length,
								end: content.length,
								newText: ":",
							},
						],
					},
				],
			),
		);
	}
	const normalizedLast = tokens.at(-1)?.text.replace(/:$/u, "") ?? "";
	if (
		tokens.length !== 4 ||
		!VARIABLE.test(tokens[1]?.text ?? "") ||
		!COMPARISON.test(tokens[2]?.text ?? "") ||
		!INTEGER.test(normalizedLast)
	) {
		const fixes: QuickFixSpec[] = [];
		const operator = tokens[2];
		if (operator?.text === "=") {
			fixes.push(
				replaceTokenFix(
					line,
					operator,
					"==",
					"Replace '=' with '=='",
					"将“=”替换为“==”",
				),
			);
		}
		diagnostics.push(
			diagnostic(
				line,
				tokens[1] ?? tokens[0],
				"syntax.condition",
				"Expected: if <%variable|$variable> <operator> <integer>:",
				"应为：if <%变量|$变量> <比较运算符> <整数>:",
				fixes,
			),
		);
	}
}

function validateChoice(
	line: number,
	tokens: readonly Token[],
	diagnostics: DiagnosticSpec[],
): void {
	if (
		tokens.length < 4 ||
		!tokens[1]?.quoted ||
		tokens[2]?.text !== "->" ||
		!IDENTIFIER.test(tokens[3]?.text ?? "")
	) {
		const fixes: QuickFixSpec[] = [];
		if (tokens.length === 3 && tokens[1]?.quoted && tokens[2]) {
			fixes.push({
				title: "Insert missing '->'",
				titleZh: "补充缺失的“->”",
				preferred: true,
				edits: [
					{
						line,
						start: tokens[2].start,
						end: tokens[2].start,
						newText: "-> ",
					},
				],
			});
		}
		diagnostics.push(
			diagnostic(
				line,
				tokens.at(-1),
				"syntax.choice",
				'Expected: choice "<option>" -> <branch_name> [if <condition>] [once]',
				'应为：choice "<选项>" -> <分支名> [if <条件>] [once]',
				fixes,
			),
		);
		return;
	}
	validateChoiceFilters(line, tokens, diagnostics);
}

function validateChoiceFilters(
	line: number,
	tokens: readonly Token[],
	diagnostics: DiagnosticSpec[],
): void {
	let index = 4;
	let hasCondition = false;
	let usedOnce = false;
	while (index < tokens.length) {
		const token = tokens[index];
		if (!token) {
			return;
		}
		if (token.text === "if") {
			if (hasCondition) {
				diagnostics.push(
					diagnostic(
						line,
						token,
						"syntax.choice_condition",
						"A choice accepts at most one 'if' filter.",
						"一个选项最多只能有一个“if”过滤条件。",
					),
				);
				return;
			}
			hasCondition = true;
			index = validateChoiceCondition(
				line,
				tokens,
				index + 1,
				diagnostics,
			);
			if (index < 0) {
				return;
			}
			continue;
		}
		if (token.text.toLowerCase() === "once") {
			if (usedOnce) {
				diagnostics.push(
					diagnostic(
						line,
						token,
						"syntax.choice_once",
						"A choice can be marked 'once' only one time.",
						"同一个选项只能标记一次“once”。",
					),
				);
				return;
			}
			usedOnce = true;
			index += 1;
			continue;
		}
		diagnostics.push(
			diagnostic(
				line,
				token,
				"syntax.choice",
				'Expected: choice "<option>" -> <branch_name> [if <condition>] [once]',
				'应为：choice "<选项>" -> <分支名> [if <条件>] [once]',
			),
		);
		return;
	}
}

function validateChoiceCondition(
	line: number,
	tokens: readonly Token[],
	start: number,
	diagnostics: DiagnosticSpec[],
): number {
	const variable = tokens[start];
	if (!variable || !VARIABLE.test(variable.text)) {
		diagnostics.push(
			diagnostic(
				line,
				variable ?? tokens[start - 1],
				"syntax.choice_condition",
				"A choice condition must begin with a %persistent or $temporary variable.",
				"选项条件必须以 %持久变量 或 $临时变量 开头。",
			),
		);
		return -1;
	}
	const operator = tokens[start + 1];
	if (!operator || !COMPARISON.test(operator.text)) {
		diagnostics.push(
			diagnostic(
				line,
				operator ?? variable,
				"syntax.choice_condition",
				"A choice condition needs a comparison operator.",
				"选项条件缺少比较运算符。",
			),
		);
		return -1;
	}
	const value = tokens[start + 2];
	if (!value || !isChoiceConditionValue(value)) {
		diagnostics.push(
			diagnostic(
				line,
				value ?? operator,
				"syntax.choice_condition",
				"A choice condition needs a number, string, identifier, or variable value.",
				"选项条件缺少数字、字符串、标识符或变量值。",
			),
		);
		return -1;
	}
	return start + 3;
}

function isChoiceConditionValue(token: Token): boolean {
	return (
		token.quoted ||
		NUMBER.test(token.text) ||
		VARIABLE.test(token.text) ||
		IDENTIFIER.test(token.text)
	);
}

function validateAchievement(
	line: number,
	tokens: readonly Token[],
	diagnostics: DiagnosticSpec[],
): void {
	const action = tokens[1];
	if (!action || !ACHIEVEMENT_ACTIONS.has(action.text)) {
		diagnostics.push(
			diagnostic(
				line,
				action,
				"syntax.achievement_action",
				"Achievement action must be unlock, increment, or set_flag.",
				"achievement 操作必须为 unlock、increment 或 set_flag。",
			),
		);
		return;
	}
	const expected = action.text === "unlock" ? 3 : 4;
	if (
		!requireCount(
			diagnostics,
			line,
			tokens,
			expected,
			`achievement ${action.text} ...`,
		)
	) {
		return;
	}
	if (!tokens[2]?.quoted) {
		diagnostics.push(
			diagnostic(
				line,
				tokens[2],
				"syntax.achievement_id",
				"Achievement and flag IDs must be quoted.",
				"成就与标记 ID 必须使用引号。",
			),
		);
	}
	if (action.text === "increment" && !NUMBER.test(tokens[3]?.text ?? "")) {
		diagnostics.push(
			diagnostic(
				line,
				tokens[3],
				"syntax.achievement_amount",
				"Achievement increment must be numeric.",
				"成就增量必须是数字。",
			),
		);
	}
	if (
		action.text === "set_flag" &&
		!["true", "false"].includes(tokens[3]?.text ?? "")
	) {
		const value = tokens[3];
		diagnostics.push(
			diagnostic(
				line,
				value,
				"syntax.boolean",
				"Flag value must be true or false.",
				"标记值必须为 true 或 false。",
				value
					? ["true", "false"].map((candidate) =>
							replaceTokenFix(
								line,
								value,
								candidate,
								`Replace with '${candidate}'`,
								`替换为“${candidate}”`,
							),
						)
					: undefined,
			),
		);
	}
}

function validateCamera(
	line: number,
	tokens: readonly Token[],
	diagnostics: DiagnosticSpec[],
): void {
	const root = tokens[0]?.text ?? "cam";
	const action = tokens[1];
	const actions = root === "asyncam" ? ASYNC_CAMERA_ACTIONS : CAMERA_ACTIONS;
	if (!action || !actions.has(action.text)) {
		diagnostics.push(
			diagnostic(
				line,
				action,
				"syntax.camera_action",
				`${root} action must be ${[...actions].join(", ")}.`,
				`${root} 操作必须为 ${[...actions].join("、")}。`,
			),
		);
		return;
	}
	if (action.text === "stop") {
		requireCount(diagnostics, line, tokens, 2, "asyncam stop");
		return;
	}
	let optionStart = 2;
	if (action.text === "move") {
		if (!tokens[2]) {
			diagnostics.push(
				diagnostic(
					line,
					action,
					"syntax.camera_target",
					`${root} move requires a camera name.`,
					`${root} move 缺少目标镜头名。`,
				),
			);
			return;
		}
		optionStart = 3;
	}
	const option = tokens[optionStart];
	const duration = tokens[optionStart + 1];
	if (action.text === "shake") {
		if (option && !NUMBER.test(option.text)) {
			diagnostics.push(
				diagnostic(
					line,
					option,
					"syntax.duration",
					"Camera shake duration must be numeric.",
					"镜头震动时长必须是数字。",
				),
			);
		}
	} else {
		if (option && !TRANSITIONS.has(option.text)) {
			diagnostics.push(
				diagnostic(
					line,
					option,
					"syntax.camera_transition",
					`Unknown camera transition '${option.text}'.`,
					`未知的镜头过渡“${option.text}”。`,
				),
			);
		}
		if (duration && !NUMBER.test(duration.text)) {
			diagnostics.push(
				diagnostic(
					line,
					duration,
					"syntax.duration",
					"Camera transition duration must be numeric.",
					"镜头过渡时长必须是数字。",
				),
			);
		}
	}
	if (tokens.length > optionStart + 2) {
		diagnostics.push(
			diagnostic(
				line,
				tokens[optionStart + 2],
				"syntax.arguments",
				`${root} has too many arguments.`,
				`${root} 参数过多。`,
			),
		);
	}
}

export function analyzeDocument(
	source: string,
	project?: ProjectSnapshot,
): DiagnosticSpec[] {
	const diagnostics: DiagnosticSpec[] = [];
	const lines = source.split(/\r?\n/u);
	const ifStack: number[] = [];
	const stableIds = new Map<string, number>();
	let insideScreenText = false;
	let screenStart = -1;
	let choiceGroupOpen = false;

	lines.forEach((line, lineNumber) => {
		const { code } = splitCodeAndComment(line);
		const content = code.trim();
		if (content.length === 0) {
			return;
		}
		const tokens = tokenizeLine(line);
		const unclosedString = tokens.find(
			(token) => token.quoted && !token.closed,
		);
		if (unclosedString) {
			diagnostics.push(
				diagnostic(
					lineNumber,
					unclosedString,
					"syntax.unclosed_string",
					"String is missing a closing quote.",
					"字符串缺少结束引号。",
					[
						{
							title: "Add closing quote",
							titleZh: "补充结束引号",
							preferred: true,
							edits: [
								{
									line: lineNumber,
									start: unclosedString.end,
									end: unclosedString.end,
									newText: '"',
								},
							],
						},
					],
				),
			);
			return;
		}
		if (insideScreenText) {
			if (tokens[0]?.text === "}") {
				const closeParameters = parseStatementParameters(
					code.trimEnd(),
				);
				validateNamedParameters(
					lineNumber,
					tokens,
					closeParameters,
					diagnostics,
					"screentext",
				);
				const stableId = closeParameters.parameters.find(
					(parameter) => parameter.name === "id",
				);
				if (stableId && IDENTIFIER.test(stableId.value)) {
					const firstLine = stableIds.get(stableId.value);
					if (firstLine !== undefined) {
						diagnostics.push({
							code: "semantic.duplicate_instruction_id",
							severity: "error",
							line: lineNumber,
							start: stableId.start,
							end: stableId.end,
							message: `Instruction ID '${stableId.value}' is duplicated (first used on line ${firstLine + 1}).`,
							messageZh: `指令 ID“${stableId.value}”重复（首次出现在第 ${firstLine + 1} 行）。`,
						});
					} else {
						stableIds.set(stableId.value, lineNumber);
					}
				}
				insideScreenText = false;
			} else if (tokens.length !== 1 || !tokens[0]?.quoted) {
				diagnostics.push(
					diagnostic(
						lineNumber,
						tokens[0],
						"syntax.screentext_content",
						"A screen-text block accepts only quoted text lines or '}'.",
						"全屏文本块内只允许带引号的文本行或“}”。",
					),
				);
			}
			return;
		}

		const parsedParameters = parseStatementParameters(code.trimEnd());
		const statementTokens = tokenizeLine(parsedParameters.base);
		const statementContent = parsedParameters.base.trim();
		validateNamedParameters(
			lineNumber,
			statementTokens,
			parsedParameters,
			diagnostics,
		);
		if (parsedParameters.malformedStart !== undefined) {
			return;
		}
		const currentRoot = statementTokens[0]?.text.replace(/:$/u, "") ?? "";
		if (currentRoot === "choice") {
			if (choiceGroupOpen && parsedParameters.parameters.length > 0) {
				const parameter = parsedParameters.parameters[0];
				if (parameter) {
					diagnostics.push({
						code: "syntax.choice_group_parameter",
						severity: "error",
						line: lineNumber,
						start: parameter.start,
						end: parameter.end,
						message:
							"Named parameters for a consecutive choice group belong on its first item only.",
						messageZh: "连续 choice 组的命名参数只能写在第一项。",
					});
				}
			}
			choiceGroupOpen = true;
		} else {
			choiceGroupOpen = false;
		}
		const stableId = parsedParameters.parameters.find(
			(parameter) => parameter.name === "id",
		);
		if (stableId && IDENTIFIER.test(stableId.value)) {
			const firstLine = stableIds.get(stableId.value);
			if (firstLine !== undefined) {
				diagnostics.push({
					code: "semantic.duplicate_instruction_id",
					severity: "error",
					line: lineNumber,
					start: stableId.start,
					end: stableId.end,
					message: `Instruction ID '${stableId.value}' is duplicated (first used on line ${firstLine + 1}).`,
					messageZh: `指令 ID“${stableId.value}”重复（首次出现在第 ${firstLine + 1} 行）。`,
				});
			} else {
				stableIds.set(stableId.value, lineNumber);
			}
		}

		if (isDialogueTokens(statementTokens)) {
			if (
				statementTokens.length < 2 ||
				!statementTokens[1]?.quoted ||
				statementTokens.length > 3
			) {
				diagnostics.push(
					diagnostic(
						lineNumber,
						statementTokens[0],
						"syntax.dialogue",
						'Expected: <actor|variable|"label"> "<dialogue>" [voice_id] [name=value ...]',
						'应为：<演员|变量|"署名"> "<对话>" [语音 ID] [名称=值 ...]',
					),
				);
			}
			return;
		}

		validateCommand(
			lineNumber,
			statementContent,
			statementTokens,
			diagnostics,
		);
		const root = statementTokens[0]?.text.replace(/:$/u, "");
		if (root === "screentext" && statementContent.endsWith("{")) {
			insideScreenText = true;
			screenStart = lineNumber;
		} else if (root === "if") {
			ifStack.push(lineNumber);
		} else if (root === "else" && ifStack.length === 0) {
			diagnostics.push(
				diagnostic(
					lineNumber,
					tokens[0],
					"syntax.unexpected_else",
					"Unexpected 'else:' without a matching 'if'.",
					"“else:”没有匹配的“if”。",
				),
			);
		} else if (root === "endif") {
			if (ifStack.length === 0) {
				diagnostics.push(
					diagnostic(
						lineNumber,
						tokens[0],
						"syntax.unexpected_endif",
						"Unexpected 'endif' without a matching 'if'.",
						"“endif”没有匹配的“if”。",
						[
							{
								title: "Remove unmatched 'endif'",
								titleZh: "移除不匹配的“endif”",
								preferred: true,
								edits: [
									{
										line: lineNumber,
										start: 0,
										end: line.length,
										newText: "",
									},
								],
							},
						],
					),
				);
			} else {
				ifStack.pop();
			}
		}
	});

	if (insideScreenText) {
		const line = Math.max(0, screenStart);
		diagnostics.push(
			diagnostic(
				line,
				undefined,
				"syntax.screentext_missing_close",
				"Screen-text block is missing '}'.",
				"全屏文本块缺少“}”。",
				[
					{
						title: "Add closing '}'",
						titleZh: "补充结束括号“}”",
						preferred: true,
						edits: [
							{
								line: lines.length - 1,
								start: lines.at(-1)?.length ?? 0,
								end: lines.at(-1)?.length ?? 0,
								newText: "\n}",
							},
						],
					},
				],
			),
		);
	}
	for (const line of ifStack) {
		diagnostics.push(
			diagnostic(
				line,
				tokenizeLine(lines[line] ?? "")[0],
				"syntax.if_missing_endif",
				"Conditional block is missing 'endif'.",
				"条件块缺少“endif”。",
				[
					{
						title: "Add closing 'endif'",
						titleZh: "补充“endif”",
						preferred: true,
						edits: [
							{
								line: lines.length - 1,
								start: lines.at(-1)?.length ?? 0,
								end: lines.at(-1)?.length ?? 0,
								newText: "\nendif",
							},
						],
					},
				],
			),
		);
	}

	appendBranchDiagnostics(source, diagnostics);
	if (project) {
		appendProjectDiagnostics(source, project, diagnostics);
	}
	return diagnostics.sort(
		(left, right) => left.line - right.line || left.start - right.start,
	);
}

function appendBranchDiagnostics(
	source: string,
	diagnostics: DiagnosticSpec[],
): void {
	const references = extractReferences(source);
	const branches = new Set(
		references
			.filter(
				(item) =>
					item.kind === "branches" && item.role === "definition",
			)
			.map((item) => item.name),
	);
	for (const item of references) {
		if (
			item.kind !== "branches" ||
			item.role !== "reference" ||
			branches.has(item.name)
		) {
			continue;
		}
		diagnostics.push({
			code: "semantic.missing_branch",
			severity: "warning",
			line: item.line,
			start: item.start,
			end: item.end,
			message: `Branch '${item.name}' is not declared in this script.`,
			messageZh: `当前剧本中未声明分支“${item.name}”。`,
			fixes: [
				{
					title: `Create branch '${item.name}'`,
					titleZh: `创建分支“${item.name}”`,
					preferred: true,
					edits: [
						{
							line: source.split(/\r?\n/u).length - 1,
							start: source.split(/\r?\n/u).at(-1)?.length ?? 0,
							end: source.split(/\r?\n/u).at(-1)?.length ?? 0,
							newText: `\n\nbranch ${item.name}\n\t`,
						},
					],
				},
			],
		});
	}
}

function appendProjectDiagnostics(
	source: string,
	project: ProjectSnapshot,
	diagnostics: DiagnosticSpec[],
): void {
	const checkedKinds = new Set<SymbolKind>([
		"actors",
		"states",
		"motions",
		"backgrounds",
		"bgms",
		"sfx",
		"voices",
		"cameras",
	]);
	for (const item of extractReferences(source)) {
		if (item.kind === "scripts") {
			if (project.definitions("scripts", item.name).length === 0) {
				diagnostics.push({
					code: "semantic.missing_script",
					severity: "warning",
					line: item.line,
					start: item.start,
					end: item.end,
					message: `Target KonadoScript '${item.name}' does not exist.`,
					messageZh: `目标 KonadoScript“${item.name}”不存在。`,
				});
			}
			continue;
		}
		if (!checkedKinds.has(item.kind)) {
			continue;
		}
		const definitions = project
			.definitions(item.kind, item.name)
			.filter((definition) => {
				if (!item.scopeName || !definition.scopeName) {
					return true;
				}
				return definition.scopeName === item.scopeName;
			});
		if (definitions.length > 0) {
			continue;
		}
		if (item.optional) {
			continue;
		}
		const label = kindLabel(item.kind);
		const labelZh = kindLabelZh(item.kind);
		const candidates = closestValues(
			item.name,
			project.values(item.kind, item.scopeName),
		);
		diagnostics.push({
			code: "semantic.unknown_resource",
			severity: "warning",
			line: item.line,
			start: item.start,
			end: item.end,
			message: `Unknown ${label} '${item.name}'.`,
			messageZh: `未知的${labelZh}“${item.name}”。`,
			fixes: candidates.map((candidate, index) => ({
				title: `Replace with '${candidate}'`,
				titleZh: `替换为“${candidate}”`,
				preferred: index === 0,
				edits: [
					{
						line: item.line,
						start: item.start,
						end: item.end,
						newText: candidate,
					},
				],
			})),
		});
	}
}

export function kindLabel(kind: SymbolKind): string {
	return (
		{
			actors: "actor",
			states: "actor state",
			motions: "actor motion",
			backgrounds: "background",
			bgms: "BGM",
			sfx: "sound effect",
			voices: "voice",
			cameras: "camera setup",
			branches: "branch",
			variables: "variable",
			signals: "signal",
			achievements: "achievement",
			scripts: "script",
		} satisfies Record<SymbolKind, string>
	)[kind];
}

function kindLabelZh(kind: SymbolKind): string {
	return (
		{
			actors: "角色",
			states: "角色状态",
			motions: "演员动作",
			backgrounds: "背景",
			bgms: "背景音乐",
			sfx: "音效",
			voices: "语音",
			cameras: "镜头配置",
			branches: "分支",
			variables: "变量",
			signals: "信号",
			achievements: "成就",
			scripts: "剧本",
		} satisfies Record<SymbolKind, string>
	)[kind];
}
