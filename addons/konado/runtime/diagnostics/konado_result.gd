extends RefCounted
class_name KonadoResult

## 统一的结构化结果约定：把「成功数据」与「结构化错误」分开表达。
##
## GDScript 没有 `Result<T, E>` 泛型，本项目用字典承载同一语义（`<T, E>` 的等价形态）：
##   成功 → `{"ok": true, "value": <T>}`
##   失败 → `{"ok": false, "code": ..., "id": ...}`，其 `error` 字段为结构化错误
##          （稳定编号 + 检出函数/文件 + 上下文）。
## 读取端用 `is_ok()` / `value_of()` / `error_of()`，可与既有 `{"ok", "value"}`、
## 以及 KonadoStageFailureReporter / KonadoExecutionFailure 的扁平形状互操作。


static func ok(value: Variant = null) -> Dictionary:
	return {"ok": true, "value": value}


## 构造失败结果：`code` 必须是 KonadoErrorRegistry 中登记的错误码。
static func error(code: StringName, message := "", context: Dictionary = {}) -> Dictionary:
	var located := KonadoErrorRegistry.location_for(code)
	var error_id := String(located.get("id", ""))
	return {
		"ok": false,
		"code": String(code),
		"id": error_id,
		"message": message,
		"error":
		{
			"code": String(code),
			"id": error_id,
			"message": message,
			"function": String(located.get("function", "")),
			"owner": String(located.get("owner", "")),
			"severity": String(located.get("severity", "error")),
			"context": context.duplicate(true),
		},
	}


static func is_ok(result: Variant) -> bool:
	return result is Dictionary and bool((result as Dictionary).get("ok", false))


static func value_of(result: Variant, fallback: Variant = null) -> Variant:
	if result is Dictionary:
		return (result as Dictionary).get("value", fallback)
	return fallback


static func error_of(result: Variant) -> Dictionary:
	if not result is Dictionary:
		return {}
	return Dictionary((result as Dictionary).get("error", {})).duplicate(true)


static func code_of(result: Variant) -> StringName:
	if not result is Dictionary:
		return &""
	return StringName((result as Dictionary).get("code", ""))


static func id_of(result: Variant) -> String:
	if not result is Dictionary:
		return ""
	return String((result as Dictionary).get("id", ""))
