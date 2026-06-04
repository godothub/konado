extends RefCounted
class_name KonadoScriptsInterpreter

## Konado 脚本编译器
##
## 编译管线：Lexer → Parser → Analyzer → Emitter
##   - KS_Lexer     : 词法分析，将源代码转换为 Token 流
##   - KS_Parser    : 语法分析，将 Token 流转换为 AST
##   - KS_Analyzer  : 语义分析，验证标签引用、演员生命周期等
##   - KS_Emitter   : 代码生成，将 AST 转换为 KND_Shot / KND_Dialogue 图结构

var _compiler: KS_Compiler


func _init() -> void:
	_compiler = KS_Compiler.new()


## 全文编译模式：.ks 文件 → KND_Shot
func process_scripts_to_data(path: String) -> KND_Shot:
	var shot := _compiler.compile_file(path)
	if shot:
		# 从分析器同步角色依赖
		if _compiler._analyzer:
			shot.dep_characters = _compiler._analyzer.get_dep_characters()
	return shot


## 单行编译模式
func parse_single_line(line: String, line_number: int, path: String) -> KND_Dialogue:
	return _compiler.compile_line(line, line_number, path)
