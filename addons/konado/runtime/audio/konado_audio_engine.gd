extends Node
class_name KonadoAudioEngine

## Konado 音频内核：总线混音、事件播放、音乐交叉淡入、音效并发池、duck 与状态捕获。
## 不依赖 KonadoDialogueManager，因此编辑器试听面板与运行时共用同一条播放路径。

signal event_started(event_id: StringName)
signal music_changed(event_id: StringName)

const BUS_MIXER := preload("res://addons/konado/runtime/audio/konado_audio_bus_mixer.gd")
const DEFAULT_SFX_POOL_SIZE := 12
const MAX_SFX_POOL_SIZE := 32
const DEFAULT_CROSSFADE := 0.35
const SILENT_DB := -80.0

var mixer := BUS_MIXER.new()
var library: KonadoAudioEventLibrary
var sfx_pool_size := DEFAULT_SFX_POOL_SIZE

var music_player_a: AudioStreamPlayer
var music_player_b: AudioStreamPlayer
var ambience_player: AudioStreamPlayer
var voice_player: AudioStreamPlayer
var sfx_pool: Array[AudioStreamPlayer] = []

var _music_players: Array[AudioStreamPlayer] = []
var _music_active: Dictionary = {}
var _ambience_active: Dictionary = {}
var _music_fades: Dictionary = {}
var _sfx_instances: Array[Dictionary] = []
var _cooldowns: Dictionary = {}
var _parameters: Dictionary = {}
var _last_sfx_state: Dictionary = {}
var _loop_cache: Dictionary = {}
var _stream_cache: Dictionary = {}
var _rng := RandomNumberGenerator.new()
var _serial := 0


func _ready() -> void:
	_ensure_players()
	set_process(true)


func _process(delta: float) -> void:
	mixer.tick(delta)
	_tick_music_fades(delta)
	_tick_cooldowns(delta)
	_reap_finished_sfx()


## 接管场景里已有的播放器（避免同一声音被播两遍），并按需补齐音效池。
## options: music_player / voice_player / sfx_player / sfx_pool_size / seed
func configure(options: Dictionary = {}) -> void:
	var music: Variant = options.get("music_player")
	if music is AudioStreamPlayer:
		music_player_a = music
	var voice: Variant = options.get("voice_player")
	if voice is AudioStreamPlayer:
		voice_player = voice
	var sfx: Variant = options.get("sfx_player")
	if sfx is AudioStreamPlayer:
		var first: Array[AudioStreamPlayer] = [sfx]
		sfx_pool = first
	sfx_pool_size = clampi(int(options.get("sfx_pool_size", sfx_pool_size)), 1, MAX_SFX_POOL_SIZE)
	if options.has("seed"):
		_rng.seed = int(options["seed"])
	else:
		_rng.randomize()
	_ensure_players()


func set_library(new_library: KonadoAudioEventLibrary) -> void:
	library = new_library
	if library != null:
		library.rebuild()


## 写入分类音量（线性 0~1）。master 会与各分类相乘后写入对应总线。
func set_volumes(master: float, music: float, sfx: float, voice: float) -> void:
	mixer.set_channel_volume(KonadoAudioBusMixer.BUS_MASTER, master)
	mixer.set_channel_volume(KonadoAudioBusMixer.BUS_MUSIC, master * music)
	mixer.set_channel_volume(KonadoAudioBusMixer.BUS_AMBIENCE, master * music)
	mixer.set_channel_volume(KonadoAudioBusMixer.BUS_SFX, master * sfx)
	mixer.set_channel_volume(KonadoAudioBusMixer.BUS_UI, master * sfx)
	mixer.set_channel_volume(KonadoAudioBusMixer.BUS_VOICE, master * voice)


## 传入当前脚本变量快照（例如 {"%love": 3}），RTPC 会立即重新计算音乐增益。
func set_variable_values(values: Dictionary) -> void:
	_parameters = values.duplicate(true)
	for bucket: Dictionary in [_music_active, _ambience_active]:
		var player: Variant = bucket.get("player")
		if player is AudioStreamPlayer and is_instance_valid(player):
			_retarget_player_db(player, _bucket_target_db(bucket))


func parameter_values() -> Dictionary:
	return _parameters.duplicate(true)


func has_event(event_id: StringName) -> bool:
	return library != null and library.has_event(event_id)


func play_event(event_id: StringName, options: Dictionary = {}) -> Dictionary:
	if library == null:
		return _failure(&"audio.library_missing", "音频事件库未配置")
	var event := library.lookup(event_id)
	if event == null:
		return _failure(&"audio.event_not_found", "未找到音频事件 '%s'" % event_id)
	return play_event_object(event, options)


func play_event_object(event: KonadoAudioEvent, options: Dictionary = {}) -> Dictionary:
	if event == null or not event.is_valid():
		return _failure(&"audio.event_invalid", "音频事件缺少 ID 或音频流")
	if float(_cooldowns.get(event.id, 0.0)) > 0.0:
		return _ignored(&"audio.cooldown", "音频事件 '%s' 处于冷却中" % event.id)
	var gain_result := event.resolve_gain(_parameters)
	if bool(gain_result.get("gated", false)):
		return _ignored(&"audio.gated", "音频事件 '%s' 的播放条件不成立" % event.id)
	var stream := event.pick_stream(_rng)
	if stream == null:
		return _failure(&"audio.event_stream_missing", "音频事件 '%s' 没有可播放的音频流" % event.id)
	var volume_offset := float(options.get("volume_db", 0.0))
	var fade := float(options.get("fade", -1.0))
	var event_db := event.volume_db + volume_offset + _random_between(0.0, event.volume_random_db)
	var gain_db := KonadoAudioBusMixer.linear_to_db(
		maxf(0.0001, float(gain_result.get("gain", 1.0)))
	)
	var pitch := event.pitch_scale * maxf(0.01, 1.0 + _random_between(0.0, event.pitch_random))
	if event.is_music():
		_start_music(event, stream, event_db, pitch, fade)
	elif event.bus == KonadoAudioEvent.BUS_VOICE:
		_start_voice(event, stream, event_db + gain_db, pitch)
	else:
		var repeat := clampi(int(options.get("count", 1)), 1, 8)
		for _index in range(repeat):
			var started := _start_sfx(event, stream, event_db + gain_db, pitch)
			if not bool(started.get("ok", false)) and repeat == 1:
				return started
	_cooldowns[event.id] = maxf(0.0, event.cooldown)
	event_started.emit(event.id)
	return {
		"ok": true,
		"event_id": event.id,
		"bus": event.bus,
		"stream_path": _cache_stream(stream),
		"duration": stream.get_length(),
	}


## 直接播放一条流（旧版资源列表、编辑器试听与外部调用使用）。
func play_stream(stream: AudioStream, bus: StringName, options: Dictionary = {}) -> Dictionary:
	if stream == null:
		return _failure(&"audio.stream_missing", "音频流为空")
	var target_db := float(options.get("volume_db", 0.0))
	var pitch := float(options.get("pitch_scale", 1.0))
	var fade := float(options.get("fade", -1.0))
	if bus == KonadoAudioEvent.BUS_MUSIC or bus == KonadoAudioEvent.BUS_AMBIENCE:
		var music_event := KonadoAudioEvent.new()
		music_event.id = &"__stream__"
		music_event.bus = bus
		music_event.loop = bool(options.get("loop", true))
		music_event.streams.append(stream)
		_start_music(music_event, stream, target_db, pitch, fade)
	elif bus == KonadoAudioEvent.BUS_VOICE:
		var voice_event := KonadoAudioEvent.new()
		voice_event.id = &"__voice__"
		voice_event.bus = bus
		voice_event.streams.append(stream)
		_start_voice(voice_event, stream, target_db, pitch)
	else:
		var sfx_event := KonadoAudioEvent.new()
		sfx_event.id = &"__sfx__"
		sfx_event.bus = bus
		sfx_event.loop = bool(options.get("loop", false))
		sfx_event.streams.append(stream)
		var started := _start_sfx(sfx_event, stream, target_db, pitch)
		if not bool(started.get("ok", false)):
			return started
	return {
		"ok": true,
		"bus": bus,
		"stream_path": _cache_stream(stream),
		"duration": stream.get_length()
	}


## 按总线停止播放：Music/Ambience 交叉淡出，SFX/UI 立即停止，Voice 由控制器处理。
func stop_bus(bus: StringName, fade := -1.0) -> void:
	var duration := DEFAULT_CROSSFADE if fade < 0.0 else maxf(0.0, fade)
	if bus == KonadoAudioEvent.BUS_MUSIC or bus == KonadoAudioEvent.BUS_AMBIENCE:
		var bucket := _bucket_for(bus)
		if bucket.is_empty():
			return
		var active_player: Variant = bucket.get("player")
		if active_player is AudioStreamPlayer and is_instance_valid(active_player):
			_fade_out_and_stop(active_player, duration)
		bucket.clear()
		return
	for instance: Dictionary in _sfx_instances.duplicate():
		if StringName(instance.get("bus", KonadoAudioEvent.BUS_SFX)) == bus:
			_stop_instance(instance)


func stop_music(fade := -1.0) -> void:
	stop_bus(KonadoAudioEvent.BUS_MUSIC, fade)


func duck_bus(
	bus: StringName, amount_db: float, attack := 0.1, hold := 0.0, release := 0.3
) -> void:
	mixer.duck_bus(bus, amount_db, attack, hold, release)


func unduck_bus(bus: StringName) -> void:
	mixer.clear_duck(bus)


func active_music() -> Dictionary:
	return _music_active.duplicate(true)


func active_instances() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for instance: Dictionary in _sfx_instances:
		result.append(instance.duplicate(true))
	return result


## 预加载音频资源（Bank 加载与编辑器试听共用）。返回实际加载成功的路径数。
func preload_paths(paths: PackedStringArray) -> int:
	var loaded := 0
	for path: String in paths:
		if path.is_empty() or _stream_cache.has(path):
			continue
		if not ResourceLoader.exists(path, "AudioStream"):
			continue
		var stream := load(path) as AudioStream
		if stream != null:
			_stream_cache[path] = stream
			loaded += 1
	return loaded


## 捕获可序列化的音频状态：音乐记录事件 ID + 播放游标，混音记录总线音量。
## 用户音量保存在总线而不在播放器里，因此读档不会覆盖玩家设置。
func capture_state() -> Dictionary:
	return {
		"bgm": _capture_bucket(_music_active),
		"ambience": _capture_bucket(_ambience_active),
		"sound_effect": _last_sfx_state.duplicate(true),
		"mix": mixer.capture_state(),
		"parameters": _parameters.duplicate(true),
	}


func _capture_bucket(bucket: Dictionary) -> Dictionary:
	if bucket.is_empty():
		return {}
	var state := _capture_player_state(
		bucket.get("player"),
		bool(bucket.get("loop", true)),
		String(bucket.get("event_id", "")),
		_bucket_target_db(bucket),
		true
	)
	if not state.is_empty():
		state["event_db"] = float(bucket.get("volume_db", 0.0))
	return state


func _bucket_for(bus: StringName) -> Dictionary:
	return _ambience_active if bus == KonadoAudioEvent.BUS_AMBIENCE else _music_active


func _bucket_target_db(bucket: Dictionary) -> float:
	var event: KonadoAudioEvent = (
		library.lookup(StringName(bucket.get("event_id", &""))) if library != null else null
	)
	return _music_target_db(float(bucket.get("volume_db", 0.0)), event)


## 恢复音频状态。一次性音效不会被重放；音乐按事件的 restore_policy 处理。
func restore_state(state: Dictionary) -> bool:
	if state.is_empty():
		return true
	if state.get("mix", {}) is Dictionary:
		mixer.restore_state(state["mix"])
	if state.get("parameters", {}) is Dictionary:
		_parameters = (state["parameters"] as Dictionary).duplicate(true)
	for instance: Dictionary in _sfx_instances.duplicate():
		_stop_instance(instance)
	_last_sfx_state = (
		(state["sound_effect"] as Dictionary).duplicate(true)
		if state.get("sound_effect", {}) is Dictionary
		else {}
	)
	var valid := _restore_music_state(state.get("bgm", {}), KonadoAudioEvent.BUS_MUSIC)
	valid = _restore_music_state(state.get("ambience", {}), KonadoAudioEvent.BUS_AMBIENCE) and valid
	return valid


func _restore_music_state(entry: Variant, bus: StringName) -> bool:
	if not entry is Dictionary or (entry as Dictionary).is_empty():
		stop_bus(bus, 0.0)
		return true
	var data: Dictionary = entry
	var event_id := StringName(data.get("event_id", &""))
	var event: KonadoAudioEvent = library.lookup(event_id) if library != null else null
	var stream: AudioStream = (
		event.pick_stream(_rng)
		if event != null
		else _load_stream(String(data.get("stream_path", "")))
	)
	if stream == null:
		stop_bus(bus, 0.0)
		return false
	if event != null and event.restore_policy == KonadoAudioEvent.RESTORE_SILENT:
		stop_bus(bus, 0.0)
		return true
	var playback_event := event
	if playback_event == null:
		playback_event = KonadoAudioEvent.new()
		playback_event.id = event_id if not String(event_id).is_empty() else &"__restored__"
		playback_event.bus = bus
		playback_event.loop = bool(data.get("loop", true))
		playback_event.streams.append(stream)
	_start_music(
		playback_event,
		stream,
		float(data.get("event_db", data.get("volume_db", 0.0))),
		float(data.get("pitch_scale", 1.0)),
		0.0
	)
	var bucket := _bucket_for(bus)
	var active: Variant = bucket.get("player")
	var seek := 0.0
	if event == null or event.restore_policy != KonadoAudioEvent.RESTORE_RESTART:
		seek = maxf(0.0, float(data.get("position", 0.0)))
	if active is AudioStreamPlayer and seek > 0.0:
		(active as AudioStreamPlayer).seek(seek)
	return true


func _start_music(
	event: KonadoAudioEvent, stream: AudioStream, event_db: float, pitch: float, fade: float
) -> void:
	var duration := DEFAULT_CROSSFADE if fade < 0.0 else maxf(0.0, fade)
	var bucket := _bucket_for(event.bus)
	var target_db := _music_target_db(event_db, event)
	var active_player: Variant = bucket.get("player")
	var active_id := StringName(bucket.get("event_id", &""))
	if (
		active_player is AudioStreamPlayer
		and is_instance_valid(active_player)
		and active_id == event.id
		and not bucket.is_empty()
	):
		bucket["volume_db"] = event_db
		bucket["pitch_scale"] = pitch
		_retarget_player_db(active_player, target_db, duration)
		return
	var incoming := ambience_player
	if event.bus == KonadoAudioEvent.BUS_MUSIC:
		incoming = music_player_b if active_player == music_player_a else music_player_a
	if incoming == null:
		return
	if (
		active_player is AudioStreamPlayer
		and is_instance_valid(active_player)
		and active_player != incoming
	):
		_fade_out_and_stop(active_player, duration)
	elif incoming == active_player:
		_fade_out_and_stop(incoming, duration)
	incoming.stop()
	incoming.stream = _with_loop(stream, event.loop)
	incoming.bus = event.bus
	incoming.pitch_scale = pitch
	incoming.volume_db = SILENT_DB if duration > 0.0 else target_db
	incoming.play()
	bucket.clear()
	(
		bucket
		. merge(
			{
				"event_id": event.id,
				"bus": event.bus,
				"player": incoming,
				"volume_db": event_db,
				"pitch_scale": pitch,
				"loop": event.loop,
				"stream_path": _cache_stream(stream),
			}
		)
	)
	if duration > 0.0:
		_retarget_player_db(incoming, target_db, duration)
	music_changed.emit(event.id)


func _start_sfx(
	event: KonadoAudioEvent, stream: AudioStream, target_db: float, pitch: float
) -> Dictionary:
	var instances := _instances_for(event.id)
	if instances.size() >= maxi(1, event.max_instances):
		if event.steal_policy == KonadoAudioEvent.STEAL_REJECT:
			return _ignored(&"audio.instance_limit", "音频事件 '%s' 已达到并发上限" % event.id)
		var victim: Dictionary = instances[0]
		if event.steal_policy == KonadoAudioEvent.STEAL_LOWEST_PRIORITY:
			for candidate: Dictionary in instances:
				if int(candidate.get("priority", 0)) < int(victim.get("priority", 0)):
					victim = candidate
			if event.priority <= int(victim.get("priority", 0)):
				return _ignored(&"audio.instance_limit", "音频事件 '%s' 优先级不足" % event.id)
		_stop_instance(victim)
	var slot := _free_sfx_slot()
	if slot == null:
		return _failure(&"audio.pool_exhausted", "音效池已满")
	slot.stream = _with_loop(stream, event.loop)
	slot.volume_db = target_db
	slot.pitch_scale = pitch
	slot.bus = (
		KonadoAudioEvent.BUS_UI
		if event.bus == KonadoAudioEvent.BUS_UI
		else KonadoAudioEvent.BUS_SFX
	)
	slot.play()
	_serial += 1
	var instance := {
		"event_id": event.id,
		"player": slot,
		"bus": slot.bus,
		"priority": event.priority,
		"serial": _serial,
		"loop": event.loop,
		"started_at": Time.get_ticks_msec() / 1000.0,
		"duration": slot.stream.get_length() if slot.stream != null else 0.0,
		"stream_path": _cache_stream(stream),
	}
	_sfx_instances.append(instance)
	_last_sfx_state = _capture_player_state(slot, event.loop, String(event.id), target_db, true)
	return {"ok": true}


## 引擎级语音通道；对话流程的等待/打断仍由 KonadoAudioController 管理。
func _start_voice(
	_event: KonadoAudioEvent, stream: AudioStream, target_db: float, pitch: float
) -> void:
	if voice_player == null:
		return
	voice_player.stop()
	voice_player.stream = stream
	voice_player.bus = KonadoAudioEvent.BUS_VOICE
	voice_player.volume_db = target_db
	voice_player.pitch_scale = pitch
	voice_player.play()


func _current_music_target_db() -> float:
	return _bucket_target_db(_music_active)


func _music_target_db(event_db: float, event: KonadoAudioEvent) -> float:
	if event == null:
		return event_db
	var gain := event.resolve_gain(_parameters)
	if bool(gain.get("gated", false)):
		return SILENT_DB
	return event_db + KonadoAudioBusMixer.linear_to_db(maxf(0.0001, float(gain.get("gain", 1.0))))


func _retarget_player_db(player: AudioStreamPlayer, target_db: float, duration := 0.0) -> void:
	if player == null or not is_instance_valid(player):
		return
	if duration <= 0.0:
		player.volume_db = target_db
		_music_fades.erase(player)
		return
	_music_fades[player] = {
		"from": player.volume_db,
		"to": target_db,
		"duration": duration,
		"elapsed": 0.0,
		"stop": false,
	}


func _fade_out_and_stop(player: AudioStreamPlayer, duration: float) -> void:
	if player == null or not is_instance_valid(player):
		return
	if duration <= 0.0 or not player.playing:
		player.stop()
		_music_fades.erase(player)
		return
	_music_fades[player] = {
		"from": player.volume_db,
		"to": SILENT_DB,
		"duration": duration,
		"elapsed": 0.0,
		"stop": true,
	}


func _tick_music_fades(delta: float) -> void:
	for player: AudioStreamPlayer in _music_fades.keys().duplicate():
		if not is_instance_valid(player):
			_music_fades.erase(player)
			continue
		var fade: Dictionary = _music_fades[player]
		fade["elapsed"] = float(fade.get("elapsed", 0.0)) + delta
		var progress := clampf(
			float(fade["elapsed"]) / maxf(0.001, float(fade.get("duration", 0.0))), 0.0, 1.0
		)
		player.volume_db = lerpf(float(fade.get("from", 0.0)), float(fade.get("to", 0.0)), progress)
		if progress < 1.0:
			continue
		if bool(fade.get("stop", false)):
			player.stop()
			player.stream = null
		_music_fades.erase(player)


func _tick_cooldowns(delta: float) -> void:
	for event_id: StringName in _cooldowns.keys().duplicate():
		var remaining := float(_cooldowns[event_id]) - delta
		if remaining <= 0.0:
			_cooldowns.erase(event_id)
		else:
			_cooldowns[event_id] = remaining


func _reap_finished_sfx() -> void:
	# 以时长而不是 player.playing 判断结束：无音频驱动（headless）时也能保持逻辑一致。
	var now := Time.get_ticks_msec() / 1000.0
	for instance: Dictionary in _sfx_instances.duplicate():
		var player: AudioStreamPlayer = instance.get("player")
		if player == null or not is_instance_valid(player):
			_sfx_instances.erase(instance)
			continue
		if bool(instance.get("loop", false)):
			continue
		var lifetime := (
			float(instance.get("started_at", now)) + float(instance.get("duration", 0.0))
		)
		if now >= lifetime:
			_sfx_instances.erase(instance)


func _stop_instance(instance: Dictionary) -> void:
	var player: AudioStreamPlayer = instance.get("player")
	if player != null and is_instance_valid(player):
		player.stop()
	_sfx_instances.erase(instance)


func _slot_in_use(player: AudioStreamPlayer) -> bool:
	for instance: Dictionary in _sfx_instances:
		if instance.get("player") == player:
			return true
	return false


func _instances_for(event_id: StringName) -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	for instance: Dictionary in _sfx_instances:
		if StringName(instance.get("event_id", &"")) == event_id:
			found.append(instance)
	return found


func _free_sfx_slot() -> AudioStreamPlayer:
	for player: AudioStreamPlayer in sfx_pool:
		if not is_instance_valid(player):
			continue
		if not _slot_in_use(player):
			return player
	if _sfx_instances.is_empty():
		return null
	var oldest: Dictionary = _sfx_instances[0]
	for instance: Dictionary in _sfx_instances:
		if int(instance.get("serial", 0)) < int(oldest.get("serial", 0)):
			oldest = instance
	var player: AudioStreamPlayer = oldest.get("player")
	_stop_instance(oldest)
	return player if player != null and is_instance_valid(player) else null


func _ensure_players() -> void:
	if not is_instance_valid(music_player_a):
		music_player_a = _create_player(KonadoAudioEvent.BUS_MUSIC, &"KonadoMusicA")
	if not is_instance_valid(music_player_b):
		music_player_b = _create_player(KonadoAudioEvent.BUS_MUSIC, &"KonadoMusicB")
	if not is_instance_valid(ambience_player):
		ambience_player = _create_player(KonadoAudioEvent.BUS_AMBIENCE, &"KonadoAmbience")
	if not is_instance_valid(voice_player):
		voice_player = _create_player(KonadoAudioEvent.BUS_VOICE, &"KonadoVoice")
	_music_players = [music_player_a, music_player_b]
	while sfx_pool.size() < sfx_pool_size:
		sfx_pool.append(_create_player(KonadoAudioEvent.BUS_SFX, &"KonadoSfx%d" % sfx_pool.size()))
	for player: AudioStreamPlayer in _music_players + sfx_pool + [ambience_player, voice_player]:
		if player == null:
			continue
		player.process_mode = Node.PROCESS_MODE_ALWAYS


func _create_player(bus: StringName, node_name: StringName) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.name = node_name
	player.bus = bus
	add_child(player)
	return player


func _with_loop(stream: AudioStream, loop: bool) -> AudioStream:
	if not loop:
		return stream
	var key := stream.get_instance_id()
	if _loop_cache.has(key):
		return _loop_cache[key]
	var copy := stream.duplicate() as AudioStream
	if copy is AudioStreamOggVorbis:
		(copy as AudioStreamOggVorbis).loop = true
	elif copy is AudioStreamMP3:
		(copy as AudioStreamMP3).loop = true
	elif copy is AudioStreamWAV:
		(copy as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD
	_loop_cache[key] = copy
	return copy


func _cache_stream(stream: AudioStream) -> String:
	if stream == null:
		return ""
	var path := stream.resource_path
	if not path.is_empty():
		_stream_cache[path] = stream
	return path


func _load_stream(path: String) -> AudioStream:
	if path.is_empty():
		return null
	var cached: Variant = _stream_cache.get(path)
	if cached is AudioStream:
		return cached
	if not ResourceLoader.exists(path, "AudioStream"):
		return null
	var stream := load(path) as AudioStream
	if stream != null:
		_stream_cache[path] = stream
	return stream


func _capture_player_state(
	player: Variant, loop: bool, event_id: String, volume_db := NAN, playing := true
) -> Dictionary:
	if not player is AudioStreamPlayer or not is_instance_valid(player):
		return {}
	var audio_player: AudioStreamPlayer = player
	if audio_player.stream == null:
		return {}
	return {
		"event_id": event_id,
		"stream_path": audio_player.stream.resource_path,
		"playing": playing,
		"position": audio_player.get_playback_position() if audio_player.playing else 0.0,
		"volume_db": audio_player.volume_db if is_nan(volume_db) else volume_db,
		"pitch_scale": audio_player.pitch_scale,
		"loop": loop,
	}


func _failure(code: StringName, message: String) -> Dictionary:
	return {"ok": false, "code": code, "message": message}


func _ignored(code: StringName, message: String) -> Dictionary:
	return {"ok": false, "code": code, "message": message, "ignored": true}


func _random_between(minimum: float, maximum: float) -> float:
	if is_zero_approx(maximum):
		return 0.0
	var low := minf(minimum, maximum)
	var high := maxf(minimum, maximum)
	return _rng.randf_range(low, high)
