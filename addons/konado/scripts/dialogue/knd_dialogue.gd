extends KND_Data
class_name KND_Dialogue

@export var source_file_line: int = -1

enum Type {
	ORDINARY_DIALOG,
	DISPLAY_ACTOR,
	ACTOR_CHANGE_STATE,
	MOVE_ACTOR,
	SWITCH_BACKGROUND,
	EXIT_ACTOR,
	PLAY_BGM,
	STOP_BGM,
	PLAY_SOUND_EFFECT,
	SHOW_CHOICE,
	IFELSE_BRANCH,
	BRANCH,          # Deprecated - 保留枚举值兼容性
	JUMP,
	JUMP_BRANCH,
	SIGNAL,
	ACHIEVEMENT_UNLOCK,
	ACHIEVEMENT_PROGRESS,
	ACHIEVEMENT_FLAG,
	SET_VARIABLE,
	THE_END
}

@export var dialog_type: Type:
	set(v):
		dialog_type = v
		notify_property_list_changed()

## 节点图ID - 每个对话节点的唯一标识
@export var node_id: String = ""
## 下一个节点ID - 指向下一个对话节点
@export var next_id: String = ""

## 条件分支 - 条件为真时跳转的节点ID
@export var if_next_id: String = ""
## 条件分支 - 条件为假时跳转的节点ID
@export var else_next_id: String = ""

## 条件变量名
@export var varname: String
## 条件操作符 (0: ==, 1: >, 2: <, 3: >=, 4: <=)
@export var condition_operator: int = 0
## if else期待的目标值
@export var target_value: int

## 对话人物ID
@export var character_id: String
## 对话内容
@export var dialog_content: String

## 创建和显示的角色ID
@export var character_name: String
## 角色图片ID
@export var character_state: String
## 创建角色的位置
@export var actor_position: Vector2
## 角色图片缩放
@export var actor_scale: float
## 演员立绘水平镜像翻转
@export var actor_mirror: bool

## 隐藏的角色
@export var exit_actor: String
## 要切换状态的角色
@export var change_state_actor: String
## 要切换的状态
@export var change_state: String
## 要移动的角色
@export var target_move_chara: String
## 角色要移动的位置
@export var target_move_pos: Vector2
## 选项
@export var choices: Array[KND_DialogueChoice] = []
## BGM
@export var bgm_name: String
## 语音名称
@export var voice_id: String
## 音效名称
@export var soundeffect_name: String
## 对话背景图片
@export var background_image_name: String
## 背景切换特效
@export var background_toggle_effects: KND_ActingInterface.BackgroundTransitionEffectsType
## 自定义信号
@export var custom_signal_name: String
## 目标跳转的镜头
@export var jump_shot_path: String
## 目标跳转的分支标签
@export var jump_branch_target: String = ""
## 成就ID
@export var achievement_id: String = ""
## 成就进度值
@export var achievement_value: int = 0
## 成就标签
@export var achievement_flag_name: String = ""
## 成就标签值
@export var achievement_flag_value: bool = false

## 目标变量名
@export var variable_name: String = ""
## 变量操作类型 (0: SET, 1: ADD, 2: SUB, 3: MUL, 4: DIV)
@export var variable_operation: int = 0
## 变量操作数值（字符串形式存储，运行时解析）
@export var variable_operand: String = ""
## 是否为持久变量（%前缀=true，$前缀=false）
@export var is_persistent: bool = true


func add_choice(text: String, target_id: String) -> void:
	var c := KND_DialogueChoice.new()
	c.choice_text = text
	c.next_id = target_id
	choices.append(c)


func clear_choices() -> void:
	choices.clear()
