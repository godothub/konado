extends RefCounted
class_name KonadoAudioBusMixer

## Konado 音频总线混音器：负责 bus 生命周期、音量/静音、duck 包络与混音快照。
## 所有音量都以线性值保存（0.0 ~ 1.0），写入 AudioServer 时统一转 dB。

const BUS_MASTER := &"Master"
const BUS_MUSIC := &"Music"
const BUS_SFX := &"SFX"
const BUS_VOICE := &"Voice"
const BUS_AMBIENCE := &"Ambience"
const BUS_UI := &"UI"
const REQUIRED_BUSES: Array[StringName] = [BUS_MUSIC, BUS_SFX, BUS_VOICE, BUS_AMBIENCE, BUS_UI]
const MIN_DB := -80.0
const DEFAULT_DUCK_ATTACK := 0.1
const DEFAULT_DUCK_HOLD := 0.0
const DEFAULT_DUCK_RELEASE := 0.3

var _volumes: Dictionary = {}
var _mutes: Dictionary = {}
var _snapshot: Dictionary = {}
var _ducks: Dictionary = {}


func _init() -> void:
	for bus: StringName in REQUIRED_BUSES:
		_volumes[bus] = 1.0
	ensure_buses()


## 确保 Music/SFX/Voice/Ambience/UI 总线存在并挂到 Master 下。
## 总线已存在时不会重复创建，也不会改动用户的现有布局。
static func ensure_buses() -> void:
	for bus: StringName in REQUIRED_BUSES:
		if AudioServer.get_bus_index(bus) >= 0:
			continue
		var index := AudioServer.bus_count
		AudioServer.add_bus(index)
		AudioServer.set_bus_name(index, bus)
		AudioServer.set_bus_send(index, BUS_MASTER)


static func bus_index(bus: StringName) -> int:
	return AudioServer.get_bus_index(bus)


func set_channel_volume(bus: StringName, linear: float) -> void:
	_volumes[bus] = clampf(linear, 0.0, 1.0)
	_apply(bus)


func channel_volume(bus: StringName) -> float:
	return float(_volumes.get(bus, 1.0))


func mute_bus(bus: StringName, muted: bool) -> void:
	_mutes[bus] = muted
	_apply(bus)


func is_muted(bus: StringName) -> bool:
	return bool(_mutes.get(bus, false))


## 压低某条总线。amount_db 为负值（例如 -6.0）。
func duck_bus(
	bus: StringName,
	amount_db: float,
	attack := DEFAULT_DUCK_ATTACK,
	hold := 0.0,
	release := DEFAULT_DUCK_RELEASE
) -> void:
	_ducks[bus] = {
		"amount_db": minf(amount_db, 0.0),
		"attack": maxf(attack, 0.001),
		"hold": maxf(hold, 0.0),
		"release": maxf(release, 0.001),
		"elapsed": 0.0,
		"released": false,
		"level_db": 0.0,
	}
	_apply(bus)


func clear_duck(bus: StringName) -> void:
	var duck: Variant = _ducks.get(bus)
	if duck == null:
		return
	var config: Dictionary = duck
	if bool(config.get("released", false)):
		return
	config["released"] = true
	config["elapsed"] = 0.0
	_ducks[bus] = config


## 应用混音快照：{bus: 线性音量}。快照与用户音量相乘，不会覆盖设置值。
func apply_snapshot(volumes: Dictionary) -> void:
	_snapshot = volumes.duplicate(true)
	for bus: StringName in REQUIRED_BUSES:
		_apply(bus)


func snapshot() -> Dictionary:
	return _snapshot.duplicate(true)


## 推进 duck 包络，每帧调用一次（O(bus 数)）。
func tick(delta: float) -> void:
	if _ducks.is_empty():
		return
	for bus: StringName in _ducks.keys():
		var config: Dictionary = _ducks[bus]
		config["elapsed"] = float(config.get("elapsed", 0.0)) + delta
		_apply(bus)
		if bool(config.get("released", false)) and float(config.get("level_db", 0.0)) >= -0.01:
			_ducks.erase(bus)


## duck 当前衰减值（dB），用于调试面板与测试。
func duck_level_db(bus: StringName) -> float:
	var duck: Variant = _ducks.get(bus)
	if duck == null:
		return 0.0
	return float((duck as Dictionary).get("level_db", 0.0))


## 只捕获游戏驱动的混音快照；用户音量与静音属于设置，不能写进存档覆盖玩家选择。
func capture_state() -> Dictionary:
	return {"snapshot": _snapshot.duplicate(true)}


func restore_state(state: Dictionary) -> bool:
	if not state is Dictionary:
		return false
	var snapshot_value: Variant = state.get("snapshot", {})
	if snapshot_value is Dictionary:
		apply_snapshot(snapshot_value)
	return true


## 把当前音量（用户音量 × 快照 × duck）写入 AudioServer。
func _apply(bus: StringName) -> void:
	var index := AudioServer.get_bus_index(bus)
	if index < 0:
		return
	var effective := channel_volume(bus) * float(_snapshot.get(bus, 1.0))
	effective *= db_to_linear(_duck_level(bus))
	AudioServer.set_bus_volume_db(index, linear_to_db(effective))
	AudioServer.set_bus_mute(index, bool(_mutes.get(bus, false)))


func _duck_level(bus: StringName) -> float:
	var duck: Variant = _ducks.get(bus)
	if duck == null:
		return 0.0
	var config: Dictionary = duck
	var amount := float(config.get("amount_db", 0.0))
	var attack := float(config.get("attack", DEFAULT_DUCK_ATTACK))
	var hold := float(config.get("hold", 0.0))
	var release := float(config.get("release", DEFAULT_DUCK_RELEASE))
	var elapsed := float(config.get("elapsed", 0.0))
	var level := 0.0
	if bool(config.get("released", false)):
		level = amount * (1.0 - clampf(elapsed / release, 0.0, 1.0))
	else:
		if elapsed <= attack:
			level = amount * clampf(elapsed / attack, 0.0, 1.0)
		elif elapsed <= attack + hold:
			level = amount
		else:
			level = amount * (1.0 - clampf((elapsed - attack - hold) / release, 0.0, 1.0))
			config["released"] = true
	config["level_db"] = level
	_ducks[bus] = config
	return level


static func linear_to_db(linear: float) -> float:
	if linear <= 0.0:
		return MIN_DB
	return maxf(20.0 * log(linear) / log(10.0), MIN_DB)


static func db_to_linear(db: float) -> float:
	if db <= MIN_DB:
		return 0.0
	return pow(10.0, db / 20.0)
