extends Node
class_name KND_AudioInterface

## 音频接口类

## Bgm播放成功
signal finish_playbgm
## 语音播放成功
signal finish_playvoice
## 音效播放成功
signal finish_playsoundeffect

## 语音播放完成
signal voice_finish_playing

## BGM播放器
@export var bgm_player: AudioStreamPlayer
## 对话播放器
@export var voice_player: AudioStreamPlayer
## 音效播放器
@export var sound_effect_player: AudioStreamPlayer

## 设置桥接器引用
@export var _settings_bridge: KND_SettingsBridge

## 缓存的音量值
var _master_volume: float = 1.0
var _music_volume: float = 0.8
var _sfx_volume: float = 1.0
var _voice_volume: float = 1.0


## 从设置更新音量
func _update_volume_from_settings() -> void:
	if _settings_bridge == null:
		return
	
	_master_volume = _settings_bridge.get_master_volume()
	_music_volume = _settings_bridge.get_music_volume()
	_sfx_volume = _settings_bridge.get_sfx_volume()
	_voice_volume = _settings_bridge.get_voice_volume()
	
	# 应用音量
	if bgm_player:
		bgm_player.volume_db = linear_to_db(_master_volume * _music_volume)
	if voice_player:
		voice_player.volume_db = linear_to_db(_master_volume * _voice_volume)
	if sound_effect_player:
		sound_effect_player.volume_db = linear_to_db(_master_volume * _sfx_volume)

## 设置变更处理
func _on_setting_changed(category: String, key: String, value: Variant) -> void:
	if category == "audio":
		_update_volume_from_settings()

## 将线性音量转换为分贝
func linear_to_db(linear: float) -> float:
	if linear <= 0.0:
		return -80.0
	return 20.0 * log(linear) / log(10.0)


## 播放BGM的方法（循环播放）
func play_bgm(audio: AudioStream, audio_id: String) -> void:
	if not bgm_player:
		push_error("没找到bgm_player")
		finish_playbgm.emit()
		return
	if bgm_player.is_playing():
		bgm_player.stop()
	bgm_player.stream = audio
	bgm_player.play()
	finish_playbgm.emit()
	bgm_player.finished.connect(func():
		bgm_player.play())
		
	
## 停止播放BGM的方法
func stop_bgm() -> void:
	if not bgm_player:
		push_error("没找到bgm_player")
		return
	if bgm_player.is_playing():
		bgm_player.stop()


## 播放语音的方法
func play_voice(audio: AudioStream) -> void:
	if not voice_player:
		push_error("没找到voice_player")
		finish_playvoice.emit()
		return
	if voice_player.is_playing():
		voice_player.stop()
	voice_player.stream=audio
	voice_player.play()
	finish_playvoice.emit()
	await voice_player.finished
	voice_finish_playing.emit()

## 停止播放语音的方法
func stop_voice() -> void:
	if not voice_player:
		push_error("没找到voice_player")
		return
	voice_player.stop()

## 播放音效的方法
func play_sound_effect(audio: AudioStream) -> void:
	if not sound_effect_player:
		push_error("没找到sound_effect_player")
		finish_playsoundeffect.emit()
		return
	sound_effect_player.stop()
	sound_effect_player.stream = audio
	sound_effect_player.play()
	finish_playsoundeffect.emit()
