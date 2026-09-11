extends RefCounted
class_name KonadoExecutionFailure

## Structured runtime failure passed from an instruction subsystem to the
## dialogue manager. Only the manager writes the final error to Godot's log.
##
## 结构化错误信封：`code`（点分命名空间主键）+ `id`（稳定错误编号，来自
## KonadoErrorRegistry）+ `function`/`owner`（检出位置）+ `resource_*`（涉及的资源）
## + `instruction_key`/`source_path`/`source_line`（剧本定位），共同回答“哪一步报错”。

var code := &"runtime.failed"
var message := "指令执行失败"
var subsystem := "runtime"
var operation := ""
var resource_kind := ""
var resource_id := ""
var cause := ""
## 稳定错误编号（如 AC-001）与检出函数/文件，缺省时由注册表补齐。
var error_id := ""
var function := ""
var owner := ""
var severity := "error"
## 脚本定位：出错指令所属剧本、指令键与源码行号。
var source_path := ""
var instruction_key := ""
var source_line := 0


func _init(
	failure_code: StringName = &"runtime.failed",
	failure_message := "指令执行失败",
	context: Dictionary = {},
) -> void:
	code = failure_code
	message = failure_message if not failure_message.is_empty() else "指令执行失败"
	subsystem = String(context.get("subsystem", "runtime"))
	operation = String(context.get("operation", ""))
	resource_kind = String(context.get("resource_kind", ""))
	resource_id = String(context.get("resource_id", ""))
	cause = String(context.get("cause", ""))
	source_path = String(context.get("source_path", ""))
	instruction_key = String(context.get("instruction_key", ""))
	source_line = int(context.get("source_line", 0))
	# 未显式提供时，用注册表补齐“检出位置”与稳定编号，保证任何失败都能定位到函数与文档。
	var located := KonadoErrorRegistry.location_for(code)
	error_id = String(context.get("error_id", located.get("id", "")))
	function = String(context.get("function", located.get("function", "")))
	owner = String(context.get("owner", located.get("owner", "")))
	severity = String(context.get("severity", located.get("severity", "error")))


func to_dictionary() -> Dictionary:
	return {
		"code": String(code),
		"id": error_id,
		"message": message,
		"subsystem": subsystem,
		"operation": operation,
		"function": function,
		"owner": owner,
		"severity": severity,
		"resource_kind": resource_kind,
		"resource_id": resource_id,
		"cause": cause,
		"instruction_key": instruction_key,
		"source_path": source_path,
		"source_line": source_line,
	}


func console_message(include_id := true) -> String:
	var details := PackedStringArray()
	if not function.is_empty():
		details.append("于 %s" % function)
	if not operation.is_empty() and operation != function:
		details.append("操作=%s" % operation)
	if not resource_kind.is_empty() and not resource_id.is_empty():
		details.append("%s=%s" % [resource_kind, resource_id])
	elif not resource_id.is_empty():
		details.append("资源=%s" % resource_id)
	elif not resource_kind.is_empty():
		details.append("资源类型=%s" % resource_kind)
	if not cause.is_empty() and cause != message:
		details.append("原因=%s" % cause)
	if not instruction_key.is_empty():
		details.append("指令=%s" % instruction_key)
	if not source_path.is_empty():
		details.append("位置=%s:%d" % [source_path, source_line])
	var tag := "[%s] " % error_id if include_id and not error_id.is_empty() else ""
	return (tag + message) if details.is_empty() else "%s%s；%s" % [tag, message, "，".join(details)]
