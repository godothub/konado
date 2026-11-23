extends "res://tests/dialogue/dialogue_lifecycle_test_base.gd"

## Compilation, execution, state, rollback, and save/restore behavior of call/return.

const CALL_SCRIPT := (
	'"Kona" "before" [id=before]\n'
	+ "call sub [id=call_sub]\n"
	+ '"Kona" "after" [id=after]\n'
	+ "end [id=done]\n"
	+ "\n"
	+ "branch sub\n"
	+ '\t"Kona" "inside" [id=inside]\n'
	+ "\treturn [id=ret]\n"
)

const NESTED_SCRIPT := (
	'"Kona" "main" [id=main]\n'
	+ "call a [id=call_a]\n"
	+ '"Kona" "done" [id=done]\n'
	+ "end\n"
	+ "\n"
	+ "branch a\n"
	+ '\t"Kona" "a1" [id=a1]\n'
	+ "\tcall b [id=call_b]\n"
	+ '\t"Kona" "a2" [id=a2]\n'
	+ "\treturn\n"
	+ "\n"
	+ "branch b\n"
	+ '\t"Kona" "b1" [id=b1]\n'
	+ "\treturn\n"
)
const SAVE_FIXTURE := "res://tests/dialogue/fixtures/call_return.ks"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_program_edges()
	_test_compile_errors()
	_test_static_analysis_across_calls()
	_test_vm_call_stack_primitives()
	await _test_call_runs_callee_and_returns()
	await _test_nested_calls_return_in_order()
	await _test_return_without_call_ends_shot()
	await _test_step_back_restores_call_stack()
	await _test_save_restore_keeps_call_stack()
	if _failures == 0:
		print("PASS: call/return tests")
	quit(_failures)


func _test_program_edges() -> void:
	var shot := _compile_shot(CALL_SCRIPT, "res://call-edges.ks")
	if shot == null:
		return
	var program := shot.program
	var call_pc := _find_opcode(program, KonadoOpcode.Type.CALL_BRANCH)
	_expect(call_pc >= 0, "call compiles into a CALL_BRANCH instruction")
	if call_pc < 0:
		return
	var callee_pc := program.next_pcs[call_pc]
	var return_address := program.true_pcs[call_pc]
	_expect(callee_pc != KonadoProgram.INVALID_PC, "call stores the callee entry in next_pc")
	_expect(
		return_address != KonadoProgram.INVALID_PC,
		"call stores the return address in true_pc",
	)
	_expect(
		program.opcode_at(callee_pc) == KonadoOpcode.Type.DIALOGUE,
		"callee entry is the first instruction of the called branch",
	)
	_expect_equal(
		program.key_for_pc(return_address),
		"ks:id:after",
		"return address points at the statement after the call",
	)
	_expect_equal(
		program.key_for_pc(call_pc),
		"ks:id:call_sub",
		"call keeps its explicit stable id",
	)
	_expect(
		_find_opcode(program, KonadoOpcode.Type.RETURN) >= 0,
		"return compiles into a RETURN instruction",
	)


func _test_compile_errors() -> void:
	var compiler := KonadoScriptCompiler.new()
	compiler.set_console_output_enabled(false)
	_expect(
		compiler.compile_string("call missing_branch\nend", "res://call-missing.ks") == null,
		"unknown call targets fail at compile time",
	)
	_expect(
		compiler.compile_string("call res://other.ks\nend", "res://call-cross.ks") == null,
		"cross-script call is rejected instead of guessing a label",
	)
	_expect(
		(
			compiler.compile_string(
				(
					'Kona "a" [id=a]\ncall a [id=call_a]\nend\n\n'
					+ 'branch a\n\tKona "b" [id=b]\n\tcall a [id=call_a2]\n\treturn\n'
				),
				"res://call-recurse.ks",
			)
			== null
		),
		"recursive call graphs are rejected at compile time",
	)


func _test_static_analysis_across_calls() -> void:
	var compiler := KonadoScriptCompiler.new()
	compiler.set_console_output_enabled(false)
	# 被调分支里定义的临时变量，调用点之后可以安全使用：分析器只放宽，不误报。
	_expect(
		(
			compiler.compile_string(
				(
					"call set_name\n"
					+ '$name "Hello"\n'
					+ "end\n\n"
					+ "branch set_name\n"
					+ '\tset $name "Kona"\n'
					+ "\treturn\n"
				),
				"res://call-temp-flow.ks",
			)
			!= null
		),
		"temporary variables defined by a callee do not break post-call analysis",
	)
	_expect(compiler.get_errors().is_empty(), "post-call analysis reports no false errors")
	_expect(
		(
			compiler.compile_string(
				(
					"call show_kona\n"
					+ "actor change Kona 正常\n"
					+ "end\n\n"
					+ "branch show_kona\n"
					+ "\tactor show Kona 正常 at 1\n"
					+ "\treturn\n"
				),
				"res://call-actor-flow.ks",
			)
			!= null
		),
		"actors introduced by a callee do not break post-call analysis",
	)
	_expect(
		compiler.get_warnings().is_empty(),
		"post-call actor checks stay advisory without warnings",
	)


func _test_vm_call_stack_primitives() -> void:
	var shot := _compile_shot(CALL_SCRIPT, "res://call-vm.ks")
	if shot == null:
		return
	var vm := KonadoVirtualMachine.new()
	_expect(vm.install(shot.program, shot.entry_pc()), "VM installs the call fixture")
	_expect(
		vm.push_call(1, "ks:id:call_sub", shot.program.fingerprint()),
		"push_call adds a frame",
	)
	_expect_equal(vm.call_stack.size(), 1, "call stack grows by one")
	var frame := vm.peek_call()
	_expect_equal(int(frame.get("return_pc", -1)), 1, "peek_call returns the newest frame")
	var exported := vm.export_call_stack()
	vm.clear_call_stack()
	_expect(vm.call_stack.is_empty(), "clear_call_stack empties the stack")
	_expect(vm.restore_call_stack(exported), "restore_call_stack accepts an exported stack")
	_expect_equal(vm.call_stack.size(), 1, "restore_call_stack rebuilds the frame")
	_expect_equal(
		int(vm.pop_call().get("return_pc", -1)), 1, "pop_call returns the newest frame"
	)
	_expect(vm.call_stack.is_empty(), "pop_call removes the frame")
	_expect(not vm.push_call(-1, "", ""), "invalid return addresses are rejected")
	_expect(
		not vm.restore_call_stack(
			[{"return_pc": shot.program.instruction_count(), "key": "", "program": ""}]
		),
		"out-of-range frames are rejected",
	)
	_expect(vm.call_stack.is_empty(), "a rejected restore leaves the stack untouched")


func _test_call_runs_callee_and_returns() -> void:
	var manager := await _create_manager()
	manager.set_shot(_compile_shot(CALL_SCRIPT))
	manager.start_dialogue()
	await _wait_for_instruction_and_state(
		manager, "ks:id:before", KonadoDialogueManager.DialogState.WAITING
	)
	_expect(manager._vm.call_stack.is_empty(), "no frame exists before the call runs")
	await _finish_current_dialogue(manager)
	await _wait_for_instruction_and_state(
		manager, "ks:id:inside", KonadoDialogueManager.DialogState.WAITING
	)
	_expect_equal(manager._vm.call_stack.size(), 1, "entering the callee pushes one frame")
	await _finish_current_dialogue(manager)
	await _wait_for_instruction_and_state(
		manager, "ks:id:after", KonadoDialogueManager.DialogState.WAITING
	)
	_expect(manager._vm.call_stack.is_empty(), "return pops the frame")
	await _finish_current_dialogue(manager)
	await _wait_for_state(manager, KonadoDialogueManager.DialogState.OFF)
	await _free_node(manager)


func _test_nested_calls_return_in_order() -> void:
	var manager := await _create_manager()
	manager.set_shot(_compile_shot(NESTED_SCRIPT))
	manager.start_dialogue()
	await _wait_for_instruction_and_state(
		manager, "ks:id:main", KonadoDialogueManager.DialogState.WAITING
	)
	await _finish_current_dialogue(manager)
	await _wait_for_instruction_and_state(
		manager, "ks:id:a1", KonadoDialogueManager.DialogState.WAITING
	)
	_expect_equal(manager._vm.call_stack.size(), 1, "first call pushed one frame")
	await _finish_current_dialogue(manager)
	await _wait_for_instruction_and_state(
		manager, "ks:id:b1", KonadoDialogueManager.DialogState.WAITING
	)
	_expect_equal(manager._vm.call_stack.size(), 2, "nested call pushed a second frame")
	await _finish_current_dialogue(manager)
	await _wait_for_instruction_and_state(
		manager, "ks:id:a2", KonadoDialogueManager.DialogState.WAITING
	)
	_expect_equal(manager._vm.call_stack.size(), 1, "inner return pops only the inner frame")
	await _finish_current_dialogue(manager)
	await _wait_for_instruction_and_state(
		manager, "ks:id:done", KonadoDialogueManager.DialogState.WAITING
	)
	_expect(manager._vm.call_stack.is_empty(), "outer return pops the outer frame")
	await _finish_current_dialogue(manager)
	await _wait_for_state(manager, KonadoDialogueManager.DialogState.OFF)
	await _free_node(manager)



func _test_return_without_call_ends_shot() -> void:
	var manager := await _create_manager()
	manager.set_shot(_compile_shot('"Kona" "only" [id=only]\nreturn [id=ret]'))
	manager.start_dialogue()
	await _wait_for_instruction_and_state(
		manager, "ks:id:only", KonadoDialogueManager.DialogState.WAITING
	)
	await _finish_current_dialogue(manager)
	await _wait_for_state(manager, KonadoDialogueManager.DialogState.OFF)
	_expect(manager._vm.call_stack.is_empty(), "bare return leaves no frame behind")
	await _free_node(manager)


func _test_step_back_restores_call_stack() -> void:
	var manager := await _create_manager()
	manager.set_shot(_compile_shot(CALL_SCRIPT))
	manager.start_dialogue()
	await _wait_for_instruction_and_state(
		manager, "ks:id:before", KonadoDialogueManager.DialogState.WAITING
	)
	await _finish_current_dialogue(manager)
	await _wait_for_instruction_and_state(
		manager, "ks:id:inside", KonadoDialogueManager.DialogState.WAITING
	)
	_expect_equal(manager._vm.call_stack.size(), 1, "frame exists inside the callee")
	_expect(manager.timeline.can_step_back(), "the previous line is reachable")
	_expect(manager.timeline.step_back(), "step_back succeeds from inside a call")
	await _wait_for_instruction_and_state(
		manager, "ks:id:before", KonadoDialogueManager.DialogState.WAITING
	)
	_expect(manager._vm.call_stack.is_empty(), "stepping back before the call clears the frame")
	await _finish_current_dialogue(manager)
	await _wait_for_instruction_and_state(
		manager, "ks:id:inside", KonadoDialogueManager.DialogState.WAITING
	)
	_expect_equal(
		manager._vm.call_stack.size(), 1, "re-entering the callee pushes exactly one frame"
	)
	await _finish_current_dialogue(manager)
	await _wait_for_instruction_and_state(
		manager, "ks:id:after", KonadoDialogueManager.DialogState.WAITING
	)
	_expect(manager._vm.call_stack.is_empty(), "the replayed call still returns")
	await _free_node(manager)


func _test_save_restore_keeps_call_stack() -> void:
	# 存档要求剧本有真实路径，并依赖 .ks 资源加载器把路径解析回 KonadoShot。
	var loader := KonadoScriptResourceLoader.new()
	ResourceLoader.add_resource_format_loader(loader, true)
	var manager := await _create_manager()
	var compiler := KonadoScriptCompiler.new()
	compiler.set_console_output_enabled(false)
	var shot := compiler.compile_file(SAVE_FIXTURE)
	_expect(shot != null, "call/return fixture compiles from disk")
	if shot == null:
		ResourceLoader.remove_resource_format_loader(loader)
		return
	manager.set_shot(shot)
	manager.start_dialogue()
	await _wait_for_instruction_and_state(
		manager, "ks:id:before", KonadoDialogueManager.DialogState.WAITING
	)
	await _finish_current_dialogue(manager)
	await _wait_for_instruction_and_state(
		manager, "ks:id:inside", KonadoDialogueManager.DialogState.WAITING
	)
	_expect_equal(manager._vm.call_stack.size(), 1, "frame exists before saving")
	_expect(manager.save_game(1), "saving inside a call succeeds")
	manager.stop_dialogue()
	await _wait_for_state(manager, KonadoDialogueManager.DialogState.OFF)
	_expect(manager.load_game(1), "loading a save taken inside a call succeeds")
	await _wait_for_instruction_and_state(
		manager, "ks:id:inside", KonadoDialogueManager.DialogState.WAITING
	)
	_expect_equal(manager._vm.call_stack.size(), 1, "load restores the call stack")
	await _finish_current_dialogue(manager)
	await _wait_for_instruction_and_state(
		manager, "ks:id:after", KonadoDialogueManager.DialogState.WAITING
	)
	_expect(manager._vm.call_stack.is_empty(), "the restored frame returns to the caller")
	_expect(manager.delete_save(1), "the fixture save is removed")
	await _free_node(manager)
	ResourceLoader.remove_resource_format_loader(loader)


func _find_opcode(program: KonadoProgram, opcode: int) -> int:
	for pc: int in range(program.instruction_count()):
		if program.opcode_at(pc) == opcode:
			return pc
	return KonadoProgram.INVALID_PC
