extends Control
class_name KonadoDialogueManager

## Konado 2.8 atomic Program runtime

signal shot_start
signal shot_end
signal dialogue_line_start(instruction_id: String)
signal dialogue_line_end(instruction_id: String)
signal custom_signal(content: String)
signal runtime_failed(message: String, instruction_id: String, source_line: int)
signal runtime_failure_reported(failure: Dictionary)
signal runtime_failure_resolved(failure: Dictionary, resolution: StringName)

enum DialogState { OFF, EXECUTING, WAITING, FAILED }

const DIALOGUE_SERVICES := preload(
	"res://addons/konado/runtime/dialogue/konado_dialogue_services.gd"
)
const INSTRUCTION_AWAITER := preload(
	"res://addons/konado/runtime/dialogue/konado_instruction_awaiter.gd"
)
const RUNTIME_FAILURE_REPORTER := preload(
	"res://addons/konado/runtime/dialogue/konado_runtime_failure_reporter.gd"
)
const RUNTIME_FAILURE_CONTROLLER := preload(
	"res://addons/konado/runtime/dialogue/konado_runtime_failure_controller.gd"
)
const RUNTIME_TIMELINE := preload("res://addons/konado/runtime/dialogue/konado_runtime_timeline.gd")
const SCRIPT_RUNTIME_DEBUGGER := preload(
	"res://addons/konado/language/integration/konado_script_runtime_debugger.gd"
)
const CAMERA_CONTROLLER_SCRIPT := preload(
	"res://addons/konado/runtime/camera/konado_camera_controller.gd"
)
const CHOICE_CONTROLLER_SCRIPT := preload(
	"res://addons/konado/runtime/dialogue/konado_choice_controller.gd"
)
const SAVE_SYSTEM_SCRIPT := preload("res://addons/konado/runtime/save/konado_save_system.gd")
const SAVE_PANEL_SCRIPT := preload("res://addons/konado/runtime/ui/save/konado_save_panel.gd")
const DIALOGUE_HISTORY_COORDINATOR := preload(
	"res://addons/konado/runtime/dialogue/konado_dialogue_history_coordinator.gd"
)
const BACKLOG_PANEL_SCRIPT := preload(
	"res://addons/konado/runtime/ui/backlog/konado_backlog_panel.gd"
)
const SETTINGS_ADAPTER_SCRIPT := preload(
	"res://addons/konado/runtime/integrations/konado_settings_adapter.gd"
)
const INVALID_NEXT := -2
const MAX_IMMEDIATE_INSTRUCTIONS_PER_PUMP := 4096

@export_category("Playback Settings")
@export var require_visible_in_tree := true
@export var initialize_on_ready := true
@export var start_on_ready := true
@export var actor_auto_highlight := true
@export var autoplay := false
@export var typing_interval := 0.04
@export var auto_play_delay := 2.0
@export var deterministic_seed := 0

@export_category("Global Variable")
@export var variable_store: KonadoVariableStore

@export_category("UI Settings")
@export var auto_show_dialogue_box := true
@export var horizontal_division := 5
@export var choice_controller: CHOICE_CONTROLLER_SCRIPT
@export var dialogue_box: KonadoDialogueBox
@export var screen_text: KonadoScreenText
@export var stage_controller: KonadoStageController
@export var audio_controller: KonadoAudioController
@export var quick_save_button: Button
@export var quick_load_button: Button
@export var save_panel_button: Button
@export var auto_play_button: Button
@export var achievement_button: Button
@export var settings_button: Button
@export var backlog_button: Button
@export var back_button: Button
@export var save_panel: SAVE_PANEL_SCRIPT
@export var backlog_panel: BACKLOG_PANEL_SCRIPT
@export var save_feedback_label: Label

@export_category("Dialogue Resources")
@export var start_dialogue_shot: KonadoShot
@export var character_list: KonadoCharacterList
@export var background_list: KonadoBackgroundList
@export var background_music_list: KonadoBackgroundMusicList
@export var voice_list: KonadoVoiceList
@export var sound_effect_list: KonadoSoundEffectList

@export_category("Log Tool")
@export var enable_overlay_log := true
@export var report_runtime_failures_to_console := true
@export var error_tooltip_panel: ColorRect
@export var error_tooltip_label: Label
@export var error_action_container: Container

@export_category("System")
@export var save_system: SAVE_SYSTEM_SCRIPT
@export var settings_adapter: SETTINGS_ADAPTER_SCRIPT

@export_category("Dialogue History")
@export var max_dialogue_history_entries := 256:
	set(value):
		max_dialogue_history_entries = maxi(0, value)
		if _dialogue_history_coordinator != null:
			_dialogue_history_coordinator.history().max_entries = max_dialogue_history_entries

@export_category("Camera")
@export var camera_controller: CAMERA_CONTROLLER_SCRIPT

var dialogue_state := DialogState.OFF
var current_shot: KonadoShot
var dialogue_history: KonadoDialogueHistory:
	get:
		return _history_coordinator().history()
var timeline: KonadoRuntimeTimeline:
	get:
		return _timeline()
var pending_runtime_failure: Dictionary:
	get:
		return _failure_controller()._pending_report()

var _achievement_manager: Node
var _temp_variables: Dictionary = {}
var _waiting_signal_name := ""
var _story_localization: Node
var _dialogue_services: RefCounted
var _dialogue_history_coordinator: KonadoDialogueHistoryCoordinator
var _vm := KonadoVirtualMachine.new()
var _executor: KonadoInstructionExecutor
var _active_token: Dictionary = {}
var _typing_completed_callback := Callable()
var _instruction_awaiter: KonadoInstructionAwaiter
var _playback_generation := 0
var _shot_active := false
var _pumping := false
var _pump_scheduled := false
var _dialogue_typing := false
var _rng := RandomNumberGenerator.new()
var _translation_reload_queued := false
var _loaded_locale := ""
var _save_feedback_generation := 0
var _transition_failure: Dictionary = {}
var _runtime_failure_controller: KonadoRuntimeFailureController
var _runtime_timeline: KonadoRuntimeTimeline


func _notification(what: int) -> void:
	if what != NOTIFICATION_TRANSLATION_CHANGED or not is_inside_tree():
		return
	if _runtime_failure_controller != null:
		_runtime_failure_controller._refresh_overlay()
	_queue_translation_reload()


func _ready() -> void:
	if deterministic_seed == 0:
		_rng.randomize()
	else:
		_rng.seed = deterministic_seed
	_executor = KonadoInstructionExecutor.new(self)
	variable_store = variable_store if variable_store != null else KonadoVariableStore.new()
	_achievement_manager = get_tree().root.get_node_or_null("KonadoAchievements")
	_story_localization = get_tree().root.get_node_or_null("KonadoStoryLocalization")
	_loaded_locale = TranslationServer.get_locale()
	if require_visible_in_tree:
		if not is_visible_in_tree():
			return
		hidden.connect(stop_dialogue)
	if dialogue_box != null:
		dialogue_box.on_dialogue_click.connect(_process_next)
		if audio_controller != null and audio_controller.voice_player != null:
			dialogue_box.bind_voice_player(audio_controller.voice_player)
	if auto_play_button != null:
		auto_play_button.toggled.connect(start_autoplay)
	if quick_save_button != null:
		quick_save_button.pressed.connect(_quick_save)
	if quick_load_button != null:
		quick_load_button.pressed.connect(_quick_load)
	if save_panel_button != null:
		save_panel_button.pressed.connect(_open_save_panel)
	for save_button: Button in [quick_save_button, quick_load_button, save_panel_button]:
		if save_button != null:
			save_button.visible = save_system != null
	if achievement_button != null:
		achievement_button.visible = _achievement_manager != null
		if _achievement_manager != null:
			achievement_button.pressed.connect(_achievement_manager.show_panel)
	if settings_adapter != null:
		settings_adapter.setting_changed.connect(_on_setting_changed)
		if settings_button != null:
			settings_button.pressed.connect(settings_adapter.show_settings_panel)
	if save_system != null:
		save_system.set_dialogue_manager(self)
	if save_panel != null:
		save_panel.set_save_system(save_system)
	if backlog_panel != null:
		backlog_panel.set_dialogue_manager(self)
	if backlog_button != null:
		backlog_button.visible = backlog_panel != null
		if backlog_panel != null:
			backlog_button.pressed.connect(backlog_panel.open_panel)
	if back_button != null:
		back_button.pressed.connect(_timeline().step_back)
	_failure_controller()._setup_logger()

	if initialize_on_ready:
		_initialize_on_ready.call_deferred()


func _exit_tree() -> void:
	_cancel_execution()
	if _runtime_failure_controller != null:
		_runtime_failure_controller._dispose()


func _initialize_on_ready() -> void:
	if not is_inside_tree() or not initialize_on_ready:
		return
	# A parent may explicitly select or initialize a shot from its own _ready().
	# Preserve that configuration instead of replacing it with the exported shot.
	if current_shot != null:
		if start_on_ready and not _shot_active:
			start_dialogue()
		return
	init_dialogue(start_dialogue if start_on_ready else Callable())


func init_dialogue(callback: Callable = Callable()) -> void:
	var shot := _load_localized_shot(start_dialogue_shot)
	if not _can_install_shot(shot):
		return
	var failure_report := _failure_controller()._detach_pending_report()
	_cancel_execution()
	if not _install_shot(shot):
		_failure_controller()._publish_external_resolution(
			failure_report, KonadoRuntimeFailureSession.RESOLUTION_CANCELLED
		)
		return
	_reset_transient_interfaces()
	_history_coordinator().clear()
	if stage_controller != null:
		stage_controller.character_list = character_list
		stage_controller.remove_all_actors(true)
	_failure_controller()._publish_external_resolution(
		failure_report, KonadoRuntimeFailureSession.RESOLUTION_REINITIALIZE
	)
	if callback.is_valid():
		callback.call()


func set_shot(new_shot: KonadoShot) -> void:
	var localized := _load_localized_shot(new_shot)
	if not _can_install_shot(localized):
		return
	var failure_report := _failure_controller()._detach_pending_report()
	_cancel_execution()
	_history_coordinator().clear()
	if screen_text != null:
		screen_text.reset_screen_text()
	if not _install_shot(localized):
		_failure_controller()._publish_external_resolution(
			failure_report, KonadoRuntimeFailureSession.RESOLUTION_CANCELLED
		)
		return
	start_dialogue_shot = localized
	_failure_controller()._publish_external_resolution(
		failure_report, KonadoRuntimeFailureSession.RESOLUTION_REPLACE_SHOT
	)


func start_dialogue() -> void:
	if current_shot == null or _vm.program == null or _vm.pc == KonadoProgram.INVALID_PC:
		push_error("Konado: 对话尚未初始化")
		return
	if _shot_active:
		return
	_shot_active = true
	dialogue_state = DialogState.EXECUTING
	if not _vm.has_state():
		_vm.synchronize_state(KonadoRuntimeState.capture(self))
	shot_start.emit()
	_schedule_pump()


func stop_dialogue() -> void:
	var emit_end := _shot_active
	var failure_report := _failure_controller()._detach_pending_report()
	_cancel_execution()
	_reset_transient_interfaces(false)
	if stage_controller != null:
		stage_controller.remove_all_actors()
		stage_controller.clean_background(
			KonadoStageController.BackgroundTransitionEffect.ALPHA_FADE
		)
	if dialogue_box != null:
		dialogue_box.dismiss_dialogue_box()
	if emit_end:
		shot_end.emit()
	_failure_controller()._publish_external_resolution(
		failure_report, KonadoRuntimeFailureSession.ACTION_STOP
	)


func _install_shot(shot: KonadoShot) -> bool:
	if not _can_install_shot(shot):
		return false
	var installed_shot := shot.duplicate() as KonadoShot
	if not _vm.install(installed_shot.program, installed_shot.entry_pc()):
		push_error("Konado: 无法安装镜头 Program")
		return false
	current_shot = installed_shot
	_remember_shot(current_shot)
	_temp_variables.clear()
	_waiting_signal_name = ""
	dialogue_state = DialogState.OFF
	return true


func _can_install_shot(shot: KonadoShot) -> bool:
	if shot == null or not shot.ensure_script_ready() or shot.program == null:
		push_error("Konado: 镜头没有可执行 Program")
		return false
	var entry_pc := shot.entry_pc()
	if entry_pc < 0 or entry_pc >= shot.program.instruction_count():
		push_error("Konado: 镜头没有有效的入口指令")
		return false
	return true


func _pump() -> void:
	_pump_scheduled = false
	if _pumping or not _shot_active or dialogue_state != DialogState.EXECUTING:
		return
	_pumping = true
	var count := 0
	while _shot_active and dialogue_state == DialogState.EXECUTING:
		if count >= MAX_IMMEDIATE_INSTRUCTIONS_PER_PUMP:
			# This per-pump time slice keeps large or cyclic scripts cancellable.
			break
		count += 1
		var instruction := _current_instruction()
		if instruction == null:
			_finish_shot()
			break
		var instruction_context := _instruction_failure_context(instruction)
		var execution_generation := _playback_generation
		if SCRIPT_RUNTIME_DEBUGGER.before_instruction(self, instruction):
			dialogue_state = DialogState.WAITING
			break
		_timeline().remember_line(instruction)
		_active_token = _vm.begin_patch(_capture_instruction_state(instruction))
		if _active_token.is_empty():
			_fail_current("VM 无法开始当前指令", {}, instruction_context)
			break
		var token := _active_token.duplicate(true)
		dialogue_line_start.emit(instruction.stable_key())
		if execution_generation != _playback_generation or not _token_is_active(token):
			break
		var result := _executor.execute(instruction, token)
		# Public callbacks may replace or stop the current shot while an instruction
		# is executing. Never apply the superseded transaction to the replacement.
		if execution_generation != _playback_generation:
			break
		if result == KonadoVirtualMachine.Result.WAITING:
			# A zero-duration awaitable may have completed synchronously.
			if _token_is_active(token):
				dialogue_state = DialogState.WAITING
				break
			if not _active_token.is_empty():
				break
			continue
		if result == KonadoVirtualMachine.Result.CANCELLED:
			break
		if result == KonadoVirtualMachine.Result.FAILED:
			if not _token_is_active(token):
				break
			var failure := _executor.get_failure()
			_fail_current(
				(
					failure
					if failure != null
					else (
						KonadoExecutionFailure
						. new(
							&"runtime.instruction_failed",
							"指令执行失败：%s" % KonadoOpcode.name_of(instruction.opcode()),
							{
								"subsystem": "runtime",
								"operation": KonadoOpcode.name_of(instruction.opcode())
							},
						)
					)
				),
				token,
				instruction_context,
			)
			break
		if _token_is_active(token):
			_fail_current("指令执行器未提交原子事务", token, instruction_context)
			break
		if not _active_token.is_empty():
			break
	_pumping = false
	if _shot_active and dialogue_state == DialogState.EXECUTING:
		_schedule_pump()


func _schedule_pump() -> void:
	if _pump_scheduled or not _shot_active:
		return
	_pump_scheduled = true
	_pump.call_deferred()


func _resume_from_debugger() -> void:
	if not _shot_active or not _active_token.is_empty():
		return
	dialogue_state = DialogState.EXECUTING
	_schedule_pump()


func _complete_instruction(
	token: Dictionary, next_pc := INVALID_NEXT, schedule_next := true
) -> void:
	# A failed transaction intentionally retains its VM token for Retry. A cancelled
	# async callback must never use that token to commit behind the recovery UI.
	if dialogue_state == DialogState.FAILED or not _token_is_active(token):
		return
	var instruction := _current_instruction()
	if instruction == null:
		return
	if next_pc == INVALID_NEXT:
		next_pc = instruction.next_pc()
	dialogue_line_end.emit(instruction.stable_key())
	if not _token_is_active(token):
		return
	if not _vm.commit_patch(token, next_pc, _capture_instruction_state(instruction)):
		_fail_current("VM 提交失败", token, _instruction_failure_context(instruction))
		return
	_history_coordinator().commit(token)
	_active_token.clear()
	_waiting_signal_name = ""
	_dialogue_typing = false
	dialogue_state = DialogState.EXECUTING
	if next_pc == KonadoProgram.INVALID_PC:
		_finish_shot()
	elif schedule_next:
		_schedule_pump()


func _transition_to_shot(token: Dictionary, target: KonadoShot) -> bool:
	_transition_failure.clear()
	if not _token_is_active(token):
		_transition_failure = {
			"code": "script.jump_transaction_inactive",
			"message": "jump 指令的原子事务已失效",
			"subsystem": "script",
			"operation": "jump",
		}
		return false
	var next_shot := _prepare_transition_target(target)
	if next_shot == null:
		return false
	var entry_pc := next_shot.entry_pc()
	dialogue_line_end.emit(_current_instruction().stable_key())
	if not _token_is_active(token):
		_transition_failure = {
			"code": "script.jump_transaction_superseded",
			"message": "jump 指令已被回调中的新执行事务取代",
			"subsystem": "script",
			"operation": "jump",
			"superseded": true,
		}
		return false
	var previous_shot := current_shot
	var previous_temporary_variables := _temp_variables.duplicate(true)
	_temp_variables.clear()
	_waiting_signal_name = ""
	current_shot = next_shot
	_remember_shot(current_shot)
	var state_after := KonadoRuntimeState.capture(self)
	if not _vm.transition(token, next_shot.program, entry_pc, state_after):
		current_shot = previous_shot
		_temp_variables = previous_temporary_variables
		_transition_failure = {
			"code": "script.jump_vm_transition_failed",
			"message": "VM 无法提交 jump 转场",
			"subsystem": "vm",
			"operation": "jump",
		}
		return false
	_active_token.clear()
	_dialogue_typing = false
	dialogue_state = DialogState.EXECUTING
	shot_end.emit()
	if not _shot_active:
		return true
	shot_start.emit()
	if _shot_active:
		_schedule_pump()
	return true


func _prepare_transition_target(target: KonadoShot) -> KonadoShot:
	var localized := _load_localized_shot(target)
	if localized == null or not localized.ensure_script_ready() or localized.program == null:
		_transition_failure = {
			"code": "script.jump_program_missing",
			"message": "jump 目标没有可执行 Program",
			"subsystem": "script",
			"operation": "jump",
		}
		return null
	var next_shot := localized.duplicate() as KonadoShot
	if next_shot.entry_pc() == KonadoProgram.INVALID_PC:
		_transition_failure = {
			"code": "script.jump_entry_missing",
			"message": "jump 目标没有入口指令",
			"subsystem": "script",
			"operation": "jump",
		}
		return null
	return next_shot


func _get_transition_failure() -> Dictionary:
	return _transition_failure.duplicate(true)


func _finish_shot() -> void:
	if not _shot_active:
		return
	_shot_active = false
	dialogue_state = DialogState.OFF
	_cancel_pending_callbacks()
	# 清理场景：隐藏对话框、清除文字、消除角色和背景
	_reset_transient_interfaces(false)
	if stage_controller != null:
		stage_controller.remove_all_actors()
		stage_controller.clean_background(
			KonadoStageController.BackgroundTransitionEffect.ALPHA_FADE
		)
	if dialogue_box != null:
		dialogue_box.dismiss_dialogue_box()
	if screen_text != null:
		screen_text.reset_screen_text()
	if audio_controller != null:
		audio_controller.stop_background_music()
		audio_controller.stop_voice()
	if camera_controller != null:
		camera_controller.restore_state(
			{"position": Vector2.ZERO, "zoom": Vector2.ONE, "offset": Vector2.ZERO}
		)
	shot_end.emit()


func _fail_current(
	failure_value: Variant, expected_token: Dictionary = {}, instruction_context: Dictionary = {}
) -> void:
	_history_coordinator().discard()
	_failure_controller()._handle_failure(failure_value, expected_token, instruction_context)


func _instruction_failure_context(instruction: KonadoInstruction) -> Dictionary:
	return RUNTIME_FAILURE_REPORTER.capture_context(self, instruction)


func _current_instruction() -> KonadoInstruction:
	return current_shot.instruction_at(_vm.pc) if current_shot != null else null


func _capture_instruction_state(instruction: KonadoInstruction) -> Dictionary:
	return KonadoRuntimeState.capture_instruction_patch(self, instruction)


func _token_is_active(token: Dictionary) -> bool:
	return not token.is_empty() and token == _active_token


func _set_waiting_token(token: Dictionary) -> void:
	if _token_is_active(token):
		dialogue_state = DialogState.WAITING


func _await_signal(completion: Signal, token: Dictionary, two_arguments := false) -> void:
	_awaiter().await_signal(completion, token, two_arguments)


func _begin_stage_operation(token: Dictionary, fallback: KonadoExecutionFailure) -> int:
	return _awaiter().begin_stage_operation(stage_controller, token, fallback)


func _cancel_execution() -> void:
	_playback_generation += 1
	_shot_active = false
	dialogue_state = DialogState.OFF
	_vm.cancel()
	_active_token.clear()
	_history_coordinator().discard()
	_dialogue_typing = false
	_cancel_pending_callbacks()


func _cancel_pending_callbacks() -> void:
	if (
		dialogue_box != null
		and _typing_completed_callback.is_valid()
		and dialogue_box.typing_completed.is_connected(_typing_completed_callback)
	):
		dialogue_box.typing_completed.disconnect(_typing_completed_callback)
	_typing_completed_callback = Callable()
	if _instruction_awaiter != null:
		_instruction_awaiter.cancel()
	if dialogue_box != null:
		dialogue_box.cancel_pending_operations()
	if screen_text != null:
		screen_text.cancel_pending_operations()
	if stage_controller != null:
		stage_controller.cancel_pending_operations()
	if audio_controller != null:
		audio_controller.cancel_pending_operations()
	if camera_controller != null:
		camera_controller.cancel_pending_operations()


func _begin_dialogue_instruction(instruction: KonadoInstruction, token: Dictionary) -> void:
	var begin := func() -> void:
		if not _token_is_active(token):
			return
		var speaker_result: Dictionary = _services().resolve_speaker(
			int(instruction.value(&"speaker_kind")), String(instruction.value(&"speaker"))
		)
		if not bool(speaker_result.get("ok", false)):
			_fail_current(
				_services()._execution_failure(
					speaker_result, &"dialogue.speaker_invalid", "无法解析对话署名"
				),
				token,
				_instruction_failure_context(instruction),
			)
			return
		var character := String(speaker_result.get("value", ""))
		var voice := String(instruction.value(&"voice_id"))
		if not voice.is_empty():
			var voice_result := _play_voice_resource(voice)
			if not bool(voice_result.get("ok", false)):
				_fail_current(
					_services()._execution_failure(
						voice_result, &"audio.voice_failed", "无法播放语音 '%s'" % voice
					),
					token,
					_instruction_failure_context(instruction),
				)
				return
		elif dialogue_box != null:
			dialogue_box.clear_voice_progress()
		if actor_auto_highlight and stage_controller != null and not character.is_empty():
			stage_controller.highlight_actor(character)
		var interval := float(instruction.value(&"interval", -1.0))
		var speed := float(instruction.value(&"speed", 1.0))
		dialogue_box.typing_interval = (interval if interval >= 0.0 else typing_interval / speed)
		var content := _interpolate_variables(String(instruction.value(&"content")))
		dialogue_box.character_name = character
		dialogue_box.dialogue_text = content
		_history_coordinator().stage_dialogue(token, instruction, character, content)
		_dialogue_typing = not content.is_empty()  # 空台词没有打字动画，保持可点击的空行
		if _dialogue_typing:
			_typing_completed_callback = _on_dialogue_typing_completed.bind(token)
			dialogue_box.typing_completed.connect(_typing_completed_callback, CONNECT_ONE_SHOT)
		else:
			_on_dialogue_typing_completed(token)  # 空台词立即视为打字完成，自动模式照常排队
		_set_waiting_token(token)
	if auto_show_dialogue_box and not dialogue_box.is_dialogue_box_visible():
		_dialogue_typing = true  # 淡入完成前尚未开始打字，阻止点击提前完成这一句
		dialogue_box.show_dialogue_box(begin)
	else:
		begin.call()


func _on_dialogue_typing_completed(token: Dictionary) -> void:
	if not _token_is_active(token):
		return
	_dialogue_typing = false
	if autoplay:
		var generation := _playback_generation
		await get_tree().create_timer(auto_play_delay).timeout
		if generation == _playback_generation:
			_complete_instruction(token)
		return
	var instruction := _current_instruction()
	if instruction != null:
		var next := current_shot.instruction_at(instruction.next_pc())
		if next != null and next.opcode() == KonadoOpcode.Type.CHOICE:
			_complete_instruction.call_deferred(token)


func _process_next() -> void:
	if not _shot_active or dialogue_state != DialogState.WAITING:
		return
	var instruction := _current_instruction()
	if instruction == null or instruction.opcode() != KonadoOpcode.Type.DIALOGUE:
		return
	if _dialogue_typing:
		dialogue_box.skip_typing_anim()
	else:
		_complete_instruction(_active_token)


func _on_option_triggered(choice: Dictionary, playback_generation := -1) -> void:
	if playback_generation >= 0 and playback_generation != _playback_generation:
		return
	if not _token_is_active(_active_token):
		return
	var target_pc := int(choice.get("target_pc", KonadoProgram.INVALID_PC))
	if target_pc == KonadoProgram.INVALID_PC:
		_fail_current("选项目标无效")
		return
	if choice_controller != null:
		choice_controller.distroy_options()
	if dialogue_state != DialogState.FAILED:
		_history_coordinator().stage_choice(_active_token, _current_instruction(), choice)
	_complete_instruction(_active_token, target_pc)


func emit_wait_signal(signal_name: String) -> void:
	if _waiting_signal_name == signal_name and _token_is_active(_active_token):
		_complete_instruction(_active_token)


func reload_localized_script(locale: String) -> bool:
	return _services()._reload_localized_script(locale)


func _queue_translation_reload() -> void:
	if _translation_reload_queued:
		return
	_translation_reload_queued = true
	_apply_translation_change.call_deferred()


func _apply_translation_change() -> void:
	_translation_reload_queued = false
	if not is_inside_tree() or not is_node_ready():
		return
	var locale := TranslationServer.get_locale()
	if locale == _loaded_locale:
		return
	if current_shot == null or reload_localized_script(locale):
		_loaded_locale = locale


func _refresh_current_localized_dialogue() -> void:
	var instruction := _current_instruction()
	if instruction == null:
		return
	if instruction.opcode() == KonadoOpcode.Type.DIALOGUE and dialogue_box != null:
		var speaker_result: Dictionary = _services().resolve_speaker(
			int(instruction.value(&"speaker_kind")), String(instruction.value(&"speaker"))
		)
		if not bool(speaker_result.get("ok", false)):
			return
		dialogue_box.character_name = String(speaker_result.get("value", ""))
		dialogue_box.dialogue_text = _interpolate_variables(String(instruction.value(&"content")))
	elif instruction.opcode() == KonadoOpcode.Type.CHOICE and choice_controller != null:
		choice_controller.display_options(
			instruction.value(&"options", []), self, 32, _playback_generation
		)


func _load_localized_shot(shot: KonadoShot) -> KonadoShot:
	return _services()._load_localized_shot(shot)


func _play_voice_resource(name: String) -> Dictionary:
	return _services()._play_voice(name)


func _read_variable(name: String, persistent: bool) -> Variant:
	if persistent:
		return variable_store.get_value(name) if variable_store != null else null
	return _temp_variables.get(name)


func _resolve_operand(value: Variant) -> Variant:
	if value is Dictionary and value.get("kind") == "variable":
		return _read_variable(String(value.get("name", "")), bool(value.get("persistent", false)))
	return value


func _compare_values(left: Variant, right: Variant, operator: int) -> Dictionary:
	return KonadoValueOperations.compare(left, right, operator)


func _apply_variable_instruction(instruction: KonadoInstruction) -> Dictionary:
	return _services()._apply_variable_instruction(instruction)


func _interpolate_variables(text: String) -> String:
	return _services()._interpolate_variables(text)


func can_rollback(steps := 1) -> bool:
	return _timeline().can_rollback(steps)


func rollback(steps := 1) -> bool:
	return _timeline().rollback(steps)


func create_checkpoint(label := "") -> String:
	return _timeline().create_checkpoint(label)


func restore_checkpoint(checkpoint_id: String) -> bool:
	return _timeline().restore_checkpoint(checkpoint_id)


func get_execution_history(limit := 0) -> Array[Dictionary]:
	return _timeline().execution_history(limit)


func clear_execution_history() -> void:
	_timeline().clear_execution_history()


func _capture_execution_snapshot() -> Dictionary:
	return _timeline().capture_execution_snapshot()


func _restore_execution_snapshot(snapshot: Dictionary) -> bool:
	var restored := _timeline().restore_execution_snapshot(snapshot)
	if restored:
		_history_coordinator().clear()
	return restored


func _remember_shot(shot: KonadoShot) -> void:
	_timeline().remember_shot(shot)


func _enter_safe_off_state() -> void:
	var failure_report := _failure_controller()._detach_pending_report()
	_cancel_execution()
	if stage_controller != null:
		stage_controller.remove_all_actors(true)
		stage_controller.clean_background(KonadoStageController.BackgroundTransitionEffect.NONE)
	if audio_controller != null:
		audio_controller.stop_background_music()
		audio_controller.stop_voice()
	if camera_controller != null:
		camera_controller.restore_state(
			{"position": Vector2.ZERO, "zoom": Vector2.ONE, "offset": Vector2.ZERO}
		)
	current_shot = null
	dialogue_state = DialogState.OFF
	_reset_transient_interfaces()
	_history_coordinator().clear()
	_failure_controller()._publish_external_resolution(
		failure_report, KonadoRuntimeFailureSession.RESOLUTION_CANCELLED
	)


func _cancel_active_instruction() -> void:
	_playback_generation += 1
	_vm.cancel()
	_active_token.clear()
	_history_coordinator().discard()
	_dialogue_typing = false
	dialogue_state = DialogState.OFF
	_cancel_pending_callbacks()


func start_autoplay(value: bool) -> void:
	autoplay = value
	if auto_play_button != null:
		auto_play_button.text = tr("KONADO_AUTO_PLAY_STOP") if value else tr("KONADO_AUTO_PLAY")


func _quick_save() -> void:
	if save_system == null:
		return
	var succeeded := save_game(0)
	_show_save_feedback("KONADO_QUICK_SAVE_SUCCEEDED" if succeeded else "KONADO_QUICK_SAVE_FAILED")
	if save_panel != null:
		save_panel.show_status(
			"KONADO_QUICK_SAVE_SUCCEEDED" if succeeded else "KONADO_QUICK_SAVE_FAILED"
		)


func _quick_load() -> void:
	if save_system == null:
		return
	if not bool(get_save_info(0).get("exists", false)):
		_show_save_feedback("KONADO_QUICK_SAVE_MISSING")
		if save_panel != null:
			save_panel.show_status("KONADO_QUICK_SAVE_MISSING")
		return
	if not load_game(0):
		_show_save_feedback("KONADO_QUICK_LOAD_FAILED")
		if save_panel != null:
			save_panel.show_status("KONADO_QUICK_LOAD_FAILED")


func _open_save_panel() -> void:
	if save_panel != null:
		save_panel.open_panel()


func _show_save_feedback(message_key: StringName) -> void:
	if save_feedback_label == null:
		return
	_save_feedback_generation += 1
	var generation := _save_feedback_generation
	save_feedback_label.text = tr(message_key)
	save_feedback_label.visible = true
	get_tree().create_timer(2.0).timeout.connect(
		func() -> void:
			if generation == _save_feedback_generation and save_feedback_label != null:
				save_feedback_label.visible = false
	)


func get_dialogue_variable(key: String) -> Dictionary:
	return {"value": variable_store.get_value(key)} if variable_store.has(key) else {}


func save_game(id: int) -> bool:
	return _services()._save_game(id)


func load_game(id: int) -> bool:
	return _services()._load_game(id)


func delete_save(id: int) -> bool:
	return _services()._delete_save(id)


func get_save_info(id: int) -> Dictionary:
	return _services()._get_save_info(id)


func get_all_save_info() -> Array[Dictionary]:
	return _services()._get_all_save_info()


func _services() -> RefCounted:
	if _dialogue_services == null:
		_dialogue_services = DIALOGUE_SERVICES.new(self)
	return _dialogue_services


func _awaiter() -> KonadoInstructionAwaiter:
	if _instruction_awaiter == null:
		_instruction_awaiter = INSTRUCTION_AWAITER.new(self)
	return _instruction_awaiter


func _failure_controller() -> KonadoRuntimeFailureController:
	if _runtime_failure_controller == null:
		_runtime_failure_controller = RUNTIME_FAILURE_CONTROLLER.new(self)
	return _runtime_failure_controller


func _timeline() -> KonadoRuntimeTimeline:
	if _runtime_timeline == null:
		_runtime_timeline = RUNTIME_TIMELINE.new(self)
	return _runtime_timeline


func _history_coordinator() -> KonadoDialogueHistoryCoordinator:
	if _dialogue_history_coordinator == null:
		_dialogue_history_coordinator = DIALOGUE_HISTORY_COORDINATOR.new(self)
		_dialogue_history_coordinator.history().max_entries = max_dialogue_history_entries
	return _dialogue_history_coordinator


func _on_setting_changed(category: String, key: String, value: Variant) -> void:
	_services()._apply_setting(category, key, value)


func _reset_transient_interfaces(reset_dialogue_box := true) -> void:
	_waiting_signal_name = ""
	if choice_controller != null:
		choice_controller.init_dialog_box()
	if reset_dialogue_box and dialogue_box != null:
		dialogue_box.reset_dialogue_box()
	if screen_text != null:
		screen_text.reset_screen_text()
	if audio_controller != null:
		audio_controller.stop_voice()


func resolve_runtime_failure(action: StringName) -> bool:
	return _failure_controller()._resolve(action)
