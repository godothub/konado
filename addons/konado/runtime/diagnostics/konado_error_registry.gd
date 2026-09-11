extends RefCounted
class_name KonadoErrorRegistry

## 全项目统一的错误反馈注册表。
##
## 每个运行期 / 舞台 / 脚本错误都必须登记在 `stage.*`、`audio.*`、`dialogue.*`、`camera.*`、
## `script.*`、`runtime.*`、`achievement.*` 命名空间下，并在这里获得：
##   - 稳定的错误 ID（如 `AC-001`），供文档、工单与玩家反馈使用；
##   - 归属模块与**检出位置**（文件 + 函数），使报错能直接定位到具体函数；
##   - 一句式中英文症状描述。
## `code` 是机器可读主键，`owner`/`function` 是"哪一步报错"的答案。
##
## 对照表：docs/<locale>/latest/tutorial/core/error-codes.md（CI 校验注册表与文档一致）。

const SEVERITY_ERROR := "error"
const SEVERITY_WARNING := "warning"
const SEVERITY_INFO := "info"

## 模块图例：错误 ID 前缀 → 模块中英文名。
const MODULES := {
	"AC": {"zh": "表演与舞台", "en": "Acting and stage"},
	"AU": {"zh": "音频", "en": "Audio"},
	"DL": {"zh": "对话与选项", "en": "Dialogue and choices"},
	"CA": {"zh": "相机", "en": "Camera"},
	"SC": {"zh": "脚本与跳转", "en": "Scripts and jumps"},
	"RT": {"zh": "运行时契约", "en": "Runtime contract"},
	"AH": {"zh": "成就", "en": "Achievements"},
	"VA": {"zh": "变量与条件", "en": "Variables and conditions"},
	"CP": {"zh": "编译与链接", "en": "Compiler and linker"},
	"RS": {"zh": "资源校验", "en": "Resource validation"},
}

const ERRORS := {
	"achievement.operation_failed":
	{
		"id": "AH-001",
		"module": "AH",
		"severity": "error",
		"owner": "addons/konado/runtime/dialogue/konado_instruction_executor.gd",
		"function": "KonadoInstructionExecutor._achievement_result",
		"title_zh": "成就指令执行失败",
		"title_en": "Achievement command failed",
	},
	"audio.bgm_failed":
	{
		"id": "AU-001",
		"module": "AU",
		"severity": "error",
		"owner": "addons/konado/runtime/dialogue/konado_instruction_executor.gd",
		"function": "KonadoInstructionExecutor._audio_bgm_play",
		"title_zh": "背景音乐播放失败",
		"title_en": "BGM playback failed",
	},
	"audio.bgm_not_found":
	{
		"id": "AU-002",
		"module": "AU",
		"severity": "error",
		"owner": "addons/konado/runtime/dialogue/konado_dialogue_services.gd",
		"function": "KonadoDialogueServices._play_bgm",
		"title_zh": "背景音乐列表里找不到该曲目",
		"title_en": "BGM is missing from the BGM list",
	},
	"audio.bgm_stream_missing":
	{
		"id": "AU-003",
		"module": "AU",
		"severity": "error",
		"owner": "addons/konado/runtime/dialogue/konado_dialogue_services.gd",
		"function": "KonadoDialogueServices._play_bgm",
		"title_zh": "背景音乐资源未配置",
		"title_en": "BGM resource is not configured",
	},
	"audio.list_missing":
	{
		"id": "AU-004",
		"module": "AU",
		"severity": "error",
		"owner": "addons/konado/runtime/dialogue/konado_dialogue_services.gd",
		"function": "KonadoDialogueServices._play_bgm",
		"title_zh": "未配置音频列表",
		"title_en": "Audio list is not configured",
	},
	"audio.player_missing":
	{
		"id": "AU-005",
		"module": "AU",
		"severity": "error",
		"owner": "addons/konado/runtime/dialogue/konado_dialogue_services.gd",
		"function": "KonadoDialogueServices._play_bgm",
		"title_zh": "音频播放器未绑定",
		"title_en": "Audio player is not bound",
	},
	"audio.sfx_failed":
	{
		"id": "AU-006",
		"module": "AU",
		"severity": "error",
		"owner": "addons/konado/runtime/dialogue/konado_instruction_executor.gd",
		"function": "KonadoInstructionExecutor._audio_sfx_play",
		"title_zh": "音效播放失败",
		"title_en": "Sound effect playback failed",
	},
	"audio.sfx_not_found":
	{
		"id": "AU-007",
		"module": "AU",
		"severity": "error",
		"owner": "addons/konado/runtime/dialogue/konado_dialogue_services.gd",
		"function": "KonadoDialogueServices._play_sound_effect",
		"title_zh": "音效列表里找不到该音效",
		"title_en": "Sound effect is missing from the list",
	},
	"audio.sfx_stream_missing":
	{
		"id": "AU-008",
		"module": "AU",
		"severity": "error",
		"owner": "addons/konado/runtime/dialogue/konado_dialogue_services.gd",
		"function": "KonadoDialogueServices._play_sound_effect",
		"title_zh": "音效资源未配置",
		"title_en": "Sound effect resource is not configured",
	},
	"audio.voice_failed":
	{
		"id": "AU-009",
		"module": "AU",
		"severity": "error",
		"owner": "addons/konado/runtime/dialogue/konado_dialogue_manager.gd",
		"function": "KonadoDialogueManager._begin_dialogue_instruction",
		"title_zh": "语音播放失败",
		"title_en": "Voice playback failed",
	},
	"audio.voice_not_found":
	{
		"id": "AU-010",
		"module": "AU",
		"severity": "error",
		"owner": "addons/konado/runtime/dialogue/konado_dialogue_services.gd",
		"function": "KonadoDialogueServices._play_voice",
		"title_zh": "语音列表里找不到该语音",
		"title_en": "Voice is missing from the voice list",
	},
	"audio.voice_stream_missing":
	{
		"id": "AU-011",
		"module": "AU",
		"severity": "error",
		"owner": "addons/konado/runtime/dialogue/konado_dialogue_services.gd",
		"function": "KonadoDialogueServices._play_voice",
		"title_zh": "语音资源未配置",
		"title_en": "Voice resource is not configured",
	},
	"camera.move_rejected":
	{
		"id": "CA-001",
		"module": "CA",
		"severity": "error",
		"owner": "addons/konado/runtime/dialogue/konado_instruction_executor.gd",
		"function": "KonadoInstructionExecutor._camera_move_async",
		"title_zh": "相机移动被拒绝（机位缺失或时长非法）",
		"title_en": "Camera move rejected (missing marker or invalid duration)",
	},
	"camera.reset_rejected":
	{
		"id": "CA-002",
		"module": "CA",
		"severity": "error",
		"owner": "addons/konado/runtime/dialogue/konado_instruction_executor.gd",
		"function": "KonadoInstructionExecutor._camera_reset_async",
		"title_zh": "相机复位被拒绝",
		"title_en": "Camera reset rejected",
	},
	"camera.shake_rejected":
	{
		"id": "CA-003",
		"module": "CA",
		"severity": "error",
		"owner": "addons/konado/runtime/dialogue/konado_instruction_executor.gd",
		"function": "KonadoInstructionExecutor._camera_shake_async",
		"title_zh": "相机震动被拒绝",
		"title_en": "Camera shake rejected",
	},
	"camera.stop_rejected":
	{
		"id": "CA-004",
		"module": "CA",
		"severity": "error",
		"owner": "addons/konado/runtime/dialogue/konado_instruction_executor.gd",
		"function": "KonadoInstructionExecutor._camera_stop_async",
		"title_zh": "相机停止被拒绝（没有待处理的异步运镜）",
		"title_en": "Camera stop rejected (no pending async operation)",
	},
	"dialogue.box_missing":
	{
		"id": "DL-001",
		"module": "DL",
		"severity": "error",
		"owner": "addons/konado/runtime/dialogue/konado_instruction_executor.gd",
		"function": "KonadoInstructionExecutor._dialogue",
		"title_zh": "未绑定对话框，无法显示台词",
		"title_en": "No dialogue box is bound, so the line cannot be shown",
	},
	"dialogue.choice_unavailable":
	{
		"id": "DL-002",
		"module": "DL",
		"severity": "error",
		"owner": "addons/konado/runtime/dialogue/konado_instruction_executor.gd",
		"function": "KonadoInstructionExecutor._choice",
		"title_zh": "没有可用的选项控制器或选项目标",
		"title_en": "No usable choice controller or option target",
	},
	"dialogue.speaker_empty":
	{
		"id": "DL-003",
		"module": "DL",
		"severity": "error",
		"owner": "addons/konado/runtime/dialogue/konado_dialogue_services.gd",
		"function": "KonadoDialogueServices._actor_speaker_success",
		"title_zh": "说话人名称解析为空",
		"title_en": "Speaker name resolved to an empty string",
	},
	"dialogue.speaker_invalid":
	{
		"id": "DL-004",
		"module": "DL",
		"severity": "error",
		"owner": "addons/konado/runtime/dialogue/konado_dialogue_manager.gd",
		"function": "KonadoDialogueManager._begin_dialogue_instruction",
		"title_zh": "说话人配置无效，台词无法显示",
		"title_en": "Invalid speaker configuration; the line cannot be shown",
	},
	"dialogue.speaker_kind_invalid":
	{
		"id": "DL-005",
		"module": "DL",
		"severity": "error",
		"owner": "addons/konado/runtime/dialogue/konado_dialogue_services.gd",
		"function": "KonadoDialogueServices.resolve_speaker",
		"title_zh": "说话人类型（speaker_kind）无效",
		"title_en": "Invalid speaker_kind",
	},
	"dialogue.speaker_variable_type_invalid":
	{
		"id": "DL-006",
		"module": "DL",
		"severity": "error",
		"owner": "addons/konado/runtime/dialogue/konado_dialogue_services.gd",
		"function": "KonadoDialogueServices._speaker_from_variable",
		"title_zh": "说话人变量不是字符串或无法解析",
		"title_en": "Speaker variable is not a resolvable string",
	},
	"script.jump_entry_missing":
	{
		"id": "SC-001",
		"module": "SC",
		"severity": "error",
		"owner": "addons/konado/runtime/dialogue/konado_dialogue_manager.gd",
		"function": "KonadoDialogueManager._prepare_transition_target",
		"title_zh": "jump 目标没有入口指令",
		"title_en": "The jump target has no entry instruction",
	},
	"script.jump_load_failed":
	{
		"id": "SC-002",
		"module": "SC",
		"severity": "error",
		"owner": "addons/konado/runtime/dialogue/konado_instruction_executor.gd",
		"function": "KonadoInstructionExecutor._jump_script",
		"title_zh": "无法加载 jump 目标脚本",
		"title_en": "The jump target script cannot be loaded",
	},
	"script.jump_program_missing":
	{
		"id": "SC-003",
		"module": "SC",
		"severity": "error",
		"owner": "addons/konado/runtime/dialogue/konado_dialogue_manager.gd",
		"function": "KonadoDialogueManager._prepare_transition_target",
		"title_zh": "jump 目标没有可执行的 Program",
		"title_en": "The jump target has no executable Program",
	},
	"script.jump_transaction_inactive":
	{
		"id": "SC-004",
		"module": "SC",
		"severity": "info",
		"owner": "addons/konado/runtime/dialogue/konado_dialogue_manager.gd",
		"function": "KonadoDialogueManager._transition_to_shot",
		"title_zh": "jump 事务已失效（被取代，非错误）",
		"title_en": "Jump transaction already inactive (superseded, not an error)",
	},
	"script.jump_transaction_superseded":
	{
		"id": "SC-005",
		"module": "SC",
		"severity": "info",
		"owner": "addons/konado/runtime/dialogue/konado_dialogue_manager.gd",
		"function": "KonadoDialogueManager._transition_to_shot",
		"title_zh": "jump 过程中被新的执行事务取代",
		"title_en": "The jump was superseded by a newer execution transaction",
	},
	"script.jump_transition_failed":
	{
		"id": "SC-006",
		"module": "SC",
		"severity": "error",
		"owner": "addons/konado/runtime/dialogue/konado_instruction_executor.gd",
		"function": "KonadoInstructionExecutor._jump_script",
		"title_zh": "无法切换到 jump 目标",
		"title_en": "Switching to the jump target failed",
	},
	"script.jump_vm_transition_failed":
	{
		"id": "SC-007",
		"module": "SC",
		"severity": "error",
		"owner": "addons/konado/runtime/dialogue/konado_dialogue_manager.gd",
		"function": "KonadoDialogueManager._transition_to_shot",
		"title_zh": "VM 拒绝了 jump 目标程序切换",
		"title_en": "The VM rejected the jump target transition",
	},
	"runtime.controller_missing":
	{
		"id": "RT-001",
		"module": "RT",
		"severity": "error",
		"owner": "addons/konado/runtime/dialogue/konado_instruction_executor.gd",
		"function": "KonadoInstructionExecutor._missing_controller",
		"title_zh": "指令所需的控制器未配置（stage / audio / camera 等）",
		"title_en": "A controller required by the instruction is not configured",
	},
	"runtime.failed":
	{
		"id": "RT-002",
		"module": "RT",
		"severity": "error",
		"owner": "addons/konado/runtime/dialogue/konado_execution_failure.gd",
		"function": "KonadoExecutionFailure._init",
		"title_zh": "未归类的运行期失败（兜底码）",
		"title_en": "Unclassified runtime failure (fallback code)",
	},
	"runtime.host_unavailable":
	{
		"id": "RT-003",
		"module": "RT",
		"severity": "error",
		"owner": "addons/konado/runtime/dialogue/konado_instruction_executor.gd",
		"function": "KonadoInstructionExecutor.execute",
		"title_zh": "对话管理器已失效（节点已释放）",
		"title_en": "The dialogue manager is gone (node freed)",
	},
	"runtime.instruction_failed":
	{
		"id": "RT-004",
		"module": "RT",
		"severity": "error",
		"owner": "addons/konado/runtime/dialogue/konado_dialogue_manager.gd",
		"function": "KonadoDialogueManager._pump",
		"title_zh": "指令执行器未提交原子事务或返回通用失败",
		"title_en": "The executor failed without committing an atomic transaction",
	},
	"runtime.unsupported_opcode":
	{
		"id": "RT-005",
		"module": "RT",
		"severity": "error",
		"owner": "addons/konado/runtime/dialogue/konado_instruction_executor.gd",
		"function": "KonadoInstructionExecutor.execute",
		"title_zh": "VM 不支持该操作码（指令与运行时版本不匹配）",
		"title_en": "The VM does not support this opcode (runtime/instruction version mismatch)",
	},
	"stage.actor_change_failed":
	{
		"id": "AC-002",
		"module": "AC",
		"severity": "error",
		"owner": "addons/konado/runtime/dialogue/konado_instruction_executor.gd",
		"function": "KonadoInstructionExecutor._actor_change",
		"title_zh": "角色状态切换失败",
		"title_en": "Changing the actor state failed",
	},
	"stage.actor_exit_failed":
	{
		"id": "AC-003",
		"module": "AC",
		"severity": "error",
		"owner": "addons/konado/runtime/dialogue/konado_instruction_executor.gd",
		"function": "KonadoInstructionExecutor._actor_exit",
		"title_zh": "角色退场失败",
		"title_en": "Actor exit failed",
	},
	"stage.actor_id_empty":
	{
		"id": "AC-001",
		"module": "AC",
		"severity": "error",
		"owner": "addons/konado/runtime/stage/konado_stage_controller.gd",
		"function": "KonadoStageController.show_actor",
		"title_zh": "创建角色时角色 ID 为空",
		"title_en": "Actor id is empty when creating an actor",
	},
	"stage.actor_motion_empty":
	{
		"id": "AC-004",
		"module": "AC",
		"severity": "error",
		"owner": "addons/konado/runtime/stage/konado_stage_controller.gd",
		"function": "KonadoStageController.play_actor_motion",
		"title_zh": "角色动作名为空",
		"title_en": "The actor motion name is empty",
	},
	"stage.actor_motion_failed":
	{
		"id": "AC-005",
		"module": "AC",
		"severity": "error",
		"owner": "addons/konado/runtime/dialogue/konado_instruction_executor.gd",
		"function": "KonadoInstructionExecutor._actor_motion",
		"title_zh": "角色动作播放失败",
		"title_en": "Playing the actor motion failed",
	},
	"stage.actor_motion_layer_invalid":
	{
		"id": "AC-006",
		"module": "AC",
		"severity": "error",
		"owner": "addons/konado/runtime/stage/konado_stage_controller.gd",
		"function": "KonadoStageController.show_actor",
		"title_zh": "角色的动作层场景无效（未继承 KonadoActorMotionLayer）",
		"title_en": "The actor motion layer scene is invalid",
	},
	"stage.actor_motion_missing":
	{
		"id": "AC-007",
		"module": "AC",
		"severity": "error",
		"owner": "addons/konado/runtime/stage/konado_stage_controller.gd",
		"function": "KonadoStageController.play_actor_motion",
		"title_zh": "角色动作层里没有该动作（AnimationPlayer 缺少同名动画）",
		"title_en": "The motion layer has no such animation",
	},
	"stage.actor_move_failed":
	{
		"id": "AC-008",
		"module": "AC",
		"severity": "error",
		"owner": "addons/konado/runtime/dialogue/konado_instruction_executor.gd",
		"function": "KonadoInstructionExecutor._actor_move",
		"title_zh": "角色移动失败",
		"title_en": "Moving the actor failed",
	},
	"stage.actor_node_missing":
	{
		"id": "AC-009",
		"module": "AC",
		"severity": "error",
		"owner": "addons/konado/runtime/stage/konado_stage_controller.gd",
		"function": "KonadoStageController.remove_actor",
		"title_zh": "舞台上找不到该角色节点",
		"title_en": "The actor node is not on stage",
	},
	"stage.actor_node_removed":
	{
		"id": "AC-010",
		"module": "AC",
		"severity": "warning",
		"owner": "addons/konado/runtime/stage/konado_stage_controller.gd",
		"function": "KonadoStageController._update_existing_actor",
		"title_zh": "旧角色节点已移除，按新建处理",
		"title_en": "The previous actor node was removed; treated as a fresh show",
	},
	"stage.actor_not_found":
	{
		"id": "AC-011",
		"module": "AC",
		"severity": "error",
		"owner": "addons/konado/runtime/dialogue/konado_dialogue_services.gd",
		"function": "KonadoDialogueServices._show_actor",
		"title_zh": "角色列表里找不到该角色",
		"title_en": "The actor is missing from the character list",
	},
	"stage.actor_not_present":
	{
		"id": "AC-012",
		"module": "AC",
		"severity": "error",
		"owner": "addons/konado/runtime/dialogue/konado_instruction_executor.gd",
		"function": "KonadoInstructionExecutor._actor_change",
		"title_zh": "角色不在舞台上（未先 actor show）",
		"title_en": "The actor is not on stage (no previous actor show)",
	},
	"stage.actor_request_superseded":
	{
		"id": "AC-013",
		"module": "AC",
		"severity": "info",
		"owner": "addons/konado/runtime/stage/konado_stage_controller.gd",
		"function": "KonadoStageController.show_actor",
		"title_zh": "角色请求被更新的请求取代（正常竞争，非错误）",
		"title_en": "The actor request was superseded by a newer one",
	},
	"stage.actor_scene_missing":
	{
		"id": "AC-014",
		"module": "AC",
		"severity": "error",
		"owner": "addons/konado/runtime/stage/konado_stage_controller.gd",
		"function": "KonadoStageController.show_actor",
		"title_zh": "角色没有配置角色场景（character_scene）",
		"title_en": "The character has no character_scene configured",
	},
	"stage.actor_show_failed":
	{
		"id": "AC-015",
		"module": "AC",
		"severity": "error",
		"owner": "addons/konado/runtime/dialogue/konado_instruction_executor.gd",
		"function": "KonadoInstructionExecutor._actor_show",
		"title_zh": "角色创建/显示失败",
		"title_en": "Creating or showing the actor failed",
	},
	"stage.actor_state_invalid":
	{
		"id": "AC-016",
		"module": "AC",
		"severity": "error",
		"owner": "addons/konado/runtime/stage/konado_stage_controller.gd",
		"function": "KonadoStageController.show_actor",
		"title_zh": "角色没有该状态（角色场景未实现对应 status）",
		"title_en": "The character scene does not provide that state",
	},
	"stage.actor_template_failed":
	{
		"id": "AC-017",
		"module": "AC",
		"severity": "error",
		"owner": "addons/konado/runtime/stage/konado_stage_controller.gd",
		"function": "KonadoStageController.show_actor",
		"title_zh": "实例化角色场景失败",
		"title_en": "Instantiating the character scene failed",
	},
	"stage.background_controller_uninitialized":
	{
		"id": "AC-018",
		"module": "AC",
		"severity": "error",
		"owner": "addons/konado/runtime/stage/background/konado_background_controller.gd",
		"function": "KonadoBackgroundController.change",
		"title_zh": "背景控制器未初始化（缺少视口或容器）",
		"title_en": "The background controller is not initialized",
	},
	"stage.background_failed":
	{
		"id": "AC-019",
		"module": "AC",
		"severity": "error",
		"owner": "addons/konado/runtime/dialogue/konado_instruction_executor.gd",
		"function": "KonadoInstructionExecutor._background",
		"title_zh": "背景切换失败",
		"title_en": "Switching the background failed",
	},
	"stage.background_not_found":
	{
		"id": "AC-020",
		"module": "AC",
		"severity": "error",
		"owner": "addons/konado/runtime/dialogue/konado_dialogue_services.gd",
		"function": "KonadoDialogueServices._display_background",
		"title_zh": "背景列表里找不到该背景",
		"title_en": "The background is missing from the background list",
	},
	"stage.background_scene_missing":
	{
		"id": "AC-021",
		"module": "AC",
		"severity": "error",
		"owner": "addons/konado/runtime/stage/konado_stage_controller.gd",
		"function": "KonadoStageController.change_background_scene",
		"title_zh": "背景没有配置场景（PackedScene）",
		"title_en": "The background has no PackedScene configured",
	},
	"stage.background_type_invalid":
	{
		"id": "AC-022",
		"module": "AC",
		"severity": "error",
		"owner": "addons/konado/runtime/stage/background/konado_background_controller.gd",
		"function": "KonadoBackgroundController.change",
		"title_zh": "背景场景类型无效（未继承 KonadoBackgroundSceneBase）",
		"title_en": "The background scene type is invalid",
	},
	"stage.operation_superseded":
	{
		"id": "AC-023",
		"module": "AC",
		"severity": "info",
		"owner": "addons/konado/runtime/stage/konado_stage_operation_tracker.gd",
		"function": "KonadoStageOperationTracker.superseded_failure",
		"title_zh": "舞台操作被更新的请求取代（正常竞争，非错误）",
		"title_en": "The stage operation was superseded by a newer request",
	},
	"achievement.not_found":
	{
		"id": "AH-002",
		"module": "AH",
		"severity": "error",
		"owner": "addons/konado_achievement/runtime/konado_achievement_manager.gd",
		"function": "KonadoAchievementManager._operation_failure",
		"title_zh": "成就列表里找不到该成就",
		"title_en": "The achievement is missing from the achievement list",
	},
	"achievement.storage_failed":
	{
		"id": "AH-003",
		"module": "AH",
		"severity": "error",
		"owner": "addons/konado_achievement/runtime/konado_achievement_manager.gd",
		"function": "KonadoAchievementManager._storage_failure",
		"title_zh": "成就存档写入失败",
		"title_en": "Writing the achievement save data failed",
	},
	"achievement.progress_invalid":
	{
		"id": "AH-004",
		"module": "AH",
		"severity": "error",
		"owner": "addons/konado_achievement/runtime/konado_achievement_manager.gd",
		"function": "KonadoAchievementManager.try_increment_progress",
		"title_zh": "计数进度键无效",
		"title_en": "Invalid counter progress key",
	},
	"achievement.progress_type_conflict":
	{
		"id": "AH-005",
		"module": "AH",
		"severity": "error",
		"owner": "addons/konado_achievement/runtime/konado_achievement_manager.gd",
		"function": "KonadoAchievementManager.try_increment_progress",
		"title_zh": "计数键与已有标志键冲突",
		"title_en": "Counter key conflicts with an existing flag key",
	},
	"achievement.flag_invalid":
	{
		"id": "AH-006",
		"module": "AH",
		"severity": "error",
		"owner": "addons/konado_achievement/runtime/konado_achievement_manager.gd",
		"function": "KonadoAchievementManager.try_set_flag",
		"title_zh": "标志键无效",
		"title_en": "Invalid flag key",
	},
	"achievement.flag_type_conflict":
	{
		"id": "AH-007",
		"module": "AH",
		"severity": "error",
		"owner": "addons/konado_achievement/runtime/konado_achievement_manager.gd",
		"function": "KonadoAchievementManager.try_set_flag",
		"title_zh": "标志键与已有计数键冲突",
		"title_en": "Flag key conflicts with an existing counter key",
	},
	"variable.condition_failed":
	{
		"id": "VA-001",
		"module": "VA",
		"severity": "error",
		"owner": "addons/konado/runtime/dialogue/konado_instruction_executor.gd",
		"function": "KonadoInstructionExecutor._condition",
		"title_zh": "条件求值失败",
		"title_en": "Evaluating the condition failed",
	},
	"variable.condition_type_mismatch":
	{
		"id": "VA-002",
		"module": "VA",
		"severity": "error",
		"owner": "addons/konado/runtime/dialogue/konado_instruction_executor.gd",
		"function": "KonadoInstructionExecutor._condition_target",
		"title_zh": "条件两侧类型不匹配（无法比较）",
		"title_en": "Condition operand types do not match",
	},
	"variable.not_found":
	{
		"id": "VA-003",
		"module": "VA",
		"severity": "error",
		"owner": "addons/konado/runtime/dialogue/konado_instruction_executor.gd",
		"function": "KonadoInstructionExecutor._condition_variable",
		"title_zh": "条件引用了未定义的变量",
		"title_en": "The condition references an undefined variable",
	},
	"variable.operation_failed":
	{
		"id": "VA-004",
		"module": "VA",
		"severity": "error",
		"owner": "addons/konado/runtime/dialogue/konado_dialogue_services.gd",
		"function": "KonadoDialogueServices._apply_temp_operation",
		"title_zh": "变量运算失败（类型或操作数非法）",
		"title_en": "Variable operation failed (invalid type or operand)",
	},
	"compiler.diagnostic":
	{
		"id": "CP-001",
		"module": "CP",
		"severity": "error",
		"owner": "addons/konado/language/service/konado_script_diagnostics.gd",
		"function": "KonadoScriptDiagnostics._parse_message",
		"title_zh": "编译器诊断（语法/语义错误）",
		"title_en": "Compiler diagnostic (syntax or semantic error)",
	},
	"link.abi_mismatch":
	{
		"id": "CP-002",
		"module": "CP",
		"severity": "error",
		"owner": "addons/konado/language/compiler/konado_script_project_linker.gd",
		"function": "KonadoScriptProjectLinker.link_additional",
		"title_zh": "目标剧本 ABI 与当前编译器不一致",
		"title_en": "Target script ABI does not match the current compiler",
	},
	"link.budget":
	{
		"id": "CP-003",
		"module": "CP",
		"severity": "error",
		"owner": "addons/konado/language/compiler/konado_script_project_linker.gd",
		"function": "KonadoScriptProjectLinker.link_additional",
		"title_zh": "跨剧本依赖超过上限（4096 个文件）",
		"title_en": "Cross-script dependency budget exceeded (4096 files)",
	},
	"link.compile_failed":
	{
		"id": "CP-004",
		"module": "CP",
		"severity": "error",
		"owner": "addons/konado/language/compiler/konado_script_project_linker.gd",
		"function": "KonadoScriptProjectLinker.link_additional",
		"title_zh": "依赖的目标剧本无法编译",
		"title_en": "A linked target script failed to compile",
	},
	"link.invalid_path":
	{
		"id": "CP-005",
		"module": "CP",
		"severity": "error",
		"owner": "addons/konado/language/compiler/konado_script_project_linker.gd",
		"function": "KonadoScriptProjectLinker.link_additional",
		"title_zh": "剧本路径不是规范的 res:// 路径",
		"title_en": "The script path is not a canonical res:// path",
	},
	"link.missing_script":
	{
		"id": "CP-006",
		"module": "CP",
		"severity": "error",
		"owner": "addons/konado/language/compiler/konado_script_project_linker.gd",
		"function": "KonadoScriptProjectLinker.link_additional",
		"title_zh": "链接的目标剧本不存在",
		"title_en": "The linked target script does not exist",
	},
	"resource.duplicate":
	{
		"id": "RS-001",
		"module": "RS",
		"severity": "error",
		"owner": "addons/konado/language/service/konado_script_diagnostics.gd",
		"function": "KonadoScriptDiagnostics._append_project_diagnostics",
		"title_zh": "资源 ID 重复声明",
		"title_en": "Duplicated resource id declaration",
	},
	"resource.missing_target":
	{
		"id": "RS-002",
		"module": "RS",
		"severity": "error",
		"owner": "addons/konado/language/service/konado_script_diagnostics.gd",
		"function": "KonadoScriptDiagnostics._append_project_diagnostics",
		"title_zh": "资源引用的目标不存在",
		"title_en": "The referenced resource target does not exist",
	},
	"resource.unassigned":
	{
		"id": "RS-003",
		"module": "RS",
		"severity": "warning",
		"owner": "addons/konado/language/service/konado_script_diagnostics.gd",
		"function": "KonadoScriptDiagnostics._append_project_diagnostics",
		"title_zh": "资源未在项目配置里指派",
		"title_en": "The resource is not assigned in the project configuration",
	},
	"resource.unknown":
	{
		"id": "RS-004",
		"module": "RS",
		"severity": "error",
		"owner": "addons/konado/language/service/konado_script_diagnostics.gd",
		"function": "KonadoScriptDiagnostics._append_project_diagnostics",
		"title_zh": "引用了未声明的资源",
		"title_en": "Referencing an undeclared resource",
	},
}


## 查询某个错误码的登记信息；未登记时返回空字典。
static func entry(code: StringName) -> Dictionary:
	return ERRORS.get(String(code), {}).duplicate(true)


static func exists(code: StringName) -> bool:
	return ERRORS.has(String(code))


## 稳定错误 ID（如 AC-001）；未登记返回空字符串。
static func id_for(code: StringName) -> String:
	return String(ERRORS.get(String(code), {}).get("id", ""))


## 检出位置：错误编号 + 文件（仓库相对路径）+ 函数符号 + 严重级别。
static func location_for(code: StringName) -> Dictionary:
	var info: Dictionary = ERRORS.get(String(code), {})
	return {
		"id": String(info.get("id", "")),
		"owner": String(info.get("owner", "")),
		"function": String(info.get("function", "")),
		"severity": String(info.get("severity", SEVERITY_ERROR)),
		"module": String(info.get("module", "")),
	}


static func severity_for(code: StringName) -> String:
	return severity_of(entry(code))


static func severity_of(info: Dictionary) -> String:
	return String(info.get("severity", SEVERITY_ERROR))


## 模块中英文名；输入错误 ID 前缀或错误码均可。
static func module_name(module_or_code: String, locale := "zh") -> String:
	var module := module_or_code
	if module.contains("."):
		module = String(entry(module).get("module", module.get_slice(".", 0)))
	var names: Dictionary = MODULES.get(module, {})
	return String(names.get(locale, names.get("en", module)))


static func codes() -> PackedStringArray:
	var result := PackedStringArray()
	for code: String in ERRORS:
		result.append(code)
	result.sort()
	return result


static func entries() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for code: String in codes():
		var info: Dictionary = entry(code)
		info["code"] = code
		result.append(info)
	return result


## 给日志/控制台用的一行摘要：`[AC-001] stage.actor_id_empty 于 KonadoStageController.show_actor → 症状`。
static func describe(code: StringName, locale := "zh") -> String:
	var info := entry(code)
	if info.is_empty():
		return "[UNREGISTERED] %s（未登记到 KonadoErrorRegistry）" % code
	var title := String(info.get("title_%s" % locale, info.get("title_en", "")))
	return "[%s] %s 于 %s → %s" % [info.get("id", ""), code, info.get("function", ""), title]
