extends "res://addons/konado/language/compiler/konado_script_parser_support.gd"

## Choice statement parsing: consecutive `choice` lines, their target branches,
## and the optional `if <condition>` / `once` suffixes.
## Kept beside KonadoScriptParser so each file stays within the file-size limit.


## 选项组解析：合并连续的 choice 行
func _parse_choice_group() -> KonadoScriptSyntaxTree.ChoiceGroupNode:
	var node := KonadoScriptSyntaxTree.ChoiceGroupNode.new()
	node.line = _peek().line

	while not _at_end() and _check(KonadoScriptToken.Type.KW_CHOICE):
		var option := _parse_single_choice_line(node, node.options.is_empty())
		if option == null:
			return null
		node.options.append(option)
		_skip_newlines()

	return node


## 解析单个 choice 行的内容
func _parse_single_choice_line(
	group: KonadoScriptSyntaxTree.ChoiceGroupNode, allow_parameters: bool
) -> KonadoScriptSyntaxTree.ChoiceOption:
	_advance()  # 跳过 choice

	var option := KonadoScriptSyntaxTree.ChoiceOption.new()

	# 读取选项文本
	var text_tok := _expect(KonadoScriptToken.Type.STRING_LITERAL)
	if text_tok == null:
		_error("choice 缺少选项文本")
		return null
	option.text = text_tok.value

	# 读取箭头 ->
	if not _check(KonadoScriptToken.Type.OP_ARROW):
		_error("choice 缺少 -> 运算符")
		return null
	_advance()

	# 读取目标分支
	var target_tok := _expect_any_value()
	if target_tok == null:
		_error("choice 缺少目标分支名")
		return null
	option.branch_target = str(target_tok.value)

	# 可选后缀：if <条件> / once（顺序任意，各最多一次）
	if not _parse_choice_suffixes(option):
		_finish_statement_line("choice 目标分支后存在多余内容")
		return null

	if allow_parameters:
		_parse_named_parameters(group)
	elif _check(KonadoScriptToken.Type.LBRACKET):
		_error("choice 组的命名参数只能写在第一项")
	_finish_statement_line("choice 目标分支后存在多余内容")
	return option


## 解析 choice 的可选后缀：`if <变量> <运算符> <值>` 与 `once`。
## 不认识的 token 留给调用方的“多余内容”诊断，避免重复报错。
func _parse_choice_suffixes(option: KonadoScriptSyntaxTree.ChoiceOption) -> bool:
	while not _at_line_end() and not _check(KonadoScriptToken.Type.LBRACKET):
		var tok := _peek()
		if tok.type == KonadoScriptToken.Type.KW_IF:
			if not option.condition.is_empty():
				_error("choice 条件重复")
				return false
			_advance()
			var condition := _parse_choice_condition()
			if condition.is_empty():
				return false
			option.condition = condition
			continue
		if tok.type == KonadoScriptToken.Type.IDENTIFIER and String(tok.value).to_lower() == "once":
			if option.once:
				_error("choice once 重复")
				return false
			_advance()
			option.once = true
			continue
		break
	return true


## 解析 choice 的可见条件，复用 if 语句的类型规则。
func _parse_choice_condition() -> Dictionary:
	var var_tok := _expect(KonadoScriptToken.Type.VARIABLE_REF)
	if var_tok == null:
		_error('choice 条件缺少变量引用（格式：choice "文本" -> 分支 if %变量名 == 值）')
		return {}
	var result := {
		"prefix": String(var_tok.value.prefix),
		"name": String(var_tok.value.name),
	}

	var op_tok := _peek()
	if _at_line_end() or op_tok.type == KonadoScriptToken.Type.LBRACKET:
		_error("choice 条件缺少比较运算符")
		return {}
	var operator := ""
	match op_tok.type:
		KonadoScriptToken.Type.OP_EQ:
			operator = "=="
		KonadoScriptToken.Type.OP_NEQ:
			operator = "!="
		KonadoScriptToken.Type.OP_GT:
			operator = ">"
		KonadoScriptToken.Type.OP_LT:
			operator = "<"
		KonadoScriptToken.Type.OP_GTE:
			operator = ">="
		KonadoScriptToken.Type.OP_LTE:
			operator = "<="
		_:
			_error("choice 条件的比较运算符无效: %s" % str(op_tok.value))
			return {}
	_advance()
	result["op"] = operator

	var val_tok := _peek()
	if (
		val_tok.type
		not in [
			KonadoScriptToken.Type.NUMBER_LITERAL,
			KonadoScriptToken.Type.STRING_LITERAL,
			KonadoScriptToken.Type.IDENTIFIER,
			KonadoScriptToken.Type.VARIABLE_REF,
		]
	):
		_error("choice 条件缺少目标值")
		return {}
	_advance()
	result["value"] = _literal_value(val_tok)
	return result
