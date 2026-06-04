extends RefCounted
class_name KS_Lexer

## KS 词法分析器
## 将 .ks 源代码文本转换为 Token 流

var _errors: Array[String] = []
var _path: String = ""


func _init() -> void:
	pass


## 获取词法分析错误列表
func get_errors() -> Array[String]:
	return _errors


## 对完整源代码进行词法分析，返回 Token 数组；出错返回空数组
func tokenize(source: String, path: String = "") -> Array[KS_Token]:
	_errors.clear()
	_path = path
	var tokens: Array[KS_Token] = []
	var lines := source.split("\n")

	for i in range(lines.size()):
		var raw_line := lines[i]
		var line_num := i + 2  # 与原解释器保持一致的行号偏移
		var stripped := raw_line.strip_edges()

		# 空行与注释行跳过
		if stripped.is_empty() or stripped.begins_with("#"):
			continue

		# 检测缩进
		var indent_level := _measure_indent(raw_line)
		if indent_level > 0:
			tokens.append(KS_Token.new(KS_Token.Type.INDENT, indent_level, line_num, 1))

		# 对该行内容进行词法分析
		var line_tokens := _tokenize_line(stripped, line_num)
		if line_tokens.is_empty() and not _errors.is_empty():
			return []
		tokens.append_array(line_tokens)

		# 行结束标记
		tokens.append(KS_Token.new(KS_Token.Type.NEWLINE, "", line_num, stripped.length() + 1))

	tokens.append(KS_Token.new(KS_Token.Type.EOF, "", 0, 0))
	return tokens


## 对单行进行词法分析（用于 parse_single_line）
func tokenize_line(line: String, line_number: int) -> Array[KS_Token]:
	_errors.clear()
	_path = ""
	var stripped := line.strip_edges()
	if stripped.is_empty():
		return [KS_Token.new(KS_Token.Type.EOF, "", line_number, 0)]

	var tokens := _tokenize_line(stripped, line_number)
	tokens.append(KS_Token.new(KS_Token.Type.NEWLINE, "", line_number, stripped.length() + 1))
	tokens.append(KS_Token.new(KS_Token.Type.EOF, "", line_number, 0))
	return tokens


# ============================================================
# 内部实现
# ============================================================

## 测量行首缩进等级（4空格或1制表符 = 1级）
func _measure_indent(line: String) -> int:
	var spaces := 0
	var tabs := 0
	for ch in line:
		if ch == " ":
			spaces += 1
		elif ch == "\t":
			tabs += 1
		else:
			break
	if tabs > 0:
		return tabs
	return spaces / 4


## 将一行文本（已 strip_edges）拆分为 Token 数组
func _tokenize_line(line: String, line_num: int) -> Array[KS_Token]:
	var tokens: Array[KS_Token] = []
	var pos := 0
	var length := line.length()

	while pos < length:
		# 跳过空白
		while pos < length and (line[pos] == " " or line[pos] == "\t"):
			pos += 1
		if pos >= length:
			break

		var ch := line[pos]

		# 字符串字面量
		if ch == "\"":
			var tok := _read_string_literal(line, pos, line_num)
			if tok == null:
				return []
			tokens.append(tok)
			pos += tok.value.length() + 2  # 内容长度 + 两个引号
			# 跳过转义引号导致的偏移修正
			var raw_len := _calc_raw_string_length(line, pos - tok.value.length() - 2)
			pos = (pos - tok.value.length() - 2) + raw_len
			continue

		# 运算符 ->
		if ch == "-" and pos + 1 < length and line[pos + 1] == ">":
			tokens.append(KS_Token.new(KS_Token.Type.OP_ARROW, "->", line_num, pos + 1))
			pos += 2
			continue

		# 双字符运算符
		if pos + 1 < length:
			var two := line.substr(pos, 2)
			if two == "==":
				tokens.append(KS_Token.new(KS_Token.Type.OP_EQ, "==", line_num, pos + 1))
				pos += 2
				continue
			if two == "!=":
				tokens.append(KS_Token.new(KS_Token.Type.OP_NEQ, "!=", line_num, pos + 1))
				pos += 2
				continue
			if two == ">=":
				tokens.append(KS_Token.new(KS_Token.Type.OP_GTE, ">=", line_num, pos + 1))
				pos += 2
				continue
			if two == "<=":
				tokens.append(KS_Token.new(KS_Token.Type.OP_LTE, "<=", line_num, pos + 1))
				pos += 2
				continue

		# 单字符运算符
		if ch == "=":
			tokens.append(KS_Token.new(KS_Token.Type.OP_ASSIGN, "=", line_num, pos + 1))
			pos += 1
			continue
		if ch == ">":
			tokens.append(KS_Token.new(KS_Token.Type.OP_GT, ">", line_num, pos + 1))
			pos += 1
			continue
		if ch == "<":
			tokens.append(KS_Token.new(KS_Token.Type.OP_LT, "<", line_num, pos + 1))
			pos += 1
			continue
		if ch == ":":
			tokens.append(KS_Token.new(KS_Token.Type.COLON, ":", line_num, pos + 1))
			pos += 1
			continue

		# 变量引用 %name 或 $name
		if ch == "%" or ch == "$":
			var ref_tok := _read_variable_ref(line, pos, line_num)
			if ref_tok:
				tokens.append(ref_tok)
				pos += 1 + ref_tok.value.name.length()  # prefix + name
				continue
			# 如果 % 或 $ 后无标识符，当作标识符的一部分处理
			var word_tok := _read_word(line, pos, line_num)
			tokens.append(word_tok)
			pos += word_tok.value.length()
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
			pos += word_tok.value.length() if word_tok.type == KS_Token.Type.IDENTIFIER else str(word_tok.value).length()
			tokens.append(word_tok)
			continue

		# 未识别字符 —— 作为单字符 IDENTIFIER 发射（供 parser 拼接路径等用途）
		tokens.append(KS_Token.new(KS_Token.Type.IDENTIFIER, ch, line_num, pos + 1))
		pos += 1

	return tokens


## 读取字符串字面量 "..."（支持 \" 转义）
func _read_string_literal(line: String, start: int, line_num: int) -> KS_Token:
	var pos := start + 1  # 跳过开头引号
	var result := ""
	var length := line.length()

	while pos < length:
		var ch := line[pos]
		if ch == "\\" and pos + 1 < length and line[pos + 1] == "\"":
			result += "\""
			pos += 2
			continue
		if ch == "\"":
			return KS_Token.new(KS_Token.Type.STRING_LITERAL, result, line_num, start + 1)
		result += ch
		pos += 1

	_error(line_num, start + 1, "字符串字面量未闭合")
	return null


## 计算原始字符串（含转义）在源代码中的实际长度
func _calc_raw_string_length(line: String, start: int) -> int:
	var pos := start + 1  # 跳过开头引号
	var length := line.length()
	while pos < length:
		if line[pos] == "\\" and pos + 1 < length and line[pos + 1] == "\"":
			pos += 2
			continue
		if line[pos] == "\"":
			return pos - start + 1
		pos += 1
	return pos - start


## 读取变量引用 %name 或 $name
func _read_variable_ref(line: String, start: int, line_num: int) -> KS_Token:
	var prefix := line[start]
	var pos := start + 1
	var length := line.length()

	if pos >= length or not _is_ident_start(line[pos]):
		return null

	var name_start := pos
	while pos < length and _is_ident_char(line[pos]):
		pos += 1

	var var_name := line.substr(name_start, pos - name_start)
	return KS_Token.new(KS_Token.Type.VARIABLE_REF, {"prefix": prefix, "name": var_name}, line_num, start + 1)


## 读取数字字面量
func _read_number(line: String, start: int, line_num: int) -> KS_Token:
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

	return KS_Token.new(KS_Token.Type.NUMBER_LITERAL, value, line_num, start + 1)


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
func _read_word(line: String, start: int, line_num: int) -> KS_Token:
	var pos := start
	var length := line.length()

	while pos < length and _is_ident_char(line[pos]):
		pos += 1

	var word := line.substr(start, pos - start)

	# 特殊处理 "else:" —— 包含冒号
	if word == "else" and pos < length and line[pos] == ":":
		pos += 1
		return KS_Token.new(KS_Token.Type.KW_ELSE, "else:", line_num, start + 1)

	# 关键字查找
	if KS_Token.KEYWORDS.has(word):
		return KS_Token.new(KS_Token.KEYWORDS[word], word, line_num, start + 1)

	return KS_Token.new(KS_Token.Type.IDENTIFIER, word, line_num, start + 1)


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
	return (code >= 65 and code <= 90) or (code >= 97 and code <= 122) or (code >= 48 and code <= 57) or code == 95 or code >= 0x80


## 错误记录
func _error(line_num: int, col: int, msg: String) -> void:
	var err := "词法错误：%s [行：%d, 列：%d] %s" % [_path, line_num, col, msg]
	_errors.append(err)
	push_error(err)
