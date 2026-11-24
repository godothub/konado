@tool
extends RefCounted
class_name KonadoScriptSymbolIndex

## Structural symbol utilities shared by language lookup and editor refactoring.

const IDENTIFIER_PATTERN := "[\\p{L}_][\\p{L}\\p{N}_-]*"
const RESOURCE_PATH_PREFIXES := ["res://", "uid://", "user://"]

static var _variable_regex: RegEx


static func get_branch_definitions(source: String) -> Dictionary:
	var definitions := {}
	for reference: Dictionary in get_semantic_references(source):
		if reference.get("kind") != "branches" or reference.get("role") != "definition":
			continue
		var symbol := String(reference.get("name", ""))
		if not definitions.has(symbol):
			definitions[symbol] = int(reference.get("line", -1))
	return definitions


static func get_branch_references(source: String) -> Array[Dictionary]:
	var references: Array[Dictionary] = []
	for reference: Dictionary in get_semantic_references(source):
		if reference.get("kind") != "branches":
			continue
		(
			references
			. append(
				{
					"symbol": reference.get("name", ""),
					"line": reference.get("line", -1),
					"column": reference.get("column", -1),
					"kind": reference.get("role", "reference"),
				}
			)
		)
	return references


static func find_branch_definition(source: String, symbol: String) -> int:
	return int(get_branch_definitions(source).get(symbol, -1))


static func find_script_jump_at_caret(code: String, caret_marker: String) -> String:
	var caret := code.find(caret_marker)
	if caret < 0:
		return ""
	var line_start := code.rfind("\n", caret - 1) + 1
	var line_end := code.find("\n", caret)
	if line_end < 0:
		line_end = code.length()
	var marked_line := code.substr(line_start, line_end - line_start)
	var caret_column := marked_line.find(caret_marker)
	var line := marked_line.replace(caret_marker, "")
	return String(find_script_jump_span(line, caret_column).get("path", ""))


static func find_script_jump_span(line: String, column: int) -> Dictionary:
	for reference: Dictionary in get_line_semantic_references(line):
		if (
			reference.get("kind") == "scripts"
			and column >= int(reference["start"])
			and column < int(reference["end"])
		):
			var result := reference.duplicate()
			result["path"] = result.get("name", "")
			result["line"] = 0
			return result
	return {}


static func get_semantic_reference_at(
	line: String,
	column: int,
	screentext_content: bool = false,
) -> Dictionary:
	var reference := find_script_jump_span(line, column)
	if not reference.is_empty():
		return reference
	var references := get_line_semantic_references(line, screentext_content)
	for candidate: Dictionary in references:
		if column >= int(candidate["start"]) and column < int(candidate["end"]):
			return candidate
	return {}


static func get_line_semantic_references(
	line: String,
	screentext_content: bool = false,
) -> Array[Dictionary]:
	var tokens := _tokenize_line_spans(line)
	return _references_from_spans(line, tokens, screentext_content)


## Builds editor symbols from the compiler-owned token stream. This is the
## canonical document path: editor features must not lex the same revision a
## second time with a separate interpretation of the grammar.
static func get_semantic_references_from_tokens(
	source: String, compiler_tokens: RefCounted
) -> Array[Dictionary]:
	var lines := source.split("\n")
	var spans_by_line: Dictionary = {}
	for token_index in int(compiler_tokens.call("size")):
		var token := compiler_tokens.call("token_at", token_index) as KonadoScriptToken
		if (
			token.type
			in [
				KonadoScriptToken.Type.INDENT,
				KonadoScriptToken.Type.DEDENT,
				KonadoScriptToken.Type.NEWLINE,
				KonadoScriptToken.Type.EOF
			]
		):
			continue
		var line_index := token.line - 1
		if line_index < 0 or line_index >= lines.size():
			continue
		if not spans_by_line.has(line_index):
			spans_by_line[line_index] = []
		spans_by_line[line_index].append(_token_span(token, String(lines[line_index])))

	var references: Array[Dictionary] = []
	var inside_screentext := false
	for line_index: int in lines.size():
		var line := String(lines[line_index])
		# Dictionary values lose their typed-array metadata. Rebuild the typed view
		# at this boundary so calls below remain safe under Godot's strict runtime
		# argument checks.
		var line_spans: Array[Dictionary] = []
		for span: Dictionary in spans_by_line.get(line_index, []):
			line_spans.append(span)
		for reference: Dictionary in _references_from_spans(line, line_spans, inside_screentext):
			reference["line"] = line_index + 1
			reference["column"] = int(reference["start"]) + 1
			references.append(reference)
		if inside_screentext:
			if _is_screentext_close_spans(line_spans):
				inside_screentext = false
		elif _is_screentext_open_spans(line_spans):
			inside_screentext = true
	return references


static func _references_from_spans(
	line: String,
	tokens: Array[Dictionary],
	screentext_content: bool,
) -> Array[Dictionary]:
	var references: Array[Dictionary] = []
	if tokens.is_empty():
		return references
	var first := String(tokens[0]["text"])
	if screentext_content:
		return (
			_get_string_variable_references(line, tokens[0])
			if bool(tokens[0].get("quoted", false))
			else references
		)
	if _is_dialogue_spans(tokens):
		if first.begins_with("%") or first.begins_with("$"):
			_append_token_reference(references, tokens[0], "variables", "reference")
		elif bool(tokens[0]["quoted"]):
			if _get_string_variable_references(line, tokens[0]).is_empty():
				_append_quoted_token_reference(references, tokens[0], "actors", "reference")
				references[-1]["optional"] = true
		else:
			_append_token_reference(references, tokens[0], "actors", "reference")
		if _has_dialogue_voice_token(tokens):
			_append_quoted_token_reference(references, tokens[2], "voices", "reference")
		references.append_array(_get_dialogue_variable_references(line, tokens))
		return references
	if KonadoScriptLanguageCatalog.ROOT_KEYWORDS.has(first):
		_append_token_reference(references, tokens[0], "commands", "definition")
	match first:
		"background":
			_append_argument_reference(references, tokens, 1, "backgrounds")
			_append_argument_reference(references, tokens, 2, "effects")
		"actor":
			if tokens.size() >= 3:
				var action := String(tokens[1]["text"])
				_append_argument_reference(references, tokens, 2, "actors")
				if action in ["show", "change"]:
					_append_argument_reference(
						references,
						tokens,
						3,
						"states",
						String(tokens[2]["text"]),
					)
				elif action == "motion":
					_append_argument_reference(
						references,
						tokens,
						3,
						"motions",
						String(tokens[2]["text"]),
					)
		"play":
			if tokens.size() >= 3:
				var kind := (
					"background_music_tracks" if String(tokens[1]["text"]) == "bgm" else "sfx"
				)
				_append_argument_reference(references, tokens, 2, kind)
		"cam", "asyncam":
			if tokens.size() >= 3 and String(tokens[1]["text"]) == "move":
				_append_argument_reference(references, tokens, 2, "cameras")
		"branch":
			_append_argument_reference(references, tokens, 1, "branches", "", "definition")
		"jump_branch":
			_append_argument_reference(references, tokens, 1, "branches")
		"call":
			_append_argument_reference(references, tokens, 1, "branches")
		"jump":
			_append_argument_reference(references, tokens, 1, "scripts")
		"choice":
			for index: int in tokens.size():
				if String(tokens[index]["text"]) == "->":
					_append_argument_reference(references, tokens, index + 1, "branches")
					break
			# `choice ... if %var op %other` 里的两个变量也要进入引用索引，
			# 否则重命名变量会漏掉菜单条件。
			for index: int in tokens.size():
				if String(tokens[index]["text"]) != "if":
					continue
				var variable_index := index + 1
				var variable_text := (
					String(tokens[variable_index]["text"]) if variable_index < tokens.size() else ""
				)
				if variable_text.begins_with("%") or variable_text.begins_with("$"):
					_append_argument_reference(references, tokens, variable_index, "variables")
				var value_index := index + 3
				var value_text := (
					String(tokens[value_index]["text"]) if value_index < tokens.size() else ""
				)
				if value_text.begins_with("%") or value_text.begins_with("$"):
					_append_argument_reference(references, tokens, value_index, "variables")
				break
		"set":
			_append_argument_reference(references, tokens, 1, "variables", "", "definition")
		"add", "sub", "mul", "div", "if":
			_append_argument_reference(references, tokens, 1, "variables")
		"signal":
			_append_remaining_reference(references, tokens, 1, "signals", "definition")
		"waitsignal":
			_append_argument_reference(references, tokens, 1, "signals")
		"achievement":
			_append_argument_reference(references, tokens, 2, "achievements")
	for token: Dictionary in tokens:
		var text := String(token["text"])
		if not text.begins_with("%") and not text.begins_with("$"):
			continue
		var already_indexed := false
		for existing: Dictionary in references:
			if existing["start"] == token["start"] and existing["end"] == token["end"]:
				already_indexed = true
				break
		if not already_indexed:
			_append_token_reference(references, token, "variables", "reference")
	return references


static func get_line_tokens(line: String) -> Array[Dictionary]:
	return _tokenize_line_spans(line)


static func get_dialogue_variable_references(line: String) -> Array[Dictionary]:
	return _get_dialogue_variable_references(line, _tokenize_line_spans(line))


static func get_semantic_references(source: String) -> Array[Dictionary]:
	var lexer := KonadoScriptLexer.new()
	lexer.console_output_enabled = false
	return get_semantic_references_from_tokens(source, lexer.tokenize(source))


static func is_screentext_content_line(source: String, target_line: int) -> bool:
	if target_line < 0:
		return false
	var lines := source.split("\n")
	var inside_screentext := false
	for line_index: int in mini(target_line + 1, lines.size()):
		var line := String(lines[line_index])
		if line_index == target_line:
			return inside_screentext
		if inside_screentext:
			if _is_screentext_close_line(line):
				inside_screentext = false
		elif _is_screentext_open_line(line):
			inside_screentext = true
	return false


static func get_local_symbol_references(
	source: String,
	kind: String,
	name: String,
) -> Array[Dictionary]:
	var references: Array[Dictionary] = []
	for reference: Dictionary in get_semantic_references(source):
		if reference.get("kind") == kind and reference.get("name") == name:
			references.append(reference)
	return references


static func find_local_definition(source: String, kind: String, name: String) -> int:
	for reference: Dictionary in get_local_symbol_references(source, kind, name):
		if reference.get("role") == "definition":
			return int(reference["line"])
	return -1


static func rename_branch(source: String, old_name: String, new_name: String) -> String:
	if (
		old_name == new_name
		or not is_valid_identifier(old_name)
		or not is_valid_identifier(new_name)
	):
		return source
	return _rename_references(source, "branches", old_name, new_name)


static func rename_local_symbol(
	source: String,
	kind: String,
	old_name: String,
	new_name: String,
) -> String:
	if old_name == new_name or not is_valid_local_symbol(kind, new_name):
		return source
	if kind == "branches":
		return rename_branch(source, old_name, new_name)
	return _rename_references(source, kind, old_name, new_name)


static func _rename_references(
	source: String, kind: String, old_name: String, new_name: String
) -> String:
	var references := get_local_symbol_references(source, kind, old_name)
	references.reverse()
	var updated := source
	var line_offsets := PackedInt32Array([0])
	for index: int in source.length():
		if source[index] == "\n":
			line_offsets.append(index + 1)
	for reference: Dictionary in references:
		var line_index := int(reference["line"]) - 1
		if line_index < 0 or line_index >= line_offsets.size():
			continue
		var start := line_offsets[line_index] + int(reference["start"])
		var end := line_offsets[line_index] + int(reference["end"])
		updated = updated.left(start) + new_name + updated.substr(end)
	return updated


static func is_valid_identifier(symbol: String) -> bool:
	var regex := RegEx.new()
	if regex.compile("^%s$" % IDENTIFIER_PATTERN) != OK:
		return false
	return regex.search(symbol) != null


static func is_valid_local_symbol(kind: String, symbol: String) -> bool:
	if kind == "variables":
		if symbol.length() < 2 or symbol.left(1) not in ["%", "$"]:
			return false
		return is_valid_identifier(symbol.substr(1))
	return is_valid_identifier(symbol)


static func _tokenize_line_spans(line: String) -> Array[Dictionary]:
	var tokens: Array[Dictionary] = []
	var lexer := KonadoScriptLexer.new()
	lexer.console_output_enabled = false
	for token: KonadoScriptToken in lexer.tokenize_line(line, 1):
		if token.type in [KonadoScriptToken.Type.NEWLINE, KonadoScriptToken.Type.EOF]:
			continue
		tokens.append(_token_span(token, line))
	return _merge_resource_path_tokens(tokens, line)


static func _merge_resource_path_tokens(
	tokens: Array[Dictionary], line: String
) -> Array[Dictionary]:
	var merged: Array[Dictionary] = []
	var token_index := 0
	while token_index < tokens.size():
		var token: Dictionary = tokens[token_index]
		var start := int(token["start"])
		var path_end := _resource_path_end(line, start)
		if path_end <= start:
			merged.append(token)
			token_index += 1
			continue
		(
			merged
			. append(
				{
					"text": line.substr(start, path_end - start),
					"start": start,
					"end": path_end,
					"quoted": false,
				}
			)
		)
		token_index += 1
		while token_index < tokens.size() and int(tokens[token_index]["start"]) < path_end:
			token_index += 1
	return merged


static func _resource_path_end(line: String, start: int) -> int:
	var has_prefix := false
	for prefix: String in RESOURCE_PATH_PREFIXES:
		if line.substr(start).begins_with(prefix):
			has_prefix = true
			break
	if not has_prefix:
		return -1
	var path_end := start
	while path_end < line.length() and line[path_end] not in [" ", "\t", "\r", "\n", "#"]:
		path_end += 1
	return path_end


static func _token_span(token: KonadoScriptToken, line: String) -> Dictionary:
	var start := token.column - 1
	var end := start + token.length
	var quoted := token.type == KonadoScriptToken.Type.STRING_LITERAL
	var item := {
		"text": str(token.value) if quoted else line.substr(start, token.length),
		"start": start + 1 if quoted else start,
		"end": maxi(start + 1, end - 1) if quoted else end,
		"quoted": quoted,
	}
	if quoted:
		item["quoted_start"] = start
		item["quoted_end"] = end
	return item


static func _append_argument_reference(
	references: Array[Dictionary],
	tokens: Array[Dictionary],
	index: int,
	kind: String,
	scope_name: String = "",
	role: String = "reference",
) -> void:
	if index < 0 or index >= tokens.size():
		return
	_append_token_reference(references, tokens[index], kind, role, scope_name)


static func _append_token_reference(
	references: Array[Dictionary],
	token: Dictionary,
	kind: String,
	role: String,
	scope_name: String = "",
) -> void:
	var name := String(token.get("text", ""))
	if name.is_empty():
		return
	var reference := {
		"kind": kind,
		"name": name,
		"role": role,
		"start": int(token["start"]),
		"end": int(token["end"]),
	}
	if not scope_name.is_empty():
		reference["scope_name"] = scope_name
	references.append(reference)


static func _append_quoted_token_reference(
	references: Array[Dictionary],
	token: Dictionary,
	kind: String,
	role: String,
) -> void:
	var quoted_token := token.duplicate()
	quoted_token["start"] = token.get("quoted_start", token["start"])
	quoted_token["end"] = token.get("quoted_end", token["end"])
	_append_token_reference(references, quoted_token, kind, role)


static func _get_dialogue_variable_references(
	line: String,
	tokens: Array[Dictionary],
) -> Array[Dictionary]:
	if not _is_dialogue_spans(tokens):
		return []
	var references := _get_string_variable_references(line, tokens[1])
	if bool(tokens[0]["quoted"]):
		references.append_array(_get_string_variable_references(line, tokens[0]))
	return references


static func _is_dialogue_spans(tokens: Array[Dictionary]) -> bool:
	if tokens.size() < 2 or not bool(tokens[1].get("quoted", false)):
		return false
	if bool(tokens[0].get("quoted", false)):
		return true
	var first := String(tokens[0].get("text", ""))
	return (
		first.begins_with("%")
		or first.begins_with("$")
		or not KonadoScriptLanguageCatalog.ROOT_KEYWORDS.has(first)
	)


static func _has_dialogue_voice_token(tokens: Array[Dictionary]) -> bool:
	return tokens.size() >= 3 and String(tokens[2].get("text", "")) != "["


static func _get_string_variable_references(
	line: String,
	token: Dictionary,
) -> Array[Dictionary]:
	var references: Array[Dictionary] = []
	_ensure_regexes()
	var content_start := int(token["start"])
	var content_end := int(token["end"])
	for match_result: RegExMatch in _variable_regex.search_all(line, content_start, content_end):
		var variable_token := {
			"text": match_result.get_string(),
			"start": match_result.get_start(),
			"end": match_result.get_end(),
		}
		_append_token_reference(references, variable_token, "variables", "reference")
		references[-1]["inside_string"] = true
	return references


static func _is_screentext_open_line(line: String) -> bool:
	return _is_screentext_open_spans(_tokenize_line_spans(line))


static func _is_screentext_open_spans(tokens: Array[Dictionary]) -> bool:
	return (
		tokens.size() >= 2
		and tokens[0].get("text") == "screentext"
		and tokens[1].get("text") == "{"
	)


static func _is_screentext_close_line(line: String) -> bool:
	return _is_screentext_close_spans(_tokenize_line_spans(line))


static func _is_screentext_close_spans(tokens: Array[Dictionary]) -> bool:
	return not tokens.is_empty() and tokens[0].get("text") == "}"


static func _append_remaining_reference(
	references: Array[Dictionary],
	tokens: Array[Dictionary],
	start_index: int,
	kind: String,
	role: String,
) -> void:
	if start_index < 0 or start_index >= tokens.size():
		return
	var name_parts := PackedStringArray()
	for index: int in range(start_index, tokens.size()):
		name_parts.append(String(tokens[index]["text"]))
	var token := {
		"text": " ".join(name_parts),
		"start": tokens[start_index]["start"],
		"end": tokens[-1]["end"],
	}
	_append_token_reference(references, token, kind, role)


static func _ensure_regexes() -> void:
	if _variable_regex != null:
		return
	_variable_regex = RegEx.new()
	_variable_regex.compile("(%|\\$)[\\p{L}_][\\p{L}\\p{N}_-]*")
