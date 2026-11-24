extends RefCounted

## choice 的运行期辅助：`once` 使用记录与可见条件求值。
## 使用记录属于运行期状态（随回退/存档还原），但不是脚本变量；
## 条件求值失败只警告一次，避免一个可选菜单项把整个剧情打断。

var _host: KonadoDialogueManager
var _used_choices: Dictionary = {}
var _condition_warnings: Dictionary = {}


func _init(host: KonadoDialogueManager) -> void:
	_host = host


## once 选项的身份：choice 指令稳定键 + 目标分支稳定键 + 组内序号。
## 不含选项文本，因此切换语言或改文案不会让“已选过”失效。
func once_key(instruction: KonadoInstruction, choice: Dictionary) -> String:
	var target_pc := int(choice.get("target_pc", KonadoProgram.INVALID_PC))
	var target_key := ""
	if _host.current_shot != null and target_pc >= 0:
		target_key = _host.current_shot.key_for_pc(target_pc)
	return "%s|%s|%d" % [instruction.stable_key(), target_key, int(choice.get("index", -1))]


func is_used(instruction: KonadoInstruction, choice: Dictionary) -> bool:
	return _used_choices.has(once_key(instruction, choice))


func mark_used(instruction: KonadoInstruction, choice: Dictionary) -> void:
	_used_choices[once_key(instruction, choice)] = true


## 清空 once 记录与条件警告（新开局时调用）。
func clear() -> void:
	_used_choices.clear()
	_condition_warnings.clear()


func export_state() -> Dictionary:
	return _used_choices.duplicate(true)


func restore_state(value: Variant) -> bool:
	if not value is Dictionary:
		return false
	_used_choices = (value as Dictionary).duplicate(true)
	return true


## choice 的可见条件：变量不存在或类型不兼容时按“条件不成立”处理。
func matches(condition: Dictionary) -> bool:
	var left_result := _read_operand(
		String(condition.get("name", "")), bool(condition.get("persistent", false))
	)
	if not bool(left_result.get("ok", false)):
		return false
	var right: Variant = condition.get("value")
	if right is Dictionary and right.get("kind") == "variable":
		var right_result := _read_operand(
			String(right.get("name", "")), bool(right.get("persistent", false))
		)
		if not bool(right_result.get("ok", false)):
			return false
		right = right_result.get("value")
	var operator := int(condition.get("operator", 0))
	var comparison := _host._compare_values(left_result.get("value"), right, operator)
	if not bool(comparison.get("ok", false)):
		_warn_once(
			"type:%s|%d" % [String(condition.get("name", "")), operator],
			"choice 条件的左右值类型不兼容，按条件不成立处理",
		)
		return false
	return bool(comparison.get("value", false))


func _read_operand(name: String, persistent: bool) -> Dictionary:
	var exists := (
		(_host.variable_store != null and _host.variable_store.has(name))
		if persistent
		else _host._temp_variables.has(name)
	)
	if not exists:
		var prefix := "%" if persistent else "$"
		_warn_once(
			prefix + name,
			"choice 条件引用的变量 '%s%s' 不存在，按条件不成立处理" % [prefix, name],
		)
		return {"ok": false}
	return {"ok": true, "value": _host._read_variable(name, persistent)}


func _warn_once(key: String, message: String) -> void:
	if _condition_warnings.has(key):
		return
	_condition_warnings[key] = true
	push_warning("Konado: " + message)
