extends Control

## 结构化错误反馈示例（报错画廊）。
##
## 依次运行 sample/error_gallery/*.ks，每条失败都会打印：
##   [错误编号] 机器码 → 检出函数；资源；指令键（剧本行）
## 同时默认对话模板的失败面板会给出可恢复动作（重试 / 跳过 / 停止）。
##
## 运行方式：
##   1) 编辑器里打开 sample/error_gallery/error_gallery.tscn 直接运行（可依次点击面板动作）；
##   2) 命令行：godot --path . sample/error_gallery/error_gallery.tscn
##      配合 auto_advance = true 可无人值守打印全部样本。
## 自动断言版本见 tests/dialogue/test_error_gallery.gd。

const GALLERY_SCRIPTS := [
	"res://sample/error_gallery/01_actor_show_missing.ks",
	"res://sample/error_gallery/02_actor_change_missing.ks",
	"res://sample/error_gallery/03_actor_motion_missing.ks",
	"res://sample/error_gallery/04_actor_exit_missing.ks",
	"res://sample/error_gallery/05_background_missing.ks",
	"res://sample/error_gallery/06_bgm_missing.ks",
	"res://sample/error_gallery/07_sfx_missing.ks",
	"res://sample/error_gallery/08_camera_missing.ks",
	"res://sample/error_gallery/09_achievement_missing.ks",
	"res://sample/error_gallery/10_variable_missing.ks",
]

@export var dialogue_manager: KonadoDialogueManager
@export var auto_advance := true
@export var auto_advance_delay := 0.4

var _index := 0
var _reports: Array[Dictionary] = []


func _ready() -> void:
	if dialogue_manager == null:
		printerr("未指定 dialogue_manager，请在场景里绑定 KonadoDialogue 节点")
		return
	dialogue_manager.report_runtime_failures_to_console = true
	dialogue_manager.runtime_failure_reported.connect(_on_runtime_failure_reported)
	dialogue_manager.runtime_failure_resolved.connect(_on_runtime_failure_resolved)
	print("=== Konado 报错测试（%d 个样本）===" % GALLERY_SCRIPTS.size())
	_run_next_script()


func _run_next_script() -> void:
	if _index >= GALLERY_SCRIPTS.size():
		_run_empty_actor_id_sample()
		_print_summary()
		return
	var path: String = GALLERY_SCRIPTS[_index]
	_index += 1
	var shot := load(path) as KonadoShot
	if shot == null:
		printerr("示例加载失败：%s" % path)
		_run_next_script()
		return
	dialogue_manager.set_shot(shot)
	dialogue_manager.start_dialogue()


func _on_runtime_failure_reported(report: Dictionary) -> void:
	_reports.append(report.duplicate(true))
	_print_report(report)
	if not auto_advance:
		return
	await get_tree().create_timer(auto_advance_delay).timeout
	_resolve_and_continue()


func _on_runtime_failure_resolved(_report: Dictionary, _resolution: StringName) -> void:
	if auto_advance:
		return
	_run_next_script()


func _resolve_and_continue() -> void:
	var actions := (
		dialogue_manager.pending_runtime_failure.get("recovery_actions", PackedStringArray())
		as PackedStringArray
	)
	if &"stop" in actions:
		dialogue_manager.resolve_runtime_failure(&"stop")
	elif &"skip" in actions:
		dialogue_manager.resolve_runtime_failure(&"skip")
	_run_next_script()


func _run_empty_actor_id_sample() -> void:
	var stage := dialogue_manager.stage_controller
	if stage == null:
		printerr("当前模板没有舞台控制器，跳过 AC-001 样本")
		return
	stage.show_actor("", 2, 1, "正常", null, null, -1.0, false, stage.begin_operation_request())
	var failure := stage.get_last_failure()
	print(
		(
			'  [%s] %s → %s；触发方式=KonadoStageController.show_actor("")'
			% [failure.get("id", ""), failure.get("code", ""), failure.get("function", "")]
		)
	)
	_reports.append(failure)


func _print_report(report: Dictionary) -> void:
	var failure := KonadoExecutionFailure.new(
		StringName(report.get("code", "")), String(report.get("message", "")), report
	)
	print(KonadoRuntimeFailureReporter.format_line(failure, report))
	var actions := ", ".join(
		report.get("recovery_actions", PackedStringArray()) as PackedStringArray
	)
	print("      可恢复动作：%s" % actions)


func _print_summary() -> void:
	print("=== 画廊汇总（%d 条）===" % _reports.size())
	for report: Dictionary in _reports:
		print(
			(
				"  %-8s %-34s %s"
				% [report.get("id", ""), report.get("code", ""), report.get("function", "")]
			)
		)
