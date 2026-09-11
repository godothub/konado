extends RefCounted
class_name KonadoRuntimeFailureReporter

## Builds and publishes the canonical runtime failure payload.
##
## Execution ownership and cancellation stay in the runtime failure controller;
## this object only snapshots immutable provenance and performs the final log.


static func capture_context(host: Node, instruction: KonadoInstruction) -> Dictionary:
	return {
		"instruction_id": instruction.stable_key() if instruction != null else "",
		"source_line": instruction.source_line() if instruction != null else -1,
		"program_counter": instruction.pc if instruction != null else KonadoProgram.INVALID_PC,
		"opcode": KonadoOpcode.name_of(instruction.opcode()) if instruction != null else "",
		"source_path": _source_path(host),
	}


static func build_report(
	failure: KonadoExecutionFailure, instruction_context: Dictionary
) -> Dictionary:
	var report := failure.to_dictionary()
	for context_key in instruction_context:
		report[context_key] = instruction_context[context_key]
	return report


static func publish(
	host: Node,
	failure: KonadoExecutionFailure,
	report: Dictionary,
	write_to_console := true,
) -> void:
	if write_to_console:
		push_error(format_line(failure, report))
	host.runtime_failure_reported.emit(report.duplicate(true))
	host.runtime_failed.emit(
		failure.message,
		String(report.get("instruction_id", "")),
		int(report.get("source_line", -1))
	)


## 控制台/日志单行格式：以稳定错误编号开头，随后是机器码与完整链路
## （检出函数、资源、操作、指令键、剧本位置），全部来自失败信封，避免重复拼接。
static func format_line(failure: KonadoExecutionFailure, report: Dictionary) -> String:
	var error_id := String(report.get("id", failure.error_id))
	var code := String(report.get("code", failure.code))
	var tag := "[%s] %s" % [error_id, code] if not error_id.is_empty() else code
	return "Konado %s: %s" % [tag, failure.console_message(false)]


static func _source_path(host: Node) -> String:
	if host.current_shot == null:
		return ""
	if host.current_shot.program != null:
		return host.current_shot.program.source_path
	return host.current_shot.source_path
