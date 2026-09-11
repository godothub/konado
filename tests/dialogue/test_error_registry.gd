extends SceneTree

## 结构化错误反馈体系契约测试：
## 1) 注册表自身完整性（编号唯一 / 前缀正确 / 检出位置真实存在）；
## 2) AC-001（创建角色 ID 为空）从舞台层到失败信封的完整链路；
## 3) KonadoResult 的 <T, E> 约定与既有形状互操作。

var _failures := 0


class FakeStageController:
	extends KonadoStageController

	func _init() -> void:
		_actor_layer = Control.new()
		add_child(_actor_layer)

	func apply_background_tint_to_actors() -> void:
		pass


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_registry_integrity()
	_test_empty_actor_id_chain()
	_test_console_message_locating()
	_test_result_convention()
	_test_executor_enrichment()
	if _failures == 0:
		print("PASS: structured error feedback contract tests")
	quit(_failures)


func _test_registry_integrity() -> void:
	var codes := KonadoErrorRegistry.codes()
	_expect(codes.size() > 0, "the error registry is populated")
	var seen_ids := {}
	for code: String in codes:
		var entry := KonadoErrorRegistry.entry(code)
		var error_id := String(entry.get("id", ""))
		_expect(not error_id.is_empty(), "%s exposes a stable error id" % code)
		_expect(not seen_ids.has(error_id), "error id %s is unique (%s)" % [error_id, code])
		seen_ids[error_id] = code
		_expect(
			error_id.get_slice("-", 0) == String(entry.get("module", "")),
			"%s id prefix matches its module" % code,
		)
		_expect(
			KonadoErrorRegistry.MODULES.has(String(entry.get("module", ""))),
			"%s module is documented in MODULES" % code,
		)
		var owner := String(entry.get("owner", ""))
		var script_source := FileAccess.get_file_as_string("res://%s" % owner)
		_expect(not script_source.is_empty(), "%s owner file exists" % code)
		_expect(script_source.contains(code), "%s is really emitted by its owner file" % code)
		var symbol := String(entry.get("function", "")).get_slice(".", -1)
		_expect(
			script_source.contains("func %s" % symbol), "%s function exists in its owner" % code
		)
	_expect(
		KonadoErrorRegistry.id_for(&"stage.actor_id_empty") == "AC-001",
		"AC-001 is bound to the empty actor id failure",
	)
	_expect(
		KonadoErrorRegistry.describe(&"stage.actor_id_empty").begins_with("[AC-001]"),
		"describe() renders the documented id",
	)
	for locale in ["zh", "en", "ja", "ko", "tc"]:
		var doc := FileAccess.get_file_as_string(
			"res://docs/%s/latest/tutorial/core/error-codes.md" % locale
		)
		_expect(doc.contains("AC-001"), "%s error-code table documents AC-001" % locale)


func _test_empty_actor_id_chain() -> void:
	var stage := FakeStageController.new()
	var failures: Array[Dictionary] = []
	stage.operation_finished.connect(
		func(_request_id: int, _succeeded: bool, detail: Dictionary) -> void:
			failures.append(detail)
	)
	var request_id := stage.begin_operation_request()
	stage.show_actor("", 2, 1, "正常", null, null, -1.0, false, request_id)
	var failure := stage.get_last_failure()
	_expect_equal(failure.get("code"), "stage.actor_id_empty", "empty actor id is rejected")
	_expect_equal(failure.get("id"), "AC-001", "the rejection carries the stable error id")
	_expect_equal(failure.get("error_id"), "AC-001", "context keeps error_id for envelopes")
	_expect_equal(
		failure.get("function"),
		"KonadoStageController.show_actor",
		"the rejection points at the exact function",
	)
	_expect_equal(failure.get("resource_kind"), "actor", "the failure names the resource kind")
	_expect_equal(failure.get("severity"), "error", "the failure exposes a severity")
	_expect_equal(failures.size(), 1, "the stage reports the rejection once")
	if not failures.is_empty():
		_expect_equal(
			failures[0].get("code"),
			"stage.actor_id_empty",
			"the request-scoped result carries the same failure",
		)
	stage.free()


func _test_console_message_locating() -> void:
	var failure := (
		KonadoExecutionFailure
		. new(
			&"stage.actor_id_empty",
			"显示角色失败：角色 ID 不能为空",
			{"resource_kind": "actor", "resource_id": "", "operation": "actor.show"},
		)
	)
	_expect_equal(failure.error_id, "AC-001", "the envelope resolves the id from the registry")
	_expect_equal(
		failure.function,
		"KonadoStageController.show_actor",
		"the envelope resolves the detecting function",
	)
	_expect_equal(
		failure.owner,
		"addons/konado/runtime/stage/konado_stage_controller.gd",
		"the envelope resolves the owner file",
	)
	var console := failure.console_message()
	_expect(console.begins_with("[AC-001]"), "the console line starts with the error id")
	_expect(console.contains("KonadoStageController.show_actor"), "console names the function")
	_expect(
		failure.to_dictionary().has("instruction_key"),
		"the structured payload exposes instruction_key",
	)
	var located := (
		KonadoExecutionFailure
		. new(
			&"stage.actor_id_empty",
			"空角色 ID",
			{
				"source_path": "res://sample/demo/demo.ks",
				"source_line": 12,
				"instruction_key": "ks:res://sample/demo/demo.ks:12",
			},
		)
	)
	var located_console := located.console_message()
	_expect(
		located_console.contains("res://sample/demo/demo.ks:12"),
		"console reports the script position",
	)
	_expect(
		located_console.contains("ks:res://sample/demo/demo.ks:12"),
		"console reports the instruction key",
	)


func _test_result_convention() -> void:
	var success := KonadoResult.ok(42)
	_expect(KonadoResult.is_ok(success), "KonadoResult.ok is readable")
	_expect_equal(KonadoResult.value_of(success, 0), 42, "value_of returns the payload")
	var failure := KonadoResult.error(&"stage.actor_id_empty", "空角色 ID", {"actor_id": ""})
	_expect(not KonadoResult.is_ok(failure), "KonadoResult.error is not ok")
	_expect_equal(KonadoResult.code_of(failure), &"stage.actor_id_empty", "the code is preserved")
	_expect_equal(KonadoResult.id_of(failure), "AC-001", "the result carries the stable id")
	var structured := KonadoResult.error_of(failure)
	_expect_equal(structured.get("id"), "AC-001", "the nested error exposes the id")
	_expect_equal(
		structured.get("function"),
		"KonadoStageController.show_actor",
		"the nested error exposes the detecting function",
	)
	_expect_equal(
		String(Dictionary(structured.get("context", {})).get("actor_id", "missing")),
		"",
		"the nested error keeps the caller context",
	)
	_expect(
		KonadoResult.is_ok({"ok": true, "value": "existing"}),
		"KonadoResult reads the pre-existing {ok, value} shape",
	)


func _test_executor_enrichment() -> void:
	var manager := KonadoDialogueManager.new()
	var stage := FakeStageController.new()
	manager.stage_controller = stage
	var compiler := KonadoScriptCompiler.new()
	compiler.set_console_output_enabled(false)
	var instruction := compiler.compile_line(
		"background missing fade", 7, "res://tests/error-registry.ks"
	)
	var executor := KonadoInstructionExecutor.new(manager)
	_expect_equal(
		executor.execute(instruction, {}),
		KonadoVirtualMachine.Result.FAILED,
		"a missing background still fails atomically",
	)
	var failure := executor.get_failure()
	_expect(failure != null, "executor failures keep a structured payload")
	if failure != null:
		_expect_equal(failure.error_id, "AC-020", "the envelope maps to the documented id")
		_expect_equal(
			failure.function,
			"KonadoDialogueServices._display_background",
			"the envelope resolves where the failure was detected",
		)
		_expect_equal(
			failure.instruction_key,
			instruction.stable_key(),
			"the failure carries the failing instruction key",
		)
		_expect_equal(
			failure.source_path,
			"res://tests/error-registry.ks",
			"the failure carries the owning script",
		)
		_expect_equal(failure.source_line, 7, "the failure carries the instruction source line")
	stage.free()
	manager.free()


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	printerr("FAIL: %s" % message)


func _expect_equal(actual: Variant, expected: Variant, message: String) -> void:
	if actual == expected:
		return
	_failures += 1
	printerr("FAIL: %s\n  expected: %s\n  actual:   %s" % [message, expected, actual])
