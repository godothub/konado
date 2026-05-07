extends Node
class_name KND_SaveSystem

## KND_SaveSystem
##
## 基于快照原理的存档系统核心类，负责创建、存储和恢复游戏状态的快照
## 支持对话系统的存档/读档功能，与现有对话管理系统无缝集成

## 存档完成
signal save_completed(save_id: int, success: bool)

## 读档完成
signal load_completed(save_id: int, success: bool)

## 存档目录
const SAVE_DIR = "user://konado_saves/"

## 存档文件扩展名
const SAVE_EXT = ".kns"

## 最大存档数量
@export var max_save_slots: int = 20

## 自动存档间隔（秒）
@export var auto_save_interval: float = 5.0

## 是否启用自动存档
@export var enable_auto_save: bool = true

## 存档策略配置
@export var save_strategy: Dictionary = {
	"include_dialogue_state": true,
	"include_variables": true,
	"include_audio_state": true,
	"include_actor_state": true,
	"include_background_state": true
}

## 对话管理器引用
var dialogue_manager: KND_DialogueManager

## 自动存档计时器
var auto_save_timer: Timer

func _ready() -> void:
	# 确保存档目录存在
	_dir_check()
	
	# 初始化自动存档计时器
	if enable_auto_save:
		auto_save_timer = Timer.new()
		auto_save_timer.wait_time = auto_save_interval
		auto_save_timer.autostart = true
		auto_save_timer.timeout.connect(_auto_save)
		add_child(auto_save_timer)

## 检查并创建存档目录
func _dir_check() -> void:
	if not DirAccess.dir_exists_absolute(SAVE_DIR):
		DirAccess.make_dir_recursive_absolute(SAVE_DIR)

## 设置对话管理器
func set_dialogue_manager(manager: KND_DialogueManager) -> void:
	dialogue_manager = manager

## 创建存档
func save_game(save_id: int) -> bool:
	if save_id < 0 or save_id >= max_save_slots:
		printerr("存档ID超出范围")
		return false
	
	if not dialogue_manager:
		printerr("对话管理器未设置")
		return false
	
	# 创建存档数据
	var save_data = KND_SaveData.new()
	
	# 填充存档数据
	if save_strategy["include_dialogue_state"]:
		save_data.dialogue_state = _capture_dialogue_state()
	
	if save_strategy["include_variables"]:
		if dialogue_manager.variable_store:
			save_data.variables = dialogue_manager.variable_store.to_dict()
		else:
			save_data.variables = {}
	
	if save_strategy["include_audio_state"]:
		save_data.audio_state = _capture_audio_state()
	
	if save_strategy["include_actor_state"]:
		save_data.actor_state = _capture_actor_state()
	
	if save_strategy["include_background_state"]:
		save_data.background_state = _capture_background_state()
	
	# 添加存档元数据
	save_data.save_time = Time.get_datetime_dict_from_system()
	save_data.version = "1.0"
	
	# 序列化为JSON
	var json = JSON.stringify(save_data.to_dict())
	if json == "":
		printerr("存档序列化失败")
		return false
	
	# 写入文件
	var save_path = SAVE_DIR + str(save_id) + SAVE_EXT
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	if not file:
		printerr("无法打开存档文件进行写入")
		return false
	
	file.store_string(json)
	file.close()
	
	print("存档成功: " + OS.get_user_data_dir() + "/" + save_path.replace("user://", ""))
	save_completed.emit(save_id, true)
	return true

## 加载存档
func load_game(save_id: int) -> bool:
	if save_id < 0 or save_id >= max_save_slots:
		printerr("存档ID超出范围")
		return false
	
	if not dialogue_manager:
		printerr("对话管理器未设置")
		return false
	
	# 读取存档文件
	var save_path = SAVE_DIR + str(save_id) + SAVE_EXT
	var file = FileAccess.open(save_path, FileAccess.READ)
	if not file:
		printerr("无法打开存档文件进行读取")
		return false
	
	var json = file.get_as_text().strip_edges()
	file.close()
	
	# 反序列化为存档数据
	var parse_result = JSON.parse_string(json)
	if typeof(parse_result) != TYPE_DICTIONARY:
		printerr("存档解析失败")
		return false
	
	var save_data = KND_SaveData.new()
	save_data.from_dict(parse_result)
	
	# 恢复游戏状态
	if save_strategy["include_dialogue_state"] and save_data.dialogue_state:
		_restore_dialogue_state(save_data.dialogue_state)
	
	# 恢复背景状态
	if save_strategy["include_background_state"] and save_data.background_state:
		_restore_background_state(save_data.background_state)
	
	# 恢复演员状态
	if save_strategy["include_actor_state"] and save_data.actor_state:
		_restore_actor_state(save_data.actor_state)
	
	# 恢复音频状态
	if save_strategy["include_audio_state"] and save_data.audio_state:
		_restore_audio_state(save_data.audio_state)
	
	# 恢复游戏变量
	if save_strategy["include_variables"] and save_data.variables:
		if dialogue_manager.variable_store:
			dialogue_manager.variable_store.from_dict(save_data.variables)
		else:
			dialogue_manager.variable_store = KND_VariableStore.new()
			dialogue_manager.variable_store.from_dict(save_data.variables)
	
	print("读档成功: " + save_path)
	load_completed.emit(save_id, true)
	return true

## 删除存档
func delete_save(save_id: int) -> bool:
	if save_id < 0 or save_id >= max_save_slots:
		printerr("存档ID超出范围")
		return false
	
	var save_path = SAVE_DIR + str(save_id) + SAVE_EXT
	if not FileAccess.file_exists(save_path):
		return true  # 文件不存在，视为删除成功
	
	var dir = DirAccess.open(SAVE_DIR)
	if dir:
		return dir.remove(str(save_id) + SAVE_EXT)
	return false

## 获取存档信息
func get_save_info(save_id: int) -> Dictionary:
	if save_id < 0 or save_id >= max_save_slots:
		return {"exists": false}
	
	var save_path = SAVE_DIR + str(save_id) + SAVE_EXT
	if not FileAccess.file_exists(save_path):
		return {"exists": false}
	
	var file = FileAccess.open(save_path, FileAccess.READ)
	if not file:
		return {"exists": false}
	
	var json = file.get_as_text()
	file.close()
	
	var parse_result = JSON.parse_string(json)
	if typeof(parse_result) != TYPE_DICTIONARY:
		return {"exists": false}
	
	return {
		"save_time": parse_result.get("save_time", {}),
		"version": parse_result.get("version", ""),
		"exists": true
	}

## 获取所有存档信息
func get_all_save_info() -> Array[Dictionary]:
	var save_infos: Array[Dictionary] = []
	for i in range(max_save_slots):
		save_infos.append(get_save_info(i))
	return save_infos

## 自动存档
func _auto_save() -> void:
	save_game(0)  # 自动存档到0号槽位

## 捕获对话状态
func _capture_dialogue_state() -> Dictionary:
	var state = {}
	
	# 保存当前镜头
	if dialogue_manager.cur_dialogue_shot:
		var shot_path = dialogue_manager.cur_dialogue_shot.ks_path
		state["shot_path"] = shot_path
		print("保存镜头路径: " + shot_path)
	else:
		print("当前镜头为空，未保存shot_path")
	
	# 保存当前对话节点ID
	state["current_node_id"] = dialogue_manager.cur_node_id
	
	# 保存对话状态
	state["dialogue_state"] = dialogue_manager.dialogueState
	
	# 保存当前对话内容（从对话框中获取）
	if dialogue_manager._konado_dialogue_box:
		state["current_dialog_content"] = dialogue_manager._konado_dialogue_box.dialogue_text
		state["current_character_name"] = dialogue_manager._konado_dialogue_box.character_name
		print("保存对话内容: " + dialogue_manager._konado_dialogue_box.dialogue_text)
		print("保存角色名称: " + dialogue_manager._konado_dialogue_box.character_name)
	else:
		# 如果对话框不存在，尝试从当前镜头的对话列表中获取
		if dialogue_manager.cur_dialogue_shot:
			var current_dialog = dialogue_manager._current_dialogue()
			if current_dialog and current_dialog.dialog_content:
				state["current_dialog_content"] = current_dialog.dialog_content
				print("保存对话内容: " + current_dialog.dialog_content)
	
	return state

## 恢复对话状态
func _restore_dialogue_state(state: Dictionary) -> void:
	# 加载镜头
	if state.has("shot_path") and state["shot_path"]:
		var shot = load(state["shot_path"]) as KND_Shot
		if shot:
			dialogue_manager.set_shot(shot)
	
	# 恢复对话节点ID
	if state.has("current_node_id"):
		var node_id: String = state["current_node_id"]
		if dialogue_manager.cur_dialogue_shot and dialogue_manager.cur_dialogue_shot.find_node(node_id) != null:
			dialogue_manager.cur_node_id = node_id
		elif dialogue_manager.cur_dialogue_shot:
			# 节点ID无效，回退到起始节点
			dialogue_manager.cur_node_id = dialogue_manager.cur_dialogue_shot.start_node_id
		else:
			dialogue_manager.cur_node_id = ""
	
	# 恢复对话状态
	if state.has("dialogue_state"):
		dialogue_manager._dialogue_goto_state(state["dialogue_state"])
	
	# 恢复对话框内容
	if dialogue_manager._konado_dialogue_box:
		if state.has("current_dialog_content"):
			dialogue_manager._konado_dialogue_box.dialogue_text = state["current_dialog_content"]
			print("恢复对话内容: " + state["current_dialog_content"])
		if state.has("current_character_name"):
			dialogue_manager._konado_dialogue_box.character_name = state["current_character_name"]
			print("恢复角色名称: " + state["current_character_name"])

## 捕获音频状态
func _capture_audio_state() -> Dictionary:
	var state = {}
	
	if dialogue_manager and dialogue_manager._audio_interface:
		var audio_interface = dialogue_manager._audio_interface
		print("捕获音频状态")
		
		# 保存BGM状态
		if audio_interface.bgm_player:
			print("BGM播放器存在")
			if audio_interface.bgm_player.stream:
				state["bgm"] = {
					"stream_path": audio_interface.bgm_player.stream.resource_path,
					"is_playing": audio_interface.bgm_player.is_playing(),
					"volume_db": audio_interface.bgm_player.volume_db
				}
				print("保存BGM状态：" + str(state["bgm"]))
			else:
				print("BGM播放器无流")
		else:
			print("BGM播放器不存在")
		
		# 保存语音状态
		if audio_interface.voice_player:
			print("语音播放器存在")
			if audio_interface.voice_player.stream:
				state["voice"] = {
					"stream_path": audio_interface.voice_player.stream.resource_path,
					"is_playing": audio_interface.voice_player.is_playing(),
					"volume_db": audio_interface.voice_player.volume_db
				}
				print("保存语音状态：" + str(state["voice"]))
			else:
				print("语音播放器无流")
		else:
			print("语音播放器不存在")
		
		# 保存音效状态
		if audio_interface.sound_effect_player:
			print("音效播放器存在")
			if audio_interface.sound_effect_player.stream:
				state["sound_effect"] = {
					"stream_path": audio_interface.sound_effect_player.stream.resource_path,
					"is_playing": audio_interface.sound_effect_player.is_playing(),
					"volume_db": audio_interface.sound_effect_player.volume_db
				}
				print("保存音效状态：" + str(state["sound_effect"]))
			else:
				print("音效播放器无流")
		else:
			print("音效播放器不存在")
	else:
		print("对话管理器或音频接口不存在")
	
	print("最终捕获的音频状态：" + str(state))
	return state

## 恢复音频状态
func _restore_audio_state(state: Dictionary) -> void:
	if not dialogue_manager or not dialogue_manager._audio_interface:
		return
	
	var audio_interface = dialogue_manager._audio_interface
	
	# 恢复BGM状态
	if state.has("bgm"):
		var bgm_state = state["bgm"]
		if bgm_state.has("stream_path"):
			var bgm_stream = load(bgm_state["stream_path"])
			if bgm_stream:
				audio_interface.bgm_player.stream = bgm_stream
				if bgm_state.has("volume_db"):
					audio_interface.bgm_player.volume_db = bgm_state["volume_db"]
				if bgm_state.has("is_playing") and bgm_state["is_playing"]:
					audio_interface.bgm_player.play()
	
	# 恢复语音状态
	if state.has("voice"):
		var voice_state = state["voice"]
		if voice_state.has("stream_path"):
			var voice_stream = load(voice_state["stream_path"])
			if voice_stream:
				audio_interface.voice_player.stream = voice_stream
				if voice_state.has("volume_db"):
					audio_interface.voice_player.volume_db = voice_state["volume_db"]
				if voice_state.has("is_playing") and voice_state["is_playing"]:
					audio_interface.voice_player.play()
	
	# 恢复音效状态
	if state.has("sound_effect"):
		var se_state = state["sound_effect"]
		if se_state.has("stream_path"):
			var se_stream = load(se_state["stream_path"])
			if se_stream:
				audio_interface.sound_effect_player.stream = se_stream
				if se_state.has("volume_db"):
					audio_interface.sound_effect_player.volume_db = se_state["volume_db"]
				if se_state.has("is_playing") and se_state["is_playing"]:
					audio_interface.sound_effect_player.play()

## 捕获演员状态
func _capture_actor_state() -> Dictionary:
	var state = {}
	
	if dialogue_manager and dialogue_manager._acting_interface:
		var acting_interface = dialogue_manager._acting_interface
		state["actors"] = []
		
		# 保存所有演员的状态
		print("捕获演员状态，演员数量：" + str(acting_interface.actor_dict.size()))
		for actor_id in acting_interface.actor_dict.keys():
			print("处理演员：" + actor_id)
			var actor_data = acting_interface.actor_dict[actor_id]
			var actor_node = acting_interface.get_chara_node(actor_id)
			
			if actor_node:
				# 获取v_character_position属性
				var pos_v = 0
				# 直接访问属性，GDScript中访问不存在的属性会返回null
				# 使用安全的方式获取属性值
				var pos_value = actor_node.v_character_position
				if pos_value != null:
					pos_v = pos_value
				
				var actor_state = {
					"id": actor_id,
					"h_division": actor_data.get("h_division", 6),
					"v_division": actor_data.get("v_division", 6),
					"pos_h": actor_data.get("pos", 0),
					"pos_v": pos_v,
					"state": actor_data.get("state", ""),
					"c_scale": actor_data.get("c_scale", 1.0),
					"mirror": actor_data.get("mirror", false)
				}
				state["actors"].append(actor_state)
				print("保存演员状态：" + str(actor_state))
			else:
				print("未找到演员节点：" + actor_id)
		if acting_interface.actor_dict.size() == 0:
			print("演员字典中无数据")
	
	print("最终捕获的演员状态：" + str(state))
	return state

## 恢复演员状态
func _restore_actor_state(state: Dictionary) -> void:
	if not dialogue_manager or not dialogue_manager._acting_interface:
		return
	
	var acting_interface = dialogue_manager._acting_interface
	
	# 先删除所有现有演员
	acting_interface.delete_all_actor()
	
	# 等待一帧，确保所有旧的演员节点都已经被完全删除
	await get_tree().process_frame
	
	# 恢复演员状态
	if state.has("actors"):
		for actor_state in state["actors"]:
			var actor_id = actor_state.get("id", "")
			if actor_id:
				# 查找对应的角色数据
				var target_chara = null
				if dialogue_manager.chara_list:
					for chara in dialogue_manager.chara_list.characters:
						if chara.chara_name == actor_id:
							target_chara = chara
							break
				
				if target_chara:
					# 查找对应的状态纹理
					var state_name = actor_state.get("state", "")
					var state_tex = null
					for chara_state in target_chara.chara_status:
						if chara_state.status_name == state_name:
							state_tex = chara_state.status_texture
							break
					
					if state_tex:
						# 创建演员
						acting_interface.create_new_character(
							actor_id,
							actor_state.get("h_division", 6),
							actor_state.get("v_division", 6),
							actor_state.get("pos_h", 0),
							actor_state.get("pos_v", 0),
							state_name,
							state_tex,
							actor_state.get("c_scale", 1.0),
							actor_state.get("mirror", false)
						)
						
						# 等待一帧，确保演员节点能够正确创建
						await get_tree().process_frame

## 捕获背景状态
func _capture_background_state() -> Dictionary:
	var state = {}
	
	if dialogue_manager and dialogue_manager._acting_interface:
		var acting_interface = dialogue_manager._acting_interface
		print("捕获背景状态")
		state["background_id"] = acting_interface.background_id
		print("背景ID：" + acting_interface.background_id)
		if acting_interface.current_texture:
			state["background_texture_path"] = acting_interface.current_texture.resource_path
			print("背景纹理路径：" + acting_interface.current_texture.resource_path)
		else:
			print("当前背景纹理为空")
	else:
		print("对话管理器或表演接口不存在")
	
	print("最终捕获的背景状态：" + str(state))
	return state

## 恢复背景状态
func _restore_background_state(state: Dictionary) -> void:
	if not dialogue_manager or not dialogue_manager._acting_interface:
		return
	
	var acting_interface = dialogue_manager._acting_interface
	
	# 恢复背景状态
	if state.has("background_id") and state.has("background_texture_path"):
		var bg_id = state["background_id"]
		var bg_tex_path = state["background_texture_path"]
		
		# 确保bg_tex_path不为空
		if bg_tex_path and bg_tex_path != "":
			var bg_tex = load(bg_tex_path)
			
			if bg_tex:
				acting_interface.change_background_image(
					bg_tex,
					bg_id,
					KND_ActingInterface.BackgroundTransitionEffectsType.NONE_EFFECT
				)
			else:
				print("无法加载背景纹理: " + bg_tex_path)
