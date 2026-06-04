extends RefCounted
class_name KS_Parser

## KS 语法分析器
## 将 Token 流转换为抽象语法树（AST）

var _tokens: Array[KS_Token] = []
var _pos: int = 0
var _path: String = ""
var _errors: Array[String] = []


func _init() -> void:
	pass


## 获取解析错误列表
func get_errors() -> Array[String]:
	return _errors


## 解析完整 Token 流为 AST 根节点；出错返回 null
func parse(tokens: Array[KS_Token], path: String = "") -> KS_AST.ScriptNode:
	_tokens = tokens
	_pos = 0
	_path = path
	_errors.clear()

	var script := KS_AST.ScriptNode.new()

	while not _at_end():
		_skip_newlines()
		if _at_end():
			break

		# 跳过缩进标记（顶层不应有缩进，但容错处理）
		if _check(KS_Token.Type.INDENT):
			_advance()
			_skip_to_next_line()
			continue

		var stmt := _parse_statement()
		if stmt == null:
			if not _errors.is_empty():
				return null
			_skip_to_next_line()
			continue

		script.statements.append(stmt)

	return script


## 解析单行 Token 为单个 AST 节点（用于 parse_single_line）
func parse_single_statement(tokens: Array[KS_Token], path: String = "") -> KS_AST.ASTNode:
	_tokens = tokens
	_pos = 0
	_path = path
	_errors.clear()

	_skip_newlines()
	if _at_end():
		return null

	return _parse_statement()


# ============================================================
# 语句分发
# ============================================================

func _parse_statement() -> KS_AST.ASTNode:
	var tok := _peek()

	# 对话（以字符串字面量开头）
	if tok.type == KS_Token.Type.STRING_LITERAL:
		return _parse_dialogue()

	match tok.type:
		KS_Token.Type.KW_BACKGROUND:
			return _parse_background()
		KS_Token.Type.KW_ACTOR:
			return _parse_actor()
		KS_Token.Type.KW_PLAY:
			return _parse_play_audio()
		KS_Token.Type.KW_STOP:
			return _parse_stop_audio()
		KS_Token.Type.KW_CHOICE:
			return _parse_choice_group()
		KS_Token.Type.KW_BRANCH:
			return _parse_branch()
		KS_Token.Type.KW_IF:
			return _parse_if_else()
		KS_Token.Type.KW_ELSE:
			# 顶层出现 else/endif 说明已被 if 消费或格式错误，跳过
			_advance()
			_skip_to_next_line()
			return null
		KS_Token.Type.KW_ENDIF:
			_advance()
			_skip_to_next_line()
			return null
		KS_Token.Type.KW_SET, KS_Token.Type.KW_ADD, KS_Token.Type.KW_SUB, \
		KS_Token.Type.KW_MUL, KS_Token.Type.KW_DIV:
			return _parse_variable()
		KS_Token.Type.KW_JUMP_BRANCH:
			return _parse_jump_branch()
		KS_Token.Type.KW_JUMP:
			return _parse_jump()
		KS_Token.Type.KW_SIGNAL:
			return _parse_signal()
		KS_Token.Type.KW_ACHIEVEMENT:
			return _parse_achievement()
		KS_Token.Type.KW_END:
			return _parse_end()

	_error("无法识别的语法：%s" % str(tok))
	return null


# ============================================================
# 各语句解析
# ============================================================

## 对话解析：  "角色" "内容" [voice_id]
func _parse_dialogue() -> KS_AST.DialogueNode:
	var node := KS_AST.DialogueNode.new()
	node.line = _peek().line

	var char_tok := _expect(KS_Token.Type.STRING_LITERAL)
	if char_tok == null:
		return null
	node.character_id = char_tok.value

	var content_tok := _expect(KS_Token.Type.STRING_LITERAL)
	if content_tok == null:
		return null
	node.content = content_tok.value

	# 可选的配音标签
	if not _at_line_end():
		var voice_tok := _peek()
		if voice_tok.type == KS_Token.Type.IDENTIFIER or voice_tok.type == KS_Token.Type.STRING_LITERAL:
			node.voice_id = str(_advance().value)

	_skip_to_next_line()
	return node


## 背景切换解析：  background <image_name> [effect]
func _parse_background() -> KS_AST.BackgroundNode:
	var node := KS_AST.BackgroundNode.new()
	node.line = _peek().line
	_advance()  # 跳过 background

	var name_tok := _expect_any_value()
	if name_tok == null:
		_error("background 缺少图片资源名")
		return null
	node.image_name = str(name_tok.value)

	# 可选的效果类型
	if not _at_line_end():
		var effect_tok := _peek()
		if effect_tok.type == KS_Token.Type.IDENTIFIER:
			node.effect = str(_advance().value)

	_skip_to_next_line()
	return node


## 演员解析：  actor show/exit/change/move ...
func _parse_actor() -> KS_AST.ActorNode:
	var node := KS_AST.ActorNode.new()
	node.line = _peek().line
	_advance()  # 跳过 actor

	var action_tok := _peek()
	if action_tok == null:
		_error("actor 缺少操作指令")
		return null

	match action_tok.type:
		KS_Token.Type.KW_SHOW:
			node.action = "show"
			_advance()
			var name_tok := _expect_any_value()
			if name_tok == null:
				_error("actor show 缺少角色名")
				return null
			node.actor_name = str(name_tok.value)

			var state_tok := _expect_any_value()
			if state_tok == null:
				_error("actor show 缺少状态")
				return null
			node.state = str(state_tok.value)

			# 可选 at <position>
			if not _at_line_end() and _check(KS_Token.Type.KW_AT):
				_advance()  # 跳过 at
				var pos_tok := _expect_any_value()
				if pos_tok:
					node.position = float(str(pos_tok.value))
					node.has_position = true

		KS_Token.Type.KW_EXIT:
			node.action = "exit"
			_advance()
			var name_tok := _expect_any_value()
			if name_tok == null:
				_error("actor exit 缺少角色名")
				return null
			node.actor_name = str(name_tok.value)

		KS_Token.Type.KW_CHANGE:
			node.action = "change"
			_advance()
			var name_tok := _expect_any_value()
			if name_tok == null:
				_error("actor change 缺少角色名")
				return null
			node.actor_name = str(name_tok.value)

			var state_tok := _expect_any_value()
			if state_tok == null:
				_error("actor change 缺少新状态")
				return null
			node.state = str(state_tok.value)

		KS_Token.Type.KW_MOVE:
			node.action = "move"
			_advance()
			var name_tok := _expect_any_value()
			if name_tok == null:
				_error("actor move 缺少角色名")
				return null
			node.actor_name = str(name_tok.value)

			var pos_tok := _expect_any_value()
			if pos_tok == null:
				_error("actor move 缺少目标坐标")
				return null
			node.position = float(str(pos_tok.value))
			node.has_position = true

		_:
			_error("未知的 actor 操作: %s" % str(action_tok.value))
			return null

	# 跳过行末剩余 token（如 scale 等额外参数）
	_skip_to_next_line()
	return node


## play audio: play bgm/sfx <name>
func _parse_play_audio() -> KS_AST.AudioNode:
	var node := KS_AST.AudioNode.new()
	node.line = _peek().line
	node.action = "play"
	_advance()  # 跳过 play

	var target_tok := _peek()
	if target_tok == null:
		_error("play 缺少音频类型")
		return null

	if target_tok.type == KS_Token.Type.KW_BGM:
		node.target = "bgm"
	elif target_tok.type == KS_Token.Type.KW_SFX:
		node.target = "sfx"
	else:
		_error("play 后应为 bgm 或 sfx，实际为: %s" % str(target_tok.value))
		return null
	_advance()

	var name_tok := _expect_any_value()
	if name_tok == null:
		_error("play %s 缺少资源名" % node.target)
		return null
	node.resource_name = str(name_tok.value)

	_skip_to_next_line()
	return node


## stop audio: stop bgm
func _parse_stop_audio() -> KS_AST.AudioNode:
	var node := KS_AST.AudioNode.new()
	node.line = _peek().line
	node.action = "stop"
	_advance()  # 跳过 stop

	if not _at_line_end() and _check(KS_Token.Type.KW_BGM):
		node.target = "bgm"
		_advance()
	else:
		node.target = "bgm"  # 默认 stop bgm

	_skip_to_next_line()
	return node


## 选项组解析：合并连续的 choice 行
func _parse_choice_group() -> KS_AST.ChoiceGroupNode:
	var node := KS_AST.ChoiceGroupNode.new()
	node.line = _peek().line

	while not _at_end() and _check(KS_Token.Type.KW_CHOICE):
		var option := _parse_single_choice_line()
		if option == null:
			return null
		node.options.append(option)
		_skip_newlines()
		# 检查下一行是否也是 choice（可能有 INDENT token 需要跳过）
		if _check(KS_Token.Type.INDENT):
			# 保存位置，预读
			var saved := _pos
			_advance()  # 跳过 INDENT
			if _check(KS_Token.Type.KW_CHOICE):
				continue
			else:
				_pos = saved
				break

	return node


## 解析单个 choice 行的内容
func _parse_single_choice_line() -> KS_AST.ChoiceOption:
	_advance()  # 跳过 choice

	var option := KS_AST.ChoiceOption.new()

	# 读取选项文本
	var text_tok := _expect(KS_Token.Type.STRING_LITERAL)
	if text_tok == null:
		_error("choice 缺少选项文本")
		return null
	option.text = text_tok.value

	# 读取箭头 ->
	if not _check(KS_Token.Type.OP_ARROW):
		_error("choice 缺少 -> 运算符")
		return null
	_advance()

	# 读取目标分支
	var target_tok := _expect_any_value()
	if target_tok == null:
		_error("choice 缺少目标分支名")
		return null
	option.branch_target = str(target_tok.value)

	_skip_to_next_line()
	return option


## 分支解析：branch <id> + 缩进块
func _parse_branch() -> KS_AST.BranchNode:
	var node := KS_AST.BranchNode.new()
	node.line = _peek().line
	_advance()  # 跳过 branch

	var id_tok := _expect_any_value()
	if id_tok == null:
		_error("branch 缺少标签ID")
		return null
	node.branch_id = str(id_tok.value)

	_skip_to_next_line()

	# 解析缩进块
	node.body = _parse_indented_block()

	return node


## 条件分支解析：if %var op val: ... else: ... endif
func _parse_if_else() -> KS_AST.IfElseNode:
	var node := KS_AST.IfElseNode.new()
	node.line = _peek().line
	_advance()  # 跳过 if

	# 变量引用
	var var_tok := _expect(KS_Token.Type.VARIABLE_REF)
	if var_tok == null:
		_error("if 条件缺少变量引用（格式：if %%变量名 == 值:）")
		return null
	node.var_prefix = var_tok.value.prefix
	node.var_name = var_tok.value.name

	# 比较运算符
	var op_tok := _peek()
	if op_tok == null:
		_error("if 条件缺少比较运算符")
		return null

	match op_tok.type:
		KS_Token.Type.OP_EQ:
			node.op = "=="
		KS_Token.Type.OP_NEQ:
			node.op = "!="
		KS_Token.Type.OP_GT:
			node.op = ">"
		KS_Token.Type.OP_LT:
			node.op = "<"
		KS_Token.Type.OP_GTE:
			node.op = ">="
		KS_Token.Type.OP_LTE:
			node.op = "<="
		_:
			_error("if 条件的比较运算符无效: %s" % str(op_tok.value))
			return null
	_advance()

	# 目标值
	var val_tok := _expect_any_value()
	if val_tok == null:
		_error("if 条件缺少目标值")
		return null
	node.target_value = int(str(val_tok.value))

	# 可选冒号
	if _check(KS_Token.Type.COLON):
		_advance()

	_skip_to_next_line()

	# 解析 if 块（直到遇到 else 或 endif）
	node.if_body = _parse_condition_block()

	# 检查是否有 else
	_skip_newlines()
	if not _at_end() and _check_keyword_on_line(KS_Token.Type.KW_ELSE):
		_skip_past_keyword(KS_Token.Type.KW_ELSE)
		# 解析 else 块
		node.else_body = _parse_condition_block()

	# 消费 endif
	_skip_newlines()
	if not _at_end() and _check_keyword_on_line(KS_Token.Type.KW_ENDIF):
		_skip_past_keyword(KS_Token.Type.KW_ENDIF)

	return node


## 变量操作解析：set/add/sub/mul/div %var [=] value
func _parse_variable() -> KS_AST.VariableNode:
	var node := KS_AST.VariableNode.new()
	node.line = _peek().line

	# 操作类型
	var op_tok := _advance()
	match op_tok.type:
		KS_Token.Type.KW_SET:
			node.operation = "set"
		KS_Token.Type.KW_ADD:
			node.operation = "add"
		KS_Token.Type.KW_SUB:
			node.operation = "sub"
		KS_Token.Type.KW_MUL:
			node.operation = "mul"
		KS_Token.Type.KW_DIV:
			node.operation = "div"

	# 变量名
	var var_tok := _expect(KS_Token.Type.VARIABLE_REF)
	if var_tok == null:
		_error("%s 缺少变量名（格式：%s %%变量名 值）" % [node.operation, node.operation])
		return null
	node.var_prefix = var_tok.value.prefix
	node.var_name = var_tok.value.name

	# 可选等号
	if not _at_line_end() and _check(KS_Token.Type.OP_ASSIGN):
		_advance()

	# 操作数（收集行末所有剩余 token 作为操作数）
	var operand_parts: PackedStringArray = []
	while not _at_line_end():
		var t := _advance()
		if t.type == KS_Token.Type.STRING_LITERAL:
			node.operand = t.value
			break
		operand_parts.append(str(t.value))

	if node.operand.is_empty() and operand_parts.size() > 0:
		node.operand = " ".join(operand_parts)

	_skip_to_next_line()
	return node


## jump 解析（路径可能包含 : / . 等特殊字符，需收集行内所有剩余 token）
func _parse_jump() -> KS_AST.JumpNode:
	var node := KS_AST.JumpNode.new()
	node.line = _peek().line
	_advance()  # 跳过 jump

	# 收集行末所有 token 拼成完整路径
	var parts: PackedStringArray = []
	while not _at_line_end():
		var t := _advance()
		parts.append(str(t.value))
	node.target_path = "".join(parts)

	if node.target_path.is_empty():
		_error("jump 缺少目标路径")
		return null

	_skip_to_next_line()
	return node


## jump_branch 解析
func _parse_jump_branch() -> KS_AST.JumpBranchNode:
	var node := KS_AST.JumpBranchNode.new()
	node.line = _peek().line
	_advance()  # 跳过 jump_branch

	var target_tok := _expect_any_value()
	if target_tok == null:
		_error("jump_branch 缺少目标分支名")
		return null
	node.target_branch = str(target_tok.value)

	_skip_to_next_line()
	return node


## signal 解析
func _parse_signal() -> KS_AST.SignalNode:
	var node := KS_AST.SignalNode.new()
	node.line = _peek().line
	_advance()  # 跳过 signal

	# 收集行末所有 token 作为信号内容
	var parts: PackedStringArray = []
	while not _at_line_end():
		parts.append(str(_advance().value))

	node.signal_content = " ".join(parts)
	if node.signal_content.is_empty():
		_error("signal 缺少信号内容")
		return null

	_skip_to_next_line()
	return node


## achievement 解析
func _parse_achievement() -> KS_AST.AchievementNode:
	var node := KS_AST.AchievementNode.new()
	node.line = _peek().line
	_advance()  # 跳过 achievement

	var action_tok := _expect_any_value()
	if action_tok == null:
		_error("achievement 缺少操作类型")
		return null

	var action_str := str(action_tok.value)
	node.action = action_str

	# 目标ID
	var id_tok := _peek()
	if id_tok == null or _at_line_end():
		_error("achievement %s 缺少目标ID" % action_str)
		return null

	if id_tok.type == KS_Token.Type.STRING_LITERAL:
		node.target_id = id_tok.value
	else:
		node.target_id = str(id_tok.value)
	_advance()

	match action_str:
		"unlock":
			pass
		"increment":
			var val_tok := _expect_any_value()
			if val_tok == null:
				_error("achievement increment 缺少增量数值")
				return null
			node.increment_value = int(str(val_tok.value))
		"set_flag":
			var val_tok := _expect_any_value()
			if val_tok == null:
				_error("achievement set_flag 缺少布尔值")
				return null
			node.flag_value = str(val_tok.value).to_lower() == "true"
		_:
			_error("未知的 achievement 操作: %s" % action_str)
			return null

	_skip_to_next_line()
	return node


## end 解析
func _parse_end() -> KS_AST.EndNode:
	var node := KS_AST.EndNode.new()
	node.line = _peek().line
	_advance()  # 跳过 end
	_skip_to_next_line()
	return node


# ============================================================
# 块级解析辅助
# ============================================================

## 解析缩进块（用于 branch 内部）
func _parse_indented_block() -> Array:
	var stmts: Array = []  # Array[KS_AST.ASTNode]

	while not _at_end():
		_skip_newlines()
		if _at_end():
			break

		# 检查是否有缩进
		if not _check(KS_Token.Type.INDENT):
			break

		_advance()  # 消费 INDENT

		# 解析缩进行内的语句
		var stmt := _parse_statement()
		if stmt:
			stmts.append(stmt)

	return stmts


## 解析条件块（if/else 内部，直到 else/endif）
## 支持缩进和非缩进两种风格
func _parse_condition_block() -> Array:
	var stmts: Array = []

	while not _at_end():
		_skip_newlines()
		if _at_end():
			break

		# 如果遇到 else 或 endif，停止
		if _check_keyword_on_line(KS_Token.Type.KW_ELSE):
			break
		if _check_keyword_on_line(KS_Token.Type.KW_ENDIF):
			break

		# 跳过可能的缩进
		if _check(KS_Token.Type.INDENT):
			_advance()

		var stmt := _parse_statement()
		if stmt:
			stmts.append(stmt)

	return stmts


# ============================================================
# Token 流操作辅助
# ============================================================

## 查看当前 Token（不消费）
func _peek() -> KS_Token:
	if _pos < _tokens.size():
		return _tokens[_pos]
	return KS_Token.new(KS_Token.Type.EOF, "", 0, 0)


## 消费并返回当前 Token
func _advance() -> KS_Token:
	var tok := _peek()
	if _pos < _tokens.size():
		_pos += 1
	return tok


## 检查当前 Token 类型
func _check(type: KS_Token.Type) -> bool:
	return _peek().type == type


## 期望指定类型的 Token，否则报错
func _expect(type: KS_Token.Type) -> KS_Token:
	if _check(type):
		return _advance()
	_error("期望 %s，实际为 %s" % [KS_Token.Type.keys()[type], str(_peek())])
	return null


## 期望任意值 Token（STRING_LITERAL / NUMBER_LITERAL / IDENTIFIER / VARIABLE_REF / 关键字）
func _expect_any_value() -> KS_Token:
	var tok := _peek()
	if tok.type == KS_Token.Type.NEWLINE or tok.type == KS_Token.Type.EOF:
		return null
	return _advance()


## 是否在行末（NEWLINE 或 EOF）
func _at_line_end() -> bool:
	var tok := _peek()
	return tok.type == KS_Token.Type.NEWLINE or tok.type == KS_Token.Type.EOF


## 跳过所有 NEWLINE
func _skip_newlines() -> void:
	while _pos < _tokens.size() and _tokens[_pos].type == KS_Token.Type.NEWLINE:
		_pos += 1


## 跳到下一行（消费到 NEWLINE 或 EOF）
func _skip_to_next_line() -> void:
	while _pos < _tokens.size():
		if _tokens[_pos].type == KS_Token.Type.NEWLINE:
			_pos += 1
			return
		if _tokens[_pos].type == KS_Token.Type.EOF:
			return
		_pos += 1


## 是否到达 Token 流末尾
func _at_end() -> bool:
	return _pos >= _tokens.size() or _peek().type == KS_Token.Type.EOF


## 检查当前行（可能跨 INDENT）是否以指定关键字开头
func _check_keyword_on_line(kw: KS_Token.Type) -> bool:
	var look := _pos
	# 跳过可能的 INDENT
	if look < _tokens.size() and _tokens[look].type == KS_Token.Type.INDENT:
		look += 1
	if look < _tokens.size() and _tokens[look].type == kw:
		return true
	return false


## 跳过到指定关键字之后（含行末 NEWLINE）
func _skip_past_keyword(kw: KS_Token.Type) -> void:
	if _check(KS_Token.Type.INDENT):
		_advance()
	if _check(kw):
		_advance()
	# 跳过冒号（else: 的冒号已在关键字中处理，但独立冒号也需处理）
	if _check(KS_Token.Type.COLON):
		_advance()
	_skip_to_next_line()


## 错误记录
func _error(msg: String) -> void:
	var line_num := _peek().line if _peek() else 0
	var err := "语法错误：%s [行：%d] %s" % [_path, line_num, msg]
	_errors.append(err)
	push_error(err)
