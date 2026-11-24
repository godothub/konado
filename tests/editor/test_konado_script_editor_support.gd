extends SceneTree

const SCRIPT_PATH := "res://tests/editor/fixtures/native_editor.ks"
const NAVIGATION_SCRIPT_PATH := "res://sample/demo/demo_03_variable.ks"
const INVALID_SCRIPT_PATH := "user://invalid_editor_document.ks"
const CARET_MARKER := "\uFFFF"
const SCRIPT_LINK_OVERLAY := preload(
	"res://addons/konado/editor/script_editor/konado_script_link_overlay.gd"
)

var _failures := 0
var _invalid_document: KonadoShot


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	if Engine.is_editor_hint():
		await EditorInterface.get_resource_filesystem().filesystem_changed
		await process_frame
		while (
			EditorInterface.get_resource_filesystem().is_scanning()
			or EditorInterface.get_resource_filesystem().is_importing()
		):
			await process_frame
	_test_language_catalog()
	_test_documentation_routes()
	_test_script_resource()
	_test_source_line_numbers()
	_test_language_validation()
	_test_language_completion_and_outline()
	_test_language_indent_lookup_and_hints()
	_test_project_resource_completion()
	_test_symbol_index()
	_test_invalid_source_document()
	_test_create_script_template()
	_test_script_tooltip_support()
	_test_source_saver()
	_test_highlighter_cache()
	_test_highlighter_lexical_boundaries()
	if Engine.is_editor_hint():
		await _test_native_script_editor()
		_test_branch_refactor_ui()
	if _failures == 0:
		print("PASS: KonadoScript editor support tests")
	await process_frame
	await process_frame
	quit(_failures)


func _test_language_catalog() -> void:
	_expect(
		KonadoScriptLanguageCatalog.validate_catalog().is_empty(),
		"language catalog contains only parser-supported keywords",
	)
	_expect(
		not KonadoScriptLanguageCatalog.ROOT_KEYWORDS.has("shot_id"),
		"obsolete shot_id is not suggested"
	)
	_expect(
		not KonadoScriptLanguageCatalog.ROOT_KEYWORDS.has("start"),
		"obsolete start is not suggested"
	)
	_expect(
		KonadoScriptLanguageCatalog.get_context_completions("play").has("sfx"),
		"audio completion uses the supported sfx keyword",
	)
	_expect(
		KonadoScriptLanguageCatalog.get_context_completions("actor").has("motion"),
		"actor motion is included in completion metadata",
	)
	_expect(
		(
			KonadoScriptLanguageCatalog.get_background_effects().size()
			== KonadoScriptProgramEmitter.BACKGROUND_EFFECTS_MAP.size()
		),
		"background effect completion uses the compiler source of truth",
	)
	var lexer := KonadoScriptLexer.new()
	var parser := KonadoScriptParser.new()
	lexer.console_output_enabled = false
	parser.console_output_enabled = false
	for snippet: Dictionary in KonadoScriptLanguageCatalog.SNIPPETS:
		var tokens := lexer.tokenize(snippet["snippet"], "editor-snippet-test.ks")
		_expect(
			parser.parse(tokens, "editor-snippet-test.ks") != null,
			"statement catalog snippet parses: %s" % snippet["label"],
		)


func _test_documentation_routes() -> void:
	_expect(
		(
			KonadoScriptEditorIntegration.get_docs_url("2.6.2", "zh_CN")
			== "https://godothub.com/oss/konado/zh/latest/"
		),
		"maintained Konado releases use the stable latest documentation route",
	)
	_expect(
		(
			KonadoScriptEditorIntegration.get_docs_url("2.4.9", "zh_CN")
			== "https://godothub.com/oss/konado/zh/2.4/"
		),
		"the supported LTS release keeps its versioned documentation route",
	)
	_expect(
		(
			KonadoScriptEditorIntegration.get_docs_url("2.6.2", "zh_Hant")
			== "https://godothub.com/oss/konado/tc/latest/"
		),
		"traditional Chinese editors open the matching documentation locale",
	)
	_expect(
		(
			(
				KonadoScriptEditorIntegration.get_docs_url("2.6.2", "ja_JP")
				== "https://godothub.com/oss/konado/ja/latest/"
			)
			and (
				KonadoScriptEditorIntegration.get_docs_url("2.6.2", "ko_KR")
				== "https://godothub.com/oss/konado/ko/latest/"
			)
			and (
				KonadoScriptEditorIntegration.get_docs_url("2.6.2", "fr_FR")
				== "https://godothub.com/oss/konado/en/latest/"
			)
		),
		"documentation URL resolves supported locales and falls back to English",
	)


func _test_script_resource() -> void:
	_expect(
		not FileAccess.file_exists(SCRIPT_PATH + ".import"),
		"KonadoScript source is not marked as a read-only imported resource",
	)
	var shot := ResourceLoader.load(SCRIPT_PATH) as KonadoShot
	_expect(shot != null, "KonadoScript files load as KonadoShot")
	if shot == null:
		return
	_expect(shot is ScriptExtension, "KonadoShot is a native Script Editor document")
	_expect(
		shot.resource_path == SCRIPT_PATH,
		"imported script keeps its source resource path: %s" % shot.resource_path,
	)
	_expect(
		shot._get_language()._get_name() == "KonadoScript",
		"KonadoShot exposes its language",
	)
	_expect(shot.source_path == SCRIPT_PATH, "imported script retains its source path")


func _test_source_line_numbers() -> void:
	var compiler := KonadoScriptCompiler.new()
	compiler.set_console_output_enabled(false)
	var shot := compiler.compile_string("unknown_command", "line-number-test.ks")
	_expect(shot == null, "invalid first-line command is rejected")
	_expect(
		not compiler.get_errors().is_empty() and "[行：1" in compiler.get_errors()[0],
		"first source line is reported as line 1",
	)


func _test_language_validation() -> void:
	var language := KonadoScriptLanguage.new()
	var result := (
		language
		. _validate(
			'if %love == 0:\n    "Kona" "Hello"\nendif_bad',
			"validation-test.ks",
			true,
			true,
			true,
			true,
		)
	)
	_expect(not result["valid"], "language bridge rejects invalid scripts")
	_expect(
		result["errors"].size() == 1 and result["errors"][0]["line"] == 3,
		"language bridge returns native Script Editor error positions",
	)
	result = (
		language
		. _validate(
			'jump_branch intro\nbranch intro\n\t"Kona" "Hello"',
			"validation-test.ks",
			true,
			true,
			true,
			true,
		)
	)
	_expect(result["valid"], "language bridge accepts valid scripts")
	_expect(
		result["functions"] == PackedStringArray(["intro:2"]),
		"branch declarations populate the native member outline",
	)


func _test_language_completion_and_outline() -> void:
	var language := KonadoScriptLanguage.new()
	var result := language._complete_code("actor %s" % CARET_MARKER, "completion.ks", null)
	_expect(
		_completion_displays(result).has("show"),
		"root command context offers actor subcommands",
	)
	result = (
		language
		. _complete_code(
			"branch intro\njump_branch in%s" % CARET_MARKER,
			"completion.ks",
			null,
		)
	)
	_expect(
		_completion_displays(result).has("intro"),
		"branch names are completed from the current document",
	)
	result = (
		language
		. _complete_code(
			"actor show Kona happy 5\nactor move Ko%s" % CARET_MARKER,
			"completion.ks",
			null,
		)
	)
	_expect(
		_completion_displays(result).has("Kona"),
		"actor names are completed from the current document",
	)
	result = language._complete_code("Ko%s" % CARET_MARKER, "completion.ks", null)
	_expect(
		_completion_displays(result).has("Kona"),
		"static dialogue actors are completed at the start of a line",
	)
	result = (
		language
		. _complete_code(
			'set $speaker "Kona"\n$sp%s' % CARET_MARKER,
			"completion.ks",
			null,
		)
	)
	_expect(
		_completion_displays(result).has("$speaker"),
		"speaker variables are completed at the start of a line",
	)
	result = language._complete_code('Kona "Hello" %s' % CARET_MARKER, "completion.ks", null)
	_expect(
		(
			_completion_displays(result).has("[speed=]")
			and _completion_displays(result).has("[interval=]")
			and _completion_displays(result).has("[id=]")
		),
		"dialogue completion exposes the registered KonadoScript 2.9 parameters",
	)
	result = (
		language
		. _complete_code(
			"actor show Kona happy at 3 %s" % CARET_MARKER,
			"completion.ks",
			null,
		)
	)
	_expect(
		(
			_completion_displays(result).has("[duration=]")
			and _completion_displays(result).has("[id=]")
		),
		"command completion derives named parameters from the compiler registry",
	)
	result = (
		language
		. _complete_code(
			"actor show Kona happy at 3 [duration=0.2] %s" % CARET_MARKER,
			"completion.ks",
			null,
		)
	)
	_expect(
		(
			not _completion_displays(result).has("[duration=]")
			and _completion_displays(result).has("[id=]")
		),
		"completion omits named parameters that are already present",
	)
	_expect(
		language._find_function("intro", "branch intro\njump_branch intro") == 0,
		"native symbol navigation resolves branch declarations",
	)
	var script_lookup := (
		language
		. _lookup_code(
			"jump res://sample/demo/demo_04_%schoice_branch.ks" % CARET_MARKER,
			"demo_04_choice_branch",
			"res://source.ks",
			null,
		)
	)
	_expect(
		(
			script_lookup.get("result") == OK
			and (
				script_lookup.get("type")
				== ScriptLanguageExtension.LookupResultType.LOOKUP_RESULT_SCRIPT_LOCATION
			)
			and script_lookup.get("script_path") == "res://sample/demo/demo_04_choice_branch.ks"
			and script_lookup.get("script") is KonadoShot
			and script_lookup.get("location") == 1
		),
		"Ctrl-click lookup returns the target KonadoScript resource for cross-file opening",
	)
	script_lookup = (
		language
		. _lookup_code(
			"jump res://missing/%sscript.ks" % CARET_MARKER,
			"script",
			"res://source.ks",
			null,
		)
	)
	_expect(
		script_lookup.get("result") == ERR_UNAVAILABLE,
		"Ctrl-click lookup never advertises a missing KonadoScript target",
	)


func _test_language_indent_lookup_and_hints() -> void:
	var language := KonadoScriptLanguage.new()
	var unindented := 'if %love == 0:\n"Kona" "Hello"\nelse:\nscreentext {\n"Fallback"\n}\nendif'
	var expected := (
		'if %love == 0:\n\t"Kona" "Hello"\nelse:\n\tscreentext {\n' + '\t\t"Fallback"\n\t}\nendif'
	)
	var indented := language._auto_indent_code(unindented, 0, 6)
	_expect(
		indented == expected,
		"automatic indentation handles nested conditions, else blocks, and screentext",
	)
	var source := "branch intro\njump_branch intro"
	var lookup := language._lookup_code(source, "intro", "res://lookup.ks", null)
	_expect(
		(
			lookup.get("result") == OK
			and lookup.get("location") == 1
			and lookup.get("script_path") == "res://lookup.ks"
		),
		"hover/navigation lookup resolves a branch declaration",
	)
	var completion := (
		language
		. _complete_code(
			"actor show %s" % CARET_MARKER,
			"completion.ks",
			null,
		)
	)
	var call_hint := String(completion.get("call_hint", ""))
	_expect(
		(
			(
				"actor show <actor_name> <state_name>"
				in call_hint.replace(language.CALL_HINT_MARKER, "")
			)
			and call_hint.count(language.CALL_HINT_MARKER) == 2
			and (
				(language.CALL_HINT_MARKER + "<actor_name>" + language.CALL_HINT_MARKER)
				in call_hint
			)
		),
		"completion displays the contextual command signature",
	)
	var root_call_hint := String(
		(
			language
			. _complete_code("actor%s" % CARET_MARKER, "completion.ks", null)
			. get(
				"call_hint",
				"",
			)
		)
	)
	_expect(
		(
			(
				language.CALL_HINT_MARKER
				+ "<show|exit|change|move|motion>"
				+ language.CALL_HINT_MARKER
			)
			in root_call_hint
		),
		"completion anchors root signatures to the active argument at the line start",
	)
	completion = language._complete_code("ac%s" % CARET_MARKER, "completion.ks", null)
	_expect(
		_completion_insertions(completion).has('achievement unlock "achievement_id"'),
		"root completion includes insertable command snippets",
	)


func _test_project_resource_completion() -> void:
	var language := KonadoScriptLanguage.new()
	var cases := [
		{"source": "background bg_%s", "expected": "bg_para"},
		{"source": "play bgm ec%s", "expected": "echo"},
		{"source": "actor show Ko%s", "expected": "Kona"},
		{"source": "actor show Kona 正%s", "expected": "正常"},
		{"source": "actor motion Kona ju%s", "expected": "jump"},
		{"source": "asyncam move ca%s", "expected": "cam2"},
		{"source": "jump res://sample/demo/demo_0%s", "expected": "res://sample/demo/demo_02.ks"},
	]
	for test_case: Dictionary in cases:
		var result := (
			language
			. _complete_code(
				test_case["source"] % CARET_MARKER,
				"completion.ks",
				null,
			)
		)
		_expect(
			_completion_displays(result).has(test_case["expected"]),
			"project resource completion offers %s" % test_case["expected"],
		)
	var voice_result := (
		language
		. _complete_code(
			'"Kona" "Hello world" vo%s' % CARET_MARKER,
			"completion.ks",
			null,
		)
	)
	_expect(
		_completion_displays(voice_result).has("voice_01"),
		"dialogue voice completion handles quoted text containing spaces",
	)
	var parameter_result := (
		language
		. _complete_code(
			'Kona "Hello world" [speed=%s' % CARET_MARKER,
			"completion.ks",
			null,
		)
	)
	_expect(
		not _completion_displays(parameter_result).has("voice_01"),
		"named dialogue parameters are not completed as voice resources",
	)


func _test_symbol_index() -> void:
	var source := (
		"branch intro\n"
		+ 'choice "Go" -> intro\n'
		+ "jump_branch intro\n"
		+ '"Kona" "intro"\n'
		+ "# intro\n"
	)
	var references := KonadoScriptSymbolIndex.get_branch_references(source)
	_expect(references.size() == 3, "branch reference query ignores dialogue text and comments")
	var renamed := KonadoScriptSymbolIndex.rename_branch(source, "intro", "opening-scene")
	_expect(
		(
			"branch opening-scene" in renamed
			and "jump_branch opening-scene" in renamed
			and '"Kona" "intro"' in renamed
			and "# intro" in renamed
		),
		"branch rename changes only structural declarations and references",
	)
	_expect(
		KonadoScriptSymbolIndex.find_branch_definition(renamed, "opening-scene") == 1,
		"branch identifiers ending in non-word characters remain navigable",
	)
	var jump_line := "jump res://sample/demo/demo_04_choice_branch.ks"
	var jump_span := KonadoScriptSymbolIndex.find_script_jump_span(
		jump_line, jump_line.find("sample")
	)
	_expect(
		(
			jump_span.get("path") == "res://sample/demo/demo_04_choice_branch.ks"
			and jump_span.get("start") == jump_line.find("res://")
			and jump_span.get("end") == jump_line.length()
		),
		"script jump links cover the complete res:// path",
	)
	_expect(
		KonadoScriptSymbolIndex.find_script_jump_span(jump_line, jump_line.find("jump")).is_empty(),
		"script jump links do not extend over the command keyword",
	)
	var local_source := (
		"set $score 0\n"
		+ "add $score 1\n"
		+ "if $score >= 1:\n"
		+ "endif\n"
		+ "signal scene_ready\n"
		+ "waitsignal scene_ready"
	)
	_expect(
		(
			KonadoScriptSymbolIndex.find_local_definition(local_source, "variables", "$score") == 1
			and (
				(
					KonadoScriptSymbolIndex
					. get_local_symbol_references(
						local_source,
						"variables",
						"$score",
					)
					. size()
				)
				== 3
			)
			and (
				KonadoScriptSymbolIndex.find_local_definition(
					local_source, "signals", "scene_ready"
				)
				== 5
			)
		),
		"variables and signals expose declarations and references",
	)
	var renamed_local := (
		KonadoScriptSymbolIndex
		. rename_local_symbol(
			local_source,
			"variables",
			"$score",
			"$points",
		)
	)
	_expect(
		"$score" not in renamed_local and renamed_local.count("$points") == 3,
		"local variable rename updates only semantic references",
	)
	var dialogue_references := KonadoScriptSymbolIndex.get_line_semantic_references(
		'Kona "Hello" [speed=2.0] [id=intro]'
	)
	_expect(
		dialogue_references.all(func(item: Dictionary) -> bool: return item["kind"] != "voices"),
		"named dialogue parameters are not indexed as voice resources",
	)


func _test_invalid_source_document() -> void:
	var source := "endif_invalid"
	var file := FileAccess.open(INVALID_SCRIPT_PATH, FileAccess.WRITE)
	file.store_string(source)
	file.close()
	var loaded: Variant = (
		KonadoScriptResourceLoader
		. new()
		. _load(
			INVALID_SCRIPT_PATH,
			INVALID_SCRIPT_PATH,
			false,
			0,
		)
	)
	_expect(loaded is KonadoShot, "invalid KonadoScript remains an editable script document")
	if loaded is KonadoShot:
		_expect(loaded.get_source_code() == source, "invalid editor document preserves its source")
		_invalid_document = loaded


func _test_create_script_template() -> void:
	var source := KonadoScriptCreateMenu.new()._get_template()
	var compiler := KonadoScriptCompiler.new()
	compiler.set_console_output_enabled(false)
	_expect(
		compiler.compile_string(source, "new-script-template.ks") != null,
		"FileSystem create menu produces a valid KonadoScript template",
	)


func _test_script_tooltip_support() -> void:
	var tooltip := (
		preload("res://addons/konado/editor/script_editor/konado_script_tooltip_plugin.gd").new()
	)
	_expect(tooltip._handles("Script"), "KonadoScript retains its FileSystem tooltip")


func _test_source_saver() -> void:
	var path := "user://konado_script_source_saver.ks"
	var shot := KonadoShot.new()
	shot.source_path = path
	shot.set_source_code('jump_branch saved\n\nbranch saved\n\t"Kona" "Saved"\n')
	_expect(ResourceSaver.save(shot, path) == OK, "source saver writes .ks files")
	var file := FileAccess.open(path, FileAccess.READ)
	_expect(
		file != null and file.get_as_text() == shot.get_source_code(),
		"source saver preserves the complete editor buffer",
	)
	_expect(
		shot.program != null and shot.program.is_valid(),
		"source saver refreshes the compiled Program after a valid save",
	)
	shot.set_source_code("endif_invalid")
	_expect(ResourceSaver.save(shot, path) == OK, "invalid editor source can still be saved")
	_expect(
		_read_text(path) == "endif_invalid",
		"invalid save preserves the exact source for repair",
	)
	_expect(
		shot.program == null,
		"invalid save cannot leave a stale executable Program attached to new source",
	)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _test_highlighter_cache() -> void:
	var highlighter := KonadoScriptSyntaxHighlighter.new()
	_expect(
		highlighter._get_supported_languages() == PackedStringArray(["KonadoScript"]),
		"syntax highlighter targets the KonadoScript language",
	)
	var first_count := highlighter.get_compiled_rule_count()
	var second_count := highlighter.get_compiled_rule_count()
	_expect(first_count > 0, "syntax highlighter compiles rules")
	_expect(first_count == second_count, "syntax highlighter reuses compiled rules")


func _test_highlighter_lexical_boundaries() -> void:
	var highlighter := KonadoScriptSyntaxHighlighter.new()
	var line := '"Kona" "C# and \\"#\\" stay text" # actual comment'
	var highlighting := highlighter._highlight_line_text(line, Color.WHITE)
	var string_hash := line.find("#")
	var comment_hash := line.rfind("#")
	_expect(
		(
			_color_at(highlighting, string_hash, Color.WHITE)
			== KonadoScriptSyntaxHighlighter.STRING_COLOR
		),
		"comment markers inside strings retain string highlighting",
	)
	_expect(
		(
			_color_at(highlighting, comment_hash, Color.WHITE)
			== KonadoScriptSyntaxHighlighter.COMMENT_COLOR
		),
		"comment markers outside strings begin comment highlighting",
	)
	var parameter_line := 'Kona "Fast" [speed=1.5]'
	var parameter_highlighting := highlighter._highlight_line_text(parameter_line, Color.WHITE)
	_expect(
		(
			_color_at(parameter_highlighting, parameter_line.find("speed"), Color.WHITE)
			== KonadoScriptSyntaxHighlighter.SUBCOMMAND_COLOR
		),
		"KonadoScript 2.9 named parameters receive semantic highlighting",
	)
	var unterminated_line := '"unfinished # still string'
	var unterminated_highlighting := highlighter._highlight_line_text(
		unterminated_line, Color.WHITE
	)
	_expect(
		(
			_color_at(unterminated_highlighting, unterminated_line.find("#"), Color.WHITE)
			== KonadoScriptSyntaxHighlighter.STRING_COLOR
		),
		"unterminated strings do not leak comment highlighting",
	)


func _test_native_script_editor() -> void:
	await process_frame
	await process_frame
	_expect(
		EditorInterface.get_resource_filesystem().get_file_type(SCRIPT_PATH) == "Script",
		"FileSystem advertises KonadoScript as a Script resource",
	)
	var shot := ResourceLoader.load(SCRIPT_PATH) as KonadoShot
	if shot == null:
		_expect(false, "native editor test can load the imported script")
		return
	EditorInterface.edit_script(shot)
	await process_frame
	await process_frame
	await create_timer(0.15).timeout
	await process_frame
	await process_frame
	await process_frame
	var script_editor := EditorInterface.get_script_editor()
	var editor := script_editor.get_current_editor()
	_expect(editor != null, "double-click target opens in Godot's Script workspace")
	if editor == null:
		return
	var code_edit := editor.get_base_editor() as CodeEdit
	_expect(code_edit != null, "native Script Editor exposes its CodeEdit")
	var palette := script_editor.find_child("KonadoInstructionPalette", true, false) as Control
	var palette_title := script_editor.find_child("InstructionPaletteTitle", true, false) as Label
	var palette_toggle := (
		script_editor.find_child("InstructionPaletteToggle", true, false) as CheckButton
	)
	var instruction_tree := script_editor.find_child("InstructionTree", true, false) as Tree
	var docs_button := script_editor.find_child("KonadoOnlineDocs", true, false) as Button
	var jump_link_overlay := (
		code_edit.find_child("KonadoJumpLinkOverlay", false, false) as SCRIPT_LINK_OVERLAY
	)
	var godot_docs_button: Button
	var godot_help_button: Button
	_expect(
		palette != null and palette.visible,
		"KonadoScript replaces the upper document list with the instruction palette",
	)
	_expect(
		instruction_tree != null and instruction_tree.get_root() != null,
		"the native Script Editor displays the complete component and command tree",
	)
	_expect(
		palette_title != null and not palette_title.text.is_empty(),
		"the component and command region has a visible title",
	)
	_expect(
		palette_toggle != null and palette_toggle.button_pressed,
		"the palette header provides an enabled sliding expansion toggle",
	)
	if palette_toggle != null and instruction_tree != null:
		palette_toggle.set_pressed_no_signal(false)
		palette_toggle.toggled.emit(false)
		_expect(
			_all_top_level_groups_collapsed(instruction_tree),
			"disabling the palette toggle retains and collapses all top-level groups",
		)
		palette_toggle.set_pressed_no_signal(true)
		palette_toggle.toggled.emit(true)
		_expect(
			not _all_top_level_groups_collapsed(instruction_tree),
			"enabling the palette toggle expands the component and command groups",
		)
	if palette != null:
		var left_split := palette.get_parent()
		_expect(
			(
				left_split.get_child_count() >= 3
				and not (left_split.get_child(1) as Control).visible
				and (left_split.get_child(2) as Control).visible
			),
			"the document list is hidden while the lower branch outline remains visible",
		)
		var lower_region := left_split.get_child(2) as Control
		var visible_height := palette.size.y + lower_region.size.y
		var ratio_is_available := visible_height / 3.0 >= lower_region.get_combined_minimum_size().y
		var ratio_is_correct := (
			visible_height > 0.0 and absf(palette.size.y / visible_height - 2.0 / 3.0) < 0.03
		)
		var ratio_is_minimum_clamped := (
			not ratio_is_available
			and is_equal_approx(
				lower_region.size.y,
				lower_region.get_combined_minimum_size().y,
			)
		)
		var layout_cannot_fit_minimums := (
			visible_height
			< (palette.get_combined_minimum_size().y + lower_region.get_combined_minimum_size().y)
		)
		_expect(
			ratio_is_correct or ratio_is_minimum_clamped or layout_cannot_fit_minimums,
			(
				"the initial component-to-branch height ratio is two to one "
				+ "or respects the native branch region's minimum height "
				+ (
					"(component: %.1f, branch: %.1f, lower minimum: %.1f)"
					% [
						palette.size.y,
						lower_region.size.y,
						lower_region.get_combined_minimum_size().y,
					]
				)
			),
		)
	_expect(
		docs_button != null and docs_button.visible,
		"KonadoScript replaces Godot's global documentation action",
	)
	_expect(
		jump_link_overlay != null,
		"KonadoScript installs a complete-path link layer in the native CodeEdit",
	)
	if docs_button != null and docs_button.get_index() > 0:
		godot_docs_button = (
			docs_button.get_parent().get_child(docs_button.get_index() - 1) as Button
		)
		_expect(
			godot_docs_button != null and not godot_docs_button.visible,
			"the Godot documentation action is hidden only while editing KonadoScript",
		)
		for child_index: int in range(
			docs_button.get_index() + 1, docs_button.get_parent().get_child_count()
		):
			var child := docs_button.get_parent().get_child(child_index)
			if child is Button and child.has_meta("konado_native_help_search"):
				godot_help_button = child
				break
		_expect(
			godot_help_button != null and not godot_help_button.visible,
			"Godot API help search is hidden while editing KonadoScript",
		)
	if code_edit != null:
		var original_source := code_edit.text
		_expect(
			original_source.begins_with("jump_branch intro"),
			"native Script Editor displays the original .ks source",
		)
		_expect(
			code_edit.syntax_highlighter is KonadoScriptSyntaxHighlighter,
			"native Script Editor selects the KonadoScript highlighter",
		)
		if instruction_tree != null:
			var instruction := _find_first_instruction(instruction_tree.get_root())
			if instruction != null:
				var insertion_line := code_edit.get_line_count() - 1
				code_edit.set_caret_line(insertion_line)
				code_edit.set_caret_column(code_edit.get_line(insertion_line).length())
				instruction.select(0)
				await process_frame
				_expect(
					code_edit.text != original_source,
					"selecting an instruction inserts its KonadoScript snippet",
				)
				code_edit.select_all()
				code_edit.insert_text_at_caret(original_source)
		var last_line := code_edit.get_line_count() - 1
		code_edit.set_caret_line(last_line)
		code_edit.set_caret_column(code_edit.get_line(last_line).length())
		code_edit.insert_text_at_caret("\n# native save integration")
		script_editor.save_all_scripts()
		await process_frame
		_expect(
			_read_text(SCRIPT_PATH).strip_edges().ends_with("# native save integration"),
			"native Script Editor saves back to the original .ks file",
		)
		code_edit.select_all()
		code_edit.insert_text_at_caret(original_source)
		script_editor.save_all_scripts()
		await process_frame
		_expect(
			_read_text(SCRIPT_PATH) == original_source,
			"native save integration restores the tracked fixture",
		)
	if jump_link_overlay != null:
		jump_link_overlay._open_target({"path": NAVIGATION_SCRIPT_PATH, "line": 1})
		await process_frame
		await process_frame
		_expect(
			(
				script_editor.get_current_script() != null
				and script_editor.get_current_script().resource_path == NAVIGATION_SCRIPT_PATH
			),
			"semantic navigation safely replaces the active KonadoScript editor",
		)
		_expect(
			not is_instance_valid(jump_link_overlay),
			"semantic navigation defers destruction of the active link overlay",
		)
	script_editor.close_file(SCRIPT_PATH)
	script_editor.close_file(NAVIGATION_SCRIPT_PATH)
	var gd_script := load("res://tests/dotnet/fake_dialogue_manager.gd") as Script
	if gd_script != null:
		EditorInterface.edit_script(gd_script)
		await process_frame
		await process_frame
		_expect(
			palette != null and not palette.visible,
			"switching to GDScript restores the native document list",
		)
		if palette != null:
			_expect(
				(palette.get_parent().get_child(1) as Control).visible,
				"the native document list is visible for non-Konado scripts",
			)
		_expect(
			docs_button != null and not docs_button.visible,
			"switching to GDScript restores Godot's documentation action",
		)
		_expect(
			not is_instance_valid(jump_link_overlay),
			"switching to GDScript removes the KonadoScript path link layer",
		)
		_expect(
			(
				godot_docs_button != null
				and godot_docs_button.visible
				and godot_help_button != null
				and godot_help_button.visible
			),
			"switching to GDScript restores both native Godot help controls",
		)
		script_editor.close_file(gd_script.resource_path)
	if _invalid_document != null:
		EditorInterface.edit_script(_invalid_document)
		await process_frame
		await process_frame
		editor = script_editor.get_current_editor()
		code_edit = editor.get_base_editor() as CodeEdit if editor != null else null
		_expect(
			code_edit != null and code_edit.text == "endif_invalid",
			"native Script Editor opens malformed KonadoScript for repair",
		)
		script_editor.close_file(INVALID_SCRIPT_PATH)
	_invalid_document = null
	if FileAccess.file_exists(INVALID_SCRIPT_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(INVALID_SCRIPT_PATH))


func _test_branch_refactor_ui() -> void:
	var code_edit := CodeEdit.new()
	code_edit.text = (
		"branch intro\n" + 'choice "Go" -> intro\n' + "jump_branch intro\n" + '"Kona" "intro"'
	)
	var menu := KonadoScriptCodeContextMenu.new()
	menu._active_code_edit = code_edit
	menu._active_symbol = "intro"
	menu._find_references(null)
	_expect(menu._reference_list.item_count == 3, "branch reference dialog lists structural uses")
	menu._ensure_rename_dialog()
	menu._rename_input.text = "opening"
	menu._apply_rename()
	_expect(
		(
			"branch opening" in code_edit.text
			and "jump_branch opening" in code_edit.text
			and '"Kona" "intro"' in code_edit.text
		),
		"branch rename dialog performs one undoable structural edit",
	)
	menu.cleanup()
	code_edit.free()


func _completion_displays(result: Dictionary) -> PackedStringArray:
	var displays := PackedStringArray()
	for option: Dictionary in result.get("options", []):
		displays.append(option["display"])
	return displays


func _find_first_instruction(item: TreeItem) -> TreeItem:
	if item == null:
		return null
	if item.get_metadata(0) != null:
		return item
	var child := item.get_first_child()
	while child != null:
		var result := _find_first_instruction(child)
		if result != null:
			return result
		child = child.get_next()
	return null


func _all_top_level_groups_collapsed(tree: Tree) -> bool:
	var root := tree.get_root()
	if root == null or root.get_first_child() == null:
		return false
	var group := root.get_first_child()
	while group != null:
		if not group.is_collapsed():
			return false
		group = group.get_next()
	return true


func _completion_insertions(result: Dictionary) -> PackedStringArray:
	var insertions := PackedStringArray()
	for option: Dictionary in result.get("options", []):
		insertions.append(option["insert_text"])
	return insertions


func _read_text(path: String) -> String:
	return FileAccess.get_file_as_string(path)


func _color_at(highlighting: Dictionary, column: int, default_color: Color) -> Color:
	var color := default_color
	var transitions: Array = highlighting.keys()
	transitions.sort()
	for transition: int in transitions:
		if transition > column:
			break
		color = highlighting[transition]["color"]
	return color


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures += 1
		push_error("FAIL: %s" % message)
