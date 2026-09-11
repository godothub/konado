extends Control
class_name KonadoStageController

## 管理剧情舞台中的背景、演员和视觉效果。

## 完成背景切换的信号
signal background_change_finished(succeeded: bool)
## 完成角色显示的信号
signal actor_shown(succeeded: bool)
## 完成角色删除的信号
signal actor_removed(succeeded: bool)
## 完成角色切换状态的信号
signal actor_state_changed(succeeded: bool)
## 完成角色移动的信号
signal actor_moved(succeeded: bool)
## 指定角色舞台动作开始的信号
signal actor_motion_started(actor_id: String, motion_name: String)
## 指定角色舞台动作完成的信号
signal actor_motion_finished(actor_id: String, motion_name: String, succeeded: bool)
## Internal request-scoped completion used by the atomic runtime. Public stage
## signals above remain available for direct integrations.
signal operation_finished(request_id: int, succeeded: bool, failure: Dictionary)

## 特效种类
enum BackgroundTransitionEffect {
	INVALID = -1,
	NONE,
	ERASE,
	BLINDS,
	WAVE,
	ALPHA_FADE,
	VORTEX_SWAP,
	WINDMILL,
	CYBER_GLITCH,
	BLINK,
}

const BACKGROUND_EFFECT_NAMES := {
	BackgroundTransitionEffect.NONE: "none",
	BackgroundTransitionEffect.ERASE: "erase",
	BackgroundTransitionEffect.BLINDS: "blinds",
	BackgroundTransitionEffect.WAVE: "wave",
	BackgroundTransitionEffect.ALPHA_FADE: "fade",
	BackgroundTransitionEffect.VORTEX_SWAP: "vortex",
	BackgroundTransitionEffect.WINDMILL: "windmill",
	BackgroundTransitionEffect.CYBER_GLITCH: "cyberglitch",
	BackgroundTransitionEffect.BLINK: "blink",
}
const ACTOR_STATE_REQUEST_COORDINATOR := preload(
	"res://addons/konado/runtime/stage/character/konado_actor_state_request_coordinator.gd"
)
const BACKGROUND_TRANSITION_LAYER_SCRIPT := preload(
	"res://addons/konado/runtime/stage/background/konado_background_transition_layer.gd"
)
const STAGE_OPERATION_TRACKER := preload(
	"res://addons/konado/runtime/stage/konado_stage_operation_tracker.gd"
)
const STAGE_FAILURE_REPORTER := preload(
	"res://addons/konado/runtime/stage/konado_stage_failure_reporter.gd"
)
const STAGE_UTILITIES := preload("res://addons/konado/runtime/stage/konado_stage_utilities.gd")

## 启用全局演员背景色调混合
@export var background_tint_enabled: bool = true
## 全局演员背景色调混合
@export var global_tint_intensity: float = 0.3:
	set(value):
		global_tint_intensity = clamp(value, 0.0, 0.5)
		# 如果正在游戏中，立刻刷新所有角色染色
		if is_inside_tree():
			apply_background_tint_to_actors()

## 启用演员状态切换淡入淡出过渡
@export var actor_state_transition_enabled: bool = true
## 演员状态切换总时长（秒）；支持状态帧时交融，否则淡出和淡入各占一半
@export_range(0.0, 5.0, 0.01, "or_greater") var actor_state_transition_duration: float = 0.3:
	set(value):
		actor_state_transition_duration = maxf(value, 0.0)

## 可持久化的演员状态，以演员 ID 为键。
var actor_states: Dictionary[String, Dictionary] = {}
## 舞台上的演员实例缓存，以演员 ID 为键。
var actor_instances: Dictionary[String, KonadoActor] = {}
## 角色列表
var character_list: KonadoCharacterList
## 存档用背景 id
var background_id: String = ""

var _background_controller := KonadoBackgroundController.new()
var _actor_state_request_serial: int = 0
var _actor_state_request_tokens: Dictionary[String, int] = {}
var _actor_pending_states: Dictionary[String, String] = {}
var _actor_state_requests: Dictionary = {}
var _highlighted_actor_id: String = ""
var _last_failure: Dictionary = {}
var _operation_tracker_instance := STAGE_OPERATION_TRACKER.new()

## 演员模板
@onready var _konado_actor_template: PackedScene = preload(
	"res://addons/konado/templates/default/character/character_template.tscn"
)
## 背景底色层
@onready var _background: ColorRect = get_node_or_null("BackgroundLayer") as ColorRect
## 背景场景容器
@onready var _background_container: Control = (
	get_node_or_null("BackgroundLayer/BackgroundContainer") as Control
)
## 背景 shader 转场层
@onready var _background_transition_layer: BACKGROUND_TRANSITION_LAYER_SCRIPT = (
	get_node_or_null("BackgroundTransitionLayer") as BACKGROUND_TRANSITION_LAYER_SCRIPT
)
## 角色容器
@onready var _actor_layer: Control = get_node_or_null("ActorLayer") as Control
## 效果层
@onready var _effect_layer: ColorRect = get_node_or_null("EffectLayer") as ColorRect


func _ready() -> void:
	_ensure_stage_nodes()
	_background_controller.setup(_background_container, _background_transition_layer)
	_background_controller.transition_finished.connect(_on_background_change_finished)
	for child in _actor_layer.get_children():
		child.queue_free()


func _on_background_change_finished(succeeded: bool) -> void:
	if succeeded:
		apply_background_tint_to_actors()
	else:
		var background_failure := _background_controller.get_last_failure()
		if not background_failure.is_empty():
			_last_failure = background_failure
	var request_id := _operation_tracker().take_background_request()
	_operation_tracker().complete(request_id, succeeded, _last_failure if not succeeded else {})
	background_change_finished.emit(succeeded)


## Allocates a request identity before a stage method is invoked, allowing the
## caller to subscribe before even a synchronous rejection is emitted.
func begin_operation_request() -> int:
	return _operation_tracker().begin_request()


func _operation_tracker() -> KonadoStageOperationTracker:
	var callback := Callable(self, "_on_operation_finished")
	if not _operation_tracker_instance.operation_finished.is_connected(callback):
		_operation_tracker_instance.operation_finished.connect(callback)
	return _operation_tracker_instance


func _on_operation_finished(request_id: int, succeeded: bool, failure: Dictionary) -> void:
	operation_finished.emit(request_id, succeeded, failure)


## Returns the failure produced by the most recently rejected stage operation.
## The atomic runtime reads this immediately when a completion signal reports
## failure, so the final log retains the subsystem's exact cause.
func get_last_failure() -> Dictionary:
	return _last_failure.duplicate(true)


## 确保表演舞台的层级存在。
## 背景已经全面转成场景，这里只兜住“场景挂载层”本身，避免旧模板实例没有 BackgroundContainer 时背景无法显示。
func _ensure_stage_nodes() -> void:
	if _background == null:
		_background = ColorRect.new()
		_background.name = "BackgroundLayer"
		_background.color = Color.BLACK
		add_child(_background)
	if _background_container == null:
		_background_container = Control.new()
		_background_container.name = "BackgroundContainer"
		_background.add_child(_background_container)
	elif _background_container.get_parent() != _background:
		var container_parent := _background_container.get_parent()
		if container_parent:
			container_parent.remove_child(_background_container)
		_background.add_child(_background_container)

	if _background_transition_layer == null:
		_background_transition_layer = BACKGROUND_TRANSITION_LAYER_SCRIPT.new()
		_background_transition_layer.name = "BackgroundTransitionLayer"
		add_child(_background_transition_layer)
	elif _background_transition_layer.get_parent() != self:
		var transition_parent := _background_transition_layer.get_parent()
		if transition_parent:
			transition_parent.remove_child(_background_transition_layer)
		add_child(_background_transition_layer)

	if _actor_layer == null:
		_actor_layer = get_node_or_null("BackgroundLayer/ActorLayer") as Control
	if _actor_layer == null:
		_actor_layer = Control.new()
		_actor_layer.name = "ActorLayer"
		add_child(_actor_layer)
	elif _actor_layer.get_parent() != self:
		var actor_layer_parent := _actor_layer.get_parent()
		if actor_layer_parent:
			actor_layer_parent.remove_child(_actor_layer)
		add_child(_actor_layer)

	if _effect_layer == null:
		_effect_layer = ColorRect.new()
		_effect_layer.name = "EffectLayer"
		_effect_layer.color = Color(0, 0, 0, 0)
		add_child(_effect_layer)

	STAGE_UTILITIES.set_full_rect(_background)
	STAGE_UTILITIES.set_full_rect(_background_container)
	STAGE_UTILITIES.set_full_rect(_background_transition_layer)
	STAGE_UTILITIES.set_full_rect(_actor_layer)
	STAGE_UTILITIES.set_full_rect(_effect_layer)

	## 层级顺序固定为：背景场景 -> shader 转场 -> 角色 -> 全屏效果。
	if _background.get_parent() == self:
		move_child(_background, 0)
	if _background_transition_layer.get_parent() == self:
		move_child(_background_transition_layer, min(1, get_child_count() - 1))
	if _actor_layer.get_parent() == self:
		move_child(_actor_layer, min(2, get_child_count() - 1))
	if _effect_layer.get_parent() == self:
		move_child(_effect_layer, get_child_count() - 1)


## 返回舞台上的演员实例。
func get_actor(actor_id: String) -> KonadoActor:
	if actor_id.is_empty():
		# 空 ID 不是有效演员名；同时避免把空串传给 Node.find_child（引擎会报错）。
		return null
	if actor_instances.has(actor_id):
		var cached_node := actor_instances[actor_id]
		if cached_node and is_instance_valid(cached_node):
			return cached_node
		actor_instances.erase(actor_id)

	var actor := _actor_layer.find_child(actor_id, true, false) as KonadoActor
	if actor != null:
		actor_instances[actor_id] = actor
		return actor
	return null


## 清空背景
func clean_background(effects_type: BackgroundTransitionEffect) -> void:
	_operation_tracker().supersede_background(background_id)
	_ensure_stage_nodes()
	background_id = ""
	_background_controller.clear(_background_effect_name(effects_type))


## 显示背景场景的方法
func change_background_scene(
	scene: PackedScene,
	name: String,
	effects_type: BackgroundTransitionEffect,
	duration: float = -1.0,
	report_errors := true,
	request_id := 0,
) -> void:
	_last_failure.clear()
	_operation_tracker().register_background(request_id, background_id)
	_ensure_stage_nodes()
	if scene == null:
		_last_failure = (
			STAGE_FAILURE_REPORTER
			. record(
				&"stage.background_scene_missing",
				"切换背景失败：背景场景为空",
				"background",
				"background",
				name,
				report_errors,
			)
		)
		_operation_tracker().take_background_request()
		_operation_tracker().complete(request_id, false, _last_failure)
		background_change_finished.emit(false)
		return
	background_id = name
	_background_controller.change(
		scene, name, _background_effect_name(effects_type), duration, report_errors
	)


func _background_effect_name(effects_type: BackgroundTransitionEffect) -> String:
	return BACKGROUND_EFFECT_NAMES.get(effects_type, "none")


func get_current_background() -> KonadoBackgroundSceneBase:
	return _background_controller.current_background


func get_pending_background() -> KonadoBackgroundSceneBase:
	return _background_controller.get_pending_background()


## 显示角色。角色不存在时创建，已存在时复用节点并更新状态或位置。
func show_actor(
	actor_id: String,
	horizontal_division: int,
	horizontal_position: int,
	state: String,
	character_scene: PackedScene = null,
	motion_layer_scene: PackedScene = null,
	duration: float = -1.0,
	report_errors := true,
	request_id := 0,
) -> void:
	_last_failure.clear()
	var existing_actor := get_actor(actor_id) as KonadoActor
	if existing_actor != null:
		_update_existing_actor(
			existing_actor,
			actor_id,
			horizontal_division,
			horizontal_position,
			state,
			duration,
			report_errors,
			request_id,
		)
		return

	# actor_states 可能残留旧数据；没有有效节点时按新建处理。
	_invalidate_actor_state_request(actor_id)
	if actor_states.has(actor_id):
		actor_states.erase(actor_id)

	# AC-001 / AC-014：空角色 ID 或未配置角色场景都无法建立角色，属于同一条入口拦截路径。
	if character_scene == null or actor_id.strip_edges().is_empty():
		var empty_id := actor_id.strip_edges().is_empty()
		_last_failure = (
			STAGE_FAILURE_REPORTER
			. record_actor_show(
				&"stage.actor_id_empty" if empty_id else &"stage.actor_scene_missing",
				(
					"显示角色失败：角色 ID 不能为空（actor show 缺少角色名称）"
					if empty_id
					else "显示角色失败：角色[%s]没有配置角色场景" % actor_id
				),
				actor_id,
				report_errors,
				"角色 ID 为空" if empty_id else "目标状态=%s" % state,
			)
		)
		_emit_actor_shown(false, request_id)
		return

	var initial_horizontal_division: int = clamp(horizontal_division, 2, 5)
	var initial_horizontal_position: int = clamp(
		horizontal_position, 0, initial_horizontal_division
	)
	var actor_state: Dictionary = {
		"id": actor_id,
		"horizontal_division": initial_horizontal_division,
		"horizontal_position": initial_horizontal_position,
		"state": state
	}

	var node_name: String = str(actor_state["id"])
	var temp_node: KonadoActor = _konado_actor_template.instantiate() as KonadoActor
	if temp_node == null:
		_last_failure = STAGE_FAILURE_REPORTER.record_actor_show(
			&"stage.actor_template_failed", "显示角色失败：无法实例化演员模板", actor_id, report_errors
		)
		_emit_actor_shown(false, request_id)
		return
	var state_request_token := _begin_actor_state_request(actor_id)
	# 初始化阶段使用内部名称并隐藏根节点。这样角色场景能够正常进入 SceneTree、执行
	# @onready/_ready，又不会被 get_actor 当成已经公开的演员。
	temp_node.name = "_KonadoPendingActor_%d" % temp_node.get_instance_id()
	temp_node.visible = false
	temp_node.use_tween = false
	temp_node.set_stage_position(horizontal_division, horizontal_position)
	temp_node.actor_motion_started.connect(_on_actor_motion_started.bind(actor_id))
	temp_node.actor_motion_finished.connect(_on_actor_motion_finished.bind(actor_id))
	_actor_layer.add_child(temp_node)
	if not temp_node.set_motion_layer_scene(motion_layer_scene):
		_last_failure = (
			STAGE_FAILURE_REPORTER
			. record_actor_show(
				&"stage.actor_motion_layer_invalid",
				"显示角色失败：角色[%s]的动作层配置无效" % actor_id,
				actor_id,
				report_errors,
				"",
				true,
			)
		)
		_emit_actor_shown(false, request_id)
		if _is_actor_state_request_current(actor_id, state_request_token):
			_invalidate_actor_state_request(actor_id)
		_discard_pending_actor(temp_node)
		return
	if not temp_node.set_character_scene(character_scene, state):
		_last_failure = (
			STAGE_FAILURE_REPORTER
			. record_actor_show(
				&"stage.actor_state_invalid",
				"显示角色失败：角色[%s]无法应用状态[%s]" % [actor_id, state],
				actor_id,
				report_errors,
				"目标状态=%s" % state,
				true,
			)
		)
		_emit_actor_shown(false, request_id)
		if _is_actor_state_request_current(actor_id, state_request_token):
			_invalidate_actor_state_request(actor_id)
		_discard_pending_actor(temp_node)
		return
	if not _is_actor_state_request_current(actor_id, state_request_token):
		# 初始化期间若同一演员已被更新请求取代，不允许旧请求进入场景树。
		_discard_pending_actor(temp_node)
		_last_failure = (
			STAGE_FAILURE_REPORTER
			. record_actor_show(
				&"stage.actor_request_superseded",
				"显示角色失败：角色[%s]的请求已被更新操作取代" % actor_id,
				actor_id,
				report_errors,
			)
		)
		_emit_actor_shown(false, request_id)
		return
	# 初始化事务成功后才使用公开名称并写入运行时索引。
	temp_node.name = node_name
	# 只有节点和初始状态都创建成功后，才提交存档使用的演员数据。
	actor_states[actor_state["id"]] = actor_state
	# 角色场景创建完成后应用色调混合，确保新角色在显示前就已带有正确的色调
	apply_background_tint_to_actors()
	actor_instances[actor_id] = temp_node
	temp_node.actor_moved.connect(_on_actor_moved.bind(actor_id))
	temp_node.actor_entered.connect(
		_on_actor_entered.bind(actor_id, state, request_id), ConnectFlags.CONNECT_ONE_SHOT
	)
	temp_node.use_tween = true
	temp_node.visible = true
	temp_node.enter_actor(true, duration)


func _update_existing_actor(
	actor: KonadoActor,
	actor_id: String,
	horizontal_division: int,
	horizontal_position: int,
	state: String,
	duration: float = -1.0,
	report_errors := true,
	request_id := 0,
) -> void:
	var previous_state := ""
	if actor_states.has(actor_id):
		previous_state = str(actor_states[actor_id].get("state", ""))

	var next_horizontal_division: int = clamp(horizontal_division, 2, 5)
	var next_horizontal_position: int = clamp(horizontal_position, 0, next_horizontal_division)
	var position_changed: bool = (
		actor.horizontal_division != next_horizontal_division
		or actor.horizontal_position != next_horizontal_position
	)
	var movement_in_progress := actor._is_stage_position_moving()
	# 持续中的转场也必须由这次 upsert 明确取代，即使已提交状态恰好相同。
	var state_changed: bool = previous_state != state or _actor_pending_states.has(actor_id)

	actor_instances[actor_id] = actor
	var next_actor_state: Dictionary = {
		"id": actor_id,
		"horizontal_division": next_horizontal_division,
		"horizontal_position": next_horizontal_position,
		"state": previous_state,
	}
	if not state_changed:
		next_actor_state["state"] = state
	# 位置是独立且已经接受的更新；状态仅在角色场景实际应用后提交。
	actor_states[actor_id] = next_actor_state

	var waits := {
		"succeeded": true,
		"failure": {},
		"state_done": not state_changed,
		"movement_done":
		not (
			movement_in_progress
			or (
				position_changed
				and actor.slot != null
				and actor.use_tween
				and actor.animation_time > 0.0
			)
		),
		"finished": false,
	}
	var actor_ref := weakref(actor)
	var finish_if_ready := func() -> void:
		if waits.finished or not waits.state_done or not waits.movement_done:
			return
		waits.finished = true
		if actor_states.has(actor_id) and waits.succeeded:
			var committed_state := str(actor_states[actor_id].get("state", ""))
			print("复用已有演员：" + str(actor_id) + " 演员状态：" + committed_state)
		else:
			waits.succeeded = false
		_emit_actor_shown(bool(waits.succeeded), request_id, waits.failure)

	var movement_exit_handler_ref := [Callable()]
	var movement_handler := func() -> void:
		waits.movement_done = true
		var active_actor := actor_ref.get_ref() as KonadoActor
		var movement_exit_handler: Callable = movement_exit_handler_ref[0]
		movement_exit_handler_ref[0] = Callable()
		if (
			active_actor != null
			and movement_exit_handler.is_valid()
			and active_actor.tree_exiting.is_connected(movement_exit_handler)
		):
			active_actor.tree_exiting.disconnect(movement_exit_handler)
		finish_if_ready.call()
	if not waits.movement_done:
		var movement_exit_handler := func() -> void:
			movement_exit_handler_ref[0] = Callable()
			if waits.movement_done:
				return
			waits.movement_done = true
			waits.succeeded = false
			waits.failure = {
				"code": "stage.actor_node_removed",
				"message": "显示角色失败：角色[%s]在操作完成前离开舞台" % actor_id,
				"subsystem": "stage",
				"operation": "actor.show",
				"resource_kind": "actor",
				"resource_id": actor_id,
			}
			var active_actor := actor_ref.get_ref() as KonadoActor
			if active_actor != null and active_actor.actor_moved.is_connected(movement_handler):
				active_actor.actor_moved.disconnect(movement_handler)
			finish_if_ready.call()
		movement_exit_handler_ref[0] = movement_exit_handler
		actor.actor_moved.connect(movement_handler, ConnectFlags.CONNECT_ONE_SHOT)
		actor.tree_exiting.connect(movement_exit_handler, ConnectFlags.CONNECT_ONE_SHOT)
	if position_changed:
		var movement_started := actor.set_stage_position(
			next_horizontal_division, next_horizontal_position, duration
		)
		if not movement_started and not waits.movement_done:
			if actor.actor_moved.is_connected(movement_handler):
				actor.actor_moved.disconnect(movement_handler)
			var movement_exit_handler: Callable = movement_exit_handler_ref[0]
			movement_exit_handler_ref[0] = Callable()
			if (
				movement_exit_handler.is_valid()
				and actor.tree_exiting.is_connected(movement_exit_handler)
			):
				actor.tree_exiting.disconnect(movement_exit_handler)
			waits.movement_done = true

	if state_changed:
		_request_actor_state(
			actor,
			actor_id,
			state,
			duration if duration >= 0.0 else 0.0,
			"显示角色失败：角色[%s]无法应用状态[%s]" % [actor_id, state],
			"actor.show",
			report_errors,
			func(succeeded: bool, actor_exited: bool, owned_request: bool) -> void:
				waits.succeeded = waits.succeeded and succeeded
				if not succeeded:
					waits.failure = (
						_last_failure.duplicate(true)
						if owned_request
						else _operation_tracker().superseded_failure(
							"actor.show", "actor", actor_id
						)
					)
				# 演员离树后移动信号也不会再到达；两个等待必须一起释放。
				if actor_exited:
					waits.movement_done = true
				waits.state_done = true
				finish_if_ready.call()
		)

	finish_if_ready.call()


func _on_actor_entered(actor_id: String, state: String, request_id := 0) -> void:
	_emit_actor_shown(true, request_id)
	print("新建了演员：" + str(actor_id) + " 演员状态：" + str(state))


func _emit_actor_shown(succeeded: bool, request_id := 0, failure: Dictionary = {}) -> void:
	var result_failure := failure
	if not succeeded and result_failure.is_empty():
		result_failure = _last_failure.duplicate(true)
	_operation_tracker().complete(request_id, succeeded, result_failure)
	actor_shown.emit(succeeded)


func _discard_pending_actor(actor: KonadoActor) -> void:
	if actor == null or not is_instance_valid(actor):
		return
	var parent := actor.get_parent()
	if parent:
		parent.remove_child(actor)
	actor.free()


## 所有已有演员的状态变更都经过这一入口。这里负责业务所有权和存档提交，
## 协调器只负责把同步、异步、拒绝与离树归一为一次完成通知。
func _request_actor_state(
	actor: KonadoActor,
	actor_id: String,
	target_state: String,
	transition_duration: float,
	failure_message: String,
	operation: String,
	report_errors: bool,
	completion: Callable
) -> bool:
	var previous_request := _capture_actor_state_request(actor_id)
	var request_token := _begin_actor_state_request(actor_id)
	_actor_pending_states[actor_id] = target_state
	# 转场帧必须使用请求开始时已经刷新的舞台色调。
	apply_background_tint_to_actors()

	var failure_reported := [false]
	var report_failure := func() -> void:
		if failure_reported[0]:
			return
		failure_reported[0] = true
		_last_failure = (
			STAGE_FAILURE_REPORTER
			. record_actor(
				&"stage.actor_state_invalid",
				failure_message,
				operation,
				actor_id,
				report_errors,
				"目标状态=%s" % target_state,
				true,
			)
		)
	var coordinator := ACTOR_STATE_REQUEST_COORDINATOR.new(
		actor,
		target_state,
		transition_duration,
		func() -> bool: return _is_actor_state_request_current(actor_id, request_token),
		func() -> void: _commit_actor_state(actor_id, target_state, request_token),
		func() -> void:
			report_failure.call()
			_restore_actor_state_request(actor_id, request_token, previous_request),
		func(succeeded: bool, actor_exited: bool) -> void:
			_actor_state_requests.erase(request_token)
			var owned_request := _is_actor_state_request_current(actor_id, request_token)
			if owned_request:
				if succeeded:
					_commit_actor_state(actor_id, target_state, request_token)
				else:
					report_failure.call()
				_actor_pending_states.erase(actor_id)
			if completion.is_valid():
				completion.call(succeeded, actor_exited, owned_request)
	)
	# 在 start() 前持有协调器，保证同步重入和异步扩展实现使用同一生命周期对象。
	_actor_state_requests[request_token] = coordinator
	return coordinator.start()


func _commit_actor_state(actor_id: String, target_state: String, request_token: int) -> void:
	if not _is_actor_state_request_current(actor_id, request_token):
		return
	if actor_states.has(actor_id):
		actor_states[actor_id]["state"] = target_state


func _begin_actor_state_request(actor_id: String) -> int:
	_actor_state_request_serial += 1
	_actor_state_request_tokens[actor_id] = _actor_state_request_serial
	return _actor_state_request_serial


func _capture_actor_state_request(actor_id: String) -> Dictionary:
	return {
		"has_token": _actor_state_request_tokens.has(actor_id),
		"token": _actor_state_request_tokens.get(actor_id, -1),
		"has_pending_state": _actor_pending_states.has(actor_id),
		"pending_state": _actor_pending_states.get(actor_id, ""),
	}


func _restore_actor_state_request(
	actor_id: String, rejected_token: int, previous_request: Dictionary
) -> void:
	if not _is_actor_state_request_current(actor_id, rejected_token):
		return
	if previous_request.has_token:
		_actor_state_request_tokens[actor_id] = previous_request.token
	else:
		_actor_state_request_tokens.erase(actor_id)
	if previous_request.has_pending_state:
		_actor_pending_states[actor_id] = previous_request.pending_state
	else:
		_actor_pending_states.erase(actor_id)


func _is_actor_state_request_current(actor_id: String, request_token: int) -> bool:
	return int(_actor_state_request_tokens.get(actor_id, -1)) == request_token


func _invalidate_actor_state_request(actor_id: String) -> void:
	_actor_state_request_tokens.erase(actor_id)
	_actor_pending_states.erase(actor_id)


## 切换演员的状态
func change_actor_state(
	actor_id: String,
	state_id: String,
	duration: float = -1.0,
	report_errors := true,
	request_id := 0,
) -> void:
	_last_failure.clear()
	var actor: KonadoActor = get_actor(actor_id)
	if actor == null:
		_last_failure = (
			STAGE_FAILURE_REPORTER
			. record_actor(
				&"stage.actor_not_present",
				"切换角色状态失败：角色ID[%s]，目标状态ID[%s]，未找到角色节点" % [actor_id, state_id],
				"actor.change",
				actor_id,
				report_errors,
				"目标状态=%s" % state_id,
			)
		)
		_operation_tracker().complete(request_id, false, _last_failure)
		actor_state_changed.emit(false)
		return

	var transition_duration := (
		duration
		if duration >= 0.0
		else actor_state_transition_duration if actor_state_transition_enabled else 0.0
	)
	_request_actor_state(
		actor,
		actor_id,
		state_id,
		transition_duration,
		"切换角色状态失败：角色[%s]无法应用状态[%s]" % [actor_id, state_id],
		"actor.change",
		report_errors,
		func(succeeded: bool, _actor_exited: bool, owned_request: bool) -> void:
			if succeeded and owned_request:
				print("切换" + actor_id + "到" + str(state_id) + "状态")
			var completed := succeeded and owned_request
			var completion_failure := {}
			if not completed:
				completion_failure = (
					_last_failure
					if owned_request
					else _operation_tracker().superseded_failure("actor.change", "actor", actor_id)
				)
			_operation_tracker().complete(request_id, completed, completion_failure)
			actor_state_changed.emit(completed)
	)


## 播放指定演员的舞台层动作（如 shake、jump_twice、bounce）；不进入角色场景，避免与内部表情/媒体播放混淆。
func play_actor_motion(
	actor_id: String,
	motion_name: String,
	params: Dictionary = {},
	report_errors := true,
	request_id := 0,
) -> void:
	_last_failure.clear()
	_operation_tracker().register_actor_motion(actor_id, motion_name, request_id)
	if motion_name.is_empty():
		_last_failure = (
			STAGE_FAILURE_REPORTER
			. record_actor(
				&"stage.actor_motion_empty",
				"播放演员动作失败：角色ID[%s]，动作名为空" % actor_id,
				"actor.motion",
				actor_id,
				report_errors,
			)
		)
		_operation_tracker().take_actor_motion(actor_id, motion_name)
		_operation_tracker().complete(request_id, false, _last_failure)
		actor_motion_finished.emit(actor_id, motion_name, false)
		return
	var actor: KonadoActor = get_actor(actor_id) as KonadoActor
	if actor == null:
		_last_failure = (
			STAGE_FAILURE_REPORTER
			. record_actor(
				&"stage.actor_not_present",
				"播放演员动作失败：角色ID[%s]，动作[%s]，未找到角色节点" % [actor_id, motion_name],
				"actor.motion",
				actor_id,
				report_errors,
				"目标动作=%s" % motion_name,
			)
		)
		_operation_tracker().take_actor_motion(actor_id, motion_name)
		_operation_tracker().complete(request_id, false, _last_failure)
		actor_motion_finished.emit(actor_id, motion_name, false)
		return
	if not actor.can_play_actor_motion(motion_name):
		_last_failure = (
			STAGE_FAILURE_REPORTER
			. record_actor(
				&"stage.actor_motion_missing",
				"播放演员动作失败：角色[%s]没有动作[%s]" % [actor_id, motion_name],
				"actor.motion",
				actor_id,
				report_errors,
				"目标动作=%s" % motion_name,
			)
		)
		_operation_tracker().take_actor_motion(actor_id, motion_name)
		_operation_tracker().complete(request_id, false, _last_failure)
		actor_motion_finished.emit(actor_id, motion_name, false)
		return
	actor.play_actor_motion(motion_name, params)


## 高亮指定演员并弱化舞台上的其他演员。
func highlight_actor(actor_id: String) -> void:
	_highlighted_actor_id = actor_id if actor_states.has(actor_id) else ""
	if actor_states.size() <= 0:
		return
	for candidate_id in actor_states.keys():
		var candidate := get_actor(candidate_id)
		if candidate == null:
			continue
		candidate.set_highlight(actor_id == candidate_id)


## 从舞台移除指定演员。
func remove_actor(
	actor_id: String, duration: float = -1.0, report_errors := true, request_id := 0
) -> void:
	_last_failure.clear()
	_invalidate_actor_state_request(actor_id)
	if _highlighted_actor_id == actor_id:
		_highlighted_actor_id = ""
	if not actor_states.has(actor_id):
		_last_failure = (
			STAGE_FAILURE_REPORTER
			. record_actor(
				&"stage.actor_not_present",
				"移出演员失败：角色ID[%s]不在舞台上" % actor_id,
				"actor.exit",
				actor_id,
				report_errors,
			)
		)
		_operation_tracker().complete(request_id, false, _last_failure)
		actor_removed.emit(false)
		return
	var actor := get_actor(actor_id)
	actor_states.erase(actor_id)
	actor_instances.erase(actor_id)
	if actor == null:
		_last_failure = (
			STAGE_FAILURE_REPORTER
			. record_actor(
				&"stage.actor_node_missing",
				"移出演员失败：角色ID[%s]的舞台节点不存在" % actor_id,
				"actor.exit",
				actor_id,
				report_errors,
			)
		)
		_operation_tracker().complete(request_id, false, _last_failure)
		actor_removed.emit(false)
		return
	actor._cancel_character_status_transition()
	actor.tree_exited.connect(
		func() -> void:
			_operation_tracker().complete(request_id, true)
			actor_removed.emit(true),
		ConnectFlags.CONNECT_ONE_SHOT,
	)
	actor.exit_actor(true, duration)


## 删除所有演员
func remove_all_actors(immediate: bool = false) -> void:
	_actor_state_request_tokens.clear()
	_actor_pending_states.clear()
	actor_states.clear()
	actor_instances.clear()
	_highlighted_actor_id = ""
	for node in _actor_layer.get_children():
		var actor := node as KonadoActor
		if actor == null:
			continue
		actor._cancel_character_status_transition()
		if immediate:
			actor.free()
		else:
			actor.exit_actor(false)
	print("删除所有演员")


## 移动演员的方法
func move_actor(
	actor_id: String,
	target_h_division: int,
	duration: float = -1.0,
	report_errors := true,
	request_id := 0,
) -> void:
	_last_failure.clear()
	_operation_tracker().register_actor_move(actor_id, request_id)
	var actor: KonadoActor = get_actor(actor_id) as KonadoActor
	if actor == null:
		_last_failure = (
			STAGE_FAILURE_REPORTER
			. record_actor(
				&"stage.actor_not_present",
				"移动角色失败：角色ID[%s]，未找到角色节点" % actor_id,
				"actor.move",
				actor_id,
				report_errors,
			)
		)
		_operation_tracker().take_actor_move(actor_id)
		_operation_tracker().complete(request_id, false, _last_failure)
		actor_moved.emit(false)
		return
	if actor_states.has(actor_id):
		var target_position := clampi(target_h_division, 0, actor.horizontal_division)
		actor_states[actor_id]["horizontal_position"] = target_position
	if not actor.set_stage_position(actor.horizontal_division, target_h_division, duration):
		# 目标值在补间开始时就会更新；重复请求同一目标时必须继续等待正在运行的补间。
		if not actor._is_stage_position_moving():
			_operation_tracker().take_actor_move(actor_id)
			_operation_tracker().complete(request_id, true)
			actor_moved.emit(true)


func _on_actor_moved(actor_id := "") -> void:
	var request_id := _operation_tracker().take_actor_move(actor_id)
	_operation_tracker().complete(request_id, true)
	actor_moved.emit(true)


func _on_actor_motion_started(motion_name: String, actor_id: String) -> void:
	actor_motion_started.emit(actor_id, motion_name)


func _on_actor_motion_finished(motion_name: String, actor_id: String) -> void:
	var request_id := _operation_tracker().take_actor_motion(actor_id, motion_name)
	_operation_tracker().complete(request_id, true)
	actor_motion_finished.emit(actor_id, motion_name, true)


## 从当前背景获取环境色，并应用到所有角色的视觉层
func apply_background_tint_to_actors() -> void:
	var current_background := _background_controller.current_background
	if current_background == null:
		return

	var raw_color: Color = current_background.get_scene_tint_color()
	var total_intensity: float = 0.0
	if background_tint_enabled:
		total_intensity = clamp(
			global_tint_intensity * current_background.scene_tint_intensity, 0.0, 1.0
		)
	var tint_color: Color = Color.WHITE.lerp(raw_color, total_intensity)

	for actor_id in actor_states.keys():
		var actor := get_actor(actor_id) as KonadoActor
		if actor:
			actor.set_actor_modulate(tint_color)


## 捕获舞台的逻辑状态；角色场景节点和转场 Tween 不进入快照。
func capture_state() -> Dictionary:
	return STAGE_UTILITIES.capture_state(background_id, actor_states, _highlighted_actor_id)


## 中止所有未完成的舞台操作，为确定性恢复建立干净边界。
func cancel_pending_operations() -> void:
	_operation_tracker().cancel()
	_background_controller.cancel_pending()
	for actor_id in actor_states:
		_invalidate_actor_state_request(String(actor_id))
		var actor := get_actor(String(actor_id)) as KonadoActor
		if actor != null:
			actor._cancel_character_status_transition()
