extends Control
class_name KND_DialogueManager

## KND_DialogueManager
##
## Konado对话管理器是对话系统的核心管理类，负责统一调度和管理对话流程的全生命周期，包括对话初始化、播放控制、各类对话指令执行（普通对话、角色显示/隐藏/移动、背景切换、音频播放、选项分支等）、状态管理和错误处理。
## 将该脚本挂载到场景中的Control节点上，在编辑器面板中配置配置对话资源后即可开始使用


## 镜头开启播放的信号
signal shot_start

## 镜头结束播放的信号
signal shot_end

## 对话开始播放的信号
signal dialogue_line_start(line: int)

## 对话结束播放的信号
signal dialogue_line_end(line: int)

@export_category("Playback Settings")

## 是否在游戏开始时自动初始化对话，如果为true，则在游戏开始时自动初始化对话，否则需要手动初始化对话
## 手动初始化对话的方法为：在游戏开始时，调用`init_dialogue`方法
@export var init_onstart: bool = true

## 是否自动开始对话，如果为true，则在游戏开始时自动开始对话，否则需要手动开始对话
## 手动开始对话的方法为：在游戏开始时，调用`start_dialogue`方法
@export var autostart: bool = true

## 是否开启演员自动高亮，如果为true，则根据对话中的角色姓名自动高亮对应的演员，否则不自动高亮
## 一般来说大部分场景可能需要打开能获得更好的效果
@export var actor_auto_highlight: bool = true

## 自动播放
@export var autoplay: bool = false
## 对话打字播放速度
@export var _typing_interval: float = 0.04
## 自动播放速度
@export var autoplayspeed: float = 2

@export_category("Global Variable")

## 对话全局变量
@export var dialogue_variables: Dictionary[String, int]

@export_category("UI Settings")

## 演员画布横向分块
@export var horizontal_division: int = 6
## 演员画布纵向分块
@export var vertical_division: int = 6

## 对话界面接口类
@export var _konado_choice_interface: KND_ChoiceInterface

## 对话框
@export var _konado_dialogue_box: KND_DialogueBox

## 背景和角色UI界面接口
@export var _acting_interface: KND_ActingInterface
## 音频接口
@export var _audio_interface: KND_AudioInterface

## 对话资源ID
var _dialog_data_id: int = 0

var option_triggered: bool = false

## 对话状态（0:关闭，1:播放，2:播放完成下一个）
enum DialogState 
{
	OFF, 
	PLAYING, 
	PAUSED
}

var dialogueState: DialogState

## 读取对话列表的下标
var cur_index: int

## 是否第一进入当前句对话，由于一些方法只需要在首次进入当前行对话时调用一次，而一些方法需要循环调用（如检查打字动画是否完成的方法）
## 因此，需要判断是否第一次进入当前行对话
var justenter: bool

## 当前对话的类型
var cur_dialogue_type: KND_Dialogue.Type

## 资源列表
@export_category("Dialogue Resources")
## 对话资源
@export var start_dialogue_shot: KND_Shot = null
## 角色列表
@export var chara_list: KND_CharacterList
## 背景列表
@export var background_list: KND_BackgroundList
## BGM列表
@export var bgm_list: KND_BgmList
## 配音资源列表
@export var voice_list: DialogVoiceList
## 音效列表
@export var soundeffect_list: KND_SoundEffectList

@export_category("Log Tool")
## 是否显示错误日志覆盖
@export var enable_overlay_log: bool = true
## 报错提示面板
@export var error_tooltip_panel: ColorRect
@export var error_tooltip_label: Label
@export var error_skip_btn: Button



func _ready() -> void:
	if enable_overlay_log:
		print("开启日志记录器")
		# 初始化Logger
		var logger: KND_Logger = KND_Logger.new()
		OS.add_logger(logger)
		# 使用Deferred避免线程问题
		logger.error_caught.connect(_show_error, ConnectFlags.CONNECT_DEFERRED)
		
		if error_skip_btn:
			error_skip_btn.pressed.connect(func():
				error_tooltip_panel.hide())
		else:
			push_warning("未指定 error_skip_btn")
	
	if _konado_dialogue_box:
		_konado_dialogue_box.on_dialogue_click.connect(_process_next)
	else:
		push_error("未指定 _konado_dialogue_box")
	

	# 自动初始化和开始对话
	if init_onstart:
		print("自动初始化对话")
		# 初始化对话
		if not autostart:
			init_dialogue(func():
				print("请手动开始对话")
				)
		else:
			init_dialogue(func():
				print("自动开始对话")
				await get_tree().process_frame
				start_dialogue()
				)
	else:
		print("请手动初始化对话")

## 显示报错
func _show_error(msg: String) -> void:
	if enable_overlay_log:
		if error_tooltip_label:
			error_tooltip_label.text = msg
		else:
			printerr(msg)
		if error_tooltip_panel:
			error_tooltip_panel.show()

## 初始化对话的方法
func init_dialogue(callback: Callable = Callable()) -> void:
	# 如果对话数据为空，则默认为第一个对话数据
	if start_dialogue_shot == null:
		push_error("未设置对话镜头")
		return
	# 将角色表传给acting_interface
	_acting_interface.chara_list = chara_list

	# 初始化各管理器
	_acting_interface.delete_all_actor()

	justenter = true
	dialogueState == DialogState.OFF
	cur_index = 0
	print_rich("[color=yellow]初始化对话 [/color]" + "justenter: " + str(justenter) +
	" 对话下标: " + str(cur_index) + " 当前状态: " + str(dialogueState))
	print("---------------------------------------------")
	if callback:
		callback.call()

## 设置对话数据的方法
func set_shot(new_shot: KND_Shot) -> void:
	self.start_dialogue_shot = new_shot
	
## 设置角色表的方法
func set_chara_list(chara_list: KND_CharacterList) -> void:
	if chara_list == null:
		printerr("角色列表为空")
		return
	print(chara_list.to_string())
	self.chara_list = chara_list

func set_background_list(background_list: KND_BackgroundList) -> void:
	if background_list == null:
		printerr("背景列表为空")
		return
	print(background_list.to_string())
	self.background_list = background_list

func set_bgm_list(bgm_list: KND_BgmList) -> void:
	if bgm_list == null:
		printerr("BGM列表为空")
		return
	print(bgm_list.to_string())
	self.bgm_list = bgm_list
	
## 获取对话变量
func get_dialogue_variable(key: String) -> Dictionary:
	if dialogue_variables.has(key):
		return { "value": dialogue_variables[key] }
	return {}

## 开始对话的方法
func start_dialogue() -> void:
	if !_konado_choice_interface:
		_konado_choice_interface.show()
	if !_acting_interface:
		_acting_interface.show()
	
	_konado_dialogue_box.show_dialogue_box()
	_dialogue_goto_state(DialogState.PLAYING)
	print_rich("[color=yellow]开始对话 [/color]")
	# 播放镜头信号
	shot_start.emit()



func _process(delta) -> void:
	match dialogueState:
		# 关闭状态
		DialogState.OFF:
			if justenter:
				print_rich("[color=cyan][b]当前状态：[/b][/color][color=orange]关闭状态[/color]")
				justenter = false
		# 播放状态
		DialogState.PLAYING:
			if justenter:
				justenter = false
				print_rich("[color=cyan][b]当前状态：[/b][/color][color=orange]播放状态[/color]")
				if start_dialogue_shot == null:
					print_rich("[color=red]对话为空[/color]")
					return
				if start_dialogue_shot.dialogues.size() <= 0:
					print_rich("[color=red]对话为空[/color]")
					_dialogue_goto_state(DialogState.OFF)
					return
				# 对话类型
				cur_dialogue_type = start_dialogue_shot.dialogues[cur_index].dialog_type
				# 对话当前句
				var dialog = start_dialogue_shot.dialogues[cur_index]
				dialogue_line_start.emit(cur_index)
				# 隐藏选项
				_konado_choice_interface._choice_container.hide()
				# 判断对话类型
				# 如果是普通对话
				if cur_dialogue_type == KND_Dialogue.Type.ORDINARY_DIALOG:
					# 播放对话
					var chara_id
					var content
					var voice_id
					if (dialog.character_id != null):
						chara_id = dialog.character_id
					if (dialog.dialog_content != null):
						content = dialog.dialog_content
					if dialog.voice_id:
						voice_id = dialog.voice_id
		
					var playvoice
					if voice_id:
						playvoice = true
					else:
						playvoice = false
					
					# 如果有配音播放配音
					if voice_id:
						_play_voice(voice_id)
					
					if _konado_dialogue_box.typing_completed.is_connected(isfinishtyping):
						_konado_dialogue_box.typing_completed.disconnect(isfinishtyping)
					
					_konado_dialogue_box.typing_completed.connect(isfinishtyping.bind(playvoice))
					# 设置角色高亮
					if actor_auto_highlight:
						if chara_id:
							_acting_interface.highlight_actor(chara_id)
					# 播放对话
					_konado_dialogue_box.typing_interval = _typing_interval
					_konado_dialogue_box.dialogue_text = content
					_konado_dialogue_box.character_name = chara_id
				# 如果是切换背景
				elif cur_dialogue_type == KND_Dialogue.Type.SWITCH_BACKGROUND:
					# 显示背景
					var bg_name = dialog.background_image_name
					var bg_effect = dialog.background_toggle_effects
					var s = _acting_interface.background_change_finished
					s.connect(_auto_process_next.bind(s))
					_acting_interface.show()
					_display_background(bg_name, bg_effect)
				# 如果是显示演员
				elif cur_dialogue_type == KND_Dialogue.Type.DISPLAY_ACTOR:
					# 显示演员
					var s = _acting_interface.character_created
					s.connect(_auto_process_next.bind(s))
					_acting_interface.show()
					_display_character(dialog)
				# 如果修改演员状态
				elif cur_dialogue_type == KND_Dialogue.Type.ACTOR_CHANGE_STATE:
					var actor = dialog.change_state_actor
					var target_state = dialog.change_state
					var s = _acting_interface.character_state_changed
					s.connect(_auto_process_next.bind(s))
					_actor_change_state(actor, target_state)
				# 如果是移动演员
				elif cur_dialogue_type == KND_Dialogue.Type.MOVE_ACTOR:
					var actor = dialog.target_move_chara
					var pos = dialog.target_move_pos
					var s = _acting_interface.character_moved
					s.connect(_auto_process_next.bind(s))
					_acting_interface.move_actor(actor, pos.x, pos.y)
				# 如果是删除演员
				elif cur_dialogue_type == KND_Dialogue.Type.EXIT_ACTOR:
					# 删除演员
					var actor = dialog.exit_actor
					var s = _acting_interface.character_deleted
					s.connect(_auto_process_next.bind(s))
					_exit_actor(actor)
				# 如果是选项
				elif cur_dialogue_type == KND_Dialogue.Type.SHOW_CHOICE:
					var dialog_choices = dialog.choices
					if dialog_choices.size() <= 0:
						printerr("当前没有任何选项，为不影响运行跳过")
						_dialogue_goto_state(DialogState.PAUSED)
						get_tree().process_frame
						_process_next()
					else:
						# 生成并显示选项
						_konado_choice_interface.display_options(dialog_choices, self)
						_acting_interface.show()
						_konado_choice_interface.show()
						_konado_choice_interface._choice_container.show()
				# 如果是播放BGM
				elif cur_dialogue_type == KND_Dialogue.Type.PLAY_BGM:
					var bgm_name = dialog.bgm_name
					_play_bgm(bgm_name)
					_dialogue_goto_state(DialogState.PAUSED)
					_process_next()
				# 如果是停止BGM
				elif cur_dialogue_type == KND_Dialogue.Type.STOP_BGM:
					_audio_interface.stop_bgm()
					_process_next()
				# 如果是播放音效
				elif cur_dialogue_type == KND_Dialogue.Type.PLAY_SOUND_EFFECT:
					var s = _audio_interface.finish_playsoundeffect
					s.connect(_auto_process_next.bind(s))
					var se_name = dialog.soundeffect_name
					_play_soundeffect(se_name)
				# if else分支
				elif cur_dialogue_type == KND_Dialogue.Type.IFELSE_BRANCH:
					print("ifelse分支对话")
					var target_value = dialog.target_value
					var tmp_dialogues: Array[KND_Dialogue] = []
					if get_dialogue_variable(dialog.varname).has("value"):
						if target_value == get_dialogue_variable(dialog.varname).get("value"):
							tmp_dialogues = dialog.if_result_dialogs
						else:
							tmp_dialogues = dialog.else_result_dialogs
						if tmp_dialogues == null || tmp_dialogues.size() <= 0:
							print("未满足条件或else无语句")
							_dialogue_goto_state(DialogState.PAUSED)
							_process_next()
						else:
							var insert_position = cur_index + 1
							for i in range(tmp_dialogues.size()):
								start_dialogue_shot.dialogues.insert(insert_position + i, tmp_dialogues[i])
							await get_tree().process_frame
							
							print("添加了 %d 个ifelse对话" % tmp_dialogues.size())
							print("当前对话总数: " + str(start_dialogue_shot.dialogues.size()))
					else:
						printerr("无法获取变量")
					
					_dialogue_goto_state(DialogState.PAUSED)
					_process_next()
				# 如果是分支对话
				elif cur_dialogue_type == KND_Dialogue.Type.BRANCH:
					print_rich("[color=orange]分支对话[/color]")
					var tag_dialogues: Array[KND_Dialogue] = dialog.branch_dialogue
					var insert_position = cur_index + 1
					for i in range(tag_dialogues.size()):
						# 检查是否已经存在
						if tag_dialogues[i].dialog_type == KND_Dialogue.Type.BRANCH:
							print_rich("[color=red]标签对话中不能包含标签对话[/color]")
							continue
						start_dialogue_shot.dialogues.insert(insert_position + i, tag_dialogues[i])
					await get_tree().process_frame
					
					print("添加了 %d 个标签对话" % tag_dialogues.size())
					print("当前对话总数: " + str(start_dialogue_shot.dialogues.size()))
					
					_dialogue_goto_state(DialogState.PAUSED)
					_process_next()
				# 如果是镜头跳转
				elif cur_dialogue_type == KND_Dialogue.Type.JUMP:
					var load_path = dialog.jump_shot_path
					if load_path:
						var res = load(load_path) as KND_Shot
						print(res.dialogues)
						_dialogue_goto_state(DialogState.OFF)
						cur_index = 0
						set_shot(res)
						_dialogue_goto_state(DialogState.PLAYING)
				# 如果剧终
				elif cur_dialogue_type == KND_Dialogue.Type.THE_END:
					# 停止对话
					stop_dialogue()
					
		# 完成下一个状态
		DialogState.PAUSED:
			if justenter:
				justenter = false
				print_rich("[color=cyan][b]状态：[/b][/color][color=orange]播放完成状态[/color]")
				
		
## 打字完成
func isfinishtyping(wait_voice: bool) -> void:
	_dialogue_goto_state(DialogState.PAUSED)
	# 如果自动播放还要检查配音是否播放完毕
	if autoplay:
		# 如果有配音等待配音播放完成
		if wait_voice:
			await _audio_interface.voice_finish_playing
			# 旁白等待两秒
		else:
			await get_tree().create_timer(autoplayspeed).timeout
		_process_next()
	print("触发打字完成信号")
	
## 处理下一个，绑定到下一个按钮
func _process_next() -> void:
	dialogue_line_end.emit(cur_index)
	print_rich("[color=yellow]判断状态[/color]")
	match dialogueState:
		DialogState.OFF:
			print("对话关闭状态，无需做任何操作")
			return
		DialogState.PLAYING:
			if cur_dialogue_type == KND_Dialogue.Type.ORDINARY_DIALOG:
				_konado_dialogue_box.skip_typing_anim()
			else:
				print("对话播放状态，等待播放完成")
			return
		DialogState.PAUSED:
			_audio_interface.stop_voice()
			print("对话播放完成，开始播放下一个")
			# 如果列表中所有对话播放完成了
			if cur_index + 1 >= start_dialogue_shot.dialogues.size():
				# 切换到对话关闭状态
				_dialogue_goto_state(DialogState.OFF)
			# 如果列表中还有对话没有播放
			else:
				_nextline()
				# 切换到播放状态
				_dialogue_goto_state(DialogState.PLAYING)
			return
	
## 自动下一个，添加信号解绑功能保证只被触发一次
func _auto_process_next(s: Signal) -> void:
	_dialogue_goto_state(DialogState.PAUSED)
	if not s.is_null() and s.is_connected(_auto_process_next):
		s.disconnect(_auto_process_next)
		print("触发自动下一个信号")
	_process_next()
	
## 关闭对话的方法
func stop_dialogue() -> void:
	print_rich("[color=yellow]关闭对话[/color]")
	# 切换到关闭状态
	_dialogue_goto_state(DialogState.OFF)
	_konado_dialogue_box.hide_dialogue_box()
	shot_end.emit()
	
## 对话状态切换的方法
func _dialogue_goto_state(dialogstate: DialogState) -> void:
	# 重置justenter状态
	justenter = true
	# 切换状态到
	dialogueState = dialogstate
	print_rich("[color=yellow]切换状态到: [/color]" + str(dialogueState))

## 增加对话下标，下一句
func _nextline() -> void:
	cur_index += 1
	print("---------------------------------------------")
	# 打印时间 日期+时间
	print("当前时间：" + str(Time.get_time_string_from_system()))
	print("对话下标：" + str(cur_index))
			
## 开始自动播放的方法
func start_autoplay(value: bool):
	autoplay = value
	#if value:
		##_autoPlayButton.set_text("停止播放")
	#else:
		##_autoPlayButton.set_text("自动播放")
	_process_next()
	pass
	
	
## 显示背景的方法
func _display_background(bg_name: String, effect: KND_ActingInterface.BackgroundTransitionEffectsType) -> void:
	if bg_name == null:
		return
	var bg_list = background_list.background_list
	var bg_tex: Texture
	for bg in bg_list:
		if bg.background_name == bg_name:
			bg_tex = bg.background_image
			
	if bg_tex == null:
		printerr("背景图片没有找到")
		return
	_acting_interface.change_background_image(bg_tex, bg_name, effect)
	

## 演员状态切换的方法
func _actor_change_state(chara_id: String, state_id: String):
	var target_chara: KND_Character
	var state_tex: Texture
	for chara in chara_list.characters:
		if chara.chara_name == chara_id:
			target_chara = chara
			for state in chara.chara_status:
				if state.status_name == state_id:
					state_tex = state.status_texture
	_acting_interface.change_actor_state(target_chara.chara_name, state_id, state_tex)

## 从角色列表创建并显示角色
func _display_character(dialogue: KND_Dialogue) -> void:
	var target_chara: KND_Character
	var target_chara_name = dialogue.character_name
	for chara in chara_list.characters:
		if chara.chara_name == target_chara_name:
			target_chara = chara
			break
	
	if target_chara == null:
		print("目标角色为空")
		return
		
	# 读取对话的角色状态图片ID
	var target_states = target_chara.chara_status
	var target_state_name = dialogue.character_state
	var target_state_tex
	for state in target_states:
		if state.status_name == target_state_name:
			target_state_tex = state.status_texture
			break
	# 角色位置
	var pos = dialogue.actor_position
	# 角色缩放
	var a_scale = dialogue.actor_scale
	
	# 角色立绘镜像翻转
	var mirror = dialogue.actor_mirror
	# 创建角色
	_acting_interface.create_new_character(target_chara_name, horizontal_division, vertical_division, pos.x, pos.y, target_state_name, target_state_tex, a_scale, mirror)
		
## 演员退场
func _exit_actor(actor_name: String) -> void:
	_acting_interface.delete_character(actor_name)

## 播放BGM
func _play_bgm(bgm_name: String) -> void:
	if bgm_name.is_empty() || bgm_name == null:
		push_error("播放BGM失败：传入的bgm_name为空字符串或null，请检查调用参数")
		return
		
	if bgm_list == null:
		push_error("播放BGM失败：bgm_list对象未初始化（null），无法查找BGM[%s]" % bgm_name)
		return
	
	if bgm_list.bgms == null:
		push_error("播放BGM失败：bgm_list中未找到bgms数组或数组为null，无法查找BGM[%s]" % bgm_name)
		return
	
	var target_bgm: AudioStream = null
	for index in bgm_list.bgms.size():
		var bgm_data = bgm_list.bgms[index]

		if bgm_data == null:
			push_error("播放BGM失败：bgm_list.bgms数组中索引[%d]位置的BGM数据为空，当前查找的BGM名称：%s" % [index, bgm_name])
			return
			
		if bgm_data.bgm_name == bgm_name:
			target_bgm = bgm_data.bgm
			break
	
	if target_bgm:
		_audio_interface.play_bgm(target_bgm, bgm_name)
	else:
		# 收集所有可用的BGM名称，方便调试
		var available_bgm_names: Array[String] = []
		for bgm_data in bgm_list.bgms:
			available_bgm_names.append(bgm_data.bgm_name)
		
		push_error(
            "播放BGM失败：未找到名称为[%s]的BGM。\n"
			+ "当前bgm_list中可用的BGM列表：%s"
			% [bgm_name, str(available_bgm_names)]
		)

## 播放配音
func _play_voice(voice_name: String) -> void:
	if voice_name == null:
		return
	var target_voice: AudioStream
	if voice_list == null or voice_list.voices == null:
		return # 判空
	for voice in voice_list.voices:
		if voice.voice_name == voice_name:
			target_voice = voice.voice
			break
	_audio_interface.play_voice(target_voice)
	pass

## 播放音效
func _play_soundeffect(se_name: String) -> void:
	if se_name == null:
		return
	var target_soundeffect: AudioStream
	if soundeffect_list == null or soundeffect_list.soundeffects == null:
		return # 判空
	for soundeffect in soundeffect_list.soundeffects:
		if soundeffect.se_name == se_name:
			target_soundeffect = soundeffect.se
			break
	_audio_interface.play_sound_effect(target_soundeffect)
	pass
	
## 选项触发方法
func on_option_triggered(choice: KND_DialogueChoice) -> void:
	_dialogue_goto_state(DialogState.PAUSED)
	_konado_choice_interface._choice_container.hide()
	_jump_tag(choice.jump_tag)
	print("玩家选择按钮： " + str(choice.choice_text))
	
	
## 跳转到对话标签的方法
func _jump_tag(tag: String) -> void:
	print_rich("跳转到标签： " + str(tag))
	if start_dialogue_shot.branches == null || start_dialogue_shot.branches.size() <= 0:
		printerr("该对话没有分支")
		return
	var target_dialogue: KND_Dialogue = start_dialogue_shot.branches[tag]
	if target_dialogue == null:
		print("无法完成跳转，没有这个分支")
		return
	
	start_dialogue_shot.dialogues.insert(cur_index + 1, target_dialogue)
	print("插入标签，对话长度" + str(start_dialogue_shot.dialogues.size()))
	_process_next()
