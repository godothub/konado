extends Resource
class_name KonadoAudioEvent

## 音频事件：编剧只写事件 ID，事件本身决定播放哪些流、走哪条总线、如何随机与抢占。
## 对标 Wwise Event / FMOD Event Instance 的定义部分（不含运行期实例）。

const CONTAINER_SINGLE := "single"
const CONTAINER_RANDOM := "random"
const CONTAINER_SEQUENCE := "sequence"
const BUS_MUSIC := &"Music"
const BUS_SFX := &"SFX"
const BUS_VOICE := &"Voice"
const BUS_AMBIENCE := &"Ambience"
const BUS_UI := &"UI"
const STEAL_OLDEST := "oldest"
const STEAL_LOWEST_PRIORITY := "lowest_priority"
const STEAL_REJECT := "reject"
const RESTORE_SEEK := "seek"
const RESTORE_RESTART := "restart"
const RESTORE_SILENT := "silent"

## 剧本中引用的事件 ID，例如 `play bgm chapter_01`。
@export var id: StringName = &""
## 目标总线；Music/Ambience 走交叉淡入，SFX 走并发池，Voice 走语音通道。
@export var bus: StringName = &"SFX"
## 一条或多条音频流；多条时按 container 规则选择。
@export var streams: Array[AudioStream] = []
@export_enum("single", "random", "sequence") var container := CONTAINER_SINGLE
@export var loop := false
@export var volume_db := 0.0
@export var volume_random_db := 0.0
@export var pitch_scale := 1.0
@export var pitch_random := 0.0
@export var fade_in := 0.0
@export var fade_out := 0.0
## 同一事件的冷却时间（秒），冷却期内再次触发会被忽略。
@export var cooldown := 0.0
## 同一事件的最大并发实例数（Music/Ambience 固定为 1）。
@export var max_instances := 1
## 并发不足时用于抢占比较的优先级，数值越大越重要。
@export var priority := 0
@export_enum("oldest", "lowest_priority", "reject") var steal_policy := STEAL_OLDEST
## 回退/读档时的恢复策略：seek 只对齐播放位置，restart 重头播放，silent 不恢复。
@export_enum("seek", "restart", "silent") var restore_policy := RESTORE_SEEK
## 变量驱动的增益/条件（RTPC）。
@export var parameters: Array[KonadoAudioParameter] = []

var _sequence_cursor := 0


func is_valid() -> bool:
	return not String(id).is_empty() and not streams.is_empty()


func stream_count() -> int:
	return streams.size()


## 第一条有效音频流，用于状态捕获与编辑器展示。
func primary_stream() -> AudioStream:
	for stream: AudioStream in streams:
		if stream != null:
			return stream
	return null


func primary_stream_path() -> String:
	var stream := primary_stream()
	return stream.resource_path if stream != null else ""


## 按 container 规则挑一条流。random 需要外部提供 RNG 以保证可复现。
func pick_stream(rng: RandomNumberGenerator = null) -> AudioStream:
	var available: Array[AudioStream] = []
	for stream: AudioStream in streams:
		if stream != null:
			available.append(stream)
	if available.is_empty():
		return null
	match container:
		CONTAINER_RANDOM:
			var generator := rng if rng != null else RandomNumberGenerator.new()
			return available[generator.randi_range(0, available.size() - 1)]
		CONTAINER_SEQUENCE:
			var stream := available[_sequence_cursor % available.size()]
			_sequence_cursor += 1
			return stream
		_:
			return available[0]


## 汇总所有参数的结果：任一条被 gate 掉就不播放，增益相乘。
func resolve_gain(values: Dictionary) -> Dictionary:
	var gain := 1.0
	for parameter: KonadoAudioParameter in parameters:
		if parameter == null or not parameter.is_valid():
			continue
		var result := parameter.evaluate(values)
		if bool(result.get("gated", false)):
			return {"gated": true, "gain": 0.0}
		gain *= float(result.get("gain", 1.0))
	return {"gated": false, "gain": gain}


func is_music() -> bool:
	return bus == BUS_MUSIC or bus == BUS_AMBIENCE
