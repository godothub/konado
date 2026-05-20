@tool
extends Control
class_name KND_Actor

## Konado对话角色类，用于在对话中显示角色

## 演员进场动画完成信号
signal actor_entered
## 演员退场动画完成信号
signal actor_exited
## 演员移动动画完成信号
signal actor_moved

## 是否使用补间动画，将会在角色移动时显示动画效果
@export var use_tween: bool = true

## 动画时间，为0时则等于禁用动画效果
@export var animation_time: float = 0.2:
	set(value):
		if animation_time != value:
			animation_time = max(value, 0)

@export var texture_rect: TextureRect

## 屏幕横向分块数，不得小于2，将屏幕宽度分为从左到右递增的块，每个块大小相同
@export var h_division: int = 5:
	set(value):
		if h_division != value:
			h_division = clamp(value, 2, 5)
			_on_resized()

## 当前角色横向位置所在区块分割线索引，从0开始，从左到右递增
@export var h_character_position: int = 3:
	set(value):
		if h_character_position != value:
			h_character_position = clamp(value, 0, h_division)
			_on_resized()

func _ready() -> void:
	# 初始化透明度为1（确保初始状态正常）
	if texture_rect:
		texture_rect.modulate.a = 1.0
		texture_rect.visible = true
	# 初始化位置
	_on_resized()

func _on_resized() -> void:
	if not texture_rect:
		print("警告：texture_rect未赋值")
		return
	
	if use_tween:
		var tween: Tween = slot.create_tween()
		tween.set_parallel(true)
		tween.tween_property(slot, "position:x", -size.x / h_division * (h_division - h_character_position ) + slot.size.x/2, animation_time)
		await tween.finished
		actor_moved.emit()
	else:
		slot.position.x = -size.x / h_division * (h_division - h_character_position ) + slot.size.x/2
	
		actor_moved.emit()

## 高亮
func set_highlight(highlight: bool) -> void:
	if highlight:
		texture_rect.set_modulate(Color(1.0, 1.0, 1.0))
	else:
		texture_rect.set_modulate(Color(0.35, 0.35, 0.35, 1.0))
	pass

## 角色进场动画（透明度从0过渡到1）
func enter_actor(play_anim: bool = true) -> void:
	if not texture_rect:
		print("警告：texture_rect未赋值，无法执行进场动画")
		emit_signal("actor_entered")
		return
	
	# 重置基础状态
	texture_rect.visible = true
	texture_rect.modulate.a = 0.0
	
	# 创建补间动画
	var tween: Tween = texture_rect.create_tween()
	# 并行执行多个动画轨道
	tween.set_parallel(true)
	
	# 透明度动画（核心进场效果）
	tween.tween_property(texture_rect, "modulate:a", 1.0, animation_time)
	
	tween.finished.connect(_on_enter_animation_finished)
	tween.play()

## 角色退场动画（透明度从1过渡到0）
func exit_actor(play_anim: bool = true) -> void:
	if not texture_rect:
		print("警告：texture_rect未赋值，无法执行退场动画")
		emit_signal("actor_exited")
		return
	
	# 创建补间动画
	var tween: Tween = texture_rect.create_tween()
	# 透明度淡出动画
	tween.tween_property(texture_rect, "modulate:a", 0.0, animation_time)
	
	# 动画完成后删除节点
	tween.finished.connect(func(): self.queue_free())
	tween.play()

## 进场动画完成回调
func _on_enter_animation_finished() -> void:
	actor_entered.emit()

func set_character_texture(texture: Texture) -> void:
	if not texture_rect:
		return
	if texture == null:
		push_error("正在试图设置一个空角色图像")
	texture_rect.texture = texture
	


@export var slot: Control


			
#@tool
#extends Control
#
#@onready var control: Control = $Slot
#
#@export var division:= 3:
	#set(value):
		#if division != value:
			#division = clamp(value,2,15)
			#_on_resized()
#
#@export var character_position := 2:
	#set(value):
		#if character_position!= value:
			#character_position = clamp(value,0,division)
			#_on_resized()
			#
#
#func _on_resized() -> void:
	#if control:
		#control.position.x = -size.x /division * (division - character_position )+ control.size.x/2
