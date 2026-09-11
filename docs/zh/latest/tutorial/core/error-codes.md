# 错误码对照表

Konado 的每一次失败都有**稳定错误码** `<模块前缀>-<三位序号>`。控制台、失败面板、
`KonadoDialogueManager.pending_runtime_failure` 与 `KonadoErrorRegistry` 共用同一套编号，
「哪一步报错」可一步定位到函数、资源与剧本行。

结构化字段（`KonadoExecutionFailure.to_dictionary()` / `pending_runtime_failure`）：

| 字段 | 含义 |
| --- | --- |
| `code` / `id` | 机器可读主键与稳定编号（如 `stage.actor_id_empty` / `AC-001`） |
| `message` | 人类可读描述 |
| `function` / `owner` | 检出函数与文件：**报错发生在哪一步** |
| `resource_kind` / `resource_id` | 涉及的资源（角色 / 背景 / 音频 / 剧本…） |
| `instruction_key` / `source_path` / `source_line` | 出错指令与剧本位置 |
| `severity` | `error` / `warning` / `info` |

控制台示例：`[AC-001] 显示角色失败：角色 ID 不能为空；于 KonadoStageController.show_actor，`
`actor=，指令=ks:res://sample/demo/demo.ks:12，位置=res://sample/demo/demo.ks:12`。
新增返回值建议统一使用 `KonadoResult`：成功 `{"ok": true, "value": …}`，失败 `KonadoResult.error(code, message, context)`。

可运行示例：`sample/error_gallery/`（11 条样本，覆盖 AC / AU / CA / AH / VA）；
自动断言见 `tests/dialogue/test_error_gallery.gd`。

## 错误码总表

> 本表由 `.github/scripts/check_error_codes.py` 依据 `KonadoErrorRegistry` 生成并校验，
> 请勿手改；新增错误码时先登记注册表，再执行 `--write-docs`。

| ID | 错误码 | 模块 | 级别 | 症状 | 检出位置 |
| --- | --- | --- | --- | --- | --- |
| AC-001 | `stage.actor_id_empty` | 表演与舞台 | 错误 | 创建角色时角色 ID 为空 | `KonadoStageController.show_actor`（addons/konado/runtime/stage/konado_stage_controller.gd） |
| AC-002 | `stage.actor_change_failed` | 表演与舞台 | 错误 | 角色状态切换失败 | `KonadoInstructionExecutor._actor_change`（addons/konado/runtime/dialogue/konado_instruction_executor.gd） |
| AC-003 | `stage.actor_exit_failed` | 表演与舞台 | 错误 | 角色退场失败 | `KonadoInstructionExecutor._actor_exit`（addons/konado/runtime/dialogue/konado_instruction_executor.gd） |
| AC-004 | `stage.actor_motion_empty` | 表演与舞台 | 错误 | 角色动作名为空 | `KonadoStageController.play_actor_motion`（addons/konado/runtime/stage/konado_stage_controller.gd） |
| AC-005 | `stage.actor_motion_failed` | 表演与舞台 | 错误 | 角色动作播放失败 | `KonadoInstructionExecutor._actor_motion`（addons/konado/runtime/dialogue/konado_instruction_executor.gd） |
| AC-006 | `stage.actor_motion_layer_invalid` | 表演与舞台 | 错误 | 角色的动作层场景无效（未继承 KonadoActorMotionLayer） | `KonadoStageController.show_actor`（addons/konado/runtime/stage/konado_stage_controller.gd） |
| AC-007 | `stage.actor_motion_missing` | 表演与舞台 | 错误 | 角色动作层里没有该动作（AnimationPlayer 缺少同名动画） | `KonadoStageController.play_actor_motion`（addons/konado/runtime/stage/konado_stage_controller.gd） |
| AC-008 | `stage.actor_move_failed` | 表演与舞台 | 错误 | 角色移动失败 | `KonadoInstructionExecutor._actor_move`（addons/konado/runtime/dialogue/konado_instruction_executor.gd） |
| AC-009 | `stage.actor_node_missing` | 表演与舞台 | 错误 | 舞台上找不到该角色节点 | `KonadoStageController.remove_actor`（addons/konado/runtime/stage/konado_stage_controller.gd） |
| AC-010 | `stage.actor_node_removed` | 表演与舞台 | 警告 | 旧角色节点已移除，按新建处理 | `KonadoStageController._update_existing_actor`（addons/konado/runtime/stage/konado_stage_controller.gd） |
| AC-011 | `stage.actor_not_found` | 表演与舞台 | 错误 | 角色列表里找不到该角色 | `KonadoDialogueServices._show_actor`（addons/konado/runtime/dialogue/konado_dialogue_services.gd） |
| AC-012 | `stage.actor_not_present` | 表演与舞台 | 错误 | 角色不在舞台上（未先 actor show） | `KonadoInstructionExecutor._actor_change`（addons/konado/runtime/dialogue/konado_instruction_executor.gd） |
| AC-013 | `stage.actor_request_superseded` | 表演与舞台 | 提示 | 角色请求被更新的请求取代（正常竞争，非错误） | `KonadoStageController.show_actor`（addons/konado/runtime/stage/konado_stage_controller.gd） |
| AC-014 | `stage.actor_scene_missing` | 表演与舞台 | 错误 | 角色没有配置角色场景（character_scene） | `KonadoStageController.show_actor`（addons/konado/runtime/stage/konado_stage_controller.gd） |
| AC-015 | `stage.actor_show_failed` | 表演与舞台 | 错误 | 角色创建/显示失败 | `KonadoInstructionExecutor._actor_show`（addons/konado/runtime/dialogue/konado_instruction_executor.gd） |
| AC-016 | `stage.actor_state_invalid` | 表演与舞台 | 错误 | 角色没有该状态（角色场景未实现对应 status） | `KonadoStageController.show_actor`（addons/konado/runtime/stage/konado_stage_controller.gd） |
| AC-017 | `stage.actor_template_failed` | 表演与舞台 | 错误 | 实例化角色场景失败 | `KonadoStageController.show_actor`（addons/konado/runtime/stage/konado_stage_controller.gd） |
| AC-018 | `stage.background_controller_uninitialized` | 表演与舞台 | 错误 | 背景控制器未初始化（缺少视口或容器） | `KonadoBackgroundController.change`（addons/konado/runtime/stage/background/konado_background_controller.gd） |
| AC-019 | `stage.background_failed` | 表演与舞台 | 错误 | 背景切换失败 | `KonadoInstructionExecutor._background`（addons/konado/runtime/dialogue/konado_instruction_executor.gd） |
| AC-020 | `stage.background_not_found` | 表演与舞台 | 错误 | 背景列表里找不到该背景 | `KonadoDialogueServices._display_background`（addons/konado/runtime/dialogue/konado_dialogue_services.gd） |
| AC-021 | `stage.background_scene_missing` | 表演与舞台 | 错误 | 背景没有配置场景（PackedScene） | `KonadoStageController.change_background_scene`（addons/konado/runtime/stage/konado_stage_controller.gd） |
| AC-022 | `stage.background_type_invalid` | 表演与舞台 | 错误 | 背景场景类型无效（未继承 KonadoBackgroundSceneBase） | `KonadoBackgroundController.change`（addons/konado/runtime/stage/background/konado_background_controller.gd） |
| AC-023 | `stage.operation_superseded` | 表演与舞台 | 提示 | 舞台操作被更新的请求取代（正常竞争，非错误） | `KonadoStageOperationTracker.superseded_failure`（addons/konado/runtime/stage/konado_stage_operation_tracker.gd） |
| AH-001 | `achievement.operation_failed` | 成就 | 错误 | 成就指令执行失败 | `KonadoInstructionExecutor._achievement_result`（addons/konado/runtime/dialogue/konado_instruction_executor.gd） |
| AH-002 | `achievement.not_found` | 成就 | 错误 | 成就列表里找不到该成就 | `KonadoAchievementManager._operation_failure`（addons/konado_achievement/runtime/konado_achievement_manager.gd） |
| AH-003 | `achievement.storage_failed` | 成就 | 错误 | 成就存档写入失败 | `KonadoAchievementManager._storage_failure`（addons/konado_achievement/runtime/konado_achievement_manager.gd） |
| AH-004 | `achievement.progress_invalid` | 成就 | 错误 | 计数进度键无效 | `KonadoAchievementManager.try_increment_progress`（addons/konado_achievement/runtime/konado_achievement_manager.gd） |
| AH-005 | `achievement.progress_type_conflict` | 成就 | 错误 | 计数键与已有标志键冲突 | `KonadoAchievementManager.try_increment_progress`（addons/konado_achievement/runtime/konado_achievement_manager.gd） |
| AH-006 | `achievement.flag_invalid` | 成就 | 错误 | 标志键无效 | `KonadoAchievementManager.try_set_flag`（addons/konado_achievement/runtime/konado_achievement_manager.gd） |
| AH-007 | `achievement.flag_type_conflict` | 成就 | 错误 | 标志键与已有计数键冲突 | `KonadoAchievementManager.try_set_flag`（addons/konado_achievement/runtime/konado_achievement_manager.gd） |
| AU-001 | `audio.bgm_failed` | 音频 | 错误 | 背景音乐播放失败 | `KonadoInstructionExecutor._audio_bgm_play`（addons/konado/runtime/dialogue/konado_instruction_executor.gd） |
| AU-002 | `audio.bgm_not_found` | 音频 | 错误 | 背景音乐列表里找不到该曲目 | `KonadoDialogueServices._play_bgm`（addons/konado/runtime/dialogue/konado_dialogue_services.gd） |
| AU-003 | `audio.bgm_stream_missing` | 音频 | 错误 | 背景音乐资源未配置 | `KonadoDialogueServices._play_bgm`（addons/konado/runtime/dialogue/konado_dialogue_services.gd） |
| AU-004 | `audio.list_missing` | 音频 | 错误 | 未配置音频列表 | `KonadoDialogueServices._play_bgm`（addons/konado/runtime/dialogue/konado_dialogue_services.gd） |
| AU-005 | `audio.player_missing` | 音频 | 错误 | 音频播放器未绑定 | `KonadoDialogueServices._play_bgm`（addons/konado/runtime/dialogue/konado_dialogue_services.gd） |
| AU-006 | `audio.sfx_failed` | 音频 | 错误 | 音效播放失败 | `KonadoInstructionExecutor._audio_sfx_play`（addons/konado/runtime/dialogue/konado_instruction_executor.gd） |
| AU-007 | `audio.sfx_not_found` | 音频 | 错误 | 音效列表里找不到该音效 | `KonadoDialogueServices._play_sound_effect`（addons/konado/runtime/dialogue/konado_dialogue_services.gd） |
| AU-008 | `audio.sfx_stream_missing` | 音频 | 错误 | 音效资源未配置 | `KonadoDialogueServices._play_sound_effect`（addons/konado/runtime/dialogue/konado_dialogue_services.gd） |
| AU-009 | `audio.voice_failed` | 音频 | 错误 | 语音播放失败 | `KonadoDialogueManager._begin_dialogue_instruction`（addons/konado/runtime/dialogue/konado_dialogue_manager.gd） |
| AU-010 | `audio.voice_not_found` | 音频 | 错误 | 语音列表里找不到该语音 | `KonadoDialogueServices._play_voice`（addons/konado/runtime/dialogue/konado_dialogue_services.gd） |
| AU-011 | `audio.voice_stream_missing` | 音频 | 错误 | 语音资源未配置 | `KonadoDialogueServices._play_voice`（addons/konado/runtime/dialogue/konado_dialogue_services.gd） |
| CA-001 | `camera.move_rejected` | 相机 | 错误 | 相机移动被拒绝（机位缺失或时长非法） | `KonadoInstructionExecutor._camera_move_async`（addons/konado/runtime/dialogue/konado_instruction_executor.gd） |
| CA-002 | `camera.reset_rejected` | 相机 | 错误 | 相机复位被拒绝 | `KonadoInstructionExecutor._camera_reset_async`（addons/konado/runtime/dialogue/konado_instruction_executor.gd） |
| CA-003 | `camera.shake_rejected` | 相机 | 错误 | 相机震动被拒绝 | `KonadoInstructionExecutor._camera_shake_async`（addons/konado/runtime/dialogue/konado_instruction_executor.gd） |
| CA-004 | `camera.stop_rejected` | 相机 | 错误 | 相机停止被拒绝（没有待处理的异步运镜） | `KonadoInstructionExecutor._camera_stop_async`（addons/konado/runtime/dialogue/konado_instruction_executor.gd） |
| CP-001 | `compiler.diagnostic` | 编译与链接 | 错误 | 编译器诊断（语法/语义错误） | `KonadoScriptDiagnostics._parse_message`（addons/konado/language/service/konado_script_diagnostics.gd） |
| CP-002 | `link.abi_mismatch` | 编译与链接 | 错误 | 目标剧本 ABI 与当前编译器不一致 | `KonadoScriptProjectLinker.link_additional`（addons/konado/language/compiler/konado_script_project_linker.gd） |
| CP-003 | `link.budget` | 编译与链接 | 错误 | 跨剧本依赖超过上限（4096 个文件） | `KonadoScriptProjectLinker.link_additional`（addons/konado/language/compiler/konado_script_project_linker.gd） |
| CP-004 | `link.compile_failed` | 编译与链接 | 错误 | 依赖的目标剧本无法编译 | `KonadoScriptProjectLinker.link_additional`（addons/konado/language/compiler/konado_script_project_linker.gd） |
| CP-005 | `link.invalid_path` | 编译与链接 | 错误 | 剧本路径不是规范的 res:// 路径 | `KonadoScriptProjectLinker.link_additional`（addons/konado/language/compiler/konado_script_project_linker.gd） |
| CP-006 | `link.missing_script` | 编译与链接 | 错误 | 链接的目标剧本不存在 | `KonadoScriptProjectLinker.link_additional`（addons/konado/language/compiler/konado_script_project_linker.gd） |
| DL-001 | `dialogue.box_missing` | 对话与选项 | 错误 | 未绑定对话框，无法显示台词 | `KonadoInstructionExecutor._dialogue`（addons/konado/runtime/dialogue/konado_instruction_executor.gd） |
| DL-002 | `dialogue.choice_unavailable` | 对话与选项 | 错误 | 没有可用的选项控制器或选项目标 | `KonadoInstructionExecutor._choice`（addons/konado/runtime/dialogue/konado_instruction_executor.gd） |
| DL-003 | `dialogue.speaker_empty` | 对话与选项 | 错误 | 说话人名称解析为空 | `KonadoDialogueServices._actor_speaker_success`（addons/konado/runtime/dialogue/konado_dialogue_services.gd） |
| DL-004 | `dialogue.speaker_invalid` | 对话与选项 | 错误 | 说话人配置无效，台词无法显示 | `KonadoDialogueManager._begin_dialogue_instruction`（addons/konado/runtime/dialogue/konado_dialogue_manager.gd） |
| DL-005 | `dialogue.speaker_kind_invalid` | 对话与选项 | 错误 | 说话人类型（speaker_kind）无效 | `KonadoDialogueServices.resolve_speaker`（addons/konado/runtime/dialogue/konado_dialogue_services.gd） |
| DL-006 | `dialogue.speaker_variable_type_invalid` | 对话与选项 | 错误 | 说话人变量不是字符串或无法解析 | `KonadoDialogueServices._speaker_from_variable`（addons/konado/runtime/dialogue/konado_dialogue_services.gd） |
| RS-001 | `resource.duplicate` | 资源校验 | 错误 | 资源 ID 重复声明 | `KonadoScriptDiagnostics._append_project_diagnostics`（addons/konado/language/service/konado_script_diagnostics.gd） |
| RS-002 | `resource.missing_target` | 资源校验 | 错误 | 资源引用的目标不存在 | `KonadoScriptDiagnostics._append_project_diagnostics`（addons/konado/language/service/konado_script_diagnostics.gd） |
| RS-003 | `resource.unassigned` | 资源校验 | 警告 | 资源未在项目配置里指派 | `KonadoScriptDiagnostics._append_project_diagnostics`（addons/konado/language/service/konado_script_diagnostics.gd） |
| RS-004 | `resource.unknown` | 资源校验 | 错误 | 引用了未声明的资源 | `KonadoScriptDiagnostics._append_project_diagnostics`（addons/konado/language/service/konado_script_diagnostics.gd） |
| RT-001 | `runtime.controller_missing` | 运行时契约 | 错误 | 指令所需的控制器未配置（stage / audio / camera 等） | `KonadoInstructionExecutor._missing_controller`（addons/konado/runtime/dialogue/konado_instruction_executor.gd） |
| RT-002 | `runtime.failed` | 运行时契约 | 错误 | 未归类的运行期失败（兜底码） | `KonadoExecutionFailure._init`（addons/konado/runtime/dialogue/konado_execution_failure.gd） |
| RT-003 | `runtime.host_unavailable` | 运行时契约 | 错误 | 对话管理器已失效（节点已释放） | `KonadoInstructionExecutor.execute`（addons/konado/runtime/dialogue/konado_instruction_executor.gd） |
| RT-004 | `runtime.instruction_failed` | 运行时契约 | 错误 | 指令执行器未提交原子事务或返回通用失败 | `KonadoDialogueManager._pump`（addons/konado/runtime/dialogue/konado_dialogue_manager.gd） |
| RT-005 | `runtime.unsupported_opcode` | 运行时契约 | 错误 | VM 不支持该操作码（指令与运行时版本不匹配） | `KonadoInstructionExecutor.execute`（addons/konado/runtime/dialogue/konado_instruction_executor.gd） |
| SC-001 | `script.jump_entry_missing` | 脚本与跳转 | 错误 | jump 目标没有入口指令 | `KonadoDialogueManager._prepare_transition_target`（addons/konado/runtime/dialogue/konado_dialogue_manager.gd） |
| SC-002 | `script.jump_load_failed` | 脚本与跳转 | 错误 | 无法加载 jump 目标脚本 | `KonadoInstructionExecutor._jump_script`（addons/konado/runtime/dialogue/konado_instruction_executor.gd） |
| SC-003 | `script.jump_program_missing` | 脚本与跳转 | 错误 | jump 目标没有可执行的 Program | `KonadoDialogueManager._prepare_transition_target`（addons/konado/runtime/dialogue/konado_dialogue_manager.gd） |
| SC-004 | `script.jump_transaction_inactive` | 脚本与跳转 | 提示 | jump 事务已失效（被取代，非错误） | `KonadoDialogueManager._transition_to_shot`（addons/konado/runtime/dialogue/konado_dialogue_manager.gd） |
| SC-005 | `script.jump_transaction_superseded` | 脚本与跳转 | 提示 | jump 过程中被新的执行事务取代 | `KonadoDialogueManager._transition_to_shot`（addons/konado/runtime/dialogue/konado_dialogue_manager.gd） |
| SC-006 | `script.jump_transition_failed` | 脚本与跳转 | 错误 | 无法切换到 jump 目标 | `KonadoInstructionExecutor._jump_script`（addons/konado/runtime/dialogue/konado_instruction_executor.gd） |
| SC-007 | `script.jump_vm_transition_failed` | 脚本与跳转 | 错误 | VM 拒绝了 jump 目标程序切换 | `KonadoDialogueManager._transition_to_shot`（addons/konado/runtime/dialogue/konado_dialogue_manager.gd） |
| VA-001 | `variable.condition_failed` | 变量与条件 | 错误 | 条件求值失败 | `KonadoInstructionExecutor._condition`（addons/konado/runtime/dialogue/konado_instruction_executor.gd） |
| VA-002 | `variable.condition_type_mismatch` | 变量与条件 | 错误 | 条件两侧类型不匹配（无法比较） | `KonadoInstructionExecutor._condition_target`（addons/konado/runtime/dialogue/konado_instruction_executor.gd） |
| VA-003 | `variable.not_found` | 变量与条件 | 错误 | 条件引用了未定义的变量 | `KonadoInstructionExecutor._condition_variable`（addons/konado/runtime/dialogue/konado_instruction_executor.gd） |
| VA-004 | `variable.operation_failed` | 变量与条件 | 错误 | 变量运算失败（类型或操作数非法） | `KonadoDialogueServices._apply_temp_operation`（addons/konado/runtime/dialogue/konado_dialogue_services.gd） |
