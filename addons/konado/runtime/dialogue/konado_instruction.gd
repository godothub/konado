extends RefCounted
class_name KonadoInstruction

## Immutable, zero-copy view over one Program instruction.

var pc := KonadoProgram.INVALID_PC
var _program: KonadoProgram
var _overlay: KonadoLocaleOverlay


func _init(
	program: KonadoProgram, instruction_pc: int, overlay: KonadoLocaleOverlay = null
) -> void:
	_program = program
	pc = instruction_pc
	_overlay = overlay if overlay != null and overlay.is_compatible(program) else null


func opcode() -> int:
	return _program.opcode_at(pc)


func stable_key() -> String:
	return _program.key_for_pc(pc)


func source_line() -> int:
	return _program.line_for_pc(pc)


## 指令所属剧本路径（用于失败定位：`source_path`）。
func source_path() -> String:
	return _program.source_path


func next_pc() -> int:
	return _program.next_pcs[pc]


func true_pc() -> int:
	return _program.true_pcs[pc]


func false_pc() -> int:
	return _program.false_pcs[pc]


func value(name: StringName, default: Variant = null) -> Variant:
	var schema := KonadoScriptCommandRegistry.schema_for(opcode())
	for index in range(schema.size()):
		if StringName(schema[index][0]) != name:
			continue
		var encoded := _program.operand_at(pc, index, default)
		var decoded: Variant
		match String(schema[index][1]):
			KonadoScriptCommandRegistry.STRING:
				decoded = _program.constant_at(int(encoded))
			KonadoScriptCommandRegistry.STRING_ARRAY:
				var result := PackedStringArray()
				for constant_index: int in encoded:
					result.append(_program.constant_at(constant_index))
				decoded = result
			KonadoScriptCommandRegistry.CHOICES:
				decoded = _decode_choices(encoded)
			_:
				decoded = encoded
		return _overlay.value_for(stable_key(), name, decoded) if _overlay != null else decoded
	return default


func _decode_choices(encoded: Array) -> Array[Dictionary]:
	var choices: Array[Dictionary] = []
	for index in range(0, encoded.size(), 2):
		(
			choices
			. append(
				{
					"text": _program.constant_at(int(encoded[index])),
					"target_pc": _program.pc_for_key(String(encoded[index + 1])),
				}
			)
		)
	return choices
