extends Node
class_name KonadoAudioController

## 音频接口类：把对话运行时的音频请求转成 KonadoAudioEngine 的事件调用。
## 语音的等待/打断仍在控制器里完成（剧本需要 await 语音结束），
## 音乐、音效、总线混音、duck 与状态捕获全部交给内核。

## Bgm播放成功
signal background_music_started
## 语音播放成功
signal voice_started
## 音效播放成功
signal sound_effect_started
## 语音播放完成
signal voice_finished

const SETTINGS_ADAPTER_SCRIPT := preload(
	"res://addons/konado/runtime/integrations/konado_settings_adapter.gd"
)
const AUDIO_ENGINE_SCRIPT := preload("res://addons/konado/runtime/audio/konado_audio_engine.gd")
const BUS_MIXER := preload("res://addons/konado/runtime/audio/konado_audio_bus_mixer.gd")
const DEFAULT_DUCK_DB := -6.0
const DEFAULT_DUCK_ATTACK := 0.08
const DEFAULT_DUCK_RELEASE := 0.25


class VoicePlaybackWaiter:
	extends RefCounted

	signal settled(completed: bool)

	var result: Variant = null

	func settle(completed: bool) -> void:
		if result != null:
			return
		result = completed
		settled.emit(completed)


## BGM播放器（会被内核接管为音乐通道 A）
@export var background_music_player: AudioStreamPlayer
## 对话播放器
@export var voice_player: AudioStreamPlayer
## 音效播放器（会被内核接管为音效池第一个槽位）
@export var sound_effect_player: AudioStreamPlayer

## 设置桥接器引用
@export var settings_adapter: SETTINGS_ADAPTER_SCRIPT
## 音频事件库；为空时仍可播放旧版资源列表传入的音频流
@export var audio_event_library: KonadoAudioEventLibrary
## 音效并发池大小
@export_range(1, 32) var sfx_pool_size := 12
## 语音播放时自动压低音乐（对标 Wwise Auto-Ducking）
@export var duck_music_for_voice := true
@export var voice_duck_db := DEFAULT_DUCK_DB

## 音频内核；编辑器试听面板可以独立创建同一个类
var engine: KonadoAudioEngine

var _master_volume: float = 1.0
var _music_volume: float = 0.8
var _sound_effect_volume: float = 1.0
var _voice_volume: float = 1.0
var _voice_playing: bool = false
var _voice_generation: int = 0
var _voice_priority: int = 0
var _voice_waiters: Dictionary[int, VoicePlaybackWaiter] = {}
var _voice_connected := false


func _ready() -> void:
	configure()


func _exit_tree() -> void:
	_cancel_voice_playback()
	var pending_generations: Array[int] = []
	pending_generations.assign(_voice_waiters.keys())
	for generation: int in pending_generations:
		_settle_voice_playback(generation, false)
	if is_instance_valid(voice_player) and _voice_connected:
		voice_player.finished.disconnect(_on_voice_player_finished)
	_voice_connected = false


## 创建/更新音频内核。可以重复调用：音量、事件库与播放器都会被重新绑定。
func configure(library: KonadoAudioEventLibrary = null) -> void:
	if not is_instance_valid(engine):
		engine = AUDIO_ENGINE_SCRIPT.new()
		engine.name = "KonadoAudioEngine"
		add_child(engine)
	(
		engine
		. configure(
			{
				"music_player": background_music_player,
				"voice_player": voice_player,
				"sfx_player": sound_effect_player,
				"sfx_pool_size": sfx_pool_size,
			}
		)
	)
	engine.set_library(library if library != null else audio_event_library)
	_ensure_voice_connection()
	refresh_volume()


## 从设置刷新分类音量。音量写在总线上，读档不会覆盖玩家设置。
func refresh_volume() -> void:
	if settings_adapter != null:
		_master_volume = settings_adapter.get_master_volume()
		_music_volume = settings_adapter.get_music_volume()
		_sound_effect_volume = settings_adapter.get_sfx_volume()
		_voice_volume = settings_adapter.get_voice_volume()
	if is_instance_valid(engine):
		engine.set_volumes(_master_volume, _music_volume, _sound_effect_volume, _voice_volume)


## 把当前脚本变量推给内核，驱动事件上的 RTPC 增益与条件。
func set_variable_values(values: Dictionary) -> void:
	if is_instance_valid(engine):
		engine.set_variable_values(values)


func duck_bus(
	bus: StringName, amount_db: float, attack := 0.1, hold := 0.0, release := 0.3
) -> void:
	if is_instance_valid(engine):
		engine.duck_bus(bus, amount_db, attack, hold, release)


func unduck_bus(bus: StringName) -> void:
	if is_instance_valid(engine):
		engine.unduck_bus(bus)


func linear_to_db(linear: float) -> float:
	return BUS_MIXER.linear_to_db(linear)


## 播放 BGM（旧版音频流入口，保持 scene 与测试兼容）。
func play_background_music(
	audio: AudioStream, _audio_id: String, fade := -1.0, volume_db := 0.0
) -> void:
	if not is_instance_valid(engine):
		push_error("音频内核尚未初始化")
		return
	var result := engine.play_stream(
		audio, KonadoAudioEvent.BUS_MUSIC, {"loop": true, "fade": fade, "volume_db": volume_db}
	)
	if not bool(result.get("ok", false)):
		push_error(String(result.get("message", "BGM 播放失败")))
	background_music_started.emit()


## 按事件播放 BGM；fade < 0 使用事件自带的淡入时间。
func play_background_music_event(
	event_id: StringName, fade := -1.0, volume_db := 0.0
) -> Dictionary:
	if not is_instance_valid(engine):
		return {"ok": false, "code": &"audio.engine_missing", "message": "音频内核未初始化"}
	var result := engine.play_event(event_id, {"fade": fade, "volume_db": volume_db})
	if bool(result.get("ok", false)):
		background_music_started.emit()
	return result


func stop_background_music(fade := -1.0) -> void:
	if is_instance_valid(engine):
		engine.stop_music(fade)


func is_voice_playing() -> bool:
	return _voice_playing


## 非阻塞地开始播放语音。自然播放完成时发出 voice_finished。
func play_voice(audio: AudioStream, priority := 0) -> void:
	_begin_voice_playback(audio, false, priority)


## 按事件播放语音（事件可以携带优先级、音量与 RTPC 增益）。
func play_voice_event(event_id: StringName, priority := -1) -> Dictionary:
	if not is_instance_valid(engine) or engine.library == null:
		return {"ok": false, "code": &"audio.library_missing", "message": "音频事件库未配置"}
	var event := engine.library.lookup(event_id)
	if event == null:
		return {
			"ok": false,
			"code": &"audio.event_not_found",
			"message": "未找到语音事件 '%s'" % event_id,
		}
	var gain := event.resolve_gain(engine.parameter_values())
	if bool(gain.get("gated", false)):
		return {
			"ok": false,
			"code": &"audio.gated",
			"message": "语音事件 '%s' 的播放条件不成立" % event_id,
			"ignored": true,
		}
	var stream := event.pick_stream()
	if stream == null:
		return {
			"ok": false,
			"code": &"audio.event_stream_missing",
			"message": "语音事件 '%s' 没有音频流" % event_id,
		}
	var effective_priority := event.priority if priority < 0 else priority
	var generation := _begin_voice_playback(stream, false, effective_priority)
	if generation < 0:
		return {
			"ok": false,
			"code": &"audio.voice_lower_priority",
			"message": "已有更高优先级的语音在播放",
			"ignored": true,
		}
	voice_player.volume_db = (
		event.volume_db + BUS_MIXER.linear_to_db(maxf(0.0001, float(gain.get("gain", 1.0))))
	)
	return {
		"ok": true,
		"event_id": event_id,
		"duration": stream.get_length(),
		"stream_path": stream.resource_path,
	}


## 播放并等待当前语音结束。
##
## 自然播放完成返回 true；被 stop_voice() 中断、被更高优先级语音替换或无法开始播放时返回 false。
func play_voice_and_wait(audio: AudioStream, priority := 0) -> bool:
	var generation := _begin_voice_playback(audio, true, priority)
	if generation < 0:
		return false
	var waiter := _voice_waiters.get(generation)
	if waiter == null:
		return false
	if waiter.result != null:
		var immediate_result := bool(waiter.result)
		_voice_waiters.erase(generation)
		return immediate_result
	var result: bool = await waiter.settled
	_voice_waiters.erase(generation)
	return result


## 停止播放语音的方法
func stop_voice() -> void:
	_cancel_voice_playback()


## Cancel transient playback owned by the current VM instruction.
## BGM is committed ambient state and is deliberately left untouched.
func cancel_pending_operations() -> void:
	_cancel_voice_playback()
	if is_instance_valid(engine):
		engine.stop_bus(KonadoAudioEvent.BUS_SFX, 0.0)
	var pending_generations: Array[int] = []
	pending_generations.assign(_voice_waiters.keys())
	for generation: int in pending_generations:
		_settle_voice_playback(generation, false)


## 播放音效（旧版音频流入口）。
func play_sound_effect(audio: AudioStream, volume_db := 0.0) -> void:
	if is_instance_valid(engine):
		engine.play_stream(audio, KonadoAudioEvent.BUS_SFX, {"volume_db": volume_db})
	else:
		push_error("音频内核尚未初始化")
	sound_effect_started.emit()


## 按事件播放音效；options 支持 volume_db 与 count。
func play_sound_effect_event(event_id: StringName, options: Dictionary = {}) -> Dictionary:
	if not is_instance_valid(engine):
		return {"ok": false, "code": &"audio.engine_missing", "message": "音频内核未初始化"}
	var result := engine.play_event(event_id, options)
	if bool(result.get("ok", false)):
		sound_effect_started.emit()
	return result


## 捕获可序列化的音频播放状态。用户音量保存在总线上，不写入存档。
func capture_state() -> Dictionary:
	var state := {}
	if is_instance_valid(engine):
		state = engine.capture_state()
	state["voice"] = _capture_voice_state()
	return state


## 原子地恢复音频播放状态。无法加载的资源会停止对应播放器并返回 false。
func restore_state(state: Dictionary) -> bool:
	_cancel_voice_playback()
	var valid := true
	if is_instance_valid(engine):
		valid = engine.restore_state(state)
	valid = _restore_voice(state.get("voice", {})) and valid
	return valid


func _begin_voice_playback(audio: AudioStream, track_result: bool, priority: int) -> int:
	if _voice_playing and priority < _voice_priority:
		return -1
	var previous_generation := _voice_generation
	var had_previous_playback := _voice_playing
	_voice_generation += 1
	var generation := _voice_generation
	if track_result:
		_voice_waiters[generation] = VoicePlaybackWaiter.new()
	_voice_playing = false
	_voice_priority = priority
	if had_previous_playback:
		_stop_voice_player()
		_settle_voice_playback(previous_generation, false)
		if generation != _voice_generation:
			_settle_voice_playback(generation, false)
			return generation if track_result else -1
	if not is_instance_valid(voice_player) or audio == null:
		_settle_voice_playback(generation, false)
		return generation if track_result else -1
	_ensure_voice_connection()
	voice_player.stop()
	voice_player.stream = audio
	voice_player.bus = KonadoAudioEvent.BUS_VOICE
	_voice_playing = true
	voice_player.play()
	_duck_music()
	voice_started.emit()
	if not is_instance_valid(voice_player) or voice_player.stream == null:
		_voice_playing = false
		_stop_voice_player()
		_release_duck()
		_settle_voice_playback(generation, false)
	return generation


func _cancel_voice_playback() -> void:
	if not _voice_playing:
		if is_instance_valid(voice_player) and voice_player.is_playing():
			voice_player.stop()
		return
	var generation := _voice_generation
	_voice_playing = false
	_voice_priority = 0
	_stop_voice_player()
	_release_duck()
	_settle_voice_playback(generation, false)


func _stop_voice_player() -> void:
	if is_instance_valid(voice_player) and voice_player.is_playing():
		voice_player.stop()


func _duck_music() -> void:
	if not duck_music_for_voice or not is_instance_valid(engine):
		return
	engine.duck_bus(
		KonadoAudioEvent.BUS_MUSIC, voice_duck_db, DEFAULT_DUCK_ATTACK, 0.0, DEFAULT_DUCK_RELEASE
	)


func _release_duck() -> void:
	if is_instance_valid(engine):
		engine.unduck_bus(KonadoAudioEvent.BUS_MUSIC)


func _ensure_voice_connection() -> void:
	if not is_instance_valid(voice_player) or _voice_connected:
		return
	if not voice_player.finished.is_connected(_on_voice_player_finished):
		voice_player.finished.connect(_on_voice_player_finished)
	_voice_connected = true


func _on_voice_player_finished() -> void:
	if not _voice_playing:
		return
	var generation := _voice_generation
	_voice_playing = false
	_voice_priority = 0
	_release_duck()
	voice_finished.emit()
	_settle_voice_playback(generation, true)


func _settle_voice_playback(generation: int, completed: bool) -> void:
	var waiter := _voice_waiters.get(generation)
	if waiter == null:
		return
	waiter.settle(completed)


func _capture_voice_state() -> Dictionary:
	if not is_instance_valid(voice_player) or voice_player.stream == null:
		return {}
	return {
		"stream_path": voice_player.stream.resource_path,
		"playing": _voice_playing,
		"position": voice_player.get_playback_position() if voice_player.playing else 0.0,
		"volume_db": voice_player.volume_db,
		"pitch_scale": voice_player.pitch_scale,
		"loop": false,
	}


func _restore_voice(entry: Variant) -> bool:
	if not is_instance_valid(voice_player):
		return not entry is Dictionary or (entry as Dictionary).is_empty()
	if not entry is Dictionary or (entry as Dictionary).is_empty():
		voice_player.stop()
		voice_player.stream = null
		return true
	var data: Dictionary = entry
	var stream_path := String(data.get("stream_path", ""))
	if stream_path.is_empty() or not ResourceLoader.exists(stream_path, "AudioStream"):
		voice_player.stop()
		voice_player.stream = null
		return false
	var stream := load(stream_path) as AudioStream
	if stream == null:
		voice_player.stop()
		voice_player.stream = null
		return false
	_ensure_voice_connection()
	voice_player.stop()
	voice_player.stream = stream
	voice_player.volume_db = float(data.get("volume_db", 0.0))
	voice_player.pitch_scale = float(data.get("pitch_scale", 1.0))
	_voice_playing = false
	if bool(data.get("playing", false)):
		voice_player.play(maxf(0.0, float(data.get("position", 0.0))))
		_voice_playing = voice_player.stream != null
		if _voice_playing:
			_voice_generation += 1
			_duck_music()
	return true


func _on_setting_changed(category: String, _key: String, _value: Variant) -> void:
	if category == "audio":
		refresh_volume()
