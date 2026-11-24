@tool
extends Resource
class_name KonadoProgram

## Compact, immutable-by-convention KonadoScript executable representation.
##
## Runtime control flow uses integer program counters. Human-readable stable
## keys are kept only for saves, localization, diagnostics and hot reload.

const FORMAT_VERSION := 1
const COMPILER_ABI := "konado-2.9"
const INVALID_PC := -1

@export_storage var format_version := FORMAT_VERSION
@export_storage var compiler_abi := COMPILER_ABI
@export_storage var schema_version := KonadoScriptCommandRegistry.SCHEMA_VERSION
@export_storage var source_path := ""
@export_storage var source_sha256 := ""
@export_storage var control_flow_sha256 := ""
@export_storage var dependency_sha256 := ""

@export_storage var constants := PackedStringArray()
@export_storage var opcodes := PackedInt32Array()
@export_storage var operand_offsets := PackedInt32Array()
@export_storage var operand_counts := PackedInt32Array()
@export_storage var operands: Array = []
@export_storage var next_pcs := PackedInt32Array()
@export_storage var true_pcs := PackedInt32Array()
@export_storage var false_pcs := PackedInt32Array()
@export_storage var stable_keys := PackedStringArray()
@export_storage var source_lines := PackedInt32Array()
@export_storage var entry_pc := INVALID_PC
@export_storage var dependencies: Dictionary = {}

var _key_to_pc: Dictionary = {}
var _sealed := false


func instruction_count() -> int:
	return opcodes.size()


func is_valid() -> bool:
	return seal()


## Validate the complete executable once and publish its immutable runtime indexes.
##
## Program data is built or deserialized before this boundary. Runtime consumers
## only receive sealed Programs, so instruction lookup never rescans the complete
## instruction tape.
func seal() -> bool:
	if _sealed:
		return true
	var count := instruction_count()
	if not _valid_header(count):
		return false
	var keys := {}
	for key in stable_keys:
		if key.is_empty() or keys.has(key):
			return false
		keys[key] = true
	for instruction_pc in range(count):
		if not _valid_instruction(instruction_pc, count, keys):
			return false
	_rebuild_key_index()
	_sealed = true
	return true


func is_sealed() -> bool:
	return _sealed


func _valid_header(count: int) -> bool:
	return (
		format_version == FORMAT_VERSION
		and compiler_abi == COMPILER_ABI
		and schema_version == KonadoScriptCommandRegistry.SCHEMA_VERSION
		and operand_offsets.size() == count
		and operand_counts.size() == count
		and next_pcs.size() == count
		and true_pcs.size() == count
		and false_pcs.size() == count
		and stable_keys.size() == count
		and source_lines.size() == count
		and count > 0
		and entry_pc >= 0
		and entry_pc < count
	)


func _valid_instruction(pc: int, count: int, keys: Dictionary) -> bool:
	var opcode := opcode_at(pc)
	var schema := KonadoScriptCommandRegistry.schema_for(opcode)
	var offset := operand_offsets[pc]
	var operand_count := operand_counts[pc]
	if KonadoScriptCommandRegistry.definition_for_opcode(opcode).is_empty():
		return false
	if offset < 0 or operand_count < 0 or offset + operand_count > operands.size():
		return false
	if operand_count != schema.size():
		return false
	for edge in [next_pcs[pc], true_pcs[pc], false_pcs[pc]]:
		if edge != INVALID_PC and (edge < 0 or edge >= count):
			return false
	for index in range(schema.size()):
		if not _valid_operand(operands[offset + index], String(schema[index][1]), keys):
			return false
	return true


func _valid_operand(value: Variant, field_type: String, keys: Dictionary) -> bool:
	var valid := true
	match field_type:
		KonadoScriptCommandRegistry.STRING:
			valid = value is int and value >= 0 and value < constants.size()
		KonadoScriptCommandRegistry.STRING_ARRAY:
			valid = _valid_string_array(value)
		KonadoScriptCommandRegistry.CHOICES:
			valid = _valid_choices(value, keys)
		KonadoScriptCommandRegistry.FILTERS:
			valid = _valid_filters(value)
		KonadoScriptCommandRegistry.VALUE:
			valid = _valid_value(value)
	return valid


## 选项过滤表：与选项一一对应，每项携带 `once` 与可选的可见条件。
## filters 属于结构字段，本地化剧本必须与默认剧本完全一致。
func _valid_filters(value: Variant) -> bool:
	if not value is Array:
		return false
	for entry: Variant in value as Array:
		if not _valid_filter_entry(entry):
			return false
	return true


func _valid_filter_entry(entry: Variant) -> bool:
	if not entry is Dictionary:
		return false
	var filter: Dictionary = entry
	if not filter.get("once", false) is bool:
		return false
	var condition: Variant = filter.get("condition", {})
	if not condition is Dictionary:
		return false
	var condition_dict: Dictionary = condition
	if condition_dict.is_empty():
		return true
	return _valid_filter_condition(condition_dict)


func _valid_filter_condition(condition: Dictionary) -> bool:
	var name: Variant = condition.get("name", null)
	if not name is String or String(name).is_empty():
		return false
	if not condition.get("persistent", null) is bool:
		return false
	var operator: Variant = condition.get("operator", null)
	if not operator is int or int(operator) < 0 or int(operator) > 5:
		return false
	return _valid_value(condition.get("value"))


func _valid_value(value: Variant) -> bool:
	if (
		value == null
		or value is bool
		or value is int
		or value is float
		or value is String
		or value is Vector2
	):
		return true
	if not value is Dictionary:
		return false
	return (
		value.size() == 3
		and value.get("kind") == "variable"
		and value.get("name") is String
		and not String(value.get("name", "")).is_empty()
		and value.get("persistent") is bool
	)


func _valid_string_array(value: Variant) -> bool:
	if not value is PackedInt32Array:
		return false
	for constant_index in value:
		if constant_index < 0 or constant_index >= constants.size():
			return false
	return true


func _valid_choices(value: Variant, keys: Dictionary) -> bool:
	if not value is Array or value.is_empty() or value.size() % 2 != 0:
		return false
	for index in range(0, value.size(), 2):
		if not _valid_operand(value[index], KonadoScriptCommandRegistry.STRING, keys):
			return false
		if not value[index + 1] is String or not keys.has(value[index + 1]):
			return false
	return true


func opcode_at(pc: int) -> int:
	return opcodes[pc] if pc >= 0 and pc < opcodes.size() else -1


func operand_at(pc: int, index: int, default: Variant = null) -> Variant:
	if pc < 0 or pc >= operand_offsets.size() or index < 0 or index >= operand_counts[pc]:
		return default
	return operands[operand_offsets[pc] + index]


func string_operand_at(pc: int, index: int, default := "") -> String:
	var constant_index := int(operand_at(pc, index, -1))
	if constant_index < 0 or constant_index >= constants.size():
		return default
	return constants[constant_index]


func constant_at(index: int, default := "") -> String:
	return constants[index] if index >= 0 and index < constants.size() else default


func instruction_at(pc: int) -> KonadoInstruction:
	return KonadoInstruction.new(self, pc) if pc >= 0 and pc < instruction_count() else null


func fingerprint() -> String:
	return "%s:%s:%s:%s" % [compiler_abi, source_sha256, control_flow_sha256, dependency_sha256]


func to_payload() -> Dictionary:
	return {
		"format_version": format_version,
		"compiler_abi": compiler_abi,
		"schema_version": schema_version,
		"source_path": source_path,
		"source_sha256": source_sha256,
		"control_flow_sha256": control_flow_sha256,
		"dependency_sha256": dependency_sha256,
		"constants": constants,
		"opcodes": opcodes,
		"operand_offsets": operand_offsets,
		"operand_counts": operand_counts,
		"operands": operands,
		"next_pcs": next_pcs,
		"true_pcs": true_pcs,
		"false_pcs": false_pcs,
		"stable_keys": stable_keys,
		"source_lines": source_lines,
		"entry_pc": entry_pc,
		"dependencies": dependencies,
	}


static func from_payload(payload: Dictionary) -> KonadoProgram:
	var result := KonadoProgram.new()
	result.format_version = int(payload.get("format_version", -1))
	result.compiler_abi = String(payload.get("compiler_abi", ""))
	result.schema_version = int(payload.get("schema_version", -1))
	result.source_path = String(payload.get("source_path", ""))
	result.source_sha256 = String(payload.get("source_sha256", ""))
	result.control_flow_sha256 = String(payload.get("control_flow_sha256", ""))
	result.dependency_sha256 = String(payload.get("dependency_sha256", ""))
	result.constants = payload.get("constants", PackedStringArray())
	result.opcodes = payload.get("opcodes", PackedInt32Array())
	result.operand_offsets = payload.get("operand_offsets", PackedInt32Array())
	result.operand_counts = payload.get("operand_counts", PackedInt32Array())
	result.operands = payload.get("operands", [])
	result.next_pcs = payload.get("next_pcs", PackedInt32Array())
	result.true_pcs = payload.get("true_pcs", PackedInt32Array())
	result.false_pcs = payload.get("false_pcs", PackedInt32Array())
	result.stable_keys = payload.get("stable_keys", PackedStringArray())
	result.source_lines = payload.get("source_lines", PackedInt32Array())
	result.entry_pc = int(payload.get("entry_pc", INVALID_PC))
	result.dependencies = payload.get("dependencies", {})
	return result if result.seal() else null


func pc_for_key(stable_key: String) -> int:
	if stable_key.is_empty():
		return INVALID_PC
	if _key_to_pc.size() != stable_keys.size():
		_rebuild_key_index()
	return int(_key_to_pc.get(stable_key, INVALID_PC))


func key_for_pc(pc: int) -> String:
	return stable_keys[pc] if pc >= 0 and pc < stable_keys.size() else ""


func line_for_pc(pc: int) -> int:
	return source_lines[pc] if pc >= 0 and pc < source_lines.size() else -1


func clear_runtime_indexes() -> void:
	_key_to_pc.clear()
	_sealed = false


func _rebuild_key_index() -> void:
	_key_to_pc.clear()
	for pc in range(stable_keys.size()):
		var key := stable_keys[pc]
		if not key.is_empty():
			_key_to_pc[key] = pc
