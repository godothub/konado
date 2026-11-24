@tool
extends EditorInspectorPlugin

## KonadoAudioEvent 专用检查器：试听、停止、复制 ID 与事件摘要。
## 试听直接使用事件定义（总线/音量/音高/循环），因此听到的效果与运行时一致。

var _preview_player: AudioStreamPlayer
var _status: Label
var _event: KonadoAudioEvent


func _can_handle(object: Object) -> bool:
	return object is KonadoAudioEvent


func _parse_begin(object: Object) -> void:
	_event = object as KonadoAudioEvent
	if _event == null:
		return
	var row := HBoxContainer.new()
	row.add_child(_make_button("▶ 试听", _preview))
	row.add_child(_make_button("■ 停止", _stop_preview))
	row.add_child(_make_button("复制 ID", _copy_id))
	add_custom_control(row)
	_status = Label.new()
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.text = _summary()
	add_custom_control(_status)


func _make_button(text: String, handler: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.pressed.connect(handler)
	return button


func _preview() -> void:
	_stop_preview()
	if _event == null or _status == null:
		return
	var stream := _event.pick_stream()
	if stream == null:
		_status.text = "该事件没有可播放的音频流"
		return
	var player := _ensure_player()
	if player == null:
		return
	player.bus = String(_event.bus)
	player.volume_db = _event.volume_db
	player.pitch_scale = _event.pitch_scale
	player.stream = _looped(stream, _event.loop)
	player.play()
	_status.text = "%s · 正在试听" % _summary()


func _stop_preview() -> void:
	if _preview_player != null and is_instance_valid(_preview_player):
		_preview_player.stop()
		_preview_player.stream = null
	if _event != null and _status != null:
		_status.text = _summary()


func _copy_id() -> void:
	if _event == null:
		return
	DisplayServer.clipboard_set(String(_event.id))
	if _status != null:
		_status.text = "%s · 已复制 ID" % _summary()


func _ensure_player() -> AudioStreamPlayer:
	if _preview_player != null and is_instance_valid(_preview_player):
		return _preview_player
	var host := EditorInterface.get_base_control()
	if host == null:
		return null
	_preview_player = AudioStreamPlayer.new()
	_preview_player.name = "KonadoAudioEventPreview"
	_preview_player.process_mode = Node.PROCESS_MODE_ALWAYS
	host.add_child(_preview_player)
	return _preview_player


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


func _summary() -> String:
	if _event == null:
		return ""
	var names := PackedStringArray()
	var duration := 0.0
	for stream: AudioStream in _event.streams:
		if stream == null:
			names.append("空流")
			continue
		var path := stream.resource_path
		names.append(path.get_file() if not path.is_empty() else "内存流")
		duration = maxf(duration, stream.get_length())
	var parts := PackedStringArray()
	parts.append("总线 %s" % String(_event.bus))
	parts.append("%d 条流" % _event.streams.size())
	if duration > 0.0:
		parts.append("%.1fs" % duration)
	parts.append("并发 %d" % _event.max_instances)
	if _event.priority != 0:
		parts.append("优先级 %d" % _event.priority)
	if _event.loop:
		parts.append("循环")
	if not _event.parameters.is_empty():
		parts.append("%d 个参数" % _event.parameters.size())
	var detail := " / ".join(names)
	if not detail.is_empty():
		return "%s · %s" % [" · ".join(parts), detail]
	return " · ".join(parts)
