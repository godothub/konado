extends RefCounted
class_name KonadoScriptsInterpreter

## Konado脚本解释器 - 节点图模型版本
## 解析.ks脚本文件并生成带有node_id/next_id链接的KND_Shot

## 源文件脚本路径
var tmp_path = ""
## 源文件脚本行，显示在编辑器中
var tmp_original_line_number = 0
## 当前脚本行，经过处理后的行
var tmp_line_number = 0
var tmp_content_lines = []

## 对话内容正则表达式
var dialogue_content_regex: RegEx

## 条件判断正则（匹配 if %变量 == 值 格式）
var condition_regex: RegEx
## 变量引用正则（匹配 %变量名 格式）
var var_ref_regex: RegEx

## 演员验证表
var cur_tmp_actors = []

## 角色依赖记录，出现的角色将记录下来
var dep_characters: Array[String] = []

## 选项行记录表 key: 行号 value: 行内容
var cur_tmp_option_lines = {}
var tmp_tags = []

## 临时分支存储（tag_name -> Array[KND_Dialogue]）
var tmp_branches: Dictionary = {}
## 临时if/else块存储（temp_key -> {"if": Array, "else": Array}）
var tmp_ifelse_blocks: Dictionary = {}
## if/else块计数器
var _ifelse_counter: int = 0
## 节点ID计数器
var _node_counter: int = 0

const BACKGROUND_EFFECTS_MAP: Dictionary = {
	"none": KND_ActingInterface.BackgroundTransitionEffectsType.NONE_EFFECT,
	"erase": KND_ActingInterface.BackgroundTransitionEffectsType.EraseEffect,
	"blinds": KND_ActingInterface.BackgroundTransitionEffectsType.BlindsEffect,
	"wave": KND_ActingInterface.BackgroundTransitionEffectsType.WaveEffect,
	"fade": KND_ActingInterface.BackgroundTransitionEffectsType.ALPHA_FADE_EFFECT,
	"vortex": KND_ActingInterface.BackgroundTransitionEffectsType.VORTEX_SWAP_EFFECT,
	"windmill": KND_ActingInterface.BackgroundTransitionEffectsType.WINDMILL_EFFECT,
	"cyberglitch": KND_ActingInterface.BackgroundTransitionEffectsType.CYBER_GLITCH_EFFECT
}

func _init() -> void:
	# 提前初始化正则表达式，避免重复编译
	dialogue_content_regex = RegEx.new()
	dialogue_content_regex.compile("^\"(.*?)\"\\s+\"(.*?)\"(?:\\s+(\\S+))?$")

	# 匹配 if %变量名 == 值 或 if $变量名 == 值（支持数字），结尾冒号可选（:?）
	condition_regex = RegEx.new()
	condition_regex.compile("^if\\s+([%$])(\\w+)\\s*(==|!=|>=|<=|>|<)\\s*(\\d+):$")
	# 匹配 %变量名 或 $变量名 格式的变量引用
	var_ref_regex = RegEx.new()
	var_ref_regex.compile("([%$])(\\w+)")

## 生成唯一节点ID
func _next_node_id() -> String:
	_node_counter += 1
	return "ks_node_%d" % _node_counter

## 全文解析模式
func process_scripts_to_data(path: String) -> KND_Shot:
	if not FileAccess.file_exists(path):
		_scripts_debug(path, 0, "文件不存在，无法打开脚本文件")
		return null
	tmp_path = path

	# 读取文件内容
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		_scripts_debug(path, 0, "无法打开脚本文件")
		return null
	var raw_script_lines = file.get_as_text().split("\n")
	file.close()

	_scripts_info(path, 0, "开始解析脚本文件")
	var shot: KND_Shot = KND_Shot.new()

	shot.ks_path = path

	# 清空临时数据
	cur_tmp_actors = []
	dep_characters.clear()
	cur_tmp_option_lines = {}
	tmp_tags = []
	tmp_branches = {}
	tmp_ifelse_blocks = {}
	_ifelse_counter = 0
	_node_counter = 0

	tmp_content_lines = raw_script_lines

	# 第一遍：解析所有行为对话节点
	var main_dialogues: Array[KND_Dialogue] = []
	var i = 0
	while i < raw_script_lines.size():
		tmp_line_number = i
		var original_line = raw_script_lines[i]
		var line = original_line.strip_edges()
		var original_line_number = i + 2
		tmp_original_line_number = original_line_number

		# 空行或注释行跳过
		if line.is_empty() or line.begins_with("#"):
			i += 1
			continue

		print("第%d行内容：" % original_line_number, line)

		if line.begins_with("else") || line.begins_with("endif"):
			i += 1
			continue

		if line.begins_with("choice "):
			var choice_dialog := KND_Dialogue.new()
			choice_dialog.dialog_type = KND_Dialogue.Type.SHOW_CHOICE
			choice_dialog.source_file_line = original_line_number

			while i < raw_script_lines.size():
				var cline = raw_script_lines[i].strip_edges()
				if cline.is_empty() or cline.begins_with("#"):
					i += 1
					continue
				if not cline.begins_with("choice "):
					break
				if not _parse_single_choice_line(cline, choice_dialog):
					_scripts_debug(path, i + 2, "选项解析失败: %s" % cline)
					return null
				i += 1

			if choice_dialog.choices.size() == 0:
				_scripts_debug(path, original_line_number, "选项行没有有效的选项")
				return null

			var jump_tags = []
			for c in choice_dialog.choices:
				jump_tags.append(c.next_id)
			cur_tmp_option_lines[original_line_number] = jump_tags

			var choices_strs = ""
			for c in choice_dialog.choices:
				choices_strs += "\"" + c.choice_text + "\" -> " + c.next_id + "  "
			_scripts_info(path, original_line_number, "选项解析完成 选项数量: " + str(choice_dialog.choices.size()) + "  选项: " + choices_strs)

			main_dialogues.append(choice_dialog)
			continue

		var dialog: KND_Dialogue = parse_line(line, original_line_number, path, shot)
		if dialog:
			if dialog.dialog_type == KND_Dialogue.Type.BRANCH:
				# 分支内容已存储在tmp_branches中，不添加到主列表
				pass
			else:
				main_dialogues.append(dialog)
			if dialog.dialog_type == KND_Dialogue.Type.IFELSE_BRANCH:
				i = tmp_line_number + 1
			else:
				i += 1
		else:
			_scripts_debug(path, original_line_number, "解析失败：无法识别的语法，终止解析: %s" % line)
			return null

	_scripts_info(path, 0, "文件：%s 章节ID：%s 对话数量：%d" %
		[path, shot.shot_id, main_dialogues.size()])

	tmp_path = ""

	# 标签验证
	if not _check_tag_and_choice():
		_scripts_debug(path, 0, "标签和选项解析失败，终止所有解析")
		return null

	# 第二遍：后处理 - 分配node_id，扁平化分支，连接next_id
	_post_process_shot(shot, main_dialogues)

	return shot

## 后处理：分配node_id，扁平化分支内容，连接next_id
func _post_process_shot(shot: KND_Shot, main_dialogues: Array[KND_Dialogue]) -> void:
	# 1. 为主线对话分配node_id
	for d in main_dialogues:
		if d.node_id.is_empty():
			d.node_id = _next_node_id()

	# 2. 为分支内对话分配node_id
	var tag_to_first_node_id: Dictionary = {}  # tag_name -> first node_id of branch
	for tag_name in tmp_branches:
		var branch_dialogs: Array = tmp_branches[tag_name]
		if branch_dialogs.size() > 0:
			for bd in branch_dialogs:
				if bd.node_id.is_empty():
					bd.node_id = _next_node_id()
			tag_to_first_node_id[tag_name] = branch_dialogs[0].node_id

	# 3. 为if/else块内对话分配node_id
	var ifelse_if_first: Dictionary = {}   # temp_key -> first node_id of if block
	var ifelse_else_first: Dictionary = {} # temp_key -> first node_id of else block
	var ifelse_if_last: Dictionary = {}    # temp_key -> last node_id of if block
	var ifelse_else_last: Dictionary = {}  # temp_key -> last node_id of else block

	for key in tmp_ifelse_blocks:
		var blocks = tmp_ifelse_blocks[key]
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

	# 4. 连接主线对话的next_id
	for idx in range(main_dialogues.size() - 1):
		var cur = main_dialogues[idx]
		var nxt = main_dialogues[idx + 1]
		# 选项节点不需要主线next_id（选项由choice.next_id控制）
		if cur.dialog_type != KND_Dialogue.Type.SHOW_CHOICE and cur.dialog_type != KND_Dialogue.Type.THE_END and cur.dialog_type != KND_Dialogue.Type.JUMP and cur.dialog_type != KND_Dialogue.Type.JUMP_BRANCH:
			if cur.dialog_type == KND_Dialogue.Type.IFELSE_BRANCH:
				# if/else节点的next_id指向下一个主线节点（汇合点）
				cur.next_id = nxt.node_id
			else:
				cur.next_id = nxt.node_id

	# 5. 解析选项的next_id（从tag名称转换为node_id）
	for d in main_dialogues:
		if d.dialog_type == KND_Dialogue.Type.SHOW_CHOICE:
			for choice in d.choices:
				if tag_to_first_node_id.has(choice.next_id):
					choice.next_id = tag_to_first_node_id[choice.next_id]
				else:
					_scripts_warning(tmp_path, d.source_file_line,
					"选项跳转标签 '%s' 未找到对应分支" % choice.next_id)

	# 5.5 解析jump_branch的next_id（从tag名称转换为node_id）
	_resolve_jump_branch_targets(main_dialogues, tag_to_first_node_id)
	for tag_name in tmp_branches:
		_resolve_jump_branch_targets(tmp_branches[tag_name], tag_to_first_node_id)
	for key in tmp_ifelse_blocks:
		var blocks = tmp_ifelse_blocks[key]
		_resolve_jump_branch_targets(blocks.get("if", []), tag_to_first_node_id)
		_resolve_jump_branch_targets(blocks.get("else", []), tag_to_first_node_id)

	# 6. 连接if/else块的next_id
	for d in main_dialogues:
		if d.dialog_type == KND_Dialogue.Type.IFELSE_BRANCH:
			var key = d.get_meta("ifelse_key", "")
			if key.is_empty():
				continue

			# if_next_id 指向if块的第一个节点
			if ifelse_if_first.has(key):
				d.if_next_id = ifelse_if_first[key]
			# else_next_id 指向else块的第一个节点
			if ifelse_else_first.has(key):
				d.else_next_id = ifelse_else_first[key]

			# if/else块最后一个节点的next_id指向汇合点（即if/else节点的next_id）
			var converge_id = d.next_id
			if not converge_id.is_empty():
				if ifelse_if_last.has(key):
					var blocks = tmp_ifelse_blocks[key]
					var if_dialogs: Array = blocks.get("if", [])
					if if_dialogs.size() > 0:
						var last_if = if_dialogs[if_dialogs.size() - 1]
						if last_if.next_id.is_empty():
							last_if.next_id = converge_id
				if ifelse_else_last.has(key):
					var blocks = tmp_ifelse_blocks[key]
					var else_dialogs: Array = blocks.get("else", [])
					if else_dialogs.size() > 0:
						var last_else = else_dialogs[else_dialogs.size() - 1]
						if last_else.next_id.is_empty():
							last_else.next_id = converge_id

	# 7. 连接分支内对话的next_id
	for tag_name in tmp_branches:
		var branch_dialogs: Array = tmp_branches[tag_name]
		for idx in range(branch_dialogs.size() - 1):
			var cur = branch_dialogs[idx]
			var nxt = branch_dialogs[idx + 1]
			if cur.next_id.is_empty():
				cur.next_id = nxt.node_id

	# 7.5 连接分支内if/else块的next_id（步骤7已设置IFELSE_BRANCH.next_id为收敛点）
	for tag_name in tmp_branches:
		var branch_dialogs: Array = tmp_branches[tag_name]
		for d in branch_dialogs:
			if d.dialog_type == KND_Dialogue.Type.IFELSE_BRANCH:
				var key = d.get_meta("ifelse_key", "")
				if key.is_empty():
					continue
				if ifelse_if_first.has(key):
					d.if_next_id = ifelse_if_first[key]
				if ifelse_else_first.has(key):
					d.else_next_id = ifelse_else_first[key]
				var converge_id = d.next_id
				if not converge_id.is_empty():
					if ifelse_if_last.has(key):
						var blocks = tmp_ifelse_blocks[key]
						var if_dialogs: Array = blocks.get("if", [])
						if if_dialogs.size() > 0:
							var last_if = if_dialogs[if_dialogs.size() - 1]
							if last_if.next_id.is_empty():
								last_if.next_id = converge_id
					if ifelse_else_last.has(key):
						var blocks = tmp_ifelse_blocks[key]
						var else_dialogs: Array = blocks.get("else", [])
						if else_dialogs.size() > 0:
							var last_else = else_dialogs[else_dialogs.size() - 1]
							if last_else.next_id.is_empty():
								last_else.next_id = converge_id

	# 8. 连接if/else块内对话的next_id
	for key in tmp_ifelse_blocks:
		var blocks = tmp_ifelse_blocks[key]
		var if_dialogs: Array = blocks.get("if", [])
		var else_dialogs: Array = blocks.get("else", [])
		for idx in range(if_dialogs.size() - 1):
			if if_dialogs[idx].next_id.is_empty():
				if_dialogs[idx].next_id = if_dialogs[idx + 1].node_id
		for idx in range(else_dialogs.size() - 1):
			if else_dialogs[idx].next_id.is_empty():
				else_dialogs[idx].next_id = else_dialogs[idx + 1].node_id

	# 9. 扁平化：将所有对话放入shot.dialogues
	shot.dialogues.clear()
	for d in main_dialogues:
		shot.dialogues.append(d)
	for tag_name in tmp_branches:
		for bd in tmp_branches[tag_name]:
			shot.dialogues.append(bd)
	for key in tmp_ifelse_blocks:
		var blocks = tmp_ifelse_blocks[key]
		for bd in blocks.get("if", []):
			shot.dialogues.append(bd)
		for bd in blocks.get("else", []):
			shot.dialogues.append(bd)

	# 10. 设置起始节点
	if shot.dialogues.size() > 0:
		shot.start_node_id = main_dialogues[0].node_id

func _resolve_jump_branch_targets(dialogs: Array, tag_to_first_node_id: Dictionary) -> void:
	for d in dialogs:
		if d.dialog_type == KND_Dialogue.Type.JUMP_BRANCH:
			var target = d.jump_branch_target
			if tag_to_first_node_id.has(target):
				d.next_id = tag_to_first_node_id[target]
			else:
				_scripts_warning(tmp_path, d.source_file_line,
					"jump_branch 目标分支 '%s' 未找到" % target)

# 单行解析模式
func parse_single_line(line: String, line_number: int, path: String) -> KND_Dialogue:
	return parse_line(line.strip_edges(), line_number, path, null)

# 内部解析实现
func parse_line(line: String, line_number: int, path: String, diadata: KND_Shot) -> KND_Dialogue:
	var dialog := KND_Dialogue.new()
	dialog.source_file_line = line_number
	

	if _parse_dialog(line, dialog):
		print("解析成功：对话相关\n")
		return dialog
	if _parse_background(line, dialog):
		print("解析成功：背景切换\n")
		return dialog
	if _parse_actor(line, dialog):
		print("解析成功：角色相关\n")
		return dialog
	if _parse_audio(line, dialog):
		print("解析成功：音频相关\n")
		return dialog
	if _parse_choice(line, dialog):
		print("解析成功：选择相关\n")
		return dialog
	if _parse_jump_branch(line, dialog):
		print("解析成功：跳转分支\n")
		return dialog
	if _parse_jumpshot(line, dialog):
		print("解析成功：跳转镜头相关\n")
		return dialog
	if _parse_signal(line, dialog):
		print("解析成功：自定义信号\n")
		return dialog
	if _parse_achievement(line, dialog):
		print("解析成功：成就系统\n")
		return dialog
	if _parse_variable(line, dialog):
		print("解析成功：变量操作\n")
		return dialog
	if _parse_end(line, dialog, diadata):
		print("解析成功：结束相关\n")
		return dialog
	if line.begins_with("if "):
		var condition_dialogs = _parse_condition(line, tmp_line_number, line_number, path, diadata)
		if condition_dialogs:
			return condition_dialogs
	if _parse_branch(line, dialog):
		print("解析成功：标签相关\n")
		return dialog

	dialog = null
	return null


## signal自定义信号
func _parse_signal(line: String, dialog: KND_Dialogue) -> bool:
	if not line.begins_with("signal"):
		return false

	var content = line.substr(7).strip_edges()
	if content.is_empty():
		_scripts_debug(tmp_path, tmp_original_line_number, "信号指令内容为空")
		return false

	dialog.dialog_type = KND_Dialogue.Type.SIGNAL
	dialog.custom_signal_name = content

	return true


## 条件判断（if/else/endif）
func _parse_condition(line: String, start_index: int, line_number: int, path: String, shot: KND_Shot) -> KND_Dialogue:
	var cur_dialogue: KND_Dialogue = KND_Dialogue.new()
	cur_dialogue.dialog_type = KND_Dialogue.Type.IFELSE_BRANCH

	var current_index = start_index + 1  # 跳过if行，开始解析内容
	var original_line_num = line_number
	var has_else = false
	var else_index = -1

	# 解析if条件表达式
	var cond_match = condition_regex.search(line)
	if not cond_match:
		_scripts_debug(path, original_line_num, "条件判断格式错误：%s（正确格式：if %%变量名 == 整数 或 if $变量名 == 整数，支持操作符：==、!=、>、<、>=、<=）" % line)
		return null

	var prefix = cond_match.get_string(1)
	var var_name = cond_match.get_string(2)
	var operator_str = cond_match.get_string(3)
	var target_value = cond_match.get_string(4).to_int()

	var condition_op: int = 0
	match operator_str:
		"==":
			condition_op = 0
		">":
			condition_op = 1
		"<":
			condition_op = 2
		">=":
			condition_op = 3
		"<=":
			condition_op = 4
		"!=":
			condition_op = 5

	cur_dialogue.varname = var_name
	cur_dialogue.condition_operator = condition_op
	cur_dialogue.target_value = target_value
	cur_dialogue.is_persistent = (prefix == "%")

	# 解析if块内容（直到else或endif）
	var if_block_lines = []
	var if_block_line_nums = []
	while current_index < tmp_content_lines.size():
		var original_line = tmp_content_lines[current_index]
		var current_line: String = original_line.strip_edges()
		var current_line_num = original_line_num + (current_index - start_index)

		if current_line.begins_with("else:"):
			has_else = true
			else_index = current_index
			break

		if current_line.begins_with("endif"):
			break

		if current_line.is_empty() or current_line.begins_with("#"):
			current_index += 1
			continue

		if_block_lines.append(current_line)
		if_block_line_nums.append(current_line_num)
		current_index += 1

	var if_result_dialogs: Array[KND_Dialogue] = []
	for idx in range(if_block_lines.size()):
		var block_line = if_block_lines[idx]
		var block_line_num = if_block_line_nums[idx]
		var dialog = parse_line(block_line, block_line_num, path, shot)
		if dialog:
			if_result_dialogs.append(dialog)
		else:
			_scripts_debug(path, block_line_num, "if块内解析失败：%s" % block_line)
			return null

	var else_result_dialogs: Array[KND_Dialogue] = []

	# 解析else块内容
	if has_else and else_index > 0:
		var else_block_index = else_index + 1
		var else_block_lines = []
		var else_block_line_nums = []

		while else_block_index < tmp_content_lines.size():
			var original_line = tmp_content_lines[else_block_index]
			var current_line = original_line.strip_edges()
			var current_line_num = original_line_num + (else_block_index - start_index)

			if current_line == "endif":
				break

			if current_line.is_empty() or current_line.begins_with("#"):
				else_block_index += 1
				continue

			else_block_lines.append(current_line)
			else_block_line_nums.append(current_line_num)
			else_block_index += 1

		for idx in range(else_block_lines.size()):
			var block_line = else_block_lines[idx]
			var block_line_num = else_block_line_nums[idx]
			var dialog = parse_line(block_line, block_line_num, path, shot)
			if dialog:
				else_result_dialogs.append(dialog)
			else:
				_scripts_debug(path, block_line_num, "else块内解析失败：%s" % block_line)
				return null

		current_index = else_block_index

	# 验证是否有endif结尾
	if current_index >= tmp_content_lines.size() or tmp_content_lines[current_index].strip_edges() != "endif":
		_scripts_debug(path, original_line_num, "条件判断缺少endif结尾（当前行：%s）" % line)
		return null

	# 存储if/else块到临时字典
	_ifelse_counter += 1
	var ifelse_key = "ifelse_%d" % _ifelse_counter
	tmp_ifelse_blocks[ifelse_key] = {
		"if": if_result_dialogs,
		"else": else_result_dialogs
	}
	# 用meta存储key，后处理时使用
	cur_dialogue.set_meta("ifelse_key", ifelse_key)

	# 更新全局索引到endif的下一行
	tmp_line_number = current_index

	_scripts_info(path, line_number, "条件判断解析完成")

	return cur_dialogue

# ========== 保留：解析缩进块内容（用于branch） ==========
func _parse_indented_block(start_index: int, start_line_num: int) -> Array[Dictionary]:
	var block_lines: Array[Dictionary] = []
	var current_index = start_index

	while current_index < tmp_content_lines.size():
		var original_line = tmp_content_lines[current_index]
		var line_stripped = original_line.strip_edges()
		var line_num = start_line_num + (current_index - start_index)

		# 空行跳过
		if line_stripped.is_empty():
			current_index += 1
			continue

		# 检查缩进（4个空格或制表符）
		if not (original_line.begins_with("    ") or original_line.begins_with("\t")):
			break

		# 添加到块内容（去掉缩进）
		block_lines.append({
			"line": line_stripped,
			"line_number": line_num,
			"index": current_index
		})

		current_index += 1

	# 更新全局索引到块结束位置
	tmp_line_number = current_index
	return block_lines

# 背景切换解析
func _parse_background(line: String, dialog: KND_Dialogue) -> bool:
	if not line.begins_with("background"):
		return false

	var parts = line.split(" ", false)
	if parts.size() < 2:
		return false

	dialog.dialog_type = KND_Dialogue.Type.SWITCH_BACKGROUND
	dialog.background_image_name = parts[1]

	if parts.size() >= 3:
		var effect = parts[2]
		dialog.background_toggle_effects = BACKGROUND_EFFECTS_MAP.get(effect, KND_ActingInterface.BackgroundTransitionEffectsType.NONE_EFFECT)

	return true

# 角色相关解析
func _parse_actor(line: String, dialog: KND_Dialogue) -> bool:
	if not line.begins_with("actor"):
		return false

	var parts = line.split(" ", false)
	if parts.size() < 3:
		return false

	match parts[1]:
		"show":
			dialog.dialog_type = KND_Dialogue.Type.DISPLAY_ACTOR
			dialog.character_name = parts[2]
			dialog.character_state = parts[3]
			# 修复：增加数组长度检查，避免索引越界
			if parts.size() >= 6 and parts[4] == "at":
				dialog.actor_position = Vector2(parts[5].to_float(), 0.0)

			if not dep_characters.has(dialog.character_name):
				dep_characters.append(dialog.character_name)

			if not cur_tmp_actors.has(dialog.character_name):
				cur_tmp_actors.append(dialog.character_name)
			else:
				_scripts_debug(tmp_path, tmp_original_line_number, "角色已存在，请检查角色名称是否重复创建")
				return false
		"exit":
			dialog.dialog_type = KND_Dialogue.Type.EXIT_ACTOR
			dialog.exit_actor = parts[2]
			if cur_tmp_actors.has(parts[2]):
				cur_tmp_actors.erase(parts[2])
			else:
				_scripts_debug(tmp_path, tmp_original_line_number, "无法移除不存在的角色，请检查角色名称是否正确")
		"change":
			dialog.dialog_type = KND_Dialogue.Type.ACTOR_CHANGE_STATE
			dialog.change_state_actor = parts[2]

			if not cur_tmp_actors.has(parts[2]):
				_scripts_debug(tmp_path, tmp_original_line_number, "无法改变不存在的角色的状态，请检查角色名称是否正确")

			dialog.change_state = parts[3]
		"move":
			dialog.dialog_type = KND_Dialogue.Type.MOVE_ACTOR
			dialog.target_move_chara = parts[2]

			if not cur_tmp_actors.has(parts[2]):
				_scripts_debug(tmp_path, tmp_original_line_number, "无法移动不存在的角色的位置，请检查角色名称是否正确")
			dialog.target_move_pos = Vector2(parts[3].to_float(), 0.0)

	return true

# 音频解析
func _parse_audio(line: String, dialog: KND_Dialogue) -> bool:
	if not line.begins_with("play") and not line.begins_with("stop"):
		return false

	var parts = line.split(" ", false)
	if parts[0] == "play":
		if parts.size() < 3:
			return false
		if parts[1] == "bgm":
			dialog.dialog_type = KND_Dialogue.Type.PLAY_BGM
			dialog.bgm_name = parts[2]
		elif parts[1] == "sfx":
			dialog.dialog_type = KND_Dialogue.Type.PLAY_SOUND_EFFECT
			dialog.soundeffect_name = parts[2]
	elif parts[0] == "stop":
		if parts.size() >= 2 and parts[1] == "bgm":
			dialog.dialog_type = KND_Dialogue.Type.STOP_BGM
		else:
			dialog.dialog_type = KND_Dialogue.Type.STOP_BGM

	return true

func _parse_single_choice_line(line: String, dialog: KND_Dialogue) -> bool:
	var content = line.substr(6).strip_edges()

	var regex = RegEx.new()
	regex.compile('"([^"\\\\]*(?:\\\\.[^"\\\\]*)*)"|(\\S+)')

	var matches = regex.search_all(content)
	var raw_parts = []

	for match in matches:
		if match.get_string(1) != "":
			var text = match.get_string(1).replace('\\"', '"')
			raw_parts.append(text)
		elif match.get_string(2) != "":
			raw_parts.append(match.get_string(2))

	var parts = []
	var j = 0
	while j < raw_parts.size():
		if raw_parts[j] == "->":
			j += 1
			continue
		parts.append(raw_parts[j])
		j += 1

	if parts.size() != 2:
		return false

	var choice = KND_DialogueChoice.new()
	choice.choice_text = parts[0]
	choice.next_id = parts[1]
	dialog.choices.append(choice)
	return true

# 解析选项（格式：choice "文本" -> 标签 "文本2" -> 标签2）
func _parse_choice(line: String, dialog: KND_Dialogue) -> bool:
	if not line.begins_with("choice ") or line.begins_with("choice:"):
		return false

	dialog.dialog_type = KND_Dialogue.Type.SHOW_CHOICE
	dialog.choices.clear()

	var content = line.substr(6).strip_edges()

	var regex = RegEx.new()
	regex.compile('"([^"\\\\]*(?:\\\\.[^"\\\\]*)*)"|(\\S+)')

	var matches = regex.search_all(content)
	var raw_parts = []

	for match in matches:
		if match.get_string(1) != "":
			var text = match.get_string(1).replace('\\"', '"')
			raw_parts.append(text)
		elif match.get_string(2) != "":
			raw_parts.append(match.get_string(2))

	var parts = []
	var i = 0
	while i < raw_parts.size():
		if raw_parts[i] == "->":
			i += 1
			continue
		parts.append(raw_parts[i])
		i += 1

	if parts.size() % 2 != 0:
		_scripts_debug(tmp_path, tmp_original_line_number, "选项格式错误: 每个选项必须包含文本和跳转标签，格式: choice \"文本\" -> 标签")
		return false

	for ic in range(0, parts.size(), 2):
		var choice = KND_DialogueChoice.new()
		choice.choice_text = parts[ic]
		choice.next_id = parts[ic + 1]
		dialog.choices.append(choice)

	var choices_strs = ""
	for choice in dialog.choices:
		choices_strs += "\"" + choice.choice_text + "\" -> " + choice.next_id + "  "

	var jump_tags = []
	for choice in dialog.choices:
		jump_tags.append(choice.next_id)
	cur_tmp_option_lines[tmp_original_line_number] = jump_tags

	_scripts_info(tmp_path, tmp_line_number + 1, "选项解析完成 选项数量: " + str(dialog.choices.size()) + "  选项: " + choices_strs)
	return true

# 分支解析
func _parse_branch(line: String, dialog: KND_Dialogue) -> bool:
	if not line.begins_with("branch"):
		return false

	var parts = line.split(" ", false)
	if parts.size() < 2:
		_scripts_debug(tmp_path, tmp_original_line_number, "branch格式错误")
		return false
	dialog.dialog_type = KND_Dialogue.Type.BRANCH
	var branch_id = parts[1]

	# 改用通用的缩进块解析函数
	var branch_block_lines = _parse_indented_block(tmp_line_number + 1, tmp_original_line_number + 1)

	# 解析branch内的内容
	var branch_dialogues: Array[KND_Dialogue] = []
	var idx = 0
	while idx < branch_block_lines.size():
		var block_line_info = branch_block_lines[idx]
		var inner_line = block_line_info.line
		var inner_line_num = block_line_info.line_number

		if inner_line.begins_with("branch"):
			_scripts_debug(tmp_path, inner_line_num, "branch内不能嵌套branch")
			return false

		if inner_line.begins_with("if "):
			var saved_line_number = tmp_line_number
			tmp_line_number = block_line_info.index
			var inner_dialog = parse_line(inner_line, inner_line_num, tmp_path, null)
			if inner_dialog:
				branch_dialogues.append(inner_dialog)
			var consumed_until = tmp_line_number
			tmp_line_number = saved_line_number
			idx += 1
			while idx < branch_block_lines.size() and branch_block_lines[idx].index <= consumed_until:
				idx += 1
			continue

		var inner_dialog = parse_line(inner_line, inner_line_num, tmp_path, null)
		if inner_dialog:
			branch_dialogues.append(inner_dialog)
		idx += 1

	# 存储到临时分支字典
	tmp_branches[branch_id] = branch_dialogues
	tmp_tags.append(branch_id)

	_scripts_info(tmp_path, tmp_original_line_number, "标签" + branch_id + "解析完成" + " " + "标签内有" + str(branch_dialogues.size()) + "行对话")

	return true

# 分支内跳转解析
func _parse_jump_branch(line: String, dialog: KND_Dialogue) -> bool:
	if not line.begins_with("jump_branch"):
		return false

	var parts = line.split(" ", false)
	if parts.size() < 2:
		_scripts_debug(tmp_path, tmp_original_line_number, "jump_branch格式错误：缺少目标分支名")
		return false
	dialog.dialog_type = KND_Dialogue.Type.JUMP_BRANCH
	dialog.jump_branch_target = parts[1]
	return true

# 跳转解析
func _parse_jumpshot(line: String, dialog: KND_Dialogue) -> bool:
	if not line.begins_with("jump"):
		return false

	var parts = line.split(" ", false)
	if parts.size() < 2:
		return false
	dialog.dialog_type = KND_Dialogue.Type.JUMP
	dialog.jump_shot_path = parts[1]
	return true

# 对话解析（使用正则表达式优化）
func _parse_dialog(line: String, dialog: KND_Dialogue) -> bool:
	if not line.begins_with("\""):
		return false

	var result = dialogue_content_regex.search(line)
	if not result:
		return false

	dialog.dialog_type = KND_Dialogue.Type.ORDINARY_DIALOG
	dialog.character_id = result.get_string(1)
	dialog.dialog_content = result.get_string(2)
	if result.get_string(3):
		dialog.voice_id = result.get_string(3)

	return true

func _parse_variable(line: String, dialog: KND_Dialogue) -> bool:
	var parts = line.split(" ", false)
	if parts.size() < 3:
		return false

	var op_str = parts[0]
	var var_name_raw = parts[1]
	var operand_raw = ""

	var is_persistent: bool
	if var_name_raw.begins_with("%"):
		is_persistent = true
	elif var_name_raw.begins_with("$"):
		is_persistent = false
	else:
		return false

	var var_name = var_name_raw.substr(1)

	var op: int = -1
	match op_str:
		"set":
			op = KND_VariableStore.Operation.SET
		"add":
			op = KND_VariableStore.Operation.ADD
		"sub":
			op = KND_VariableStore.Operation.SUB
		"mul":
			op = KND_VariableStore.Operation.MUL
		"div":
			op = KND_VariableStore.Operation.DIV
		_:
			return false

	if parts.size() >= 4 and parts[2] == "=":
		operand_raw = " ".join(parts.slice(3))
	else:
		operand_raw = " ".join(parts.slice(2))

	operand_raw = operand_raw.strip_edges()
	if operand_raw.begins_with("\"") and operand_raw.ends_with("\""):
		operand_raw = operand_raw.substr(1, operand_raw.length() - 2)

	dialog.dialog_type = KND_Dialogue.Type.SET_VARIABLE
	dialog.variable_name = var_name
	dialog.variable_operation = op
	dialog.variable_operand = operand_raw
	dialog.is_persistent = is_persistent

	_scripts_info(tmp_path, tmp_original_line_number, "变量操作: %s %s%s = %s" % [op_str, "%" if is_persistent else "$", var_name, operand_raw])
	return true

## 解析结束
func _parse_end(line: String, dialog: KND_Dialogue, diadata: KND_Shot) -> bool:
	if line.begins_with("end"):
		dialog.dialog_type = KND_Dialogue.Type.THE_END
		return true
	return false

# 检查tag和choice
func _check_tag_and_choice() -> bool:
	for line_num in cur_tmp_option_lines:
		var jump_tags = cur_tmp_option_lines[line_num] as Array
		for tag in jump_tags:
			if not tmp_tags.has(tag):
				_scripts_debug(tmp_path, line_num, "跳转标签 '%s' 不存在（当前可选标签：%s）" % [tag, str(tmp_tags)])
				return false
	return true

## 成就系统解析
func _parse_achievement(line: String, dialog: KND_Dialogue) -> bool:
	if not line.begins_with("achievement"):
		return false

	# 使用简单的分割，后续再精细化处理引号
	var parts = line.split(" ", false)
	if parts.size() < 3:
		_scripts_debug(tmp_path, tmp_original_line_number, "achievement 指令格式错误")
		return false

	var action = parts[1]
	
	var raw_id = parts[2]
	var target_id = ""
	if raw_id.begins_with("\"") and raw_id.ends_with("\""):
		target_id = raw_id.substr(1, raw_id.length() - 2)

	match action:
		"unlock":
			dialog.dialog_type = KND_Dialogue.Type.ACHIEVEMENT_UNLOCK
			dialog.achievement_id = target_id # 假设 KND_Dialogue 已新增该字段
			
		"increment":
			if parts.size() < 4:
				_scripts_debug(tmp_path, tmp_original_line_number, "achievement increment 缺少增量数值")
				return false
			dialog.dialog_type = KND_Dialogue.Type.ACHIEVEMENT_PROGRESS
			dialog.achievement_id = target_id
			dialog.achievement_value = parts[3].to_int()
			
		"set_flag":
			if parts.size() < 4:
				_scripts_debug(tmp_path, tmp_original_line_number, "achievement set_flag 缺少布尔值 (true/false)")
				return false
			dialog.dialog_type = KND_Dialogue.Type.ACHIEVEMENT_FLAG
			dialog.achievement_flag_name = target_id # 假设 KND_Dialogue 已新增该字段
			dialog.achievement_flag_value = (parts[3].to_lower() == "true") # 假设 KND_Dialogue 已新增该字段
			
		_:
			_scripts_debug(tmp_path, tmp_original_line_number, "未知的 achievement 操作: " + action)
			return false

	return true

# 错误报告
func _scripts_debug(path: String, line: int, error_info: String):
	push_error("错误：%s [行：%d] %s " % [path, line, error_info])

# 警告提示
func _scripts_warning(path: String, line: int, warning_info: String):
	push_warning("警告：%s [行：%d] %s " % [path, line, warning_info])

# 信息提示
func _scripts_info(path: String, line: int, info_info: String):
	print("信息：%s [行：%d] %s " % [path, line, info_info])
