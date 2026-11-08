extends "res://tests/dialogue/dialogue_lifecycle_test_base.gd"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await _test_step_back_lands_on_previous_line_without_flash()
	await _test_repeated_step_back_until_exhausted()
	await _test_signal_is_crossed_and_replayed_with_a_variable_handler()
	await _test_step_back_crosses_achievement_commands()
	await _test_replayed_barrier_commands_keep_their_count()
	await _test_step_back_crosses_cancellable_async_camera()
	await _test_step_back_redraws_choice_and_records_new_selection()
	await _test_step_back_past_a_choice_dismisses_the_option_buttons()
	await _test_step_back_from_a_choice_skips_the_adjacent_line()
	await _test_step_back_restores_variables_written_by_a_chosen_option()
	await _test_rollback_then_save_keeps_persistent_variables_consistent()
	await _test_rollback_to_backlog_entry()
	await _test_step_back_redraws_screen_text()
	await _test_step_back_restores_scene_from_snapshot()
	await _test_step_back_restores_actor_state()
	await _test_step_back_restores_background()
	await _test_step_back_crosses_jump_between_scripts()
	_test_snapshot_store_is_bounded()
	_test_cleared_history_drops_armed_rewind_skips()
	_test_every_presentation_command_is_reversible()
	if _failures == 0:
		print("PASS: dialogue rollback tests")
	quit(_failures)


func _test_step_back_lands_on_previous_line_without_flash() -> void:
	var manager := await _create_manager()
	manager.set_shot(
		_compile_shot('"Kona" "L1" [id=l1]\nset $n = 1 [id=set]\n"Kona" "L2" [id=l2]\nend')
	)
	manager.start_dialogue()
	await _wait_for_instruction_and_state(
		manager, "ks:id:l1", KonadoDialogueManager.DialogState.WAITING
	)
	await _finish_current_dialogue(manager)
	await _wait_for_instruction_and_state(
		manager, "ks:id:l2", KonadoDialogueManager.DialogState.WAITING
	)
	_expect(manager.timeline.can_step_back(), "a previous line is reachable")
	_expect(manager.timeline.step_back(), "step back succeeds across a variable")
	# 同步重放：同一帧内对话框已是目标句，证明没有闪出更早的一帧。
	_expect_equal(
		manager.dialogue_box.dialogue_text,
		"L1",
		"the target line is rendered synchronously in the same frame",
	)
	_expect_equal(
		manager._current_instruction().stable_key(),
		"ks:id:l1",
		"the current instruction is the previous line",
	)
	_expect_equal(
		manager.dialogue_state,
		KonadoDialogueManager.DialogState.WAITING,
		"the restored timeline is live and waiting for input",
	)
	await _free_node(manager)


func _test_repeated_step_back_until_exhausted() -> void:
	var manager := await _create_manager()
	manager.set_shot(
		_compile_shot('"Kona" "L1" [id=l1]\n"Kona" "L2" [id=l2]\n"Kona" "L3" [id=l3]\nend')
	)
	manager.start_dialogue()
	await _wait_for_instruction_and_state(
		manager, "ks:id:l1", KonadoDialogueManager.DialogState.WAITING
	)
	await _finish_current_dialogue(manager)
	await _wait_for_instruction_and_state(
		manager, "ks:id:l2", KonadoDialogueManager.DialogState.WAITING
	)
	await _finish_current_dialogue(manager)
	await _wait_for_instruction_and_state(
		manager, "ks:id:l3", KonadoDialogueManager.DialogState.WAITING
	)
	_expect(manager.timeline.step_back(), "first step back reaches L2")
	_expect_equal(manager.dialogue_box.dialogue_text, "L2", "landed on L2")
	_expect(manager.timeline.step_back(), "second step back reaches L1")
	_expect_equal(manager.dialogue_box.dialogue_text, "L1", "landed on L1")
	_expect(not manager.timeline.can_step_back(), "no earlier line remains")
	_expect(not manager.timeline.step_back(), "step back is refused when exhausted")
	await _free_node(manager)


## signal 是可重放的一次性副作用：回退跨越它，重放到该指令时重新发射。
## 处理函数只改快照内的脚本变量时，回退 + 重放的结果与“全新播一次”完全一致。
func _test_signal_is_crossed_and_replayed_with_a_variable_handler() -> void:
	var manager := await _create_manager()
	var emissions: Array[String] = []
	manager.custom_signal.connect(
		func(content: String) -> void:
			emissions.append(content)
			manager.variable_store.apply_operation("love", KonadoVariableStore.Operation.ADD, 1)
	)
	manager.set_shot(
		_compile_shot(
			(
				"set %love = 0\n"
				+ '"Kona" "L0" [id=l0]\n'
				+ "signal marker\n"
				+ '"Kona" "L1" [id=l1]\n'
				+ "end"
			)
		)
	)
	manager.start_dialogue()
	await _wait_for_instruction_and_state(
		manager, "ks:id:l0", KonadoDialogueManager.DialogState.WAITING
	)
	await _finish_current_dialogue(manager)
	await _wait_for_instruction_and_state(
		manager, "ks:id:l1", KonadoDialogueManager.DialogState.WAITING
	)
	_expect_equal(emissions.size(), 1, "the signal fires once on the first pass")
	_expect_equal(manager.variable_store.get_int("love"), 1, "the handler applied its change")
	_expect(manager.timeline.can_step_back(), "a signal does not block a rewind")
	_expect(manager.timeline.step_back(), "step back crosses the signal command")
	_expect_equal(manager.dialogue_box.dialogue_text, "L0", "landed on the previous line")
	_expect_equal(
		manager.variable_store.get_int("love"), 0, "the handler change is rolled back with the line"
	)
	await _finish_current_dialogue(manager)
	await _wait_for_instruction_and_state(
		manager, "ks:id:l1", KonadoDialogueManager.DialogState.WAITING
	)
	_expect_equal(emissions.size(), 2, "the signal is re-emitted on the replayed path")
	_expect_equal(
		manager.variable_store.get_int("love"),
		1,
		"replaying the handler applies its effect exactly once",
	)
	await _free_node(manager)


func _test_step_back_crosses_achievement_commands() -> void:
	var manager := await _create_manager()
	manager.set_shot(
		_compile_shot(
			(
				'Kona "L1" [id=l1]\n'
				+ 'achievement unlock "first_blood"\n'
				+ 'achievement increment "explorer" 1\n'
				+ "set $x = 1 [id=set]\n"
				+ 'Kona "L2" [id=l2]\n'
				+ "end"
			)
		)
	)
	manager.start_dialogue()
	await _wait_for_instruction_and_state(
		manager, "ks:id:l1", KonadoDialogueManager.DialogState.WAITING
	)
	await _finish_current_dialogue(manager)
	await _wait_for_instruction_and_state(
		manager, "ks:id:l2", KonadoDialogueManager.DialogState.WAITING
	)
	_expect(manager.timeline.can_step_back(), "achievement commands do not block a rewind")
	_expect(manager.timeline.step_back(), "step back crosses achievement commands")
	_expect_equal(manager.dialogue_box.dialogue_text, "L1", "landed on the previous line")
	await _free_node(manager)


## 同一条成就指令在回退区间内执行多次时，重放必须按次数跳过，
## 不能只跳过第一次而让后续执行再次累加进度。
func _test_replayed_barrier_commands_keep_their_count() -> void:
	var manager := await _create_manager()
	var achievement_manager: Node = manager._achievement_manager
	_expect(achievement_manager != null, "the achievement autoload is available")
	if achievement_manager == null:
		await _free_node(manager)
		return
	manager.set_shot(
		_compile_shot(
			(
				"set %i = 0\n"
				+ '"Kona" "L0" [id=l0]\n'
				+ "jump_branch loop\n"
				+ "branch loop\n"
				+ '\tachievement increment "explorer" 1\n'
				+ "\tadd %i 1\n"
				+ "\tif %i < 2:\n"
				+ "\t\tjump_branch loop\n"
				+ "\tendif\n"
				+ '\t"Kona" "L1" [id=l1]\n'
				+ "\tend"
			)
		)
	)
	manager.start_dialogue()
	await _wait_for_instruction_and_state(
		manager, "ks:id:l0", KonadoDialogueManager.DialogState.WAITING
	)
	var baseline := float(achievement_manager.get_progress("explorer"))
	await _finish_current_dialogue(manager)
	await _wait_for_instruction_and_state(
		manager, "ks:id:l1", KonadoDialogueManager.DialogState.WAITING
	)
	_expect_equal(
		achievement_manager.get_progress("explorer") - baseline,
		2.0,
		"the loop applies its progress twice",
	)
	_expect(manager.timeline.step_back(), "step back across the loop succeeds")
	await _wait_for_instruction_and_state(
		manager, "ks:id:l0", KonadoDialogueManager.DialogState.WAITING
	)
	await _finish_current_dialogue(manager)
	await _wait_for_instruction_and_state(
		manager, "ks:id:l1", KonadoDialogueManager.DialogState.WAITING
	)
	_expect_equal(
		achievement_manager.get_progress("explorer") - baseline,
		2.0,
		"replaying the loop does not add progress again",
	)
	await _free_node(manager)


## 异步相机只改相机变换，属于快照可逆状态：回退要取消进行中的 Tween 并还原变换，
## 继续前进时 asyncam 必须重新执行（而不是被当成不可逆副作用永久跳过）。
func _test_step_back_crosses_cancellable_async_camera() -> void:
	var manager := await _create_manager()
	var camera := _attach_camera_marker(manager, Vector2(900.0, 900.0))
	manager.set_shot(
		_compile_shot(
			(
				'"Kona" "L0" [id=l0]\n'
				+ "asyncam move cam1 linear 1.0\n"
				+ '"Kona" "L1" [id=l1]\n'
				+ "end"
			)
		)
	)
	manager.start_dialogue()
	await _wait_for_instruction_and_state(
		manager, "ks:id:l0", KonadoDialogueManager.DialogState.WAITING
	)
	var baseline := camera.position
	await _finish_current_dialogue(manager)
	await _wait_for_instruction_and_state(
		manager, "ks:id:l1", KonadoDialogueManager.DialogState.WAITING
	)
	await _wait_for_frames(12)
	_expect(
		camera.position != baseline,
		"the asynchronous camera move runs in the background while the line is displayed"
	)
	_expect(
		manager.timeline.can_step_back(),
		"a cancellable async camera command does not block stepping back",
	)
	_expect(manager.timeline.step_back(), "step back crosses cancellable async camera work")
	_expect_equal(manager.dialogue_box.dialogue_text, "L0", "landed on the previous line")
	_expect_equal(camera.position, baseline, "the in-flight camera tween is cancelled and restored")
	await _finish_current_dialogue(manager)
	await _wait_for_instruction_and_state(
		manager, "ks:id:l1", KonadoDialogueManager.DialogState.WAITING
	)
	await _wait_for_frames(12)
	_expect(
		camera.position != baseline,
		"the async camera command runs again after the rewind instead of being skipped",
	)
	await _free_node(manager)


func _test_step_back_redraws_choice_and_records_new_selection() -> void:
	var manager := await _create_manager()
	manager.set_shot(
		_compile_shot(
			(
				'choice "Tea" -> tea [id=drink]\n'
				+ 'choice "Coffee" -> coffee\n'
				+ "branch tea\n"
				+ '\t"Kona" "tea" [id=tea_line]\n'
				+ "\tend\n"
				+ "branch coffee\n"
				+ '\t"Kona" "coffee" [id=coffee_line]\n'
				+ "\tend"
			)
		)
	)
	manager.start_dialogue()
	await _wait_for_instruction_and_state(
		manager, "ks:id:drink", KonadoDialogueManager.DialogState.WAITING
	)
	manager._on_option_triggered(
		manager._current_instruction().value(&"options")[0], manager._playback_generation
	)
	await _wait_for_instruction_and_state(
		manager, "ks:id:tea_line", KonadoDialogueManager.DialogState.WAITING
	)
	_expect_equal(
		manager.dialogue_history.entries(0, false)[0]["text"],
		"Tea",
		"the first selection is recorded"
	)
	_expect(manager.timeline.step_back(), "step back reaches the choice")
	_expect_equal(
		manager._current_instruction().opcode(),
		KonadoOpcode.Type.CHOICE,
		"the choice instruction is replayed",
	)
	_expect_equal(
		manager._current_instruction().value(&"options").size(),
		2,
		"both options are presented again",
	)
	_expect_equal(
		manager.dialogue_history.entries(0, false).size(),
		0,
		"the abandoned selection is trimmed from the history",
	)
	manager._on_option_triggered(
		manager._current_instruction().value(&"options")[1], manager._playback_generation
	)
	await _wait_for_instruction_and_state(
		manager, "ks:id:coffee_line", KonadoDialogueManager.DialogState.WAITING
	)
	var history := manager.dialogue_history.entries(0, false)
	_expect_equal(history.size(), 1, "the new selection is recorded once")
	_expect_equal(history[0]["kind"], "choice", "the new entry is a choice")
	_expect_equal(history[0]["text"], "Coffee", "the new selection is recorded verbatim")
	await _free_node(manager)


## 从选项退回更早的台词时，重新绘制的选项按钮必须被关闭，不能残留在画面上。
func _test_step_back_past_a_choice_dismisses_the_option_buttons() -> void:
	var manager := await _create_manager()
	manager.set_shot(
		_compile_shot(
			(
				'"Kona" "L0" [id=l0]\n'
				+ 'choice "Tea" -> tea [id=drink]\n'
				+ 'choice "Coffee" -> coffee\n'
				+ "branch tea\n"
				+ '\t"Kona" "tea" [id=tea_line]\n'
				+ "\tend\n"
				+ "branch coffee\n"
				+ '\t"Kona" "coffee" [id=coffee_line]\n'
				+ "\tend"
			)
		)
	)
	manager.start_dialogue()
	await _wait_for_instruction_and_state(
		manager, "ks:id:l0", KonadoDialogueManager.DialogState.WAITING
	)
	await _finish_current_dialogue(manager)
	await _wait_for_instruction_and_state(
		manager, "ks:id:drink", KonadoDialogueManager.DialogState.WAITING
	)
	manager._on_option_triggered(
		manager._current_instruction().value(&"options")[0], manager._playback_generation
	)
	await _wait_for_instruction_and_state(
		manager, "ks:id:tea_line", KonadoDialogueManager.DialogState.WAITING
	)
	_expect(manager.timeline.step_back(), "step back reaches the choice again")
	_expect_equal(
		manager._current_instruction().stable_key(), "ks:id:drink", "the choice is replayed"
	)
	_expect_equal(_visible_choice_buttons(manager), 2, "the choice options are redrawn")
	_expect(manager.timeline.step_back(), "step back goes past the choice")
	_expect_equal(
		manager.dialogue_box.dialogue_text, "L0", "landed on the dialogue before the choice"
	)
	_expect(
		not manager.choice_controller._choice_container.visible,
		"the option container is hidden again",
	)
	_expect_equal(_visible_choice_buttons(manager), 0, "no option button is left visible")
	await _free_node(manager)


func _visible_choice_buttons(manager: KonadoDialogueManager) -> int:
	var container := manager.choice_controller._choice_container
	var visible_count := 0
	for child in container.get_children():
		if child.visible:
			visible_count += 1
	return visible_count


## 选项展示时它旁边那句台词仍在屏幕上：从选项回退必须一次点击就回到更早的一句，
## 不能停在“画面没有任何变化”的那一句上；同时从选项之后的台词回退仍要回到选项（可改选）。
func _test_step_back_from_a_choice_skips_the_adjacent_line() -> void:
	var manager := await _create_manager()
	manager.set_shot(
		_compile_shot(
			(
				'"Kona" "L0" [id=l0]\n'
				+ '"Kona" "L1" [id=l1]\n'
				+ 'choice "Tea" -> tea [id=drink]\n'
				+ 'choice "Coffee" -> coffee\n'
				+ "branch tea\n"
				+ '\t"Kona" "tea" [id=tea_line]\n'
				+ "\tend\n"
				+ "branch coffee\n"
				+ '\t"Kona" "coffee" [id=coffee_line]\n'
				+ "\tend"
			)
		)
	)
	manager.start_dialogue()
	await _wait_for_instruction_and_state(
		manager, "ks:id:l0", KonadoDialogueManager.DialogState.WAITING
	)
	await _finish_current_dialogue(manager)
	await _wait_for_instruction_and_state(
		manager, "ks:id:l1", KonadoDialogueManager.DialogState.WAITING
	)
	await _finish_current_dialogue(manager)
	await _wait_for_instruction_and_state(
		manager, "ks:id:drink", KonadoDialogueManager.DialogState.WAITING
	)
	_expect_equal(
		manager.dialogue_box.dialogue_text, "L1", "the question line stays behind the options"
	)
	_expect(manager.timeline.step_back(), "step back from the choice")
	_expect_equal(
		manager._current_instruction().stable_key(),
		"ks:id:l0",
		"one step reaches the line before the question",
	)
	_expect_equal(manager.dialogue_box.dialogue_text, "L0", "the text actually changed")
	await _finish_current_dialogue(manager)
	await _wait_for_instruction_and_state(
		manager, "ks:id:l1", KonadoDialogueManager.DialogState.WAITING
	)
	await _finish_current_dialogue(manager)
	await _wait_for_instruction_and_state(
		manager, "ks:id:drink", KonadoDialogueManager.DialogState.WAITING
	)
	manager._on_option_triggered(
		manager._current_instruction().value(&"options")[0], manager._playback_generation
	)
	await _wait_for_instruction_and_state(
		manager, "ks:id:tea_line", KonadoDialogueManager.DialogState.WAITING
	)
	_expect(manager.timeline.step_back(), "step back from the branch line reaches the choice")
	_expect_equal(
		manager._current_instruction().stable_key(), "ks:id:drink", "the choice can be re-picked"
	)
	_expect_equal(_visible_choice_buttons(manager), 2, "the options are presented again")
	_expect(manager.timeline.step_back(), "step back from the choice again")
	_expect_equal(
		manager._current_instruction().stable_key(),
		"ks:id:l0",
		"the question line is skipped from the choice as well",
	)
	await _free_node(manager)


## 选项分支里的变量写入必须随回退一起撤销：既不能残留，也不能重复累加。
## 持久变量（%）与临时变量（$）都在快照域内，恢复时整体替换。
func _test_step_back_restores_variables_written_by_a_chosen_option() -> void:
	var manager := await _create_manager()
	manager.set_shot(
		_compile_shot(
			(
				"set %love = 0\n"
				+ "set $seen = 0\n"
				+ '"Kona" "L1" [id=l1]\n'
				+ 'choice "A" -> a [id=drink]\n'
				+ 'choice "B" -> b\n'
				+ "branch a\n"
				+ "\tadd %love 1\n"
				+ "\tset $seen = 1\n"
				+ '\t"Kona" "A" [id=line_a]\n'
				+ "\tend\n"
				+ "branch b\n"
				+ "\tadd %love 5\n"
				+ '\t"Kona" "B" [id=line_b]\n'
				+ "\tend"
			)
		)
	)
	manager.start_dialogue()
	await _wait_for_instruction_and_state(
		manager, "ks:id:l1", KonadoDialogueManager.DialogState.WAITING
	)
	_expect_equal(
		manager.variable_store.get_int("love"), 0, "the persistent variable starts at zero"
	)
	await _finish_current_dialogue(manager)
	await _wait_for_instruction_and_state(
		manager, "ks:id:drink", KonadoDialogueManager.DialogState.WAITING
	)
	manager._on_option_triggered(
		manager._current_instruction().value(&"options")[0], manager._playback_generation
	)
	await _wait_for_instruction_and_state(
		manager, "ks:id:line_a", KonadoDialogueManager.DialogState.WAITING
	)
	_expect_equal(
		manager.variable_store.get_int("love"), 1, "the chosen option applied its change once"
	)
	_expect_equal(int(manager._temp_variables.get("seen", -1)), 1, "the temporary variable is set")
	_expect(manager.timeline.step_back(), "step back reaches the choice")
	_expect_equal(
		manager.variable_store.get_int("love"), 0, "the persistent variable is rolled back"
	)
	_expect_equal(
		int(manager._temp_variables.get("seen", -1)), 0, "the temporary variable is rolled back"
	)
	_expect_equal(_visible_choice_buttons(manager), 2, "the options are presented again")
	# 重新选择同一个选项：只能再记一次，不能把上一次的 +1 留在里面。
	manager._on_option_triggered(
		manager._current_instruction().value(&"options")[0], manager._playback_generation
	)
	await _wait_for_instruction_and_state(
		manager, "ks:id:line_a", KonadoDialogueManager.DialogState.WAITING
	)
	_expect_equal(
		manager.variable_store.get_int("love"), 1, "re-picking the same option applies once"
	)
	_expect(manager.timeline.step_back(), "step back reaches the choice a second time")
	_expect_equal(
		manager.variable_store.get_int("love"), 0, "the second selection is rolled back too"
	)
	# 改选另一支：只保留新分支的效果。
	manager._on_option_triggered(
		manager._current_instruction().value(&"options")[1], manager._playback_generation
	)
	await _wait_for_instruction_and_state(
		manager, "ks:id:line_b", KonadoDialogueManager.DialogState.WAITING
	)
	_expect_equal(
		manager.variable_store.get_int("love"), 5, "the new selection applies exactly once"
	)
	await _free_node(manager)


## 回退与存档必须一致：存档写入的是回退后的状态，读档后持久变量与执行位置都对得上，
## 且读档清空了内存执行历史（回退随之不可用，直到重新读到新行）。
func _test_rollback_then_save_keeps_persistent_variables_consistent() -> void:
	var loader := KonadoScriptResourceLoader.new()
	ResourceLoader.add_resource_format_loader(loader, true)
	var dir := "res://tests/dialogue/fixtures"
	DirAccess.make_dir_recursive_absolute(dir)
	var path := dir.path_join("knd_rollback_save.ks")
	_write_text(path, '"Kona" "L0" [id=l0]\nset %love = 5\n"Kona" "L1" [id=l1]\nend\n')
	var manager := await _create_manager()
	manager.set_shot(load(path) as KonadoShot)
	manager.start_dialogue()
	await _wait_for_instruction_and_state(
		manager, "ks:id:l0", KonadoDialogueManager.DialogState.WAITING
	)
	_expect(not manager.variable_store.has("love"), "%love is unset before the assignment")
	await _finish_current_dialogue(manager)
	await _wait_for_instruction_and_state(
		manager, "ks:id:l1", KonadoDialogueManager.DialogState.WAITING
	)
	_expect_equal(manager.variable_store.get_int("love"), 5, "the assignment committed")
	_expect(manager.timeline.step_back(), "step back crosses the variable assignment")
	_expect(not manager.variable_store.has("love"), "the rollback removed the assigned variable")
	_expect(manager.save_game(0), "the rolled-back state can be saved")
	await _finish_current_dialogue(manager)
	await _wait_for_instruction_and_state(
		manager, "ks:id:l1", KonadoDialogueManager.DialogState.WAITING
	)
	_expect_equal(manager.variable_store.get_int("love"), 5, "the replayed assignment committed")
	_expect(manager.load_game(0), "the save can be loaded")
	_expect(
		not manager.variable_store.has("love"),
		"the load restores the persisted state, not the replayed one",
	)
	_expect_equal(
		manager._current_instruction().stable_key(),
		"ks:id:l0",
		"the load resumes on the saved line",
	)
	_expect(
		not manager.timeline.can_step_back(),
		"loading clears the in-memory execution history",
	)
	_expect(manager.delete_save(0), "the test save is removed again")
	await _free_node(manager)
	DirAccess.remove_absolute(path)
	ResourceLoader.remove_resource_format_loader(loader)


## Backlog 条目回退：按记录的提交序号精确退回那一句，变量/历史裁剪/重放语义与「上一句」一致。
func _test_rollback_to_backlog_entry() -> void:
	var manager := await _create_manager()
	var emissions: Array[String] = []
	manager.custom_signal.connect(func(content: String) -> void: emissions.append(content))
	manager.set_shot(
		_compile_shot(
			(
				"set %love = 0\n"
				+ '"Kona" "L1" [id=l1]\n'
				+ "add %love 1\n"
				+ '"Kona" "L2" [id=l2]\n'
				+ "signal marker\n"
				+ "add %love 1\n"
				+ '"Kona" "L3" [id=l3]\n'
				+ "end"
			)
		)
	)
	manager.start_dialogue()
	await _wait_for_instruction_and_state(
		manager, "ks:id:l1", KonadoDialogueManager.DialogState.WAITING
	)
	await _finish_current_dialogue(manager)
	await _wait_for_instruction_and_state(
		manager, "ks:id:l2", KonadoDialogueManager.DialogState.WAITING
	)
	await _finish_current_dialogue(manager)
	await _wait_for_instruction_and_state(
		manager, "ks:id:l3", KonadoDialogueManager.DialogState.WAITING
	)
	_expect_equal(manager.variable_store.get_int("love"), 2, "both increments applied")
	_expect_equal(emissions.size(), 1, "the signal fired once on the first pass")
	# 已提交条目＝当前行之前读过的行；正在显示的那一行是 pending 行，不是回退落点。
	var entries := manager.dialogue_history.entries(0, false)
	_expect_equal(entries.size(), 2, "committed lines before the displayed one are recorded")
	_expect_equal(String(entries[0].get("text", "")), "L1", "the earliest entry is the first line")
	_expect_equal(String(entries[1].get("text", "")), "L2", "the next entry is the second line")
	_expect_equal(
		int(manager.dialogue_history.entries(0, true)[-1].get("serial", -1)),
		0,
		"the displayed line stays pending, so it is not a rollback target",
	)
	var middle_serial := int(entries[1].get("serial", 0))
	_expect(manager.timeline.can_rollback_to_entry(middle_serial), "a committed entry is reachable")
	_expect(
		manager.timeline.rollback_to_entry(middle_serial), "rollback to the second line succeeds"
	)
	_expect_equal(manager.dialogue_box.dialogue_text, "L2", "landed on the clicked line")
	_expect_equal(manager.variable_store.get_int("love"), 1, "only the second increment is undone")
	var first_serial := int(manager.dialogue_history.entries(0, false)[0].get("serial", 0))
	_expect(first_serial > 0, "the remaining committed entry still carries its serial")
	_expect(manager.timeline.rollback_to_entry(first_serial), "rollback to the first line succeeds")
	_expect_equal(manager.dialogue_box.dialogue_text, "L1", "landed on the earliest line")
	_expect_equal(manager.variable_store.get_int("love"), 0, "variables roll back with it")
	_expect_equal(
		manager.dialogue_history.entries(0, false).size(),
		0,
		"the backlog keeps only the displayed line after rolling back to the start",
	)
	_expect(not manager.timeline.can_rollback_to_entry(0), "an unknown serial is refused")
	_expect(not manager.timeline.rollback_to_entry(0), "an unknown serial cannot be rolled back")
	await _finish_current_dialogue(manager)
	await _wait_for_instruction_and_state(
		manager, "ks:id:l2", KonadoDialogueManager.DialogState.WAITING
	)
	await _finish_current_dialogue(manager)
	await _wait_for_instruction_and_state(
		manager, "ks:id:l3", KonadoDialogueManager.DialogState.WAITING
	)
	_expect_equal(
		manager.variable_store.get_int("love"), 2, "the replayed script lands on the same values"
	)
	_expect_equal(emissions.size(), 2, "the replayed signal fires again")
	_expect_equal(
		manager.dialogue_history.entries(0, false).size(),
		2,
		"the replayed lines are recorded again",
	)
	await _free_node(manager)


func _test_step_back_redraws_screen_text() -> void:
	var manager := await _create_manager()
	manager.screen_text.fade_duration = 0.0
	manager.screen_text.line_fade_duration = 0.0
	manager.set_shot(
		_compile_shot(
			(
				'screentext {\n    "First"\n    "Second"\n} [id=overlay]\n'
				+ '"Kona" "After" [id=after]\nend'
			)
		)
	)
	manager.start_dialogue()
	await _wait_for_instruction_and_state(
		manager, "ks:id:overlay", KonadoDialogueManager.DialogState.WAITING
	)
	await _wait_for_condition(
		func() -> bool: return manager.screen_text._is_waiting_input,
		"screen text waits for input",
	)
	manager.screen_text.skip_display()
	await _wait_for_instruction_and_state(
		manager, "ks:id:after", KonadoDialogueManager.DialogState.WAITING
	)
	_expect(manager.timeline.can_step_back(), "the screen text line is reachable")
	_expect(manager.timeline.step_back(), "step back reaches the screen text")
	_expect_equal(
		manager._current_instruction().stable_key(),
		"ks:id:overlay",
		"the screen text instruction is replayed in the same frame",
	)
	await _free_node(manager)


func _test_step_back_restores_scene_from_snapshot() -> void:
	var manager := await _create_manager()
	manager.set_shot(
		_compile_shot('"Kona" "L1" [id=l1]\nset $x = 1 [id=set]\n"Kona" "L2" [id=l2]\nend')
	)
	manager.start_dialogue()
	await _wait_for_instruction_and_state(
		manager, "ks:id:l1", KonadoDialogueManager.DialogState.WAITING
	)
	var camera := manager.camera_controller.active_camera
	_expect(camera != null, "the default template exposes an active camera")
	var baseline := camera.position
	# 模拟一次没有任何指令捕获的镜头改动：增量累加模型无法还原它，快照可以。
	camera.position = baseline + Vector2(120.0, 60.0)
	await _finish_current_dialogue(manager)
	await _wait_for_instruction_and_state(
		manager, "ks:id:l2", KonadoDialogueManager.DialogState.WAITING
	)
	_expect(manager.timeline.step_back(), "step back succeeds")
	_expect_equal(camera.position, baseline, "the line snapshot restores the camera exactly")
	await _free_node(manager)


func _test_step_back_restores_actor_state() -> void:
	var manager := await _create_manager()
	manager.character_list = load("res://sample/demo/character_list.tres")
	manager.stage_controller.character_list = manager.character_list
	manager.set_shot(
		_compile_shot(
			(
				"actor show Kona 正常 at 1\n"
				+ '"Kona" "L1" [id=l1]\n'
				+ "actor move Kona 3\n"
				+ '"Kona" "L2" [id=l2]\n'
				+ "end"
			)
		)
	)
	manager.start_dialogue()
	await _wait_for_instruction_and_state(
		manager, "ks:id:l1", KonadoDialogueManager.DialogState.WAITING
	)
	var before := _actor_position(manager, "Kona")
	_expect_equal(before, 1, "the actor starts on the first column")
	await _finish_current_dialogue(manager)
	await _wait_for_instruction_and_state(
		manager, "ks:id:l2", KonadoDialogueManager.DialogState.WAITING
	)
	_expect_equal(_actor_position(manager, "Kona"), 3, "the actor moved to the third column")
	_expect(manager.timeline.step_back(), "step back succeeds")
	_expect_equal(
		_actor_position(manager, "Kona"), before, "the actor position is restored from the snapshot"
	)
	await _free_node(manager)


func _test_step_back_restores_background() -> void:
	var manager := await _create_manager()
	manager.background_list = load("res://sample/demo/background_list.tres")
	manager.set_shot(
		_compile_shot(
			(
				"background bg_para none\n"
				+ '"Kona" "L1" [id=l1]\n'
				+ "background 01 fade\n"
				+ '"Kona" "L2" [id=l2]\n'
				+ "end"
			)
		)
	)
	manager.start_dialogue()
	await _wait_for_instruction_and_state(
		manager, "ks:id:l1", KonadoDialogueManager.DialogState.WAITING
	)
	var before := _background_id(manager)
	await _finish_current_dialogue(manager)
	await _wait_for_instruction_and_state(
		manager, "ks:id:l2", KonadoDialogueManager.DialogState.WAITING
	)
	_expect_equal(_background_id(manager), "01", "the background switched")
	_expect(manager.timeline.step_back(), "step back succeeds")
	_expect_equal(_background_id(manager), before, "the background is restored from the snapshot")
	await _free_node(manager)


## 快照缓存必须有界：行数上限、字节预算，且清空后不留下任何残留。
func _test_snapshot_store_is_bounded() -> void:
	var store := KonadoRuntimeSnapshots.new()
	store.capacity = 3
	for index: int in range(5):
		store.store("line-%d" % index, {"value": index})
	_expect_equal(store.size(), 3, "the snapshot store keeps only the newest lines")
	_expect(store.has("line-4"), "the newest line is retained")
	_expect(not store.has("line-0"), "the least recently visited line is evicted")
	# 回读会刷新访问顺序：它下一次淘汰的是“最久未访问”的一行，而不是刚刚回读过的那一行。
	store.store("line-2", {"value": 22})
	store.store("line-5", {"value": 5})
	_expect(store.has("line-2"), "a revisited line survives the next eviction")
	_expect(not store.has("line-3"), "the least recently visited line is evicted next")
	store.bytes_capacity = 1
	store.store("big", {"blob": "x".repeat(4096)})
	_expect_equal(store.size(), 1, "a tight byte budget drops the older lines")
	_expect(store.has("big"), "the newest line survives a tight byte budget")
	store.clear()
	_expect_equal(store.size(), 0, "clearing releases every snapshot")
	_expect_equal(store.bytes_used(), 0, "clearing resets the accounted bytes")


## 执行历史被清空后，已登记的重放跳过键必须失效：它们指向的记录已不存在。
func _test_cleared_history_drops_armed_rewind_skips() -> void:
	var shot := _compile_shot('"Kona" "L1" [id=l1]\nend', "res://tests/rewind-skips.ks")
	var vm := KonadoVirtualMachine.new()
	_expect(vm.install(shot.program), "the fixture program installs")
	vm._prepare_rewind_skips(PackedStringArray(["%s|ks:id:l1" % shot.program.source_path]))
	_expect(vm._should_skip_rewind("ks:id:l1"), "an armed rewind skip is visible to the executor")
	vm.clear_history()
	_expect(
		not vm._should_skip_rewind("ks:id:l1"),
		"clearing the history invalidates armed rewind skips",
	)


## 所有演出指令都必须是可回退的；只有明确列出的副作用与流程边界例外。
func _test_every_presentation_command_is_reversible() -> void:
	# 成就指令仍是不可逆副作用；异步相机只改相机变换，属于快照可逆状态。
	var side_effect_barriers := [
		"achievement.unlock",
		"achievement.progress",
		"achievement.flag",
	]
	var flow_boundaries := ["halt"]
	# jump 虽然是 CHECKPOINT，但“上一句”回退可以跨越它并回到上一剧本。
	var cross_script_jumps := ["jump.script"]
	# signal 是可重放的一次性副作用：跨越后在重放中重新发射，重选分支会再次触发处理函数。
	var replayable_side_effects := ["signal"]
	for command: String in KonadoScriptCommandRegistry.COMMANDS:
		var opcode := int(KonadoScriptCommandRegistry.COMMANDS[command]["opcode"])
		var policy := KonadoScriptCommandRegistry.rollback_policy(opcode)
		if command in flow_boundaries:
			_expect_equal(
				policy,
				KonadoScriptCommandRegistry.ROLLBACK_CHECKPOINT,
				"%s stays a flow boundary" % command,
			)
		elif command in cross_script_jumps:
			_expect_equal(
				policy,
				KonadoScriptCommandRegistry.ROLLBACK_CHECKPOINT,
				"%s stays rewindable across scripts" % command,
			)
		elif command in replayable_side_effects:
			_expect_equal(
				policy,
				KonadoScriptCommandRegistry.ROLLBACK_REVERSIBLE,
				"%s must stay replayable so a re-picked branch re-fires it" % command,
			)
		elif command in side_effect_barriers:
			_expect_equal(
				policy,
				KonadoScriptCommandRegistry.ROLLBACK_BARRIER,
				"%s stays a side-effect barrier" % command,
			)
		else:
			_expect_equal(
				policy,
				KonadoScriptCommandRegistry.ROLLBACK_REVERSIBLE,
				"%s must stay reversible so it can be rewound" % command,
			)


## 在默认模板的相机控制器上注册一个 cam1 机位，并返回活动相机。
func _attach_camera_marker(manager: KonadoDialogueManager, marker_position: Vector2) -> Camera2D:
	var controller := manager.camera_controller
	var camera := controller.active_camera
	_expect(camera != null, "the default template exposes an active camera")
	camera.position = Vector2(100.0, 100.0)
	var marker := KonadoCameraMarker.new()
	marker.marker_id = "cam1"
	marker.position = marker_position
	if is_instance_valid(controller.marker_root):
		controller.marker_root.add_child(marker)
	else:
		controller.add_child(marker)
	controller.refresh_camera_markers()
	return camera


## 等待若干帧，让 Tween 推进（或保持静止）。
func _wait_for_frames(count: int) -> void:
	for _frame: int in range(count):
		await process_frame


func _actor_position(manager: KonadoDialogueManager, actor_id: String) -> int:
	for actor: Dictionary in manager.stage_controller.capture_state().get("actors", []):
		if String(actor.get("id", "")) == actor_id:
			return int(actor.get("position", -1))
	return -1


func _background_id(manager: KonadoDialogueManager) -> String:
	return String(manager.stage_controller.capture_state().get("background", ""))


## jump 也应可回退：用真实 .ks 加载器搭一个跨剧本场景，验证能退回上一剧本的上一句，
## 并确认持久变量（%）跨剧本保留、临时变量（$）在换镜头时清空，回退时都按目标行的快照还原。
func _test_step_back_crosses_jump_between_scripts() -> void:
	var loader := KonadoScriptResourceLoader.new()
	ResourceLoader.add_resource_format_loader(loader, true)
	var dir := "res://tests/dialogue/fixtures"
	DirAccess.make_dir_recursive_absolute(dir)
	var path_a := dir.path_join("knd_rewind_a.ks")
	var path_b := dir.path_join("knd_rewind_b.ks")
	_write_text(path_a, 'set %%love = 1\nset $note = 1\n"Kona" "A1" [id=a1]\njump %s\n' % path_b)
	_write_text(
		path_b, '"Kona" "B1" [id=b1]\nset %love = 5\nset $note = 5\n"Kona" "B2" [id=b2]\nend\n'
	)
	var manager := await _create_manager()
	manager.set_shot(load(path_a) as KonadoShot)
	manager.start_dialogue()
	await _wait_for_instruction_and_state(
		manager, "ks:id:a1", KonadoDialogueManager.DialogState.WAITING
	)
	_expect_equal(manager.variable_store.get_int("love"), 1, "the source script set %love")
	_expect_equal(int(manager._temp_variables.get("note", -1)), 1, "the source script set $note")
	await _finish_current_dialogue(manager)
	await _wait_for_instruction_and_state(
		manager, "ks:id:b1", KonadoDialogueManager.DialogState.WAITING
	)
	_expect_equal(manager.variable_store.get_int("love"), 1, "%love survives the shot change")
	_expect(not manager._temp_variables.has("note"), "$note is reset by the shot change")
	await _finish_current_dialogue(manager)
	await _wait_for_instruction_and_state(
		manager, "ks:id:b2", KonadoDialogueManager.DialogState.WAITING
	)
	_expect_equal(manager.variable_store.get_int("love"), 5, "the jumped script updated %love")
	_expect_equal(int(manager._temp_variables.get("note", -1)), 5, "the jumped script set $note")
	_expect(manager.timeline.step_back(), "step back within the jumped script")
	_expect_equal(manager.dialogue_box.dialogue_text, "B1", "landed on the previous line of B")
	_expect_equal(
		manager.variable_store.get_int("love"), 1, "B1 predates the jumped script's update"
	)
	_expect(manager.timeline.can_step_back(), "the previous line lives in the source script")
	_expect(manager.timeline.step_back(), "step back crosses the jump")
	_expect_equal(manager.dialogue_box.dialogue_text, "A1", "landed on the source script's line")
	_expect_equal(
		manager.variable_store.get_int("love"), 1, "%love is restored from the source line"
	)
	_expect_equal(
		int(manager._temp_variables.get("note", -1)), 1, "$note is restored from the source line"
	)
	await _free_node(manager)
	DirAccess.remove_absolute(path_a)
	DirAccess.remove_absolute(path_b)
	ResourceLoader.remove_resource_format_loader(loader)


func _write_text(path: String, content: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(content)
	file.close()
