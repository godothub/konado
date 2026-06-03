extends Control
class_name KND_DialogueBox

## 打字机模式枚举
enum TypewriterMode {
	TRADITIONAL = 0,  ## 传统模式
	FADE_IN_TYPEWRITER = 1  ## 淡入打字机模式
}

## Konado对话框模板
## 可以自定义设置画面显示内容、位置、尺寸

## 点击对话框
signal on_dialogue_click 
signal on_button_pressed
signal on_character_name_click

## 打字完成
signal typing_completed

## 对话框显示动画完成
signal on_dialogue_show_completed

## 对话框隐藏动画完成
signal on_dialogue_hide_completed

## 角色对象
@export_group("名字")
@export var character_name: String = "" :
	set(value):
		character_name = value
		update_dialogue()
			
@export var name_size: int = 32              ## 名字字体大小
@export var name_bg: Texture2D              ## 名字标签背景
@export var name_color: Color = Color.WHITE ## 名字颜色

## 对话内容
@export_group("对话文本设置")
@export var dialogue_text: String= "":
	set(value):
		dialogue_text = value
		update_dialogue_content()

@export var dialogue_font_size: int = 24     ## 对话文本字体大小（新增）
## 打字间隔（单字符）
@export var typing_interval: float = 0.4:
	set(value):
		typing_interval = value
		update_dialogue_content()
		
@export_group("打字音效配置")
@export var enable_typing_effect_audio: bool = true
@export var typing_effect_audio: AudioStream
@export var audio_trigger_chance: float = 0.8  ## 音效触发概率(0-1)，1=每次必播，0=不播
@export var min_audio_interval: float = 0.02   ## 音效最小播放间隔（秒），适配滴滴声快速节奏
@export var max_audio_interval: float = 0.08   ## 音效最大播放间隔（秒）
@export var audio_volumn: float = 0.6         ## 音效音量(0-1)

@export_group("对话框设置")
@export var dialogue_margins: int = 100     ## 对话框到底部距离
@export var dialogue_bg: StyleBox          ## 对话框背景
@export var dialogue_color: Color = Color.WHITE ## 对话文字颜色
@export var dialogue_height: int = 200  ## 对话文本框高度

@export_group("按钮")
@export var button_show: bool = false
@export var button_text: String = ""
@export var button_texture: Texture2D

# 动画相关变量
@export_group("过渡动画设置")
@export var fade_duration: float = 0.5      ## 显示/隐藏过渡动画时长
@export var fade_trans_type: Tween.TransitionType = Tween.TRANS_SINE  ## 过渡动画曲线类型
@export var fade_ease_type: Tween.EaseType = Tween.EASE_IN_OUT        ## 过渡动画缓动类型

@export_group("打字机设置")
@export var typewriter_mode: TypewriterMode = TypewriterMode.TRADITIONAL  ## 打字机模式

# 动态音频播放器
@onready var audio_player: AudioStreamPlayer = AudioStreamPlayer.new()
# 音效状态变量 - 记录上一次播放时间、当前随机间隔
var last_audio_play_time: float = 0.0
var current_random_interval: float = 0.0

# 透明度过渡动画Tween
var fade_tween: Tween = null

## 加载节点
@onready var character_name_label: Label = %character_name_label
@onready var dialogue_label: RichTextLabel = %dialogue_label
@onready var progress_bar: TextureProgressBar = %ProgressBar
@onready var dialogue_container: MarginContainer = %dialogue_container
@onready var dialogue_box_bg: Panel = %dialogue_box_bg

# TypewriterText 组件
@export var typewriter_text: KND_TypewriterText

var typing_tween: Tween = null


func _ready() -> void:
	self.modulate.a = 0.0
	apply_dialogue_text_theme_settings()
	update_dialogue_box_height()
	
	if enable_typing_effect_audio:
		# 将音频播放器添加为子节点，自动完成初始化
		add_child(audio_player)
		audio_player.name = "TypingAudioPlayer"
		# 绑定滴滴音效资源
		audio_player.stream = typing_effect_audio
		# 设置音量，关闭自动播放
		audio_player.volume_db = linear_to_db(audio_volumn)
		audio_player.autoplay = false
		# 初始化随机间隔
		current_random_interval = randf_range(min_audio_interval, max_audio_interval)
	
	# 根据打字机模式处理 TypewriterText 组件
	if typewriter_mode == TypewriterMode.FADE_IN_TYPEWRITER:
		create_typewriter_text()
	else:
		# 如果 TypewriterText 组件存在，则隐藏它并显示传统的 dialogue_label
		if typewriter_text != null:
			typewriter_text.hide()
		dialogue_label.show()

## 应用对话文本的主题设置
func apply_dialogue_text_theme_settings() -> void:
	if not is_inside_tree():
		return
	dialogue_label.add_theme_font_size_override("normal_font_size", dialogue_font_size)
	
	# 如果使用 TypewriterText 模式，也应用主题设置
	if typewriter_text != null:
		typewriter_text.font_size = dialogue_font_size
		typewriter_text.font_color = dialogue_color

## 创建 TypewriterText 组件
func create_typewriter_text() -> void:
	# 连接信号
	typewriter_text.typewriter_finished.connect(func():
		typing_completed.emit()
	)
	
	# 隐藏默认的 dialogue_label
	dialogue_label.hide()
	
## 隐藏对话框（带透明度过渡动画）
func hide_dialogue_box() -> void:
	# 停止原有过渡动画，避免动画冲突
	if fade_tween != null and fade_tween.is_running():
		fade_tween.kill()
	
	# 创建新的透明度过渡动画
	fade_tween = get_tree().create_tween()
	fade_tween.set_trans(fade_trans_type)
	fade_tween.set_ease(fade_ease_type)
	
	# 同时过渡三个节点的 modulate:a 从当前值到 0
	fade_tween.tween_property(self, "modulate:a", 0.0, fade_duration)
	if character_name_label:
		fade_tween.tween_property(character_name_label, "modulate:a", 0.0, fade_duration)
	if dialogue_label:
		fade_tween.tween_property(dialogue_label, "modulate:a", 0.0, fade_duration)
	if typewriter_text:
		fade_tween.tween_property(typewriter_text, "modulate:a", 0.0, fade_duration)
	
	# 动画结束后隐藏所有节点并重置透明度
	fade_tween.finished.connect(func():
		self.hide()
		self.modulate.a = 1.0
		
		character_name_label.hide()
		character_name_label.modulate.a = 1.0
		
		dialogue_label.hide()
		dialogue_label.modulate.a = 1.0
		
		# 发射对话框隐藏完成信号
		on_dialogue_hide_completed.emit()
	)
	
## 显示对话框（带透明度过渡动画）
func show_dialogue_box() -> void:
	# 先显示节点并重置透明度
	self.show()
	self.modulate.a = 0.0
	
	# 停止原有过渡动画，避免动画冲突
	if fade_tween != null and fade_tween.is_running():
		fade_tween.kill()
	
	# 创建新的透明度过渡动画
	fade_tween = get_tree().create_tween()
	# 设置动画曲线和缓动类型
	fade_tween.set_trans(fade_trans_type)
	fade_tween.set_ease(fade_ease_type)
	# 过渡modulate的alpha值从0到1
	fade_tween.tween_property(self, "modulate:a", 1.0, fade_duration)
	# 动画结束后发射显示完成信号
	fade_tween.finished.connect(func():
		on_dialogue_show_completed.emit()
	)
	
func update_dialogue():
	if not is_inside_tree():
		return
	update_character_name()
	update_dialogue_content()
	
func update_character_name() -> void:
	if not is_inside_tree():
		return
	character_name_label.text = character_name
	character_name_label.label_settings.font_size = name_size
	character_name_label.label_settings.font_color = name_color
	
func update_dialogue_box_height() -> void:
	# 更改边距
	dialogue_container.add_theme_constant_override("margin_left", dialogue_margins)
	dialogue_container.add_theme_constant_override("margin_right",dialogue_margins)
	dialogue_container.add_theme_constant_override("margin_bottom",dialogue_margins)
	# 如果用户选择了背景
	if dialogue_bg:
		dialogue_box_bg.add_theme_stylebox_override("panel",dialogue_bg)
	# 更改文本高度
	dialogue_label.custom_minimum_size.y = dialogue_height
	
	# 如果使用 TypewriterText 模式，也设置其高度
	if typewriter_text != null:
		typewriter_text.size = Vector2(dialogue_container.size.x, dialogue_height)
	
	
func update_dialogue_content() -> void:
	if not is_inside_tree() or dialogue_text.is_empty():
		return
	
	# 每次更新对话内容时，重新应用主题设置（确保字体大小/颜色生效）
	apply_dialogue_text_theme_settings()
	
	update_dialogue_box_height()
	
	# 重置音效状态 - 重新打字时从头计算间隔
	last_audio_play_time = 0.0
	current_random_interval = randf_range(min_audio_interval, max_audio_interval)
	
	# 根据打字机模式选择不同的更新方式
	if typewriter_mode == TypewriterMode.FADE_IN_TYPEWRITER:
		# 淡入打字机模式
		if typewriter_text == null:
			create_typewriter_text()
		else:
			typewriter_text.set_bbcode(dialogue_text, true)
	else:
		# 传统模式
		dialogue_label.visible_ratio = 0
		dialogue_label.text = dialogue_text  # 恢复原生text赋值，无需BBCode
		await get_tree().process_frame
		
		# 停止原有打字动画
		if typing_tween != null and typing_tween.is_running():
			typing_tween.kill()
		
		# 创建新的打字动画
		typing_tween = get_tree().create_tween()
		typing_tween.finished.connect(func(): 
			typing_completed.emit())
		# 优化：按**字符数**计算总时长
		var total_typing_time = dialogue_text.length() * typing_interval
		typing_tween.tween_property(dialogue_label, "visible_ratio", 1.0, total_typing_time).set_trans(Tween.TRANS_LINEAR)

## 跳过打字机动画
func skip_typing_anim() -> void:
	# 根据打字机模式选择不同的跳过方式
	if typewriter_mode == TypewriterMode.FADE_IN_TYPEWRITER:
		# 淡入打字机模式
		if typewriter_text != null and typewriter_text.is_playing():
			typewriter_text.skip()
			
			if enable_typing_effect_audio and audio_player.is_playing():
				audio_player.stop()
			# 重置音效状态
			last_audio_play_time = 0.0
			current_random_interval = randf_range(min_audio_interval, max_audio_interval)
			typing_completed.emit()
	else:
		# 传统模式
		# 如果打字动画正在运行，则中断并跳过
		if typing_tween != null and typing_tween.is_running():
			# 停止打字动画
			typing_tween.kill()
			# 直接显示完整文本
			dialogue_label.visible_ratio = 1.0
			
			if enable_typing_effect_audio and audio_player.is_playing():
				audio_player.stop()
			# 重置音效状态
			last_audio_play_time = 0.0
			current_random_interval = randf_range(min_audio_interval, max_audio_interval)
			typing_completed.emit()

func _process(delta: float) -> void:
	# 仅当打字动画运行、文本非空时，处理音效逻辑
	var is_typing = false
	if typewriter_mode == TypewriterMode.FADE_IN_TYPEWRITER:
		# 淡入打字机模式
		is_typing = typewriter_text != null and typewriter_text.is_playing() and not dialogue_text.is_empty()
	else:
		# 传统模式
		is_typing = typing_tween and typing_tween.is_running() and not dialogue_text.is_empty()
	
	if not is_typing:
		return
	
	# 获取当前运行时间（秒），用于计算时间间隔
	var current_time = Time.get_unix_time_from_system()
	# 距离上一次播放音效的时间差
	var time_since_last_play = current_time - last_audio_play_time
	
	if enable_typing_effect_audio:
		var should_play = false
		if typewriter_mode == TypewriterMode.FADE_IN_TYPEWRITER:
			# 淡入打字机模式：检查进度
			var progress = typewriter_text.get_progress()
			var total_chars = dialogue_text.length()
			should_play = progress < float(total_chars)
		else:
			# 传统模式：检查 visible_ratio
			should_play = dialogue_label.visible_ratio < 0.98
		
		if time_since_last_play > current_random_interval and randf() < audio_trigger_chance and should_play:
			# 防重叠
			audio_player.stop()
			audio_player.play()
			# 更新上一次播放时间
			last_audio_play_time = current_time
			# 重新生成随机间隔（每次播放后更新，保证间隔不重复）
			current_random_interval = randf_range(min_audio_interval, max_audio_interval)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed():
		on_dialogue_click.emit()
		
func _input(event: InputEvent) -> void:
	# 可以根据需要绑定其他
	if event.is_action_pressed("ui_accept") || event.is_action_pressed("ui_select"):
		on_dialogue_click.emit()

func _on_button_pressed() -> void:
	on_button_pressed.emit()

func _on_character_name_label_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed():
		on_character_name_click.emit()
