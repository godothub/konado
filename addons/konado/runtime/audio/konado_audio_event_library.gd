extends Resource
class_name KonadoAudioEventLibrary

## 运行时音频事件库：把 Bank、独立事件与旧版资源列表统一成 id → 事件 的 O(1) 索引。
## 旧版 KonadoBackgroundMusicList / KonadoSoundEffectList / KonadoVoiceList 会在
## register_legacy_lists() 里被转成内存事件，因此现有工程无需改动即可继续播放。

@export var banks: Array[KonadoAudioBank] = []
@export var events: Array[KonadoAudioEvent] = []

var _index: Dictionary = {}
var _bank_index: Dictionary = {}
var _legacy_ids: Dictionary = {}


## 重建索引。显式事件优先于旧版列表生成的兼容事件。
func rebuild() -> void:
	_index.clear()
	_bank_index.clear()
	_legacy_ids.clear()
	for bank: KonadoAudioBank in banks:
		if bank == null:
			continue
		var collected: Array[KonadoAudioEvent] = []
		for event: KonadoAudioEvent in bank.events:
			if event == null:
				continue
			collected.append(event)
			_index[event.id] = event
		_bank_index[bank.bank_name] = collected
	for event: KonadoAudioEvent in events:
		if event == null:
			continue
		_index[event.id] = event


func lookup(id: StringName) -> KonadoAudioEvent:
	return _index.get(id)


func has_event(id: StringName) -> bool:
	return _index.has(id)


func is_legacy(id: StringName) -> bool:
	return _legacy_ids.has(id)


func event_ids() -> PackedStringArray:
	var ids := PackedStringArray()
	for id: StringName in _index.keys():
		ids.append(String(id))
	ids.sort()
	return ids


func bank_names() -> PackedStringArray:
	var names := PackedStringArray()
	for name: StringName in _bank_index.keys():
		names.append(String(name))
	names.sort()
	return names


func events_in_bank(bank_name: StringName) -> Array[KonadoAudioEvent]:
	var found: Array[KonadoAudioEvent] = []
	found.assign(_bank_index.get(bank_name, []))
	return found


func register_event(event: KonadoAudioEvent) -> void:
	if event == null or not event.is_valid():
		return
	_index[event.id] = event
	if not events.has(event):
		events.append(event)


## 把旧版三个资源列表转换成事件，保持现有工程可直接播放。
## bgm 自动开启循环，voice/sfx 走各自总线；显式同名事件不会被覆盖。
func register_legacy_lists(bgm_list: Resource, sfx_list: Resource, voice_list: Resource) -> void:
	for entry: Variant in _entries(bgm_list, &"background_music_tracks"):
		_register_legacy_entry(entry, &"background_music_name", KonadoAudioEvent.BUS_MUSIC, true)
	for entry: Variant in _entries(sfx_list, &"sound_effects"):
		_register_legacy_entry(entry, &"sound_effect_name", KonadoAudioEvent.BUS_SFX, false)
	for entry: Variant in _entries(voice_list, &"voices"):
		_register_legacy_entry(entry, &"voice_name", KonadoAudioEvent.BUS_VOICE, false)


## 返回结构化问题列表，供编辑器 Problems 面板与 CI 脚本共用同一套规则。
func validate() -> Array[Dictionary]:
	var problems: Array[Dictionary] = []
	var seen: Dictionary = {}
	for bank: KonadoAudioBank in banks:
		if bank == null:
			continue
		if String(bank.bank_name).is_empty():
			problems.append(_problem(&"audio.bank_name_missing", "", "Bank 缺少名称"))
		for event: KonadoAudioEvent in bank.events:
			_validate_event(event, seen, problems)
	for event: KonadoAudioEvent in events:
		_validate_event(event, seen, problems)
	return problems


func _validate_event(
	event: KonadoAudioEvent, seen: Dictionary, problems: Array[Dictionary]
) -> void:
	if event == null:
		problems.append(_problem(&"audio.event_null", "", "Bank 中存在空事件"))
		return
	if String(event.id).is_empty():
		problems.append(_problem(&"audio.event_id_missing", "", "事件缺少 ID"))
		return
	if seen.has(event.id):
		problems.append(_problem(&"audio.event_id_duplicate", String(event.id), "事件 ID 重复"))
		return
	seen[event.id] = true
	if event.streams.is_empty():
		problems.append(_problem(&"audio.event_stream_missing", String(event.id), "事件没有音频流"))
	for stream: AudioStream in event.streams:
		if stream == null:
			problems.append(_problem(&"audio.event_stream_null", String(event.id), "事件存在空音频流"))
		elif stream.resource_path.is_empty():
			(
				problems
				. append(
					_problem(
						&"audio.event_stream_unsaved",
						String(event.id),
						"音频流未保存到磁盘，打包后会丢失",
					)
				)
			)
	for parameter: KonadoAudioParameter in event.parameters:
		if parameter != null and not parameter.is_valid():
			(
				problems
				. append(
					_problem(
						&"audio.parameter_variable",
						String(event.id),
						"参数绑定缺少 %变量 或 $变量 形式的变量名",
					)
				)
			)


func _problem(code: StringName, event_id: String, message: String) -> Dictionary:
	return {"code": code, "event_id": event_id, "message": message}


func _register_legacy_entry(
	entry: Variant, name_property: StringName, bus: StringName, loop: bool
) -> void:
	if not entry is Resource:
		return
	var name := String((entry as Resource).get(name_property))
	if name.is_empty():
		return
	var event := KonadoAudioEvent.new()
	event.id = StringName(name)
	event.bus = bus
	event.loop = loop
	var stream: Variant = (entry as Resource).get(&"stream")
	if stream is AudioStream:
		event.streams.append(stream)
	if not _index.has(event.id):
		_index[event.id] = event
		_legacy_ids[event.id] = true


func _entries(list: Resource, property: StringName) -> Array:
	if list == null:
		return []
	var value: Variant = list.get(property)
	return value if value is Array else []
