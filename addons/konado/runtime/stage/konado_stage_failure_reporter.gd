extends RefCounted
class_name KonadoStageFailureReporter

## Builds the stable failure payload shared by direct stage API calls and the
## request-scoped atomic runtime, while keeping console reporting in one place.


static func record_actor(
	code: StringName,
	message: String,
	operation: String,
	actor_id: String,
	report_errors: bool,
	cause := "",
	as_warning := false,
) -> Dictionary:
	return record(code, message, operation, "actor", actor_id, report_errors, cause, as_warning)


## actor.show 专用：把失败载荷构建收敛到上报器，控制器只保留两行调用模式。
static func record_actor_show(
	code: StringName,
	message: String,
	actor_id: String,
	report_errors: bool,
	cause := "",
	as_warning := false,
) -> Dictionary:
	return record_actor(code, message, "actor.show", actor_id, report_errors, cause, as_warning)


static func record(
	code: StringName,
	message: String,
	operation: String,
	resource_kind: String,
	resource_id: String,
	report_errors: bool,
	cause := "",
	as_warning := false,
) -> Dictionary:
	# 稳定编号与检出位置来自统一错误注册表：任何舞台失败都能定位到函数与文档对照表。
	var located := KonadoErrorRegistry.location_for(code)
	var error_id := String(located.get("id", ""))
	var failure := {
		"code": String(code),
		"id": error_id,
		"error_id": error_id,
		"message": message,
		"subsystem": "stage",
		"operation": operation,
		"function": String(located.get("function", "")),
		"owner": String(located.get("owner", "")),
		"severity": String(located.get("severity", "error")),
		"resource_kind": resource_kind,
		"resource_id": resource_id,
		"cause": cause,
	}
	if report_errors:
		var line := "[%s] %s" % [error_id, message] if not error_id.is_empty() else message
		if as_warning:
			push_warning(line)
		else:
			push_error(line)
	return failure
