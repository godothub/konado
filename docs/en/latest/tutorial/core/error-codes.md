# Error code reference

Every Konado failure carries a **stable error code** `<module>-<three digits>`. The console,
the failure panel, `KonadoDialogueManager.pending_runtime_failure` and `KonadoErrorRegistry`
share the same numbering, so "which step failed" resolves to a function, a resource and a
script line in one step.

Structured fields (`KonadoExecutionFailure.to_dictionary()` / `pending_runtime_failure`):

| Field | Meaning |
| --- | --- |
| `code` / `id` | Machine-readable key and stable id (`stage.actor_id_empty` / `AC-001`) |
| `message` | Human-readable description |
| `function` / `owner` | Detecting function and file: **which step failed** |
| `resource_kind` / `resource_id` | The resource involved (actor / background / audio / script) |
| `instruction_key` / `source_path` / `source_line` | Failing instruction and script position |
| `severity` | `error` / `warning` / `info` |

Console example: `[AC-001] 显示角色失败：角色 ID 不能为空；于 KonadoStageController.show_actor，`
`actor=，指令=ks:res://sample/demo/demo.ks:12，位置=res://sample/demo/demo.ks:12`.
Prefer `KonadoResult` for new return values: `{"ok": true, "value": …}` / `KonadoResult.error(code, message, context)`.

Runnable samples live in `sample/error_gallery/` (11 cases across AC / AU / CA / AH / VA);
the automated check is `tests/dialogue/test_error_gallery.gd`.

## Full table

> Generated and verified from `KonadoErrorRegistry` by `.github/scripts/check_error_codes.py`;
> do not edit by hand. Register a new code first, then run the script with `--write-docs`.

| ID | Code | Module | Severity | Symptom | Detected in |
| --- | --- | --- | --- | --- | --- |
| AC-001 | `stage.actor_id_empty` | Acting and stage | error | Actor id is empty when creating an actor | `KonadoStageController.show_actor`（addons/konado/runtime/stage/konado_stage_controller.gd） |
| AC-002 | `stage.actor_change_failed` | Acting and stage | error | Changing the actor state failed | `KonadoInstructionExecutor._actor_change`（addons/konado/runtime/dialogue/konado_instruction_executor.gd） |
| AC-003 | `stage.actor_exit_failed` | Acting and stage | error | Actor exit failed | `KonadoInstructionExecutor._actor_exit`（addons/konado/runtime/dialogue/konado_instruction_executor.gd） |
| AC-004 | `stage.actor_motion_empty` | Acting and stage | error | The actor motion name is empty | `KonadoStageController.play_actor_motion`（addons/konado/runtime/stage/konado_stage_controller.gd） |
| AC-005 | `stage.actor_motion_failed` | Acting and stage | error | Playing the actor motion failed | `KonadoInstructionExecutor._actor_motion`（addons/konado/runtime/dialogue/konado_instruction_executor.gd） |
| AC-006 | `stage.actor_motion_layer_invalid` | Acting and stage | error | The actor motion layer scene is invalid | `KonadoStageController.show_actor`（addons/konado/runtime/stage/konado_stage_controller.gd） |
| AC-007 | `stage.actor_motion_missing` | Acting and stage | error | The motion layer has no such animation | `KonadoStageController.play_actor_motion`（addons/konado/runtime/stage/konado_stage_controller.gd） |
| AC-008 | `stage.actor_move_failed` | Acting and stage | error | Moving the actor failed | `KonadoInstructionExecutor._actor_move`（addons/konado/runtime/dialogue/konado_instruction_executor.gd） |
| AC-009 | `stage.actor_node_missing` | Acting and stage | error | The actor node is not on stage | `KonadoStageController.remove_actor`（addons/konado/runtime/stage/konado_stage_controller.gd） |
| AC-010 | `stage.actor_node_removed` | Acting and stage | warning | The previous actor node was removed; treated as a fresh show | `KonadoStageController._update_existing_actor`（addons/konado/runtime/stage/konado_stage_controller.gd） |
| AC-011 | `stage.actor_not_found` | Acting and stage | error | The actor is missing from the character list | `KonadoDialogueServices._show_actor`（addons/konado/runtime/dialogue/konado_dialogue_services.gd） |
| AC-012 | `stage.actor_not_present` | Acting and stage | error | The actor is not on stage (no previous actor show) | `KonadoInstructionExecutor._actor_change`（addons/konado/runtime/dialogue/konado_instruction_executor.gd） |
| AC-013 | `stage.actor_request_superseded` | Acting and stage | info | The actor request was superseded by a newer one | `KonadoStageController.show_actor`（addons/konado/runtime/stage/konado_stage_controller.gd） |
| AC-014 | `stage.actor_scene_missing` | Acting and stage | error | The character has no character_scene configured | `KonadoStageController.show_actor`（addons/konado/runtime/stage/konado_stage_controller.gd） |
| AC-015 | `stage.actor_show_failed` | Acting and stage | error | Creating or showing the actor failed | `KonadoInstructionExecutor._actor_show`（addons/konado/runtime/dialogue/konado_instruction_executor.gd） |
| AC-016 | `stage.actor_state_invalid` | Acting and stage | error | The character scene does not provide that state | `KonadoStageController.show_actor`（addons/konado/runtime/stage/konado_stage_controller.gd） |
| AC-017 | `stage.actor_template_failed` | Acting and stage | error | Instantiating the character scene failed | `KonadoStageController.show_actor`（addons/konado/runtime/stage/konado_stage_controller.gd） |
| AC-018 | `stage.background_controller_uninitialized` | Acting and stage | error | The background controller is not initialized | `KonadoBackgroundController.change`（addons/konado/runtime/stage/background/konado_background_controller.gd） |
| AC-019 | `stage.background_failed` | Acting and stage | error | Switching the background failed | `KonadoInstructionExecutor._background`（addons/konado/runtime/dialogue/konado_instruction_executor.gd） |
| AC-020 | `stage.background_not_found` | Acting and stage | error | The background is missing from the background list | `KonadoDialogueServices._display_background`（addons/konado/runtime/dialogue/konado_dialogue_services.gd） |
| AC-021 | `stage.background_scene_missing` | Acting and stage | error | The background has no PackedScene configured | `KonadoStageController.change_background_scene`（addons/konado/runtime/stage/konado_stage_controller.gd） |
| AC-022 | `stage.background_type_invalid` | Acting and stage | error | The background scene type is invalid | `KonadoBackgroundController.change`（addons/konado/runtime/stage/background/konado_background_controller.gd） |
| AC-023 | `stage.operation_superseded` | Acting and stage | info | The stage operation was superseded by a newer request | `KonadoStageOperationTracker.superseded_failure`（addons/konado/runtime/stage/konado_stage_operation_tracker.gd） |
| AH-001 | `achievement.operation_failed` | Achievements | error | Achievement command failed | `KonadoInstructionExecutor._achievement_result`（addons/konado/runtime/dialogue/konado_instruction_executor.gd） |
| AH-002 | `achievement.not_found` | Achievements | error | The achievement is missing from the achievement list | `KonadoAchievementManager._operation_failure`（addons/konado_achievement/runtime/konado_achievement_manager.gd） |
| AH-003 | `achievement.storage_failed` | Achievements | error | Writing the achievement save data failed | `KonadoAchievementManager._storage_failure`（addons/konado_achievement/runtime/konado_achievement_manager.gd） |
| AH-004 | `achievement.progress_invalid` | Achievements | error | Invalid counter progress key | `KonadoAchievementManager.try_increment_progress`（addons/konado_achievement/runtime/konado_achievement_manager.gd） |
| AH-005 | `achievement.progress_type_conflict` | Achievements | error | Counter key conflicts with an existing flag key | `KonadoAchievementManager.try_increment_progress`（addons/konado_achievement/runtime/konado_achievement_manager.gd） |
| AH-006 | `achievement.flag_invalid` | Achievements | error | Invalid flag key | `KonadoAchievementManager.try_set_flag`（addons/konado_achievement/runtime/konado_achievement_manager.gd） |
| AH-007 | `achievement.flag_type_conflict` | Achievements | error | Flag key conflicts with an existing counter key | `KonadoAchievementManager.try_set_flag`（addons/konado_achievement/runtime/konado_achievement_manager.gd） |
| AU-001 | `audio.bgm_failed` | Audio | error | BGM playback failed | `KonadoInstructionExecutor._audio_bgm_play`（addons/konado/runtime/dialogue/konado_instruction_executor.gd） |
| AU-002 | `audio.bgm_not_found` | Audio | error | BGM is missing from the BGM list | `KonadoDialogueServices._play_bgm`（addons/konado/runtime/dialogue/konado_dialogue_services.gd） |
| AU-003 | `audio.bgm_stream_missing` | Audio | error | BGM resource is not configured | `KonadoDialogueServices._play_bgm`（addons/konado/runtime/dialogue/konado_dialogue_services.gd） |
| AU-004 | `audio.list_missing` | Audio | error | Audio list is not configured | `KonadoDialogueServices._play_bgm`（addons/konado/runtime/dialogue/konado_dialogue_services.gd） |
| AU-005 | `audio.player_missing` | Audio | error | Audio player is not bound | `KonadoDialogueServices._play_bgm`（addons/konado/runtime/dialogue/konado_dialogue_services.gd） |
| AU-006 | `audio.sfx_failed` | Audio | error | Sound effect playback failed | `KonadoInstructionExecutor._audio_sfx_play`（addons/konado/runtime/dialogue/konado_instruction_executor.gd） |
| AU-007 | `audio.sfx_not_found` | Audio | error | Sound effect is missing from the list | `KonadoDialogueServices._play_sound_effect`（addons/konado/runtime/dialogue/konado_dialogue_services.gd） |
| AU-008 | `audio.sfx_stream_missing` | Audio | error | Sound effect resource is not configured | `KonadoDialogueServices._play_sound_effect`（addons/konado/runtime/dialogue/konado_dialogue_services.gd） |
| AU-009 | `audio.voice_failed` | Audio | error | Voice playback failed | `KonadoDialogueManager._begin_dialogue_instruction`（addons/konado/runtime/dialogue/konado_dialogue_manager.gd） |
| AU-010 | `audio.voice_not_found` | Audio | error | Voice is missing from the voice list | `KonadoDialogueServices._play_voice`（addons/konado/runtime/dialogue/konado_dialogue_services.gd） |
| AU-011 | `audio.voice_stream_missing` | Audio | error | Voice resource is not configured | `KonadoDialogueServices._play_voice`（addons/konado/runtime/dialogue/konado_dialogue_services.gd） |
| CA-001 | `camera.move_rejected` | Camera | error | Camera move rejected (missing marker or invalid duration) | `KonadoInstructionExecutor._camera_move_async`（addons/konado/runtime/dialogue/konado_instruction_executor.gd） |
| CA-002 | `camera.reset_rejected` | Camera | error | Camera reset rejected | `KonadoInstructionExecutor._camera_reset_async`（addons/konado/runtime/dialogue/konado_instruction_executor.gd） |
| CA-003 | `camera.shake_rejected` | Camera | error | Camera shake rejected | `KonadoInstructionExecutor._camera_shake_async`（addons/konado/runtime/dialogue/konado_instruction_executor.gd） |
| CA-004 | `camera.stop_rejected` | Camera | error | Camera stop rejected (no pending async operation) | `KonadoInstructionExecutor._camera_stop_async`（addons/konado/runtime/dialogue/konado_instruction_executor.gd） |
| CP-001 | `compiler.diagnostic` | Compiler and linker | error | Compiler diagnostic (syntax or semantic error) | `KonadoScriptDiagnostics._parse_message`（addons/konado/language/service/konado_script_diagnostics.gd） |
| CP-002 | `link.abi_mismatch` | Compiler and linker | error | Target script ABI does not match the current compiler | `KonadoScriptProjectLinker.link_additional`（addons/konado/language/compiler/konado_script_project_linker.gd） |
| CP-003 | `link.budget` | Compiler and linker | error | Cross-script dependency budget exceeded (4096 files) | `KonadoScriptProjectLinker.link_additional`（addons/konado/language/compiler/konado_script_project_linker.gd） |
| CP-004 | `link.compile_failed` | Compiler and linker | error | A linked target script failed to compile | `KonadoScriptProjectLinker.link_additional`（addons/konado/language/compiler/konado_script_project_linker.gd） |
| CP-005 | `link.invalid_path` | Compiler and linker | error | The script path is not a canonical res:// path | `KonadoScriptProjectLinker.link_additional`（addons/konado/language/compiler/konado_script_project_linker.gd） |
| CP-006 | `link.missing_script` | Compiler and linker | error | The linked target script does not exist | `KonadoScriptProjectLinker.link_additional`（addons/konado/language/compiler/konado_script_project_linker.gd） |
| DL-001 | `dialogue.box_missing` | Dialogue and choices | error | No dialogue box is bound, so the line cannot be shown | `KonadoInstructionExecutor._dialogue`（addons/konado/runtime/dialogue/konado_instruction_executor.gd） |
| DL-002 | `dialogue.choice_unavailable` | Dialogue and choices | error | No usable choice controller or option target | `KonadoInstructionExecutor._choice`（addons/konado/runtime/dialogue/konado_instruction_executor.gd） |
| DL-003 | `dialogue.speaker_empty` | Dialogue and choices | error | Speaker name resolved to an empty string | `KonadoDialogueServices._actor_speaker_success`（addons/konado/runtime/dialogue/konado_dialogue_services.gd） |
| DL-004 | `dialogue.speaker_invalid` | Dialogue and choices | error | Invalid speaker configuration; the line cannot be shown | `KonadoDialogueManager._begin_dialogue_instruction`（addons/konado/runtime/dialogue/konado_dialogue_manager.gd） |
| DL-005 | `dialogue.speaker_kind_invalid` | Dialogue and choices | error | Invalid speaker_kind | `KonadoDialogueServices.resolve_speaker`（addons/konado/runtime/dialogue/konado_dialogue_services.gd） |
| DL-006 | `dialogue.speaker_variable_type_invalid` | Dialogue and choices | error | Speaker variable is not a resolvable string | `KonadoDialogueServices._speaker_from_variable`（addons/konado/runtime/dialogue/konado_dialogue_services.gd） |
| RS-001 | `resource.duplicate` | Resource validation | error | Duplicated resource id declaration | `KonadoScriptDiagnostics._append_project_diagnostics`（addons/konado/language/service/konado_script_diagnostics.gd） |
| RS-002 | `resource.missing_target` | Resource validation | error | The referenced resource target does not exist | `KonadoScriptDiagnostics._append_project_diagnostics`（addons/konado/language/service/konado_script_diagnostics.gd） |
| RS-003 | `resource.unassigned` | Resource validation | warning | The resource is not assigned in the project configuration | `KonadoScriptDiagnostics._append_project_diagnostics`（addons/konado/language/service/konado_script_diagnostics.gd） |
| RS-004 | `resource.unknown` | Resource validation | error | Referencing an undeclared resource | `KonadoScriptDiagnostics._append_project_diagnostics`（addons/konado/language/service/konado_script_diagnostics.gd） |
| RT-001 | `runtime.controller_missing` | Runtime contract | error | A controller required by the instruction is not configured | `KonadoInstructionExecutor._missing_controller`（addons/konado/runtime/dialogue/konado_instruction_executor.gd） |
| RT-002 | `runtime.failed` | Runtime contract | error | Unclassified runtime failure (fallback code) | `KonadoExecutionFailure._init`（addons/konado/runtime/dialogue/konado_execution_failure.gd） |
| RT-003 | `runtime.host_unavailable` | Runtime contract | error | The dialogue manager is gone (node freed) | `KonadoInstructionExecutor.execute`（addons/konado/runtime/dialogue/konado_instruction_executor.gd） |
| RT-004 | `runtime.instruction_failed` | Runtime contract | error | The executor failed without committing an atomic transaction | `KonadoDialogueManager._pump`（addons/konado/runtime/dialogue/konado_dialogue_manager.gd） |
| RT-005 | `runtime.unsupported_opcode` | Runtime contract | error | The VM does not support this opcode (runtime/instruction version mismatch) | `KonadoInstructionExecutor.execute`（addons/konado/runtime/dialogue/konado_instruction_executor.gd） |
| SC-001 | `script.jump_entry_missing` | Scripts and jumps | error | The jump target has no entry instruction | `KonadoDialogueManager._prepare_transition_target`（addons/konado/runtime/dialogue/konado_dialogue_manager.gd） |
| SC-002 | `script.jump_load_failed` | Scripts and jumps | error | The jump target script cannot be loaded | `KonadoInstructionExecutor._jump_script`（addons/konado/runtime/dialogue/konado_instruction_executor.gd） |
| SC-003 | `script.jump_program_missing` | Scripts and jumps | error | The jump target has no executable Program | `KonadoDialogueManager._prepare_transition_target`（addons/konado/runtime/dialogue/konado_dialogue_manager.gd） |
| SC-004 | `script.jump_transaction_inactive` | Scripts and jumps | info | Jump transaction already inactive (superseded, not an error) | `KonadoDialogueManager._transition_to_shot`（addons/konado/runtime/dialogue/konado_dialogue_manager.gd） |
| SC-005 | `script.jump_transaction_superseded` | Scripts and jumps | info | The jump was superseded by a newer execution transaction | `KonadoDialogueManager._transition_to_shot`（addons/konado/runtime/dialogue/konado_dialogue_manager.gd） |
| SC-006 | `script.jump_transition_failed` | Scripts and jumps | error | Switching to the jump target failed | `KonadoInstructionExecutor._jump_script`（addons/konado/runtime/dialogue/konado_instruction_executor.gd） |
| SC-007 | `script.jump_vm_transition_failed` | Scripts and jumps | error | The VM rejected the jump target transition | `KonadoDialogueManager._transition_to_shot`（addons/konado/runtime/dialogue/konado_dialogue_manager.gd） |
| VA-001 | `variable.condition_failed` | Variables and conditions | error | Evaluating the condition failed | `KonadoInstructionExecutor._condition`（addons/konado/runtime/dialogue/konado_instruction_executor.gd） |
| VA-002 | `variable.condition_type_mismatch` | Variables and conditions | error | Condition operand types do not match | `KonadoInstructionExecutor._condition_target`（addons/konado/runtime/dialogue/konado_instruction_executor.gd） |
| VA-003 | `variable.not_found` | Variables and conditions | error | The condition references an undefined variable | `KonadoInstructionExecutor._condition_variable`（addons/konado/runtime/dialogue/konado_instruction_executor.gd） |
| VA-004 | `variable.operation_failed` | Variables and conditions | error | Variable operation failed (invalid type or operand) | `KonadoDialogueServices._apply_temp_operation`（addons/konado/runtime/dialogue/konado_dialogue_services.gd） |
