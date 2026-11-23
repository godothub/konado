extends RefCounted
class_name KonadoScriptLexer

## KonadoScript 词法分析器
## 将 .ks 源代码文本转换为 Token 流

const MAX_SOURCE_BYTES := 8 * 1024 * 1024
const MAX_SOURCE_LINES := 250_000
const MAX_TOKENS := 1_000_000
const MAX_DIAGNOSTICS := 256
const TOKEN_TAPE_SCRIPT := preload(
	"res://addons/konado/language/compiler/konado_script_token_tape.gd"
)

var console_output_enabled := true
var _errors: Array[String] = []
var _diagnostics: Array[Dictionary] = []
var _path: String = ""
var _column_offset := 0


## 获取词法分析错误列表
func get_errors() -> Array[String]:
	return _errors


func get_diagnostics() -> Array[Dictionary]:
	return _diagnostics


## Tokenize a complete source into the canonical compact stream shared by the
## compiler and editor. Consumers materialize short-lived token views on demand.
func tokenize(source: String, path: String = "") -> RefCounted:
	_errors.clear()
	_diagnostics.clear()
	_path = path
	var tokens: Variant = TOKEN_TAPE_SCRIPT.new()
	if source.to_utf8_buffer().size() > MAX_SOURCE_BYTES:
		_error(1, 1, "剧本超过 8 MiB 安全上限，请拆分为多个 KonadoScript 文件")
		return tokens
	var lines := source.split("\n")
	if lines.size() > MAX_SOURCE_LINES:
		_error(1, 1, "剧本行数超过 250000 行安全上限，请拆分文件")
		return tokens
	var indent_stack: Array[int] = [0]
	var line_offset := 0

	for i in range(lines.size()):
		if _errors.size() >= MAX_DIAGNOSTICS:
			return tokens
		var raw_line := String(lines[i])
		# Windows 换行会留下 CR；它不属于脚本内容，必须在分词前剥离。
		var line_text := raw_line.trim_suffix("\r")
		var line_num := i + 1
		var stripped := line_text.strip_edges()

		# 空行与注释行跳过
		if stripped.is_empty() or stripped.begins_with("#"):
			line_offset += raw_line.length() + 1
			continue

		# 只在缩进层级发生变化时发射结构 Token。这样 Parser 能准确区分
		# 同级语句、子块和块结束，而不是把每个带空白的行都当成“某种缩进”。
		var indentation := _measure_indentation(line_text, line_num)
		if not indentation["valid"]:
			line_offset += raw_line.length() + 1
			continue
		var indent_columns := int(indentation["columns"])
		var current_indent := indent_stack.back()
		if indent_columns > current_indent:
			if indent_columns != current_indent + 4:
				_error(line_num, 1, "缩进每次只能增加一级（4 个空格或 1 个制表符）")
				line_offset += raw_line.length() + 1
				continue
			indent_stack.append(indent_columns)
			var indent_token := KonadoScriptToken.new(
				KonadoScriptToken.Type.INDENT, indent_columns, line_num, 1
			)
			indent_token.start_offset = line_offset
			indent_token.end_offset = line_offset
			tokens.append(indent_token)
		elif indent_columns < current_indent:
			while indent_stack.size() > 1 and indent_columns < indent_stack.back():
				indent_stack.pop_back()
				var dedent := KonadoScriptToken.new(
					KonadoScriptToken.Type.DEDENT, indent_columns, line_num, 1
				)
				dedent.start_offset = line_offset
				dedent.end_offset = line_offset
				tokens.append(dedent)
			if indent_columns != indent_stack.back():
				_error(line_num, 1, "缩进未对齐到已有层级")
				line_offset += raw_line.length() + 1
				continue

		# 对该行内容进行词法分析
		var content := line_text.strip_edges(true, false)
		var leading_columns := line_text.length() - content.length()
		_column_offset = leading_columns
		var error_count := _errors.size()
		var line_tokens := _tokenize_line(content, line_num)
		if _errors.size() > error_count:
			line_offset += raw_line.length() + 1
			continue
		for token: KonadoScriptToken in line_tokens:
			token.column += leading_columns
			token.start_offset = line_offset + token.column - 1
			token.end_offset = token.start_offset + token.length
		for token: KonadoScriptToken in line_tokens:
			tokens.append(token)
		if tokens.size() > MAX_TOKENS:
			_error(line_num, 1, "剧本 Token 数超过 1000000 个安全上限")
			tokens.clear()
			return tokens

		# 行结束标记
		var newline := KonadoScriptToken.new(
			KonadoScriptToken.Type.NEWLINE, "", line_num, line_text.length() + 1
		)
		newline.start_offset = line_offset + line_text.length()
		newline.end_offset = newline.start_offset + 1
		tokens.append(newline)
		line_offset += raw_line.length() + 1

	var eof_line := lines.size() + 1
	while indent_stack.size() > 1:
		indent_stack.pop_back()
		var dedent := KonadoScriptToken.new(KonadoScriptToken.Type.DEDENT, 0, eof_line, 1)
		dedent.start_offset = source.length()
		dedent.end_offset = source.length()
		tokens.append(dedent)
	var eof := KonadoScriptToken.new(KonadoScriptToken.Type.EOF, "", eof_line, 1)
	eof.start_offset = source.length()
	eof.end_offset = source.length()
	tokens.append(eof)
	return tokens


## 对单行进行词法分析（用于 parse_single_line）
func tokenize_line(line: String, line_number: int) -> Array[KonadoScriptToken]:
	_errors.clear()
	_diagnostics.clear()
	_path = ""
	# 单行预览/索引同样要剥离 Windows 行尾 CR。
	line = line.trim_suffix("\r")
	var stripped := line.strip_edges(true, false)
	if stripped.is_empty():
		return [KonadoScriptToken.new(KonadoScriptToken.Type.EOF, "", line_number, 0)]

	var leading_columns := line.length() - stripped.length()
	_column_offset = leading_columns
	var tokens := _tokenize_line(stripped, line_number)
	for token: KonadoScriptToken in tokens:
		token.column += leading_columns
		token.start_offset = token.column - 1
		token.end_offset = token.start_offset + token.length
	var newline := KonadoScriptToken.new(
		KonadoScriptToken.Type.NEWLINE, "", line_number, line.length() + 1
	)
	newline.start_offset = line.length()
	newline.end_offset = line.length()
	tokens.append(newline)
	var eof := KonadoScriptToken.new(KonadoScriptToken.Type.EOF, "", line_number, 0)
	eof.start_offset = line.length()
	eof.end_offset = line.length()
	tokens.append(eof)
	return tokens


# ============================================================
# 内部实现
# ============================================================


## 测量行首缩进。制表符按一个完整层级（4 列）处理；不同逻辑行可以
## 分别使用制表符或四空格，便于安全读取既有项目和不同编辑器生成的
## 文件。同一行前缀仍禁止混用两种字符，避免视觉缩进与语义缩进不一致。
func _measure_indentation(line: String, line_num: int) -> Dictionary:
	var spaces := 0
	var tabs := 0
	for ch in line:
		if ch == " ":
			spaces += 1
		elif ch == "\t":
			tabs += 1
		else:
			break
	if spaces > 0 and tabs > 0:
		_error(line_num, 1, "行首不能混用制表符和空格缩进")
		return {"valid": false, "columns": 0, "style": ""}
	if spaces % 4 != 0:
		_error(line_num, 1, "空格缩进必须是 4 的整数倍")
		return {"valid": false, "columns": 0, "style": ""}
	return {
		"valid": true,
		"columns": tabs * 4 + spaces,
	}


## 将一行文本（已 strip_edges）拆分为 Token 数组
func _tokenize_line(line: String, line_num: int) -> Array[KonadoScriptToken]:
	var tokens: Array[KonadoScriptToken] = []
	var pos := 0
	var length := line.length()

	while pos < length:
		# 跳过空白
		while pos < length and (line[pos] == " " or line[pos] == "\t"):
			pos += 1
		if pos >= length:
			break

		var ch := line[pos]

		# 行内注释（字符串内部由字符串读取器处理）
		if ch == "#":
			break

		# 字符串字面量
		if ch == '"':
			var string_start := pos
			var tok := _read_string_literal(line, pos, line_num)
			if tok == null:
				return []
			tokens.append(tok)
			pos = string_start + tok.length
			continue

		# 运算符 ->
		if ch == "-" and pos + 1 < length and line[pos + 1] == ">":
			tokens.append(
				KonadoScriptToken.new(KonadoScriptToken.Type.OP_ARROW, "->", line_num, pos + 1)
			)
			pos += 2
			continue

		# 双字符运算符
		if pos + 1 < length:
			var two := line.substr(pos, 2)
			if two == "==":
				tokens.append(
					KonadoScriptToken.new(KonadoScriptToken.Type.OP_EQ, "==", line_num, pos + 1)
				)
				pos += 2
				continue
			if two == "!=":
				tokens.append(
					KonadoScriptToken.new(KonadoScriptToken.Type.OP_NEQ, "!=", line_num, pos + 1)
				)
				pos += 2
				continue
			if two == ">=":
				tokens.append(
					KonadoScriptToken.new(KonadoScriptToken.Type.OP_GTE, ">=", line_num, pos + 1)
				)
				pos += 2
				continue
			if two == "<=":
				tokens.append(
					KonadoScriptToken.new(KonadoScriptToken.Type.OP_LTE, "<=", line_num, pos + 1)
				)
				pos += 2
				continue

		# 单字符运算符
		if ch == "=":
			tokens.append(
				KonadoScriptToken.new(KonadoScriptToken.Type.OP_ASSIGN, "=", line_num, pos + 1)
			)
			pos += 1
			continue
		if ch == ">":
			tokens.append(
				KonadoScriptToken.new(KonadoScriptToken.Type.OP_GT, ">", line_num, pos + 1)
			)
			pos += 1
			continue
		if ch == "<":
			tokens.append(
				KonadoScriptToken.new(KonadoScriptToken.Type.OP_LT, "<", line_num, pos + 1)
			)
			pos += 1
			continue
		if ch == ":":
			tokens.append(
				KonadoScriptToken.new(KonadoScriptToken.Type.COLON, ":", line_num, pos + 1)
			)
			pos += 1
			continue

		# 定界符 { }
		if ch == "{":
			tokens.append(
				KonadoScriptToken.new(KonadoScriptToken.Type.LBRACE, "{", line_num, pos + 1)
			)
			pos += 1
			continue
		if ch == "}":
			tokens.append(
				KonadoScriptToken.new(KonadoScriptToken.Type.RBRACE, "}", line_num, pos + 1)
			)
			pos += 1
			continue
		if ch == "[":
			tokens.append(
				KonadoScriptToken.new(KonadoScriptToken.Type.LBRACKET, "[", line_num, pos + 1)
			)
			pos += 1
			continue
		if ch == "]":
			tokens.append(
				KonadoScriptToken.new(KonadoScriptToken.Type.RBRACKET, "]", line_num, pos + 1)
			)
			pos += 1
			continue

		# 变量引用 %name 或 $name
		if ch == "%" or ch == "$":
			var ref_tok := _read_variable_ref(line, pos, line_num)
			if ref_tok:
				tokens.append(ref_tok)
				pos += 1 + ref_tok.value.name.length()  # prefix + name
				continue
			# 孤立的 %/$ 必须至少消费一个字符，避免编辑器实时检查进入死循环。
			tokens.append(
				KonadoScriptToken.new(KonadoScriptToken.Type.IDENTIFIER, ch, line_num, pos + 1)
			)
			pos += 1
			continue

		# 数字字面量（含负号开头）
		if ch.is_valid_int() or (ch == "-" and pos + 1 < length and line[pos + 1].is_valid_int()):
			var num_tok := _read_number(line, pos, line_num)
			tokens.append(num_tok)
			# value 现在是原始字符串，长度一致
			pos += num_tok.value.length()
			continue

		# 标识符或关键字
		if _is_ident_start(ch):
			var word_tok := _read_word(line, pos, line_num)
			pos += (
				word_tok.value.length()
				if word_tok.type == KonadoScriptToken.Type.IDENTIFIER
				else str(word_tok.value).length()
			)
			tokens.append(word_tok)
			continue

		# 未识别字符 —— 作为单字符 IDENTIFIER 发射（供 parser 拼接路径等用途）
		tokens.append(
			KonadoScriptToken.new(KonadoScriptToken.Type.IDENTIFIER, ch, line_num, pos + 1)
		)
		pos += 1

	return tokens


## 读取字符串字面量。支持可移植的明确转义，未知转义直接拒绝。
func _read_string_literal(line: String, start: int, line_num: int) -> KonadoScriptToken:
	var pos := start + 1  # 跳过开头引号
	var result := ""
	var length := line.length()

	while pos < length:
		var ch := line[pos]
		if ch == "\\":
			if pos + 1 >= length:
				_error(line_num, pos + 1, "字符串末尾的转义符不完整")
				return null
			var escaped := line[pos + 1]
			match escaped:
				'"':
					result += '"'
				"\\":
					result += "\\"
				"n":
					result += "\n"
				"r":
					result += "\r"
				"t":
					result += "\t"
				_:
					_error(line_num, pos + 1, "不支持的字符串转义 \\%s" % escaped)
					return null
			pos += 2
			continue
		if ch == '"':
			return KonadoScriptToken.new(
				KonadoScriptToken.Type.STRING_LITERAL, result, line_num, start + 1, pos - start + 1
			)
		result += ch
		pos += 1

	_error(line_num, start + 1, "字符串字面量未闭合")
	return null


## 读取变量引用 %name 或 $name
func _read_variable_ref(line: String, start: int, line_num: int) -> KonadoScriptToken:
	var prefix := line[start]
	var pos := start + 1
	var length := line.length()

	if pos >= length or not _is_ident_start(line[pos]):
		return null

	var name_start := pos
	while pos < length and _is_ident_char(line[pos]):
		pos += 1

	var var_name := line.substr(name_start, pos - name_start)
	return (
		KonadoScriptToken
		. new(
			KonadoScriptToken.Type.VARIABLE_REF,
			{"prefix": prefix, "name": var_name},
			line_num,
			start + 1,
			pos - start,
		)
	)


## 读取数字字面量
func _read_number(line: String, start: int, line_num: int) -> KonadoScriptToken:
	var pos := start
	var length := line.length()
	var has_dot := false

	if line[pos] == "-":
		pos += 1

	while pos < length:
		if line[pos] == "." and not has_dot:
			has_dot = true
			pos += 1
		elif line[pos].is_valid_int():
			pos += 1
		else:
			break

	var num_str := line.substr(start, pos - start)
	# 保留原始字符串作为 value，避免前导零等信息丢失（如 "00" → 0 → "0"）
	var value: Variant = num_str

	return KonadoScriptToken.new(KonadoScriptToken.Type.NUMBER_LITERAL, value, line_num, start + 1)


## 跳过数字字符，返回结束位置
func _skip_number_chars(line: String, start: int) -> int:
	var pos := start
	var length := line.length()
	if pos < length and line[pos] == "-":
		pos += 1
	var has_dot := false
	while pos < length:
		if line[pos] == "." and not has_dot:
			has_dot = true
			pos += 1
		elif line[pos].is_valid_int():
			pos += 1
		else:
			break
	return pos


## 读取标识符/关键字
func _read_word(line: String, start: int, line_num: int) -> KonadoScriptToken:
	var pos := start
	var length := line.length()

	while pos < length and _is_ident_char(line[pos]):
		pos += 1

	var word := line.substr(start, pos - start)

	# 特殊处理 "else:" —— 包含冒号
	if word == "else" and pos < length and line[pos] == ":":
		pos += 1
		return KonadoScriptToken.new(KonadoScriptToken.Type.KW_ELSE, "else:", line_num, start + 1)

	# 关键字查找
	if KonadoScriptToken.KEYWORDS.has(word):
		return KonadoScriptToken.new(KonadoScriptToken.KEYWORDS[word], word, line_num, start + 1)

	return KonadoScriptToken.new(KonadoScriptToken.Type.IDENTIFIER, word, line_num, start + 1)


## 判断字符是否可作为标识符开头
func _is_ident_start(ch: String) -> bool:
	if ch.length() != 1:
		return false
	var code := ch.unicode_at(0)
	# a-z, A-Z, _, 以及 CJK 字符（Unicode >= 0x80）
	return (code >= 65 and code <= 90) or (code >= 97 and code <= 122) or code == 95 or code >= 0x80


## 判断字符是否可作为标识符中间字符
func _is_ident_char(ch: String) -> bool:
	if ch.length() != 1:
		return false
	var code := ch.unicode_at(0)
	return (
		(code >= 65 and code <= 90)
		or (code >= 97 and code <= 122)
		or (code >= 48 and code <= 57)
		or code == 95
		or code == 45
		or code >= 0x80
	)


## 错误记录
func _error(line_num: int, col: int, msg: String) -> void:
	if _errors.size() >= MAX_DIAGNOSTICS:
		return
	var column := col + _column_offset
	var err := "词法错误：%s [行：%d, 列：%d] %s" % [_path, line_num, column, msg]
	_errors.append(err)
	var description := KonadoScriptDiagnosticMessages.describe(msg, "zh_CN")
	(
		_diagnostics
		. append(
			{
				"severity": "error",
				"stage": "lexer",
				"path": _path,
				"line": maxi(1, line_num),
				"column": maxi(1, column),
				"end_line": maxi(1, line_num),
				"end_column": maxi(2, column + 1),
				"code": description["code"],
				"arguments": description["arguments"],
				"raw_message": msg,
			}
		)
	)
	if console_output_enabled:
		push_error(err)
