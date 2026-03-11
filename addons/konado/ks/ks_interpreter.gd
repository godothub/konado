extends RefCounted
class_name KonadoScriptsInterpreter

## Konado脚本解释器

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
	
	# 匹配 if %变量名 == 值（支持数字），结尾冒号可选（:?）
	condition_regex = RegEx.new()
	condition_regex.compile("^if\\s+%(\\w+)\\s*==\\s*(\\d+):$")
	# 匹配 %变量名 格式的变量引用
	var_ref_regex = RegEx.new()
	var_ref_regex.compile("%(\\w+)")

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
	
	# 清空演员验证表
	cur_tmp_actors = []
	# 清空角色依赖记录
	dep_characters.clear()
	
	tmp_content_lines = raw_script_lines
	
	# 解析内容行
	var i = 0
	while i < raw_script_lines.size():
		tmp_line_number = i
		var original_line = raw_script_lines[i]  # 保留原始行（未strip）
		var line = original_line.strip_edges()  # 处理后的行，用于内容解析
		var original_line_number =  i + 2
		tmp_original_line_number = original_line_number

		# 空行或注释行跳过
		if line.is_empty() or line.begins_with("#") or line.begins_with("##"):
			i += 1
			continue
			
		print("第%d行内容：" % original_line_number, line)
		
		if line.begins_with("else") || line.begins_with("endif"):
			i += 1
			continue
		
		var dialog: KND_Dialogue = parse_line(line, original_line_number, path, shot)
		if dialog:
			# 如果是标签对话，则添加到标签对话字典中
			if dialog.dialog_type == KND_Dialogue.Type.BRANCH:
				shot.branches.set(dialog.branch_id, dialog)
			else:
				shot.dialogues.append(dialog)
			if dialog.dialog_type == KND_Dialogue.Type.IFELSE_BRANCH:
				i = tmp_line_number + 1
			else:
				i += 1
		else:
			_scripts_debug(path, original_line_number, "解析失败：无法识别的语法，终止解析: %s" % line)
			return null
		
		i += 1
			
	_scripts_info(path, 0, "文件：%s 章节ID：%s 对话数量：%d" % 
		[path, shot.shot_id, shot.dialogues.size()])

	tmp_path = ""

	# 标签验证失败
	if not _check_tag_and_choice():
		_scripts_debug(path, 0, "标签和选项解析失败，终止所有解析")
		return null
	
	return shot

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
	if _parse_jumpshot(line, dialog):
		print("解析成功：跳转镜头相关\n")
		return dialog
	if _parse_end(line, dialog, diadata):  # 传入diadata
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
	
	
	
## 条件判断（if/else/endif）
func _parse_condition(line: String, start_index: int, line_number: int, path: String, shot: KND_Shot) -> KND_Dialogue:
	var cur_dialogue: KND_Dialogue = KND_Dialogue.new()
	cur_dialogue.dialog_type = KND_Dialogue.Type.IFELSE_BRANCH
	
	var current_index = start_index + 1  # 跳过if行，开始解析内容
	var original_line_num = line_number
	var condition_result: bool = false  
	var has_else = false
	var else_index = -1
	
	# 解析if条件表达式
	var cond_match = condition_regex.search(line)
	if not cond_match:
		_scripts_debug(path, original_line_num, "条件判断格式错误：%s（正确格式：if %%变量名 == 整数）" % line)
		return null
	
	var var_name = cond_match.get_string(1)
	var target_value = cond_match.get_string(2).to_int()
	
	cur_dialogue.varname = var_name
	cur_dialogue.target_value = target_value
	
	
	# 解析if块内容（直到else或endif）
	var if_block_lines = []
	var if_block_line_nums = []
	while current_index < tmp_content_lines.size():
		var original_line = tmp_content_lines[current_index]
		var current_line: String = original_line.strip_edges()
		var current_line_num = original_line_num + (current_index - start_index)
		
		# 遇到else，记录位置并终止if块解析
		if current_line.begins_with("else:"):
			has_else = true
			else_index = current_index
			break
		
		# 遇到endif，终止if块解析
		if current_line.begins_with("endif"):
			break
		
		# 空行/注释行跳过（但计入行号）
		if current_line.is_empty() or current_line.begins_with("#"):
			current_index += 1
			continue
		
		# 添加到if块内容
		if_block_lines.append(current_line)
		if_block_line_nums.append(current_line_num)
		current_index += 1
	
	var if_result_dialogs: Array[KND_Dialogue]
	for idx in range(if_block_lines.size()):
		var block_line = if_block_lines[idx]
		var block_line_num = if_block_line_nums[idx]
		var dialog = parse_line(block_line, block_line_num, path, shot)
		if dialog:
			if_result_dialogs.append(dialog)
		else:
			_scripts_debug(path, block_line_num, "if块内解析失败：%s" % block_line)
			return null
			
	cur_dialogue.if_result_dialogs = if_result_dialogs
	
	# 解析else块内容（条件不成立时生效）
	if has_else and else_index > 0:
		var else_block_index = else_index + 1
		var else_block_lines = []
		var else_block_line_nums = []
		
		# 解析else块内容（直到endif）
		while else_block_index < tmp_content_lines.size():
			var original_line = tmp_content_lines[else_block_index]
			var current_line = original_line.strip_edges()
			var current_line_num = original_line_num + (else_block_index - start_index)
			
			# 遇到endif，终止else块解析
			if current_line == "endif":
				break
			
			# 空行/注释行跳过
			if current_line.is_empty() or current_line.begins_with("#"):
				else_block_index += 1
				continue
			
			# 添加到else块内容
			else_block_lines.append(current_line)
			else_block_line_nums.append(current_line_num)
			else_block_index += 1
		
		# 条件不成立时解析else块

		var else_result_dialogs: Array[KND_Dialogue]
		for idx in range(else_block_lines.size()):
			var block_line = else_block_lines[idx]
			var block_line_num = else_block_line_nums[idx]
			var dialog = parse_line(block_line, block_line_num, path, shot)
			if dialog:
				
				else_result_dialogs.append(dialog)
			else:
				_scripts_debug(path, block_line_num, "else块内解析失败：%s" % block_line)
				return null
				
		cur_dialogue.else_result_dialogs = else_result_dialogs
		
		
		# 更新current_index到endif位置
		current_index = else_block_index
	
	# 5. 验证是否有endif结尾
	if current_index >= tmp_content_lines.size() or tmp_content_lines[current_index].strip_edges() != "endif":
		_scripts_debug(path, original_line_num, "条件判断缺少endif结尾（当前行：%s）" % line)
		return null
	
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
			"line_number": line_num
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
				dialog.actor_position = Vector2(parts[5].to_float(), parts[6].to_float())
			if parts.size() >= 9 and parts[7] == "scale":
				dialog.actor_scale = parts[8].to_float()
			if parts.size() == 10:
				if parts[9] == "mirror":
					dialog.actor_mirror = true

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
			# 修复：增加数组长度检查，避免索引越界
			if parts.size() >= 5:
				dialog.target_move_pos = Vector2(parts[3].to_float(), parts[4].to_float())
	
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

# 解析选项（仅保留单行式choice：choice "文本" 标签 "文本2" 标签2）
func _parse_choice(line: String, dialog: KND_Dialogue) -> bool:
	# 仅匹配单行式choice：以choice开头，且不是choice:
	if not line.begins_with("choice ") or line.begins_with("choice:"):
		return false
	
	dialog.dialog_type = KND_Dialogue.Type.SHOW_CHOICE
	dialog.choices.clear()  # 清空现有选项
	
	# 移除开头的"choice"关键字
	var content = line.substr(6).strip_edges()
	
	# 使用正则表达式来正确解析带引号的字符串
	var regex = RegEx.new()
	regex.compile('"([^"\\\\]*(?:\\\\.[^"\\\\]*)*)"|(\\S+)')
	
	var matches = regex.search_all(content)
	var parts = []
	
	for match in matches:
		if match.get_string(1) != "":  # 带引号的部分
			# 恢复转义的引号
			var text = match.get_string(1).replace('\\"', '"')
			parts.append(text)
		elif match.get_string(2) != "":  # 无引号的部分
			parts.append(match.get_string(2))
	
	# 验证parts数量
	if parts.size() % 2 != 0:
		_scripts_debug(tmp_path, tmp_original_line_number, "选项格式错误: 每个选项必须包含文本和跳转标签")
		return false
	
	# 创建选项对象
	for i in range(0, parts.size(), 2):
		var choice = KND_DialogueChoice.new()
		choice.choice_text = parts[i]
		choice.jump_tag = parts[i + 1]
		dialog.choices.append(choice)
	
	# 记录日志
	var choices_strs = ""
	for choice in dialog.choices:
		choices_strs += "\"" + choice.choice_text + "\" -> " + choice.jump_tag + "  "
	
	# 记录跳转标签用于后续验证
	var jump_tags = []
	for choice in dialog.choices:
		jump_tags.append(choice.jump_tag)
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
	dialog.branch_id = parts[1]

	# 改用通用的缩进块解析函数
	var branch_block_lines = _parse_indented_block(tmp_line_number + 1, tmp_original_line_number + 1)
	
	# 解析branch内的内容
	for block_line_info in branch_block_lines:
		var inner_line = block_line_info.line
		var inner_line_num = block_line_info.line_number
		
		if inner_line.begins_with("branch"):
			_scripts_debug(tmp_path, inner_line_num, "branch内不能嵌套branch")
			return false
		
		var inner_dialog = parse_line(inner_line, inner_line_num, tmp_path, null)
		if inner_dialog:
			dialog.branch_dialogue.append(inner_dialog)

	tmp_tags.append(dialog.branch_id)

	_scripts_info(tmp_path, tmp_original_line_number, "标签" + dialog.branch_id + "解析完成" + " " + "标签内有" + str(dialog.branch_dialogue.size()) + "行对话")

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
	
	
# 错误报告
func _scripts_debug(path: String, line: int, error_info: String):
	push_error("错误：%s [行：%d] %s " % [path, line, error_info])

# 警告提示
func _scripts_warning(path: String, line: int, warning_info: String):
	push_warning("警告：%s [行：%d] %s " % [path, line, warning_info])

# 信息提示
func _scripts_info(path: String, line: int, info_info: String):
	print("信息：%s [行：%d] %s " % [path, line, info_info])
