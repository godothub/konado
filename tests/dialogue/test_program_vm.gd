extends SceneTree

var _failures := 0


func _init() -> void:
	_test_patch_delta_tracks_only_changed_paths()
	_test_compiler_and_overlay()
	_test_speaker_syntax()
	_test_compiler_result_ownership()
	_test_atomic_history()
	_test_failed_restore_is_atomic()
	_test_recursive_state_delta()
	_test_partial_state_commit()
	_test_instruction_patch_scope()
	_test_cross_program_history()
	_test_vm_limits_and_barriers()
	_test_save_codec()
	_test_source_normalization()
	_test_diagnostic_budget()
	if _failures == 0:
		print("PASS: Konado 2.9 Program VM")
	quit(_failures)


func _test_speaker_syntax() -> void:
	var compiler := KonadoScriptCompiler.new()
	compiler.set_console_output_enabled(false)
	var static_shot := compiler.compile_string('Kona "Hello"\nend', "res://static-speaker.ks")
	_expect(static_shot != null, "bare actor dialogue syntax compiles")
	if static_shot != null:
		var instruction := static_shot.instruction_at(0)
		_expect(
			(
				int(instruction.value(&"speaker_kind"))
				== KonadoScriptSyntaxTree.DialogueNode.SpeakerKind.ACTOR
			),
			"bare dialogue speaker is encoded as an actor reference",
		)
		_expect(instruction.value(&"speaker") == "Kona", "actor reference preserves its ID")
		_expect(
			static_shot.dependent_characters == ["Kona"],
			"static dialogue actors participate in dependency analysis",
		)
	var legacy_shot := compiler.compile_string('"Kona" "Hello"\nend', "res://legacy.ks")
	_expect(legacy_shot != null, "quoted legacy dialogue syntax remains valid")
	if legacy_shot != null:
		_expect(
			(
				int(legacy_shot.instruction_at(0).value(&"speaker_kind"))
				== KonadoScriptSyntaxTree.DialogueNode.SpeakerKind.TEXT
			),
			"quoted dialogue speaker is encoded as interpolated text",
		)
	var temp_shot := compiler.compile_string(
		'set $speaker "Kona"\n$speaker "Hello"\nend', "res://temp-speaker.ks"
	)
	_expect(temp_shot != null, "defined temporary speaker variables compile")
	if temp_shot != null:
		_expect(
			(
				int(temp_shot.instruction_at(1).value(&"speaker_kind"))
				== KonadoScriptSyntaxTree.DialogueNode.SpeakerKind.TEMPORARY_VARIABLE
			),
			"temporary speaker variables preserve their storage class",
		)
	var persistent_shot := compiler.compile_string(
		'%speaker "Hello"\nend', "res://persistent-speaker.ks"
	)
	_expect(persistent_shot != null, "persistent speaker variables compile")
	var interpolated_shot := compiler.compile_string(
		'set $index 2\n"Guest $index" "Hello"\nend', "res://interpolated-speaker.ks"
	)
	_expect(interpolated_shot != null, "quoted speaker interpolation compiles")
	var unresolved_interpolation := compiler.compile_string(
		'"Guest $missing" "Hello, $missing"\nend', "res://unresolved-interpolation.ks"
	)
	_expect(
		unresolved_interpolation != null,
		"unresolved text interpolation remains a runtime warning instead of invalidating the script",
	)
	var missing_temp := compiler.compile_string('$missing "Hello"\nend', "res://missing-speaker.ks")
	_expect(missing_temp == null, "undefined temporary speaker variables fail static analysis")
	var invalid_temp := compiler.compile_string(
		'set $speaker 12\n$speaker "Hello"\nend', "res://invalid-speaker.ks"
	)
	_expect(invalid_temp == null, "non-string temporary speaker variables fail static analysis")


func _test_patch_delta_tracks_only_changed_paths() -> void:
	var state := {
		"variables": {"score": 1, "name": "Kona"},
		"stage": {"background": "day"},
	}
	var patch := (
		KonadoStateDelta
		. combine_patches(
			[
				KonadoStateDelta.path_patch(["variables", "score"], true, 2),
				KonadoStateDelta.path_patch(["variables", "name"], true, "Kona"),
				KonadoStateDelta.path_patch(["variables", "temporary"], true, 3),
			]
		)
	)
	var delta := KonadoStateDelta.for_patch(state, patch)
	var updated := KonadoStateDelta.apply(state, delta.forward)
	_expect(updated.variables.score == 2, "patch delta updates a nested value")
	_expect(updated.variables.temporary == 3, "patch delta inserts a nested value")
	_expect(updated.stage == state.stage, "patch delta preserves untouched domains")
	_expect(
		not delta.forward.variables.changes.has("name"),
		"patch delta removes no-op entries",
	)
	_expect(
		KonadoStateDelta.apply(updated, delta.reverse) == state,
		"patch delta reconstructs an exact reverse patch",
	)
	var insert_nested := KonadoStateDelta.path_patch(["new_domain", "value"], true, 7)
	var insert_delta := KonadoStateDelta.for_patch(state, insert_nested)
	var inserted := KonadoStateDelta.apply(state, insert_delta.forward)
	_expect(inserted.new_domain.value == 7, "patch delta creates a missing parent path")
	_expect(
		KonadoStateDelta.apply(inserted, insert_delta.reverse) == state,
		"patch delta rollback removes a parent path that did not previously exist",
	)


func _test_compiler_and_overlay() -> void:
	var compiler := KonadoScriptCompiler.new()
	compiler.set_console_output_enabled(false)
	var source := (
		"screentext {\n"
		+ '    "Opening"\n'
		+ "} [id=opening]\n"
		+ '"Kona" "Hello" [speed=2.0] [id=intro]\n'
		+ 'choice "Continue" -> finish [id=menu]\n'
		+ "branch finish\n"
		+ "    end [id=done]"
	)
	var localized_source := source.replace("Hello", "你好").replace("Continue", "继续")
	var shot := compiler.compile_string(source, "res://tests/program.ks")
	var localized := compiler.compile_string(localized_source, "res://tests/program.zh_Hans.ks")
	_expect(shot != null and localized != null, "compiler emits valid Programs")
	if shot == null or localized == null:
		return
	_expect(shot.program.is_valid(), "emitted Program validates")
	_expect(shot.program.pc_for_key("ks:id:opening") == 0, "screen-text stable ID resolves to PC")
	_expect(shot.program.pc_for_key("ks:id:intro") == 1, "explicit stable ID resolves to PC")
	var first := shot.program.instruction_at(1)
	_expect(first.opcode() == KonadoOpcode.Type.DIALOGUE, "first opcode is dialogue")
	_expect(first.value(&"speed") == 2.0, "named speed parameter reaches Program operands")
	var overlay_result := KonadoLocaleOverlay.build(shot.program, localized.program, "zh_Hans")
	_expect(bool(overlay_result.get("ok", false)), "locale overlay accepts identical structure")
	if bool(overlay_result.get("ok", false)):
		shot.install_locale_overlay(overlay_result.overlay)
		_expect(shot.instruction_at(1).value(&"content") == "你好", "overlay replaces local text")
		var choice: Dictionary = shot.instruction_at(2).value(&"options")[0]
		_expect(choice.text == "继续", "overlay replaces choice text")
		_expect(int(choice.target_pc) == 3, "overlay preserves compiled choice target")
	var label_source := compiler.compile_string('"Narrator" "Hello"\nend', "res://label.ks")
	var label_translation := compiler.compile_string('"旁白" "你好"\nend', "res://label.zh_Hans.ks")
	var label_overlay := KonadoLocaleOverlay.build(
		label_source.program, label_translation.program, "zh_Hans"
	)
	_expect(bool(label_overlay.get("ok", false)), "quoted speaker labels may be localized")
	if bool(label_overlay.get("ok", false)):
		label_source.install_locale_overlay(label_overlay.overlay)
		_expect(
			label_source.instruction_at(0).value(&"speaker") == "旁白",
			"speaker label localization reaches runtime operands",
		)
	var actor_source := compiler.compile_string('Kona "Hello"\nend', "res://actor.ks")
	var actor_translation := compiler.compile_string('Alice "你好"\nend', "res://actor.zh_Hans.ks")
	var actor_overlay := KonadoLocaleOverlay.build(
		actor_source.program, actor_translation.program, "zh_Hans"
	)
	_expect(bool(actor_overlay.get("ok", false)), "localized scripts may replace actors")
	if bool(actor_overlay.get("ok", false)):
		actor_source.install_locale_overlay(actor_overlay.overlay)
		_expect(
			actor_source.instruction_at(0).value(&"speaker") == "Alice",
			"localized actor identity reaches runtime dialogue operands",
		)
	var staging_source := (
		compiler
		. compile_string(
			(
				"actor show Kona normal at 1 [duration=0.2] [id=actor]\n"
				+ "background room fade [duration=0.3] [id=background]\n"
				+ "cam move cam1 linear 0.4 [id=camera]\n"
				+ "play bgm morning [id=bgm]\n"
				+ "end [id=end]"
			),
			"res://staging.ks",
		)
	)
	var staging_translation := (
		compiler
		. compile_string(
			(
				"actor show Alice winter at 3 [duration=0.5] [id=actor]\n"
				+ "background snow wave [duration=0.6] [id=background]\n"
				+ "cam move cam2 ease_in_out 0.7 [id=camera]\n"
				+ "play bgm winter [id=bgm]\n"
				+ "end [id=end]"
			),
			"res://staging.zh_Hans.ks",
		)
	)
	_expect(
		staging_source != null and staging_translation != null,
		"locale-specific presentation fixtures compile",
	)
	if staging_source != null and staging_translation != null:
		_expect(
			(
				staging_source.program.control_flow_sha256
				== staging_translation.program.control_flow_sha256
			),
			"presentation differences do not alter the control-flow fingerprint",
		)
		var staging_overlay := KonadoLocaleOverlay.build(
			staging_source.program, staging_translation.program, "zh_Hans"
		)
		_expect(
			bool(staging_overlay.get("ok", false)),
			"locale overlay accepts different presentation resources and timing",
		)
		if bool(staging_overlay.get("ok", false)):
			staging_source.install_locale_overlay(staging_overlay.overlay)
			_expect(
				(
					staging_source.instruction_at(0).value(&"actor") == "Alice"
					and staging_source.instruction_at(0).value(&"state") == "winter"
					and staging_source.instruction_at(1).value(&"background") == "snow"
					and staging_source.instruction_at(2).value(&"camera") == "cam2"
					and staging_source.instruction_at(3).value(&"resource") == "winter"
				),
				"runtime instructions use locale-specific presentation operands",
			)


func _test_compiler_result_ownership() -> void:
	var compiler := KonadoScriptCompiler.new()
	compiler.set_console_output_enabled(false)
	var first := compiler.compile_string("actor show Kona normal at 1\nend", "res://first.ks")
	var second := compiler.compile_string("actor show Alice normal at 1\nend", "res://second.ks")
	_expect(first != null and second != null, "compiler ownership fixtures compile")
	if first == null or second == null:
		return
	_expect(
		first.dependent_characters == ["Kona"],
		"reusing a compiler does not mutate an earlier Shot's dependency metadata",
	)
	_expect(second.dependent_characters == ["Alice"], "later compile owns its dependency metadata")


func _test_atomic_history() -> void:
	var compiler := KonadoScriptCompiler.new()
	compiler.set_console_output_enabled(false)
	var shot := compiler.compile_string('"Kona" "Line"\nend', "res://tests/vm.ks")
	_expect(shot != null, "VM fixture compiles")
	if shot == null:
		return
	var vm := KonadoVirtualMachine.new()
	_expect(vm.install(shot.program), "VM installs valid Program")
	var before := {"variables": {"score": 1}, "unchanged": {"large": PackedByteArray([1, 2, 3])}}
	var after := {"variables": {"score": 2}, "unchanged": {"large": PackedByteArray([1, 2, 3])}}
	var token := vm.begin(before)
	_expect(vm.commit(token, 1, after), "VM commits one atomic instruction")
	var history := vm.history()
	_expect(history.size() == 1, "VM records bounded history")
	_expect(
		not history[0].reverse_delta.has("unchanged"),
		"history delta excludes unchanged runtime domains",
	)
	var restored: Array[Dictionary] = []
	var restore_callback := func(state: Dictionary) -> bool:
		restored.append(state)
		return true
	_expect(
		vm.rollback(1, restore_callback),
		"VM rolls back a reversible instruction",
	)
	_expect(restored.size() == 1 and restored[0] == before, "rollback restores exact prior state")
	vm.history_limit = 2
	vm.clear_history()
	for value in range(3):
		var state := {"variables": {"score": value}}
		var next_state := {"variables": {"score": value + 1}}
		var loop_token := vm.begin(state)
		_expect(vm.commit(loop_token, 0, next_state), "ring history accepts commit %d" % value)
	_expect(vm.history_size() == 2, "history uses its bounded ring capacity")
	_expect(vm.history()[0].pc == 0, "ring history remains chronologically ordered")


func _test_failed_restore_is_atomic() -> void:
	var compiler := KonadoScriptCompiler.new()
	compiler.set_console_output_enabled(false)
	var shot := compiler.compile_string("set $score = 1\nend", "res://tests/atomic-restore.ks")
	_expect(shot != null, "atomic restore fixture compiles")
	if shot == null:
		return
	var before := {"variables": {"score": 0}}
	var after := {"variables": {"score": 1}}

	var rollback_vm := KonadoVirtualMachine.new()
	_expect(rollback_vm.install(shot.program), "rollback restore fixture installs")
	var rollback_token := rollback_vm.begin(before)
	_expect(rollback_vm.commit(rollback_token, 1, after), "rollback fixture commits state")
	var suspended_token := rollback_vm.begin(after)
	var rollback_restore_calls := 0
	var failing_rollback_restore := func(_state: Dictionary) -> bool:
		rollback_restore_calls += 1
		return rollback_restore_calls > 1
	_expect(
		not rollback_vm.rollback(1, failing_rollback_restore, true),
		"a failed rollback restore reports failure",
	)
	_expect(rollback_vm.program == shot.program, "failed rollback preserves the Program")
	_expect(rollback_vm.pc == 1, "failed rollback preserves the program counter")
	_expect(rollback_vm.snapshot_state() == after, "failed rollback reapplies committed state")
	_expect(rollback_vm.history_size() == 1, "failed rollback preserves execution history")
	_expect(
		rollback_vm.fail(suspended_token),
		"failed rollback preserves the suspended transaction for another recovery action",
	)
	var unrecoverable_vm := KonadoVirtualMachine.new()
	_expect(unrecoverable_vm.install(shot.program), "unrecoverable restore fixture installs")
	var unrecoverable_token := unrecoverable_vm.begin(before)
	_expect(
		unrecoverable_vm.commit(unrecoverable_token, 1, after),
		"unrecoverable restore fixture commits state",
	)
	unrecoverable_vm.begin(after)
	_expect(
		not unrecoverable_vm.rollback(1, func(_state: Dictionary) -> bool: return false, true),
		"rollback rejects a restore that cannot reapply either boundary",
	)
	_expect(
		not unrecoverable_vm._last_failed_restore_preserved_state(),
		"the VM exposes when a failed restore cannot safely preserve the suspended session",
	)

	var checkpoint_vm := KonadoVirtualMachine.new()
	_expect(checkpoint_vm.install(shot.program), "checkpoint restore fixture installs")
	var checkpoint := checkpoint_vm.create_checkpoint("before", before)
	_expect(not checkpoint.is_empty(), "checkpoint restore fixture creates a checkpoint")
	var checkpoint_token := checkpoint_vm.begin(before)
	_expect(checkpoint_vm.commit(checkpoint_token, 1, after), "checkpoint fixture commits state")
	var checkpoint_suspended_token := checkpoint_vm.begin(after)
	var checkpoint_restore_calls := 0
	var failing_checkpoint_restore := func(_state: Dictionary) -> bool:
		checkpoint_restore_calls += 1
		return checkpoint_restore_calls > 1
	_expect(
		not checkpoint_vm.restore_checkpoint(checkpoint, failing_checkpoint_restore, true),
		"a failed checkpoint restore reports failure",
	)
	_expect(checkpoint_vm.program == shot.program, "failed checkpoint restore preserves Program")
	_expect(checkpoint_vm.pc == 1, "failed checkpoint restore preserves the program counter")
	_expect(
		checkpoint_vm.snapshot_state() == after,
		"failed checkpoint restore reapplies committed state",
	)
	_expect(
		checkpoint_vm.history_size() == 1,
		"failed checkpoint restore preserves execution history",
	)
	_expect(
		checkpoint_vm.fail(checkpoint_suspended_token),
		"failed checkpoint restore preserves the suspended transaction",
	)


func _test_cross_program_history() -> void:
	var compiler := KonadoScriptCompiler.new()
	compiler.set_console_output_enabled(false)
	var source := compiler.compile_string("jump res://sample/demo/demo_02.ks", "res://source.ks")
	var target := compiler.compile_string('"Kona" "Target"\nend', "res://target.ks")
	_expect(source != null and target != null, "cross-Program VM fixtures compile")
	if source == null or target == null:
		return
	var vm := KonadoVirtualMachine.new()
	_expect(vm.install(source.program), "VM installs source Program")
	var before := {"execution": {"shot_path": "res://source.ks"}, "variables": {"score": 1}}
	var after := {"execution": {"shot_path": "res://target.ks"}, "variables": {"score": 1}}
	var token := vm.begin(before)
	_expect(
		vm.transition(token, target.program, target.program.entry_pc, after),
		"VM commits a cross-Program transition without clearing history",
	)
	_expect(vm.program == target.program and vm.history_size() == 1, "transition installs target")
	var restored: Array[Dictionary] = []
	var restore_callback := func(state: Dictionary) -> bool:
		restored.append(state)
		return true
	_expect(vm.rollback(1, restore_callback), "VM rolls back across Program boundary")
	_expect(vm.program == source.program and vm.pc == 0, "rollback restores source Program and PC")
	_expect(restored.size() == 1 and restored[0] == before, "rollback restores source state")
	var checkpoint := vm.create_checkpoint("source", before)
	var second_token := vm.begin(before)
	_expect(
		vm.transition(second_token, target.program, target.program.entry_pc, after),
		"VM transitions after cross-Program checkpoint",
	)
	_expect(
		vm.restore_checkpoint(checkpoint, restore_callback),
		"checkpoint restores its owning Program after a transition",
	)
	_expect(vm.program == source.program and vm.pc == 0, "checkpoint restores source execution")


func _test_recursive_state_delta() -> void:
	var unchanged := PackedByteArray([1, 2, 3])
	var before := {
		"variables": {"score": 1, "profile": {"name": "Kona", "blob": unchanged}},
		"stage": {"background": "day"},
	}
	var after := before.duplicate(true)
	after.variables.score = 2
	var delta := KonadoStateDelta.between(before, after)
	_expect(delta.forward.has("variables"), "nested delta records changed domain")
	_expect(
		not delta.forward.variables.changes.has("profile"),
		"nested delta excludes unchanged values inside a changed domain",
	)
	_expect(
		KonadoStateDelta.apply(after, delta.reverse) == before,
		"nested reverse delta restores the exact previous state",
	)


func _test_partial_state_commit() -> void:
	var compiler := KonadoScriptCompiler.new()
	compiler.set_console_output_enabled(false)
	var shot := compiler.compile_string('"Kona" "Line"\nend', "res://tests/partial-vm.ks")
	_expect(shot != null, "partial-state VM fixture compiles")
	if shot == null:
		return
	var vm := KonadoVirtualMachine.new()
	vm.history_bytes_limit = 64 * 1024
	_expect(vm.install(shot.program), "partial-state VM installs Program")
	var initial := {
		"variables": {"score": 1, "unchanged": PackedByteArray([1, 2, 3])},
		"stage": {"background": "day"},
	}
	vm.synchronize_state(initial)
	var before_patch := KonadoStateDelta.path_patch(["variables", "score"], true, 1)
	var token := vm.begin_patch(before_patch)
	var after_patch := KonadoStateDelta.path_patch(["variables", "score"], true, 2)
	_expect(vm.commit_patch(token, 1, after_patch), "VM commits a path-level state patch")
	_expect(
		vm.snapshot_state().stage == initial.stage, "partial commit preserves untouched domains"
	)
	_expect(vm.snapshot_state().variables.score == 2, "partial commit updates the selected value")
	var record := vm.history()[0]
	_expect(
		not record.forward_delta.variables.changes.has("unchanged"),
		"partial commit does not copy unrelated variables into history",
	)


func _test_instruction_patch_scope() -> void:
	var compiler := KonadoScriptCompiler.new()
	compiler.set_console_output_enabled(false)
	var plain := compiler.compile_string('"Kona" "Line"\nend', "res://plain.ks")
	var voiced := compiler.compile_string('"Kona" "Line" voice_01\nend', "res://voiced.ks")
	var bgm := compiler.compile_string("play bgm echo\nend", "res://bgm.ks")
	_expect(plain != null and voiced != null and bgm != null, "state-patch fixtures compile")
	if plain == null or voiced == null or bgm == null:
		return
	var manager := KonadoDialogueManager.new()
	var audio_controller := KonadoAudioController.new()
	manager.audio_controller = audio_controller
	audio_controller.voice_player = AudioStreamPlayer.new()
	audio_controller.background_music_player = AudioStreamPlayer.new()
	audio_controller.sound_effect_player = AudioStreamPlayer.new()
	manager.add_child(audio_controller)
	audio_controller.configure()
	var plain_patch := KonadoRuntimeState.capture_instruction_patch(
		manager, plain.instruction_at(0)
	)
	_expect(
		not plain_patch.has(KonadoRuntimeState.DOMAIN_AUDIO),
		"dialogue without voice does not sample unrelated audio playback positions",
	)
	var voice_patch := KonadoRuntimeState.capture_instruction_patch(
		manager, voiced.instruction_at(0)
	)
	var voice_audio: Dictionary = KonadoStateDelta.apply({}, voice_patch).get(
		KonadoRuntimeState.DOMAIN_AUDIO, {}
	)
	_expect(
		voice_audio.has("voice"),
		"voiced dialogue captures the audio domain including the voice channel",
	)
	var bgm_patch := KonadoRuntimeState.capture_instruction_patch(manager, bgm.instruction_at(0))
	var bgm_audio: Dictionary = KonadoStateDelta.apply({}, bgm_patch).get(
		KonadoRuntimeState.DOMAIN_AUDIO, {}
	)
	_expect(
		bgm_audio.has("bgm") and bgm_audio.has("mix") and bgm_audio.has("parameters"),
		"audio instructions capture the whole audio domain (bgm + mix + parameters)",
	)
	manager.free()


func _test_vm_limits_and_barriers() -> void:
	var compiler := KonadoScriptCompiler.new()
	compiler.set_console_output_enabled(false)
	var shot := compiler.compile_string(
		'achievement unlock "external"\n"Kona" "Line"\nend', "res://tests/barrier-vm.ks"
	)
	_expect(shot != null, "rollback barrier fixture compiles")
	if shot == null:
		return
	var vm := KonadoVirtualMachine.new()
	_expect(vm.install(shot.program), "rollback barrier fixture installs")
	var token := vm.begin({"value": 0})
	_expect(vm.commit(token, 1, {"value": 1}), "VM commits rollback barrier")
	token = vm.begin({"value": 1})
	_expect(vm.commit(token, 1, {"value": 2}), "VM commits reversible instruction")
	_expect(vm.can_rollback(1), "rollback remains available after a reversible instruction")
	_expect(not vm.can_rollback(2), "rollback cannot cross an external side-effect barrier")
	# signal 是可重放的一次性副作用：跨越它不会被拒绝（重放时会重新发射）。
	var replayable_shot := compiler.compile_string(
		'signal "external"\n"Kona" "Line"\nend', "res://tests/signal-vm.ks"
	)
	_expect(replayable_shot != null, "replayable signal fixture compiles")
	if replayable_shot != null:
		var replayable_vm := KonadoVirtualMachine.new()
		_expect(replayable_vm.install(replayable_shot.program), "replayable signal installs")
		token = replayable_vm.begin({"value": 0})
		_expect(replayable_vm.commit(token, 1, {"value": 1}), "VM commits the signal instruction")
		token = replayable_vm.begin({"value": 1})
		_expect(replayable_vm.commit(token, 1, {"value": 2}), "VM commits a reversible instruction")
		_expect(replayable_vm.can_rollback(2), "rollback crosses a replayable signal")
	var checkpoint := vm.create_checkpoint("before-resize", {"value": 2})
	_expect(not checkpoint.is_empty(), "VM creates an explicit checkpoint")
	vm.history_limit = 1
	token = vm.begin({"value": 2})
	_expect(vm.commit(token, 1, {"value": 3}), "VM applies a new history capacity")
	_expect(
		vm.restore_checkpoint(checkpoint, func(_state: Dictionary) -> bool: return true),
		"resizing execution history does not discard explicit checkpoints",
	)
	var disabled_vm := KonadoVirtualMachine.new()
	disabled_vm.history_limit = 0
	_expect(disabled_vm.install(shot.program), "history-disabled VM installs Program")
	token = disabled_vm.begin({"value": 0})
	_expect(disabled_vm.commit(token, 1, {"value": 1}), "history-disabled VM still executes")
	_expect(disabled_vm.history_size() == 0, "zero history limit disables history retention")
	_expect(
		not disabled_vm.install(shot.program, shot.program.instruction_count()),
		"VM rejects an out-of-range entry PC",
	)
	_expect(
		disabled_vm.program == shot.program,
		"failed installation preserves the previously installed Program",
	)
	_expect(disabled_vm.pc == 1, "failed installation preserves the program counter")


func _test_save_codec() -> void:
	var source := {
		"camera": {"position": Vector2(12.5, -3.0), "zoom": Vector2(1.25, 1.25)},
		"bytes": PackedByteArray([0, 1, 127, 255]),
		"nested": [{"color": Color(0.1, 0.2, 0.3, 0.4)}],
	}
	var encoded := KonadoSaveCodec.encode(source)
	_expect(not encoded.is_empty(), "save codec encodes object-free Variant state")
	var decoded := KonadoSaveCodec.decode(encoded)
	_expect(decoded == source, "save codec preserves Godot value types exactly")
	var corrupted := encoded.duplicate()
	corrupted[corrupted.size() - 1] ^= 0xff
	_expect(KonadoSaveCodec.decode(corrupted).is_empty(), "save codec rejects corrupted payloads")
	_expect(
		KonadoSaveCodec.decode(encoded.slice(0, encoded.size() - 1)).is_empty(),
		"save codec rejects truncated payloads",
	)


func _test_source_normalization() -> void:
	var raw := '\ufeff"Kona" "一"\r\nend\r'
	var normalized := KonadoScriptSourceNormalizer.normalize_with_map(raw)
	_expect(
		normalized.text == '"Kona" "一"\nend\n',
		"source normalization handles BOM and mixed newlines"
	)
	var map: PackedInt32Array = normalized.normalized_to_raw
	_expect(
		map.size() == String(normalized.text).length() + 1, "normalization preserves offset map"
	)
	_expect(map[0] == 1 and map[map.size() - 1] == raw.length(), "offset map spans raw source")
	var compiler := KonadoScriptCompiler.new()
	compiler.set_console_output_enabled(false)
	var lf := compiler.compile_string('"Kona" "一"\nend\n', "res://lf.ks")
	var mixed := compiler.compile_string(raw, "res://mixed.ks")
	_expect(lf != null and mixed != null, "normalized source variants compile")
	if lf != null and mixed != null:
		_expect(
			lf.program.control_flow_sha256 == mixed.program.control_flow_sha256,
			"newline variants produce equivalent control flow",
		)


func _test_diagnostic_budget() -> void:
	var invalid_lines := PackedStringArray()
	invalid_lines.resize(KonadoScriptLexer.MAX_DIAGNOSTICS * 2)
	invalid_lines.fill("@")
	var compiler := KonadoScriptCompiler.new()
	compiler.set_console_output_enabled(false)
	var analysis := compiler.analyze_string("\n".join(invalid_lines), "res://invalid.ks")
	_expect(not bool(analysis.valid), "error-storm fixture is rejected")
	_expect(
		analysis.diagnostics.size() <= KonadoScriptLexer.MAX_DIAGNOSTICS,
		"compiler caps a single-stage diagnostic storm",
	)


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	printerr("FAIL: " + message)
