# 錯誤碼對照表

Konado 的每一次失敗都有**穩定錯誤碼** `<模組前綴>-<三位序號>`。主控台、失敗面板、
`pending_runtime_failure` 與 `KonadoErrorRegistry` 共用同一套編號，因此「哪一步報錯」
可以一步定位到函式、資源與指令碼行。

主要結構化欄位（完整說明見中文/英文頁面）：`code` / `id`（穩定編號）、`message`、
`function` / `owner`（檢出函式與檔案）、`resource_kind` / `resource_id`、
`instruction_key` / `source_path` / `source_line`（出錯指令與位置）、`severity`。
主控台示例：`[AC-001] 显示角色失败：角色 ID 不能为空；于 KonadoStageController.show_actor，`
`actor=，指令=ks:res://sample/demo/demo.ks:12，位置=res://sample/demo/demo.ks:12`。

可執行範例：`sample/error_gallery/`（11 筆樣本，涵蓋 AC / AU / CA / AH / VA）；
自動斷言見 `tests/dialogue/test_error_gallery.gd`。

## 錯誤碼總表

> 本表由 `.github/scripts/check_error_codes.py` 依 `KonadoErrorRegistry` 產生並校驗，
> 請勿手改；新增錯誤碼時先登記註冊表，再執行 `--write-docs`。

| ID | 錯誤碼 | 模組 | 級別 | 症狀 | 檢出位置 |
| --- | --- | --- | --- | --- | --- |
| AC-001 | `stage.actor_id_empty` | Acting and stage | 錯誤 | Actor id is empty when creating an actor | `KonadoStageController.show_actor`（addons/konado/runtime/stage/konado_stage_controller.gd） |
| AC-002 | `stage.actor_change_failed` | Acting and stage | 錯誤 | Changing the actor state failed | `KonadoInstructionExecutor._actor_change`（addons/konado/runtime/dialogue/konado_instruction_executor.gd） |
| AC-003 | `stage.actor_exit_failed` | Acting and stage | 錯誤 | Actor exit failed | `KonadoInstructionExecutor._actor_exit`（addons/konado/runtime/dialogue/konado_instruction_executor.gd） |
| AC-004 | `stage.actor_motion_empty` | Acting and stage | 錯誤 | The actor motion name is empty | `KonadoStageController.play_actor_motion`（addons/konado/runtime/stage/konado_stage_controller.gd） |
| AC-005 | `stage.actor_motion_failed` | Acting and stage | 錯誤 | Playing the actor motion failed | `KonadoInstructionExecutor._actor_motion`（addons/konado/runtime/dialogue/konado_instruction_executor.gd） |
| AC-006 | `stage.actor_motion_layer_invalid` | Acting and stage | 錯誤 | The actor motion layer scene is invalid | `KonadoStageController.show_actor`（addons/konado/runtime/stage/konado_stage_controller.gd） |
| AC-007 | `stage.actor_motion_missing` | Acting and stage | 錯誤 | The motion layer has no such animation | `KonadoStageController.play_actor_motion`（addons/konado/runtime/stage/konado_stage_controller.gd） |
| AC-008 | `stage.actor_move_failed` | Acting and stage | 錯誤 | Moving the actor failed | `KonadoInstructionExecutor._actor_move`（addons/konado/runtime/dialogue/konado_instruction_executor.gd） |
| AC-009 | `stage.actor_node_missing` | Acting and stage | 錯誤 | The actor node is not on stage | `KonadoStageController.remove_actor`（addons/konado/runtime/stage/konado_stage_controller.gd） |
| AC-010 | `stage.actor_node_removed` | Acting and stage | 警告 | The previous actor node was removed; treated as a fresh show | `KonadoStageController._update_existing_actor`（addons/konado/runtime/stage/konado_stage_controller.gd） |
| AC-011 | `stage.actor_not_found` | Acting and stage | 錯誤 | The actor is missing from the character list | `KonadoDialogueServices._show_actor`（addons/konado/runtime/dialogue/konado_dialogue_services.gd） |
| AC-012 | `stage.actor_not_present` | Acting and stage | 錯誤 | The actor is not on stage (no previous actor show) | `KonadoInstructionExecutor._actor_change`（addons/konado/runtime/dialogue/konado_instruction_executor.gd） |
| AC-013 | `stage.actor_request_superseded` | Acting and stage | 提示 | The actor request was superseded by a newer one | `KonadoStageController.show_actor`（addons/konado/runtime/stage/konado_stage_controller.gd） |
| AC-014 | `stage.actor_scene_missing` | Acting and stage | 錯誤 | The character has no character_scene configured | `KonadoStageController.show_actor`（addons/konado/runtime/stage/konado_stage_controller.gd） |
| AC-015 | `stage.actor_show_failed` | Acting and stage | 錯誤 | Creating or showing the actor failed | `KonadoInstructionExecutor._actor_show`（addons/konado/runtime/dialogue/konado_instruction_executor.gd） |
| AC-016 | `stage.actor_state_invalid` | Acting and stage | 錯誤 | The character scene does not provide that state | `KonadoStageController.show_actor`（addons/konado/runtime/stage/konado_stage_controller.gd） |
| AC-017 | `stage.actor_template_failed` | Acting and stage | 錯誤 | Instantiating the character scene failed | `KonadoStageController.show_actor`（addons/konado/runtime/stage/konado_stage_controller.gd） |
| AC-018 | `stage.background_controller_uninitialized` | Acting and stage | 錯誤 | The background controller is not initialized | `KonadoBackgroundController.change`（addons/konado/runtime/stage/background/konado_background_controller.gd） |
| AC-019 | `stage.background_failed` | Acting and stage | 錯誤 | Switching the background failed | `KonadoInstructionExecutor._background`（addons/konado/runtime/dialogue/konado_instruction_executor.gd） |
| AC-020 | `stage.background_not_found` | Acting and stage | 錯誤 | The background is missing from the background list | `KonadoDialogueServices._display_background`（addons/konado/runtime/dialogue/konado_dialogue_services.gd） |
| AC-021 | `stage.background_scene_missing` | Acting and stage | 錯誤 | The background has no PackedScene configured | `KonadoStageController.change_background_scene`（addons/konado/runtime/stage/konado_stage_controller.gd） |
| AC-022 | `stage.background_type_invalid` | Acting and stage | 錯誤 | The background scene type is invalid | `KonadoBackgroundController.change`（addons/konado/runtime/stage/background/konado_background_controller.gd） |
| AC-023 | `stage.operation_superseded` | Acting and stage | 提示 | The stage operation was superseded by a newer request | `KonadoStageOperationTracker.superseded_failure`（addons/konado/runtime/stage/konado_stage_operation_tracker.gd） |
| AH-001 | `achievement.operation_failed` | Achievements | 錯誤 | Achievement command failed | `KonadoInstructionExecutor._achievement_result`（addons/konado/runtime/dialogue/konado_instruction_executor.gd） |
| AH-002 | `achievement.not_found` | Achievements | 錯誤 | The achievement is missing from the achievement list | `KonadoAchievementManager._operation_failure`（addons/konado_achievement/runtime/konado_achievement_manager.gd） |
| AH-003 | `achievement.storage_failed` | Achievements | 錯誤 | Writing the achievement save data failed | `KonadoAchievementManager._storage_failure`（addons/konado_achievement/runtime/konado_achievement_manager.gd） |
| AH-004 | `achievement.progress_invalid` | Achievements | 錯誤 | Invalid counter progress key | `KonadoAchievementManager.try_increment_progress`（addons/konado_achievement/runtime/konado_achievement_manager.gd） |
| AH-005 | `achievement.progress_type_conflict` | Achievements | 錯誤 | Counter key conflicts with an existing flag key | `KonadoAchievementManager.try_increment_progress`（addons/konado_achievement/runtime/konado_achievement_manager.gd） |
| AH-006 | `achievement.flag_invalid` | Achievements | 錯誤 | Invalid flag key | `KonadoAchievementManager.try_set_flag`（addons/konado_achievement/runtime/konado_achievement_manager.gd） |
| AH-007 | `achievement.flag_type_conflict` | Achievements | 錯誤 | Flag key conflicts with an existing counter key | `KonadoAchievementManager.try_set_flag`（addons/konado_achievement/runtime/konado_achievement_manager.gd） |
| AU-001 | `audio.bgm_failed` | Audio | 錯誤 | BGM playback failed | `KonadoInstructionExecutor._audio_bgm_play`（addons/konado/runtime/dialogue/konado_instruction_executor.gd） |
| AU-002 | `audio.bgm_not_found` | Audio | 錯誤 | BGM is missing from the BGM list | `KonadoDialogueServices._play_bgm`（addons/konado/runtime/dialogue/konado_dialogue_services.gd） |
| AU-003 | `audio.bgm_stream_missing` | Audio | 錯誤 | BGM resource is not configured | `KonadoDialogueServices._play_bgm`（addons/konado/runtime/dialogue/konado_dialogue_services.gd） |
| AU-004 | `audio.list_missing` | Audio | 錯誤 | Audio list is not configured | `KonadoDialogueServices._play_bgm`（addons/konado/runtime/dialogue/konado_dialogue_services.gd） |
| AU-005 | `audio.player_missing` | Audio | 錯誤 | Audio player is not bound | `KonadoDialogueServices._play_bgm`（addons/konado/runtime/dialogue/konado_dialogue_services.gd） |
| AU-006 | `audio.sfx_failed` | Audio | 錯誤 | Sound effect playback failed | `KonadoInstructionExecutor._audio_sfx_play`（addons/konado/runtime/dialogue/konado_instruction_executor.gd） |
| AU-007 | `audio.sfx_not_found` | Audio | 錯誤 | Sound effect is missing from the list | `KonadoDialogueServices._play_sound_effect`（addons/konado/runtime/dialogue/konado_dialogue_services.gd） |
| AU-008 | `audio.sfx_stream_missing` | Audio | 錯誤 | Sound effect resource is not configured | `KonadoDialogueServices._play_sound_effect`（addons/konado/runtime/dialogue/konado_dialogue_services.gd） |
| AU-009 | `audio.voice_failed` | Audio | 錯誤 | Voice playback failed | `KonadoDialogueManager._begin_dialogue_instruction`（addons/konado/runtime/dialogue/konado_dialogue_manager.gd） |
| AU-010 | `audio.voice_not_found` | Audio | 錯誤 | Voice is missing from the voice list | `KonadoDialogueServices._play_voice`（addons/konado/runtime/dialogue/konado_dialogue_services.gd） |
| AU-011 | `audio.voice_stream_missing` | Audio | 錯誤 | Voice resource is not configured | `KonadoDialogueServices._play_voice`（addons/konado/runtime/dialogue/konado_dialogue_services.gd） |
| CA-001 | `camera.move_rejected` | Camera | 錯誤 | Camera move rejected (missing marker or invalid duration) | `KonadoInstructionExecutor._camera_move_async`（addons/konado/runtime/dialogue/konado_instruction_executor.gd） |
| CA-002 | `camera.reset_rejected` | Camera | 錯誤 | Camera reset rejected | `KonadoInstructionExecutor._camera_reset_async`（addons/konado/runtime/dialogue/konado_instruction_executor.gd） |
| CA-003 | `camera.shake_rejected` | Camera | 錯誤 | Camera shake rejected | `KonadoInstructionExecutor._camera_shake_async`（addons/konado/runtime/dialogue/konado_instruction_executor.gd） |
| CA-004 | `camera.stop_rejected` | Camera | 錯誤 | Camera stop rejected (no pending async operation) | `KonadoInstructionExecutor._camera_stop_async`（addons/konado/runtime/dialogue/konado_instruction_executor.gd） |
| CP-001 | `compiler.diagnostic` | Compiler and linker | 錯誤 | Compiler diagnostic (syntax or semantic error) | `KonadoScriptDiagnostics._parse_message`（addons/konado/language/service/konado_script_diagnostics.gd） |
| CP-002 | `link.abi_mismatch` | Compiler and linker | 錯誤 | Target script ABI does not match the current compiler | `KonadoScriptProjectLinker.link_additional`（addons/konado/language/compiler/konado_script_project_linker.gd） |
| CP-003 | `link.budget` | Compiler and linker | 錯誤 | Cross-script dependency budget exceeded (4096 files) | `KonadoScriptProjectLinker.link_additional`（addons/konado/language/compiler/konado_script_project_linker.gd） |
| CP-004 | `link.compile_failed` | Compiler and linker | 錯誤 | A linked target script failed to compile | `KonadoScriptProjectLinker.link_additional`（addons/konado/language/compiler/konado_script_project_linker.gd） |
| CP-005 | `link.invalid_path` | Compiler and linker | 錯誤 | The script path is not a canonical res:// path | `KonadoScriptProjectLinker.link_additional`（addons/konado/language/compiler/konado_script_project_linker.gd） |
| CP-006 | `link.missing_script` | Compiler and linker | 錯誤 | The linked target script does not exist | `KonadoScriptProjectLinker.link_additional`（addons/konado/language/compiler/konado_script_project_linker.gd） |
| DL-001 | `dialogue.box_missing` | Dialogue and choices | 錯誤 | No dialogue box is bound, so the line cannot be shown | `KonadoInstructionExecutor._dialogue`（addons/konado/runtime/dialogue/konado_instruction_executor.gd） |
| DL-002 | `dialogue.choice_unavailable` | Dialogue and choices | 錯誤 | No usable choice controller or option target | `KonadoInstructionExecutor._choice`（addons/konado/runtime/dialogue/konado_instruction_executor.gd） |
| DL-003 | `dialogue.speaker_empty` | Dialogue and choices | 錯誤 | Speaker name resolved to an empty string | `KonadoDialogueServices._actor_speaker_success`（addons/konado/runtime/dialogue/konado_dialogue_services.gd） |
| DL-004 | `dialogue.speaker_invalid` | Dialogue and choices | 錯誤 | Invalid speaker configuration; the line cannot be shown | `KonadoDialogueManager._begin_dialogue_instruction`（addons/konado/runtime/dialogue/konado_dialogue_manager.gd） |
| DL-005 | `dialogue.speaker_kind_invalid` | Dialogue and choices | 錯誤 | Invalid speaker_kind | `KonadoDialogueServices.resolve_speaker`（addons/konado/runtime/dialogue/konado_dialogue_services.gd） |
| DL-006 | `dialogue.speaker_variable_type_invalid` | Dialogue and choices | 錯誤 | Speaker variable is not a resolvable string | `KonadoDialogueServices._speaker_from_variable`（addons/konado/runtime/dialogue/konado_dialogue_services.gd） |
| RS-001 | `resource.duplicate` | Resource validation | 錯誤 | Duplicated resource id declaration | `KonadoScriptDiagnostics._append_project_diagnostics`（addons/konado/language/service/konado_script_diagnostics.gd） |
| RS-002 | `resource.missing_target` | Resource validation | 錯誤 | The referenced resource target does not exist | `KonadoScriptDiagnostics._append_project_diagnostics`（addons/konado/language/service/konado_script_diagnostics.gd） |
| RS-003 | `resource.unassigned` | Resource validation | 警告 | The resource is not assigned in the project configuration | `KonadoScriptDiagnostics._append_project_diagnostics`（addons/konado/language/service/konado_script_diagnostics.gd） |
| RS-004 | `resource.unknown` | Resource validation | 錯誤 | Referencing an undeclared resource | `KonadoScriptDiagnostics._append_project_diagnostics`（addons/konado/language/service/konado_script_diagnostics.gd） |
| RT-001 | `runtime.controller_missing` | Runtime contract | 錯誤 | A controller required by the instruction is not configured | `KonadoInstructionExecutor._missing_controller`（addons/konado/runtime/dialogue/konado_instruction_executor.gd） |
| RT-002 | `runtime.failed` | Runtime contract | 錯誤 | Unclassified runtime failure (fallback code) | `KonadoExecutionFailure._init`（addons/konado/runtime/dialogue/konado_execution_failure.gd） |
| RT-003 | `runtime.host_unavailable` | Runtime contract | 錯誤 | The dialogue manager is gone (node freed) | `KonadoInstructionExecutor.execute`（addons/konado/runtime/dialogue/konado_instruction_executor.gd） |
| RT-004 | `runtime.instruction_failed` | Runtime contract | 錯誤 | The executor failed without committing an atomic transaction | `KonadoDialogueManager._pump`（addons/konado/runtime/dialogue/konado_dialogue_manager.gd） |
| RT-005 | `runtime.unsupported_opcode` | Runtime contract | 錯誤 | The VM does not support this opcode (runtime/instruction version mismatch) | `KonadoInstructionExecutor.execute`（addons/konado/runtime/dialogue/konado_instruction_executor.gd） |
| SC-001 | `script.jump_entry_missing` | Scripts and jumps | 錯誤 | The jump target has no entry instruction | `KonadoDialogueManager._prepare_transition_target`（addons/konado/runtime/dialogue/konado_dialogue_manager.gd） |
| SC-002 | `script.jump_load_failed` | Scripts and jumps | 錯誤 | The jump target script cannot be loaded | `KonadoInstructionExecutor._jump_script`（addons/konado/runtime/dialogue/konado_instruction_executor.gd） |
| SC-003 | `script.jump_program_missing` | Scripts and jumps | 錯誤 | The jump target has no executable Program | `KonadoDialogueManager._prepare_transition_target`（addons/konado/runtime/dialogue/konado_dialogue_manager.gd） |
| SC-004 | `script.jump_transaction_inactive` | Scripts and jumps | 提示 | Jump transaction already inactive (superseded, not an error) | `KonadoDialogueManager._transition_to_shot`（addons/konado/runtime/dialogue/konado_dialogue_manager.gd） |
| SC-005 | `script.jump_transaction_superseded` | Scripts and jumps | 提示 | The jump was superseded by a newer execution transaction | `KonadoDialogueManager._transition_to_shot`（addons/konado/runtime/dialogue/konado_dialogue_manager.gd） |
| SC-006 | `script.jump_transition_failed` | Scripts and jumps | 錯誤 | Switching to the jump target failed | `KonadoInstructionExecutor._jump_script`（addons/konado/runtime/dialogue/konado_instruction_executor.gd） |
| SC-007 | `script.jump_vm_transition_failed` | Scripts and jumps | 錯誤 | The VM rejected the jump target transition | `KonadoDialogueManager._transition_to_shot`（addons/konado/runtime/dialogue/konado_dialogue_manager.gd） |
| VA-001 | `variable.condition_failed` | Variables and conditions | 錯誤 | Evaluating the condition failed | `KonadoInstructionExecutor._condition`（addons/konado/runtime/dialogue/konado_instruction_executor.gd） |
| VA-002 | `variable.condition_type_mismatch` | Variables and conditions | 錯誤 | Condition operand types do not match | `KonadoInstructionExecutor._condition_target`（addons/konado/runtime/dialogue/konado_instruction_executor.gd） |
| VA-003 | `variable.not_found` | Variables and conditions | 錯誤 | The condition references an undefined variable | `KonadoInstructionExecutor._condition_variable`（addons/konado/runtime/dialogue/konado_instruction_executor.gd） |
| VA-004 | `variable.operation_failed` | Variables and conditions | 錯誤 | Variable operation failed (invalid type or operand) | `KonadoDialogueServices._apply_temp_operation`（addons/konado/runtime/dialogue/konado_dialogue_services.gd） |
