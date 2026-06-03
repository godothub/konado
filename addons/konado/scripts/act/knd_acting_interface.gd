extends Control
class_name KND_ActingInterface

## 表演管理器

## 完成背景切换的信号
signal background_change_finished
## 完成角色创建的信号
signal character_created
## 完成角色删除的信号
signal character_deleted
## 完成角色切换状态的信号
signal character_state_changed
## 完成角色移动的信号
signal character_moved

## 特效种类
enum BackgroundTransitionEffectsType {
	NONE_EFFECT, ## 无效果
	EraseEffect, ## 擦除效果
	BlindsEffect, ## 百叶窗效果
	WaveEffect, ## 波浪效果
	ALPHA_FADE_EFFECT, ## ALPHA淡入淡出
	VORTEX_SWAP_EFFECT, ## 极坐标漩涡效果
	WINDMILL_EFFECT, ## 风车效果
	CYBER_GLITCH_EFFECT ## 电子故障效果
	}
	
## 当前背景
var current_texture: Texture = Texture.new()

## 特效Shader路径
var none_effect_shader: Shader = preload("res://addons/konado/shader/bg_trans_effects/none_effect.gdshader")
var erase_effect_shader: Shader = preload("res://addons/konado/shader/bg_trans_effects/erase_effect.gdshader")
var blinds_effect_shader: Shader = preload("res://addons/konado/shader/bg_trans_effects/blinds_effect.gdshader")
var wave_effect_shader: Shader = preload("res://addons/konado/shader/bg_trans_effects/wave_effect.gdshader")
var alpha_fade_effect_shader: Shader = preload("res://addons/konado/shader/bg_trans_effects/alpha_fade_effect.gdshader")
var vortex_swap_effect_shader: Shader = preload("res://addons/konado/shader/bg_trans_effects/vortex_swap_effect.gdshader")
var windmill_effect_shader: Shader = preload("res://addons/konado/shader/bg_trans_effects/windmill_effect.gdshader")
var cyber_glitch_effect_shader: Shader = preload("res://addons/konado/shader/bg_trans_effects/cyber_glitch_effect.gdshader")

## 演员模板
@onready var _konado_actor_template: PackedScene = preload("res://addons/konado/template/character/character_template.tscn")

## 演员字典
var actor_dict = {}
## 演员节点字典，用于快速访问演员节点
var actor_nodes = {}
## 角色列表
var chara_list: KND_CharacterList
## 背景图片
@onready var _background: ColorRect = $BackgroundLayer
## 角色容器
@onready var _chara_controler: Control = $BackgroundLayer/CharaControl
## 效果层
@onready var _effect_layer: ColorRect = $EffectLayer

# Tween效果动画节点
var effect_tween: Tween
#存档用背景id
var background_id : String

var TRANSITION_CONFIGS: Dictionary = {}


func _ready() -> void:
	# 初始化 ShaderMaterial
	_background.material = ShaderMaterial.new()
	# 初始化配置
	init_transtion_config()
	
	for child in _chara_controler.get_children():
		child.queue_free()
	
## 获取角色节点的方法
func get_chara_node(actor_id: String) -> Node:
	 # 首先从演员节点字典中获取
	if actor_nodes.has(actor_id):
		return actor_nodes[actor_id]
		
	# 如果字典中没有，再通过find_child方法查找
	var chara_node: Node = _chara_controler.find_child(actor_id, true, false)
	if chara_node:
		# 将找到的节点添加到字典中
		actor_nodes[actor_id] = chara_node
		return chara_node
	return null
			
## 初始化背景切换配置
func init_transtion_config() -> void:
	TRANSITION_CONFIGS = {
		BackgroundTransitionEffectsType.NONE_EFFECT: {
			"shader": none_effect_shader,
			"duration": 0.0,
			"progress_target": 0.0,
			"tween_trans": Tween.TRANS_LINEAR
		},
		BackgroundTransitionEffectsType.EraseEffect: {
			"shader": erase_effect_shader,
			"duration": 1.0,
			"progress_target": 1.0,
			"tween_trans": Tween.TRANS_LINEAR
		},
		BackgroundTransitionEffectsType.BlindsEffect: {
			"shader": blinds_effect_shader,
			"duration": 1.0,
			"progress_target": 1.0,
			"tween_trans": Tween.TRANS_LINEAR
		},
		BackgroundTransitionEffectsType.WaveEffect: {
			"shader": wave_effect_shader,
			"duration": 1.0,
			"progress_target": 1.8,
			"tween_trans": Tween.TRANS_LINEAR
		},
		BackgroundTransitionEffectsType.ALPHA_FADE_EFFECT: {
			"shader": alpha_fade_effect_shader,
			"duration": 1.0,
			"progress_target": 1.0,
			"tween_trans": Tween.TRANS_LINEAR
		},
		BackgroundTransitionEffectsType.VORTEX_SWAP_EFFECT: {
			"shader": vortex_swap_effect_shader,
			"duration": 1.0,
			"progress_target": 1.0,
			"tween_trans": Tween.TRANS_LINEAR
		},
		BackgroundTransitionEffectsType.WINDMILL_EFFECT: {
			"shader": windmill_effect_shader,
			"duration": 1.0,
			"progress_target": 1.0,
			"tween_trans": Tween.TRANS_LINEAR
		},
		BackgroundTransitionEffectsType.CYBER_GLITCH_EFFECT: {
			"shader": cyber_glitch_effect_shader,
			"duration": 1.0,
			"progress_target": 1.0,
			"tween_trans": Tween.TRANS_LINEAR
		}
	}

## 清空背景
func clean_background(effects_type: BackgroundTransitionEffectsType) -> void:
	var image = Image.create(256, 256, false, Image.FORMAT_RGBA8)
	image.fill(Color.BLACK)
	var tex = ImageTexture.create_from_image(image)
	if effects_type == BackgroundTransitionEffectsType.NONE_EFFECT:
		_background.material.set_shader(none_effect_shader)
		_background.material.set_shader_parameter("target_texture", tex)
		current_texture = tex
		background_change_finished.emit()
		return
	
	var config = TRANSITION_CONFIGS.get(effects_type, TRANSITION_CONFIGS[BackgroundTransitionEffectsType.NONE_EFFECT])

	_background.material.set("shader", config.shader)
	print(_background.material.get_shader())
	_background.material.set_shader_parameter("progress", 0.0)
	_background.material.set_shader_parameter("current_texture", current_texture)
	_background.material.set_shader_parameter("target_texture", tex)

	# 创建并配置过渡动画
	effect_tween = get_tree().create_tween()
	effect_tween.tween_property(
		_background.material, 
		"shader_parameter/progress", 
		config.progress_target, 
		config.duration
	)
	effect_tween.set_ease(config.tween_trans)
	
	# 动画完成回调
	effect_tween.finished.connect(_on_transition_finished.bind(_background.material, tex))
	effect_tween.play()
	

## 显示背景图片的方法
func change_background_image(tex: Texture, name: String, effects_type: BackgroundTransitionEffectsType) -> void:
	if not tex:
		print_rich("[color=red]切换背景失败，空Texture，请检查资源图片[/color]")
		background_change_finished.emit()
		return

	# 基础状态更新
	background_id = name
	print_rich("[color=cyan]切换背景为: [/color]"+str(name) +" " + "过渡效果: " + str(effects_type))
	
	# 获取当前效果配置
	var config = TRANSITION_CONFIGS.get(effects_type, TRANSITION_CONFIGS[BackgroundTransitionEffectsType.NONE_EFFECT])
	
	# 停止之前的过渡动画
	if effect_tween and not effect_tween.is_valid():
		effect_tween.kill()
		effect_tween = null

	# 无效果处理
	if effects_type == BackgroundTransitionEffectsType.NONE_EFFECT:
		_background.material.set_shader(none_effect_shader)
		_background.material.set_shader_parameter("target_texture", tex)
		current_texture = tex
		background_change_finished.emit()
		return

	_background.material.set("shader", config.shader)
	print(_background.material.get_shader())
	_background.material.set_shader_parameter("progress", 0.0)
	_background.material.set_shader_parameter("current_texture", current_texture)
	_background.material.set_shader_parameter("target_texture", tex)

	# 创建并配置过渡动画
	effect_tween = get_tree().create_tween()
	effect_tween.tween_property(
		_background.material, 
		"shader_parameter/progress", 
		config.progress_target, 
		config.duration
	)
	effect_tween.set_ease(config.tween_trans)
	
	# 动画完成回调
	effect_tween.finished.connect(_on_transition_finished.bind(_background.material, tex))
	effect_tween.play()


## 过渡动画完成统一处理函数
func _on_transition_finished(mat: ShaderMaterial, target_tex: Texture) -> void:
	print("背景过渡动画完成")
	current_texture = target_tex
	mat.set_shader_parameter("current_texture", current_texture)
	
	# 清理tween（避免内存泄漏）
	if effect_tween and effect_tween.is_valid():
		effect_tween.kill()
	effect_tween = null
	
	background_change_finished.emit()
	
	
# 新建角色图片的方法
func create_new_character(chara_id: String, h_division: int, pos_h: int, state: String, tex: Texture) -> void:
	# 检查创建的是否为场景已有角色
	for chara_dict in actor_dict.values():
		if chara_dict["id"] == chara_id:
			print_rich("[color=red]创建新演员：错误，重复的角色[/color]")
			delete_character(chara_dict["id"])
			
	# 角色信息字典结构说明:
	# {
	#     "id": int,        # 角色唯一标识
	#     "division": int,       # X轴坐标
	#     "y": float,       # Y轴坐标
	#     "state": String,   # 当前状态标识
	#     "c_scale": float, # 缩放系数
	#     "mirror": bool    # 是否镜像翻转
	# }

	var chara_dict: Dictionary = {
		"id": chara_id,
		"h_division": h_division,
		"pos": pos_h,
		"state": state
		}
		
	# 添加到角色字典
	actor_dict[chara_dict["id"]] = chara_dict
	var node_name : String = str(chara_dict["id"])
	var temp_node : KND_Actor = _konado_actor_template.instantiate() as KND_Actor
	temp_node.name = node_name
	temp_node.use_tween = false
	temp_node.h_division = h_division
	temp_node.h_character_position = pos_h
	temp_node.set_character_texture(tex)
	# 添加到角色容器
	_chara_controler.add_child(temp_node)
	# 添加到演员节点字典
	actor_nodes[chara_id] = temp_node
	temp_node.use_tween = true
	temp_node.enter_actor(true)
	temp_node.actor_entered.connect(
		func():
			character_created.emit()
			print("新建了演员："+str(chara_id)+" 演员状态："+str(state)))
	# 移动信号
	temp_node.actor_moved.connect(_on_character_moved)


## 切换演员的状态
func change_actor_state(actor_id: String, state_id: String, state_tex: Texture) -> void:
	var chara_node: KND_Actor = get_chara_node(actor_id)
	if chara_node == null:
		var tex_info = state_tex.get_path()
		push_error("切换角色状态失败：角色ID[%s]，目标状态ID[%s]，纹理[%s]，未找到角色节点" % [actor_id, state_id, tex_info])
		character_state_changed.emit()
	else:
		# 修改字典中角色的状态
		actor_dict[actor_id]["state"] = state_id
		chara_node.set_character_texture(state_tex)
		character_state_changed.emit()
		print("切换"+actor_id+"到"+str(state_id)+"状态")


# 高亮角色
func highlight_actor(actor_id: String) -> void:
	if actor_dict.size() <= 0:
		return
	for actor in actor_dict.keys():
		var tmp = get_chara_node(actor)
		if actor_id == actor:
			tmp.set_highlight(true)
		else:
			tmp.set_highlight(false)

#
	#var chara_node: KND_Actor = get_chara_node(actor_id)
	##
	#if chara_node != null:
		##如果剧情角色名字和演员名字不匹配，就pass，防止崩溃
		#var tex_node = chara_node.find_child(actor_id, true, false)
		#if tex_node:
			## 修改字典中角色的状态
			#tex_node.set_modulate(Color(1.0, 1.0, 1.0))
		#pass
	#

# 删除指定角色图片的方法
func delete_character(chara_id: String) -> void:
	# 检查要删除的角色是否在容器和字典中
	for actor in actor_dict.values():
		if actor["id"] == chara_id:
			# 删除容器和字典中的角色
			actor_dict.erase(chara_id)
			# 从演员节点字典中删除
			actor_nodes.erase(chara_id)
			# 通过名称查找索引并删除
			var chara_node: KND_Actor = get_chara_node(chara_id) as KND_Actor
			if chara_node:
				chara_node.tree_exited.connect(func(): character_deleted.emit())
				chara_node.exit_actor(true)
			else:
				print("找不到要删除的演员")
				character_deleted.emit()
				return
				
## 删除所有演员
func delete_all_actor() -> void:
	actor_dict.clear()
	# 清空演员节点字典
	actor_nodes.clear()
	for node in _chara_controler.get_children():
		node.exit_actor(false)
	print("删除所有演员")

## 移动演员的方法
func move_actor(chara_id: String, target_h_division: int):
	print("移动演员")
	print(target_h_division)
	var chara_node: KND_Actor = get_chara_node(chara_id) as KND_Actor
	chara_node.h_character_position = target_h_division

	
func _on_character_moved() -> void:
	print("移动回调")
	character_moved.emit()
	pass
	
