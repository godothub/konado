extends "res://addons/konado/language/compiler/konado_script_parser_choices.gd"
class_name KonadoScriptParser

## KonadoScript 语法分析器
## 将 Token 流转换为抽象语法树（AST）


## 获取解析错误列表
func get_errors() -> Array[String]:
	return _errors


## 解析完整 Token 流为 AST 根节点；出错返回 null
func parse(tokens: Variant, path: String = "") -> KonadoScriptSyntaxTree.ScriptNode:
	_tokens = tokens
	_pos = 0
	_cached_token = null
	_cached_token_position = -1
	_path = path
	_errors.clear()
	_diagnostics.clear()
	_last_error_line = 0
	_block_depth = 0

	var script := KonadoScriptSyntaxTree.ScriptNode.new()

	while not _at_end() and _errors.size() < MAX_DIAGNOSTICS:
		_skip_newlines()
		if _at_end():
			break

		if _check(KonadoScriptToken.Type.INDENT) or _check(KonadoScriptToken.Type.DEDENT):
			_error("脚本顶层出现了意外的缩进层级")
			_advance()
			continue

		var position_before_statement := _pos
		var error_count := _errors.size()
		var stmt := _parse_statement()
		if _errors.size() > error_count:
			if _pos <= position_before_statement or _peek().line <= _last_error_line:
				_skip_to_next_line()
			continue
		if stmt == null:
			_skip_to_next_line()
			continue
		if _pos <= position_before_statement:
			_error("解析器未能消费当前语句")
			_skip_to_next_line()
			continue

		script.statements.append(stmt)

	return null if not _errors.is_empty() else script


## 解析单行 Token 为单个 AST 节点（用于 parse_single_line）
func parse_single_statement(
	tokens: Array[KonadoScriptToken], path: String = ""
) -> KonadoScriptSyntaxTree.ASTNode:
	_tokens = tokens
	_pos = 0
	_cached_token = null
	_cached_token_position = -1
	_path = path
	_errors.clear()
	_diagnostics.clear()
	_last_error_line = 0
	_block_depth = 0

	_skip_newlines()
	if _at_end():
		return null

	var position_before_statement := _pos
	var statement := _parse_statement()
	if not _errors.is_empty():
		return null
	if statement != null and _pos <= position_before_statement:
		_error("解析器未能消费当前语句")
		return null
	return statement


func _parse_statement() -> KonadoScriptSyntaxTree.ASTNode:
	var tok := _peek()
	var statement: KonadoScriptSyntaxTree.ASTNode

	match tok.type:
		KonadoScriptToken.Type.STRING_LITERAL, KonadoScriptToken.Type.VARIABLE_REF:
			statement = _parse_dialogue()
		KonadoScriptToken.Type.IDENTIFIER:
			if _token_type_at(_pos + 1) == KonadoScriptToken.Type.STRING_LITERAL:
				statement = _parse_dialogue()
			elif str(tok.value).begins_with("endif"):
				_error("无法识别的语法：%s；条件块结束关键字应为 endif" % str(tok.value))
			else:
				_error("无法识别的语法：%s" % str(tok.value))
		KonadoScriptToken.Type.KW_SCREENTEXT:
			statement = _parse_screen_text()
		KonadoScriptToken.Type.KW_SHOWTEXTBOX:
			statement = _parse_show_textbox()
		KonadoScriptToken.Type.KW_HIDETEXTBOX:
			statement = _parse_hide_textbox()
		KonadoScriptToken.Type.KW_WAITSIGNAL:
			statement = _parse_wait_signal()
		KonadoScriptToken.Type.KW_BACKGROUND:
			statement = _parse_background()
		KonadoScriptToken.Type.KW_ACTOR:
			statement = _parse_actor()
		KonadoScriptToken.Type.KW_PLAY:
			statement = _parse_play_audio()
		KonadoScriptToken.Type.KW_STOP:
			statement = _parse_stop_audio()
		KonadoScriptToken.Type.KW_CHOICE:
			statement = _parse_choice_group()
		KonadoScriptToken.Type.KW_BRANCH:
			statement = _parse_branch()
		KonadoScriptToken.Type.KW_IF:
			statement = _parse_if_else()
		KonadoScriptToken.Type.KW_ELSE:
			_error("意外的 else：当前没有等待结束的 if 条件块")
			_skip_to_next_line()
		KonadoScriptToken.Type.KW_ENDIF:
			_error("意外的 endif：当前没有等待结束的 if 条件块")
			_skip_to_next_line()
		KonadoScriptToken.Type.KW_SET:
			statement = _parse_variable()
		KonadoScriptToken.Type.KW_ADD:
			statement = _parse_variable()
		KonadoScriptToken.Type.KW_SUB:
			statement = _parse_variable()
		KonadoScriptToken.Type.KW_MUL:
			statement = _parse_variable()
		KonadoScriptToken.Type.KW_DIV:
			statement = _parse_variable()
		KonadoScriptToken.Type.KW_JUMP_BRANCH:
			statement = _parse_jump_branch()
		KonadoScriptToken.Type.KW_CALL:
			statement = _parse_call()
		KonadoScriptToken.Type.KW_RETURN:
			statement = _parse_return()
		KonadoScriptToken.Type.KW_JUMP:
			statement = _parse_jump()
		KonadoScriptToken.Type.KW_SIGNAL:
			statement = _parse_signal()
		KonadoScriptToken.Type.KW_ACHIEVEMENT:
			statement = _parse_achievement()
		KonadoScriptToken.Type.KW_CAM:
			statement = _parse_camera()
		KonadoScriptToken.Type.KW_ASYNCAM:
			statement = _parse_asyncam()
		KonadoScriptToken.Type.KW_END:
			statement = _parse_end()
		_:
			_error("无法识别的语法：%s" % str(tok.value))

	return statement


## 对话解析：角色 "内容"、$变量 "内容"、%变量 "内容" 或 "署名" "内容"
func _parse_dialogue() -> KonadoScriptSyntaxTree.DialogueNode:
	var node := KonadoScriptSyntaxTree.DialogueNode.new()
	node.line = _peek().line

	var speaker_token := _peek()
	match speaker_token.type:
		KonadoScriptToken.Type.IDENTIFIER:
			node.speaker_kind = KonadoScriptSyntaxTree.DialogueNode.SpeakerKind.ACTOR
			node.speaker = String(_advance().value)
		KonadoScriptToken.Type.STRING_LITERAL:
			node.speaker_kind = KonadoScriptSyntaxTree.DialogueNode.SpeakerKind.TEXT
			node.speaker = String(_advance().value)
		KonadoScriptToken.Type.VARIABLE_REF:
			node.speaker_kind = (
				KonadoScriptSyntaxTree.DialogueNode.SpeakerKind.PERSISTENT_VARIABLE
				if String(speaker_token.value.prefix) == "%"
				else KonadoScriptSyntaxTree.DialogueNode.SpeakerKind.TEMPORARY_VARIABLE
			)
			node.speaker = String(_advance().value.name)
		_:
			_error("对话开头应为演员标识符、变量或带引号的署名")
			return null

	var content_tok := _expect(KonadoScriptToken.Type.STRING_LITERAL)
	if content_tok == null:
		return null
	node.content = content_tok.value

	# 可选的配音标签
	if not _at_line_end() and not _check(KonadoScriptToken.Type.LBRACKET):
		var voice_tok := _peek()
		if (
			voice_tok.type == KonadoScriptToken.Type.IDENTIFIER
			or voice_tok.type == KonadoScriptToken.Type.STRING_LITERAL
		):
			node.voice_id = str(_advance().value)

	_parse_named_parameters(node)
	_finish_statement_line("对话语句后存在多余内容")
	return node


## NVL 屏幕文本解析：screentext { "行1" "行2" ... }
func _parse_screen_text() -> KonadoScriptSyntaxTree.ScreenTextNode:
	var node := KonadoScriptSyntaxTree.ScreenTextNode.new()
	node.line = _peek().line
	_advance()  # 跳过 screentext

	# 跳过 {
	if not _check(KonadoScriptToken.Type.LBRACE):
		_error("screentext 缺少 {")
		return null
	_advance()
	_skip_to_next_line()

	if not _check(KonadoScriptToken.Type.INDENT):
		_error_at(node.line, "screentext 内容必须缩进一级")
		_skip_screen_text_remainder()
		return node
	_advance()

	# 读取花括号内的文本行
	var is_closed := false
	while not _at_end():
		_skip_newlines()
		if _at_end():
			break
		if _check(KonadoScriptToken.Type.DEDENT):
			_advance()
			break

		# 读取文本行
		if _check(KonadoScriptToken.Type.STRING_LITERAL):
			var text_tok := _advance()
			node.lines.append(text_tok.value)
			_skip_to_next_line()
			continue

		_error("screentext 块内仅允许字符串文本或结束符 }")
		_skip_to_next_line()
		_skip_screen_text_remainder()
		return node

	_skip_newlines()
	if _check(KonadoScriptToken.Type.RBRACE):
		_advance()
		_parse_named_parameters(node)
		_finish_statement_line("screentext 结束符后存在多余内容")
		is_closed = true
	if not is_closed:
		_error_at(node.line, "screentext 缺少结束符 }")

	return node


## 显示对话框解析：showtextbox [duration]
func _parse_show_textbox() -> KonadoScriptSyntaxTree.ShowTextBoxNode:
	var node := KonadoScriptSyntaxTree.ShowTextBoxNode.new()
	node.line = _peek().line
	_advance()  # 跳过 showtextbox

	if not _at_line_end() and not _check(KonadoScriptToken.Type.LBRACKET):
		var dur_tok := _expect(KonadoScriptToken.Type.NUMBER_LITERAL)
		if dur_tok == null:
			return null
		node.duration = float(str(dur_tok.value))
		if node.duration < 0.0:
			_error_at(node.line, "showtextbox 动画时长不能为负数")
			_skip_to_next_line()
			return null
	_parse_named_parameters(node)
	_finish_statement_line("showtextbox 动画时长后存在多余内容")
	return node


## 隐藏对话框解析：hidetextbox [duration]
func _parse_hide_textbox() -> KonadoScriptSyntaxTree.HideTextBoxNode:
	var node := KonadoScriptSyntaxTree.HideTextBoxNode.new()
	node.line = _peek().line
	_advance()  # 跳过 hidetextbox

	if not _at_line_end() and not _check(KonadoScriptToken.Type.LBRACKET):
		var dur_tok := _expect(KonadoScriptToken.Type.NUMBER_LITERAL)
		if dur_tok == null:
			return null
		node.duration = float(str(dur_tok.value))
		if node.duration < 0.0:
			_error_at(node.line, "hidetextbox 动画时长不能为负数")
			_skip_to_next_line()
			return null
	_parse_named_parameters(node)
	_finish_statement_line("hidetextbox 动画时长后存在多余内容")
	return node


## 等待外部信号解析：waitsignal <name>
func _parse_wait_signal() -> KonadoScriptSyntaxTree.WaitSignalNode:
	var node := KonadoScriptSyntaxTree.WaitSignalNode.new()
	node.line = _peek().line
	_advance()  # 跳过 waitsignal

	# 读取信号名称（字符串字面量或标识符）
	if _check(KonadoScriptToken.Type.STRING_LITERAL):
		var tok := _advance()
		node.signal_name = tok.value
	elif _check(KonadoScriptToken.Type.IDENTIFIER):
		var tok := _advance()
		node.signal_name = str(tok.value)
	else:
		_error("waitsignal 缺少信号名称")
		return null

	_parse_named_parameters(node)
	_finish_statement_line("waitsignal 信号名称后存在多余内容")
	return node


## 背景切换解析：  background <background_name> [effect]
func _parse_background() -> KonadoScriptSyntaxTree.BackgroundNode:
	var node := KonadoScriptSyntaxTree.BackgroundNode.new()
	node.line = _peek().line
	_advance()  # 跳过 background

	var name_tok := _expect_any_value()
	if name_tok == null:
		_error("background 缺少背景资源名")
		return null
	node.background_name = str(name_tok.value)

	# 可选的效果类型
	if not _at_line_end() and not _check(KonadoScriptToken.Type.LBRACKET):
		var effect_tok := _peek()
		if effect_tok.type == KonadoScriptToken.Type.IDENTIFIER:
			node.effect = str(_advance().value)

	_parse_named_parameters(node)
	_finish_statement_line("background 参数后存在多余内容")
	return node


## 演员解析：  actor show/exit/change/move/motion ...
func _parse_actor() -> KonadoScriptSyntaxTree.ActorNode:
	var node := KonadoScriptSyntaxTree.ActorNode.new()
	node.line = _peek().line
	_advance()  # 跳过 actor

	var action_tok := _peek()
	var is_valid := (
		action_tok.type != KonadoScriptToken.Type.NEWLINE
		and action_tok.type != KonadoScriptToken.Type.EOF
	)

	if not is_valid:
		_error("actor 缺少操作指令")
	else:
		match action_tok.type:
			KonadoScriptToken.Type.KW_SHOW:
				is_valid = _parse_actor_show(node)
			KonadoScriptToken.Type.KW_EXIT:
				is_valid = _parse_actor_exit(node)
			KonadoScriptToken.Type.KW_CHANGE:
				is_valid = _parse_actor_change(node)
			KonadoScriptToken.Type.KW_MOVE:
				is_valid = _parse_actor_move(node)
			KonadoScriptToken.Type.KW_MOTION:
				is_valid = _parse_actor_motion(node)
			_:
				_error("未知的 actor 操作: %s" % str(action_tok.value))
				is_valid = false

	if is_valid:
		_parse_named_parameters(node)
		if _finish_statement_line("actor 参数后存在多余内容"):
			return node
	return null


func _parse_actor_show(node: KonadoScriptSyntaxTree.ActorNode) -> bool:
	node.action = "show"
	_advance()
	var name_tok := _expect_any_value()
	if name_tok == null:
		_error("actor show 缺少角色名")
		return false
	var state_tok := _expect_any_value()
	if state_tok == null:
		_error("actor show 缺少状态")
		return false
	node.actor_name = str(name_tok.value)
	node.state = str(state_tok.value)
	if _at_line_end():
		_error("actor show 缺少 at 和位置")
		return false
	if not _check(KonadoScriptToken.Type.KW_AT):
		_error("actor show 状态后应为 at")
		return false
	_advance()
	var pos_tok := _expect(KonadoScriptToken.Type.NUMBER_LITERAL)
	if pos_tok == null:
		_error("actor show 的 at 缺少位置")
		return false
	node.position = float(str(pos_tok.value))
	node.has_position = true
	return true


func _parse_actor_exit(node: KonadoScriptSyntaxTree.ActorNode) -> bool:
	node.action = "exit"
	_advance()
	return _parse_actor_name(node, "actor exit 缺少角色名")


func _parse_actor_change(node: KonadoScriptSyntaxTree.ActorNode) -> bool:
	node.action = "change"
	_advance()
	var name_tok := _expect_any_value()
	if name_tok == null:
		_error("actor change 缺少角色名")
		return false
	var state_tok := _expect_any_value()
	if state_tok == null:
		_error("actor change 缺少新状态")
		return false
	node.actor_name = str(name_tok.value)
	node.state = str(state_tok.value)
	return true


func _parse_actor_move(node: KonadoScriptSyntaxTree.ActorNode) -> bool:
	node.action = "move"
	_advance()
	var name_tok := _expect_any_value()
	if name_tok == null:
		_error("actor move 缺少角色名")
		return false
	var pos_tok := _expect(KonadoScriptToken.Type.NUMBER_LITERAL)
	if pos_tok == null:
		_error("actor move 缺少目标坐标")
		return false
	node.actor_name = str(name_tok.value)
	node.position = float(str(pos_tok.value))
	node.has_position = true
	return true


func _parse_actor_motion(node: KonadoScriptSyntaxTree.ActorNode) -> bool:
	node.action = "motion"
	_advance()
	var name_tok := _expect_any_value()
	if name_tok == null:
		_error("actor motion 缺少角色名")
		return false
	var motion_tok := _expect_any_value()
	if motion_tok == null:
		_error("actor motion 缺少动作名")
		return false
	node.actor_name = str(name_tok.value)
	node.motion_name = str(motion_tok.value)
	return true


func _parse_actor_name(node: KonadoScriptSyntaxTree.ActorNode, error_message: String) -> bool:
	var name_tok := _expect_any_value()
	if name_tok == null:
		_error(error_message)
		return false
	node.actor_name = str(name_tok.value)
	return true


## play audio: play bgm/sfx <name>
func _parse_play_audio() -> KonadoScriptSyntaxTree.AudioNode:
	var node := KonadoScriptSyntaxTree.AudioNode.new()
	node.line = _peek().line
	node.action = "play"
	_advance()  # 跳过 play

	var target_tok := _peek()
	if target_tok == null:
		_error("play 缺少音频类型")
		return null

	if target_tok.type == KonadoScriptToken.Type.KW_BGM:
		node.target = "bgm"
	elif target_tok.type == KonadoScriptToken.Type.KW_SFX:
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

	_parse_named_parameters(node)
	_finish_statement_line("play 参数后存在多余内容")
	return node


## stop audio: stop bgm
func _parse_stop_audio() -> KonadoScriptSyntaxTree.AudioNode:
	var node := KonadoScriptSyntaxTree.AudioNode.new()
	node.line = _peek().line
	node.action = "stop"
	_advance()  # 跳过 stop

	if not _at_line_end() and _check(KonadoScriptToken.Type.KW_BGM):
		node.target = "bgm"
		_advance()
	else:
		node.target = "bgm"  # 默认 stop bgm

	_parse_named_parameters(node)
	_finish_statement_line("stop bgm 后存在多余内容")
	return node


## 镜头解析：  cam move <target_cam> [tween_type] [time] | cam reset
## 语法规则：
## - cam move xxx              : 默认无动画
## - cam move xxx none          : 无动画
## - cam move xxx linear        : linear 动画，默认时间 1.0
## - cam move xxx linear 2.0    : linear 动画，时间 2.0
func _parse_camera() -> KonadoScriptSyntaxTree.CameraNode:
	var node := KonadoScriptSyntaxTree.CameraNode.new()
	node.line = _peek().line
	_advance()  # 跳过 cam
	if not _parse_camera_operation(node, "cam", false):
		_skip_to_next_line()
		return null
	_parse_named_parameters(node)
	_finish_statement_line("cam 参数后存在多余内容")
	return node


## 异步相机解析：支持 asyncam move/reset/shake/stop，
## move 和 reset 可附带 tween_type 与 tween_time。
func _parse_asyncam() -> KonadoScriptSyntaxTree.AsyncCamNode:
	var node := KonadoScriptSyntaxTree.AsyncCamNode.new()
	node.line = _peek().line
	_advance()  # 跳过 asyncam
	if not _parse_camera_operation(node, "asyncam", true):
		_skip_to_next_line()
		return null
	_parse_named_parameters(node)
	_finish_statement_line("asyncam 参数后存在多余内容")
	return node


func _parse_camera_operation(node: Variant, command: String, allow_stop: bool) -> bool:
	if _at_line_end():
		_error("%s 缺少操作指令" % command)
		return false
	var action_tok := _advance()
	var valid := true
	match action_tok.type:
		KonadoScriptToken.Type.KW_MOVE:
			node.action = "move"
			var target_tok := _expect_any_value()
			if target_tok == null:
				_error("%s move 缺少目标镜头名" % command)
				valid = false
			else:
				node.target_cam = str(target_tok.value)
				valid = _parse_camera_tween(node, command)
		KonadoScriptToken.Type.KW_RESET:
			node.action = "reset"
			valid = _parse_camera_tween(node, command)
		KonadoScriptToken.Type.KW_SHAKE:
			node.action = "shake"
			valid = _parse_camera_shake(node, command)
		KonadoScriptToken.Type.KW_STOP:
			if allow_stop:
				node.action = "stop"
			else:
				valid = false
		_:
			valid = false
	if not valid and _errors.is_empty():
		var actions := "move、reset、shake 或 stop" if allow_stop else "move、reset 或 shake"
		_error("%s 未知操作: %s（应为 %s）" % [command, str(action_tok.value), actions])
	return (
		valid
		and _validate_camera_values(
			node.action,
			node.tween_type,
			node.tween_time,
			node.shake_time,
		)
	)


func _parse_camera_tween(node: Variant, command: String) -> bool:
	if _at_line_end():
		return true
	var tween_tok := _peek()
	if tween_tok.type != KonadoScriptToken.Type.IDENTIFIER:
		return true
	node.tween_type = str(_advance().value)
	if _at_line_end():
		return true
	var time_tok := _peek()
	if time_tok.type != KonadoScriptToken.Type.NUMBER_LITERAL:
		_error("%s 过渡时长应为数字" % command)
		return false
	node.tween_time = float(str(_advance().value))
	return true


func _parse_camera_shake(node: Variant, command: String) -> bool:
	if _at_line_end():
		return true
	var time_tok := _peek()
	if time_tok.type != KonadoScriptToken.Type.NUMBER_LITERAL:
		_error("%s 震动时长应为数字" % command)
		return false
	node.shake_time = float(str(_advance().value))
	return true


## 分支解析：branch <id> + 缩进块
func _parse_branch() -> KonadoScriptSyntaxTree.BranchNode:
	var node := KonadoScriptSyntaxTree.BranchNode.new()
	node.line = _peek().line
	_advance()  # 跳过 branch

	var id_tok := _expect_any_value()
	if id_tok == null:
		_error("branch 缺少标签ID")
		return null
	node.branch_id = str(id_tok.value)

	if not _finish_statement_line("branch 标签后存在多余内容"):
		return null

	# 解析缩进块
	node.body = _parse_indented_block("branch", _parse_statement)

	return node


## 条件分支解析：if %var op val: ... else: ... endif
func _parse_if_else() -> KonadoScriptSyntaxTree.IfElseNode:
	var node := KonadoScriptSyntaxTree.IfElseNode.new()
	node.line = _peek().line
	_advance()  # 跳过 if

	# 变量引用
	var var_tok := _expect(KonadoScriptToken.Type.VARIABLE_REF)
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
		KonadoScriptToken.Type.OP_EQ:
			node.op = "=="
		KonadoScriptToken.Type.OP_NEQ:
			node.op = "!="
		KonadoScriptToken.Type.OP_GT:
			node.op = ">"
		KonadoScriptToken.Type.OP_LT:
			node.op = "<"
		KonadoScriptToken.Type.OP_GTE:
			node.op = ">="
		KonadoScriptToken.Type.OP_LTE:
			node.op = "<="
		_:
			_error("if 条件的比较运算符无效: %s" % str(op_tok.value))
			return null
	_advance()

	# 目标值使用与变量赋值相同的类型系统。
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
		val_tok = null
	if val_tok == null:
		_error("if 条件缺少目标值")
		return null
	_advance()
	node.target_value = _literal_value(val_tok)
	_parse_named_parameters(node)

	# 解析 if 块（直到遇到 else 或 endif）
	if _consume_required_colon_line("if 条件末尾缺少冒号", "if 条件冒号后不允许其他内容"):
		node.if_body = _parse_condition_block(_parse_statement)

	# 检查是否有 else
	if _errors.is_empty():
		_skip_newlines()
		if not _at_end() and _check_keyword_on_line(KonadoScriptToken.Type.KW_ELSE):
			if _consume_keyword_line(
				KonadoScriptToken.Type.KW_ELSE,
				true,
				"else 末尾缺少冒号",
				"else 冒号后不允许其他内容",
			):
				# 解析 else 块
				node.else_body = _parse_condition_block(_parse_statement)

	# 消费 endif
	if _errors.is_empty():
		_skip_newlines()
		if not _at_end() and _check_keyword_on_line(KonadoScriptToken.Type.KW_ENDIF):
			_consume_keyword_line(
				KonadoScriptToken.Type.KW_ENDIF,
				false,
				"",
				"endif 后不允许其他内容",
			)
		elif (
			not _at_end()
			and _peek().type == KonadoScriptToken.Type.IDENTIFIER
			and String(_peek().value).begins_with("endif")
		):
			_error("无法识别的语法：%s；条件块结束关键字应为 endif" % String(_peek().value))
			_skip_to_next_line()
		else:
			_error_at(node.line, "if 条件块缺少 endif")

	if not _errors.is_empty():
		_skip_condition_remainder()
	return node


## 变量操作解析：set/add/sub/mul/div %var [=] value
func _parse_variable() -> KonadoScriptSyntaxTree.VariableNode:
	var node := KonadoScriptSyntaxTree.VariableNode.new()
	node.line = _peek().line

	var op_tok := _advance()
	match op_tok.type:
		KonadoScriptToken.Type.KW_SET:
			node.operation = "set"
		KonadoScriptToken.Type.KW_ADD:
			node.operation = "add"
		KonadoScriptToken.Type.KW_SUB:
			node.operation = "sub"
		KonadoScriptToken.Type.KW_MUL:
			node.operation = "mul"
		KonadoScriptToken.Type.KW_DIV:
			node.operation = "div"

	var var_tok := _expect(KonadoScriptToken.Type.VARIABLE_REF)
	if var_tok == null:
		_error("%s 缺少变量名（格式：%s %%变量名 值）" % [node.operation, node.operation])
		return null
	node.var_prefix = var_tok.value.prefix
	node.var_name = var_tok.value.name

	# 可选等号
	if not _at_line_end() and _check(KonadoScriptToken.Type.OP_ASSIGN):
		_advance()

	var operand_token := _peek()
	if (
		operand_token.type
		not in [
			KonadoScriptToken.Type.NUMBER_LITERAL,
			KonadoScriptToken.Type.STRING_LITERAL,
			KonadoScriptToken.Type.IDENTIFIER,
			KonadoScriptToken.Type.VARIABLE_REF,
		]
	):
		_error("%s 缺少变量值" % node.operation)
		return null
	_advance()
	node.operand = _literal_value(operand_token)

	_parse_named_parameters(node)
	_finish_statement_line("%s 变量值后存在多余内容" % node.operation)
	return node


## jump 解析（路径可能包含 : / . 等特殊字符，需收集行内所有剩余 token）
func _parse_jump() -> KonadoScriptSyntaxTree.JumpNode:
	var node := KonadoScriptSyntaxTree.JumpNode.new()
	node.line = _peek().line
	_advance()  # 跳过 jump

	var parts: PackedStringArray = []
	while not _at_line_end() and not _check(KonadoScriptToken.Type.LBRACKET):
		var t := _advance()
		parts.append(str(t.value))
	node.target_path = "".join(parts)

	if node.target_path.is_empty():
		_error("jump 缺少目标路径")
		return null
	if not node.target_path.begins_with("res://") or node.target_path.get_extension() != "ks":
		_error("jump 目标必须是 res:// 下的 .ks 文件")
		return null

	_parse_named_parameters(node)
	_finish_statement_line("jump 路径后存在多余内容")
	return node


## jump_branch 解析
func _parse_jump_branch() -> KonadoScriptSyntaxTree.JumpBranchNode:
	var node := KonadoScriptSyntaxTree.JumpBranchNode.new()
	node.line = _peek().line
	_advance()  # 跳过 jump_branch

	var target_tok := _expect_any_value()
	if target_tok == null:
		_error("jump_branch 缺少目标分支名")
		return null
	node.target_branch = str(target_tok.value)

	_parse_named_parameters(node)
	_finish_statement_line("jump_branch 目标分支后存在多余内容")
	return node


## call 解析：调用本剧本内的一个分支，执行到 return 时回到调用点。
## 跨剧本调用暂不支持（用 jump），因此目标必须是有效标识符而不是 res:// 路径。
func _parse_call() -> KonadoScriptSyntaxTree.CallNode:
	var node := KonadoScriptSyntaxTree.CallNode.new()
	node.line = _peek().line
	_advance()  # 跳过 call

	var target_tok := _expect_any_value()
	if target_tok == null:
		_error("call 缺少目标分支名")
		return null
	var target := str(target_tok.value)
	if not target.is_valid_identifier():
		_error("call 目标必须是本剧本内有效的分支标识符（跨剧本调用暂不支持，请使用 jump）")
		return null
	node.target_branch = target

	_parse_named_parameters(node)
	_finish_statement_line("call 目标分支后存在多余内容")
	return node


## return 解析：弹出调用栈并回到调用点；空栈时等价于 end。
func _parse_return() -> KonadoScriptSyntaxTree.ReturnNode:
	var node := KonadoScriptSyntaxTree.ReturnNode.new()
	node.line = _peek().line
	_advance()  # 跳过 return

	_parse_named_parameters(node)
	_finish_statement_line("return 后存在多余内容")
	return node


## signal 解析
func _parse_signal() -> KonadoScriptSyntaxTree.SignalNode:
	var node := KonadoScriptSyntaxTree.SignalNode.new()
	node.line = _peek().line
	_advance()  # 跳过 signal

	# 收集行末所有 token 作为信号内容
	var parts: PackedStringArray = []
	while not _at_line_end() and not _check(KonadoScriptToken.Type.LBRACKET):
		parts.append(str(_advance().value))

	node.signal_content = " ".join(parts)
	if node.signal_content.is_empty():
		_error("signal 缺少信号内容")
		return null

	_parse_named_parameters(node)
	_finish_statement_line("signal 参数后存在多余内容")
	return node


## achievement 解析
func _parse_achievement() -> KonadoScriptSyntaxTree.AchievementNode:
	var node := KonadoScriptSyntaxTree.AchievementNode.new()
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

	if id_tok.type == KonadoScriptToken.Type.STRING_LITERAL:
		node.target_id = id_tok.value
	else:
		node.target_id = str(id_tok.value)
	_advance()

	match action_str:
		"unlock":
			pass
		"increment":
			var val_tok := _expect(KonadoScriptToken.Type.NUMBER_LITERAL)
			if val_tok == null:
				_error("achievement increment 缺少增量数值")
				return null
			if not str(val_tok.value).is_valid_int():
				_error("achievement increment 增量应为整数")
			else:
				node.increment_value = int(str(val_tok.value))
		"set_flag":
			var val_tok := _expect_any_value()
			if val_tok == null:
				_error("achievement set_flag 缺少布尔值")
				return null
			var bool_value := str(val_tok.value).to_lower()
			if bool_value not in ["true", "false"]:
				_error("achievement set_flag 布尔值应为 true 或 false")
			else:
				node.flag_value = bool_value == "true"
		_:
			_error("未知的 achievement 操作: %s" % action_str)
			return null

	_parse_named_parameters(node)
	_finish_statement_line("achievement 参数后存在多余内容")
	return node


## end 解析
func _parse_end() -> KonadoScriptSyntaxTree.EndNode:
	var node := KonadoScriptSyntaxTree.EndNode.new()
	node.line = _peek().line
	_advance()  # 跳过 end
	_parse_named_parameters(node)
	_finish_statement_line("end 后存在多余内容")
	return node
