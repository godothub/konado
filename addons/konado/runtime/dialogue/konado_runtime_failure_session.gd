extends RefCounted
class_name KonadoRuntimeFailureSession

## Immutable identity and recovery policy for one suspended VM instruction.

const ACTION_RETRY := &"retry"
const ACTION_SKIP := &"skip"
const ACTION_CONTINUE_TRUE := &"continue_true"
const ACTION_CONTINUE_FALSE := &"continue_false"
const ACTION_STOP := &"stop"
const RESOLUTION_REINITIALIZE := &"reinitialize"
const RESOLUTION_REPLACE_SHOT := &"replace_shot"
const RESOLUTION_ROLLBACK := &"rollback"
const RESOLUTION_RESTORE_CHECKPOINT := &"restore_checkpoint"
const RESOLUTION_RESTORE_SNAPSHOT := &"restore_snapshot"
const RESOLUTION_CANCELLED := &"cancelled"

var report: Dictionary
var token: Dictionary
var instruction: KonadoInstruction
var program: KonadoProgram
var program_counter := KonadoProgram.INVALID_PC
var playback_generation := -1
var state_restored := false


func _init(
	failure_report: Dictionary,
	failure_token: Dictionary,
	failing_instruction: KonadoInstruction,
	failing_program: KonadoProgram,
	failure_generation: int,
	restored: bool,
) -> void:
	report = failure_report.duplicate(true)
	token = failure_token.duplicate(true)
	instruction = failing_instruction
	program = failing_program
	program_counter = (
		failing_instruction.pc if failing_instruction != null else KonadoProgram.INVALID_PC
	)
	playback_generation = failure_generation
	state_restored = restored


func is_current(host: KonadoDialogueManager) -> bool:
	return (
		host != null
		and instruction != null
		and program != null
		and host.dialogue_state == KonadoDialogueManager.DialogState.FAILED
		and host._vm.program == program
		and host._vm.pc == program_counter
		and host._token_is_active(token)
		and host._playback_generation == playback_generation
	)


func available_actions() -> PackedStringArray:
	var actions := PackedStringArray()
	if not state_restored or instruction == null:
		actions.append(ACTION_STOP)
		return actions

	var rollback_policy := KonadoScriptCommandRegistry.rollback_policy(instruction.opcode())
	if rollback_policy != KonadoScriptCommandRegistry.ROLLBACK_BARRIER:
		actions.append(ACTION_RETRY)
		if instruction.opcode() == KonadoOpcode.Type.CONDITION:
			if instruction.true_pc() != KonadoProgram.INVALID_PC:
				actions.append(ACTION_CONTINUE_TRUE)
			if instruction.false_pc() != KonadoProgram.INVALID_PC:
				actions.append(ACTION_CONTINUE_FALSE)
		elif (
			rollback_policy == KonadoScriptCommandRegistry.ROLLBACK_REVERSIBLE
			and instruction.next_pc() != KonadoProgram.INVALID_PC
			# call 的 next_pc 是“被调分支入口”，不是调用点之后的指令；跳过 call 会
			# 进入没有返回帧的分支，因此这里只允许 retry / stop。
			and instruction.opcode() != KonadoOpcode.Type.CALL_BRANCH
		):
			actions.append(ACTION_SKIP)
	actions.append(ACTION_STOP)
	return actions


func supports(action: StringName) -> bool:
	return action in available_actions()


func target_for(action: StringName) -> int:
	if instruction == null:
		return KonadoProgram.INVALID_PC
	match action:
		ACTION_SKIP:
			return instruction.next_pc()
		ACTION_CONTINUE_TRUE:
			return instruction.true_pc()
		ACTION_CONTINUE_FALSE:
			return instruction.false_pc()
	return KonadoProgram.INVALID_PC
