extends "res://tests/dialogue/dialogue_lifecycle_test_base.gd"


class VariableConfigHost:
	extends Control

	var manager: KonadoDialogueManager

	func _ready() -> void:
		manager.variable_store.set_value("love", 0)


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await _test_auto_start_waits_for_parent_configuration()
	await _test_missing_condition_variable_reports_its_name()
	await _test_failed_condition_can_retry_after_live_fix()
	await _test_failed_condition_requires_an_explicit_branch()
	await _test_reversible_linear_failure_can_be_skipped()
	await _test_barrier_failure_can_only_stop()
	await _test_failed_recovery_preflight_is_non_destructive()
	await _test_nested_condition_choice_reaches_branch()
	await _test_set_shot_and_complete_dialogue()
	await _test_empty_dialogue_line_can_advance()
	await _test_empty_dialogue_line_advances_in_autoplay()
	await _test_click_during_dialogue_box_show_does_not_skip_line()
	await _test_visibility_commands_are_atomic()
	await _test_screen_text_completion_lifecycle()
	await _test_replacement_clears_pending_screen_text()
	await _test_replacement_cancels_stale_typing()
	await _test_stop_cancels_all_pending_callbacks()
	await _test_committed_variable_can_rollback_while_waiting()
	await _test_checkpoint_restores_committed_boundary()
	await _test_execution_snapshot_restores_original_program()
	if _failures == 0:
		print("PASS: atomic dialogue lifecycle tests")
	quit(_failures)


func _test_auto_start_waits_for_parent_configuration() -> void:
	var host := VariableConfigHost.new()
	var manager := DIALOGUE_MANAGER_SCENE.instantiate() as KonadoDialogueManager
	manager.require_visible_in_tree = false
	manager.enable_overlay_log = false
	manager.auto_show_dialogue_box = false
	manager.typing_interval = 0.001
	manager.dialogue_box.enable_typing_effect_audio = false
	manager.start_dialogue_shot = _compile_shot(
		(
			"if %love <= 0:\n"
			+ '\t"Kona" "configured" [id=configured]\n'
			+ "else:\n"
			+ '\t"Kona" "wrong" [id=wrong]\n'
			+ "endif\nend"
		)
	)
	host.manager = manager
	host.add_child(manager)
	root.add_child(host)
	await _wait_for_instruction_and_state(
		manager, "ks:id:configured", KonadoDialogueManager.DialogState.WAITING
	)
	_expect_equal(
		manager.dialogue_box.dialogue_text,
		"configured",
		"automatic playback observes variables configured by the parent ready callback",
	)
	await _free_node(host)


func _test_missing_condition_variable_reports_its_name() -> void:
	var manager := await _create_manager()
	manager.set_shot(_compile_shot("if %missing == 1:\n\tend\nendif"))
	var result := manager._executor._condition_target(manager, manager._current_instruction())
	_expect(not bool(result.get("ok", false)), "an undefined condition variable is rejected")
	_expect(
		String(result.get("message", "")).contains("%missing"),
		"condition diagnostics identify the undefined variable instead of only naming the opcode",
	)
	_expect_equal(
		result.get("code"), "variable.not_found", "condition failures expose a stable error code"
	)
	_expect_equal(
		result.get("resource_id"),
		"%missing",
		"condition failures identify the exact variable resource",
	)
	await _free_node(manager)


func _test_failed_condition_can_retry_after_live_fix() -> void:
	var manager := await _create_manager()
	manager.report_runtime_failures_to_console = false
	var reports: Array[Dictionary] = []
	var resolutions: Array[Dictionary] = []
	manager.runtime_failure_reported.connect(
		func(report: Dictionary) -> void: reports.append(report)
	)
	manager.runtime_failure_resolved.connect(
		func(report: Dictionary, resolution: StringName) -> void:
			(
				resolutions
				. append(
					{
						"report": report,
						"resolution": resolution,
						"state": manager.dialogue_state,
					}
				)
			)
	)
	manager.set_shot(
		_compile_shot(
			(
				"if %love == 0:\n"
				+ '\t"Kona" "retry succeeded" [id=retry_succeeded]\n'
				+ "else:\n"
				+ '\t"Kona" "wrong branch" [id=wrong_branch]\n'
				+ "endif\nend"
			)
		)
	)
	manager.start_dialogue()
	await _wait_for_state(manager, KonadoDialogueManager.DialogState.FAILED)
	_expect_equal(
		manager.pending_runtime_failure.get("code"),
		"variable.not_found",
		"a failed instruction remains available as a structured paused failure",
	)
	var actions := (
		manager.pending_runtime_failure.get("recovery_actions", PackedStringArray())
		as PackedStringArray
	)
	_expect(&"retry" in actions, "a reversible condition can be retried")
	_expect(&"continue_false" in actions, "a failed condition exposes its false edge")
	_expect(&"continue_true" in actions, "a failed condition exposes its true edge")
	_expect(not (&"skip" in actions), "a condition never offers an ambiguous generic skip")
	_expect_equal(reports.size(), 1, "one failed instruction publishes one structured report")
	if not reports.is_empty():
		_expect(
			bool(reports[0].get("recoverable", false)),
			"the structured report declares a safely recoverable failure",
		)
		_expect_equal(
			reports[0].get("recovery_actions"),
			actions,
			"the structured report and the live recovery API expose the same actions",
		)
	manager.variable_store.set_value("love", 0)
	_expect(
		manager.resolve_runtime_failure(&"retry"),
		"retry accepts the live debugger correction",
	)
	_expect_equal(resolutions.size(), 1, "a successful recovery is reported exactly once")
	if not resolutions.is_empty():
		_expect_equal(resolutions[0].resolution, &"retry", "the resolution identifies Retry")
		_expect_equal(
			resolutions[0].state,
			KonadoDialogueManager.DialogState.EXECUTING,
			"resolution observers see the resumed state rather than the stale failure state",
		)
	await _wait_for_instruction_and_state(
		manager, "ks:id:retry_succeeded", KonadoDialogueManager.DialogState.WAITING
	)
	_expect_equal(
		manager.dialogue_box.dialogue_text,
		"retry succeeded",
		"retry re-executes the original condition against the corrected state",
	)
	await _free_node(manager)


func _test_failed_condition_requires_an_explicit_branch() -> void:
	var manager := await _create_manager()
	manager.report_runtime_failures_to_console = false
	manager.set_shot(
		_compile_shot(
			(
				"if %missing == 1:\n"
				+ '\t"Kona" "true branch" [id=true_branch]\n'
				+ "else:\n"
				+ '\t"Kona" "false branch" [id=false_branch]\n'
				+ "endif\nend"
			)
		)
	)
	manager.start_dialogue()
	await _wait_for_state(manager, KonadoDialogueManager.DialogState.FAILED)
	_expect(
		manager.resolve_runtime_failure(&"continue_false"),
		"the developer can explicitly select the false branch",
	)
	await _wait_for_instruction_and_state(
		manager, "ks:id:false_branch", KonadoDialogueManager.DialogState.WAITING
	)
	_expect_equal(
		manager.dialogue_box.dialogue_text,
		"false branch",
		"condition recovery commits the selected control-flow edge",
	)
	var history := manager.get_execution_history()
	_expect_equal(
		history[0].get("result"),
		KonadoVirtualMachine.Result.SKIPPED,
		"an explicitly bypassed condition is auditable in VM history",
	)
	await _free_node(manager)


func _test_reversible_linear_failure_can_be_skipped() -> void:
	var manager := await _create_manager()
	manager.report_runtime_failures_to_console = false
	manager.enable_overlay_log = true
	manager.set_shot(
		_compile_shot(
			(
				"actor change Ghost missing [id=missing_actor]\n"
				+ '"Kona" "continued" [id=continued]\nend'
			)
		)
	)
	manager.start_dialogue()
	await _wait_for_state(manager, KonadoDialogueManager.DialogState.FAILED)
	_expect(
		&"skip" in manager.pending_runtime_failure.get("recovery_actions", PackedStringArray()),
		"a reversible instruction with one successor exposes Skip",
	)
	_expect(manager.error_tooltip_panel.visible, "a recoverable failure opens the action overlay")
	var skip_button := manager.error_action_container.get_node_or_null("SkipInstruction") as Button
	_expect(skip_button != null, "the overlay exposes a deterministic Skip action")
	if skip_button != null:
		skip_button.pressed.emit()
	await _wait_for_instruction_and_state(
		manager, "ks:id:continued", KonadoDialogueManager.DialogState.WAITING
	)
	_expect(not manager.error_tooltip_panel.visible, "resuming hides the stale failure overlay")
	_expect_equal(
		manager.dialogue_box.dialogue_text,
		"continued",
		"Skip advances to the unique linear successor",
	)
	await _free_node(manager)


func _test_barrier_failure_can_only_stop() -> void:
	var manager := await _create_manager()
	manager.report_runtime_failures_to_console = false
	manager._achievement_manager = null
	manager.set_shot(_compile_shot('achievement unlock "missing" [id=barrier]\nend'))
	manager.start_dialogue()
	await _wait_for_state(manager, KonadoDialogueManager.DialogState.FAILED)
	_expect_equal(
		manager.pending_runtime_failure.get("recovery_actions", PackedStringArray()),
		PackedStringArray([&"stop"]),
		"an external-side-effect barrier never offers unsafe retry or skip actions",
	)
	_expect(
		not manager.resolve_runtime_failure(&"retry"),
		"an unsafe barrier cannot be retried",
	)
	_expect(
		manager.resolve_runtime_failure(&"stop"),
		"Stop safely settles an unrecoverable failure",
	)
	_expect_equal(
		manager.dialogue_state,
		KonadoDialogueManager.DialogState.OFF,
		"Stop leaves the manager in its final state",
	)
	await _free_node(manager)


func _test_failed_recovery_preflight_is_non_destructive() -> void:
	var manager := await _create_manager()
	manager.report_runtime_failures_to_console = false
	var resolutions: Array[StringName] = []
	manager.runtime_failure_resolved.connect(
		func(_failure: Dictionary, resolution: StringName) -> void: resolutions.append(resolution)
	)
	manager.set_shot(
		_compile_shot(
			(
				"if %missing == 1:\n"
				+ '\t"Kona" "unreachable" [id=unreachable]\n'
				+ "else:\n"
				+ '\t"Kona" "also unreachable" [id=also_unreachable]\n'
				+ "endif\nend"
			)
		)
	)
	manager.start_dialogue()
	await _wait_for_state(manager, KonadoDialogueManager.DialogState.FAILED)
	var original_failure := manager.pending_runtime_failure
	var suspended_token := manager._active_token.duplicate(true)
	var suspended_pc := manager._vm.pc
	manager._complete_instruction(suspended_token)
	(
		manager
		. _fail_current(
			KonadoExecutionFailure.new(&"runtime.stale_callback", "stale callback"),
			suspended_token,
		)
	)
	_expect_equal(
		manager.dialogue_state,
		KonadoDialogueManager.DialogState.FAILED,
		"late callbacks cannot commit a suspended failure token",
	)
	_expect_equal(manager._vm.pc, suspended_pc, "late callbacks cannot advance the failed PC")
	_expect_equal(
		manager.pending_runtime_failure.get("code"),
		original_failure.get("code"),
		"late failures cannot replace the original actionable report",
	)
	_expect(not manager.rollback(), "rollback rejects a failure without committed history")
	_expect_equal(
		manager.dialogue_state,
		KonadoDialogueManager.DialogState.FAILED,
		"a rejected rollback keeps the original failure suspended",
	)
	_expect_equal(
		manager.pending_runtime_failure.get("code"),
		original_failure.get("code"),
		"a rejected rollback preserves the actionable failure report",
	)
	_expect(
		not manager.restore_checkpoint("missing-checkpoint"),
		"checkpoint restore rejects an unknown checkpoint",
	)
	_expect_equal(
		manager.dialogue_state,
		KonadoDialogueManager.DialogState.FAILED,
		"a rejected checkpoint restore keeps the original failure suspended",
	)
	_expect_equal(resolutions.size(), 0, "preflight rejection does not publish a false resolution")
	manager.stop_dialogue()
	_expect_equal(
		manager.dialogue_state, KonadoDialogueManager.DialogState.OFF, "Stop remains final"
	)
	_expect(manager.pending_runtime_failure.is_empty(), "Stop clears the suspended failure")
	_expect_equal(resolutions, [&"stop"], "direct Stop settles the failure exactly once")
	await _free_node(manager)


func _test_nested_condition_choice_reaches_branch() -> void:
	var manager := await _create_manager()
	manager.set_shot(
		_compile_shot(
			(
				'choice "Right" -> right [id=main_choice]\n'
				+ "branch right\n"
				+ "\tset $right = 5\n"
				+ "\tif $right == 5:\n"
				+ '\t\tchoice "Back" -> no [id=nested_choice]\n'
				+ "\tendif\n"
				+ "\tend\n"
				+ "branch no\n"
				+ '\t"Kona" "returned" [id=returned]\n'
				+ "\tend"
			)
		)
	)
	manager.start_dialogue()
	await _wait_for_instruction_and_state(
		manager, "ks:id:main_choice", KonadoDialogueManager.DialogState.WAITING
	)
	var main_option: Dictionary = manager._current_instruction().value(&"options")[0]
	manager._on_option_triggered(main_option, manager._playback_generation)
	await _wait_for_instruction_and_state(
		manager, "ks:id:nested_choice", KonadoDialogueManager.DialogState.WAITING
	)
	var nested_option: Dictionary = manager._current_instruction().value(&"options")[0]
	manager._on_option_triggered(nested_option, manager._playback_generation)
	await _wait_for_instruction_and_state(
		manager, "ks:id:returned", KonadoDialogueManager.DialogState.WAITING
	)
	_expect_equal(
		manager.dialogue_box.dialogue_text,
		"returned",
		"a choice nested in a conditional branch resolves its compiled target",
	)
	await _free_node(manager)


func _test_set_shot_and_complete_dialogue() -> void:
	var manager := await _create_manager()
	var selected := _make_shot("selected")
	manager.set_shot(selected)
	manager.start_dialogue()
	await _wait_for_state(manager, KonadoDialogueManager.DialogState.WAITING)
	_expect_equal(manager.start_dialogue_shot, selected, "SetShot stores the selected source")
	_expect_equal(
		manager.dialogue_box.dialogue_text,
		"selected",
		"Program dialogue reaches the dialogue box",
	)
	await _finish_current_dialogue(manager)
	await _wait_for_state(manager, KonadoDialogueManager.DialogState.OFF)
	_expect(not manager._shot_active, "HALT closes the session exactly once")
	await _free_node(manager)


func _test_empty_dialogue_line_can_advance() -> void:
	var manager := await _create_manager()
	manager.set_shot(_compile_shot('"Kona" "" [id=empty]\n"Kona" "L1" [id=l1]\nend'))
	manager.start_dialogue()
	await _wait_for_instruction_and_state(
		manager, "ks:id:empty", KonadoDialogueManager.DialogState.WAITING
	)
	_expect(not manager._dialogue_typing, "an empty line has no typing animation to wait for")
	await _finish_current_dialogue(manager)
	await _wait_for_instruction_and_state(
		manager, "ks:id:l1", KonadoDialogueManager.DialogState.WAITING
	)
	_expect_equal(manager.dialogue_box.dialogue_text, "L1", "the next line is reached")
	await _free_node(manager)


## 空台词在自动播放模式下也必须排入自动推进，而不是停在空行等待点击。
func _test_empty_dialogue_line_advances_in_autoplay() -> void:
	var manager := await _create_manager()
	manager.autoplay = true
	manager.auto_play_delay = 0.05
	var started_keys: Array[String] = []
	manager.dialogue_line_start.connect(
		func(instruction_id: String) -> void: started_keys.append(instruction_id)
	)
	manager.set_shot(_compile_shot('"Kona" "" [id=empty]\n"Kona" "L1" [id=l1]\nend'))
	manager.start_dialogue()
	await _wait_for_condition(
		func() -> bool: return manager.dialogue_state == KonadoDialogueManager.DialogState.OFF,
		"autoplay reaches the end of the shot without manual input",
	)
	_expect("ks:id:empty" in started_keys, "autoplay starts the empty line")
	_expect("ks:id:l1" in started_keys, "autoplay advances past the empty line")
	_expect(not manager._shot_active, "the shot finishes without manual input")
	await _free_node(manager)


## 对话框淡入期间点击不能提前完成尚未显示的台词。
func _test_click_during_dialogue_box_show_does_not_skip_line() -> void:
	var manager := await _create_manager()
	manager.auto_show_dialogue_box = true
	manager.dialogue_box.fade_duration = 1.0
	manager.dialogue_box.reset_dialogue_box()
	manager.set_shot(_compile_shot('"Kona" "L1" [id=l1]\n"Kona" "L2" [id=l2]\nend'))
	manager.start_dialogue()
	await _wait_for_instruction_and_state(
		manager, "ks:id:l1", KonadoDialogueManager.DialogState.WAITING
	)
	_expect(manager._dialogue_typing, "the line is pending while the dialogue box fades in")
	_expect_equal(manager.dialogue_box.dialogue_text, "", "the line is not shown before the fade")
	manager._process_next()
	await _wait_for_condition(
		func() -> bool: return manager.dialogue_box.dialogue_text == "L1",
		"the dialogue box finishes its show transition",
	)
	_expect_equal(
		manager._current_instruction().stable_key(),
		"ks:id:l1",
		"a click during the show transition does not advance the line",
	)
	_expect_equal(manager.dialogue_box.dialogue_text, "L1", "the first line stays displayed")
	await _finish_current_dialogue(manager)
	await _wait_for_instruction_and_state(
		manager, "ks:id:l2", KonadoDialogueManager.DialogState.WAITING
	)
	await _free_node(manager)


func _test_visibility_commands_are_atomic() -> void:
	var manager := await _create_manager()
	manager.set_shot(_make_visibility_shot("visibility", "Kona", "line", 0.0))
	manager.start_dialogue()
	await _wait_for_instruction_and_state(
		manager, "ks:id:line_visibility", KonadoDialogueManager.DialogState.WAITING
	)
	_expect(manager.dialogue_box.is_dialogue_box_visible(), "showtextbox commits first")
	await _finish_current_dialogue(manager)
	await _wait_for_state(manager, KonadoDialogueManager.DialogState.OFF)
	_expect(
		not manager.dialogue_box.is_dialogue_box_visible(),
		"hidetextbox finishes before HALT",
	)
	_expect(manager.get_execution_history().size() >= 3, "visibility actions enter VM history")
	await _free_node(manager)


func _test_screen_text_completion_lifecycle() -> void:
	var manager := await _create_manager()
	manager.screen_text.fade_duration = 0.0
	manager.screen_text.line_fade_duration = 0.0
	var events: Array[String] = []
	manager.screen_text.display_finished.connect(func() -> void: events.append("display_finished"))
	manager.screen_text.screen_text_hidden.connect(
		func() -> void: events.append("screen_text_hidden")
	)
	manager.set_shot(
		_compile_shot(
			(
				'screentext {\n    "Opening"\n} [id=overlay]\n'
				+ '"Kona" "After overlay" [id=after_overlay]\nend'
			)
		)
	)
	manager.start_dialogue()
	await _wait_for_instruction_and_state(
		manager, "ks:id:overlay", KonadoDialogueManager.DialogState.WAITING
	)
	await _wait_for_condition(
		func() -> bool: return manager.screen_text._is_waiting_input,
		"screen text waits for the final acknowledgement",
	)
	manager.screen_text._on_click_advance()
	manager.screen_text.skip_display()
	manager.screen_text.skip_display()
	await _wait_for_instruction_and_state(
		manager, "ks:id:after_overlay", KonadoDialogueManager.DialogState.WAITING
	)
	_expect_equal(
		events,
		["display_finished", "screen_text_hidden"],
		"screen text completes and hides exactly once before the next instruction",
	)
	_expect(not manager.screen_text.visible, "the following instruction starts without an overlay")
	await _finish_current_dialogue(manager)
	await _wait_for_state(manager, KonadoDialogueManager.DialogState.OFF)

	manager.screen_text.next_line_indicator = null
	manager.screen_text.display(["Manual overlay"])
	await _wait_for_condition(
		func() -> bool: return manager.screen_text._is_waiting_input,
		"screen text remains interactive without an optional next-line indicator",
	)
	manager.screen_text._on_click_advance()
	await process_frame
	_expect(manager.screen_text.visible, "direct display calls keep their existing visible default")
	_expect_equal(events.count("display_finished"), 2, "direct display completion emits once")
	_expect_equal(events.count("screen_text_hidden"), 1, "direct display does not auto-hide")
	manager.screen_text.hide_screen_text()
	manager.screen_text.show_screen_text()
	await process_frame
	manager.screen_text.hide_screen_text()
	await _wait_for_condition(
		func() -> bool: return not manager.screen_text.visible,
		"an interrupted hide can be shown again and hidden explicitly",
	)
	await _free_node(manager)


func _test_replacement_clears_pending_screen_text() -> void:
	var manager := await _create_manager()
	manager.screen_text.fade_duration = 0.0
	manager.screen_text.line_fade_duration = 0.0
	manager.set_shot(_compile_shot('screentext {\n    "Old overlay"\n}\nend'))
	manager.start_dialogue()
	await _wait_for_condition(
		func() -> bool: return manager.screen_text._is_waiting_input,
		"the original screen text starts before replacement",
	)
	manager.set_shot(_compile_shot('"Kona" "Replacement" [id=replacement]\nend'))
	manager.start_dialogue()
	await _wait_for_instruction_and_state(
		manager, "ks:id:replacement", KonadoDialogueManager.DialogState.WAITING
	)
	_expect(
		not manager.screen_text.visible,
		"replacing a shot clears its uncommitted screen text overlay",
	)
	await _free_node(manager)


func _test_replacement_cancels_stale_typing() -> void:
	var manager := await _create_manager()
	manager.typing_interval = 1.0
	manager.set_shot(_make_shot("old text that must not finish"))
	manager.start_dialogue()
	await _wait_for_state(manager, KonadoDialogueManager.DialogState.WAITING)
	manager.set_shot(_compile_shot('"Kona" "replacement" [id=replacement]\nend'))
	manager.start_dialogue()
	await _wait_for_instruction_and_state(
		manager, "ks:id:replacement", KonadoDialogueManager.DialogState.WAITING
	)
	_expect_equal(
		manager.dialogue_box.dialogue_text,
		"replacement",
		"a replaced instruction cannot publish stale text",
	)
	_expect_equal(
		manager.dialogue_box.typing_completed.get_connections().size(),
		1,
		"replacement owns one completion callback",
	)
	await _free_node(manager)


func _test_stop_cancels_all_pending_callbacks() -> void:
	var manager := await _create_manager()
	manager.typing_interval = 1.0
	manager.set_shot(_make_shot("pending"))
	manager.start_dialogue()
	await _wait_for_state(manager, KonadoDialogueManager.DialogState.WAITING)
	manager.stop_dialogue()
	_expect_equal(manager.dialogue_state, KonadoDialogueManager.DialogState.OFF, "stop is final")
	_expect(manager._active_token.is_empty(), "stop invalidates the active transaction")
	_expect(
		manager._instruction_awaiter == null or manager._instruction_awaiter.pending_count() == 0,
		"stop disconnects awaited signals",
	)
	_expect_equal(
		manager.dialogue_box.typing_completed.get_connections().size(),
		0,
		"stop disconnects the typewriter callback",
	)
	await _free_node(manager)


func _test_committed_variable_can_rollback_while_waiting() -> void:
	var manager := await _create_manager()
	var source := 'set $score = 7 [id=set_score]\n"Kona" "pause" [id=pause]\nend'
	manager.set_shot(_compile_shot(source))
	manager.start_dialogue()
	await _wait_for_instruction_and_state(
		manager, "ks:id:pause", KonadoDialogueManager.DialogState.WAITING
	)
	_expect_equal(manager._temp_variables.get("score"), 7, "variable instruction committed")
	_expect(manager.can_rollback(), "waiting transaction can be cancelled for rollback")
	_expect(manager.rollback(), "rollback restores the previous committed boundary")
	await process_frame
	_expect_equal(
		manager._temp_variables.get("score"),
		7,
		"rollback resumes by deterministically re-executing the restored instruction",
	)
	await _free_node(manager)


func _test_checkpoint_restores_committed_boundary() -> void:
	var manager := await _create_manager()
	(
		manager
		. set_shot(
			_compile_shot(
				'set $score = 1\n"Kona" "first" [id=first]\nset $score = 2\n"Kona" "second" [id=second]\nend',
				"",
			)
		)
	)
	manager.start_dialogue()
	await _wait_for_instruction_and_state(
		manager, "ks:id:first", KonadoDialogueManager.DialogState.WAITING
	)
	var checkpoint := manager.create_checkpoint("first-line")
	_expect(not checkpoint.is_empty(), "checkpoint is created at a valid instruction")
	await _finish_current_dialogue(manager)
	await _wait_for_instruction_and_state(
		manager, "ks:id:second", KonadoDialogueManager.DialogState.WAITING
	)
	_expect_equal(manager._temp_variables.get("score"), 2, "execution advances after checkpoint")
	_expect(manager.restore_checkpoint(checkpoint), "checkpoint restore succeeds")
	await _wait_for_instruction_and_state(
		manager, "ks:id:first", KonadoDialogueManager.DialogState.WAITING
	)
	_expect_equal(manager._temp_variables.get("score"), 1, "checkpoint restores logical state")
	await _free_node(manager)


func _test_execution_snapshot_restores_original_program() -> void:
	var manager := await _create_manager()
	var original := load("res://tests/localization/fixtures/story.ks") as KonadoShot
	var replacement := load("res://tests/editor/fixtures/native_editor.ks") as KonadoShot
	_expect(original != null and replacement != null, "snapshot fixtures import as KonadoShot")
	if original == null or replacement == null:
		await _free_node(manager)
		return
	manager.set_shot(original)
	var original_fingerprint := manager.current_shot.program_fingerprint()
	var snapshot := manager._capture_execution_snapshot()
	_expect(not snapshot.is_empty(), "timeline captures a portable execution snapshot")
	manager.set_shot(replacement)
	_expect(
		manager.current_shot.program_fingerprint() != original_fingerprint,
		"snapshot fixture replaces the active Program before restoration",
	)
	_expect(manager._restore_execution_snapshot(snapshot), "timeline restores a valid snapshot")
	_expect_equal(
		manager.current_shot.program_fingerprint(),
		original_fingerprint,
		"snapshot restoration reinstalls the original Program",
	)
	manager.stop_dialogue()
	await _free_node(manager)
