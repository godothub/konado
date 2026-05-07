extends RefCounted
class_name KND_VariableCondition

enum Operator {
	EQ,
	NEQ,
	GT,
	LT,
	GTE,
	LTE
}

static func evaluate(store: KND_VariableStore, var_name: String, op: Operator, target: Variant) -> bool:
	if not store.has(var_name):
		return false

	var current = store.get_value(var_name)

	match op:
		Operator.EQ:
			return _compare_eq(current, target)
		Operator.NEQ:
			return not _compare_eq(current, target)
		Operator.GT:
			return _compare_gt(current, target)
		Operator.LT:
			return _compare_lt(current, target)
		Operator.GTE:
			return _compare_gte(current, target)
		Operator.LTE:
			return _compare_lte(current, target)

	return false

static func _compare_eq(a: Variant, b: Variant) -> bool:
	if typeof(a) == TYPE_STRING or typeof(b) == TYPE_STRING:
		return str(a) == str(b)
	if typeof(a) == TYPE_BOOL or typeof(b) == TYPE_BOOL:
		return bool(a) == bool(b)
	return float(a) == float(b)

static func _compare_gt(a: Variant, b: Variant) -> bool:
	return float(a) > float(b)

static func _compare_lt(a: Variant, b: Variant) -> bool:
	return float(a) < float(b)

static func _compare_gte(a: Variant, b: Variant) -> bool:
	return float(a) >= float(b)

static func _compare_lte(a: Variant, b: Variant) -> bool:
	return float(a) <= float(b)

static func operator_from_string(op_str: String) -> Operator:
	match op_str:
		"==":
			return Operator.EQ
		"!=":
			return Operator.NEQ
		">":
			return Operator.GT
		"<":
			return Operator.LT
		">=":
			return Operator.GTE
		"<=":
			return Operator.LTE
	return Operator.EQ
