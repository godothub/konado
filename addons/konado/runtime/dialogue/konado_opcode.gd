extends RefCounted
class_name KonadoOpcode

## Stable Konado 2.9 bytecode operation identifiers.
##
## These values are part of the Program ABI. Append new operations; never
## reorder existing ones inside the same format version.
enum Type {
	DIALOGUE,
	ACTOR_SHOW,
	ACTOR_CHANGE,
	ACTOR_MOVE,
	BACKGROUND,
	ACTOR_EXIT,
	BGM_PLAY,
	BGM_STOP,
	SFX_PLAY,
	CHOICE,
	CONDITION,
	RESERVED_BRANCH,
	JUMP_SCRIPT,
	JUMP_BRANCH,
	SIGNAL,
	ACHIEVEMENT_UNLOCK,
	ACHIEVEMENT_PROGRESS,
	ACHIEVEMENT_FLAG,
	VARIABLE,
	HALT,
	ACTOR_MOTION,
	CAMERA_MOVE,
	CAMERA_RESET,
	CAMERA_SHAKE,
	SCREEN_TEXT,
	TEXTBOX_SHOW,
	TEXTBOX_HIDE,
	WAIT_SIGNAL,
	CAMERA_MOVE_ASYNC,
	CAMERA_RESET_ASYNC,
	CAMERA_SHAKE_ASYNC,
	CAMERA_STOP_ASYNC,
	CALL_BRANCH,
	RETURN,
}

const NAMES := [
	"dialogue",
	"actor.show",
	"actor.change",
	"actor.move",
	"background",
	"actor.exit",
	"audio.bgm.play",
	"audio.bgm.stop",
	"audio.sfx.play",
	"choice",
	"condition",
	"reserved.branch",
	"jump.script",
	"jump.branch",
	"signal",
	"achievement.unlock",
	"achievement.progress",
	"achievement.flag",
	"variable",
	"halt",
	"actor.motion",
	"camera.move",
	"camera.reset",
	"camera.shake",
	"screen_text",
	"textbox.show",
	"textbox.hide",
	"wait.signal",
	"camera.move.async",
	"camera.reset.async",
	"camera.shake.async",
	"camera.stop.async",
	"call.branch",
	"return",
]


static func name_of(opcode: int) -> String:
	return NAMES[opcode] if opcode >= 0 and opcode < NAMES.size() else "unknown(%d)" % opcode


static func is_terminal(opcode: int) -> bool:
	return opcode in [Type.HALT, Type.JUMP_SCRIPT]


static func is_control_flow(opcode: int) -> bool:
	return opcode in [
		Type.CHOICE,
		Type.CONDITION,
		Type.JUMP_SCRIPT,
		Type.JUMP_BRANCH,
		Type.CALL_BRANCH,
		Type.RETURN,
		Type.HALT,
	]
