@tool
extends ScriptLanguageExtension
class_name KonadoScriptLanguage

const CALL_HINT_MARKER := "\uFFFF"

## Godot Script Editor bridge for KonadoScript.
##
## This object is intentionally not registered as a runtime scripting language:
## KonadoScript is compiled to KonadoShot resources by the resource loader. KonadoShot
## returns this bridge while it is edited so Godot can provide its native script
## workspace, validation, outline, and completion UI.

const CARET_MARKER := "\uFFFF"
const COMPLETION_COLOR := Color(0.85, 0.72, 1.0)
const POSITION_VALUES := ["1", "2", "3", "4", "5"]
const COMPARISON_OPERATORS := ["==", "!=", ">", "<", ">=", "<="]
const BOOLEAN_VALUES := ["true", "false"]

var _project_index := KonadoScriptProjectIndex.shared()
var _document_store := KonadoScriptDocumentStore.shared()


func _get_name() -> String:
	return "KonadoScript"


func _get_type() -> String:
	return "KonadoScript"


func _get_extension() -> String:
	return "ks"


func _get_recognized_extensions() -> PackedStringArray:
	return PackedStringArray(["ks"])


func _get_reserved_words() -> PackedStringArray:
	var keywords := PackedStringArray()
	for keyword: String in KonadoScriptToken.KEYWORDS:
		keywords.append(keyword)
	return keywords


func _is_control_flow_keyword(keyword: String) -> bool:
	return (
		keyword
		in [
			"if",
			"else",
			"endif",
			"choice",
			"branch",
			"jump",
			"jump_branch",
			"call",
			"return",
		]
	)


func _get_comment_delimiters() -> PackedStringArray:
	return PackedStringArray(["#"])


func _get_doc_comment_delimiters() -> PackedStringArray:
	return PackedStringArray()


func _get_string_delimiters() -> PackedStringArray:
	return PackedStringArray(['" "'])


func _get_built_in_templates(_object: StringName) -> Array[Dictionary]:
	return []


func _is_using_templates() -> bool:
	return false


func _supports_builtin_mode() -> bool:
	return false


func _supports_documentation() -> bool:
	return false


func _can_inherit_from_file() -> bool:
	return false


func _can_make_function() -> bool:
	return false


func _overrides_external_editor() -> bool:
	return false


func _validate(
	code: String,
	path: String,
	validate_functions: bool,
	validate_errors: bool,
	validate_warnings: bool,
	validate_safe_lines: bool,
) -> Dictionary:
	var result := {"valid": true}
	var document := _document_store.update_buffer(path, code)
	_project_index.update_document(document)
	var diagnostics := document.get_diagnostics(KonadoScriptEditorLocale.get_editor_locale())
	var errors: Array[Dictionary] = []
	var warnings: Array[Dictionary] = []
	for diagnostic: Dictionary in diagnostics:
		var line := int(diagnostic["line"])
		var column := int(diagnostic["column"])
		if diagnostic["severity"] == "error":
			(
				errors
				. append(
					{
						"path": path,
						"line": line,
						"column": column,
						"message": diagnostic["message"],
					}
				)
			)
		else:
			(
				warnings
				. append(
					{
						"start_line": line,
						"end_line": line,
						"code": 0,
						"string_code": "konado",
						"message": diagnostic["message"],
					}
				)
			)

	if validate_functions:
		result["functions"] = document.get_outline()
	if validate_errors:
		result["errors"] = errors
	if validate_warnings:
		result["warnings"] = warnings
	if validate_safe_lines:
		result["safe_lines"] = PackedInt32Array()
	result["valid"] = errors.is_empty()
	return result


func _find_function(function: String, code: String) -> int:
	for outline_entry: String in _collect_outline(code):
		if outline_entry.get_slice(":", 0) == function:
			return maxi(0, outline_entry.get_slice(":", 1).to_int() - 1)
	return -1


func _complete_code(code: String, _path: String, _owner: Object) -> Dictionary:
	var caret := code.find(CARET_MARKER)
	if caret < 0:
		return _empty_completion()
	var line_start := code.rfind("\n", caret - 1) + 1
	var line_prefix := code.substr(line_start, caret - line_start).replace(CARET_MARKER, "")
	var source := code.replace(CARET_MARKER, "")
	var document := _document_store.update_buffer(_path, source)
	_project_index.update_document(document)
	var options: Array[Dictionary] = []
	for candidate: Dictionary in _get_completion_candidates(source, line_prefix):
		var kind: CodeEdit.CodeCompletionKind = candidate.get(
			"kind", CodeEdit.CodeCompletionKind.KIND_KEYWORD
		)
		(
			options
			. append(
				{
					"kind": kind,
					"display": _completion_display(candidate),
					"insert_text": candidate["insert_text"],
					"font_color": COMPLETION_COLOR,
					"icon": _completion_icon(kind),
					"default_value": null,
					"location": CodeEdit.CodeCompletionLocation.LOCATION_LOCAL,
				}
			)
		)
	return {
		"result": OK,
		"options": options,
		"force": false,
		"call_hint": _get_call_hint(line_prefix),
	}


func _lookup_code(code: String, symbol: String, path: String, _owner: Object) -> Dictionary:
	var reference := _get_reference_at_caret(code)
	var source := code.replace(CARET_MARKER, "")
	_document_store.update_buffer(path, source)
	var reference_kind := String(reference.get("kind", ""))
	var reference_name := String(reference.get("name", symbol))
	var lookup := {}
	# Godot treats the complete quoted dialogue as the native lookup token. Returning
	# a successful lookup for an interpolated variable would therefore underline the
	# whole string. The semantic-link overlay owns these exact inner-string spans.
	if bool(reference.get("inside_string", false)):
		return _empty_lookup()
	match reference_kind:
		"scripts":
			lookup = _lookup_script(reference_name)
		"branches", "variables", "signals":
			lookup = _lookup_local(source, reference_kind, reference_name, path)
	if not lookup.is_empty():
		return lookup
	# Commands have documentation but no source declaration. Project resources are
	# opened by the semantic-link controller because ScriptLanguage lookup can only
	# navigate to script lines and would incorrectly reuse the current `.ks` path.
	if not reference.is_empty():
		return _empty_lookup()
	var location := KonadoScriptSymbolIndex.find_branch_definition(source, symbol)
	if location < 0:
		return _empty_lookup()
	return {
		"result": OK,
		"type": LookupResultType.LOOKUP_RESULT_LOCAL_CONSTANT,
		"description":
		(
			KonadoScriptEditorLocale
			. text(
				"Branch declared on line %d." % location,
				"分支声明位于第 %d 行。" % location,
			)
		),
		"doc_type": "KonadoScript branch",
		"value": symbol,
		"script_path": path,
		"location": location,
	}


func _lookup_script(script_target: String) -> Dictionary:
	if script_target.is_empty() or not FileAccess.file_exists(script_target):
		return {}
	var target_script := ResourceLoader.load(script_target, "Script") as Script
	if target_script == null:
		return {}
	return {
		"result": OK,
		"type": LookupResultType.LOOKUP_RESULT_SCRIPT_LOCATION,
		"description":
		(
			KonadoScriptEditorLocale
			. text(
				"Open KonadoScript: %s" % script_target,
				"打开 KonadoScript：%s" % script_target,
			)
		),
		"doc_type": "KonadoScript file",
		"value": script_target,
		"script": target_script,
		"script_path": script_target,
		"location": 1,
	}


func _lookup_local(source: String, kind: String, name: String, path: String) -> Dictionary:
	var location := KonadoScriptSymbolIndex.find_local_definition(source, kind, name)
	if location < 0:
		return {}
	return {
		"result": OK,
		"type": LookupResultType.LOOKUP_RESULT_LOCAL_CONSTANT,
		"description":
		(
			KonadoScriptEditorLocale
			. text(
				(
					"%s '%s' is declared on line %d."
					% [kind.trim_suffix("s").capitalize(), name, location]
				),
				"%s“%s”声明于第 %d 行。" % [_local_kind_label(kind), name, location],
			)
		),
		"doc_type": "KonadoScript %s" % kind.trim_suffix("s"),
		"value": name,
		"script_path": path,
		"location": location,
	}


func _get_reference_at_caret(code: String) -> Dictionary:
	var caret := code.find(CARET_MARKER)
	if caret < 0:
		return {}
	var line_start := code.rfind("\n", caret - 1) + 1
	var line_end := code.find("\n", caret)
	if line_end < 0:
		line_end = code.length()
	var marked_line := code.substr(line_start, line_end - line_start)
	var caret_column := marked_line.find(CARET_MARKER)
	var line := marked_line.replace(CARET_MARKER, "")
	var source := code.replace(CARET_MARKER, "")
	var line_index := source.left(line_start).count("\n")
	return (
		KonadoScriptSymbolIndex
		. get_semantic_reference_at(
			line,
			caret_column,
			KonadoScriptSymbolIndex.is_screentext_content_line(source, line_index),
		)
	)


func _local_kind_label(kind: String) -> String:
	return {"branches": "分支", "variables": "变量", "signals": "信号"}.get(kind, kind)


func _empty_lookup() -> Dictionary:
	return {"result": ERR_UNAVAILABLE, "type": LookupResultType.LOOKUP_RESULT_SCRIPT_LOCATION}


func _auto_indent_code(code: String, from_line: int, to_line: int) -> String:
	return (
		KonadoScriptFormatter
		. format_range(
			code,
			from_line,
			to_line,
			_detect_indent_unit(code.split("\n")),
		)
	)


func _reload_scripts(_scripts: Array, _soft_reload: bool) -> void:
	pass


func _reload_tool_script(_script: Script, _soft_reload: bool) -> void:
	pass


func _get_public_functions() -> Array[Dictionary]:
	return []


func _get_public_constants() -> Dictionary:
	return {}


func _get_public_annotations() -> Array[Dictionary]:
	return []


func _get_global_class_name(_path: String) -> Dictionary:
	return {"name": ""}


func _collect_outline(source: String) -> PackedStringArray:
	var outline := PackedStringArray()
	var definitions := KonadoScriptSymbolIndex.get_branch_definitions(source)
	for branch_name: String in definitions:
		outline.append("%s:%d" % [branch_name, definitions[branch_name]])
	return outline


func _get_completion_candidates(source: String, line_prefix: String) -> Array[Dictionary]:
	var stripped := line_prefix.strip_edges()
	var ends_with_space := line_prefix.ends_with(" ") or line_prefix.ends_with("\t")
	var token_spans := KonadoScriptSymbolIndex.get_line_tokens(line_prefix)
	var tokens := PackedStringArray()
	for token_span: Dictionary in token_spans:
		tokens.append(String(token_span["text"]))
	var candidates: Array[Dictionary] = []
	if tokens.is_empty():
		candidates = _make_candidates(KonadoScriptLanguageCatalog.ROOT_KEYWORDS, "")
	elif _is_dialogue_completion(token_spans):
		if tokens.size() >= 2 and bool(token_spans[1].get("quoted", false)):
			if tokens.size() == 2 and ends_with_space:
				candidates = _make_candidates(_project_index.get_values("voices"), "")
			elif (
				tokens.size() == 3
				and not ends_with_space
				and String(token_spans[2].get("text", "")) != "["
			):
				candidates = _make_candidates(_project_index.get_values("voices"), tokens[2])
	else:
		var root_keyword := tokens[0]
		var partial := "" if ends_with_space else tokens[-1]
		var argument_index := tokens.size() if ends_with_space else tokens.size() - 1
		var context_values := KonadoScriptLanguageCatalog.get_context_completions(root_keyword)
		if stripped.is_empty():
			candidates = _make_candidates(KonadoScriptLanguageCatalog.ROOT_KEYWORDS, "")
		elif tokens.size() == 1 and not ends_with_space:
			candidates = _make_candidates(KonadoScriptLanguageCatalog.ROOT_KEYWORDS, root_keyword)
			candidates.append_array(
				_make_candidates(_project_index.get_values("actors"), root_keyword)
			)
			var dialogue_variables := _merge_values(
				_collect_matches(source, "(?m)((?:%|\\$)[\\p{L}_][\\p{L}\\p{N}_-]*)"),
				_project_index.get_values("variables"),
			)
			candidates.append_array(_make_candidates(dialogue_variables, root_keyword))
			(
				candidates
				. append_array(
					(
						KonadoScriptLanguageCatalog
						. get_snippet_completions(
							root_keyword,
							KonadoScriptEditorLocale.get_editor_locale(),
						)
					)
				)
			)
		elif not context_values.is_empty() and argument_index == 1:
			candidates = _make_candidates(context_values, partial)
		elif root_keyword == "background" and argument_index == 1:
			candidates = _make_candidates(_project_index.get_values("backgrounds"), partial)
		elif root_keyword == "background" and argument_index == 2:
			candidates = _make_candidates(
				KonadoScriptLanguageCatalog.get_background_effects(), partial
			)
		elif root_keyword == "jump_branch" and argument_index == 1:
			candidates = _make_candidates(_get_branch_names(source), partial)
		elif root_keyword == "call" and argument_index == 1:
			candidates = _make_candidates(_get_branch_names(source), partial)
		elif root_keyword == "choice" and "->" in tokens:
			# 分支名之后是可选后缀：if <条件> / once。
			if argument_index >= 4:
				var suffix_region := tokens.slice(4)
				if not ends_with_space and suffix_region.size() > 0:
					suffix_region = suffix_region.slice(0, suffix_region.size() - 1)
				var suffixes := PackedStringArray()
				if "if" not in suffix_region:
					suffixes.append("if")
				if "once" not in suffix_region:
					suffixes.append("once")
				candidates = _make_candidates(suffixes, partial)
			else:
				candidates = _make_candidates(_get_branch_names(source), partial)
		elif root_keyword == "jump" and argument_index == 1:
			candidates = _make_candidates(
				_project_index.get_values("scripts"),
				partial,
				CodeEdit.CodeCompletionKind.KIND_FILE_PATH,
			)
		elif root_keyword == "play" and argument_index == 2 and tokens.size() >= 2:
			var audio_kind := String(tokens[1])
			if audio_kind in ["bgm", "sfx"]:
				var resource_kind := "background_music_tracks" if audio_kind == "bgm" else "sfx"
				candidates = _make_candidates(_project_index.get_values(resource_kind), partial)
		elif root_keyword == "actor" and tokens.size() >= 2:
			var actor_action := String(tokens[1])
			if argument_index == 2:
				candidates = _make_candidates(
					_merge_values(
						_project_index.get_values("actors"),
						_collect_matches(
							source,
							"(?m)^\\s*actor\\s+show\\s+([\\p{L}_][\\p{L}\\p{N}_-]*)",
						),
					),
					partial,
				)
			elif actor_action in ["show", "change"] and argument_index == 3:
				candidates = _make_candidates(
					_project_index.get_actor_scoped_values(String(tokens[2]), "states"),
					partial,
				)
			elif actor_action == "show" and argument_index == 4:
				candidates = _make_candidates(PackedStringArray(["at"]), partial)
			elif actor_action == "show" and argument_index == 5:
				candidates = _make_candidates(POSITION_VALUES, partial)
			elif actor_action == "move" and argument_index == 3:
				candidates = _make_candidates(POSITION_VALUES, partial)
			elif actor_action == "motion" and argument_index == 3:
				candidates = _make_candidates(
					_project_index.get_actor_scoped_values(String(tokens[2]), "motions"),
					partial,
				)
		elif root_keyword in ["set", "add", "sub", "mul", "div", "if"] and argument_index == 1:
			var variables := _collect_matches(
				source,
				"(?m)((?:%|\\$)[\\p{L}_][\\p{L}\\p{N}_-]*)",
			)
			if partial.begins_with("%") or partial.is_empty():
				variables = _merge_values(
					variables,
					_filter_values_by_prefix(_project_index.get_values("variables"), "%"),
				)
			candidates = _make_candidates(
				variables,
				partial,
			)
		elif root_keyword == "if" and argument_index == 2:
			candidates = _make_candidates(COMPARISON_OPERATORS, partial)
		elif root_keyword == "achievement" and tokens.size() >= 2:
			if argument_index == 2:
				candidates = _make_candidates(_project_index.get_values("achievements"), partial)
			elif String(tokens[1]) == "set_flag" and argument_index == 3:
				candidates = _make_candidates(BOOLEAN_VALUES, partial)
		elif root_keyword == "waitsignal" and argument_index == 1:
			candidates = _make_candidates(
				_collect_local_symbol_names(source, "signals"),
				partial,
			)
		elif root_keyword in ["cam", "asyncam"] and tokens.size() >= 2:
			var camera_action := String(tokens[1])
			if camera_action == "move" and argument_index == 2:
				candidates = _make_candidates(_project_index.get_values("cameras"), partial)
			elif (
				(camera_action == "move" and argument_index == 3)
				or (camera_action == "reset" and argument_index == 2)
			):
				candidates = _make_candidates(
					KonadoScriptLanguageCatalog.CAMERA_TRANSITIONS, partial
				)
		var inferred_kind := _infer_completion_kind(root_keyword, tokens, argument_index)
		if inferred_kind != CodeEdit.CodeCompletionKind.KIND_KEYWORD:
			for candidate: Dictionary in candidates:
				if candidate.get("kind") == CodeEdit.CodeCompletionKind.KIND_KEYWORD:
					candidate["kind"] = inferred_kind
	candidates.append_array(
		_get_named_parameter_candidates(line_prefix, token_spans, ends_with_space)
	)
	return candidates


func _get_named_parameter_candidates(
	line_prefix: String,
	token_spans: Array[Dictionary],
	ends_with_space: bool,
) -> Array[Dictionary]:
	if not ends_with_space:
		return []
	var statement_spans: Array[Dictionary] = []
	for span: Dictionary in token_spans:
		if String(span.get("text", "")) == "[":
			break
		statement_spans.append(span)
	if not _is_complete_parameterized_statement(statement_spans):
		return []
	var command := _registry_command_for_spans(statement_spans)
	if command.is_empty() or not KonadoScriptCommandRegistry.COMMANDS.has(command):
		return []
	if command == "condition" and line_prefix.strip_edges().ends_with(":"):
		return []
	var definitions := KonadoScriptCommandRegistry.COMMON_PARAMETERS.duplicate(true)
	(
		definitions
		. merge(
			KonadoScriptCommandRegistry.COMMANDS[command].get("parameters", {}),
			true,
		)
	)
	var result: Array[Dictionary] = []
	for name: String in definitions:
		var existing_pattern := "\\[\\s*%s\\s*=" % name
		var regex := RegEx.new()
		if regex.compile(existing_pattern) == OK and regex.search(line_prefix) != null:
			continue
		var default_value := (
			{
				"id": "step_id",
				"duration": "0.3",
				"speed": "1.0",
				"interval": "0.03",
			}
			. get(name, "value")
		)
		(
			result
			. append(
				{
					"text": "[%s=]" % name,
					"insert_text": "[%s=%s]" % [name, default_value],
					"kind": CodeEdit.CodeCompletionKind.KIND_MEMBER,
					"score": 0,
				}
			)
		)
	return result


func _registry_command_for_spans(token_spans: Array[Dictionary]) -> String:
	if _is_dialogue_completion(token_spans):
		return "dialogue"
	if token_spans.is_empty():
		return ""
	var root := String(token_spans[0].get("text", ""))
	var action := String(token_spans[1].get("text", "")) if token_spans.size() > 1 else ""
	var command := String(
		(
			{
				"showtextbox": "textbox.show",
				"hidetextbox": "textbox.hide",
				"waitsignal": "wait.signal",
				"background": "background",
				"stop": "audio.bgm.stop",
				"choice": "choice",
				"if": "condition",
				"set": "variable",
				"add": "variable",
				"sub": "variable",
				"mul": "variable",
				"div": "variable",
				"jump": "jump.script",
				"jump_branch": "jump.branch",
				"call": "call.branch",
				"return": "return",
				"signal": "signal",
				"end": "halt",
			}
			. get(root, "")
		)
	)
	match root:
		"actor":
			command = "actor.%s" % action
		"play":
			command = "audio.%s.play" % action
		"achievement":
			command = (
				{
					"unlock": "achievement.unlock",
					"increment": "achievement.progress",
					"set_flag": "achievement.flag",
				}
				. get(action, "")
			)
		"cam":
			command = "camera.%s" % action
		"asyncam":
			command = "camera.%s.async" % action
	return command


func _is_complete_parameterized_statement(token_spans: Array[Dictionary]) -> bool:
	if _is_dialogue_completion(token_spans):
		return token_spans.size() in [2, 3]
	if token_spans.is_empty():
		return false
	var root := String(token_spans[0].get("text", ""))
	var action := String(token_spans[1].get("text", "")) if token_spans.size() > 1 else ""
	var command := "%s %s" % [root, action]
	var minimum_tokens := {
		"showtextbox": 1,
		"hidetextbox": 1,
		"waitsignal": 2,
		"background": 2,
		"actor show": 6,
		"actor exit": 3,
		"actor change": 4,
		"actor move": 4,
		"actor motion": 4,
		"play bgm": 3,
		"play sfx": 3,
		"stop": 1,
		"stop bgm": 2,
		"choice": 4,
		"if": 4,
		"set": 3,
		"add": 3,
		"sub": 3,
		"mul": 3,
		"div": 3,
		"jump": 2,
		"jump_branch": 2,
		"call": 2,
		"return": 1,
		"signal": 2,
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
		"end": 1,
	}
	var minimum := int(minimum_tokens.get(command, minimum_tokens.get(root, -1)))
	return minimum >= 0 and token_spans.size() >= minimum


func _is_dialogue_completion(token_spans: Array[Dictionary]) -> bool:
	if token_spans.is_empty():
		return false
	if bool(token_spans[0].get("quoted", false)):
		return true
	if token_spans.size() < 2 or not bool(token_spans[1].get("quoted", false)):
		return false
	var first := String(token_spans[0].get("text", ""))
	return (
		first.begins_with("%")
		or first.begins_with("$")
		or not KonadoScriptLanguageCatalog.ROOT_KEYWORDS.has(first)
	)


func _infer_completion_kind(
	root_keyword: String,
	tokens: PackedStringArray,
	argument_index: int,
) -> CodeEdit.CodeCompletionKind:
	var kind := CodeEdit.CodeCompletionKind.KIND_KEYWORD
	if root_keyword in ["jump_branch", "choice", "call"]:
		kind = CodeEdit.CodeCompletionKind.KIND_FUNCTION
	elif root_keyword in ["set", "add", "sub", "mul", "div", "if"] and argument_index == 1:
		kind = CodeEdit.CodeCompletionKind.KIND_VARIABLE
	elif root_keyword == "waitsignal":
		kind = CodeEdit.CodeCompletionKind.KIND_SIGNAL
	elif root_keyword == "achievement" and argument_index == 2:
		kind = CodeEdit.CodeCompletionKind.KIND_CONSTANT
	elif (
		root_keyword in ["background", "actor", "play", "cam", "asyncam"]
		and tokens.size() > 1
		and argument_index > 1
	):
		kind = CodeEdit.CodeCompletionKind.KIND_MEMBER
	return kind


func _make_candidates(
	values: Variant,
	partial: String,
	kind: CodeEdit.CodeCompletionKind = CodeEdit.CodeCompletionKind.KIND_KEYWORD,
) -> Array[Dictionary]:
	var candidates: Array[Dictionary] = []
	var normalized_partial := partial.to_lower()
	for value: String in values:
		var score := _fuzzy_score(value.to_lower(), normalized_partial)
		if score < 0:
			continue
		candidates.append({"text": value, "insert_text": value, "kind": kind, "score": score})
	candidates.sort_custom(
		func(left: Dictionary, right: Dictionary) -> bool:
			if left["score"] == right["score"]:
				return String(left["text"]).naturalnocasecmp_to(String(right["text"])) < 0
			return int(left["score"]) > int(right["score"])
	)
	return candidates


func _fuzzy_score(value: String, partial: String) -> int:
	if partial.is_empty():
		return 0
	if value.begins_with(partial):
		return 1000 - value.length()
	var search_from := 0
	var score := 0
	var previous := -2
	for character: String in partial:
		var found := value.find(character, search_from)
		if found < 0:
			return -1
		score += 12 if found == previous + 1 else 2
		previous = found
		search_from = found + 1
	return score - value.length()


func _completion_display(candidate: Dictionary) -> String:
	return String(candidate["text"])


func _completion_icon(kind: CodeEdit.CodeCompletionKind) -> Texture2D:
	if not Engine.is_editor_hint():
		return null
	var theme := EditorInterface.get_editor_theme()
	if theme == null:
		return null
	var icon_name := (
		{
			CodeEdit.CodeCompletionKind.KIND_FILE_PATH: "Script",
			CodeEdit.CodeCompletionKind.KIND_FUNCTION: "MemberMethod",
			CodeEdit.CodeCompletionKind.KIND_SIGNAL: "Signal",
			CodeEdit.CodeCompletionKind.KIND_VARIABLE: "MemberProperty",
			CodeEdit.CodeCompletionKind.KIND_MEMBER: "Resource",
			CodeEdit.CodeCompletionKind.KIND_CONSTANT: "Enum",
		}
		. get(kind, "MemberMethod")
	)
	return (
		theme.get_icon(icon_name, "EditorIcons")
		if theme.has_icon(icon_name, "EditorIcons")
		else null
	)


func _get_branch_names(source: String) -> PackedStringArray:
	var names := PackedStringArray(KonadoScriptSymbolIndex.get_branch_definitions(source).keys())
	names.sort()
	return names


func _merge_values(first: PackedStringArray, second: PackedStringArray) -> PackedStringArray:
	var merged := first.duplicate()
	for value: String in second:
		if not merged.has(value):
			merged.append(value)
	merged.sort()
	return merged


func _collect_matches(source: String, pattern: String) -> PackedStringArray:
	var values := PackedStringArray()
	var regex := RegEx.new()
	if regex.compile(pattern) != OK:
		return values
	for match_result: RegExMatch in regex.search_all(source):
		var value := match_result.get_string(1)
		if not values.has(value):
			values.append(value)
	values.sort()
	return values


func _collect_local_symbol_names(source: String, kind: String) -> PackedStringArray:
	var values := PackedStringArray()
	for reference: Dictionary in KonadoScriptSymbolIndex.get_semantic_references(source):
		if reference.get("kind") != kind:
			continue
		var value := String(reference.get("name", ""))
		if not value.is_empty() and not values.has(value):
			values.append(value)
	values.sort()
	return values


func _filter_values_by_prefix(values: PackedStringArray, prefix: String) -> PackedStringArray:
	var filtered := PackedStringArray()
	for value: String in values:
		if value.begins_with(prefix):
			filtered.append(value)
	return filtered


func _empty_completion() -> Dictionary:
	return {
		"result": OK,
		"options": [],
		"force": false,
		"call_hint": "",
	}


func _get_call_hint(line_prefix: String) -> String:
	var tokens := line_prefix.strip_edges().replace("\t", " ").split(" ", false)
	if tokens.is_empty():
		return ""
	var command := String(tokens[0])
	var command_word_count := 1
	if tokens.size() >= 2:
		var contextual_command := "%s %s" % [tokens[0], tokens[1]]
		if not KonadoScriptLanguageCatalog.get_signature(contextual_command).is_empty():
			command = contextual_command
			command_word_count = 2
	var signature := KonadoScriptLanguageCatalog.get_signature(command)
	if signature.is_empty():
		return ""
	signature = _mark_active_call_hint_parameter(
		signature,
		line_prefix,
		tokens.size(),
		command_word_count,
	)
	var root_command := String(tokens[0])
	var description := (
		KonadoScriptLanguageCatalog
		. get_command_description(
			root_command,
			KonadoScriptEditorLocale.get_editor_locale(),
		)
	)
	return signature if description.is_empty() else "%s\n%s" % [signature, description]


func _mark_active_call_hint_parameter(
	signature: String,
	line_prefix: String,
	token_count: int,
	command_word_count: int,
) -> String:
	var parameter_spans: Array[Vector2i] = []
	var column := 0
	while column < signature.length():
		var opening := signature.substr(column, 1)
		if opening not in ["<", "["]:
			column += 1
			continue
		var closing := ">" if opening == "<" else "]"
		var end := signature.find(closing, column + 1)
		if end < 0:
			break
		parameter_spans.append(Vector2i(column, end + 1))
		column = end + 1
	if parameter_spans.is_empty():
		return CALL_HINT_MARKER + signature + CALL_HINT_MARKER
	var supplied_argument_count := maxi(0, token_count - command_word_count)
	var ends_with_separator := line_prefix.ends_with(" ") or line_prefix.ends_with("\t")
	var active_parameter := (
		supplied_argument_count if ends_with_separator else maxi(0, supplied_argument_count - 1)
	)
	active_parameter = mini(active_parameter, parameter_spans.size() - 1)
	var span := parameter_spans[active_parameter]
	return (
		signature.left(span.x)
		+ CALL_HINT_MARKER
		+ signature.substr(span.x, span.y - span.x)
		+ CALL_HINT_MARKER
		+ signature.substr(span.y)
	)


func _detect_indent_unit(lines: PackedStringArray) -> String:
	var minimum_spaces := 0
	for line: String in lines:
		if line.begins_with("\t"):
			return "\t"
		var spaces := line.length() - line.strip_edges(true, false).length()
		if spaces > 0 and (minimum_spaces == 0 or spaces < minimum_spaces):
			minimum_spaces = spaces
	if minimum_spaces > 0:
		return " ".repeat(minimum_spaces)
	if Engine.is_editor_hint():
		var settings := EditorInterface.get_editor_settings()
		if settings != null:
			var indent_type := int(settings.get_setting("text_editor/behavior/indent/type"))
			var indent_size := int(settings.get_setting("text_editor/behavior/indent/size"))
			return "\t" if indent_type == 0 else " ".repeat(maxi(1, indent_size))
	return "    "
