@tool
extends VBoxContainer

## Konado 音频面板（右键/底部停靠）：浏览事件、试听、按参数模拟、检查问题、
## 以及把旧版 BGM/SFX/Voice 列表一键导入为事件资源。

const EVENT_SCRIPT := preload("res://addons/konado/runtime/audio/konado_audio_event.gd")
const LIBRARY_SCRIPT := preload("res://addons/konado/runtime/audio/konado_audio_event_library.gd")
const SEARCH_DIRS: Array[String] = ["res://audio", "res://events"]
const EVENT_OUTPUT_DIR := "res://audio/events"

var _events: Array[KonadoAudioEvent] = []
var _library: KonadoAudioEventLibrary
var _tree: Tree
var _problems: ItemList
var _search: LineEdit
var _status: Label
var _parameter_slider: HSlider
var _parameter_label: Label
var _player: AudioStreamPlayer
var _current: KonadoAudioEvent
var _dirty := false


func _ready() -> void:
	name = "Konado Audio"
	_library = LIBRARY_SCRIPT.new()
	_build_ui()
	_refresh()
	var filesystem := EditorInterface.get_resource_filesystem()
	if (
		filesystem != null
		and not filesystem.filesystem_changed.is_connected(_on_filesystem_changed)
	):
		filesystem.filesystem_changed.connect(_on_filesystem_changed)


func _build_ui() -> void:
	var header := HBoxContainer.new()
	var refresh_button := Button.new()
	refresh_button.text = "刷新"
	refresh_button.pressed.connect(_refresh)
	header.add_child(refresh_button)
	_search = LineEdit.new()
	_search.placeholder_text = "搜索事件 ID"
	_search.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_search.text_changed.connect(_on_search_changed)
	header.add_child(_search)
	add_child(header)

	_tree = Tree.new()
	_tree.columns = 2
	_tree.set_column_title(0, "事件")
	_tree.set_column_title(1, "信息")
	_tree.column_titles_visible = true
	_tree.hide_root = true
	_tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tree.custom_minimum_size = Vector2(0, 220)
	_tree.item_selected.connect(_on_tree_selected)
	_tree.item_activated.connect(_on_tree_activated)
	add_child(_tree)

	var controls := HBoxContainer.new()
	controls.add_child(_make_button("▶ 试听", _play_selected))
	controls.add_child(_make_button("■ 停止", _stop))
	controls.add_child(_make_button("导入旧版列表", _import_legacy_lists))
	add_child(controls)

	var parameter_row := HBoxContainer.new()
	_parameter_label = Label.new()
	_parameter_label.text = "参数模拟"
	_parameter_label.custom_minimum_size = Vector2(90, 0)
	parameter_row.add_child(_parameter_label)
	_parameter_slider = HSlider.new()
	_parameter_slider.min_value = 0.0
	_parameter_slider.max_value = 100.0
	_parameter_slider.step = 1.0
	_parameter_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_parameter_slider.value_changed.connect(_on_parameter_changed)
	parameter_row.add_child(_parameter_slider)
	add_child(parameter_row)

	_status = Label.new()
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.text = "尚未扫描到事件"
	add_child(_status)

	var problems_title := Label.new()
	problems_title.text = "问题"
	add_child(problems_title)
	_problems = ItemList.new()
	_problems.custom_minimum_size = Vector2(0, 120)
	_problems.item_activated.connect(_on_problem_activated)
	add_child(_problems)


func _make_button(text: String, handler: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.pressed.connect(handler)
	return button


func _on_filesystem_changed() -> void:
	_dirty = true
	call_deferred("_refresh_if_dirty")


func _refresh_if_dirty() -> void:
	if not _dirty:
		return
	_dirty = false
	_refresh()


func _refresh() -> void:
	_events = _scan_events()
	_library.banks.clear()
	_library.events.clear()
	for event: KonadoAudioEvent in _events:
		_library.events.append(event)
	_library.rebuild()
	_fill_tree()
	_fill_problems()
	_status.text = "已加载 %d 个事件" % _events.size()


func _scan_events() -> Array[KonadoAudioEvent]:
	var found: Array[KonadoAudioEvent] = []
	var seen: Dictionary = {}
	for directory: String in SEARCH_DIRS:
		_scan_directory(directory, found, seen)
	return found


func _scan_directory(directory: String, found: Array[KonadoAudioEvent], seen: Dictionary) -> void:
	var handle := DirAccess.open(directory)
	if handle == null:
		return
	handle.list_dir_begin()
	var entry := handle.get_next()
	while entry != "":
		if entry.begins_with("."):
			entry = handle.get_next()
			continue
		var path := directory.path_join(entry)
		if handle.current_is_dir():
			_scan_directory(path, found, seen)
		elif entry.get_extension().to_lower() == "tres":
			_collect_event(path, found, seen)
		entry = handle.get_next()
	handle.list_dir_end()


func _collect_event(path: String, found: Array[KonadoAudioEvent], seen: Dictionary) -> void:
	if seen.has(path):
		return
	seen[path] = true
	var resource := ResourceLoader.load(path)
	if resource is KonadoAudioEvent:
		found.append(resource as KonadoAudioEvent)


func _fill_tree() -> void:
	_tree.clear()
	var root := _tree.create_item()
	var groups := {}
	var filter := _search.text.strip_edges().to_lower()
	for event: KonadoAudioEvent in _events:
		if not filter.is_empty() and not String(event.id).to_lower().contains(filter):
			continue
		var bus := String(event.bus)
		if not groups.has(bus):
			var group := _tree.create_item(root)
			group.set_text(0, bus)
			group.set_selectable(0, false)
			groups[bus] = group
		var item := _tree.create_item(groups[bus])
		item.set_text(0, String(event.id))
		item.set_text(1, _summary(event))
		item.set_metadata(0, event)


func _summary(event: KonadoAudioEvent) -> String:
	var parts := PackedStringArray()
	parts.append("%d 流" % event.streams.size())
	parts.append("并发 %d" % event.max_instances)
	if event.loop:
		parts.append("循环")
	if not event.parameters.is_empty():
		parts.append("参数 %d" % event.parameters.size())
	return " · ".join(parts)


func _on_search_changed(_text: String) -> void:
	_fill_tree()


func _on_tree_selected() -> void:
	var item := _tree.get_selected()
	_current = item.get_metadata(0) if item != null else null
	_update_parameter_ui()
	if _current != null:
		_status.text = "%s · %s" % [String(_current.id), _summary(_current)]


func _on_tree_activated() -> void:
	if _current == null:
		return
	EditorInterface.inspect_object(_current)


func _update_parameter_ui() -> void:
	var parameter := _first_parameter()
	if parameter == null:
		_parameter_label.text = "无参数"
		_parameter_slider.editable = false
		return
	_parameter_label.text = parameter.variable
	_parameter_slider.editable = true
	_parameter_slider.min_value = parameter.minimum
	_parameter_slider.max_value = maxf(parameter.maximum, parameter.minimum + 1.0)
	_parameter_slider.step = 1.0 if parameter.maximum - parameter.minimum > 10.0 else 0.1


func _first_parameter() -> KonadoAudioParameter:
	if _current == null:
		return null
	for parameter: KonadoAudioParameter in _current.parameters:
		if parameter != null and parameter.is_valid():
			return parameter
	return null


func _on_parameter_changed(value: float) -> void:
	var parameter := _first_parameter()
	if parameter == null:
		return
	var result := parameter.evaluate({parameter.variable: value})
	_parameter_label.text = (
		"%s = %s（增益 %.2f）" % [parameter.variable, str(value), float(result.get("gain", 1.0))]
	)
	if bool(result.get("gated", false)):
		_parameter_label.text += " · 条件不成立"


func _play_selected() -> void:
	if _current == null:
		_status.text = "先在列表中选择一个事件"
		return
	var stream := _current.pick_stream()
	if stream == null:
		_status.text = "该事件没有可播放的音频流"
		return
	var gain_db := 0.0
	var parameter := _first_parameter()
	if parameter != null:
		var result := parameter.evaluate({parameter.variable: _parameter_slider.value})
		if bool(result.get("gated", false)):
			_status.text = "参数条件不成立，运行时不会播放该事件"
			return
		gain_db = linear_to_db(maxf(0.0001, float(result.get("gain", 1.0))))
	var player := _ensure_player()
	player.stop()
	player.bus = String(_current.bus)
	player.volume_db = _current.volume_db + gain_db
	player.pitch_scale = _current.pitch_scale
	player.stream = _looped(stream, _current.loop)
	player.play()
	_status.text = "%s · 正在试听" % String(_current.id)


func _stop() -> void:
	if _player != null and is_instance_valid(_player):
		_player.stop()
		_player.stream = null


func _ensure_player() -> AudioStreamPlayer:
	if _player != null and is_instance_valid(_player):
		return _player
	_player = AudioStreamPlayer.new()
	_player.name = "KonadoAudioDockPreview"
	_player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_player)
	return _player


func _looped(stream: AudioStream, loop: bool) -> AudioStream:
	if not loop:
		return stream
	var copy := stream.duplicate() as AudioStream
	if copy is AudioStreamOggVorbis:
		(copy as AudioStreamOggVorbis).loop = true
	elif copy is AudioStreamMP3:
		(copy as AudioStreamMP3).loop = true
	elif copy is AudioStreamWAV:
		(copy as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD
	return copy


func _fill_problems() -> void:
	_problems.clear()
	for problem: Dictionary in _library.validate():
		_problems.add_item(
			"%s · %s" % [String(problem.get("event_id", "")), String(problem.get("message", ""))]
		)
		_problems.set_item_metadata(_problems.item_count - 1, String(problem.get("event_id", "")))


func _on_problem_activated(index: int) -> void:
	var target := String(_problems.get_item_metadata(index))
	if target.is_empty():
		return
	var root := _tree.get_root()
	if root == null:
		return
	for group: TreeItem in root.get_children():
		for item: TreeItem in group.get_children():
			if String(item.get_text(0)) != target:
				continue
			item.select(0)
			_tree.scroll_to_item(item)
			_on_tree_selected()
			return


## 把文件系统里选中的旧版 BGM/SFX/Voice 列表转成 res://audio/events/*.tres。
func _import_legacy_lists() -> void:
	var paths := EditorInterface.get_selected_paths()
	if paths.is_empty():
		_status.text = "先在文件系统里选中 BGM/SFX/Voice 列表资源"
		return
	var created := 0
	for path: String in paths:
		var resource := ResourceLoader.load(path)
		if resource != null:
			created += _import_list(resource)
	_refresh()
	_status.text = "已导入 %d 个事件到 %s" % [created, EVENT_OUTPUT_DIR]


func _import_list(resource: Resource) -> int:
	var specs: Array[Dictionary] = [
		{
			"property": &"background_music_tracks",
			"name": &"background_music_name",
			"bus": KonadoAudioEvent.BUS_MUSIC,
			"loop": true,
		},
		{
			"property": &"sound_effects",
			"name": &"sound_effect_name",
			"bus": KonadoAudioEvent.BUS_SFX,
			"loop": false,
		},
		{
			"property": &"voices",
			"name": &"voice_name",
			"bus": KonadoAudioEvent.BUS_VOICE,
			"loop": false,
		},
	]
	var created := 0
	for spec: Dictionary in specs:
		var entries: Variant = resource.get(spec["property"])
		if not entries is Array:
			continue
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(EVENT_OUTPUT_DIR))
		for entry: Variant in entries as Array:
			if not entry is Resource:
				continue
			var event_id := String((entry as Resource).get(spec["name"]))
			var stream: Variant = (entry as Resource).get(&"stream")
			if event_id.is_empty() or not stream is AudioStream:
				continue
			var event := EVENT_SCRIPT.new()
			event.id = StringName(event_id)
			event.bus = spec["bus"]
			event.loop = bool(spec["loop"])
			event.streams.append(stream)
			var target := "%s/%s.tres" % [EVENT_OUTPUT_DIR, event_id]
			if ResourceSaver.save(event, target) == OK:
				created += 1
	return created


func linear_to_db(linear: float) -> float:
	if linear <= 0.0:
		return -80.0
	return maxf(20.0 * log(linear) / log(10.0), -80.0)
