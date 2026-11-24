extends RefCounted
class_name KonadoScriptProgramEmitter

## Lowers validated AST directly into compact Program IR.

const BACKGROUND_EFFECTS_MAP := {
	"": KonadoStageController.BackgroundTransitionEffect.NONE,
	"none": KonadoStageController.BackgroundTransitionEffect.NONE,
	"fade": KonadoStageController.BackgroundTransitionEffect.ALPHA_FADE,
	"windmill": KonadoStageController.BackgroundTransitionEffect.WINDMILL,
	"wave": KonadoStageController.BackgroundTransitionEffect.WAVE,
	"erase": KonadoStageController.BackgroundTransitionEffect.ERASE,
	"cyberglitch": KonadoStageController.BackgroundTransitionEffect.CYBER_GLITCH,
	"blinds": KonadoStageController.BackgroundTransitionEffect.BLINDS,
	"vortex": KonadoStageController.BackgroundTransitionEffect.VORTEX_SWAP,
	"blink": KonadoStageController.BackgroundTransitionEffect.BLINK,
}
const MAX_DIAGNOSTICS := 256

var console_output_enabled := true
var _path := ""
var _errors: Array[String] = []
var _program: KonadoProgram
var _constant_index: Dictionary = {}
var _branch_nodes: Dictionary = {}
var _branch_entries: Dictionary = {}
var _pending_branch_targets: Array[Dictionary] = []
var _generated_halt_pc := KonadoProgram.INVALID_PC


class GraphFragment:
	extends RefCounted
	var entry_pc := KonadoProgram.INVALID_PC
	var exits: Array[Dictionary] = []


func get_errors() -> Array[String]:
	return _errors.duplicate()


func release_compilation_state() -> void:
	_branch_nodes.clear()
	_branch_entries.clear()
	_pending_branch_targets.clear()
	_constant_index.clear()
	_program = null


func emit(
	script: KonadoScriptSyntaxTree.ScriptNode,
	path: String,
	source_sha256: String,
	dependencies: Dictionary
) -> KonadoProgram:
	_reset(path, source_sha256, dependencies)
	_collect_branches(script.statements)
	var main_statements: Array = []
	for statement in script.statements:
		if not statement is KonadoScriptSyntaxTree.BranchNode:
			main_statements.append(statement)
	var main := _emit_sequence(main_statements, "main")
	if main.entry_pc == KonadoProgram.INVALID_PC:
		_error(1, "脚本主线没有可执行指令；branch 不能替代程序入口")

	for branch_id: String in _branch_nodes:
		var branch: KonadoScriptSyntaxTree.BranchNode = _branch_nodes[branch_id]
		var fragment := _emit_sequence(branch.body, "branch/%s" % branch_id)
		if fragment.entry_pc == KonadoProgram.INVALID_PC:
			_error(branch.line, "branch 标签 '%s' 没有可执行内容" % branch_id)
		else:
			_branch_entries[branch_id] = fragment.entry_pc
		_connect_to_halt(fragment.exits, branch.line)

	_connect_to_halt(main.exits, 1)
	_resolve_branch_targets()
	_program.entry_pc = main.entry_pc
	_program.control_flow_sha256 = _control_flow_fingerprint()
	_program.dependency_sha256 = JSON.stringify(_program.dependencies, "", true).sha256_text()
	return _program


func emit_single(node: KonadoScriptSyntaxTree.ASTNode) -> KonadoProgram:
	_reset("", "", {})
	var fragment := _emit_statement(node, "single")
	_connect_to_halt(fragment.exits, node.line)
	_program.entry_pc = fragment.entry_pc
	_program.control_flow_sha256 = _control_flow_fingerprint()
	return _program


func _reset(path: String, source_sha256: String, dependencies: Dictionary) -> void:
	_path = path
	_errors.clear()
	_constant_index.clear()
	_branch_nodes.clear()
	_branch_entries.clear()
	_pending_branch_targets.clear()
	_generated_halt_pc = KonadoProgram.INVALID_PC
	_program = KonadoProgram.new()
	_program.schema_version = KonadoScriptCommandRegistry.SCHEMA_VERSION
	_program.source_path = path
	_program.source_sha256 = source_sha256
	_program.dependencies = dependencies.duplicate(true)


func _collect_branches(statements: Array) -> void:
	for statement in statements:
		if statement is KonadoScriptSyntaxTree.BranchNode:
			_branch_nodes[statement.branch_id] = statement


func _emit_sequence(statements: Array, scope: String) -> GraphFragment:
	var result := GraphFragment.new()
	var instruction_index := 0
	for statement in statements:
		if statement is KonadoScriptSyntaxTree.BranchNode:
			continue
		var current := _emit_statement(statement, "%s/%d" % [scope, instruction_index])
		instruction_index += 1
		if current.entry_pc == KonadoProgram.INVALID_PC:
			continue
		if result.entry_pc == KonadoProgram.INVALID_PC:
			result.entry_pc = current.entry_pc
		else:
			_connect_exits(result.exits, current.entry_pc)
		result.exits = current.exits
	return result


func _emit_statement(node: KonadoScriptSyntaxTree.ASTNode, logical_path: String) -> GraphFragment:
	if node is KonadoScriptSyntaxTree.IfElseNode:
		return _emit_if_else(node, logical_path)
	var fragment := GraphFragment.new()
	var instruction := _instruction_for(node)
	if instruction.is_empty():
		_error(node.line, "编译器无法生成当前语句")
		return fragment
	var stable_key := (
		"ks:id:%s" % String(node.parameters["id"])
		if node.parameters.has("id")
		else "ks:%s" % logical_path
	)
	var pc := _append_instruction(
		int(instruction["opcode"]), instruction.get("operands", []), stable_key, node.line
	)
	fragment.entry_pc = pc
	if instruction.has("branch_targets"):
		_pending_branch_targets.append(
			{"pc": pc, "kind": "choices", "symbols": instruction["branch_targets"]}
		)
	elif node is KonadoScriptSyntaxTree.JumpBranchNode:
		_pending_branch_targets.append({"pc": pc, "kind": "jump", "symbols": [node.target_branch]})
	elif node is KonadoScriptSyntaxTree.CallNode:
		_pending_branch_targets.append({"pc": pc, "kind": "call", "symbols": [node.target_branch]})
	if (
		int(instruction["opcode"])
		not in [
			KonadoOpcode.Type.CHOICE,
			KonadoOpcode.Type.HALT,
			KonadoOpcode.Type.JUMP_SCRIPT,
			KonadoOpcode.Type.JUMP_BRANCH,
			KonadoOpcode.Type.CALL_BRANCH,
			KonadoOpcode.Type.RETURN,
		]
	):
		fragment.exits.append({"pc": pc, "edge": "next"})
	elif node is KonadoScriptSyntaxTree.CallNode:
		# call 的 next_pcs 会被回填为目标分支入口；返回点（调用点之后的指令）
		# 借 true_pcs 保存，避免为单条指令扩展 Program 的边数组。
		fragment.exits.append({"pc": pc, "edge": "fallthrough"})
	elif node is KonadoScriptSyntaxTree.ChoiceGroupNode:
		# 所有选项都被 `if` / `once` 过滤掉时，执行流从这里继续；
		# true_pcs 保存选择组之后的位置（没有后续语句时接到生成的 halt）。
		fragment.exits.append({"pc": pc, "edge": "fallthrough"})
	return fragment


func _emit_if_else(node: KonadoScriptSyntaxTree.IfElseNode, logical_path: String) -> GraphFragment:
	var result := GraphFragment.new()
	var condition_pc := _append_instruction(
		KonadoOpcode.Type.CONDITION,
		[
			_intern(node.var_name),
			_condition_opcode(node.op),
			node.target_value,
			node.var_prefix == "%",
		],
		_stable_key(node, logical_path),
		node.line
	)
	result.entry_pc = condition_pc
	var if_fragment := _emit_sequence(node.if_body, logical_path + "/if")
	var else_fragment := _emit_sequence(node.else_body, logical_path + "/else")
	if if_fragment.entry_pc == KonadoProgram.INVALID_PC:
		result.exits.append({"pc": condition_pc, "edge": "true"})
	else:
		_program.true_pcs[condition_pc] = if_fragment.entry_pc
		result.exits.append_array(if_fragment.exits)
	if else_fragment.entry_pc == KonadoProgram.INVALID_PC:
		result.exits.append({"pc": condition_pc, "edge": "false"})
	else:
		_program.false_pcs[condition_pc] = else_fragment.entry_pc
		result.exits.append_array(else_fragment.exits)
	return result


func _instruction_for(node: KonadoScriptSyntaxTree.ASTNode) -> Dictionary:
	var result := {}
	if node is KonadoScriptSyntaxTree.DialogueNode:
		var interval := float(node.parameters.get("interval", -1.0))
		var speed := float(node.parameters.get("speed", 1.0))
		result = _instruction(
			KonadoOpcode.Type.DIALOGUE,
			[
				int(node.speaker_kind),
				_intern(node.speaker),
				_intern(node.content),
				interval,
				speed,
				_intern(node.voice_id)
			]
		)
	elif node is KonadoScriptSyntaxTree.BackgroundNode:
		result = _instruction(
			KonadoOpcode.Type.BACKGROUND,
			[
				_intern(node.background_name),
				int(BACKGROUND_EFFECTS_MAP.get(node.effect, BACKGROUND_EFFECTS_MAP["none"])),
				_duration(node),
			]
		)
	elif node is KonadoScriptSyntaxTree.ActorNode:
		result = _actor_instruction(node)
	elif node is KonadoScriptSyntaxTree.AudioNode:
		result = _audio_instruction(node)
	elif node is KonadoScriptSyntaxTree.CameraNode or node is KonadoScriptSyntaxTree.AsyncCamNode:
		result = _camera_instruction(node, node is KonadoScriptSyntaxTree.AsyncCamNode)
	elif node is KonadoScriptSyntaxTree.ChoiceGroupNode:
		var encoded: Array = []
		var targets := PackedStringArray()
		var filters: Array = []
		for option: KonadoScriptSyntaxTree.ChoiceOption in node.options:
			encoded.append(_intern(option.text))
			encoded.append(option.branch_target)
			targets.append(option.branch_target)
			var condition := {}
			if not option.condition.is_empty():
				condition = {
					"persistent": String(option.condition.get("prefix", "%")) == "%",
					"name": String(option.condition.get("name", "")),
					"operator": _condition_opcode(String(option.condition.get("op", "=="))),
					"value": option.condition.get("value"),
				}
			filters.append({"condition": condition, "once": option.once})
		result = _instruction(KonadoOpcode.Type.CHOICE, [encoded, filters])
		result["branch_targets"] = targets
	elif node is KonadoScriptSyntaxTree.VariableNode:
		result = _instruction(
			KonadoOpcode.Type.VARIABLE,
			[
				_intern(node.var_name),
				_variable_opcode(node.operation),
				node.operand,
				node.var_prefix == "%",
			]
		)
	elif node is KonadoScriptSyntaxTree.JumpNode:
		result = _instruction(KonadoOpcode.Type.JUMP_SCRIPT, [_intern(node.target_path)])
	elif node is KonadoScriptSyntaxTree.JumpBranchNode:
		result = _instruction(KonadoOpcode.Type.JUMP_BRANCH, [_intern(node.target_branch)])
	elif node is KonadoScriptSyntaxTree.CallNode:
		result = _instruction(KonadoOpcode.Type.CALL_BRANCH, [_intern(node.target_branch)])
	elif node is KonadoScriptSyntaxTree.ReturnNode:
		result = _instruction(KonadoOpcode.Type.RETURN)
	elif node is KonadoScriptSyntaxTree.SignalNode:
		result = _instruction(KonadoOpcode.Type.SIGNAL, [_intern(node.signal_content)])
	elif node is KonadoScriptSyntaxTree.AchievementNode:
		result = _achievement_instruction(node)
	elif node is KonadoScriptSyntaxTree.EndNode:
		result = _instruction(KonadoOpcode.Type.HALT)
	elif node is KonadoScriptSyntaxTree.ScreenTextNode:
		var encoded_lines := PackedInt32Array()
		for line: String in node.lines:
			encoded_lines.append(_intern(line))
		result = _instruction(KonadoOpcode.Type.SCREEN_TEXT, [encoded_lines])
	elif node is KonadoScriptSyntaxTree.ShowTextBoxNode:
		result = _instruction(
			KonadoOpcode.Type.TEXTBOX_SHOW,
			[float(node.parameters.get("duration", node.duration))],
		)
	elif node is KonadoScriptSyntaxTree.HideTextBoxNode:
		result = _instruction(
			KonadoOpcode.Type.TEXTBOX_HIDE,
			[float(node.parameters.get("duration", node.duration))],
		)
	elif node is KonadoScriptSyntaxTree.WaitSignalNode:
		result = _instruction(KonadoOpcode.Type.WAIT_SIGNAL, [_intern(node.signal_name)])
	return result


func _actor_instruction(node: KonadoScriptSyntaxTree.ActorNode) -> Dictionary:
	match node.action:
		"show":
			return _instruction(
				KonadoOpcode.Type.ACTOR_SHOW,
				[
					_intern(node.actor_name),
					_intern(node.state),
					Vector2(node.position, 0.0),
					_duration(node)
				]
			)
		"exit":
			return _instruction(
				KonadoOpcode.Type.ACTOR_EXIT, [_intern(node.actor_name), _duration(node)]
			)
		"change":
			return _instruction(
				KonadoOpcode.Type.ACTOR_CHANGE,
				[_intern(node.actor_name), _intern(node.state), _duration(node)]
			)
		"move":
			return _instruction(
				KonadoOpcode.Type.ACTOR_MOVE,
				[_intern(node.actor_name), Vector2(node.position, 0.0), _duration(node)]
			)
		"motion":
			return _instruction(
				KonadoOpcode.Type.ACTOR_MOTION,
				[_intern(node.actor_name), _intern(node.motion_name), _duration(node)]
			)
	return {}


func _audio_instruction(node: KonadoScriptSyntaxTree.AudioNode) -> Dictionary:
	if node.action == "stop":
		return _instruction(KonadoOpcode.Type.BGM_STOP)
	if node.target == "bgm":
		return _instruction(KonadoOpcode.Type.BGM_PLAY, [_intern(node.resource_name)])
	return _instruction(KonadoOpcode.Type.SFX_PLAY, [_intern(node.resource_name)])


func _achievement_instruction(node: KonadoScriptSyntaxTree.AchievementNode) -> Dictionary:
	match node.action:
		"unlock":
			return _instruction(KonadoOpcode.Type.ACHIEVEMENT_UNLOCK, [_intern(node.target_id)])
		"increment":
			return _instruction(
				KonadoOpcode.Type.ACHIEVEMENT_PROGRESS,
				[_intern(node.target_id), node.increment_value]
			)
		"set_flag":
			return _instruction(
				KonadoOpcode.Type.ACHIEVEMENT_FLAG, [_intern(node.target_id), node.flag_value]
			)
	return {}


func _camera_instruction(node: Variant, asynchronous: bool) -> Dictionary:
	var duration := _camera_duration(node)
	match node.action:
		"move":
			return _instruction(
				(
					KonadoOpcode.Type.CAMERA_MOVE_ASYNC
					if asynchronous
					else KonadoOpcode.Type.CAMERA_MOVE
				),
				[_intern(node.target_cam), _intern(node.tween_type), duration]
			)
		"reset":
			return _instruction(
				(
					KonadoOpcode.Type.CAMERA_RESET_ASYNC
					if asynchronous
					else KonadoOpcode.Type.CAMERA_RESET
				),
				[_intern(node.tween_type), duration]
			)
		"shake":
			return _instruction(
				(
					KonadoOpcode.Type.CAMERA_SHAKE_ASYNC
					if asynchronous
					else KonadoOpcode.Type.CAMERA_SHAKE
				),
				[duration]
			)
		"stop":
			return _instruction(KonadoOpcode.Type.CAMERA_STOP_ASYNC)
	return {}


func _instruction(opcode: int, operands: Array = []) -> Dictionary:
	return {"opcode": opcode, "operands": operands}


func _append_instruction(opcode: int, operands: Array, stable_key: String, line: int) -> int:
	var pc := _program.opcodes.size()
	_program.opcodes.append(opcode)
	_program.operand_offsets.append(_program.operands.size())
	_program.operand_counts.append(operands.size())
	_program.operands.append_array(operands)
	_program.next_pcs.append(KonadoProgram.INVALID_PC)
	_program.true_pcs.append(KonadoProgram.INVALID_PC)
	_program.false_pcs.append(KonadoProgram.INVALID_PC)
	_program.stable_keys.append(stable_key)
	_program.source_lines.append(line)
	return pc


func _connect_exits(exits: Array[Dictionary], target_pc: int) -> void:
	for exit: Dictionary in exits:
		var pc := int(exit["pc"])
		match String(exit["edge"]):
			"next":
				_program.next_pcs[pc] = target_pc
			"true":
				_program.true_pcs[pc] = target_pc
			"false":
				_program.false_pcs[pc] = target_pc
			"fallthrough":
				_program.true_pcs[pc] = target_pc


func _connect_to_halt(exits: Array[Dictionary], line: int) -> void:
	if exits.is_empty():
		return
	if _generated_halt_pc == KonadoProgram.INVALID_PC:
		_generated_halt_pc = _append_instruction(
			KonadoOpcode.Type.HALT, [], "ks:generated/halt", line
		)
	_connect_exits(exits, _generated_halt_pc)


func _resolve_branch_targets() -> void:
	for pending: Dictionary in _pending_branch_targets:
		var pc := int(pending["pc"])
		var symbols: Variant = pending["symbols"]
		if pending["kind"] == "jump":
			var symbol := String(symbols[0])
			if _branch_entries.has(symbol):
				_program.next_pcs[pc] = int(_branch_entries[symbol])
			else:
				_error(_program.source_lines[pc], "jump_branch 目标分支 '%s' 不存在或为空" % symbol)
			continue
		if pending["kind"] == "call":
			var call_symbol := String(symbols[0])
			if _branch_entries.has(call_symbol):
				_program.next_pcs[pc] = int(_branch_entries[call_symbol])
			else:
				_error(_program.source_lines[pc], "call 目标分支 '%s' 不存在或为空" % call_symbol)
			continue
		var encoded: Array = _program.operand_at(pc, 0, [])
		for index in range(symbols.size()):
			var symbol := String(symbols[index])
			if not _branch_entries.has(symbol):
				_error(_program.source_lines[pc], "选项目标分支 '%s' 不存在或为空" % symbol)
				continue
			encoded[index * 2 + 1] = _program.key_for_pc(int(_branch_entries[symbol]))
		_program.operands[_program.operand_offsets[pc]] = encoded


func _stable_key(node: KonadoScriptSyntaxTree.ASTNode, logical_path: String) -> String:
	return (
		"ks:id:%s" % String(node.parameters["id"])
		if node.parameters.has("id")
		else "ks:%s" % logical_path
	)


func _intern(value: String) -> int:
	if _constant_index.has(value):
		return int(_constant_index[value])
	var index := _program.constants.size()
	_program.constants.append(value)
	_constant_index[value] = index
	return index


func _duration(node: KonadoScriptSyntaxTree.ASTNode) -> float:
	return float(node.parameters.get("duration", -1.0))


func _camera_duration(node: Variant) -> float:
	if node.parameters.has("duration"):
		return float(node.parameters["duration"])
	if node.action == "shake":
		return node.shake_time if node.shake_time > 0.0 else 1.0
	if node.tween_type.is_empty() or node.tween_type == "none":
		return 0.0
	return node.tween_time if node.tween_time > 0.0 else 1.0


func _condition_opcode(operator: String) -> int:
	return ["==", ">", "<", ">=", "<=", "!="].find(operator)


func _variable_opcode(operation: String) -> int:
	return ["set", "add", "sub", "mul", "div"].find(operation)


func _control_flow_fingerprint() -> String:
	var context := HashingContext.new()
	if context.start(HashingContext.HASH_SHA256) != OK:
		return ""
	for pc in range(_program.instruction_count()):
		var structural_operands: Array = []
		var schema := KonadoScriptCommandRegistry.schema_for(_program.opcodes[pc])
		for operand_index in schema.size():
			var field: Array = schema[operand_index]
			if String(field[1]) == KonadoScriptCommandRegistry.CHOICES:
				var encoded: Array = _program.operand_at(pc, operand_index, [])
				var targets := PackedInt32Array()
				for choice_index in range(1, encoded.size(), 2):
					targets.append(_program.pc_for_key(String(encoded[choice_index])))
				structural_operands.append(targets)
			elif not bool(field[2]):
				structural_operands.append(
					_fingerprint_operand(pc, operand_index, String(field[1]))
				)
		var row := (
			"%s%d|%d|%d|%d|%s|%s"
			% [
				"" if pc == 0 else "\n",
				_program.opcodes[pc],
				_program.next_pcs[pc],
				_program.true_pcs[pc],
				_program.false_pcs[pc],
				_program.stable_keys[pc],
				JSON.stringify(structural_operands, "", true),
			]
		)
		context.update(row.to_utf8_buffer())
	return context.finish().hex_encode()


func _fingerprint_operand(pc: int, operand_index: int, field_type: String) -> Variant:
	var encoded: Variant = _program.operand_at(pc, operand_index)
	match field_type:
		KonadoScriptCommandRegistry.STRING:
			return _program.constant_at(int(encoded))
		KonadoScriptCommandRegistry.STRING_ARRAY:
			var decoded := PackedStringArray()
			for constant_index: int in encoded:
				decoded.append(_program.constant_at(constant_index))
			return decoded
	return encoded


func _error(line: int, message: String) -> void:
	if _errors.size() >= MAX_DIAGNOSTICS:
		return
	var formatted := "%s [行：%d] %s" % [_path, maxi(1, line), message]
	if not _errors.has(formatted):
		_errors.append(formatted)
		if console_output_enabled:
			push_error(formatted)
