extends RefCounted
class_name KonadoScriptCommandRegistry

## Canonical KonadoScript command contract shared by compiler, IDE and VM.

const SCHEMA_VERSION := 4
const STRING := "string"
const STRING_ARRAY := "string_array"
const CHOICES := "choices"
const FILTERS := "filters"
const VALUE := "value"

const ROLLBACK_REVERSIBLE := "reversible"
const ROLLBACK_CHECKPOINT := "checkpoint"
const ROLLBACK_BARRIER := "barrier"

const COMMON_PARAMETERS := {"id": {"type": "identifier"}}

const CANCEL_SYNC := "synchronous"
const CANCEL_SIGNAL := "disconnect_signal"
const CANCEL_CALLBACK := "invalidate_callback"
const CANCEL_EXTERNAL := "external_side_effect"
const CANCEL_BACKGROUND_TASK := "cancel_background_task"

const RUNTIME_HANDLERS := {
	KonadoOpcode.Type.DIALOGUE: &"_dialogue",
	KonadoOpcode.Type.BACKGROUND: &"_background",
	KonadoOpcode.Type.ACTOR_SHOW: &"_actor_show",
	KonadoOpcode.Type.ACTOR_CHANGE: &"_actor_change",
	KonadoOpcode.Type.ACTOR_MOVE: &"_actor_move",
	KonadoOpcode.Type.ACTOR_MOTION: &"_actor_motion",
	KonadoOpcode.Type.ACTOR_EXIT: &"_actor_exit",
	KonadoOpcode.Type.BGM_PLAY: &"_audio_bgm_play",
	KonadoOpcode.Type.BGM_STOP: &"_audio_bgm_stop",
	KonadoOpcode.Type.SFX_PLAY: &"_audio_sfx_play",
	KonadoOpcode.Type.CHOICE: &"_choice",
	KonadoOpcode.Type.CONDITION: &"_condition",
	KonadoOpcode.Type.VARIABLE: &"_variable",
	KonadoOpcode.Type.JUMP_SCRIPT: &"_jump_script",
	KonadoOpcode.Type.JUMP_BRANCH: &"_jump_branch",
	KonadoOpcode.Type.SIGNAL: &"_emit_signal",
	KonadoOpcode.Type.ACHIEVEMENT_UNLOCK: &"_achievement_unlock",
	KonadoOpcode.Type.ACHIEVEMENT_PROGRESS: &"_achievement_progress",
	KonadoOpcode.Type.ACHIEVEMENT_FLAG: &"_achievement_flag",
	KonadoOpcode.Type.HALT: &"_halt",
	KonadoOpcode.Type.CAMERA_MOVE: &"_camera_move",
	KonadoOpcode.Type.CAMERA_RESET: &"_camera_reset",
	KonadoOpcode.Type.CAMERA_SHAKE: &"_camera_shake",
	KonadoOpcode.Type.SCREEN_TEXT: &"screen_text",
	KonadoOpcode.Type.TEXTBOX_SHOW: &"_textbox_show",
	KonadoOpcode.Type.TEXTBOX_HIDE: &"_textbox_hide",
	KonadoOpcode.Type.WAIT_SIGNAL: &"_wait_signal",
	KonadoOpcode.Type.CAMERA_MOVE_ASYNC: &"_camera_move_async",
	KonadoOpcode.Type.CAMERA_RESET_ASYNC: &"_camera_reset_async",
	KonadoOpcode.Type.CAMERA_SHAKE_ASYNC: &"_camera_shake_async",
	KonadoOpcode.Type.CAMERA_STOP_ASYNC: &"_camera_stop_async",
	KonadoOpcode.Type.CALL_BRANCH: &"_call_branch",
	KonadoOpcode.Type.RETURN: &"_return",
}

const RESOURCE_OPERANDS := {
	KonadoOpcode.Type.BACKGROUND: &"background",
	KonadoOpcode.Type.ACTOR_SHOW: &"actor",
	KonadoOpcode.Type.BGM_PLAY: &"resource",
	KonadoOpcode.Type.SFX_PLAY: &"resource",
	KonadoOpcode.Type.JUMP_SCRIPT: &"path",
	KonadoOpcode.Type.CAMERA_MOVE: &"camera",
	KonadoOpcode.Type.CAMERA_MOVE_ASYNC: &"camera",
}

const STATE_DOMAINS := {
	KonadoOpcode.Type.DIALOGUE: [&"dialogue_box", &"audio", &"stage"],
	KonadoOpcode.Type.BACKGROUND: [&"stage"],
	KonadoOpcode.Type.ACTOR_SHOW: [&"stage"],
	KonadoOpcode.Type.ACTOR_CHANGE: [&"stage"],
	KonadoOpcode.Type.ACTOR_MOVE: [&"stage"],
	KonadoOpcode.Type.ACTOR_MOTION: [&"stage"],
	KonadoOpcode.Type.ACTOR_EXIT: [&"stage"],
	KonadoOpcode.Type.BGM_PLAY: [&"audio"],
	KonadoOpcode.Type.BGM_STOP: [&"audio"],
	KonadoOpcode.Type.SFX_PLAY: [&"audio"],
	KonadoOpcode.Type.VARIABLE: [&"temporary_variables", &"persistent_variables"],
	KonadoOpcode.Type.CAMERA_MOVE: [&"camera"],
	KonadoOpcode.Type.CAMERA_RESET: [&"camera"],
	KonadoOpcode.Type.CAMERA_SHAKE: [&"camera"],
	KonadoOpcode.Type.CAMERA_MOVE_ASYNC: [&"camera"],
	KonadoOpcode.Type.CAMERA_RESET_ASYNC: [&"camera"],
	KonadoOpcode.Type.CAMERA_SHAKE_ASYNC: [&"camera"],
	KonadoOpcode.Type.CAMERA_STOP_ASYNC: [&"camera"],
	KonadoOpcode.Type.SCREEN_TEXT: [&"screen_text"],
	KonadoOpcode.Type.TEXTBOX_SHOW: [&"dialogue_box"],
	KonadoOpcode.Type.TEXTBOX_HIDE: [&"dialogue_box"],
	KonadoOpcode.Type.CALL_BRANCH: [&"execution"],
	KonadoOpcode.Type.RETURN: [&"execution"],
	KonadoOpcode.Type.CHOICE: [&"choices"],
}

const COMMANDS := {
	"dialogue":
	{
		"opcode": KonadoOpcode.Type.DIALOGUE,
		"operands":
		[
			["speaker_kind", VALUE, false],
			["speaker", STRING, true],
			["content", STRING, true],
			["interval", VALUE, true],
			["speed", VALUE, true],
			["voice_id", STRING, true]
		],
		"parameters":
		{
			"speed": {"type": "number", "min_exclusive": 0.0},
			"interval": {"type": "number", "min": 0.0}
		},
		"blocking": true,
		"rollback": ROLLBACK_REVERSIBLE
	},
	"actor.show":
	{
		"opcode": KonadoOpcode.Type.ACTOR_SHOW,
		"operands":
		[
			["actor", STRING, true],
			["state", STRING, true],
			["position", VALUE, true],
			["duration", VALUE, true]
		],
		"parameters": {"duration": {"type": "number", "min": 0.0}},
		"blocking": true,
		"rollback": ROLLBACK_REVERSIBLE
	},
	"actor.change":
	{
		"opcode": KonadoOpcode.Type.ACTOR_CHANGE,
		"operands": [["actor", STRING, true], ["state", STRING, true], ["duration", VALUE, true]],
		"parameters": {"duration": {"type": "number", "min": 0.0}},
		"blocking": true,
		"rollback": ROLLBACK_REVERSIBLE
	},
	"actor.move":
	{
		"opcode": KonadoOpcode.Type.ACTOR_MOVE,
		"operands": [["actor", STRING, true], ["position", VALUE, true], ["duration", VALUE, true]],
		"parameters": {"duration": {"type": "number", "min": 0.0}},
		"blocking": true,
		"rollback": ROLLBACK_REVERSIBLE
	},
	"actor.exit":
	{
		"opcode": KonadoOpcode.Type.ACTOR_EXIT,
		"operands": [["actor", STRING, true], ["duration", VALUE, true]],
		"parameters": {"duration": {"type": "number", "min": 0.0}},
		"blocking": true,
		"rollback": ROLLBACK_REVERSIBLE
	},
	"actor.motion":
	{
		"opcode": KonadoOpcode.Type.ACTOR_MOTION,
		"operands": [["actor", STRING, true], ["motion", STRING, true], ["duration", VALUE, true]],
		"parameters": {"duration": {"type": "number", "min": 0.0}},
		"blocking": true,
		"rollback": ROLLBACK_REVERSIBLE
	},
	"background":
	{
		"opcode": KonadoOpcode.Type.BACKGROUND,
		"operands":
		[["background", STRING, true], ["effect", VALUE, true], ["duration", VALUE, true]],
		"parameters": {"duration": {"type": "number", "min": 0.0}},
		"blocking": true,
		"rollback": ROLLBACK_REVERSIBLE
	},
	"audio.bgm.play":
	{
		"opcode": KonadoOpcode.Type.BGM_PLAY,
		"operands": [["resource", STRING, true]],
		"parameters": {},
		"blocking": false,
		"rollback": ROLLBACK_REVERSIBLE
	},
	"audio.bgm.stop":
	{
		"opcode": KonadoOpcode.Type.BGM_STOP,
		"operands": [],
		"parameters": {},
		"blocking": false,
		"rollback": ROLLBACK_REVERSIBLE
	},
	"audio.sfx.play":
	{
		"opcode": KonadoOpcode.Type.SFX_PLAY,
		"operands": [["resource", STRING, true]],
		"parameters": {},
		"blocking": false,
		"rollback": ROLLBACK_REVERSIBLE
	},
	"choice":
	{
		"opcode": KonadoOpcode.Type.CHOICE,
		"operands": [["options", CHOICES, true], ["filters", FILTERS, false]],
		"parameters": {},
		"blocking": true,
		"rollback": ROLLBACK_REVERSIBLE
	},
	"condition":
	{
		"opcode": KonadoOpcode.Type.CONDITION,
		"operands":
		[
			["variable", STRING, false],
			["operator", VALUE, false],
			["target", VALUE, false],
			["persistent", VALUE, false]
		],
		"parameters": {},
		"blocking": false,
		"rollback": ROLLBACK_REVERSIBLE
	},
	"jump.script":
	{
		"opcode": KonadoOpcode.Type.JUMP_SCRIPT,
		"operands": [["path", STRING, false]],
		"parameters": {},
		"blocking": false,
		"rollback": ROLLBACK_CHECKPOINT
	},
	"jump.branch":
	{
		"opcode": KonadoOpcode.Type.JUMP_BRANCH,
		"operands": [["branch", STRING, false]],
		"parameters": {},
		"blocking": false,
		"rollback": ROLLBACK_REVERSIBLE
	},
	"call.branch":
	{
		"opcode": KonadoOpcode.Type.CALL_BRANCH,
		"operands": [["branch", STRING, false]],
		"parameters": {},
		"blocking": false,
		# 调用本身完全可回退：返回点保存在运行期调用栈里，随 delta/快照一起还原。
		# 注意：失败恢复不能提供 skip —— next_pc 指向被调分支入口而不是调用点之后，
		# 跳过会把控制流带进没有返回帧的分支（见 KonadoRuntimeFailureSession）。
		"rollback": ROLLBACK_REVERSIBLE
	},
	"return":
	{
		"opcode": KonadoOpcode.Type.RETURN,
		"operands": [],
		"parameters": {},
		"blocking": false,
		"rollback": ROLLBACK_REVERSIBLE
	},
	# signal 是“可重放”的一次性副作用：回退可以跨越它，重放到该指令时会重新发射，
	# 由信号处理函数自行保证幂等（例如只改快照内的脚本变量）。成就指令保持不可逆，外部计数不会被二次累加。
	"signal":
	{
		"opcode": KonadoOpcode.Type.SIGNAL,
		"operands": [["content", STRING, false]],
		"parameters": {},
		"blocking": false,
		"rollback": ROLLBACK_REVERSIBLE
	},
	"achievement.unlock":
	{
		"opcode": KonadoOpcode.Type.ACHIEVEMENT_UNLOCK,
		"operands": [["id", STRING, false]],
		"parameters": {},
		"blocking": false,
		"rollback": ROLLBACK_BARRIER
	},
	"achievement.progress":
	{
		"opcode": KonadoOpcode.Type.ACHIEVEMENT_PROGRESS,
		"operands": [["id", STRING, false], ["value", VALUE, false]],
		"parameters": {},
		"blocking": false,
		"rollback": ROLLBACK_BARRIER
	},
	"achievement.flag":
	{
		"opcode": KonadoOpcode.Type.ACHIEVEMENT_FLAG,
		"operands": [["id", STRING, false], ["value", VALUE, false]],
		"parameters": {},
		"blocking": false,
		"rollback": ROLLBACK_BARRIER
	},
	"variable":
	{
		"opcode": KonadoOpcode.Type.VARIABLE,
		"operands":
		[
			["name", STRING, false],
			["operation", VALUE, false],
			["operand", VALUE, false],
			["persistent", VALUE, false]
		],
		"parameters": {},
		"blocking": false,
		"rollback": ROLLBACK_REVERSIBLE
	},
	"halt":
	{
		"opcode": KonadoOpcode.Type.HALT,
		"operands": [],
		"parameters": {},
		"blocking": false,
		"rollback": ROLLBACK_CHECKPOINT
	},
	"camera.move":
	{
		"opcode": KonadoOpcode.Type.CAMERA_MOVE,
		"operands":
		[["camera", STRING, true], ["transition", STRING, true], ["duration", VALUE, true]],
		"parameters": {"duration": {"type": "number", "min": 0.0}},
		"blocking": true,
		"rollback": ROLLBACK_REVERSIBLE
	},
	"camera.reset":
	{
		"opcode": KonadoOpcode.Type.CAMERA_RESET,
		"operands": [["transition", STRING, true], ["duration", VALUE, true]],
		"parameters": {"duration": {"type": "number", "min": 0.0}},
		"blocking": true,
		"rollback": ROLLBACK_REVERSIBLE
	},
	"camera.shake":
	{
		"opcode": KonadoOpcode.Type.CAMERA_SHAKE,
		"operands": [["duration", VALUE, true]],
		"parameters": {"duration": {"type": "number", "min": 0.0}},
		"blocking": true,
		"rollback": ROLLBACK_REVERSIBLE
	},
	"screen_text":
	{
		"opcode": KonadoOpcode.Type.SCREEN_TEXT,
		"operands": [["lines", STRING_ARRAY, true]],
		"parameters": {},
		"blocking": true,
		"rollback": ROLLBACK_REVERSIBLE
	},
	"textbox.show":
	{
		"opcode": KonadoOpcode.Type.TEXTBOX_SHOW,
		"operands": [["duration", VALUE, true]],
		"parameters": {"duration": {"type": "number", "min": 0.0}},
		"blocking": true,
		"rollback": ROLLBACK_REVERSIBLE
	},
	"textbox.hide":
	{
		"opcode": KonadoOpcode.Type.TEXTBOX_HIDE,
		"operands": [["duration", VALUE, true]],
		"parameters": {"duration": {"type": "number", "min": 0.0}},
		"blocking": true,
		"rollback": ROLLBACK_REVERSIBLE
	},
	"wait.signal":
	{
		"opcode": KonadoOpcode.Type.WAIT_SIGNAL,
		"operands": [["name", STRING, false]],
		"parameters": {},
		"blocking": true,
		"rollback": ROLLBACK_REVERSIBLE
	},
	# 异步相机指令只改变相机变换，属于快照可逆状态：回退会取消进行中的 Tween 并按快照还原，
	# 继续前进时会重新执行，因此它们不是不可逆副作用。
	"camera.move.async":
	{
		"opcode": KonadoOpcode.Type.CAMERA_MOVE_ASYNC,
		"operands":
		[["camera", STRING, true], ["transition", STRING, true], ["duration", VALUE, true]],
		"parameters": {"duration": {"type": "number", "min": 0.0}},
		"blocking": false,
		"rollback": ROLLBACK_REVERSIBLE
	},
	"camera.reset.async":
	{
		"opcode": KonadoOpcode.Type.CAMERA_RESET_ASYNC,
		"operands": [["transition", STRING, true], ["duration", VALUE, true]],
		"parameters": {"duration": {"type": "number", "min": 0.0}},
		"blocking": false,
		"rollback": ROLLBACK_REVERSIBLE
	},
	"camera.shake.async":
	{
		"opcode": KonadoOpcode.Type.CAMERA_SHAKE_ASYNC,
		"operands": [["duration", VALUE, true]],
		"parameters": {"duration": {"type": "number", "min": 0.0}},
		"blocking": false,
		"rollback": ROLLBACK_REVERSIBLE
	},
	"camera.stop.async":
	{
		"opcode": KonadoOpcode.Type.CAMERA_STOP_ASYNC,
		"operands": [],
		"parameters": {},
		"blocking": false,
		"rollback": ROLLBACK_REVERSIBLE
	},
}

static var _by_opcode: Dictionary = {}


static func command_for_node(node: KonadoScriptSyntaxTree.ASTNode) -> String:
	if node is KonadoScriptSyntaxTree.DialogueNode:
		return "dialogue"
	if node is KonadoScriptSyntaxTree.BackgroundNode:
		return "background"
	if node is KonadoScriptSyntaxTree.ActorNode:
		return "actor.%s" % node.action
	if node is KonadoScriptSyntaxTree.AudioNode:
		return "audio.%s.%s" % [node.target, node.action]
	if node is KonadoScriptSyntaxTree.ChoiceGroupNode:
		return "choice"
	if node is KonadoScriptSyntaxTree.IfElseNode:
		return "condition"
	if node is KonadoScriptSyntaxTree.VariableNode:
		return "variable"
	if node is KonadoScriptSyntaxTree.JumpNode:
		return "jump.script"
	if node is KonadoScriptSyntaxTree.JumpBranchNode:
		return "jump.branch"
	if node is KonadoScriptSyntaxTree.CallNode:
		return "call.branch"
	if node is KonadoScriptSyntaxTree.ReturnNode:
		return "return"
	if node is KonadoScriptSyntaxTree.SignalNode:
		return "signal"
	if node is KonadoScriptSyntaxTree.AchievementNode:
		match node.action:
			"increment":
				return "achievement.progress"
			"set_flag":
				return "achievement.flag"
			_:
				return "achievement.%s" % node.action
	if node is KonadoScriptSyntaxTree.EndNode:
		return "halt"
	if node is KonadoScriptSyntaxTree.ScreenTextNode:
		return "screen_text"
	if node is KonadoScriptSyntaxTree.ShowTextBoxNode:
		return "textbox.show"
	if node is KonadoScriptSyntaxTree.HideTextBoxNode:
		return "textbox.hide"
	if node is KonadoScriptSyntaxTree.WaitSignalNode:
		return "wait.signal"
	if node is KonadoScriptSyntaxTree.CameraNode:
		return "camera.%s" % node.action
	if node is KonadoScriptSyntaxTree.AsyncCamNode:
		return "camera.%s.async" % node.action
	return ""


static func parameters_for_node(node: KonadoScriptSyntaxTree.ASTNode) -> Dictionary:
	var result := COMMON_PARAMETERS.duplicate(true)
	var command := command_for_node(node)
	if COMMANDS.has(command):
		result.merge(COMMANDS[command]["parameters"], true)
	return result


static func definition_for_opcode(opcode: int) -> Dictionary:
	if _by_opcode.is_empty():
		for command: String in COMMANDS:
			var definition: Dictionary = COMMANDS[command].duplicate(true)
			definition["command"] = command
			definition["handler"] = RUNTIME_HANDLERS.get(int(definition["opcode"]), &"")
			definition["cancellation"] = _cancellation_for(definition)
			definition["resource_operand"] = RESOURCE_OPERANDS.get(int(definition["opcode"]), &"")
			definition["doc_anchor"] = "konadoscript-%s" % command.replace(".", "-")
			definition["units"] = _units_for(definition)
			definition["defaults"] = _defaults_for(definition)
			_by_opcode[int(definition["opcode"])] = definition
	return _by_opcode.get(opcode, {})


static func schema_for(opcode: int) -> Array:
	return definition_for_opcode(opcode).get("operands", [])


static func rollback_policy(opcode: int) -> String:
	return String(definition_for_opcode(opcode).get("rollback", ROLLBACK_BARRIER))


static func is_blocking(opcode: int) -> bool:
	return bool(definition_for_opcode(opcode).get("blocking", false))


static func runtime_handler(opcode: int) -> StringName:
	return StringName(definition_for_opcode(opcode).get("handler", &""))


static func state_domains(opcode: int) -> Array:
	return STATE_DOMAINS.get(opcode, []).duplicate()


static func _cancellation_for(definition: Dictionary) -> String:
	var opcode := int(definition.get("opcode", -1))
	if (
		opcode
		in [
			KonadoOpcode.Type.CAMERA_MOVE_ASYNC,
			KonadoOpcode.Type.CAMERA_RESET_ASYNC,
			KonadoOpcode.Type.CAMERA_SHAKE_ASYNC,
			KonadoOpcode.Type.CAMERA_STOP_ASYNC,
		]
	):
		return CANCEL_BACKGROUND_TASK
	if definition.get("rollback") == ROLLBACK_BARRIER:
		return CANCEL_EXTERNAL
	if not bool(definition.get("blocking", false)):
		return CANCEL_SYNC
	if (
		opcode
		in [
			KonadoOpcode.Type.CAMERA_MOVE,
			KonadoOpcode.Type.CAMERA_RESET,
			KonadoOpcode.Type.CAMERA_SHAKE
		]
	):
		return CANCEL_CALLBACK
	return CANCEL_SIGNAL


static func _units_for(_definition: Dictionary) -> Dictionary:
	return {"duration": "seconds", "interval": "seconds", "speed": "multiplier"}


static func _defaults_for(definition: Dictionary) -> Dictionary:
	var result := {}
	var parameters: Dictionary = definition.get("parameters", {})
	if parameters.has("duration"):
		result["duration"] = "component_default"
	if parameters.has("speed"):
		result["speed"] = 1.0
	if parameters.has("interval"):
		result["interval"] = "dialogue_default"
	return result
