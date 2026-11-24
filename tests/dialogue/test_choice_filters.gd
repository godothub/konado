extends "res://tests/dialogue/dialogue_lifecycle_test_base.gd"

## choice 的 `if` / `once` 过滤、回退与存档行为。

const FILTER_SCRIPT := (
	'choice "always" -> done\n'
	+ 'choice "gated" -> done if %love >= 5\n'
	+ 'choice "one-shot" -> done once\n'
	+ "\n"
	+ "branch done\n"
	+ "\tend\n"
)

const ALL_FILTERED_SCRIPT := (
	"set $allow false\n"
	+ 'choice "only" -> done if $allow == true\n'
	+ 'Kona "after menu" [id=after]\n'
	+ "end\n"
	+ "\n"
	+ "branch done\n"
	+ '\tKona "picked" [id=picked]\n'
	+ "\tend\n"
)

const ONCE_LOOP_SCRIPT := (
	"jump_branch menu\n"
	+ "\n"
	+ "branch menu\n"
	+ '\tchoice "take once" -> take once [id=menu_choice]\n'
	+ '\tchoice "leave" -> leave\n'
	+ "\n"
	+ "branch take\n"
	+ "\tjump_branch menu\n"
	+ "\n"
	+ "branch leave\n"
	+ "\tend\n"
)

const ONCE_ROLLBACK_SCRIPT := (
	"jump_branch menu\n"
	+ "\n"
	+ "branch menu\n"
	+ '\tchoice "take once" -> picked once [id=menu_choice]\n'
	+ '\tchoice "leave" -> leave\n'
	+ "\n"
	+ "branch picked\n"
	+ '\tKona "picked" [id=picked_line]\n'
	+ "\tend\n"
	+ "\n"
	+ "branch leave\n"
	+ "\tend\n"
)

const SAVE_FIXTURE := "res://tests/dialogue/fixtures/choice_once.ks"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_compiler_filters()
	_test_compile_errors()
	_test_localized_choice_filters()
	await _test_visibility_filters()
	await _test_all_filtered_advances()
	await _test_runtime_state_contract()
	await _test_once_hides_on_revisit()
	await _test_step_back_restores_once()
	await _test_save_restores_once()
	if _failures == 0:
		print("PASS: choice filter tests")
	quit(_failures)


func _test_compiler_filters() -> void:
	var compiler := KonadoScriptCompiler.new()
	compiler.set_console_output_enabled(false)
	_expect(
		(
			compiler.compile_string(FILTER_SCRIPT.replace("\n", "\r\n"), "res://choice-crlf.ks")
			!= null
		),
		"CRLF scripts compile the same as LF scripts",
	)
	var shot := _compile_shot(FILTER_SCRIPT, "res://choice-filters.ks")
	if shot == null:
		return
	var program := shot.program
	var choice_pc := _find_opcode(program, KonadoOpcode.Type.CHOICE)
	_expect(choice_pc >= 0, "choice compiles into a CHOICE instruction")
	if choice_pc < 0:
		return
	var instruction := program.instruction_at(choice_pc)
	var options: Array[Dictionary] = instruction.value(&"options", [])
	_expect_equal(options.size(), 3, "all options are encoded")
	_expect_equal(int(options[0].get("index", -1)), 0, "options carry their group index")
	_expect_equal(int(options[2].get("index", -1)), 2, "group indexes stay in order")
	var filters: Variant = instruction.value(&"filters", [])
	_expect(filters is Array, "choice stores a filter table")
	if not filters is Array:
		return
	var filter_array: Array = filters
	_expect_equal(filter_array.size(), 3, "filters mirror the option count")
	var always: Dictionary = filter_array[0]
	_expect(
		(always.get("condition", {}) as Dictionary).is_empty(), "plain options have no condition"
	)
	_expect(not bool(always.get("once", false)), "plain options are repeatable")
	var gated: Dictionary = filter_array[1]
	var condition: Dictionary = gated.get("condition", {})
	_expect(bool(condition.get("persistent", false)), "persistent conditions are encoded as %")
	_expect_equal(String(condition.get("name", "")), "love", "condition keeps its variable name")
	_expect_equal(
		int(condition.get("operator", -1)),
		3,
		">= is encoded with the shared operator table",
	)
	_expect_equal(condition.get("value"), 5, "condition keeps its comparison value")
	var one_shot: Dictionary = filter_array[2]
	_expect(bool(one_shot.get("once", false)), "once is encoded per option")
	_expect(
		program.true_pcs[choice_pc] != KonadoProgram.INVALID_PC,
		"choice stores its fall-through position for fully filtered menus",
	)


func _test_compile_errors() -> void:
	var compiler := KonadoScriptCompiler.new()
	compiler.set_console_output_enabled(false)
	var suffixes := [
		'choice "a" -> done if\n\nbranch done\n\tend\n',
		'choice "a" -> done if %love\n\nbranch done\n\tend\n',
		'choice "a" -> done if %love == 1 if %love == 2\n\nbranch done\n\tend\n',
		'choice "a" -> done once once\n\nbranch done\n\tend\n',
		'choice "a" -> done unless %love == 1\n\nbranch done\n\tend\n',
	]
	for source: String in suffixes:
		_expect(
			compiler.compile_string(source, "res://choice-suffix.ks") == null,
			"invalid choice suffixes fail: %s" % source.replace("\n", "\\n"),
		)
	_expect(
		(
			(
				compiler
				. compile_string(
					'choice "a" -> done if $undefined == 1\n\nbranch done\n\tend\n',
					"res://choice-undefined.ks",
				)
			)
			== null
		),
		"choice conditions participate in temporary-variable analysis",
	)


func _test_visibility_filters() -> void:
	var manager := await _create_manager()
	manager.variable_store.set_value("love", 10)
	manager.set_shot(_compile_shot(FILTER_SCRIPT))
	manager.start_dialogue()
	await _wait_for_instruction_and_state(
		manager, "ks:main/0", KonadoDialogueManager.DialogState.WAITING
	)
	_expect_equal(
		_choice_texts(manager),
		PackedStringArray(["always", "gated", "one-shot"]),
		"all options are visible when the condition holds",
	)
	manager.stop_dialogue()
	await _wait_for_state(manager, KonadoDialogueManager.DialogState.OFF)
	manager.variable_store.set_value("love", 1)
	manager.set_shot(_compile_shot(FILTER_SCRIPT))
	manager.start_dialogue()
	await _wait_for_instruction_and_state(
		manager, "ks:main/0", KonadoDialogueManager.DialogState.WAITING
	)
	_expect_equal(
		_choice_texts(manager),
		PackedStringArray(["always", "one-shot"]),
		"options whose condition is false are hidden",
	)
	_expect(_press_choice(manager, "always"), "visible options can still be picked")
	await _wait_for_state(manager, KonadoDialogueManager.DialogState.OFF)
	# 持久变量未初始化时按“条件不成立”处理，不能打断剧情。
	var fresh_manager := await _create_manager()
	fresh_manager.set_shot(_compile_shot(FILTER_SCRIPT))
	fresh_manager.start_dialogue()
	await _wait_for_instruction_and_state(
		fresh_manager, "ks:main/0", KonadoDialogueManager.DialogState.WAITING
	)
	_expect_equal(
		_choice_texts(fresh_manager),
		PackedStringArray(["always", "one-shot"]),
		"missing condition variables hide the option instead of failing",
	)
	await _free_node(fresh_manager)
	await _free_node(manager)


func _test_all_filtered_advances() -> void:
	var manager := await _create_manager()
	manager.set_shot(_compile_shot(ALL_FILTERED_SCRIPT))
	manager.start_dialogue()
	await _wait_for_instruction_and_state(
		manager, "ks:id:after", KonadoDialogueManager.DialogState.WAITING
	)
	_expect_equal(
		manager._vm.program.key_for_pc(manager._vm.pc),
		"ks:id:after",
		"a fully filtered menu advances to the statement after the choice group",
	)
	await _finish_current_dialogue(manager)
	await _wait_for_state(manager, KonadoDialogueManager.DialogState.OFF)
	await _free_node(manager)


func _test_runtime_state_contract() -> void:
	var manager := await _create_manager()
	manager.set_shot(_compile_shot(FILTER_SCRIPT))
	manager.start_dialogue()
	await _wait_for_instruction_and_state(
		manager, "ks:main/0", KonadoDialogueManager.DialogState.WAITING
	)
	var state := KonadoRuntimeState.capture(manager)
	_expect(KonadoRuntimeState.validate(state, manager), "a complete 2.9 runtime state validates")
	var without_call_stack := state.duplicate(true)
	(without_call_stack["execution"] as Dictionary).erase("call_stack")
	_expect(
		not KonadoRuntimeState.validate(without_call_stack, manager),
		"runtime states without call_stack are rejected",
	)
	var without_choices := state.duplicate(true)
	without_choices.erase("choices")
	_expect(
		not KonadoRuntimeState.validate(without_choices, manager),
		"runtime states without choices are rejected",
	)
	_expect(
		not KonadoRuntimeState.validate({"schema_version": 2}, manager),
		"2.8 runtime state schemas are rejected",
	)
	var legacy_save := KonadoSaveData.new().to_dict()
	legacy_save["compiler_abi"] = "konado-2.8"
	_expect(
		not KonadoSaveData.new().from_dict(legacy_save),
		"2.8 save envelopes are rejected",
	)
	var current_save := KonadoSaveData.new()
	current_save.execution = {
		"shot_path": "res://x.ks",
		"program_fingerprint": "fp",
		"instruction_id": "ks:main/0",
	}
	current_save.runtime_state = {"schema_version": KonadoRuntimeState.SCHEMA_VERSION}
	_expect(
		KonadoSaveData.new().from_dict(current_save.to_dict()),
		"2.9 save envelopes round-trip",
	)
	manager.stop_dialogue()
	await _wait_for_state(manager, KonadoDialogueManager.DialogState.OFF)
	await _free_node(manager)


func _test_once_hides_on_revisit() -> void:
	var manager := await _create_manager()
	manager.set_shot(_compile_shot(ONCE_LOOP_SCRIPT))
	manager.start_dialogue()
	await _wait_for_instruction_and_state(
		manager, "ks:id:menu_choice", KonadoDialogueManager.DialogState.WAITING
	)
	_expect_equal(
		_choice_texts(manager),
		PackedStringArray(["take once", "leave"]),
		"the one-time option is visible before it is used",
	)
	_expect(_press_choice(manager, "take once"), "the one-time option can be picked")
	await _wait_for_condition(
		func() -> bool: return _choice_texts(manager) == PackedStringArray(["leave"]),
		"the one-time option disappears when the menu is revisited",
	)
	_expect_equal(manager._choices().export_state().size(), 1, "the used option is recorded once")
	_expect(_press_choice(manager, "leave"), "the remaining option can be picked")
	await _wait_for_state(manager, KonadoDialogueManager.DialogState.OFF)
	await _free_node(manager)


func _test_step_back_restores_once() -> void:
	var manager := await _create_manager()
	manager.set_shot(_compile_shot(ONCE_ROLLBACK_SCRIPT))
	manager.start_dialogue()
	await _wait_for_instruction_and_state(
		manager, "ks:id:menu_choice", KonadoDialogueManager.DialogState.WAITING
	)
	_expect(_press_choice(manager, "take once"), "the one-time option can be picked")
	await _wait_for_instruction_and_state(
		manager, "ks:id:picked_line", KonadoDialogueManager.DialogState.WAITING
	)
	_expect_equal(manager._choices().export_state().size(), 1, "picking marks the option as used")
	_expect(manager.timeline.step_back(), "stepping back to the menu succeeds")
	await _wait_for_instruction_and_state(
		manager, "ks:id:menu_choice", KonadoDialogueManager.DialogState.WAITING
	)
	_expect(manager._choices().export_state().is_empty(), "rollback removes the usage record")
	_expect_equal(
		_choice_texts(manager),
		PackedStringArray(["take once", "leave"]),
		"the one-time option reappears after rollback",
	)
	_expect(_press_choice(manager, "take once"), "the option can be picked again after rollback")
	await _wait_for_instruction_and_state(
		manager, "ks:id:picked_line", KonadoDialogueManager.DialogState.WAITING
	)
	_expect_equal(
		manager._choices().export_state().size(),
		1,
		"re-picking records the usage exactly once",
	)
	await _free_node(manager)


func _test_save_restores_once() -> void:
	var loader := KonadoScriptResourceLoader.new()
	ResourceLoader.add_resource_format_loader(loader, true)
	var manager := await _create_manager()
	var compiler := KonadoScriptCompiler.new()
	compiler.set_console_output_enabled(false)
	var shot := compiler.compile_file(SAVE_FIXTURE)
	_expect(shot != null, "choice fixture compiles from disk")
	if shot == null:
		ResourceLoader.remove_resource_format_loader(loader)
		return
	manager.set_shot(shot)
	manager.start_dialogue()
	await _wait_for_instruction_and_state(
		manager, "ks:id:menu_choice", KonadoDialogueManager.DialogState.WAITING
	)
	_expect(_press_choice(manager, "take once"), "the one-time option can be picked before saving")
	await _wait_for_condition(
		func() -> bool: return _choice_texts(manager) == PackedStringArray(["leave"]),
		"the revisited menu shows only the remaining option",
	)
	_expect(manager.save_game(1), "saving with a used one-time option succeeds")
	manager.stop_dialogue()
	await _wait_for_state(manager, KonadoDialogueManager.DialogState.OFF)
	_expect(manager.load_game(1), "loading the save succeeds")
	await _wait_for_condition(
		func() -> bool: return _choice_texts(manager) == PackedStringArray(["leave"]),
		"load restores the one-time usage",
	)
	_expect_equal(manager._choices().export_state().size(), 1, "load restores the usage record")
	_expect(_press_choice(manager, "leave"), "the remaining option works after loading")
	await _wait_for_state(manager, KonadoDialogueManager.DialogState.OFF)
	_expect(manager.delete_save(1), "the fixture save is removed")
	await _free_node(manager)
	ResourceLoader.remove_resource_format_loader(loader)


func _choice_texts(manager: KonadoDialogueManager) -> PackedStringArray:
	var texts := PackedStringArray()
	if manager.choice_controller == null:
		return texts
	for child: Node in manager.choice_controller._choice_container.get_children():
		if child is Button and not child.is_queued_for_deletion():
			texts.append((child as Button).text)
	return texts


func _press_choice(manager: KonadoDialogueManager, text: String) -> bool:
	if manager.choice_controller == null:
		return false
	for child: Node in manager.choice_controller._choice_container.get_children():
		if child is Button and not child.is_queued_for_deletion():
			if (child as Button).text == text:
				(child as Button).pressed.emit()
				return true
	return false


func _test_localized_choice_filters() -> void:
	var compiler := KonadoScriptCompiler.new()
	compiler.set_console_output_enabled(false)
	var base := compiler.compile_string(
		'choice "Base" -> done\n\nbranch done\n\tend\n', "res://choice-base.ks"
	)
	var localized := compiler.compile_string(
		'choice "本地化" -> done\n\nbranch done\n\tend\n', "res://choice-base.zh_Hans.ks"
	)
	_expect(base != null and localized != null, "choice localization fixtures compile")
	if base == null or localized == null:
		return
	var overlay_result := KonadoLocaleOverlay.build(base.program, localized.program, "zh_Hans")
	_expect(bool(overlay_result.get("ok", false)), "localized choice text builds an overlay")
	var runtime_shot := base.duplicate() as KonadoShot
	_expect(
		runtime_shot.install_locale_overlay(overlay_result.get("overlay")),
		"the overlay is compatible with the default program",
	)
	var localized_options: Array[Dictionary] = runtime_shot.instruction_at(0).value(&"options", [])
	_expect_equal(
		String(localized_options[0].get("text", "")),
		"本地化",
		"localized text is applied to the option",
	)
	_expect_equal(
		int(localized_options[0].get("index", -1)),
		0,
		"the overlay preserves option indexes",
	)
	# 结构字段 filters 不允许被本地化剧本修改。
	var once_localized := compiler.compile_string(
		'choice "Base" -> done once\n\nbranch done\n\tend\n', "res://choice-once.zh_Hans.ks"
	)
	_expect(once_localized != null, "the once fixture compiles")
	if once_localized != null:
		var rejected := KonadoLocaleOverlay.build(base.program, once_localized.program, "zh_Hans")
		_expect(
			not bool(rejected.get("ok", false)),
			"localized scripts cannot add or remove once",
		)


func _find_opcode(program: KonadoProgram, opcode: int) -> int:
	for pc: int in range(program.instruction_count()):
		if program.opcode_at(pc) == opcode:
			return pc
	return KonadoProgram.INVALID_PC
