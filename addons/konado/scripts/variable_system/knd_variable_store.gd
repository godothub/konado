extends KND_Data
class_name KND_VariableStore

enum VarType {
	INT,
	FLOAT,
	BOOL,
	STRING
}

enum Operation {
	SET,
	ADD,
	SUB,
	MUL,
	DIV
}

signal variable_changed(name: String, value: Variant)
signal variable_added(name: String, value: Variant)
signal variable_removed(name: String)

@export var _variables: Dictionary = {}
@export var _types: Dictionary = {}

func has(name: String) -> bool:
	return _variables.has(name)

func get_value(name: String, default: Variant = null) -> Variant:
	if _variables.has(name):
		return _variables[name]
	return default

func get_int(name: String, default: int = 0) -> int:
	var v = get_value(name)
	if typeof(v) == TYPE_INT or typeof(v) == TYPE_FLOAT:
		return int(v)
	if typeof(v) == TYPE_BOOL:
		return 1 if v else 0
	if typeof(v) == TYPE_STRING:
		return int(v) if v.is_valid_int() else default
	return default

func get_float(name: String, default: float = 0.0) -> float:
	var v = get_value(name)
	if typeof(v) == TYPE_FLOAT or typeof(v) == TYPE_INT:
		return float(v)
	if typeof(v) == TYPE_STRING:
		return float(v) if v.is_valid_float() else default
	return default

func get_bool(name: String, default: bool = false) -> bool:
	var v = get_value(name)
	if typeof(v) == TYPE_BOOL:
		return v
	if typeof(v) == TYPE_INT:
		return v != 0
	if typeof(v) == TYPE_FLOAT:
		return v != 0.0
	if typeof(v) == TYPE_STRING:
		return v.to_lower() == "true"
	return default

func get_string(name: String, default: String = "") -> String:
	var v = get_value(name)
	if typeof(v) == TYPE_STRING:
		return v
	return str(v) if v != null else default

func set_value(name: String, value: Variant) -> void:
	var existed = _variables.has(name)
	_variables[name] = value
	_types[name] = typeof(value)
	if existed:
		variable_changed.emit(name, value)
	else:
		variable_added.emit(name, value)

func apply_operation(name: String, op: Operation, operand: Variant) -> void:
	match op:
		Operation.SET:
			set_value(name, operand)
		Operation.ADD:
			var current = get_value(name, 0)
			if typeof(current) == TYPE_STRING:
				set_value(name, str(current) + str(operand))
			else:
				set_value(name, get_float(name) + float(operand))
		Operation.SUB:
			set_value(name, get_float(name) - float(operand))
		Operation.MUL:
			set_value(name, get_float(name) * float(operand))
		Operation.DIV:
			var divisor = float(operand)
			if divisor == 0.0:
				push_error("变量 '%s' 除法操作除数为零" % name)
				return
			set_value(name, get_float(name) / divisor)

func remove(name: String) -> void:
	if _variables.has(name):
		_variables.erase(name)
		_types.erase(name)
		variable_removed.emit(name)

func clear() -> void:
	_variables.clear()
	_types.clear()

func get_all() -> Dictionary:
	return _variables.duplicate()

func get_count() -> int:
	return _variables.size()

func to_dict() -> Dictionary:
	return {
		"variables": _variables.duplicate(),
		"types": _types.duplicate()
	}

func from_dict(data: Dictionary) -> void:
	clear()
	if data.has("variables"):
		_variables = data["variables"].duplicate()
	if data.has("types"):
		_types = data["types"].duplicate()
