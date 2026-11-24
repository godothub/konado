import * as path from "node:path";
import * as vscode from "vscode";
import {
	extractReferences,
	type IndexedDefinition,
	type ProjectSnapshot,
	type SymbolKind,
} from "./language";

const RESOURCE_SCHEMAS = {
	actors: { name: "character_id", target: "character_scene" },
	backgrounds: { name: "background_name", target: "background_scene" },
	bgms: { name: "background_music_name", target: "stream" },
	sfx: { name: "sound_effect_name", target: "stream" },
	voices: { name: "voice_name", target: "stream" },
} as const;

const SCANNED_GLOB = "**/*.{ks,tres,tscn,gd}";
const EXCLUDED_GLOB = "**/{.git,.godot,node_modules,build,dist}/**";
const MAX_RESOURCE_BYTES = 8 * 1024 * 1024;

interface InternalDefinition extends IndexedDefinition {
	targetResourcePath?: string;
	motionResourcePath?: string;
}

export class ProjectIndex implements ProjectSnapshot, vscode.Disposable {
	private readonly byKind = new Map<
		SymbolKind,
		Map<string, InternalDefinition[]>
	>();
	private readonly indexedUris = new Set<string>();
	private readonly changeEmitter = new vscode.EventEmitter<void>();
	private readonly watchers: vscode.Disposable[] = [];
	private rebuildPromise: Promise<void> | undefined;
	private rebuildTimer: NodeJS.Timeout | undefined;

	readonly onDidChange = this.changeEmitter.event;

	constructor(private readonly output: vscode.OutputChannel) {
		const watcher = vscode.workspace.createFileSystemWatcher(SCANNED_GLOB);
		watcher.onDidCreate(() => this.scheduleRebuild());
		watcher.onDidChange(() => this.scheduleRebuild());
		watcher.onDidDelete(() => this.scheduleRebuild());
		this.watchers.push(watcher);
	}

	dispose(): void {
		if (this.rebuildTimer) {
			clearTimeout(this.rebuildTimer);
		}
		this.watchers.forEach((watcher) => watcher.dispose());
		this.changeEmitter.dispose();
	}

	definitions(kind: SymbolKind, name?: string): readonly IndexedDefinition[] {
		const values = this.byKind.get(kind);
		if (!values) {
			return [];
		}
		if (name !== undefined) {
			return values.get(name) ?? [];
		}
		return [...values.values()].flat();
	}

	values(kind: SymbolKind, scopeName?: string): readonly string[] {
		const definitions = this.byKind.get(kind);
		if (!definitions) {
			return [];
		}
		return [...definitions.entries()]
			.filter(([, items]) => {
				if (!scopeName) {
					return true;
				}
				return items.some(
					(item) => !item.scopeName || item.scopeName === scopeName,
				);
			})
			.map(([name]) => name)
			.sort((left, right) => left.localeCompare(right));
	}

	hasUri(uri: string): boolean {
		return this.indexedUris.has(uri);
	}

	async rebuild(): Promise<void> {
		if (this.rebuildPromise) {
			return this.rebuildPromise;
		}
		this.rebuildPromise = this.performRebuild().finally(() => {
			this.rebuildPromise = undefined;
		});
		return this.rebuildPromise;
	}

	scheduleRebuild(): void {
		if (this.rebuildTimer) {
			clearTimeout(this.rebuildTimer);
		}
		this.rebuildTimer = setTimeout(() => {
			this.rebuildTimer = undefined;
			void this.rebuild();
		}, 250);
	}

	updateDocument(document: vscode.TextDocument): void {
		if (document.languageId !== "konadoscript") {
			return;
		}
		const uri = document.uri.toString();
		this.removeUri(uri);
		this.indexScript(document.uri, document.getText());
		this.rebuildScopes();
		this.changeEmitter.fire();
	}

	resolveResourceUri(
		documentUri: vscode.Uri,
		resourcePath: string,
	): vscode.Uri | undefined {
		if (!resourcePath.startsWith("res://")) {
			return undefined;
		}
		const folder = vscode.workspace.getWorkspaceFolder(documentUri);
		if (!folder) {
			return undefined;
		}
		return vscode.Uri.joinPath(
			folder.uri,
			resourcePath.slice("res://".length),
		);
	}

	private async performRebuild(): Promise<void> {
		const enabled = vscode.workspace
			.getConfiguration("konado")
			.get<boolean>("projectIndex.enable", true);
		this.byKind.clear();
		this.indexedUris.clear();
		if (!enabled || !vscode.workspace.workspaceFolders?.length) {
			this.changeEmitter.fire();
			return;
		}

		const started = Date.now();
		const uris = await vscode.workspace.findFiles(
			SCANNED_GLOB,
			EXCLUDED_GLOB,
		);
		const sources = new Map<string, string>();
		await Promise.all(
			uris.map(async (uri) => {
				try {
					const stat = await vscode.workspace.fs.stat(uri);
					if (stat.size > MAX_RESOURCE_BYTES) {
						return;
					}
					const bytes = await vscode.workspace.fs.readFile(uri);
					const source = new TextDecoder("utf-8").decode(bytes);
					sources.set(uri.toString(), source);
				} catch (error) {
					this.output.appendLine(
						`Unable to index ${uri.toString()}: ${String(error)}`,
					);
				}
			}),
		);
		for (const uri of uris) {
			const source = sources.get(uri.toString());
			if (source === undefined) {
				continue;
			}
			if (uri.path.endsWith(".ks")) {
				this.indexScript(uri, source);
			} else if (
				uri.path.endsWith(".tres") ||
				uri.path.endsWith(".tscn")
			) {
				this.indexGodotResource(uri, source, sources);
			}
		}
		for (const document of vscode.workspace.textDocuments) {
			if (document.languageId === "konadoscript" && document.isDirty) {
				this.removeUri(document.uri.toString());
				this.indexScript(document.uri, document.getText());
			}
		}
		this.rebuildScopes();
		this.output.appendLine(
			`Indexed ${uris.length} Konado project files in ${Date.now() - started} ms.`,
		);
		this.changeEmitter.fire();
	}

	private indexScript(uri: vscode.Uri, source: string): void {
		const uriText = uri.toString();
		this.indexedUris.add(uriText);
		this.add({
			kind: "scripts",
			name: this.toResourcePath(uri),
			uri: uriText,
			line: 0,
			start: 0,
			end: 1,
			targetUri: uriText,
		});
		for (const item of extractReferences(source)) {
			if (
				item.role !== "definition" &&
				item.kind !== "variables" &&
				item.kind !== "achievements"
			) {
				continue;
			}
			this.add({
				kind: item.kind,
				name: item.name,
				uri: uriText,
				line: item.line,
				start: item.start,
				end: item.end,
				targetUri: uriText,
			});
		}
	}

	private indexGodotResource(
		uri: vscode.Uri,
		source: string,
		sources: ReadonlyMap<string, string>,
	): void {
		const uriText = uri.toString();
		this.indexedUris.add(uriText);
		const externalResources = collectExternalResources(source);
		const blocks = collectBlocks(source);
		for (const block of blocks) {
			for (const [kind, schema] of Object.entries(RESOURCE_SCHEMAS) as [
				keyof typeof RESOURCE_SCHEMAS,
				(typeof RESOURCE_SCHEMAS)[keyof typeof RESOURCE_SCHEMAS],
			][]) {
				const name = findProperty(block.source, schema.name);
				if (!name) {
					continue;
				}
				const targetResourcePath = resolvePropertyTarget(
					block.source,
					schema.target,
					externalResources,
				);
				const motionResourcePath =
					kind === "actors"
						? resolvePropertyTarget(
								block.source,
								"actor_motion_layer",
								externalResources,
							)
						: undefined;
				this.add({
					kind,
					name: name.value,
					uri: uriText,
					line: lineAt(source, block.start + name.start),
					start: name.column,
					end: name.column + name.value.length,
					targetUri: targetResourcePath
						? this.resolveResourceUri(
								uri,
								targetResourcePath,
							)?.toString()
						: undefined,
					targetResourcePath,
					motionResourcePath,
				});
			}

			const scriptPath = resolvePropertyTarget(
				block.source,
				"script",
				externalResources,
			);
			const scriptSource = scriptPath
				? sources.get(
						this.resolveResourceUri(uri, scriptPath)?.toString() ??
							"",
					)
				: undefined;
			const state =
				findProperty(block.source, "status_name") ??
				findScriptDefault(scriptSource, "status_name");
			if (state) {
				this.add({
					kind: "states",
					name: state.value,
					uri: uriText,
					line: lineAt(source, block.start + state.start),
					start: state.column,
					end: state.column + state.value.length,
					targetUri: uriText,
				});
			}
			const camera =
				findProperty(block.source, "camera_setup") ??
				findScriptDefault(scriptSource, "camera_setup");
			if (camera) {
				this.add({
					kind: "cameras",
					name: camera.value,
					uri: uriText,
					line: lineAt(source, block.start + camera.start),
					start: camera.column,
					end: camera.column + camera.value.length,
					targetUri: uriText,
				});
			}
		}

		if (uri.path.endsWith(".tres")) {
			this.indexAudioEvents(uri, uriText, source, externalResources);
		}

		if (uri.path.endsWith(".tscn")) {
			this.collectPatternDefinitions(
				uri,
				source,
				"states",
				/"name"\s*:\s*&?"([^"]+)"/gu,
			);
			this.collectPatternDefinitions(
				uri,
				source,
				"motions",
				/^\s*resource_name\s*=\s*"([^"]+)"/gmu,
			);
		}
	}

	/**
	 * Index KonadoAudioEvent resources by bus so `play bgm <id>` resolves to the
	 * event (and its first stream) instead of only legacy resource lists.
	 */
	private indexAudioEvents(
		uri: vscode.Uri,
		uriText: string,
		source: string,
		externalResources: ReadonlyMap<string, string>,
	): void {
		if (!source.includes("KonadoAudioEvent")) {
			return;
		}
		for (const block of collectBlocks(source)) {
			const id = findStringNameProperty(block.source, "id");
			if (!id) {
				continue;
			}
			const bus =
				findStringNameProperty(block.source, "bus")?.value ?? "SFX";
			const kind: SymbolKind =
				bus === "Music" || bus === "Ambience"
					? "bgms"
					: bus === "Voice"
						? "voices"
						: "sfx";
			const targetResourcePath = resolveFirstExtResource(
				block.source,
				"streams",
				externalResources,
			);
			this.add({
				kind,
				name: id.value,
				uri: uriText,
				line: lineAt(source, block.start + id.start),
				start: id.column,
				end: id.column + id.value.length,
				targetUri: targetResourcePath
					? this.resolveResourceUri(
							uri,
							targetResourcePath,
						)?.toString()
					: undefined,
				targetResourcePath,
			});
		}
	}

	private collectPatternDefinitions(
		uri: vscode.Uri,
		source: string,
		kind: SymbolKind,
		pattern: RegExp,
	): void {
		for (const match of source.matchAll(pattern)) {
			const name = match[1];
			if (!name) {
				continue;
			}
			const offset = (match.index ?? 0) + match[0].indexOf(name);
			const line = lineAt(source, offset);
			const lineStart = source.lastIndexOf("\n", offset - 1) + 1;
			this.add({
				kind,
				name,
				uri: uri.toString(),
				line,
				start: offset - lineStart,
				end: offset - lineStart + name.length,
				targetUri: uri.toString(),
			});
		}
	}

	private rebuildScopes(): void {
		const actors = this.definitions("actors") as InternalDefinition[];
		const actorByTarget = new Map<string, string>();
		const actorByMotion = new Map<string, string>();
		for (const actor of actors) {
			if (actor.targetResourcePath) {
				actorByTarget.set(
					this.resolveResourceUri(
						vscode.Uri.parse(actor.uri),
						actor.targetResourcePath,
					)?.toString() ?? "",
					actor.name,
				);
			}
			if (actor.motionResourcePath) {
				actorByMotion.set(
					this.resolveResourceUri(
						vscode.Uri.parse(actor.uri),
						actor.motionResourcePath,
					)?.toString() ?? "",
					actor.name,
				);
			}
		}
		for (const definition of this.definitions(
			"states",
		) as InternalDefinition[]) {
			definition.scopeName = actorByTarget.get(definition.uri);
		}
		for (const definition of this.definitions(
			"motions",
		) as InternalDefinition[]) {
			definition.scopeName = actorByMotion.get(definition.uri);
		}
	}

	private add(definition: InternalDefinition): void {
		let names = this.byKind.get(definition.kind);
		if (!names) {
			names = new Map();
			this.byKind.set(definition.kind, names);
		}
		const definitions = names.get(definition.name) ?? [];
		if (
			definitions.some(
				(item) =>
					item.uri === definition.uri &&
					item.line === definition.line &&
					item.start === definition.start,
			)
		) {
			return;
		}
		definitions.push(definition);
		names.set(definition.name, definitions);
	}

	private removeUri(uri: string): void {
		for (const names of this.byKind.values()) {
			for (const [name, definitions] of names) {
				const remaining = definitions.filter(
					(definition) => definition.uri !== uri,
				);
				if (remaining.length === 0) {
					names.delete(name);
				} else {
					names.set(name, remaining);
				}
			}
		}
		this.indexedUris.delete(uri);
	}

	private toResourcePath(uri: vscode.Uri): string {
		const folder = vscode.workspace.getWorkspaceFolder(uri);
		if (!folder) {
			return uri.path;
		}
		const relative = path.posix.relative(folder.uri.path, uri.path);
		return `res://${relative}`;
	}
}

function collectExternalResources(source: string): Map<string, string> {
	const resources = new Map<string, string>();
	const pattern = /^\[ext_resource[^\]]*\]$/gmu;
	for (const match of source.matchAll(pattern)) {
		const header = match[0];
		const id = /\bid="([^"]+)"/u.exec(header)?.[1];
		const resourcePath = /\bpath="([^"]+)"/u.exec(header)?.[1];
		if (id && resourcePath) {
			resources.set(id, resourcePath);
		}
	}
	return resources;
}

function collectBlocks(source: string): { start: number; source: string }[] {
	const headers = [
		...source.matchAll(/^\[(?:sub_resource|resource|node)[^\]]*\]$/gmu),
	];
	return headers.map((header, index) => {
		const start = (header.index ?? 0) + header[0].length;
		const end = headers[index + 1]?.index ?? source.length;
		return { start, source: source.slice(start, end) };
	});
}

function findProperty(
	source: string,
	property: string,
): { value: string; start: number; column: number } | undefined {
	const pattern = new RegExp(`^\\s*${property}\\s*=\\s*"([^"]+)"`, "mu");
	const match = pattern.exec(source);
	const value = match?.[1];
	if (!match || !value) {
		return undefined;
	}
	const start = match.index + match[0].lastIndexOf(value);
	const lineStart = source.lastIndexOf("\n", start - 1) + 1;
	return { value, start, column: start - lineStart };
}

function findScriptDefault(
	source: string | undefined,
	property: string,
): { value: string; start: number; column: number } | undefined {
	if (!source) {
		return undefined;
	}
	const pattern = new RegExp(
		`^\\s*(?:@export(?:_[A-Za-z0-9_]+)?(?:\\([^\\n]*\\))?\\s+)?var\\s+${property}\\s*(?::[^=\\n]+)?=\\s*"([^"]*)"`,
		"mu",
	);
	const value = pattern.exec(source)?.[1];
	if (!value) {
		return undefined;
	}
	return { value, start: 0, column: 0 };
}

/** `id = &"echo"` uses StringName syntax, so accept an optional leading `&`. */
function findStringNameProperty(
	source: string,
	property: string,
): { value: string; start: number; column: number } | undefined {
	const pattern = new RegExp(`^\\s*${property}\\s*=\\s*&?"([^"]+)"`, "mu");
	const match = pattern.exec(source);
	const value = match?.[1];
	if (!match || !value) {
		return undefined;
	}
	const start = match.index + match[0].lastIndexOf(value);
	const lineStart = source.lastIndexOf("\n", start - 1) + 1;
	return { value, start, column: start - lineStart };
}

/** First external audio stream of an array property such as `streams`. */
function resolveFirstExtResource(
	source: string,
	property: string,
	resources: ReadonlyMap<string, string>,
): string | undefined {
	const pattern = new RegExp(
		`^\\s*${property}\\s*=\\s*[^\\n]*ExtResource\\("([^"]+)"\\)`,
		"mu",
	);
	const id = pattern.exec(source)?.[1];
	return id ? resources.get(id) : undefined;
}

function resolvePropertyTarget(
	source: string,
	property: string,
	resources: ReadonlyMap<string, string>,
): string | undefined {
	const pattern = new RegExp(
		`^\\s*${property}\\s*=\\s*ExtResource\\("([^"]+)"\\)`,
		"mu",
	);
	const id = pattern.exec(source)?.[1];
	return id ? resources.get(id) : undefined;
}

function lineAt(source: string, offset: number): number {
	return source.slice(0, Math.max(0, offset)).split("\n").length - 1;
}
