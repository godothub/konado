import * as vscode from "vscode";
import {
	ACTOR_POSITIONS,
	BACKGROUND_EFFECTS,
	CAMERA_TRANSITIONS,
	COMMANDS,
	CONTEXT_KEYWORDS,
	ROOT_KEYWORDS,
	SNIPPETS,
	commandKey,
	namedParametersForCommand,
} from "./catalog";
import type { DiagnosticManager } from "./diagnostics";
import { formatSource } from "./formatter";
import {
	extractReferences,
	kindLabel,
	referencesForLine,
	splitCodeAndComment,
	tokenizeLine,
	type IndexedDefinition,
	type SymbolKind,
	type SymbolReference,
} from "./language";
import { isChineseUi, text } from "./localization";
import type { ProjectIndex } from "./project-index";

const SELECTOR: vscode.DocumentSelector = {
	language: "konadoscript",
	scheme: "file",
};

const SEMANTIC_LEGEND = new vscode.SemanticTokensLegend([
	"variable",
	"class",
	"property",
	"event",
	"label",
]);

export function registerLanguageProviders(
	context: vscode.ExtensionContext,
	index: ProjectIndex,
	diagnostics: DiagnosticManager,
): void {
	context.subscriptions.push(
		vscode.languages.registerCompletionItemProvider(
			SELECTOR,
			new CompletionProvider(index),
			" ",
			"%",
			"$",
			"/",
		),
		vscode.languages.registerHoverProvider(
			SELECTOR,
			new HoverProvider(index),
		),
		vscode.languages.registerDefinitionProvider(
			SELECTOR,
			new DefinitionProvider(index),
		),
		vscode.languages.registerReferenceProvider(
			SELECTOR,
			new ReferenceProvider(),
		),
		vscode.languages.registerRenameProvider(SELECTOR, new RenameProvider()),
		vscode.languages.registerDocumentSymbolProvider(
			SELECTOR,
			new DocumentSymbolProvider(),
		),
		vscode.languages.registerWorkspaceSymbolProvider(
			new WorkspaceSymbolProvider(index),
		),
		vscode.languages.registerFoldingRangeProvider(
			SELECTOR,
			new FoldingProvider(),
		),
		vscode.languages.registerSignatureHelpProvider(
			SELECTOR,
			new SignatureProvider(),
			" ",
		),
		vscode.languages.registerDocumentLinkProvider(
			SELECTOR,
			new LinkProvider(index),
		),
		vscode.languages.registerDocumentSemanticTokensProvider(
			SELECTOR,
			new SemanticTokensProvider(),
			SEMANTIC_LEGEND,
		),
		vscode.languages.registerDocumentHighlightProvider(
			SELECTOR,
			new HighlightProvider(),
		),
		vscode.languages.registerDocumentFormattingEditProvider(
			SELECTOR,
			new FormattingProvider(),
		),
		vscode.languages.registerCodeActionsProvider(
			SELECTOR,
			new CodeActionProvider(diagnostics),
			{
				providedCodeActionKinds: [vscode.CodeActionKind.QuickFix],
			},
		),
	);
}

class CompletionProvider implements vscode.CompletionItemProvider {
	constructor(private readonly index: ProjectIndex) {}

	provideCompletionItems(
		document: vscode.TextDocument,
		position: vscode.Position,
	): vscode.CompletionList {
		const line = document
			.lineAt(position.line)
			.text.slice(0, position.character);
		const { code } = splitCodeAndComment(line);
		const tokens = tokenizeLine(code);
		const trailingSpace = /\s$/u.test(code);
		const argumentIndex = trailingSpace
			? tokens.length
			: Math.max(0, tokens.length - 1);
		const partial = trailingSpace ? "" : (tokens.at(-1)?.text ?? "");
		const root = tokens[0]?.text.replace(/:$/u, "") ?? "";
		const items: vscode.CompletionItem[] = [];

		if (argumentIndex === 0) {
			for (const keyword of ROOT_KEYWORDS) {
				const item = new vscode.CompletionItem(
					keyword,
					vscode.CompletionItemKind.Keyword,
				);
				const info = COMMANDS[keyword];
				item.detail = info?.signature;
				item.documentation = info
					? isChineseUi()
						? info.descriptionZh
						: info.description
					: undefined;
				item.sortText = `0-${keyword}`;
				items.push(item);
			}
			for (const snippet of SNIPPETS) {
				const item = new vscode.CompletionItem(
					isChineseUi() ? snippet.labelZh : snippet.label,
					vscode.CompletionItemKind.Snippet,
				);
				item.detail = isChineseUi() ? snippet.detailZh : snippet.detail;
				item.insertText = new vscode.SnippetString(snippet.body);
				item.sortText = `1-${snippet.label}`;
				items.push(item);
			}
			for (const candidate of [
				...this.index.values("actors"),
				...documentSymbols(document, "variables"),
			]) {
				const item = new vscode.CompletionItem(
					candidate,
					candidate.startsWith("$") || candidate.startsWith("%")
						? vscode.CompletionItemKind.Variable
						: vscode.CompletionItemKind.Class,
				);
				item.sortText = `0-${candidate}`;
				items.push(item);
			}
			return new vscode.CompletionList(
				filterCompletions(items, partial),
				false,
			);
		}

		const candidates = this.contextCandidates(
			document,
			tokens,
			argumentIndex,
		);
		for (const candidate of candidates) {
			const item = new vscode.CompletionItem(
				candidate,
				completionKind(root, argumentIndex),
			);
			item.sortText = `0-${candidate}`;
			items.push(item);
		}
		if (trailingSpace) {
			items.push(...this.namedParameterItems(tokens, code));
		}
		return new vscode.CompletionList(
			filterCompletions(items, partial),
			false,
		);
	}

	private namedParameterItems(
		tokens: ReturnType<typeof tokenizeLine>,
		line: string,
	): vscode.CompletionItem[] {
		const parameterIndex = tokens.findIndex((token) =>
			token.text.startsWith("["),
		);
		const statementTokens =
			parameterIndex < 0 ? tokens : tokens.slice(0, parameterIndex);
		if (!isCompleteStatementForParameters(statementTokens)) {
			return [];
		}
		const command = isDialogueStatement(statementTokens)
			? "dialogue"
			: commandKey(statementTokens.map((token) => token.text));
		if (command === "if" && line.trim().endsWith(":")) {
			return [];
		}
		const parameters = namedParametersForCommand(command);
		return Object.entries(parameters).flatMap(([name, definition]) => {
			if (new RegExp(`\\[\\s*${name}\\s*=`, "u").test(line)) {
				return [];
			}
			const item = new vscode.CompletionItem(
				`[${name}=]`,
				vscode.CompletionItemKind.Property,
			);
			item.insertText = new vscode.SnippetString(
				`[${name}=\${1:${definition.defaultValue}}]`,
			);
			item.detail = text(
				`KonadoScript named parameter for ${command}`,
				`${command} 的 KonadoScript 命名参数`,
			);
			item.sortText = `0-parameter-${name}`;
			return [item];
		});
	}

	private contextCandidates(
		document: vscode.TextDocument,
		tokens: ReturnType<typeof tokenizeLine>,
		argumentIndex: number,
	): readonly string[] {
		const root = tokens[0]?.text.replace(/:$/u, "") ?? "";
		if (argumentIndex === 1 && root in CONTEXT_KEYWORDS) {
			return CONTEXT_KEYWORDS[root as keyof typeof CONTEXT_KEYWORDS];
		}
		switch (root) {
			case "background":
				return argumentIndex === 1
					? this.index.values("backgrounds")
					: argumentIndex === 2
						? BACKGROUND_EFFECTS
						: [];
			case "actor": {
				const action = tokens[1]?.text;
				if (argumentIndex === 2) {
					return this.index.values("actors");
				}
				if (
					argumentIndex === 3 &&
					["show", "change"].includes(action ?? "")
				) {
					return this.index.values("states", tokens[2]?.text);
				}
				if (argumentIndex === 3 && action === "motion") {
					return this.index.values("motions", tokens[2]?.text);
				}
				if (
					(argumentIndex === 3 && action === "move") ||
					(argumentIndex === 5 && action === "show")
				) {
					return ACTOR_POSITIONS;
				}
				if (argumentIndex === 4 && action === "show") {
					return ["at"];
				}
				return [];
			}
			case "play":
				if (argumentIndex === 2) {
					return this.index.values(
						tokens[1]?.text === "sfx" ? "sfx" : "bgms",
					);
				}
				return [];
			case "stop":
				return argumentIndex === 1 ? ["bgm"] : [];
			case "choice":
				return argumentIndex === 2
					? ["->"]
					: argumentIndex === 3
						? documentSymbols(document, "branches")
						: [];
			case "jump_branch":
			case "call":
				return argumentIndex === 1
					? documentSymbols(document, "branches")
					: [];
			case "jump":
				return argumentIndex === 1 ? this.index.values("scripts") : [];
			case "cam":
			case "asyncam": {
				const action = tokens[1]?.text;
				if (argumentIndex === 2 && action === "move") {
					return this.index.values("cameras");
				}
				const optionIndex = action === "move" ? 3 : 2;
				if (
					argumentIndex === optionIndex &&
					action !== "shake" &&
					action !== "stop"
				) {
					return CAMERA_TRANSITIONS;
				}
				return [];
			}
			case "if":
			case "set":
			case "add":
			case "sub":
			case "mul":
			case "div":
				if (argumentIndex === 1) {
					return documentSymbols(document, "variables");
				}
				break;
			case "waitsignal":
				return argumentIndex === 1 ? this.index.values("signals") : [];
			case "achievement":
				if (argumentIndex === 2) {
					return this.index
						.values("achievements")
						.map((value) => `"${value}"`);
				}
				if (argumentIndex === 3 && tokens[1]?.text === "set_flag") {
					return ["true", "false"];
				}
				break;
		}
		return [];
	}
}

function isDialogueStatement(tokens: ReturnType<typeof tokenizeLine>): boolean {
	return Boolean(
		tokens.length >= 2 &&
		tokens[1]?.quoted &&
		(tokens[0]?.quoted ||
			tokens[0]?.text.startsWith("$") ||
			tokens[0]?.text.startsWith("%") ||
			!ROOT_KEYWORDS.includes(
				tokens[0]?.text as (typeof ROOT_KEYWORDS)[number],
			)),
	);
}

function isCompleteStatementForParameters(
	tokens: ReturnType<typeof tokenizeLine>,
): boolean {
	if (isDialogueStatement(tokens)) {
		return tokens.length === 2 || tokens.length === 3;
	}
	const command = commandKey(tokens.map((token) => token.text));
	const minimumTokens: Readonly<Record<string, number>> = {
		showtextbox: 1,
		hidetextbox: 1,
		waitsignal: 2,
		background: 2,
		"actor show": 6,
		"actor exit": 3,
		"actor change": 4,
		"actor move": 4,
		"actor motion": 4,
		"play bgm": 3,
		"play sfx": 3,
		stop: 1,
		"stop bgm": 2,
		choice: 4,
		if: 4,
		set: 3,
		add: 3,
		sub: 3,
		mul: 3,
		div: 3,
		jump: 2,
		jump_branch: 2,
		call: 2,
		return: 1,
		signal: 2,
		"achievement unlock": 3,
		"achievement increment": 4,
		"achievement set_flag": 4,
		"cam move": 3,
		"cam reset": 2,
		"cam shake": 2,
		"asyncam move": 3,
		"asyncam reset": 2,
		"asyncam shake": 2,
		"asyncam stop": 2,
		end: 1,
	};
	const minimum = minimumTokens[command];
	return minimum !== undefined && tokens.length >= minimum;
}

class HoverProvider implements vscode.HoverProvider {
	constructor(private readonly index: ProjectIndex) {}

	provideHover(
		document: vscode.TextDocument,
		position: vscode.Position,
	): vscode.Hover | undefined {
		const reference = referenceAt(document, position);
		if (reference) {
			const definitions =
				reference.kind === "branches"
					? localDefinitions(document, reference)
					: this.index.definitions(reference.kind, reference.name);
			const markdown = new vscode.MarkdownString();
			markdown.appendCodeblock(
				`${kindLabel(reference.kind)} ${reference.name}`,
				"konadoscript",
			);
			if (definitions.length > 0) {
				markdown.appendMarkdown(
					`\n${text("Definitions", "定义")}: ${definitions.length}\n`,
				);
				for (const definition of definitions.slice(0, 5)) {
					markdown.appendMarkdown(
						`\n- [${displayPath(definition.uri)}:${definition.line + 1}](${definition.uri}#L${definition.line + 1})`,
					);
				}
			} else if (reference.kind === "variables") {
				markdown.appendMarkdown(
					reference.name.startsWith("%")
						? text(
								"\nPersistent variable: retained across shots and save data.",
								"\n持久变量：跨镜头保留，并写入存档。",
							)
						: text(
								"\nTemporary variable: valid only in the current shot.",
								"\n临时变量：只在当前镜头内有效。",
							),
				);
			}
			markdown.isTrusted = true;
			return new vscode.Hover(markdown, referenceRange(reference));
		}

		const line = document.lineAt(position.line).text;
		const tokens = tokenizeLine(line);
		const token = tokens.find(
			(item) =>
				position.character >= item.start &&
				position.character <= item.end,
		);
		if (!token) {
			return undefined;
		}
		const words = tokens.map((item) => item.text);
		const key =
			tokens.indexOf(token) <= 1
				? commandKey(words)
				: (tokens[0]?.text ?? "");
		const info = COMMANDS[key];
		if (!info) {
			return undefined;
		}
		const markdown = new vscode.MarkdownString();
		markdown.appendCodeblock(info.signature, "konadoscript");
		markdown.appendMarkdown(
			`\n${isChineseUi() ? info.descriptionZh : info.description}`,
		);
		markdown.appendMarkdown(
			`\n\n[${text("Open documentation", "查看文档")}](command:konado.openDocumentation)`,
		);
		markdown.isTrusted = true;
		return new vscode.Hover(markdown, tokenRange(position.line, token));
	}
}

class DefinitionProvider implements vscode.DefinitionProvider {
	constructor(private readonly index: ProjectIndex) {}

	provideDefinition(
		document: vscode.TextDocument,
		position: vscode.Position,
	): vscode.Definition | undefined {
		const reference = referenceAt(document, position);
		if (!reference) {
			return undefined;
		}
		if (reference.kind === "branches") {
			return localDefinitions(document, reference).map(toLocation);
		}
		if (reference.kind === "scripts") {
			const uri = this.index.resolveResourceUri(
				document.uri,
				reference.name,
			);
			return uri
				? new vscode.Location(uri, new vscode.Position(0, 0))
				: undefined;
		}
		return this.index
			.definitions(reference.kind, reference.name)
			.map(toLocation);
	}
}

class ReferenceProvider implements vscode.ReferenceProvider {
	async provideReferences(
		document: vscode.TextDocument,
		position: vscode.Position,
		context: vscode.ReferenceContext,
	): Promise<vscode.Location[]> {
		const target = referenceAt(document, position);
		if (!target) {
			return [];
		}
		const documents = await referenceDocuments(document, target);
		const locations: vscode.Location[] = [];
		for (const candidate of documents) {
			for (const reference of extractReferences(candidate.getText())) {
				if (
					reference.kind === target.kind &&
					reference.name === target.name &&
					(context.includeDeclaration ||
						reference.role !== "definition")
				) {
					locations.push(
						new vscode.Location(
							candidate.uri,
							referenceRange(reference),
						),
					);
				}
			}
		}
		return locations;
	}
}

class RenameProvider implements vscode.RenameProvider {
	prepareRename(
		document: vscode.TextDocument,
		position: vscode.Position,
	): vscode.Range | { range: vscode.Range; placeholder: string } {
		const reference = referenceAt(document, position);
		if (
			!reference ||
			!["branches", "variables", "signals"].includes(reference.kind)
		) {
			throw new Error(
				text(
					"Only branches, variables, and signals can be renamed safely.",
					"只能安全地重命名分支、变量和信号。",
				),
			);
		}
		return {
			range: referenceRange(reference),
			placeholder: reference.name,
		};
	}

	async provideRenameEdits(
		document: vscode.TextDocument,
		position: vscode.Position,
		newName: string,
	): Promise<vscode.WorkspaceEdit> {
		const target = referenceAt(document, position);
		if (!target) {
			return new vscode.WorkspaceEdit();
		}
		if (
			target.kind === "variables" &&
			!newName.startsWith(target.name.slice(0, 1))
		) {
			throw new Error(
				text(
					`The renamed variable must retain its '${target.name.slice(0, 1)}' prefix.`,
					`重命名后的变量必须保留“${target.name.slice(0, 1)}”前缀。`,
				),
			);
		}
		const edit = new vscode.WorkspaceEdit();
		for (const candidate of await referenceDocuments(document, target)) {
			for (const reference of extractReferences(candidate.getText())) {
				if (
					reference.kind === target.kind &&
					reference.name === target.name
				) {
					edit.replace(
						candidate.uri,
						referenceRange(reference),
						newName,
					);
				}
			}
		}
		return edit;
	}
}

class DocumentSymbolProvider implements vscode.DocumentSymbolProvider {
	provideDocumentSymbols(
		document: vscode.TextDocument,
	): vscode.DocumentSymbol[] {
		const references = extractReferences(document.getText());
		const lines = document.lineCount;
		const definitions = references.filter(
			(item) =>
				item.role === "definition" &&
				["branches", "variables", "signals", "achievements"].includes(
					item.kind,
				),
		);
		return definitions.map((item, index) => {
			let endLine = item.line;
			if (item.kind === "branches") {
				endLine =
					definitions
						.slice(index + 1)
						.find((candidate) => candidate.kind === "branches")
						?.line ?? lines;
				endLine = Math.max(item.line, endLine - 1);
			}
			return new vscode.DocumentSymbol(
				item.name,
				kindLabel(item.kind),
				symbolKind(item.kind),
				new vscode.Range(
					item.line,
					0,
					endLine,
					document.lineAt(Math.min(endLine, lines - 1)).text.length,
				),
				referenceRange(item),
			);
		});
	}
}

class WorkspaceSymbolProvider implements vscode.WorkspaceSymbolProvider {
	constructor(private readonly index: ProjectIndex) {}

	provideWorkspaceSymbols(query: string): vscode.SymbolInformation[] {
		const normalized = query.toLocaleLowerCase();
		const kinds: SymbolKind[] = [
			"scripts",
			"branches",
			"variables",
			"signals",
			"achievements",
			"actors",
			"states",
			"motions",
			"backgrounds",
			"bgms",
			"sfx",
			"voices",
			"cameras",
		];
		return kinds.flatMap((kind) =>
			this.index
				.definitions(kind)
				.filter((definition) =>
					definition.name.toLocaleLowerCase().includes(normalized),
				)
				.map(
					(definition) =>
						new vscode.SymbolInformation(
							definition.name,
							symbolKind(kind),
							kindLabel(kind),
							toLocation(definition),
						),
				),
		);
	}
}

class FoldingProvider implements vscode.FoldingRangeProvider {
	provideFoldingRanges(document: vscode.TextDocument): vscode.FoldingRange[] {
		const ranges: vscode.FoldingRange[] = [];
		const conditions: number[] = [];
		const screens: number[] = [];
		let lastBranch: number | undefined;
		for (let line = 0; line < document.lineCount; line += 1) {
			const content = splitCodeAndComment(
				document.lineAt(line).text,
			).code.trim();
			if (content.startsWith("if ") && content.endsWith(":")) {
				conditions.push(line);
			} else if (content === "endif") {
				const start = conditions.pop();
				if (start !== undefined && line > start) {
					ranges.push(new vscode.FoldingRange(start, line));
				}
			} else if (
				content.startsWith("screentext") &&
				content.endsWith("{")
			) {
				screens.push(line);
			} else if (content === "}") {
				const start = screens.pop();
				if (start !== undefined && line > start) {
					ranges.push(new vscode.FoldingRange(start, line));
				}
			} else if (content.startsWith("branch ")) {
				if (lastBranch !== undefined && line - 1 > lastBranch) {
					ranges.push(new vscode.FoldingRange(lastBranch, line - 1));
				}
				lastBranch = line;
			}
		}
		if (lastBranch !== undefined && document.lineCount - 1 > lastBranch) {
			ranges.push(
				new vscode.FoldingRange(lastBranch, document.lineCount - 1),
			);
		}
		return ranges;
	}
}

class SignatureProvider implements vscode.SignatureHelpProvider {
	provideSignatureHelp(
		document: vscode.TextDocument,
		position: vscode.Position,
	): vscode.SignatureHelp | undefined {
		const line = document
			.lineAt(position.line)
			.text.slice(0, position.character);
		const tokens = tokenizeLine(line);
		const info = COMMANDS[commandKey(tokens.map((token) => token.text))];
		if (!info) {
			return undefined;
		}
		const help = new vscode.SignatureHelp();
		const signature = new vscode.SignatureInformation(
			info.signature,
			isChineseUi() ? info.descriptionZh : info.description,
		);
		for (const match of info.signature.matchAll(
			/<([^>]+)>|\[([^\]]+)\]/gu,
		)) {
			signature.parameters.push(
				new vscode.ParameterInformation(match[0], match[1] ?? match[2]),
			);
		}
		help.signatures = [signature];
		help.activeSignature = 0;
		help.activeParameter = Math.max(0, tokens.length - 2);
		return help;
	}
}

class LinkProvider implements vscode.DocumentLinkProvider {
	constructor(private readonly index: ProjectIndex) {}

	provideDocumentLinks(document: vscode.TextDocument): vscode.DocumentLink[] {
		return extractReferences(document.getText())
			.filter((reference) => reference.kind === "scripts")
			.flatMap((reference) => {
				const target = this.index.resolveResourceUri(
					document.uri,
					reference.name,
				);
				if (!target) {
					return [];
				}
				const link = new vscode.DocumentLink(
					referenceRange(reference),
					target,
				);
				link.tooltip = text(
					`Open ${reference.name}`,
					`打开 ${reference.name}`,
				);
				return [link];
			});
	}
}

class SemanticTokensProvider implements vscode.DocumentSemanticTokensProvider {
	provideDocumentSemanticTokens(
		document: vscode.TextDocument,
	): vscode.SemanticTokens {
		const builder = new vscode.SemanticTokensBuilder(SEMANTIC_LEGEND);
		for (const reference of extractReferences(document.getText())) {
			if (reference.optional) {
				continue;
			}
			builder.push(
				reference.line,
				reference.start,
				reference.end - reference.start,
				semanticType(reference.kind),
				0,
			);
		}
		return builder.build();
	}
}

class HighlightProvider implements vscode.DocumentHighlightProvider {
	provideDocumentHighlights(
		document: vscode.TextDocument,
		position: vscode.Position,
	): vscode.DocumentHighlight[] {
		const target = referenceAt(document, position);
		if (!target) {
			return [];
		}
		return extractReferences(document.getText())
			.filter(
				(item) =>
					item.kind === target.kind && item.name === target.name,
			)
			.map(
				(item) =>
					new vscode.DocumentHighlight(
						referenceRange(item),
						item.role === "definition"
							? vscode.DocumentHighlightKind.Write
							: vscode.DocumentHighlightKind.Read,
					),
			);
	}
}

class FormattingProvider implements vscode.DocumentFormattingEditProvider {
	provideDocumentFormattingEdits(
		document: vscode.TextDocument,
	): vscode.TextEdit[] {
		const configuration = vscode.workspace.getConfiguration(
			"konado.format",
			document.uri,
		);
		const style = configuration.get<string>("indentStyle", "tab");
		const size = configuration.get<number>("indentSize", 4);
		const indent = style === "space" ? " ".repeat(size) : "\t";
		const formatted = formatSource(document.getText(), indent);
		if (formatted === document.getText()) {
			return [];
		}
		const end = document.positionAt(document.getText().length);
		return [
			vscode.TextEdit.replace(
				new vscode.Range(new vscode.Position(0, 0), end),
				formatted,
			),
		];
	}
}

class CodeActionProvider implements vscode.CodeActionProvider {
	constructor(private readonly diagnostics: DiagnosticManager) {}

	provideCodeActions(
		document: vscode.TextDocument,
		range: vscode.Range,
		context: vscode.CodeActionContext,
	): vscode.CodeAction[] {
		const actions: vscode.CodeAction[] = [];
		for (const spec of this.diagnostics.getSpecs(document.uri)) {
			const diagnostic = context.diagnostics.find(
				(item) =>
					item.source === "KonadoScript" &&
					item.code === spec.code &&
					item.range.start.line === spec.line &&
					item.range.start.character === spec.start,
			);
			if (
				!diagnostic ||
				!diagnostic.range.intersection(range) ||
				!spec.fixes
			) {
				continue;
			}
			for (const fix of spec.fixes.slice(0, 3)) {
				const action = new vscode.CodeAction(
					isChineseUi() ? fix.titleZh : fix.title,
					vscode.CodeActionKind.QuickFix,
				);
				action.diagnostics = [diagnostic];
				action.isPreferred = fix.preferred;
				action.edit = new vscode.WorkspaceEdit();
				for (const edit of fix.edits) {
					action.edit.replace(
						document.uri,
						new vscode.Range(
							edit.line,
							edit.start,
							edit.line,
							edit.end,
						),
						edit.newText,
					);
				}
				actions.push(action);
			}
		}
		return actions;
	}
}

function referenceAt(
	document: vscode.TextDocument,
	position: vscode.Position,
): SymbolReference | undefined {
	return referencesForLine(
		document.lineAt(position.line).text,
		position.line,
		isScreenTextContent(document, position.line),
	).find(
		(item) =>
			position.character >= item.start && position.character <= item.end,
	);
}

function isScreenTextContent(
	document: vscode.TextDocument,
	targetLine: number,
): boolean {
	let inside = false;
	for (let line = 0; line <= targetLine; line += 1) {
		if (line === targetLine) {
			return inside;
		}
		const content = splitCodeAndComment(
			document.lineAt(line).text,
		).code.trim();
		if (
			!inside &&
			content.startsWith("screentext") &&
			content.endsWith("{")
		) {
			inside = true;
		} else if (inside && tokenizeLine(content)[0]?.text === "}") {
			inside = false;
		}
	}
	return false;
}

function localDefinitions(
	document: vscode.TextDocument,
	target: SymbolReference,
): IndexedDefinition[] {
	return extractReferences(document.getText())
		.filter(
			(item) =>
				item.kind === target.kind &&
				item.name === target.name &&
				item.role === "definition",
		)
		.map((item) => ({
			...item,
			uri: document.uri.toString(),
			targetUri: document.uri.toString(),
		}));
}

function toLocation(definition: IndexedDefinition): vscode.Location {
	const uri = vscode.Uri.parse(definition.targetUri ?? definition.uri);
	const line =
		definition.targetUri && definition.targetUri !== definition.uri
			? 0
			: definition.line;
	const start =
		definition.targetUri && definition.targetUri !== definition.uri
			? 0
			: definition.start;
	const end =
		definition.targetUri && definition.targetUri !== definition.uri
			? 1
			: definition.end;
	return new vscode.Location(uri, new vscode.Range(line, start, line, end));
}

function referenceRange(reference: SymbolReference): vscode.Range {
	return new vscode.Range(
		reference.line,
		reference.start,
		reference.line,
		reference.end,
	);
}

function tokenRange(
	line: number,
	token: ReturnType<typeof tokenizeLine>[number],
): vscode.Range {
	return new vscode.Range(line, token.start, line, token.end);
}

async function referenceDocuments(
	current: vscode.TextDocument,
	target: SymbolReference,
): Promise<vscode.TextDocument[]> {
	if (
		target.kind === "branches" ||
		(target.kind === "variables" && target.name.startsWith("$"))
	) {
		return [current];
	}
	const uris = await vscode.workspace.findFiles(
		"**/*.ks",
		"**/{.git,.godot,node_modules,build,dist}/**",
	);
	return Promise.all(
		uris.map(async (uri) => {
			const open = vscode.workspace.textDocuments.find(
				(document) => document.uri.toString() === uri.toString(),
			);
			return open ?? vscode.workspace.openTextDocument(uri);
		}),
	);
}

function documentSymbols(
	document: vscode.TextDocument,
	kind: SymbolKind,
): string[] {
	return [
		...new Set(
			extractReferences(document.getText())
				.filter((reference) => reference.kind === kind)
				.map((reference) => reference.name),
		),
	].sort((left, right) => left.localeCompare(right));
}

function filterCompletions(
	items: vscode.CompletionItem[],
	partial: string,
): vscode.CompletionItem[] {
	if (!partial) {
		return items;
	}
	const normalized = partial.toLocaleLowerCase();
	return items.filter((item) =>
		String(item.label).toLocaleLowerCase().includes(normalized),
	);
}

function completionKind(
	root: string,
	argumentIndex: number,
): vscode.CompletionItemKind {
	if (argumentIndex === 1 && root in CONTEXT_KEYWORDS) {
		return vscode.CompletionItemKind.Keyword;
	}
	if (["jump_branch", "call", "choice", "branch"].includes(root)) {
		return vscode.CompletionItemKind.Reference;
	}
	if (["set", "add", "sub", "mul", "div", "if"].includes(root)) {
		return vscode.CompletionItemKind.Variable;
	}
	if (root === "jump") {
		return vscode.CompletionItemKind.File;
	}
	return vscode.CompletionItemKind.Value;
}

function symbolKind(kind: SymbolKind): vscode.SymbolKind {
	return (
		{
			actors: vscode.SymbolKind.Class,
			states: vscode.SymbolKind.Property,
			motions: vscode.SymbolKind.Method,
			backgrounds: vscode.SymbolKind.Object,
			bgms: vscode.SymbolKind.File,
			sfx: vscode.SymbolKind.File,
			voices: vscode.SymbolKind.File,
			cameras: vscode.SymbolKind.Object,
			branches: vscode.SymbolKind.Namespace,
			variables: vscode.SymbolKind.Variable,
			signals: vscode.SymbolKind.Event,
			achievements: vscode.SymbolKind.Key,
			scripts: vscode.SymbolKind.File,
		} satisfies Record<SymbolKind, vscode.SymbolKind>
	)[kind];
}

function semanticType(kind: SymbolKind): number {
	const name = {
		actors: "class",
		states: "property",
		motions: "property",
		backgrounds: "property",
		bgms: "property",
		sfx: "property",
		voices: "property",
		cameras: "property",
		branches: "label",
		variables: "variable",
		signals: "event",
		achievements: "property",
		scripts: "property",
	} satisfies Record<SymbolKind, string>;
	return SEMANTIC_LEGEND.tokenTypes.indexOf(name[kind]);
}

function displayPath(uri: string): string {
	const parsed = vscode.Uri.parse(uri);
	return vscode.workspace.asRelativePath(parsed, false);
}
