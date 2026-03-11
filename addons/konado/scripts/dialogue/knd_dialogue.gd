extends KND_Data
class_name KND_Dialogue

## 源对话文件行号
@export var source_file_line: int = -1

## 对话类型枚举
enum Type {
	ORDINARY_DIALOG,     # 普通对话
	DISPLAY_ACTOR,       # 显示演员
	ACTOR_CHANGE_STATE,  # 演员切换状态
	MOVE_ACTOR,          # 移动角色
	SWITCH_BACKGROUND,   # 切换背景
	EXIT_ACTOR,          # 演员退场
	PLAY_BGM,            # 播放BGM
	STOP_BGM,            # 停止播放BGM
	PLAY_SOUND_EFFECT,   # 播放音效
	SHOW_CHOICE,         # 显示选项
	IFELSE_BRANCH,       # 条件分支
	BRANCH,              # 分支
	JUMP,                # 跳转
	THE_END              # 剧终
}

@export var dialog_type: Type:
	set(v):
		dialog_type = v
		notify_property_list_changed()
		
## 值名称
@export var varname: String

## if else期待的目标值
@export var target_value: int

# 用于标记跳转点
@export var branch_id: String

@export var else_result_dialogs: Array[KND_Dialogue] = []

@export var if_result_dialogs: Array[KND_Dialogue] = []

# 对话内容
@export var branch_dialogue: Array[KND_Dialogue] = []


# 对话人物ID
@export var character_id: String
# 对话内容
@export var dialog_content: String
# 显示的角色

# 创建和显示的角色ID
@export var character_name: String
# 角色图片ID
@export var character_state: String
# 创建角色的位置
@export var actor_position: Vector2
# 角色图片缩放
@export var actor_scale: float
## 演员立绘水平镜像翻转
@export var actor_mirror: bool

# 隐藏的角色
@export var exit_actor: String
# 要切换状态的角色
@export var change_state_actor: String
# 要切换的状态
@export var change_state: String
# 要移动的角色
@export var target_move_chara: String
# 角色要移动的位置
@export var target_move_pos: Vector2
# 选项
@export var choices: Array[KND_DialogueChoice] = []
# BGM
@export var bgm_name: String
# 语音名称
@export var voice_id: String
# 音效名称
@export var soundeffect_name: String
# 对话背景图片
@export var background_image_name: String
# 背景切换特效
@export var background_toggle_effects: KND_ActingInterface.BackgroundTransitionEffectsType

# 目标跳转的镜头
@export var jump_shot_path: String
