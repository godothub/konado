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
signal dialogue_line_start(node_id: String)

## 对话结束播放的信号
signal dialogue_line_end(node_id: String)

## 自定义信号
signal custom_signal(content: String)

@export_category("Playback Settings")

## 是否检查对话节点可见，如果不可见不会执行后续初始化和播放操作，同时会订阅hidden信号，在节点隐藏时停止对话
## 建议设置为true
@export var check_visable: bool = true

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

## 对话全局变量存储（%前缀，持久化）
@export var variable_store: KND_VariableStore

## 对话临时变量存储（$前缀，仅脚本内有效，每次镜头重置）
var _temp_variables: Dictionary = {}

@export_category("UI Settings")

## 演员画布横向分块
@export var horizontal_division: int = 5

## 对话界面接口类
@export var _konado_choice_interface: KND_ChoiceInterface

## 对话框
@export var _konado_dialogue_box: KND_DialogueBox

## 背景和角色UI界面接口
@export var _acting_interface: KND_ActingInterface
## 音频接口
@export var _audio_interface: KND_AudioInterface

## 自动播放按钮
@export var _autoPlayButton: Button

## 设置按钮
@export var _settingsButton: Button

## 对话资源ID
var _dialog_data_id: int = 0

var option_triggered: bool = false

## 对话状态（0:关闭，1:播放，2:播放完成下一个）
enum DialogState 
{
	OFF = 0, 
	PLAYING = 1, 
	PAUSED = 2
}

var dialogueState: DialogState

## 当前对话
var cur_dialogue_shot: KND_Shot

## 当前对话节点ID
var cur_node_id: String = ""

## 是否第一进入当前句对话，由于一些方法只需要在首次进入当前行对话时调用一次，而一些方法需要循环调用（如检查打字动画是否完成的方法）
## 因此，需要判断是否第一次进入当前行对话
var justenter: bool

## 当前对话的类型
var cur_dialogue_type: KND_Dialogue.Type

## 获取当前对话节点
func _current_dialogue() -> KND_Dialogue:
	if cur_dialogue_shot == null or cur_node_id.is_empty():
		return null
	return cur_dialogue_shot.find_node(cur_node_id)

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
## 浏览器各种快捷键调试功能，Godot默认会拦截，如果需要在web调试请打开
@export var enable_web_devtool: bool = false

@export_category("System")
## 存档系统
@export var save_system: KND_SaveSystem

## 成就系统单例引用
var achievement_mgr: Node = null

## 设置桥接器
@export var _settings_bridge: KND_SettingsBridge


## 设置变更处理
func _on_setting_changed(category: String, key: String, value: Variant) -> void:
	match category:
		"text":
			match key:
				"text_speed":
					_typing_interval = value
				"auto_delay":
					autoplayspeed = value
				"auto_mode":
					start_autoplay(value)
		"audio":
			# 音频设置变更由 KND_AudioInterface 处理
			pass

func _ready() -> void:
	if check_visable:
		if not self.is_visible_in_tree():
			printerr("对话已隐藏，不做任何操作")
			return
		self.hidden.connect(
			func():
				printerr("对话已隐藏，自动停止")
				stop_dialogue()
				)

		
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
		
	if _autoPlayButton:
		_autoPlayButton.toggled.connect(start_autoplay)
	else:
		push_error("未指定 _autoPlayButton")
		
	# 如果有设置系统
	if _settings_bridge:
		_settings_bridge.setting_changed.connect(
			_on_setting_changed
		)
		if _settingsButton:
			_settingsButton.pressed.connect(
				func():
					_settings_bridge.show_settings_panel()
					)
	
	# 设置存档系统的对话管理器引用
	if save_system:
		save_system.set_dialogue_manager(self)
		
	## 尝试获取成就系统
	achievement_mgr = get_tree().root.get_node_or_null("KND_AchievementManager")
	if achievement_mgr == null:
		print("成就系统不可用")

	if not variable_store:
		variable_store = KND_VariableStore.new()
		print("变量存储自动初始化")
	

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
	else:
		# 如果不为空，复制一份start_dialogue_shot
		cur_dialogue_shot = start_dialogue_shot.duplicate()
	# 将角色表传给acting_interface
	_acting_interface.chara_list = chara_list

	# 初始化各管理器
	_acting_interface.delete_all_actor()
	

	justenter = true
	dialogueState = DialogState.OFF
	_temp_variables.clear()
	if cur_dialogue_shot.start_node_id and not cur_dialogue_shot.start_node_id.is_empty():
		cur_node_id = cur_dialogue_shot.start_node_id
	elif cur_dialogue_shot.dialogues.size() > 0:
		cur_node_id = cur_dialogue_shot.dialogues[0].node_id
	else:
		cur_node_id = ""
	print_rich("[color=yellow]初始化对话 [/color]" + "justenter: " + str(justenter) +
	" 当前节点ID: " + str(cur_node_id) + " 当前状态: " + str(dialogueState))
	print("---------------------------------------------")
	if callback:
		callback.call()

## 设置对话数据的方法
func set_shot(new_shot: KND_Shot) -> void:
	cur_dialogue_shot = new_shot.duplicate()
	_temp_variables.clear()
	if cur_dialogue_shot.start_node_id and not cur_dialogue_shot.start_node_id.is_empty():
		cur_node_id = cur_dialogue_shot.start_node_id
	elif cur_dialogue_shot.dialogues.size() > 0:
		cur_node_id = cur_dialogue_shot.dialogues[0].node_id
	else:
		cur_node_id = ""
	
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
	if variable_store and variable_store.has(key):
		return { "value": variable_store.get_value(key) }
	return {}

## 开始对话的方法
func start_dialogue() -> void:
	if _konado_choice_interface:
		_konado_choice_interface.show()
	if _acting_interface:
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
				if cur_dialogue_shot == null:
					print_rich("[color=red]对话为空[/color]")
					return
				var dialog = _current_dialogue()
				if dialog == null:
					print_rich("[color=red]当前节点为空，节点ID: %s[/color]" % cur_node_id)
					_dialogue_goto_state(DialogState.OFF)
					return
				# 对话类型
				cur_dialogue_type = dialog.dialog_type
				dialogue_line_start.emit(cur_node_id)
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
						content = _interpolate_variables(dialog.dialog_content)
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
					# 检查信号是否已经连接
					if not s.is_connected(_auto_process_next.bind(s)):
						s.connect(_auto_process_next.bind(s))
					_acting_interface.show()
					_display_background(bg_name, bg_effect)
				# 如果是显示演员
				elif cur_dialogue_type == KND_Dialogue.Type.DISPLAY_ACTOR:
					# 显示演员
					var s = _acting_interface.character_created
					# 检查信号是否已经连接
					if not s.is_connected(_auto_process_next.bind(s)):
						s.connect(_auto_process_next.bind(s))
					_acting_interface.show()
					_display_character(dialog)
				# 如果是改变演员状态
				elif cur_dialogue_type == KND_Dialogue.Type.ACTOR_CHANGE_STATE:
					var actor = dialog.change_state_actor
					var target_state = dialog.change_state
					var s = _acting_interface.character_state_changed
					# 检查信号是否已经连接
					if not s.is_connected(_auto_process_next.bind(s)):
						s.connect(_auto_process_next.bind(s))
					_actor_change_state(actor, target_state)
				# 如果是移动演员
				elif cur_dialogue_type == KND_Dialogue.Type.MOVE_ACTOR:
					var actor = dialog.target_move_chara
					var pos = dialog.target_move_pos
					var s = _acting_interface.character_moved
					# 检查信号是否已经连接
					if not s.is_connected(_auto_process_next.bind(s)):
						s.connect(_auto_process_next.bind(s))
					_acting_interface.move_actor(actor, pos.x)
				# 如果是删除演员
				elif cur_dialogue_type == KND_Dialogue.Type.EXIT_ACTOR:
					# 删除演员
					var actor = dialog.exit_actor
					var s = _acting_interface.character_deleted
					# 检查信号是否已经连接
					if not s.is_connected(_auto_process_next.bind(s)):
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
						print_rich("[color=green]显示选项，共 %d 个选项[/color]" % dialog_choices.size())
						for c in dialog_choices:
							print_rich("[color=green]  \"%s\" -> %s[/color]" % [c.choice_text, c.next_id])
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
					_dialogue_goto_state(DialogState.PAUSED)
					_process_next()
				# 如果是播放音效
				elif cur_dialogue_type == KND_Dialogue.Type.PLAY_SOUND_EFFECT:
					#var s = _audio_interface.finish_playsoundeffect
					#s.connect(_auto_process_next.bind(s))
					var se_name = dialog.soundeffect_name
					_play_soundeffect(se_name)
					_dialogue_goto_state(DialogState.PAUSED)
					_process_next()
				# if-else流程控制分支
				elif cur_dialogue_type == KND_Dialogue.Type.IFELSE_BRANCH:
					print("ifelse流程控制分支")
					var condition_met = false
					var current_value: Variant = null

					if dialog.is_persistent:
						if variable_store and variable_store.has(dialog.varname):
							current_value = variable_store.get_value(dialog.varname)
					else:
						if _temp_variables.has(dialog.varname):
							current_value = _temp_variables[dialog.varname]

					if current_value != null:
						match dialog.condition_operator:
							0:
								condition_met = (float(current_value) == float(dialog.target_value))
							1:
								condition_met = (float(current_value) > float(dialog.target_value))
							2:
								condition_met = (float(current_value) < float(dialog.target_value))
							3:
								condition_met = (float(current_value) >= float(dialog.target_value))
							4:
								condition_met = (float(current_value) <= float(dialog.target_value))
							5:
								condition_met = (float(current_value) != float(dialog.target_value))
					else:
						printerr("无法获取变量: " + dialog.varname)

					if condition_met and not dialog.if_next_id.is_empty():
						# 条件成立，跳转到if分支
						cur_node_id = dialog.if_next_id
						_dialogue_goto_state(DialogState.PLAYING)
					elif not condition_met and not dialog.else_next_id.is_empty():
						# 条件不成立，跳转到else分支
						cur_node_id = dialog.else_next_id
						_dialogue_goto_state(DialogState.PLAYING)
					else:
						# 没有对应分支，走主线next_id
						if not dialog.next_id.is_empty():
							cur_node_id = dialog.next_id
							_dialogue_goto_state(DialogState.PLAYING)
						else:
							_dialogue_goto_state(DialogState.OFF)
				# 如果是分支对话
				elif cur_dialogue_type == KND_Dialogue.Type.BRANCH:
					print_rich("[color=orange]分支对话（已弃用）[/color]")
					if not dialog.next_id.is_empty():
						cur_node_id = dialog.next_id
						_dialogue_goto_state(DialogState.PLAYING)
					else:
						_dialogue_goto_state(DialogState.OFF)
				# 如果是镜头跳转
				elif cur_dialogue_type == KND_Dialogue.Type.JUMP:
					var load_path = dialog.jump_shot_path
					if load_path:
						var res = load(load_path) as KND_Shot
						print(res.dialogues)
						_dialogue_goto_state(DialogState.OFF)
						set_shot(res)
						_dialogue_goto_state(DialogState.PLAYING)
				# 如果是分支内跳转
				elif cur_dialogue_type == KND_Dialogue.Type.JUMP_BRANCH:
					if not dialog.next_id.is_empty():
						cur_node_id = dialog.next_id
						_dialogue_goto_state(DialogState.PLAYING)
					else:
						printerr("jump_branch 目标节点为空")
						_dialogue_goto_state(DialogState.OFF)
				# 信号触发
				elif cur_dialogue_type == KND_Dialogue.Type.SIGNAL:
					var content = dialog.custom_signal_name
					custom_signal.emit(content)
					await get_tree().process_frame
					_dialogue_goto_state(DialogState.PAUSED)
					_process_next()
				# 解锁成就
				elif cur_dialogue_type == KND_Dialogue.Type.ACHIEVEMENT_UNLOCK:
					if achievement_mgr:
						achievement_mgr.unlock_achievement(dialog.achievement_id)
					_dialogue_goto_state(DialogState.PAUSED)
					get_tree().process_frame
					_process_next()
				# 更新成就进度
				elif cur_dialogue_type == KND_Dialogue.Type.ACHIEVEMENT_PROGRESS:
					if achievement_mgr:
						achievement_mgr.increment_progress(dialog.achievement_id, dialog.achievement_value)
					_dialogue_goto_state(DialogState.PAUSED)
					get_tree().process_frame
					_process_next()
				# 设置成就标志位
				elif cur_dialogue_type == KND_Dialogue.Type.ACHIEVEMENT_FLAG:
					if achievement_mgr:
						achievement_mgr.set_flag(dialog.achievement_flag_name, dialog.achievement_flag_value)
					_dialogue_goto_state(DialogState.PAUSED)
					get_tree().process_frame
					_process_next()
				# 变量操作
				elif cur_dialogue_type == KND_Dialogue.Type.SET_VARIABLE:
					_handle_variable_operation(dialog)
					_dialogue_goto_state(DialogState.PAUSED)
					_process_next()
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
	if _settings_bridge:
		var auto = _settings_bridge.get_auto_mode()
		await get_tree().create_timer(1).timeout
		start_autoplay(auto)
	# 如果自动播放还要检查配音是否播放完毕
	if autoplay:
		# 如果有配音等待配音播放完成
		if wait_voice:
			await _audio_interface.voice_finish_playing
		else:
			await get_tree().create_timer(autoplayspeed).timeout
		_process_next()
	else:
		# 检查下一句是否是选项，如果是自动下一句
		var nd: KND_Dialogue = cur_dialogue_shot.find_node(_current_dialogue().next_id)
		if nd.dialog_type == KND_Dialogue.Type.SHOW_CHOICE:
			print("选项自动下一个")
			await get_tree().create_timer(0.05).timeout
			_process_next()
		print("触发打字完成信号")
	
## 处理下一个，绑定到下一个按钮
func _process_next() -> void:
	dialogue_line_end.emit(cur_node_id)
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
			# 检查是否还有下一个节点
			var cur: KND_Dialogue = _current_dialogue()
			if cur == null or cur.next_id.is_empty() or cur_dialogue_shot.find_node(cur.next_id) == null:
				# 切换到对话关闭状态
				_dialogue_goto_state(DialogState.OFF)
			else:
				_goto_next_node()
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
	_acting_interface.delete_all_actor()
	_acting_interface.clean_background(KND_ActingInterface.BackgroundTransitionEffectsType.ALPHA_FADE_EFFECT)
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

## 导航到下一个节点
func _goto_next_node() -> void:
	var node := _current_dialogue()
	if node:
		cur_node_id = node.next_id
	print("---------------------------------------------")
	# 打印时间 日期+时间
	print("当前时间：" + str(Time.get_time_string_from_system()))
	print("导航到节点: %s" % cur_node_id)
			
## 开始自动播放的方法
func start_autoplay(value: bool):
	autoplay = value
	if value:
		_autoPlayButton.set_text("停止播放")
	else:
		_autoPlayButton.set_text("自动播放")
	await get_tree().process_frame
	_process_next()
	
	
	
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
	# 创建角色
	_acting_interface.create_new_character(target_chara_name, horizontal_division, pos.x, target_state_name, target_state_tex)
		
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

func _handle_variable_operation(dialog: KND_Dialogue) -> void:
	var operand: Variant = dialog.variable_operand
	if operand is String:
		if (operand as String).is_valid_int():
			operand = (operand as String).to_int()
		elif (operand as String).is_valid_float():
			operand = (operand as String).to_float()
		elif (operand as String).to_lower() == "true":
			operand = true
		elif (operand as String).to_lower() == "false":
			operand = false

	if dialog.is_persistent:
		if not variable_store:
			printerr("持久变量存储未初始化")
			return
		variable_store.apply_operation(dialog.variable_name, dialog.variable_operation, operand)
		print_rich("[color=cyan]持久变量操作: %%%s = %s[/color]" % [dialog.variable_name, str(variable_store.get_value(dialog.variable_name))])
	else:
		_apply_temp_operation(dialog.variable_name, dialog.variable_operation, operand)
		print_rich("[color=magenta]临时变量操作: $%s = %s[/color]" % [dialog.variable_name, str(_temp_variables.get(dialog.variable_name))])

func _apply_temp_operation(name: String, op: int, operand: Variant) -> void:
	match op:
		KND_VariableStore.Operation.SET:
			_temp_variables[name] = operand
		KND_VariableStore.Operation.ADD:
			var current = _temp_variables.get(name, 0)
			if typeof(current) == TYPE_STRING:
				_temp_variables[name] = str(current) + str(operand)
			else:
				_temp_variables[name] = float(current) + float(operand)
		KND_VariableStore.Operation.SUB:
			_temp_variables[name] = float(_temp_variables.get(name, 0)) - float(operand)
		KND_VariableStore.Operation.MUL:
			_temp_variables[name] = float(_temp_variables.get(name, 0)) * float(operand)
		KND_VariableStore.Operation.DIV:
			var divisor = float(operand)
			if divisor == 0.0:
				push_error("临时变量 '$%s' 除法操作除数为零" % name)
				return
			_temp_variables[name] = float(_temp_variables.get(name, 0)) / divisor

## 获取变量字符，比如好感度，角色名称等
func _interpolate_variables(text: String) -> String:
	if text.is_empty():
		return text

	var result = text
	var regex = RegEx.new()
	regex.compile("([%$])(\\w+)")

	var matches = regex.search_all(text)
	var offset = 0

	for match in matches:
		var prefix = match.get_string(1)
		var var_name = match.get_string(2)
		var value: Variant = null

		if prefix == "%":
			if variable_store and variable_store.has(var_name):
				value = variable_store.get_value(var_name)
		elif prefix == "$":
			if _temp_variables.has(var_name):
				value = _temp_variables[var_name]

		if value != null:
			var start = match.get_start() + offset
			var end = match.get_end() + offset
			var replacement = str(value)
			result = result.substr(0, start) + replacement + result.substr(end)
			offset += replacement.length() - match.get_string().length()

	return result

## 选项触发方法
func on_option_triggered(choice: KND_DialogueChoice) -> void:
	_konado_choice_interface._choice_container.hide()
	dialogue_line_end.emit(cur_node_id)
	print_rich("[color=green]玩家选择: \"%s\" -> %s[/color]" % [choice.choice_text, choice.next_id])
	if not choice.next_id.is_empty():
		var target = cur_dialogue_shot.find_node(choice.next_id)
		if target == null:
			printerr("选项目标节点不存在: %s，停止对话" % choice.next_id)
			_dialogue_goto_state(DialogState.OFF)
			return
		cur_node_id = choice.next_id
		_dialogue_goto_state(DialogState.PLAYING)
	else:
		print_rich("[color=yellow]选项没有跳转目标，停止对话[/color]")
		_dialogue_goto_state(DialogState.OFF)

## 保存游戏
func save_game(save_id: int) -> bool:
	if not save_system:
		printerr("存档系统未设置")
		return false
	return save_system.save_game(save_id)

## 加载游戏
func load_game(save_id: int) -> bool:
	if not save_system:
		printerr("存档系统未设置")
		return false
	return save_system.load_game(save_id)

## 删除存档
func delete_save(save_id: int) -> bool:
	if not save_system:
		printerr("存档系统未设置")
		return false
	return save_system.delete_save(save_id)

## 获取存档信息
func get_save_info(save_id: int) -> Dictionary:
	if not save_system:
		printerr("存档系统未设置")
		return {}
	return save_system.get_save_info(save_id)

## 获取所有存档信息
func get_all_save_info() -> Array[Dictionary]:
	if not save_system:
		printerr("存档系统未设置")
		return []
	return save_system.get_all_save_info()

## 设置存档策略
func set_save_strategy(strategy: Dictionary) -> void:
	if save_system:
		save_system.save_strategy = strategy

## 获取存档策略
func get_save_strategy() -> Dictionary:
	if not save_system:
		return {}
	return save_system.save_strategy


func _on_achievement_pressed() -> void:
	if achievement_mgr:
		achievement_mgr.show_panel()
	else:
		printerr("无KND_AchievementManager")
	pass
