extends RefCounted

## Resource lookup, localization and persistence services for the atomic runtime.

var _host: KonadoDialogueManager
var _variable_pattern := RegEx.create_from_string("([%$])([\\p{L}_][\\p{L}\\p{N}_-]*)")
var _missing_variable_warnings: Dictionary = {}
var _translation_reload_queued := false
var _loaded_locale := ""


func _init(host: KonadoDialogueManager) -> void:
	_host = host


func _display_background(name: String, effect: int, duration: float, request_id := 0) -> Dictionary:
	if _host.stage_controller == null:
		return _failure(
			&"runtime.controller_missing",
			"stage_controller 未配置",
			"stage",
			"background",
			"controller",
			"stage_controller",
		)
	var target: KonadoBackground
	if _host.background_list != null:
		for background in _host.background_list.background_list:
			if background.background_name == name:
				target = background
				break
	if target == null or target.background_scene == null:
		return _failure(
			&"stage.background_not_found",
			"未找到背景资源 '%s'" % name,
			"stage",
			"background",
			"background",
			name,
		)
	_host.stage_controller.change_background_scene(
		target.background_scene, name, effect, duration, false, request_id
	)
	return {"ok": true}


func _show_actor(
	actor: String, state: String, position: int, duration: float, request_id := 0
) -> Dictionary:
	var target: KonadoCharacter
	if _host.character_list != null:
		for character in _host.character_list.characters:
			if character.character_id == actor:
				target = character
				break
	if target == null or target.character_scene == null:
		return (
			_failure(
				&"stage.actor_not_found",
				"未找到角色资源 '%s'" % actor,
				"stage",
				"actor.show",
				"actor",
				actor,
			)
			. merged({"cause": "目标状态=%s" % state}, true)
		)
	(
		_host
		. stage_controller
		. show_actor(
			actor,
			_host.horizontal_division,
			position,
			state,
			target.character_scene,
			target.actor_motion_layer,
			duration,
			false,
			request_id,
		)
	)
	return {"ok": true}


func _play_bgm(name: String, fade := -1.0, volume_db := 0.0) -> Dictionary:
	if _host.audio_controller == null:
		return _missing_audio_controller("audio.bgm.play")
	var event_result := _play_audio_event(
		name, "audio.bgm.play", "background_music", fade, volume_db
	)
	if not event_result.is_empty():
		return event_result
	return _play_bgm_stream(name, fade, volume_db)


func _play_bgm_stream(name: String, fade: float, volume_db: float) -> Dictionary:
	if _host.audio_controller.background_music_player == null:
		return _failure(
			&"audio.player_missing",
			"background_music_player 未配置",
			"audio",
			"audio.bgm.play",
			"audio_player",
			"background_music_player",
		)
	if _host.background_music_list == null:
		return _failure(
			&"audio.list_missing",
			"background_music_list 未配置",
			"audio",
			"audio.bgm.play",
			"resource_list",
			"background_music_list",
		)
	for item in _host.background_music_list.background_music_tracks:
		if item != null and item.background_music_name == name:
			if item.stream == null:
				return _failure(
					&"audio.bgm_stream_missing",
					"BGM '%s' 没有配置音频资源" % name,
					"audio",
					"audio.bgm.play",
					"background_music",
					name,
				)
			_host.audio_controller.play_background_music(item.stream, name, fade, volume_db)
			return {"ok": true}
	return _failure(
		&"audio.bgm_not_found",
		"未找到背景音乐 '%s'：事件库与 background_music_list 中都没有该 ID" % name,
		"audio",
		"audio.bgm.play",
		"background_music",
		name,
	)


func _play_voice(name: String, priority := 0) -> Dictionary:
	if _host.audio_controller != null:
		var event_result := _play_audio_event(name, "audio.voice.play", "voice")
		if not event_result.is_empty():
			return event_result
	if _host.audio_controller == null or _host.voice_list == null:
		var failure := (
			_missing_audio_controller("audio.voice.play")
			if _host.audio_controller == null
			else _failure(
				&"audio.list_missing",
				"voice_list 未配置",
				"audio",
				"audio.voice.play",
				"resource_list",
				"voice_list",
			)
		)
		failure["duration"] = 0.0
		return failure
	if _host.audio_controller.voice_player == null:
		var missing_player := _failure(
			&"audio.player_missing",
			"voice_player 未配置",
			"audio",
			"audio.voice.play",
			"audio_player",
			"voice_player",
		)
		missing_player["duration"] = 0.0
		return missing_player
	for item in _host.voice_list.voices:
		if item != null and item.voice_name == name:
			if item.stream == null:
				var missing_stream := _failure(
					&"audio.voice_stream_missing",
					"语音 '%s' 没有配置音频资源" % name,
					"audio",
					"audio.voice.play",
					"voice",
					name,
				)
				missing_stream["duration"] = 0.0
				return missing_stream
			_host.audio_controller.play_voice(item.stream, priority)
			return {
				"ok": true,
				"duration": item.stream.get_length(),
			}
	if _host.dialogue_box != null:
		_host.dialogue_box.clear_voice_progress()
	var missing_voice := _failure(
		&"audio.voice_not_found",
		"未找到语音 '%s'：事件库与 voice_list 中都没有该 ID" % name,
		"audio",
		"audio.voice.play",
		"voice",
		name,
	)
	missing_voice["duration"] = 0.0
	return missing_voice


func _play_sound_effect(name: String, volume_db := 0.0, count := 1) -> Dictionary:
	if _host.audio_controller == null:
		return _missing_audio_controller("audio.sfx.play")
	var event_result := _play_audio_event(
		name, "audio.sfx.play", "sound_effect", -1.0, volume_db, count
	)
	if not event_result.is_empty():
		return event_result
	return _play_sound_effect_stream(name, volume_db, count)


func _play_sound_effect_stream(name: String, volume_db: float, _count: int) -> Dictionary:
	if _host.audio_controller.sound_effect_player == null:
		return _failure(
			&"audio.player_missing",
			"sound_effect_player 未配置",
			"audio",
			"audio.sfx.play",
			"audio_player",
			"sound_effect_player",
		)
	if _host.sound_effect_list == null:
		return _failure(
			&"audio.list_missing",
			"sound_effect_list 未配置",
			"audio",
			"audio.sfx.play",
			"resource_list",
			"sound_effect_list",
		)
	for item in _host.sound_effect_list.sound_effects:
		if item != null and item.sound_effect_name == name:
			if item.stream == null:
				return _failure(
					&"audio.sfx_stream_missing",
					"音效 '%s' 没有配置音频资源" % name,
					"audio",
					"audio.sfx.play",
					"sound_effect",
					name,
				)
			_host.audio_controller.play_sound_effect(item.stream, volume_db)
			return {"ok": true}
	return _failure(
		&"audio.sfx_not_found",
		"未找到音效 '%s'：事件库与 sound_effect_list 中都没有该 ID" % name,
		"audio",
		"audio.sfx.play",
		"sound_effect",
		name,
	)


func _apply_temp_operation(name: String, operation: int, operand: Variant) -> Dictionary:
	var result := KonadoValueOperations.apply(
		_host._temp_variables.get(name), operation, operand, _host._temp_variables.has(name)
	)
	if not bool(result.get("ok", false)):
		return _failure(
			&"variable.operation_failed",
			String(result.get("reason", "临时变量操作失败")),
			"variables",
			"variable",
			"temporary_variable",
			"$" + name,
		)
	_host._temp_variables[name] = result.get("value")
	_host._refresh_audio_parameters()
	return {"ok": true}


func _apply_variable_instruction(instruction: KonadoInstruction) -> Dictionary:
	var name := String(instruction.value(&"name"))
	var operation := int(instruction.value(&"operation"))
	var operand := _host._resolve_operand(instruction.value(&"operand"))
	if not bool(instruction.value(&"persistent")):
		return _apply_temp_operation(name, operation, operand)
	if _host.variable_store == null:
		return _failure(
			&"runtime.controller_missing",
			"variable_store 未配置",
			"variables",
			"variable",
			"controller",
			"variable_store",
		)
	var result := (
		KonadoValueOperations
		. apply(
			_host.variable_store.get_value(name),
			operation,
			operand,
			_host.variable_store.has(name),
		)
	)
	if not bool(result.get("ok", false)):
		return _failure(
			&"variable.operation_failed",
			String(result.get("reason", "持久变量操作失败")),
			"variables",
			"variable",
			"persistent_variable",
			"%" + name,
		)
	_host.variable_store.set_value(name, result.get("value"))
	_host._refresh_audio_parameters()
	return {"ok": true}


## 事件优先：命中事件库时返回事件播放结果；未命中返回空字典，由旧版资源列表兜底。
func _play_audio_event(
	name: String,
	operation: String,
	resource_kind: String,
	fade := -1.0,
	volume_db := 0.0,
	count := 1
) -> Dictionary:
	if _host.audio_controller == null or _host.audio_controller.engine == null:
		return {}
	var event_id := StringName(name)
	if not _host.audio_controller.engine.has_event(event_id):
		return {}
	var result: Dictionary
	if resource_kind == "voice":
		result = _host.audio_controller.play_voice_event(event_id)
	elif resource_kind == "background_music":
		result = _host.audio_controller.play_background_music_event(event_id, fade, volume_db)
	else:
		result = _host.audio_controller.play_sound_effect_event(
			event_id, {"volume_db": volume_db, "count": count}
		)
	if bool(result.get("ok", false)):
		return {"ok": true, "duration": float(result.get("duration", 0.0))}
	if bool(result.get("ignored", false)):
		return {"ok": true, "duration": 0.0}
	return _failure(
		&"audio.event_failed",
		String(result.get("message", "音频事件播放失败")),
		"audio",
		operation,
		resource_kind,
		name,
	)


## 供音频 RTPC 使用的变量快照：{"%持久变量": 值, "$临时变量": 值}。
func _audio_variable_values() -> Dictionary:
	var values := {}
	if _host.variable_store != null:
		var stored: Variant = _host.variable_store.to_dict().get("variables", {})
		if stored is Dictionary:
			for key: Variant in (stored as Dictionary).keys():
				values["%" + String(key)] = (stored as Dictionary)[key]
	for key: Variant in _host._temp_variables.keys():
		values["$" + String(key)] = _host._temp_variables[key]
	return values


func _missing_audio_controller(operation: String) -> Dictionary:
	return _failure(
		&"runtime.controller_missing",
		"audio_controller 未配置",
		"audio",
		operation,
		"controller",
		"audio_controller",
	)


func _failure(
	code: StringName,
	message: String,
	subsystem: String,
	operation: String,
	resource_kind: String,
	resource_id: String,
) -> Dictionary:
	return {
		"ok": false,
		"code": String(code),
		"message": message,
		"subsystem": subsystem,
		"operation": operation,
		"resource_kind": resource_kind,
		"resource_id": resource_id,
	}


func _execution_failure(
	result: Dictionary, fallback_code: StringName, fallback_message: String
) -> KonadoExecutionFailure:
	return (
		KonadoExecutionFailure
		. new(
			StringName(result.get("code", fallback_code)),
			String(result.get("message", fallback_message)),
			result,
		)
	)


func _interpolate_variables(text: String) -> String:
	var result := text
	var offset := 0
	for regex_match in _variable_pattern.search_all(text):
		var prefix := regex_match.get_string(1)
		var variable_name := regex_match.get_string(2)
		var resolution := _resolve_variable_result(prefix, variable_name)
		if not bool(resolution.get("found", false)):
			_warn_missing_variable(prefix, variable_name)
			continue
		var value: Variant = resolution.get("value")
		var start := regex_match.get_start() + offset
		var finish := regex_match.get_end() + offset
		var replacement := str(value)
		result = result.substr(0, start) + replacement + result.substr(finish)
		offset += replacement.length() - regex_match.get_string().length()
	return result


func _resolve_variable(prefix: String, name: String) -> Variant:
	return _resolve_variable_result(prefix, name).get("value")


func resolve_speaker(kind: int, source: String) -> Dictionary:
	match kind:
		KonadoScriptSyntaxTree.DialogueNode.SpeakerKind.ACTOR:
			return _actor_speaker_success(source)
		KonadoScriptSyntaxTree.DialogueNode.SpeakerKind.TEXT:
			return {"ok": true, "value": _interpolate_variables(source)}
		KonadoScriptSyntaxTree.DialogueNode.SpeakerKind.TEMPORARY_VARIABLE:
			return _speaker_from_variable("$", source)
		KonadoScriptSyntaxTree.DialogueNode.SpeakerKind.PERSISTENT_VARIABLE:
			return _speaker_from_variable("%", source)
	return _failure(
		&"dialogue.speaker_kind_invalid",
		"未知的对话署名类型：%d" % kind,
		"dialogue",
		"dialogue",
		"speaker_kind",
		str(kind),
	)


func _speaker_from_variable(prefix: String, name: String) -> Dictionary:
	var resolution := _resolve_variable_result(prefix, name)
	if not bool(resolution.get("found", false)):
		return _failure(
			&"variable.not_found",
			"找不到%s变量 '%s%s'" % [_variable_scope_name(prefix), prefix, name],
			"variables",
			"dialogue",
			"variable",
			prefix + name,
		)
	var value: Variant = resolution.get("value")
	if not (value is String or value is StringName):
		return _failure(
			&"dialogue.speaker_variable_type_invalid",
			"对话署名变量 '%s%s' 必须保存字符串演员 ID" % [prefix, name],
			"dialogue",
			"dialogue",
			"variable",
			prefix + name,
		)
	return _actor_speaker_success(String(value))


func _actor_speaker_success(value: String) -> Dictionary:
	if value.is_empty():
		return _failure(
			&"dialogue.speaker_empty",
			"对话署名必须是非空的演员 ID",
			"dialogue",
			"dialogue",
			"actor",
			value,
		)
	return {"ok": true, "value": value}


func _resolve_variable_result(prefix: String, name: String) -> Dictionary:
	if prefix == "%" and _host.variable_store != null and _host.variable_store.has(name):
		return {"found": true, "value": _host.variable_store.get_value(name)}
	if prefix == "$" and _host._temp_variables.has(name):
		return {"found": true, "value": _host._temp_variables[name]}
	return {"found": false}


func _warn_missing_variable(prefix: String, name: String) -> void:
	var key := prefix + name
	if _missing_variable_warnings.has(key):
		return
	_missing_variable_warnings[key] = true
	push_warning("Konado: 找不到%s变量 '%s'，保留原始占位符" % [_variable_scope_name(prefix), key])


func _variable_scope_name(prefix: String) -> String:
	return "持久" if prefix == "%" else "临时"


func _reload_localized_script(locale: String) -> bool:
	var service := _get_story_localization()
	if service == null or _host.current_shot == null:
		return false
	var source_path := _host.current_shot.source_path
	if source_path.is_empty() or source_path == "null":
		return false
	var localized := service.call("load_localized_script", source_path, locale, false) as KonadoShot
	if localized == null or not localized.ensure_script_ready():
		return false
	var current_program := _host.current_shot.program
	if (
		localized.program == null
		or localized.program.control_flow_sha256 != current_program.control_flow_sha256
	):
		push_error("Konado: 本地化剧本结构与默认剧本不一致，已拒绝热切换")
		return false
	_host.current_shot.install_locale_overlay(localized.locale_overlay)
	_host.start_dialogue_shot = localized
	_refresh_current_localized_dialogue()
	return true


func _get_story_localization() -> Node:
	if _host._story_localization == null and _host.is_inside_tree():
		_host._story_localization = (_host.get_tree().root.get_node_or_null(
			"KonadoStoryLocalization"
		))
	return _host._story_localization


func _load_localized_shot(shot: KonadoShot) -> KonadoShot:
	var service := _get_story_localization()
	if service == null or shot == null or shot.source_path.is_empty() or shot.source_path == "null":
		return shot
	var localized := (
		service.call("load_localized_script", shot.source_path, "", false) as KonadoShot
	)
	return localized if localized != null else shot


func _sync_locale() -> void:
	_loaded_locale = TranslationServer.get_locale()


func _queue_translation_reload() -> void:
	if _translation_reload_queued:
		return
	_translation_reload_queued = true
	_apply_translation_change.call_deferred()


func _apply_translation_change() -> void:
	_translation_reload_queued = false
	if not _host.is_inside_tree() or not _host.is_node_ready():
		return
	var locale := TranslationServer.get_locale()
	if locale == _loaded_locale:
		return
	if _host.current_shot == null or _reload_localized_script(locale):
		_loaded_locale = locale


func _refresh_current_localized_dialogue() -> void:
	var instruction := _host._current_instruction()
	if instruction == null:
		return
	if instruction.opcode() == KonadoOpcode.Type.DIALOGUE and _host.dialogue_box != null:
		var speaker_result: Dictionary = resolve_speaker(
			int(instruction.value(&"speaker_kind")), String(instruction.value(&"speaker"))
		)
		if not bool(speaker_result.get("ok", false)):
			return
		_host.dialogue_box.character_name = String(speaker_result.get("value", ""))
		_host.dialogue_box.dialogue_text = _interpolate_variables(
			String(instruction.value(&"content"))
		)
	elif instruction.opcode() == KonadoOpcode.Type.CHOICE and _host.choice_controller != null:
		_host.choice_controller.display_options(
			instruction.value(&"options", []), _host, 32, _host._playback_generation
		)


func _apply_setting(category: String, key: String, value: Variant) -> void:
	if category == "audio":
		if _host.audio_controller != null:
			_host.audio_controller.refresh_volume()
		return
	if category == "text":
		match key:
			"text_speed":
				_host.typing_interval = float(value)
			"auto_delay":
				_host.auto_play_delay = float(value)
			"auto_mode":
				_host.start_autoplay(bool(value))


func _save_game(id: int) -> bool:
	if _host.save_system == null:
		return false
	return _host.save_system.save_game(id)


func _load_game(id: int) -> bool:
	if _host.save_system == null:
		return false
	return _host.save_system.load_game(id)


func _delete_save(id: int) -> bool:
	if _host.save_system == null:
		return false
	return _host.save_system.delete_save(id)


func _get_save_info(id: int) -> Dictionary:
	return _host.save_system.get_save_info(id) if _host.save_system != null else {}


func _get_all_save_info() -> Array[Dictionary]:
	return _host.save_system.get_all_save_info() if _host.save_system != null else []
