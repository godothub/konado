extends "res://tests/dialogue/dialogue_lifecycle_test_base.gd"

## 结构化错误反馈「报错画廊」自动校验。
##
## 直接读取 sample/error_gallery/*.ks 示例文件（示例与测试同一份来源），
## 用默认对话模板搭起真实运行期逐条触发失败，校验：
## 错误码 → 稳定编号 → 检出函数/文件 → 资源 → 剧本定位 → 可恢复动作 → 控制台单行格式；
## 并把每条样本打印成可读对照表。
##
## 运行：godot --headless --path . --script tests/dialogue/test_error_gallery.gd

const GALLERY_SAMPLES := [
	{
		"file": "res://sample/error_gallery/01_actor_show_missing.ks",
		"note": "显示一个没有配置的角色",
		"code": "stage.actor_not_found",
		"function": "KonadoDialogueServices._show_actor",
		"resource_kind": "actor",
	},
	{
		"file": "res://sample/error_gallery/02_actor_change_missing.ks",
		"note": "切换不在舞台上的角色状态",
		"code": "stage.actor_not_present",
		"function": "KonadoInstructionExecutor._actor_change",
		"resource_kind": "actor",
	},
	{
		"file": "res://sample/error_gallery/03_actor_motion_missing.ks",
		"note": "播放不在舞台上角色的动作",
		"code": "stage.actor_not_present",
		"function": "KonadoInstructionExecutor._actor_motion",
		"resource_kind": "actor",
	},
	{
		"file": "res://sample/error_gallery/04_actor_exit_missing.ks",
		"note": "让不存在的角色退场",
		"code": "stage.actor_not_present",
		"function": "KonadoInstructionExecutor._actor_exit",
		"resource_kind": "actor",
	},
	{
		"file": "res://sample/error_gallery/05_background_missing.ks",
		"note": "切换没有配置的背景",
		"code": "stage.background_not_found",
		"function": "KonadoDialogueServices._display_background",
		"resource_kind": "background",
	},
	{
		"file": "res://sample/error_gallery/06_bgm_missing.ks",
		"note": "播放不存在的背景音乐（未配置音乐列表）",
		"code": "audio.list_missing",
		"function": "KonadoDialogueServices._play_bgm",
		"resource_kind": "resource_list",
	},
	{
		"file": "res://sample/error_gallery/07_sfx_missing.ks",
		"note": "播放不存在的音效（未配置音效列表）",
		"code": "audio.list_missing",
		"function": "KonadoDialogueServices._play_bgm",
		"resource_kind": "resource_list",
	},
	{
		"file": "res://sample/error_gallery/08_camera_missing.ks",
		"note": "异步运镜但机位不存在",
		"code": "camera.move_rejected",
		"function": "KonadoInstructionExecutor._camera_move_async",
		"resource_kind": "camera_marker",
	},
	{
		"file": "res://sample/error_gallery/09_achievement_missing.ks",
		"note": "解锁不存在的成就（外部副作用屏障）",
		"code": "achievement.not_found",
		"function": "KonadoAchievementManager._operation_failure",
		"resource_kind": "achievement",
	},
	{
		"file": "res://sample/error_gallery/10_variable_missing.ks",
		"note": "条件引用未定义的变量（可重试）",
		"code": "variable.not_found",
		"function": "KonadoInstructionExecutor._condition_variable",
		"resource_kind": "variable",
	},
]


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var sample_count := GALLERY_SAMPLES.size() + 1
	print("=== Konado 结构化报错画廊（%d 个运行期样本）===" % sample_count)
	for index: int in GALLERY_SAMPLES.size():
		await _run_gallery_sample(index + 1, GALLERY_SAMPLES[index])
	await _run_empty_actor_id_sample()
	if _failures == 0:
		print("PASS: structured error feedback gallery (%d samples)" % sample_count)
	quit(_failures)


func _run_gallery_sample(index: int, sample: Dictionary) -> void:
	var manager := await _create_manager()
	manager.report_runtime_failures_to_console = false
	var path := String(sample["file"])
	var source := FileAccess.get_file_as_string(path)
	_expect(not source.is_empty(), "#%d 示例文件可读：%s" % [index, path])
	var shot := _compile_shot(source, path)
	if shot == null:
		await _free_node(manager)
		return
	manager.set_shot(shot)
	manager.start_dialogue()
	await _wait_for_state(manager, KonadoDialogueManager.DialogState.FAILED)
	var report := manager.pending_runtime_failure.duplicate(true)
	_print_gallery_row(index, sample, report)
	_assert_report(index, sample, report, path)
	var actions := report.get("recovery_actions", PackedStringArray()) as PackedStringArray
	if &"stop" in actions:
		manager.resolve_runtime_failure(&"stop")
	elif &"skip" in actions:
		manager.resolve_runtime_failure(&"skip")
	await _free_node(manager)


func _assert_report(index: int, sample: Dictionary, report: Dictionary, path: String) -> void:
	var label := "#%d %s" % [index, sample["note"]]
	var code := String(report.get("code", ""))
	var entry := KonadoErrorRegistry.entry(StringName(code))
	_expect_equal(code, sample["code"], "%s：错误码与示例约定一致" % label)
	_expect(KonadoErrorRegistry.exists(StringName(code)), "%s：错误码已登记注册表" % label)
	_expect_equal(String(report.get("id", "")), String(entry.get("id", "")), "%s：稳定编号来自注册表" % label)
	_expect_equal(String(report.get("function", "")), sample["function"], "%s：检出函数精确到那一步" % label)
	_expect_equal(
		String(report.get("owner", "")), String(entry.get("owner", "")), "%s：检出文件一致" % label
	)
	_expect_equal(
		String(report.get("severity", "")),
		String(entry.get("severity", "")),
		"%s：严重级别一致" % label,
	)
	_expect(not String(report.get("message", "")).is_empty(), "%s：保留人类可读描述" % label)
	_expect(int(report.get("source_line", 0)) > 0, "%s：指出出错剧本行号" % label)
	_expect(String(report.get("instruction_id", "")).begins_with("ks:"), "%s：指出出错指令键" % label)
	_expect_equal(String(report.get("source_path", "")), path, "%s：指出出错剧本" % label)
	var resource_kind := String(report.get("resource_kind", ""))
	if not String(sample.get("resource_kind", "")).is_empty():
		_expect_equal(resource_kind, sample["resource_kind"], "%s：指出涉及的资源类型" % label)
		_expect(not String(report.get("resource_id", "")).is_empty(), "%s：指出资源标识" % label)
	var actions := report.get("recovery_actions", PackedStringArray()) as PackedStringArray
	_expect(not actions.is_empty(), "%s：失败面板给出可恢复动作" % label)
	var failure := KonadoExecutionFailure.new(
		StringName(code), String(report.get("message", "")), report
	)
	var line := KonadoRuntimeFailureReporter.format_line(failure, report)
	_expect(
		line.begins_with("Konado [%s] %s:" % [report.get("id", ""), code]),
		"%s：控制台单行以错误编号开头（%s）" % [label, line],
	)
	_expect(line.contains(path), "%s：控制台单行包含剧本位置" % label)


func _run_empty_actor_id_sample() -> void:
	var manager := await _create_manager()
	var stage := manager.stage_controller
	_expect(stage != null, "#11：默认模板提供舞台控制器")
	if stage == null:
		await _free_node(manager)
		return
	stage.show_actor("", 2, 1, "正常", null, null, -1.0, false, stage.begin_operation_request())
	var failure := stage.get_last_failure()
	print(
		(
			'  #11 [%s] %s → %s；触发方式=KonadoStageController.show_actor("")'
			% [failure.get("id", ""), failure.get("code", ""), failure.get("function", "")]
		)
	)
	_expect_equal(failure.get("code"), "stage.actor_id_empty", "#11：空角色 ID 被拦截")
	_expect_equal(failure.get("id"), "AC-001", "#11：稳定编号来自注册表")
	_expect_equal(
		failure.get("function"),
		KonadoErrorRegistry.entry(&"stage.actor_id_empty").get("function"),
		"#11：检出函数与注册表一致",
	)
	_expect_equal(failure.get("resource_kind"), "actor", "#11：指出涉及的资源类型")
	await _free_node(manager)


func _print_gallery_row(index: int, sample: Dictionary, report: Dictionary) -> void:
	var resource := String(report.get("resource_kind", ""))
	var resource_id := String(report.get("resource_id", ""))
	var target := "%s=%s" % [resource, resource_id] if not resource.is_empty() else "资源=无"
	print(
		(
			"  #%02d [%s] %s → %s；%s；指令=%s（行 %s）；动作=%s\n      样本：%s（%s）"
			% [
				index,
				report.get("id", ""),
				report.get("code", ""),
				report.get("function", ""),
				target,
				report.get("instruction_id", ""),
				report.get("source_line", 0),
				", ".join(report.get("recovery_actions", PackedStringArray()) as PackedStringArray),
				sample["note"],
				String(sample["file"]).get_file(),
			]
		)
	)
