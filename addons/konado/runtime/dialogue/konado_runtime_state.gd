extends RefCounted
class_name KonadoRuntimeState

## Serializable VM state. Scene nodes and signal connections never enter a snapshot.

const SCHEMA_VERSION := 3
const MAX_SNAPSHOT_ACTORS := 256

const DOMAIN_EXECUTION := &"execution"
const DOMAIN_TEMPORARY_VARIABLES := &"temporary_variables"
const DOMAIN_PERSISTENT_VARIABLES := &"persistent_variables"
const DOMAIN_DIALOGUE_BOX := &"dialogue_box"
const DOMAIN_SCREEN_TEXT := &"screen_text"
const DOMAIN_STAGE := &"stage"
const DOMAIN_AUDIO := &"audio"
const DOMAIN_CAMERA := &"camera"
const DOMAIN_RANDOM_STATE := &"random_state"
## `once` 选项的使用记录（菜单集）。与脚本变量分开存放，但仍属于运行期状态。
const DOMAIN_CHOICES := &"choices"

const ALL_DOMAINS := [
	DOMAIN_EXECUTION,
	DOMAIN_TEMPORARY_VARIABLES,
	DOMAIN_PERSISTENT_VARIABLES,
	DOMAIN_DIALOGUE_BOX,
	DOMAIN_SCREEN_TEXT,
	DOMAIN_STAGE,
	DOMAIN_AUDIO,
	DOMAIN_CAMERA,
	DOMAIN_RANDOM_STATE,
	DOMAIN_CHOICES,
]
const ACTOR_STATE_OPCODES := [
	KonadoOpcode.Type.ACTOR_SHOW,
	KonadoOpcode.Type.ACTOR_CHANGE,
	KonadoOpcode.Type.ACTOR_MOVE,
	KonadoOpcode.Type.ACTOR_MOTION,
	KonadoOpcode.Type.ACTOR_EXIT,
]


static func capture(manager: KonadoDialogueManager) -> Dictionary:
	return capture_domains(manager, ALL_DOMAINS, true)


static func capture_domains(
	manager: KonadoDialogueManager, domains: Array, include_schema := false
) -> Dictionary:
	var result := {}
	if include_schema:
		result["schema_version"] = SCHEMA_VERSION
	for domain: StringName in domains:
		match domain:
			DOMAIN_EXECUTION:
				result[domain] = {
					"shot_path":
					manager.current_shot.source_path if manager.current_shot != null else "",
					"program_fingerprint":
					(
						manager.current_shot.program_fingerprint()
						if manager.current_shot != null
						else ""
					),
					"call_stack": manager._vm.call_stack.export_frames(),
				}
			DOMAIN_TEMPORARY_VARIABLES:
				result[domain] = manager._temp_variables.duplicate(true)
			DOMAIN_PERSISTENT_VARIABLES:
				result[domain] = (
					manager.variable_store.to_dict() if manager.variable_store != null else {}
				)
			DOMAIN_DIALOGUE_BOX:
				result[domain] = (
					manager.dialogue_box.capture_state() if manager.dialogue_box != null else {}
				)
			DOMAIN_SCREEN_TEXT:
				result[domain] = (
					manager.screen_text.capture_state() if manager.screen_text != null else {}
				)
			DOMAIN_STAGE:
				result[domain] = (
					manager.stage_controller.capture_state()
					if manager.stage_controller != null
					else {}
				)
			DOMAIN_AUDIO:
				result[domain] = (
					manager.audio_controller.capture_state()
					if manager.audio_controller != null
					else {}
				)
			DOMAIN_CAMERA:
				result[domain] = (
					manager.camera_controller.capture_state()
					if manager.camera_controller != null
					else {}
				)
			DOMAIN_RANDOM_STATE:
				result[domain] = manager._rng.state
			DOMAIN_CHOICES:
				result[domain] = manager._choices().export_state()
	return result


static func capture_instruction_patch(
	manager: KonadoDialogueManager, instruction: KonadoInstruction
) -> Dictionary:
	if instruction == null:
		return {}
	var opcode := instruction.opcode()
	if opcode in ACTOR_STATE_OPCODES:
		return _capture_stage_paths(manager, ["actors", "highlighted_actor"])
	match opcode:
		KonadoOpcode.Type.VARIABLE:
			return _capture_variable_patch(manager, instruction)
		KonadoOpcode.Type.DIALOGUE:
			return _capture_dialogue_patch(manager, instruction)
		KonadoOpcode.Type.BACKGROUND:
			return _capture_stage_paths(manager, ["background"])
		KonadoOpcode.Type.BGM_PLAY, KonadoOpcode.Type.BGM_STOP:
			return _capture_audio_path(manager, "bgm")
		KonadoOpcode.Type.SFX_PLAY:
			return _capture_audio_path(manager, "sound_effect")
	return KonadoStateDelta.replacement_patch(
		capture_domains(manager, KonadoScriptCommandRegistry.state_domains(instruction.opcode()))
	)


static func _capture_variable_patch(
	manager: KonadoDialogueManager, instruction: KonadoInstruction
) -> Dictionary:
	var name := String(instruction.value(&"name"))
	if not bool(instruction.value(&"persistent")):
		return (
			KonadoStateDelta
			. path_patch(
				[DOMAIN_TEMPORARY_VARIABLES, name],
				manager._temp_variables.has(name),
				manager._temp_variables.get(name),
			)
		)
	var exists := manager.variable_store != null and manager.variable_store.has(name)
	var value: Variant = manager.variable_store.get_value(name) if exists else null
	return (
		KonadoStateDelta
		. combine_patches(
			[
				KonadoStateDelta.path_patch(
					[DOMAIN_PERSISTENT_VARIABLES, "variables", name], exists, value
				),
				(
					KonadoStateDelta
					. path_patch(
						[DOMAIN_PERSISTENT_VARIABLES, "types", name],
						exists,
						typeof(value) if exists else null,
					)
				),
			]
		)
	)


static func _capture_dialogue_patch(
	manager: KonadoDialogueManager, instruction: KonadoInstruction
) -> Dictionary:
	var dialogue_box_state := (
		manager.dialogue_box.capture_state() if manager.dialogue_box != null else {}
	)
	var patches: Array[Dictionary] = [
		KonadoStateDelta.path_patch([DOMAIN_DIALOGUE_BOX], true, dialogue_box_state),
	]
	patches.append_array(_stage_path_patches(manager, ["highlighted_actor"]))
	if not String(instruction.value(&"voice_id")).is_empty():
		patches.append(_capture_audio_path(manager, "voice"))
	return KonadoStateDelta.combine_patches(patches)


static func _capture_stage_paths(
	manager: KonadoDialogueManager, paths: Array[String]
) -> Dictionary:
	return KonadoStateDelta.combine_patches(_stage_path_patches(manager, paths))


static func _stage_path_patches(
	manager: KonadoDialogueManager, paths: Array[String]
) -> Array[Dictionary]:
	var stage_state := (
		manager.stage_controller.capture_state() if manager.stage_controller != null else {}
	)
	var patches: Array[Dictionary] = []
	for path: String in paths:
		patches.append(
			KonadoStateDelta.path_patch(
				[DOMAIN_STAGE, path], stage_state.has(path), stage_state.get(path)
			)
		)
	return patches


static func _capture_audio_path(manager: KonadoDialogueManager, path: String) -> Dictionary:
	var audio_state := (
		manager.audio_controller.capture_state() if manager.audio_controller != null else {}
	)
	return KonadoStateDelta.path_patch(
		[DOMAIN_AUDIO, path], audio_state.has(path), audio_state.get(path)
	)


static func validate(state: Dictionary, manager: KonadoDialogueManager) -> bool:
	if int(state.get("schema_version", -1)) != SCHEMA_VERSION:
		return false
	var execution: Variant = state.get("execution", {})
	if (
		not execution is Dictionary
		or not execution.get("shot_path", "") is String
		or not execution.get("program_fingerprint", "") is String
		or String(execution.get("program_fingerprint", "")).is_empty()
	):
		return false
	if (
		not execution.has("call_stack")
		or not _validate_call_stack(execution["call_stack"], manager)
	):
		return false
	for key in [
		"temporary_variables",
		"persistent_variables",
		"dialogue_box",
		"screen_text",
		"stage",
		"audio",
		"camera"
	]:
		if not state.get(key, {}) is Dictionary:
			return false
	if not state.get("random_state", 0) is int:
		return false
	if not state.has("choices") or not state["choices"] is Dictionary:
		return false
	if not _validate_stage(state.get("stage", {}), manager):
		return false
	if not _validate_audio(state.get("audio", {}), manager):
		return false
	if not _validate_camera(state.get("camera", {}), manager):
		return false
	return _validate_ui(state, manager)


static func restore(state: Dictionary, manager: KonadoDialogueManager) -> bool:
	if not validate(state, manager):
		return false
	# 先恢复调用栈：它是执行位置的一部分，非法帧必须整体拒绝而不是跳到错误 pc。
	var execution: Dictionary = state.get("execution", {})
	if not _restore_call_stack(execution["call_stack"], manager):
		return false
	manager._temp_variables = state.get("temporary_variables", {}).duplicate(true)
	manager._choices().restore_state(state["choices"])
	manager._waiting_signal_name = ""
	manager._rng.state = int(state.get("random_state", manager._rng.state))
	if manager.variable_store != null:
		manager.variable_store.from_dict(state.get("persistent_variables", {}))
	var valid := _restore_stage(state.get("stage", {}), manager)
	if manager.audio_controller != null:
		valid = manager.audio_controller.restore_state(state.get("audio", {})) and valid
	if manager.camera_controller != null:
		valid = manager.camera_controller.restore_state(state.get("camera", {})) and valid
	if manager.screen_text != null:
		valid = manager.screen_text.restore_state(state.get("screen_text", {})) and valid
	if manager.dialogue_box != null:
		valid = manager.dialogue_box.restore_state(state.get("dialogue_box", {})) and valid
	return valid


static func _restore_stage(state: Dictionary, manager: KonadoDialogueManager) -> bool:
	var acting := manager.stage_controller
	if acting == null:
		return state.is_empty()
	acting.cancel_pending_operations()
	acting.remove_all_actors(true)
	var valid := _restore_background(String(state.get("background", "")), manager)
	for actor_state: Dictionary in state.get("actors", []):
		var actor_id := String(actor_state.get("id", ""))
		var character := _find_character(actor_id, manager.character_list)
		if character == null or character.character_scene == null:
			valid = false
			continue
		(
			acting
			. show_actor(
				actor_id,
				int(actor_state.get("horizontal_division", manager.horizontal_division)),
				int(actor_state.get("position", 0)),
				String(actor_state.get("state", "")),
				character.character_scene,
				character.actor_motion_layer,
				0.0,
			)
		)
	var highlighted := String(state.get("highlighted_actor", ""))
	if not highlighted.is_empty():
		acting.highlight_actor(highlighted)
	return valid


## 调用栈是 2.9 运行期状态的必需字段；2.8 存档在版本校验阶段就会被拒绝。
static func _validate_call_stack(value: Variant, manager: KonadoDialogueManager) -> bool:
	return KonadoCallStack.is_valid_frames(value, _call_instruction_limit(manager))


static func _restore_call_stack(value: Variant, manager: KonadoDialogueManager) -> bool:
	return manager._vm.call_stack.restore_frames(value, _call_instruction_limit(manager))


## 返回点必须落在当前镜头 Program 内；没有镜头时跳过范围检查。
static func _call_instruction_limit(manager: KonadoDialogueManager) -> int:
	if manager.current_shot == null or manager.current_shot.program == null:
		return -1
	return manager.current_shot.program.instruction_count()


static func _validate_stage(state: Dictionary, manager: KonadoDialogueManager) -> bool:
	if state.is_empty():
		return true
	if manager.stage_controller == null:
		return false
	var actors_value: Variant = state.get("actors", [])
	if not actors_value is Array or actors_value.size() > MAX_SNAPSHOT_ACTORS:
		return false
	var actor_ids := {}
	for actor_value: Variant in actors_value:
		if not actor_value is Dictionary:
			return false
		var actor_state: Dictionary = actor_value
		var actor_id := String(actor_state.get("id", ""))
		if actor_id.is_empty() or actor_ids.has(actor_id):
			return false
		actor_ids[actor_id] = true
		var character := _find_character(actor_id, manager.character_list)
		if character == null or character.character_scene == null:
			return false
	var highlighted := String(state.get("highlighted_actor", ""))
	if not highlighted.is_empty() and not actor_ids.has(highlighted):
		return false
	var background_id := String(state.get("background", ""))
	if (
		not background_id.is_empty()
		and not _background_exists(background_id, manager.background_list)
	):
		return false
	return true


static func _validate_audio(state: Dictionary, manager: KonadoDialogueManager) -> bool:
	if state.is_empty():
		return true
	if manager.audio_controller == null:
		return false
	for key in ["bgm", "voice", "sound_effect"]:
		var player_state: Variant = state.get(key, {})
		if not player_state is Dictionary:
			return false
		var path := String(player_state.get("stream_path", ""))
		if not path.is_empty() and not ResourceLoader.exists(path, "AudioStream"):
			return false
	return true


static func _validate_camera(state: Dictionary, manager: KonadoDialogueManager) -> bool:
	if state.is_empty():
		return true
	return (
		manager.camera_controller != null
		and state.get("position") is Vector2
		and state.get("zoom") is Vector2
		and state.get("offset") is Vector2
	)


static func _validate_ui(state: Dictionary, manager: KonadoDialogueManager) -> bool:
	var dialogue_box: Dictionary = state.get("dialogue_box", {})
	if not dialogue_box.is_empty() and manager.dialogue_box == null:
		return false
	var screen_text: Dictionary = state.get("screen_text", {})
	if not screen_text.is_empty() and manager.screen_text == null:
		return false
	if not screen_text.is_empty() and not screen_text.get("lines", []) is Array:
		return false
	return true


static func _background_exists(background_id: String, list: KonadoBackgroundList) -> bool:
	if list == null:
		return false
	for background in list.background_list:
		if (
			background != null
			and background.background_name == background_id
			and background.background_scene != null
		):
			return true
	return false


static func _restore_background(background_id: String, manager: KonadoDialogueManager) -> bool:
	var acting := manager.stage_controller
	if background_id.is_empty():
		acting.clean_background(KonadoStageController.BackgroundTransitionEffect.NONE)
		return true
	if manager.background_list == null:
		return false
	for background in manager.background_list.background_list:
		if background != null and background.background_name == background_id:
			if background.background_scene == null:
				return false
			(
				acting
				. change_background_scene(
					background.background_scene,
					background_id,
					KonadoStageController.BackgroundTransitionEffect.NONE,
					0.0,
				)
			)
			return true
	return false


static func _find_character(actor_id: String, list: KonadoCharacterList) -> KonadoCharacter:
	if list == null:
		return null
	for character in list.characters:
		if character != null and character.character_id == actor_id:
			return character
	return null
