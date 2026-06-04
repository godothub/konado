extends RefCounted
class_name KS_Emitter

## KS 代码生成器（发射器）
## 将验证后的 AST 转换为 KND_Shot / KND_Dialogue 结构

var _node_counter: int = 0
var _ifelse_counter: int = 0
var _path: String = ""

## 分支存储：branch_id -> Array[KND_Dialogue]
var _branch_dialogues: Dictionary = {}
## if/else 块存储：ifelse_key -> {"if": Array, "else": Array}
var _ifelse_blocks: Dictionary = {}

## 背景特效表
const BACKGROUND_EFFECTS_MAP: Dictionary = {
	"none": KND_ActingInterface.BackgroundTransitionEffectsType.NONE_EFFECT,
	"erase": KND_ActingInterface.BackgroundTransitionEffectsType.EraseEffect,
	"blinds": KND_ActingInterface.BackgroundTransitionEffectsType.BlindsEffect,
	"wave": KND_ActingInterface.BackgroundTransitionEffectsType.WaveEffect,
	"fade": KND_ActingInterface.BackgroundTransitionEffectsType.ALPHA_FADE_EFFECT,
	"vortex": KND_ActingInterface.BackgroundTransitionEffectsType.VORTEX_SWAP_EFFECT,
	"windmill": KND_ActingInterface.BackgroundTransitionEffectsType.WINDMILL_EFFECT,
	"cyberglitch": KND_ActingInterface.BackgroundTransitionEffectsType.CYBER_GLITCH_EFFECT,
}


func _init() -> void:
	pass


## 从 AST 生成 KND_Shot
func emit(script: KS_AST.ScriptNode, path: String) -> KND_Shot:
	_node_counter = 0
	_ifelse_counter = 0
	_path = path
	_branch_dialogues.clear()
	_ifelse_blocks.clear()

	var shot := KND_Shot.new()
	shot.ks_path = path

	# 第一步：遍历 AST 生成主线 KND_Dialogue 列表
	var main_dialogues: Array[KND_Dialogue] = _emit_statements(script.statements)

	# 第二步：后处理 —— 分配 node_id、连接 next_id、扁平化
	_post_process(shot, main_dialogues)

	return shot


## 从单个 AST 节点生成 KND_Dialogue（用于 parse_single_line）
func emit_single(node: KS_AST.ASTNode) -> KND_Dialogue:
	_node_counter = 0
	_ifelse_counter = 0
	return _emit_node(node)


## 节点ID生成
func _next_node_id() -> String:
	_node_counter += 1
	return "ks_node_%d" % _node_counter
	
	
## 语句列表发射
func _emit_statements(stmts: Array) -> Array[KND_Dialogue]:
	var dialogues: Array[KND_Dialogue] = []

	for stmt in stmts:
		if stmt is KS_AST.BranchNode:
			_emit_branch(stmt)
			# branch 内容存入 _branch_dialogues，不加入主线
			continue

		var dialog := _emit_node(stmt)
		if dialog:
			dialogues.append(dialog)

	return dialogues


## 分发发射单个 AST 节点
func _emit_node(node: KS_AST.ASTNode) -> KND_Dialogue:
	if node is KS_AST.DialogueNode:
		return _emit_dialogue(node)
	if node is KS_AST.BackgroundNode:
		return _emit_background(node)
	if node is KS_AST.ActorNode:
		return _emit_actor(node)
	if node is KS_AST.AudioNode:
		return _emit_audio(node)
	if node is KS_AST.ChoiceGroupNode:
		return _emit_choice(node)
	if node is KS_AST.IfElseNode:
		return _emit_if_else(node)
	if node is KS_AST.VariableNode:
		return _emit_variable(node)
	if node is KS_AST.JumpNode:
		return _emit_jump(node)
	if node is KS_AST.JumpBranchNode:
		return _emit_jump_branch(node)
	if node is KS_AST.SignalNode:
		return _emit_signal(node)
	if node is KS_AST.AchievementNode:
		return _emit_achievement(node)
	if node is KS_AST.EndNode:
		return _emit_end(node)

	return null


# ============================================================
# 各类型节点发射
# ============================================================

func _emit_dialogue(node: KS_AST.DialogueNode) -> KND_Dialogue:
	var d := KND_Dialogue.new()
	d.source_file_line = node.line
	d.dialog_type = KND_Dialogue.Type.ORDINARY_DIALOG
	d.character_id = node.character_id
	d.dialog_content = node.content
	if not node.voice_id.is_empty():
		d.voice_id = node.voice_id
	return d


func _emit_background(node: KS_AST.BackgroundNode) -> KND_Dialogue:
	var d := KND_Dialogue.new()
	d.source_file_line = node.line
	d.dialog_type = KND_Dialogue.Type.SWITCH_BACKGROUND
	d.background_image_name = node.image_name
	if not node.effect.is_empty():
		d.background_toggle_effects = BACKGROUND_EFFECTS_MAP.get(
			node.effect, KND_ActingInterface.BackgroundTransitionEffectsType.NONE_EFFECT)
	return d


func _emit_actor(node: KS_AST.ActorNode) -> KND_Dialogue:
	var d := KND_Dialogue.new()
	d.source_file_line = node.line

	match node.action:
		"show":
			d.dialog_type = KND_Dialogue.Type.DISPLAY_ACTOR
			d.character_name = node.actor_name
			d.character_state = node.state
			if node.has_position:
				d.actor_position = Vector2(node.position, 0.0)
		"exit":
			d.dialog_type = KND_Dialogue.Type.EXIT_ACTOR
			d.exit_actor = node.actor_name
		"change":
			d.dialog_type = KND_Dialogue.Type.ACTOR_CHANGE_STATE
			d.change_state_actor = node.actor_name
			d.change_state = node.state
		"move":
			d.dialog_type = KND_Dialogue.Type.MOVE_ACTOR
			d.target_move_chara = node.actor_name
			d.target_move_pos = Vector2(node.position, 0.0)

	return d


func _emit_audio(node: KS_AST.AudioNode) -> KND_Dialogue:
	var d := KND_Dialogue.new()
	d.source_file_line = node.line

	if node.action == "play":
		if node.target == "bgm":
			d.dialog_type = KND_Dialogue.Type.PLAY_BGM
			d.bgm_name = node.resource_name
		elif node.target == "sfx":
			d.dialog_type = KND_Dialogue.Type.PLAY_SOUND_EFFECT
			d.soundeffect_name = node.resource_name
	elif node.action == "stop":
		d.dialog_type = KND_Dialogue.Type.STOP_BGM

	return d


func _emit_choice(node: KS_AST.ChoiceGroupNode) -> KND_Dialogue:
	var d := KND_Dialogue.new()
	d.source_file_line = node.line
	d.dialog_type = KND_Dialogue.Type.SHOW_CHOICE

	for option in node.options:
		var choice := KND_DialogueChoice.new()
		choice.choice_text = option.text
		choice.next_id = option.branch_target  # 暂用 tag 名称，后处理时替换为 node_id
		d.choices.append(choice)

	return d


func _emit_branch(node: KS_AST.BranchNode) -> void:
	var branch_dialogs: Array[KND_Dialogue] = []

	for stmt in node.body:
		if stmt is KS_AST.ChoiceGroupNode:
			var choice_d := _emit_choice(stmt)
			if choice_d:
				branch_dialogs.append(choice_d)
		elif stmt is KS_AST.IfElseNode:
			var ifelse_d := _emit_if_else(stmt)
			if ifelse_d:
				branch_dialogs.append(ifelse_d)
		else:
			var d := _emit_node(stmt)
			if d:
				branch_dialogs.append(d)

	_branch_dialogues[node.branch_id] = branch_dialogs


func _emit_if_else(node: KS_AST.IfElseNode) -> KND_Dialogue:
	var d := KND_Dialogue.new()
	d.source_file_line = node.line
	d.dialog_type = KND_Dialogue.Type.IFELSE_BRANCH

	d.varname = node.var_name
	d.is_persistent = (node.var_prefix == "%")

	# 操作符映射
	match node.op:
		"==":
			d.condition_operator = 0
		">":
			d.condition_operator = 1
		"<":
			d.condition_operator = 2
		">=":
			d.condition_operator = 3
		"<=":
			d.condition_operator = 4
		"!=":
			d.condition_operator = 5

	d.target_value = node.target_value

	# 递归发射 if/else 块内容
	var if_dialogs: Array[KND_Dialogue] = []
	for stmt in node.if_body:
		var inner := _emit_node(stmt)
		if inner:
			if_dialogs.append(inner)

	var else_dialogs: Array[KND_Dialogue] = []
	for stmt in node.else_body:
		var inner := _emit_node(stmt)
		if inner:
			else_dialogs.append(inner)

	# 存储到 ifelse 块
	_ifelse_counter += 1
	var ifelse_key := "ifelse_%d" % _ifelse_counter
	_ifelse_blocks[ifelse_key] = {
		"if": if_dialogs,
		"else": else_dialogs,
	}

	# 用 meta 存储 key，后处理时使用
	d.set_meta("ifelse_key", ifelse_key)

	return d


func _emit_variable(node: KS_AST.VariableNode) -> KND_Dialogue:
	var d := KND_Dialogue.new()
	d.source_file_line = node.line
	d.dialog_type = KND_Dialogue.Type.SET_VARIABLE
	d.variable_name = node.var_name
	d.is_persistent = (node.var_prefix == "%")
	d.variable_operand = node.operand

	match node.operation:
		"set":
			d.variable_operation = KND_VariableStore.Operation.SET
		"add":
			d.variable_operation = KND_VariableStore.Operation.ADD
		"sub":
			d.variable_operation = KND_VariableStore.Operation.SUB
		"mul":
			d.variable_operation = KND_VariableStore.Operation.MUL
		"div":
			d.variable_operation = KND_VariableStore.Operation.DIV

	return d


func _emit_jump(node: KS_AST.JumpNode) -> KND_Dialogue:
	var d := KND_Dialogue.new()
	d.source_file_line = node.line
	d.dialog_type = KND_Dialogue.Type.JUMP
	d.jump_shot_path = node.target_path
	return d


func _emit_jump_branch(node: KS_AST.JumpBranchNode) -> KND_Dialogue:
	var d := KND_Dialogue.new()
	d.source_file_line = node.line
	d.dialog_type = KND_Dialogue.Type.JUMP_BRANCH
	d.jump_branch_target = node.target_branch
	return d


func _emit_signal(node: KS_AST.SignalNode) -> KND_Dialogue:
	var d := KND_Dialogue.new()
	d.source_file_line = node.line
	d.dialog_type = KND_Dialogue.Type.SIGNAL
	d.custom_signal_name = node.signal_content
	return d


func _emit_achievement(node: KS_AST.AchievementNode) -> KND_Dialogue:
	var d := KND_Dialogue.new()
	d.source_file_line = node.line

	match node.action:
		"unlock":
			d.dialog_type = KND_Dialogue.Type.ACHIEVEMENT_UNLOCK
			d.achievement_id = node.target_id
		"increment":
			d.dialog_type = KND_Dialogue.Type.ACHIEVEMENT_PROGRESS
			d.achievement_id = node.target_id
			d.achievement_value = node.increment_value
		"set_flag":
			d.dialog_type = KND_Dialogue.Type.ACHIEVEMENT_FLAG
			d.achievement_flag_name = node.target_id
			d.achievement_flag_value = node.flag_value

	return d


func _emit_end(node: KS_AST.EndNode) -> KND_Dialogue:
	var d := KND_Dialogue.new()
	d.source_file_line = node.line
	d.dialog_type = KND_Dialogue.Type.THE_END
	return d


## 后处理：分配 node_id、连接 next_id、扁平化
func _post_process(shot: KND_Shot, main_dialogues: Array[KND_Dialogue]) -> void:
	# 1. 为主线对话分配 node_id
	for d in main_dialogues:
		if d.node_id.is_empty():
			d.node_id = _next_node_id()

	# 2. 为分支内对话分配 node_id
	var tag_to_first_node_id: Dictionary = {}
	for tag_name in _branch_dialogues:
		var branch_dialogs: Array = _branch_dialogues[tag_name]
		if branch_dialogs.size() > 0:
			for bd in branch_dialogs:
				if bd.node_id.is_empty():
					bd.node_id = _next_node_id()
			tag_to_first_node_id[tag_name] = branch_dialogs[0].node_id

	# 3. 为 if/else 块内对话分配 node_id
	var ifelse_if_first: Dictionary = {}
	var ifelse_else_first: Dictionary = {}
	var ifelse_if_last: Dictionary = {}
	var ifelse_else_last: Dictionary = {}

	for key in _ifelse_blocks:
		var blocks: Dictionary = _ifelse_blocks[key]
		var if_dialogs: Array = blocks.get("if", [])
		var else_dialogs: Array = blocks.get("else", [])

		for bd in if_dialogs:
			if bd.node_id.is_empty():
				bd.node_id = _next_node_id()
		for bd in else_dialogs:
			if bd.node_id.is_empty():
				bd.node_id = _next_node_id()

		if if_dialogs.size() > 0:
			ifelse_if_first[key] = if_dialogs[0].node_id
			ifelse_if_last[key] = if_dialogs[if_dialogs.size() - 1].node_id
		if else_dialogs.size() > 0:
			ifelse_else_first[key] = else_dialogs[0].node_id
			ifelse_else_last[key] = else_dialogs[else_dialogs.size() - 1].node_id

	# 4. 连接主线对话的 next_id
	for idx in range(main_dialogues.size() - 1):
		var cur: KND_Dialogue = main_dialogues[idx]
		var nxt: KND_Dialogue = main_dialogues[idx + 1]
		if cur.dialog_type != KND_Dialogue.Type.SHOW_CHOICE \
			and cur.dialog_type != KND_Dialogue.Type.THE_END \
			and cur.dialog_type != KND_Dialogue.Type.JUMP \
			and cur.dialog_type != KND_Dialogue.Type.JUMP_BRANCH:
			cur.next_id = nxt.node_id

	# 5. 解析选项的 next_id（tag -> node_id）
	_resolve_choice_targets(main_dialogues, tag_to_first_node_id)
	for tag_name in _branch_dialogues:
		_resolve_choice_targets(_branch_dialogues[tag_name], tag_to_first_node_id)

	# 5.5 解析 jump_branch 的 next_id
	_resolve_jump_branch_targets(main_dialogues, tag_to_first_node_id)
	for tag_name in _branch_dialogues:
		_resolve_jump_branch_targets(_branch_dialogues[tag_name], tag_to_first_node_id)
	for key in _ifelse_blocks:
		var blocks: Dictionary = _ifelse_blocks[key]
		_resolve_jump_branch_targets(blocks.get("if", []), tag_to_first_node_id)
		_resolve_jump_branch_targets(blocks.get("else", []), tag_to_first_node_id)

	# 6. 连接 if/else 块（主线 + 分支内）
	_link_ifelse_blocks(main_dialogues, ifelse_if_first, ifelse_else_first, ifelse_if_last, ifelse_else_last)
	for tag_name in _branch_dialogues:
		_link_ifelse_blocks(_branch_dialogues[tag_name], ifelse_if_first, ifelse_else_first, ifelse_if_last, ifelse_else_last)

	# 7. 连接分支内对话的 next_id
	for tag_name in _branch_dialogues:
		var branch_dialogs: Array = _branch_dialogues[tag_name]
		for idx in range(branch_dialogs.size() - 1):
			var cur: KND_Dialogue = branch_dialogs[idx]
			var nxt: KND_Dialogue = branch_dialogs[idx + 1]
			if cur.next_id.is_empty():
				cur.next_id = nxt.node_id

	# 8. 连接 if/else 块内对话的 next_id
	for key in _ifelse_blocks:
		var blocks: Dictionary = _ifelse_blocks[key]
		var if_dialogs: Array = blocks.get("if", [])
		var else_dialogs: Array = blocks.get("else", [])
		for idx in range(if_dialogs.size() - 1):
			if if_dialogs[idx].next_id.is_empty():
				if_dialogs[idx].next_id = if_dialogs[idx + 1].node_id
		for idx in range(else_dialogs.size() - 1):
			if else_dialogs[idx].next_id.is_empty():
				else_dialogs[idx].next_id = else_dialogs[idx + 1].node_id

	# 9. 扁平化：将所有对话放入 shot.dialogues
	shot.dialogues.clear()
	for d in main_dialogues:
		shot.dialogues.append(d)
	for tag_name in _branch_dialogues:
		for bd in _branch_dialogues[tag_name]:
			shot.dialogues.append(bd)
	for key in _ifelse_blocks:
		var blocks: Dictionary = _ifelse_blocks[key]
		for bd in blocks.get("if", []):
			shot.dialogues.append(bd)
		for bd in blocks.get("else", []):
			shot.dialogues.append(bd)

	# 10. 设置起始节点
	if shot.dialogues.size() > 0:
		shot.start_node_id = main_dialogues[0].node_id


## 解析选项跳转目标
func _resolve_choice_targets(dialogs: Array, tag_map: Dictionary) -> void:
	for d in dialogs:
		if d.dialog_type == KND_Dialogue.Type.SHOW_CHOICE:
			for choice in d.choices:
				if tag_map.has(choice.next_id):
					choice.next_id = tag_map[choice.next_id]
				else:
					push_warning("警告：%s [行：%d] 选项跳转标签 '%s' 未找到对应分支" % [
						_path, d.source_file_line, choice.next_id])


## 解析 jump_branch 跳转目标
func _resolve_jump_branch_targets(dialogs: Array, tag_map: Dictionary) -> void:
	for d in dialogs:
		if d.dialog_type == KND_Dialogue.Type.JUMP_BRANCH:
			var target: String = d.jump_branch_target
			if tag_map.has(target):
				d.next_id = tag_map[target]
			else:
				push_warning("警告：%s [行：%d] jump_branch 目标分支 '%s' 未找到" % [
					_path, d.source_file_line, target])


## 连接 if/else 块的跳转关系
func _link_ifelse_blocks(dialogs: Array, if_first: Dictionary, else_first: Dictionary, if_last: Dictionary, else_last: Dictionary) -> void:
	for d in dialogs:
		if d.dialog_type == KND_Dialogue.Type.IFELSE_BRANCH:
			var key: String = d.get_meta("ifelse_key", "")
			if key.is_empty():
				continue

			# if_next_id 指向 if 块的第一个节点
			if if_first.has(key):
				d.if_next_id = if_first[key]
			# else_next_id 指向 else 块的第一个节点
			if else_first.has(key):
				d.else_next_id = else_first[key]

			# if/else 块最后一个节点的 next_id 指向汇合点
			var converge_id: String = d.next_id
			if not converge_id.is_empty():
				if if_last.has(key):
					var blocks: Dictionary = _ifelse_blocks[key]
					var if_dialogs: Array = blocks.get("if", [])
					if if_dialogs.size() > 0:
						var last_if: KND_Dialogue = if_dialogs[if_dialogs.size() - 1]
						if last_if.next_id.is_empty():
							last_if.next_id = converge_id
				if else_last.has(key):
					var blocks: Dictionary = _ifelse_blocks[key]
					var else_dialogs: Array = blocks.get("else", [])
					if else_dialogs.size() > 0:
						var last_else: KND_Dialogue = else_dialogs[else_dialogs.size() - 1]
						if last_else.next_id.is_empty():
							last_else.next_id = converge_id
