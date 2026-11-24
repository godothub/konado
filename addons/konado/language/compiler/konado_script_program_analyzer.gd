extends RefCounted
class_name KonadoScriptProgramAnalyzer

## Non-recursive fixed-point semantic analysis over executable control flow.

const MAX_STEPS := 2_000_000
const MAX_DIAGNOSTICS := 256

var _errors: Array[String] = []
var _warnings: Array[String] = []
var _seen: Dictionary = {}


func analyze(program: KonadoProgram) -> bool:
	_errors.clear()
	_warnings.clear()
	_seen.clear()
	if program == null or not program.is_valid():
		_errors.append("Program 语义分析收到无效输入")
		return false
	var incoming: Array[Dictionary] = []
	incoming.resize(program.instruction_count())
	incoming[program.entry_pc] = _empty_state()
	var has_state := {program.entry_pc: true}
	var queue := [program.entry_pc]
	var queued := {program.entry_pc: true}
	var cursor := 0
	var steps := 0
	while cursor < queue.size():
		if _errors.size() >= MAX_DIAGNOSTICS:
			return false
		steps += 1
		if steps > MAX_STEPS:
			_errors.append("Program 数据流分析超过安全预算")
			return false
		var pc := int(queue[cursor])
		cursor += 1
		queued.erase(pc)
		var before: Dictionary = incoming[pc]
		_validate(program, pc, before)
		var after := _transfer(program, pc, before)
		for target in _targets(program, pc):
			var edge_state := after
			if (
				program.opcode_at(pc) == KonadoOpcode.Type.CALL_BRANCH
				and target == program.true_pcs[pc]
			):
				# 返回点：被调分支的执行结果无法在单文件里精确知道，
				# 只放宽后续检查，绝不据此产生错误。
				edge_state = _copy(after)
				edge_state["unknown_temps"] = true
				edge_state["unknown_actors"] = true
			var first_visit := not has_state.has(target)
			var merged := _copy(edge_state) if first_visit else _merge(incoming[target], edge_state)
			if first_visit or merged != incoming[target]:
				incoming[target] = merged
				has_state[target] = true
				if not queued.has(target):
					queue.append(target)
					queued[target] = true
	return _errors.is_empty()


func get_errors() -> Array[String]:
	return _errors.duplicate()


func get_warnings() -> Array[String]:
	return _warnings.duplicate()


func _empty_state() -> Dictionary:
	return {
		"actor_must": {},
		"actor_may": {},
		"temp_must": {},
		"temp_types": {},
		# call 返回后，被调分支可能已经定义/改写了任意临时变量与演员，
		# 单文件数据流无法精确建模，因此这两个标记让后续检查保持保守（不误报）。
		"unknown_temps": false,
		"unknown_actors": false,
	}


func _copy(state: Dictionary) -> Dictionary:
	return {
		"actor_must": state["actor_must"].duplicate(),
		"actor_may": state["actor_may"].duplicate(),
		"temp_must": state["temp_must"].duplicate(),
		"temp_types": state["temp_types"].duplicate(true),
		"unknown_temps": bool(state.get("unknown_temps", false)),
		"unknown_actors": bool(state.get("unknown_actors", false)),
	}


func _validate(program: KonadoProgram, pc: int, state: Dictionary) -> void:
	var instruction := program.instruction_at(pc)
	var opcode := instruction.opcode()
	if (
		opcode
		in [
			KonadoOpcode.Type.ACTOR_CHANGE,
			KonadoOpcode.Type.ACTOR_MOVE,
			KonadoOpcode.Type.ACTOR_MOTION,
			KonadoOpcode.Type.ACTOR_EXIT
		]
	):
		_validate_actor(program, pc, String(instruction.value(&"actor")), state)
	if opcode == KonadoOpcode.Type.VARIABLE:
		var persistent := bool(instruction.value(&"persistent"))
		var operation := int(instruction.value(&"operation"))
		var name := String(instruction.value(&"name"))
		if (
			not persistent
			and operation != KonadoVariableStore.Operation.SET
			and not bool(state["unknown_temps"])
			and not state["temp_must"].has(name)
		):
			_error(program, pc, "临时变量 '$%s' 在当前所有路径上尚未定义" % name)
		var operand := instruction.value(&"operand")
		_validate_reference(program, pc, operand, state)
		_validate_variable_types(program, pc, instruction, state)
		if (
			operation == KonadoVariableStore.Operation.DIV
			and not operand is Dictionary
			and float(operand) == 0.0
		):
			_error(program, pc, "变量除法的除数不能为零")
	if opcode == KonadoOpcode.Type.CONDITION:
		if not bool(instruction.value(&"persistent")):
			var name := String(instruction.value(&"variable"))
			if not bool(state["unknown_temps"]) and not state["temp_must"].has(name):
				_error(program, pc, "条件引用的临时变量 '$%s' 在当前所有路径上尚未定义" % name)
		_validate_reference(program, pc, instruction.value(&"target"), state)
		_validate_condition_types(program, pc, instruction, state)
	if opcode == KonadoOpcode.Type.DIALOGUE:
		var speaker_kind := int(instruction.value(&"speaker_kind"))
		var speaker := String(instruction.value(&"speaker"))
		if (
			speaker_kind == KonadoScriptSyntaxTree.DialogueNode.SpeakerKind.TEMPORARY_VARIABLE
			and not bool(state["unknown_temps"])
			and not state["temp_must"].has(speaker)
		):
			_error(program, pc, "对话署名引用的临时变量 '$%s' 在当前所有路径上尚未定义" % speaker)
		elif (
			speaker_kind == KonadoScriptSyntaxTree.DialogueNode.SpeakerKind.TEMPORARY_VARIABLE
			and not bool(state["unknown_temps"])
		):
			var speaker_type := String(state["temp_types"].get(speaker, "unknown"))
			if speaker_type not in ["string", "unknown", "variant"]:
				_error(program, pc, "对话署名变量 '$%s' 必须保存字符串演员 ID" % speaker)
	if opcode == KonadoOpcode.Type.CHOICE:
		_validate_choice_filters(program, pc, instruction, state)


## choice 的 `if <条件>` 参与与 if 语句相同的临时变量可定义性检查。
func _validate_choice_filters(
	program: KonadoProgram, pc: int, instruction: KonadoInstruction, state: Dictionary
) -> void:
	var filters: Variant = instruction.value(&"filters", [])
	if not filters is Array:
		return
	for filter: Variant in filters:
		if not filter is Dictionary:
			continue
		var condition: Variant = (filter as Dictionary).get("condition", {})
		if not condition is Dictionary:
			continue
		var condition_dict: Dictionary = condition
		if condition_dict.is_empty():
			continue
		var name := String(condition_dict.get("name", ""))
		if (
			not bool(condition_dict.get("persistent", false))
			and not bool(state["unknown_temps"])
			and not state["temp_must"].has(name)
		):
			_error(program, pc, "choice 条件引用的临时变量 '$%s' 在当前所有路径上尚未定义" % name)
		_validate_reference(program, pc, condition_dict.get("value"), state)


func _validate_actor(program: KonadoProgram, pc: int, actor: String, state: Dictionary) -> void:
	# call 返回后无法知道被调分支展示/移除了哪些演员，跳过而非误报。
	if bool(state.get("unknown_actors", false)):
		return
	if state["actor_must"].has(actor):
		return
	if state["actor_may"].has(actor):
		_error(program, pc, "角色 '%s' 只在部分路径上存在" % actor)
	else:
		# A KonadoScript can intentionally continue a stage prepared by its caller or
		# by a previous file reached through `jump`. A single-file compiler therefore
		# cannot prove that an actor absent from the local flow is absent at runtime.
		# Preserve the diagnostic without rejecting valid cross-file compositions.
		_warning(program, pc, "无法在当前文件中确认角色 '%s' 已入场" % actor)


func _validate_reference(
	program: KonadoProgram, pc: int, value: Variant, state: Dictionary
) -> void:
	if bool(state.get("unknown_temps", false)):
		return
	if not value is Dictionary or value.get("kind") != "variable":
		return
	if bool(value.get("persistent", false)):
		return
	var name := String(value.get("name", ""))
	if not state["temp_must"].has(name):
		_error(program, pc, "引用的临时变量 '$%s' 在当前所有路径上尚未定义" % name)


func _validate_variable_types(
	program: KonadoProgram, pc: int, instruction: KonadoInstruction, state: Dictionary
) -> void:
	# 被调分支可能改写了同一变量的类型；调用之后不再做类型推断。
	if bool(state.get("unknown_temps", false)):
		return
	var operation := int(instruction.value(&"operation"))
	if operation == KonadoVariableStore.Operation.SET:
		return
	if bool(instruction.value(&"persistent")):
		return
	var name := String(instruction.value(&"name"))
	var current_type := String(state["temp_types"].get(name, "unknown"))
	var operand_type := _operand_type(instruction.value(&"operand"), state)
	if current_type in ["unknown", "variant"] or operand_type in ["unknown", "variant"]:
		return
	if operation == KonadoVariableStore.Operation.ADD:
		if (
			(current_type == "string" and operand_type == "string")
			or (_is_numeric_type(current_type) and _is_numeric_type(operand_type))
		):
			return
	else:
		if _is_numeric_type(current_type) and _is_numeric_type(operand_type):
			return
	_error(program, pc, "变量运算的左右值类型不兼容：%s 与 %s" % [current_type, operand_type])


func _validate_condition_types(
	program: KonadoProgram, pc: int, instruction: KonadoInstruction, state: Dictionary
) -> void:
	if bool(state.get("unknown_temps", false)):
		return
	var operator := int(instruction.value(&"operator"))
	if operator in [0, 5] or bool(instruction.value(&"persistent")):
		return
	var left_type := String(
		state["temp_types"].get(String(instruction.value(&"variable")), "unknown")
	)
	var right_type := _operand_type(instruction.value(&"target"), state)
	if left_type in ["unknown", "variant"] or right_type in ["unknown", "variant"]:
		return
	if (
		(left_type == "string" and right_type == "string")
		or (_is_numeric_type(left_type) and _is_numeric_type(right_type))
	):
		return
	_error(program, pc, "有序比较要求同为字符串或数值，实际为 %s 与 %s" % [left_type, right_type])


func _transfer(program: KonadoProgram, pc: int, before: Dictionary) -> Dictionary:
	var result := _copy(before)
	var instruction := program.instruction_at(pc)
	match instruction.opcode():
		KonadoOpcode.Type.ACTOR_SHOW:
			var actor := String(instruction.value(&"actor"))
			result["actor_must"][actor] = true
			result["actor_may"][actor] = true
		KonadoOpcode.Type.ACTOR_EXIT:
			var actor := String(instruction.value(&"actor"))
			result["actor_must"].erase(actor)
			result["actor_may"].erase(actor)
		KonadoOpcode.Type.VARIABLE:
			if not bool(instruction.value(&"persistent")):
				var name := String(instruction.value(&"name"))
				result["temp_must"][name] = true
				var operand_type := _operand_type(instruction.value(&"operand"), before)
				var operation := int(instruction.value(&"operation"))
				if operation == KonadoVariableStore.Operation.SET:
					result["temp_types"][name] = operand_type
				elif operation == KonadoVariableStore.Operation.ADD:
					var current_type := String(before["temp_types"].get(name, "unknown"))
					result["temp_types"][name] = (
						"string"
						if current_type == "string" and operand_type == "string"
						else _numeric_result_type(current_type, operand_type)
					)
				else:
					result["temp_types"][name] = (
						"float"
						if operation == KonadoVariableStore.Operation.DIV
						else _numeric_result_type(
							String(before["temp_types"].get(name, "unknown")), operand_type
						)
					)
	return result


func _merge(left: Dictionary, right: Dictionary) -> Dictionary:
	return {
		"actor_must": _intersection(left["actor_must"], right["actor_must"]),
		"actor_may": _union(left["actor_may"], right["actor_may"]),
		"temp_must": _intersection(left["temp_must"], right["temp_must"]),
		"temp_types": _merge_types(left["temp_types"], right["temp_types"]),
		"unknown_temps":
		bool(left.get("unknown_temps", false)) or bool(right.get("unknown_temps", false)),
		"unknown_actors":
		bool(left.get("unknown_actors", false)) or bool(right.get("unknown_actors", false)),
	}


func _merge_types(left: Dictionary, right: Dictionary) -> Dictionary:
	var result := {}
	for name in _union(left, right):
		var left_type := String(left.get(name, "unknown"))
		var right_type := String(right.get(name, "unknown"))
		result[name] = left_type if left_type == right_type else "variant"
	return result


func _intersection(left: Dictionary, right: Dictionary) -> Dictionary:
	var result := {}
	for key in left:
		if right.has(key):
			result[key] = true
	return result


func _union(left: Dictionary, right: Dictionary) -> Dictionary:
	var result := left.duplicate()
	for key in right:
		result[key] = true
	return result


func _targets(program: KonadoProgram, pc: int) -> PackedInt32Array:
	var instruction := program.instruction_at(pc)
	var result := PackedInt32Array()
	for target in [instruction.next_pc(), instruction.true_pc(), instruction.false_pc()]:
		if target != KonadoProgram.INVALID_PC and not result.has(target):
			result.append(target)
	if instruction.opcode() == KonadoOpcode.Type.CHOICE:
		for choice: Dictionary in instruction.value(&"options", []):
			var target := int(choice["target_pc"])
			if target != KonadoProgram.INVALID_PC and not result.has(target):
				result.append(target)
	return result


func _operand_type(value: Variant, state: Dictionary) -> String:
	if value is Dictionary and value.get("kind") == "variable":
		if bool(value.get("persistent", false)):
			return "unknown"
		return String(state["temp_types"].get(String(value.get("name", "")), "unknown"))
	var built_in_types := {
		TYPE_INT: "int",
		TYPE_FLOAT: "float",
		TYPE_BOOL: "bool",
		TYPE_STRING: "string",
	}
	return String(built_in_types.get(typeof(value), "unknown"))


func _is_numeric_type(type_name: String) -> bool:
	return type_name in ["int", "float"]


func _numeric_result_type(left: String, right: String) -> String:
	if not _is_numeric_type(left) or not _is_numeric_type(right):
		return "variant"
	return "float" if left == "float" or right == "float" else "int"


func _error(program: KonadoProgram, pc: int, message: String) -> void:
	if _errors.size() >= MAX_DIAGNOSTICS:
		return
	var full := "第 %d 行：%s" % [program.line_for_pc(pc), message]
	if _seen.has(full):
		return
	_seen[full] = true
	_errors.append(full)


func _warning(program: KonadoProgram, pc: int, message: String) -> void:
	if _errors.size() + _warnings.size() >= MAX_DIAGNOSTICS:
		return
	var full := "第 %d 行：%s" % [program.line_for_pc(pc), message]
	if _seen.has(full):
		return
	_seen[full] = true
	_warnings.append(full)
