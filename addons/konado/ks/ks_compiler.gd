extends RefCounted
class_name KS_Compiler

## KS 编译器管线
## 串联 Lexer → Parser → Analyzer → Emitter 四个阶段

var _lexer: KS_Lexer
var _parser: KS_Parser
var _analyzer: KS_Analyzer
var _emitter: KS_Emitter

var _errors: Array[String] = []
var _warnings: Array[String] = []


func _init() -> void:
	_lexer = KS_Lexer.new()
	_parser = KS_Parser.new()
	_analyzer = KS_Analyzer.new()
	_emitter = KS_Emitter.new()


## 获取编译错误
func get_errors() -> Array[String]:
	return _errors


## 获取编译警告
func get_warnings() -> Array[String]:
	return _warnings


## 编译 ks 文件
func compile_file(path: String) -> KND_Shot:
	_errors.clear()
	_warnings.clear()

	if not FileAccess.file_exists(path):
		_report_error(path, 0, "文件不存在，无法打开脚本文件")
		return null

	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		_report_error(path, 0, "无法打开脚本文件")
		return null

	var source := file.get_as_text()
	file.close()

	return compile_string(source, path)


## 编译源代码字符串
func compile_string(source: String, path: String = "") -> KND_Shot:
	_errors.clear()
	_warnings.clear()

	_report_info(path, 0, "开始编译脚本文件")

	# 词法分析
	var tokens := _lexer.tokenize(source, path)
	if tokens.is_empty() and not _lexer.get_errors().is_empty():
		_errors.append_array(_lexer.get_errors())
		return null

	# 语法分析
	var ast := _parser.parse(tokens, path)
	if ast == null:
		_errors.append_array(_parser.get_errors())
		return null

	# 语义分析
	if not _analyzer.analyze(ast, path):
		_errors.append_array(_analyzer.get_errors())
		_warnings.append_array(_analyzer.get_warnings())
		return null
	_warnings.append_array(_analyzer.get_warnings())

	# 生成
	var shot: KND_Shot = _emitter.emit(ast, path)

	_report_info(path, 0, "编译完成 —— 文件：%s 对话数量：%d" % [path, shot.dialogues.size()])

	return shot


## 编译单行 → KND_Dialogue（跳过语义分析阶段）
func compile_line(line: String, line_number: int, path: String = "") -> KND_Dialogue:
	_errors.clear()
	_warnings.clear()

	var stripped := line.strip_edges()
	if stripped.is_empty():
		return null

	# 词法分析
	var tokens := _lexer.tokenize_line(stripped, line_number)
	if tokens.is_empty() and not _lexer.get_errors().is_empty():
		_errors.append_array(_lexer.get_errors())
		return null

	# 语法分析
	var node := _parser.parse_single_statement(tokens, path)
	if node == null:
		_errors.append_array(_parser.get_errors())
		return null

	# 直接发射（跳过语义分析，单行模式无上下文）
	return _emitter.emit_single(node)
	
	
func _report_error(path: String, line: int, msg: String) -> void:
	var err := "错误：%s [行：%d] %s" % [path, line, msg]
	_errors.append(err)
	push_error(err)


func _report_info(path: String, line: int, msg: String) -> void:
	print("信息：%s [行：%d] %s" % [path, line, msg])
