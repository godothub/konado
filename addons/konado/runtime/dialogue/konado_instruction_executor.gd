extends RefCounted
class_name KonadoInstructionExecutor

## Executes one atomic instruction. Flow ownership remains in KonadoVirtualMachine.

var _host_ref: WeakRef
var _handlers: Dictionary = {}
var _failure: KonadoExecutionFailure
var _executing_instruction: KonadoInstruction


func _init(host: KonadoDialogueManager) -> void:
	_host_ref = weakref(host)
	for opcode in KonadoScriptCommandRegistry.RUNTIME_HANDLERS:
		var handler_name := KonadoScriptCommandRegistry.runtime_handler(int(opcode))
		var handler := Callable(self, handler_name)
		if handler.is_valid():
			_handlers[int(opcode)] = handler


func execute(instruction: KonadoInstruction, token: Dictionary) -> int:
	_failure = null
	_executing_instruction = instruction
	var host := _host_ref.get_ref() as KonadoDialogueManager
	if host == null:
		return _failed(&"runtime.host_unavailable", "对话管理器已失效")
	# 回退重放：该不可逆指令此前已经生效，此处跳过执行以避免重复副作用。
	if host._vm._should_skip_rewind(instruction.stable_key()):
		host._vm._consume_rewind_skip(instruction.stable_key())
		if host._token_is_active(token):
			host._complete_instruction(token, instruction.next_pc())
		return KonadoVirtualMachine.Result.COMPLETED
	var handler: Callable = _handlers.get(instruction.opcode(), Callable())
	if not handler.is_valid():
		return _failed(
			&"runtime.unsupported_opcode",
			"VM 不支持操作码 '%s'" % KonadoOpcode.name_of(instruction.opcode()),
			{"subsystem": "vm", "operation": KonadoOpcode.name_of(instruction.opcode())},
		)
	var result := int(handler.call(host, instruction, token))
	if result == KonadoVirtualMachine.Result.COMPLETED and host._token_is_active(token):
		host._complete_instruction(token, instruction.next_pc())
	return result


func get_failure() -> KonadoExecutionFailure:
	return _failure


func _failed(code: StringName, message: String, context: Dictionary = {}) -> int:
	_failure = KonadoExecutionFailure.new(code, message, _locate(code, context))
	return KonadoVirtualMachine.Result.FAILED


## 给失败上下文补上“哪一步报错”：当前指令所属剧本、指令键与源码行号。
## 错误编号与检出函数由 KonadoExecutionFailure 从 KonadoErrorRegistry 补齐。
func _locate(code: StringName, context: Dictionary) -> Dictionary:
	var enriched := context.duplicate(true)
	var host := _host_ref.get_ref() as KonadoDialogueManager
	if host == null:
		return enriched
	if host._vm.program != null:
		enriched["source_path"] = host._vm.program.source_path
	var instruction := (
		_executing_instruction if _executing_instruction != null else host._current_instruction()
	)
	if instruction != null:
		enriched["instruction_key"] = String(instruction.stable_key())
		enriched["source_line"] = instruction.source_line()
		if String(enriched.get("source_path", "")).is_empty():
			enriched["source_path"] = instruction.source_path()
		_refine_function(code, enriched, instruction)
	return enriched


## 检出函数精修：注册表若把同类失败归并到“另一个指令处理器”，则改用当前实际处理器，
## 使 `actor motion` 的失败指向 `_actor_motion` 而不是 `_actor_change`；
## 注册表指向更深的私有助手（如 `_condition_variable`）时更精确，保持不变。
func _refine_function(
	code: StringName, enriched: Dictionary, instruction: KonadoInstruction
) -> void:
	if not String(enriched.get("function", "")).is_empty():
		return
	var canonical := String(KonadoErrorRegistry.location_for(code).get("function", ""))
	var prefix := "KonadoInstructionExecutor."
	if not canonical.begins_with(prefix):
		return
	var canonical_handler := canonical.trim_prefix(prefix)
	var handler := KonadoScriptCommandRegistry.runtime_handler(instruction.opcode())
	if handler.is_empty() or handler == canonical_handler:
		return
	if not KonadoScriptCommandRegistry.RUNTIME_HANDLERS.values().has(StringName(canonical_handler)):
		return
	enriched["function"] = "%s%s" % [prefix, handler]


func _dialogue(
	host: KonadoDialogueManager, instruction: KonadoInstruction, token: Dictionary
) -> int:
	if host.dialogue_box == null:
		return _failed(
			&"dialogue.box_missing",
			"dialogue 指令需要 KonadoDialogueBox",
			{"subsystem": "dialogue", "operation": "dialogue"},
		)
	host._begin_dialogue_instruction(instruction, token)
	return KonadoVirtualMachine.Result.WAITING


func _background(
	host: KonadoDialogueManager, instruction: KonadoInstruction, token: Dictionary
) -> int:
	if host.stage_controller == null:
		return _missing_controller("background", "stage_controller")
	var background_id := String(instruction.value(&"background"))
	var fallback := _make_failure(
		&"stage.background_failed",
		"背景 '%s' 切换失败" % background_id,
		{
			"subsystem": "stage",
			"operation": "background",
			"resource_kind": "background",
			"resource_id": background_id,
		},
	)
	var request_id := host._begin_stage_operation(token, fallback)
	var result: Dictionary = (
		host
		. _services()
		. _display_background(
			background_id,
			int(instruction.value(&"effect")),
			float(instruction.value(&"duration")),
			request_id,
		)
	)
	if not bool(result.get("ok", false)):
		return _failed_from_result(result, fallback)
	return KonadoVirtualMachine.Result.WAITING


func _actor_show(
	host: KonadoDialogueManager, instruction: KonadoInstruction, token: Dictionary
) -> int:
	if host.stage_controller == null:
		return _missing_controller("actor.show", "stage_controller")
	var actor_id := String(instruction.value(&"actor"))
	var state_id := String(instruction.value(&"state"))
	var fallback := _actor_failure(&"stage.actor_show_failed", "actor.show", actor_id, state_id)
	var request_id := host._begin_stage_operation(token, fallback)
	var position: Vector2 = instruction.value(&"position", Vector2.ZERO)
	var result: Dictionary = (
		host
		. _services()
		. _show_actor(
			actor_id,
			state_id,
			int(position.x),
			float(instruction.value(&"duration")),
			request_id,
		)
	)
	if not bool(result.get("ok", false)):
		return _failed_from_result(result, fallback)
	return KonadoVirtualMachine.Result.WAITING


func _actor_change(
	host: KonadoDialogueManager, instruction: KonadoInstruction, token: Dictionary
) -> int:
	if host.stage_controller == null:
		return _missing_controller("actor.change", "stage_controller")
	var actor_id := String(instruction.value(&"actor"))
	var state_id := String(instruction.value(&"state"))
	if host.stage_controller.get_actor(actor_id) == null:
		return _failed(
			&"stage.actor_not_present",
			"无法切换演员 '%s' 的状态：演员不在舞台上" % actor_id,
			_actor_context("actor.change", actor_id, state_id),
		)
	var fallback := _actor_failure(&"stage.actor_change_failed", "actor.change", actor_id, state_id)
	var request_id := host._begin_stage_operation(token, fallback)
	host.stage_controller.change_actor_state(
		actor_id, state_id, float(instruction.value(&"duration")), false, request_id
	)
	return KonadoVirtualMachine.Result.WAITING


func _actor_move(
	host: KonadoDialogueManager, instruction: KonadoInstruction, token: Dictionary
) -> int:
	if host.stage_controller == null:
		return _missing_controller("actor.move", "stage_controller")
	var actor_id := String(instruction.value(&"actor"))
	if host.stage_controller.get_actor(actor_id) == null:
		return _failed(
			&"stage.actor_not_present",
			"无法移动演员 '%s'：演员不在舞台上" % actor_id,
			_actor_context("actor.move", actor_id),
		)
	var fallback := _actor_failure(&"stage.actor_move_failed", "actor.move", actor_id)
	var request_id := host._begin_stage_operation(token, fallback)
	var position: Vector2 = instruction.value(&"position", Vector2.ZERO)
	host.stage_controller.move_actor(
		actor_id, int(position.x), float(instruction.value(&"duration")), false, request_id
	)
	return KonadoVirtualMachine.Result.WAITING


func _actor_motion(
	host: KonadoDialogueManager, instruction: KonadoInstruction, token: Dictionary
) -> int:
	if host.stage_controller == null:
		return _missing_controller("actor.motion", "stage_controller")
	var actor_id := String(instruction.value(&"actor"))
	var motion_name := String(instruction.value(&"motion"))
	if host.stage_controller.get_actor(actor_id) == null:
		return _failed(
			&"stage.actor_not_present",
			"无法播放演员 '%s' 的动作：演员不在舞台上" % actor_id,
			_actor_context("actor.motion", actor_id, "", motion_name),
		)
	var fallback := _actor_failure(
		&"stage.actor_motion_failed", "actor.motion", actor_id, "", motion_name
	)
	# 未指定 duration 时编译器会填入 -1 哨兵：不能把它当成显式时长传给动作层，
	# 否则动作层会判定“时长为 0 或负数”而立刻播完，动作在画面上根本看不到。
	var params := {}
	var motion_duration := float(instruction.value(&"duration"))
	if motion_duration >= 0.0:
		params["duration"] = motion_duration
	var request_id := host._begin_stage_operation(token, fallback)
	host.stage_controller.play_actor_motion(actor_id, motion_name, params, false, request_id)
	return KonadoVirtualMachine.Result.WAITING


func _actor_exit(
	host: KonadoDialogueManager, instruction: KonadoInstruction, token: Dictionary
) -> int:
	if host.stage_controller == null:
		return _missing_controller("actor.exit", "stage_controller")
	var actor_id := String(instruction.value(&"actor"))
	if host.stage_controller.get_actor(actor_id) == null:
		return _failed(
			&"stage.actor_not_present",
			"无法移出演员 '%s'：演员不在舞台上" % actor_id,
			_actor_context("actor.exit", actor_id),
		)
	var fallback := _actor_failure(&"stage.actor_exit_failed", "actor.exit", actor_id)
	var request_id := host._begin_stage_operation(token, fallback)
	host.stage_controller.remove_actor(
		actor_id, float(instruction.value(&"duration")), false, request_id
	)
	return KonadoVirtualMachine.Result.WAITING


func _choice(host: KonadoDialogueManager, instruction: KonadoInstruction, token: Dictionary) -> int:
	var choices: Array[Dictionary] = instruction.value(&"options", [])
	if choices.is_empty() or host.choice_controller == null:
		return _failed(
			&"dialogue.choice_unavailable",
			"choice 指令没有有效选项或选项界面",
			{"subsystem": "dialogue", "operation": "choice"},
		)
	host._set_waiting_token(token)
	host.choice_controller.display_options(choices, host, 32, host._playback_generation)
	host.choice_controller.show()
	return KonadoVirtualMachine.Result.WAITING


func _audio_bgm_play(
	host: KonadoDialogueManager, instruction: KonadoInstruction, _token: Dictionary
) -> int:
	var resource_id := String(instruction.value(&"resource"))
	var result: Dictionary = host._services()._play_bgm(resource_id)
	return (
		KonadoVirtualMachine.Result.COMPLETED
		if bool(result.get("ok", false))
		else _failed_from_result(
			result,
			_make_failure(
				&"audio.bgm_failed",
				"无法播放 BGM '%s'" % resource_id,
				_audio_context("audio.bgm.play", "background_music", resource_id),
			)
		)
	)


func _audio_bgm_stop(
	host: KonadoDialogueManager, _instruction: KonadoInstruction, _token: Dictionary
) -> int:
	if host.audio_controller == null:
		return _missing_controller("audio.bgm.stop", "audio_controller")
	if host.audio_controller.background_music_player == null:
		return _failed(
			&"audio.player_missing",
			"background_music_player 未配置",
			_audio_context("audio.bgm.stop", "audio_player", "background_music_player"),
		)
	host.audio_controller.stop_background_music()
	return KonadoVirtualMachine.Result.COMPLETED


func _audio_sfx_play(
	host: KonadoDialogueManager, instruction: KonadoInstruction, _token: Dictionary
) -> int:
	var resource_id := String(instruction.value(&"resource"))
	var result: Dictionary = host._services()._play_sound_effect(resource_id)
	return (
		KonadoVirtualMachine.Result.COMPLETED
		if bool(result.get("ok", false))
		else _failed_from_result(
			result,
			_make_failure(
				&"audio.sfx_failed",
				"无法播放音效 '%s'" % resource_id,
				_audio_context("audio.sfx.play", "sound_effect", resource_id),
			)
		)
	)


func _condition(
	host: KonadoDialogueManager, instruction: KonadoInstruction, token: Dictionary
) -> int:
	var target := _condition_target(host, instruction)
	if not bool(target.get("ok", false)):
		return _failed_from_result(
			target,
			_make_failure(
				&"variable.condition_failed",
				"条件求值失败",
				{"subsystem": "variables", "operation": "condition"},
			),
		)
	host._complete_instruction(token, int(target.get("pc", KonadoProgram.INVALID_PC)))
	return KonadoVirtualMachine.Result.COMPLETED


func _variable(
	host: KonadoDialogueManager, instruction: KonadoInstruction, _token: Dictionary
) -> int:
	var result := host._apply_variable_instruction(instruction)
	return (
		KonadoVirtualMachine.Result.COMPLETED
		if bool(result.get("ok", false))
		else _failed_from_result(
			result,
			_make_failure(
				&"variable.operation_failed",
				"变量操作失败",
				{
					"subsystem": "variables",
					"operation": "variable",
					"resource_kind": "variable",
					"resource_id": String(instruction.value(&"name")),
				},
			)
		)
	)


func _jump_branch(
	host: KonadoDialogueManager, instruction: KonadoInstruction, token: Dictionary
) -> int:
	host._complete_instruction(token, instruction.next_pc())
	return KonadoVirtualMachine.Result.COMPLETED


func _emit_signal(
	host: KonadoDialogueManager, instruction: KonadoInstruction, _token: Dictionary
) -> int:
	host.custom_signal.emit(String(instruction.value(&"content")))
	return KonadoVirtualMachine.Result.COMPLETED


func _achievement_unlock(
	host: KonadoDialogueManager, instruction: KonadoInstruction, _token: Dictionary
) -> int:
	if host._achievement_manager == null:
		return _missing_controller("achievement.unlock", "KonadoAchievements")
	return _achievement_result(
		host._achievement_manager.try_unlock_achievement(String(instruction.value(&"id"))),
		"achievement.unlock",
		String(instruction.value(&"id")),
	)


func _achievement_progress(
	host: KonadoDialogueManager, instruction: KonadoInstruction, _token: Dictionary
) -> int:
	if host._achievement_manager == null:
		return _missing_controller("achievement.progress", "KonadoAchievements")
	return _achievement_result(
		host._achievement_manager.try_increment_progress(
			String(instruction.value(&"id")), instruction.value(&"value")
		),
		"achievement.progress",
		String(instruction.value(&"id")),
	)


func _achievement_flag(
	host: KonadoDialogueManager, instruction: KonadoInstruction, _token: Dictionary
) -> int:
	if host._achievement_manager == null:
		return _missing_controller("achievement.flag", "KonadoAchievements")
	return _achievement_result(
		host._achievement_manager.try_set_flag(
			String(instruction.value(&"id")), bool(instruction.value(&"value"))
		),
		"achievement.flag",
		String(instruction.value(&"id")),
	)


func _halt(host: KonadoDialogueManager, _instruction: KonadoInstruction, token: Dictionary) -> int:
	host._complete_instruction(token, KonadoProgram.INVALID_PC)
	return KonadoVirtualMachine.Result.COMPLETED


func _textbox_show(
	host: KonadoDialogueManager, instruction: KonadoInstruction, token: Dictionary
) -> int:
	return _textbox(host, instruction, token, true)


func _textbox_hide(
	host: KonadoDialogueManager, instruction: KonadoInstruction, token: Dictionary
) -> int:
	return _textbox(host, instruction, token, false)


func _wait_signal(
	host: KonadoDialogueManager, instruction: KonadoInstruction, token: Dictionary
) -> int:
	host._waiting_signal_name = String(instruction.value(&"name"))
	host._set_waiting_token(token)
	return KonadoVirtualMachine.Result.WAITING


func _camera_move_async(
	host: KonadoDialogueManager, instruction: KonadoInstruction, _token: Dictionary
) -> int:
	if host.camera_controller == null:
		return _missing_controller("camera.move.async", "camera_controller")
	var accepted := (
		host
		. camera_controller
		. move_to_marker_async(
			String(instruction.value(&"camera")),
			float(instruction.value(&"duration")),
			String(instruction.value(&"transition")),
		)
	)
	return (
		KonadoVirtualMachine.Result.COMPLETED
		if accepted
		else _camera_failed(&"camera.move_rejected", "camera.move.async", host, instruction)
	)


func _camera_reset_async(
	host: KonadoDialogueManager, instruction: KonadoInstruction, _token: Dictionary
) -> int:
	if host.camera_controller == null:
		return _missing_controller("camera.reset.async", "camera_controller")
	var accepted := host.camera_controller.reset_camera_async(
		float(instruction.value(&"duration")), String(instruction.value(&"transition"))
	)
	return (
		KonadoVirtualMachine.Result.COMPLETED
		if accepted
		else _camera_failed(&"camera.reset_rejected", "camera.reset.async", host, instruction)
	)


func _camera_shake_async(
	host: KonadoDialogueManager, instruction: KonadoInstruction, _token: Dictionary
) -> int:
	if host.camera_controller == null:
		return _missing_controller("camera.shake.async", "camera_controller")
	var accepted := host.camera_controller.shake_camera_async(float(instruction.value(&"duration")))
	return (
		KonadoVirtualMachine.Result.COMPLETED
		if accepted
		else _camera_failed(&"camera.shake_rejected", "camera.shake.async", host, instruction)
	)


func _camera_stop_async(
	host: KonadoDialogueManager, _instruction: KonadoInstruction, _token: Dictionary
) -> int:
	if host.camera_controller == null:
		return _missing_controller("camera.stop.async", "camera_controller")
	if host.camera_controller.finish_async_operations():
		return KonadoVirtualMachine.Result.COMPLETED
	return _camera_failed(&"camera.stop_rejected", "camera.stop.async", host, null)


func _condition_target(host: KonadoDialogueManager, instruction: KonadoInstruction) -> Dictionary:
	var variable_name := String(instruction.value(&"variable"))
	var persistent := bool(instruction.value(&"persistent"))
	var left := _condition_variable(host, variable_name, persistent)
	if not bool(left.get("ok", false)):
		return left
	var encoded_target := instruction.value(&"target")
	if encoded_target is Dictionary and encoded_target.get("kind") == "variable":
		var target_name := String(encoded_target.get("name", ""))
		var target_persistent := bool(encoded_target.get("persistent", false))
		var right := _condition_variable(host, target_name, target_persistent)
		if not bool(right.get("ok", false)):
			return right
		encoded_target = right["value"]
	var comparison := host._compare_values(
		left["value"], encoded_target, int(instruction.value(&"operator"))
	)
	if not bool(comparison.get("ok", false)):
		return {
			"ok": false,
			"code": "variable.condition_type_mismatch",
			"message": String(comparison.get("reason", "条件左右值类型不兼容")),
			"subsystem": "variables",
			"operation": "condition",
			"resource_kind": "variable",
			"resource_id": ("%" if persistent else "$") + variable_name,
		}
	return {
		"ok": true,
		"pc": instruction.true_pc() if bool(comparison.value) else instruction.false_pc(),
	}


func _condition_variable(host: KonadoDialogueManager, name: String, persistent: bool) -> Dictionary:
	var exists := (
		host.variable_store != null and host.variable_store.has(name)
		if persistent
		else host._temp_variables.has(name)
	)
	if exists:
		return {"ok": true, "value": host._read_variable(name, persistent)}
	var scope := "持久" if persistent else "临时"
	var prefix := "%" if persistent else "$"
	return {
		"ok": false,
		"code": "variable.not_found",
		"message": "找不到%s变量 '%s%s'" % [scope, prefix, name],
		"subsystem": "variables",
		"operation": "condition",
		"resource_kind": "variable",
		"resource_id": prefix + name,
	}


func _jump_script(
	host: KonadoDialogueManager, instruction: KonadoInstruction, token: Dictionary
) -> int:
	var path := String(instruction.value(&"path"))
	var shot := load(path) as KonadoShot
	if shot == null:
		return _failed(
			&"script.jump_load_failed",
			"无法加载 jump 目标 '%s'" % path,
			{
				"subsystem": "script",
				"operation": "jump",
				"resource_kind": "script",
				"resource_id": path,
			},
		)
	if not host._transition_to_shot(token, shot):
		if not host._token_is_active(token):
			return KonadoVirtualMachine.Result.CANCELLED
		return _failed_from_result(
			host._get_transition_failure(),
			_make_failure(
				&"script.jump_transition_failed",
				"无法切换到 jump 目标 '%s'" % path,
				{
					"subsystem": "script",
					"operation": "jump",
					"resource_kind": "script",
					"resource_id": path,
				},
			),
		)
	return KonadoVirtualMachine.Result.COMPLETED


func _camera_move(
	host: KonadoDialogueManager, instruction: KonadoInstruction, token: Dictionary
) -> int:
	if host.camera_controller == null:
		return _missing_controller("camera.move", "camera_controller")
	var accepted := host.camera_controller.move_to_marker(
		String(instruction.value(&"camera")),
		float(instruction.value(&"duration")),
		host._complete_instruction.bind(token),
		String(instruction.value(&"transition"))
	)
	if not accepted:
		return _camera_failed(&"camera.move_rejected", "camera.move", host, instruction)
	host._set_waiting_token(token)
	return KonadoVirtualMachine.Result.WAITING


func _camera_reset(
	host: KonadoDialogueManager, instruction: KonadoInstruction, token: Dictionary
) -> int:
	if host.camera_controller == null:
		return _missing_controller("camera.reset", "camera_controller")
	var accepted := host.camera_controller.reset_camera(
		true,
		float(instruction.value(&"duration")),
		host._complete_instruction.bind(token),
		String(instruction.value(&"transition"))
	)
	if not accepted:
		return _camera_failed(&"camera.reset_rejected", "camera.reset", host, instruction)
	host._set_waiting_token(token)
	return KonadoVirtualMachine.Result.WAITING


func _camera_shake(
	host: KonadoDialogueManager, instruction: KonadoInstruction, token: Dictionary
) -> int:
	if host.camera_controller == null:
		return _missing_controller("camera.shake", "camera_controller")
	var accepted := host.camera_controller.shake_camera(
		float(instruction.value(&"duration")), host._complete_instruction.bind(token)
	)
	if not accepted:
		return _camera_failed(&"camera.shake_rejected", "camera.shake", host, instruction)
	host._set_waiting_token(token)
	return KonadoVirtualMachine.Result.WAITING


func screen_text(
	host: KonadoDialogueManager, instruction: KonadoInstruction, token: Dictionary
) -> int:
	if host.screen_text == null:
		return _missing_controller("screen_text", "screen_text")
	var screen_text := host.screen_text
	var lines: PackedStringArray = instruction.value(&"lines")
	host._history_coordinator().stage_screen_text(token, instruction, lines)
	host._await_signal(screen_text.screen_text_hidden, token)
	screen_text.display(lines, "center", true)
	return KonadoVirtualMachine.Result.WAITING


func _textbox(
	host: KonadoDialogueManager, instruction: KonadoInstruction, token: Dictionary, show: bool
) -> int:
	if host.dialogue_box == null:
		return _missing_controller("textbox.show" if show else "textbox.hide", "dialogue_box")
	var completion := (
		host.dialogue_box.on_dialogue_show_completed
		if show
		else host.dialogue_box.on_dialogue_hide_completed
	)
	host._await_signal(completion, token)
	if show:
		host.dialogue_box.show_dialogue_box_with_duration(float(instruction.value(&"duration")))
	else:
		host.dialogue_box.dismiss_dialogue_box_with_duration(float(instruction.value(&"duration")))
	return KonadoVirtualMachine.Result.WAITING


func _make_failure(
	code: StringName, message: String, context: Dictionary = {}
) -> KonadoExecutionFailure:
	return KonadoExecutionFailure.new(code, message, _locate(code, context))


func _failed_from_result(result: Dictionary, fallback: KonadoExecutionFailure) -> int:
	var context := fallback.to_dictionary()
	# 最终错误码可能与兜底码不同：编号与检出位置必须按最终码重新解析，避免沿用兜底位置。
	for stale: String in ["error_id", "function", "owner"]:
		context.erase(stale)
	for key: String in [
		"subsystem",
		"operation",
		"resource_kind",
		"resource_id",
		"cause",
		"error_id",
		"function",
		"owner",
		"severity",
	]:
		if result.has(key) and not String(result[key]).is_empty():
			context[key] = result[key]
	return _failed(
		StringName(result.get("code", fallback.code)),
		String(result.get("message", fallback.message)),
		context,
	)


func _missing_controller(operation: String, controller: String) -> int:
	return _failed(
		&"runtime.controller_missing",
		"%s 未配置" % controller,
		{
			"subsystem": operation.get_slice(".", 0),
			"operation": operation,
			"resource_kind": "controller",
			"resource_id": controller,
		},
	)


func _achievement_result(result: Dictionary, operation: String, resource_id: String) -> int:
	if bool(result.get("ok", false)):
		return KonadoVirtualMachine.Result.COMPLETED
	return _failed_from_result(
		result,
		_make_failure(
			&"achievement.operation_failed",
			"成就操作失败：%s" % resource_id,
			{
				"subsystem": "achievement",
				"operation": operation,
				"resource_kind": "achievement",
				"resource_id": resource_id,
			},
		),
	)


func _actor_context(
	operation: String, actor_id: String, state_id := "", motion_name := ""
) -> Dictionary:
	var context := {
		"subsystem": "stage",
		"operation": operation,
		"resource_kind": "actor",
		"resource_id": actor_id,
	}
	if not state_id.is_empty():
		context["cause"] = "目标状态=%s" % state_id
	elif not motion_name.is_empty():
		context["cause"] = "目标动作=%s" % motion_name
	return context


func _actor_failure(
	code: StringName, operation: String, actor_id: String, state_id := "", motion_name := ""
) -> KonadoExecutionFailure:
	return _make_failure(
		code,
		"演员 '%s' 的操作 '%s' 执行失败" % [actor_id, operation],
		_actor_context(operation, actor_id, state_id, motion_name),
	)


func _audio_context(operation: String, resource_kind: String, resource_id: String) -> Dictionary:
	return {
		"subsystem": "audio",
		"operation": operation,
		"resource_kind": resource_kind,
		"resource_id": resource_id,
	}


func _camera_failed(
	code: StringName,
	operation: String,
	host: KonadoDialogueManager,
	instruction: KonadoInstruction,
) -> int:
	var marker_id := ""
	if instruction != null:
		marker_id = String(instruction.value(&"camera", ""))
	return _failed(
		code,
		host.camera_controller.get_last_error(),
		{
			"subsystem": "camera",
			"operation": operation,
			"resource_kind": "camera_marker" if not marker_id.is_empty() else "camera",
			"resource_id": marker_id,
		},
	)
