extends SceneTree

## Konado 音频内核测试：总线混音、事件路由、交叉淡入、并发池、RTPC、状态恢复。
## 全部断言基于逻辑状态与 AudioServer，不依赖真实声卡（headless 亦可运行）。

const BUS_MIXER := preload("res://addons/konado/runtime/audio/konado_audio_bus_mixer.gd")
const CONTROLLER_SCRIPT := preload("res://addons/konado/runtime/audio/konado_audio_controller.gd")
const DEMO_LIBRARY_PATH := "res://audio/audio_event_library.tres"
const DEMO_SCRIPT_DIR := "res://sample/demo"

var _failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_test_audio_parameters_compile()
	_test_buses_and_volume()
	_test_duck_envelope()
	await _test_event_routing_and_errors()
	await _test_music_crossfade_and_loop()
	await _test_sfx_pool_and_steal()
	await _test_cooldown()
	await _test_rtpc_gate_and_gain()
	_test_legacy_lists()
	_test_library_validation()
	_test_demo_library()
	_test_demo_scripts_reference_known_events()
	_test_demo_scene_wiring()
	await _test_state_roundtrip_keeps_settings()
	await _test_controller_voice_priority()
	if _failures == 0:
		print("PASS: audio engine tests")
	quit(_failures)


func _test_buses_and_volume() -> void:
	BUS_MIXER.ensure_buses()
	for bus: StringName in [&"Music", &"SFX", &"Voice", &"Ambience", &"UI"]:
		_expect(AudioServer.get_bus_index(bus) >= 0, "bus '%s' exists" % bus)
	var mixer := BUS_MIXER.new()
	mixer.set_channel_volume(&"Music", 0.5)
	var index := AudioServer.get_bus_index(&"Music")
	_expect_approx(
		AudioServer.get_bus_volume_db(index), -6.0206, 0.01, "linear volume is written in dB"
	)
	mixer.mute_bus(&"Music", true)
	_expect(AudioServer.is_bus_mute(index), "mute reaches AudioServer")
	mixer.mute_bus(&"Music", false)
	mixer.set_channel_volume(&"Music", 1.0)
	_expect_approx(AudioServer.get_bus_volume_db(index), 0.0, 0.01, "volume is restored")


## 编译器侧：音频命名参数（fade/volume/count）必须进入操作数并做范围校验。
func _test_audio_parameters_compile() -> void:
	var compiler := KonadoScriptCompiler.new()
	compiler.set_console_output_enabled(false)
	var play_bgm := compiler.compile_line(
		"play bgm theme [fade=1.5] [volume=-3]", 1, "res://audio-params.ks"
	)
	_expect(play_bgm != null, "play bgm with named parameters compiles")
	if play_bgm != null:
		_expect_equal(play_bgm.opcode(), KonadoOpcode.Type.BGM_PLAY, "play bgm emits BGM_PLAY")
		_expect_approx(float(play_bgm.value(&"fade")), 1.5, 0.001, "fade reaches the instruction")
		_expect_approx(
			float(play_bgm.value(&"volume")), -3.0, 0.001, "volume reaches the instruction"
		)
	var play_sfx := compiler.compile_line(
		"play sfx hit [count=3] [volume=-2]", 2, "res://audio-params.ks"
	)
	_expect(play_sfx != null, "play sfx with named parameters compiles")
	if play_sfx != null:
		_expect_equal(play_sfx.opcode(), KonadoOpcode.Type.SFX_PLAY, "play sfx emits SFX_PLAY")
		_expect_equal(int(play_sfx.value(&"count")), 3, "count reaches the instruction")
		_expect_approx(
			float(play_sfx.value(&"volume")), -2.0, 0.001, "sfx volume reaches the instruction"
		)
	var stop_bgm := compiler.compile_line("stop bgm [fade=2]", 3, "res://audio-params.ks")
	_expect(stop_bgm != null, "stop bgm with fade compiles")
	if stop_bgm != null:
		_expect_equal(stop_bgm.opcode(), KonadoOpcode.Type.BGM_STOP, "stop bgm emits BGM_STOP")
		_expect_approx(float(stop_bgm.value(&"fade")), 2.0, 0.001, "stop fade is emitted")
	_expect(compiler.get_errors().is_empty(), "valid audio parameters compile without errors")

	var strict := KonadoScriptCompiler.new()
	strict.set_console_output_enabled(false)
	strict.compile_line("play bgm theme [fade=-1]", 1, "res://audio-params.ks")
	_expect(not strict.get_errors().is_empty(), "a negative fade is rejected by the schema")


func _test_duck_envelope() -> void:
	var mixer := BUS_MIXER.new()
	mixer.set_channel_volume(&"Music", 1.0)
	mixer.duck_bus(&"Music", -6.0, 0.1, 0.0, 0.2)
	mixer.tick(0.1)
	_expect_approx(mixer.duck_level_db(&"Music"), -6.0, 0.01, "duck reaches its depth")
	var index := AudioServer.get_bus_index(&"Music")
	_expect_approx(
		AudioServer.get_bus_volume_db(index), -6.0206, 0.05, "duck is applied to the bus"
	)
	mixer.clear_duck(&"Music")
	mixer.tick(0.2)
	_expect_approx(mixer.duck_level_db(&"Music"), 0.0, 0.01, "duck releases back to zero")
	_expect_approx(AudioServer.get_bus_volume_db(index), 0.0, 0.05, "bus volume returns to normal")


func _make_engine(pool_size := 4) -> KonadoAudioEngine:
	var engine := KonadoAudioEngine.new()
	engine.sfx_pool_size = pool_size
	root.add_child(engine)
	engine.configure({"seed": 7, "sfx_pool_size": pool_size})
	return engine


func _make_stream(duration := 0.2) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	var frames := int(stream.mix_rate * duration)
	var data := PackedByteArray()
	data.resize(frames * 2)
	stream.data = data
	return stream


func _make_event(
	event_id: String, bus: StringName, stream: AudioStream, overrides := {}
) -> KonadoAudioEvent:
	var event := KonadoAudioEvent.new()
	event.id = StringName(event_id)
	event.bus = bus
	event.streams.append(stream)
	for key: String in overrides.keys():
		event.set(key, overrides[key])
	return event


func _make_library(events: Array) -> KonadoAudioEventLibrary:
	var library := KonadoAudioEventLibrary.new()
	for event: KonadoAudioEvent in events:
		library.events.append(event)
	library.rebuild()
	return library


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	printerr("ASSERTION FAILED: " + message)


func _expect_equal(actual: Variant, expected: Variant, message: String) -> void:
	if actual == expected:
		return
	_failures += 1
	printerr("ASSERTION FAILED: %s (expected %s, got %s)" % [message, expected, actual])


func _expect_approx(actual: float, expected: float, tolerance: float, message: String) -> void:
	if absf(actual - expected) <= tolerance:
		return
	_failures += 1
	printerr("ASSERTION FAILED: %s (expected %s, got %s)" % [message, expected, actual])


func _free_node(node: Node) -> void:
	if node == null or not is_instance_valid(node):
		return
	if node.get_parent() != null:
		node.get_parent().remove_child(node)
	node.free()


func _test_event_routing_and_errors() -> void:
	await process_frame
	var engine := _make_engine()
	var stream := _make_stream(0.2)
	(
		engine
		. set_library(
			_make_library(
				[
					_make_event("bgm_a", KonadoAudioEvent.BUS_MUSIC, stream, {"loop": true}),
					_make_event("hit", KonadoAudioEvent.BUS_SFX, stream),
				]
			)
		)
	)
	_expect(engine.has_event(&"bgm_a"), "library indexes standalone events")
	var music := engine.play_event(&"bgm_a", {"fade": 0.0})
	_expect(bool(music.get("ok", false)), "music event plays")
	_expect_equal(engine.active_music().get("event_id"), &"bgm_a", "active music tracks the event")
	var captured := engine.capture_state()
	var bgm_state: Dictionary = captured.get("bgm", {})
	_expect_equal(bgm_state.get("event_id"), "bgm_a", "the active event id is captured")
	var missing := engine.play_event(&"nope")
	_expect_equal(missing.get("code"), &"audio.event_not_found", "unknown events report a code")
	var sfx := engine.play_event(&"hit")
	_expect(bool(sfx.get("ok", false)), "sfx event plays")
	_expect_equal(engine.active_instances().size(), 1, "sfx instance is tracked")
	_free_node(engine)


func _test_music_crossfade_and_loop() -> void:
	await process_frame
	var engine := _make_engine()
	var stream := _make_stream(0.2)
	(
		engine
		. set_library(
			_make_library(
				[
					_make_event("bgm_a", KonadoAudioEvent.BUS_MUSIC, stream, {"loop": true}),
					_make_event("bgm_b", KonadoAudioEvent.BUS_MUSIC, stream, {"loop": true}),
				]
			)
		)
	)
	engine.play_event(&"bgm_a", {"fade": 0.0})
	var first: AudioStreamPlayer = engine.active_music().get("player")
	engine.play_event(&"bgm_b", {"fade": 0.2})
	_expect_equal(
		engine.active_music().get("event_id"), &"bgm_b", "crossfade switches logical music"
	)
	var second: AudioStreamPlayer = engine.active_music().get("player")
	_expect(first != second, "crossfade uses the spare music player")
	engine._process(0.25)
	_expect(first.stream == null, "the previous music player fades out and stops")
	_expect(second.stream != null, "the new music player keeps its stream")
	var looped := second.stream as AudioStreamWAV
	_expect(
		looped != null and looped.loop_mode == AudioStreamWAV.LOOP_FORWARD,
		"music streams are duplicated with a real loop",
	)
	_free_node(engine)


func _test_sfx_pool_and_steal() -> void:
	await process_frame
	var engine := _make_engine(4)
	var stream := _make_stream(0.4)
	(
		engine
		. set_library(
			_make_library(
				[
					_make_event(
						"hit",
						KonadoAudioEvent.BUS_SFX,
						stream,
						{"max_instances": 3, "steal_policy": KonadoAudioEvent.STEAL_REJECT},
					),
				]
			)
		)
	)
	for index in range(3):
		_expect(
			bool(engine.play_event(&"hit").get("ok", false)),
			"sfx instance %d plays" % (index + 1),
		)
	_expect_equal(engine.active_instances().size(), 3, "sfx pool overlaps three instances")
	var rejected := engine.play_event(&"hit")
	_expect(bool(rejected.get("ignored", false)), "steal_policy reject refuses the fourth")
	_expect_equal(rejected.get("code"), &"audio.instance_limit", "rejection reports a code")
	_free_node(engine)

	var small_engine := _make_engine(2)
	(
		small_engine
		. set_library(
			_make_library(
				[
					_make_event(
						"hit",
						KonadoAudioEvent.BUS_SFX,
						stream,
						{"max_instances": 8, "steal_policy": KonadoAudioEvent.STEAL_OLDEST},
					),
				]
			)
		)
	)
	for _index in range(3):
		small_engine.play_event(&"hit")
	_expect_equal(
		small_engine.active_instances().size(), 2, "a full pool steals the oldest instance"
	)
	_free_node(small_engine)


func _test_cooldown() -> void:
	await process_frame
	var engine := _make_engine()
	var stream := _make_stream(0.1)
	engine.set_library(
		_make_library([_make_event("hit", KonadoAudioEvent.BUS_SFX, stream, {"cooldown": 0.5})])
	)
	_expect(bool(engine.play_event(&"hit").get("ok", false)), "first trigger plays")
	var cooling := engine.play_event(&"hit")
	_expect(bool(cooling.get("ignored", false)), "a cooldown blocks the second trigger")
	_expect_equal(cooling.get("code"), &"audio.cooldown", "cooldown reports a code")
	engine._process(0.6)
	_expect(bool(engine.play_event(&"hit").get("ok", false)), "the trigger works after cooldown")
	_free_node(engine)


func _test_rtpc_gate_and_gain() -> void:
	await process_frame
	var engine := _make_engine()
	var stream := _make_stream(0.2)
	var parameter := KonadoAudioParameter.new()
	parameter.variable = "%love"
	parameter.gates_event = true
	parameter.minimum = 5.0
	parameter.maximum = 99.0
	parameter.gain_floor = 0.25
	parameter.gain_ceiling = 1.0
	var event := _make_event("love_theme", KonadoAudioEvent.BUS_MUSIC, stream)
	event.parameters.append(parameter)
	engine.set_library(_make_library([event]))
	engine.set_variable_values({"%love": 1})
	var gated := engine.play_event(&"love_theme")
	_expect(bool(gated.get("ignored", false)), "a gated event is skipped")
	_expect_equal(gated.get("code"), &"audio.gated", "gated events report a code")
	engine.set_variable_values({"%love": 10})
	var played := engine.play_event(&"love_theme", {"fade": 0.0})
	_expect(bool(played.get("ok", false)), "the event plays once the condition holds")
	var player: AudioStreamPlayer = engine.active_music().get("player")
	_expect_approx(
		player.volume_db,
		-10.755,
		0.2,
		"the RTPC curve drives the music gain",
	)
	engine.set_variable_values({"%love": 99})
	_expect_approx(player.volume_db, 0.0, 0.05, "changing the variable retargets the playing music")
	_free_node(engine)


func _test_legacy_lists() -> void:
	var list := KonadoBackgroundMusicList.new()
	var entry := KonadoBackgroundMusic.new()
	entry.background_music_name = "theme"
	entry.stream = _make_stream(0.1)
	list.background_music_tracks.append(entry)
	var library := KonadoAudioEventLibrary.new()
	library.register_legacy_lists(list, null, null)
	var event := library.lookup(&"theme")
	_expect(event != null, "legacy bgm lists become events")
	if event == null:
		return
	_expect_equal(event.bus, KonadoAudioEvent.BUS_MUSIC, "legacy bgm uses the music bus")
	_expect(event.loop, "legacy bgm loops")


func _test_library_validation() -> void:
	var stream := _make_stream(0.1)
	var library := _make_library(
		[
			_make_event("dup", KonadoAudioEvent.BUS_SFX, stream),
			_make_event("dup", KonadoAudioEvent.BUS_SFX, stream),
		]
	)
	var empty_event := KonadoAudioEvent.new()
	empty_event.id = &"empty"
	library.events.append(empty_event)
	var codes: Array[String] = []
	for problem: Dictionary in library.validate():
		codes.append(String(problem.get("code", "")))
	_expect(codes.has("audio.event_id_duplicate"), "duplicate ids are reported")
	_expect(codes.has("audio.event_stream_missing"), "events without streams are reported")


func _test_state_roundtrip_keeps_settings() -> void:
	await process_frame
	var engine := _make_engine()
	var stream := _make_stream(0.3)
	engine.set_library(
		_make_library([_make_event("bgm_a", KonadoAudioEvent.BUS_MUSIC, stream, {"loop": true})])
	)
	engine.set_volumes(0.5, 0.5, 0.5, 0.5)
	engine.play_event(&"bgm_a", {"fade": 0.0})
	var state := engine.capture_state()
	var music_index := AudioServer.get_bus_index(&"Music")
	engine.set_volumes(1.0, 1.0, 1.0, 1.0)
	var settings_db := AudioServer.get_bus_volume_db(music_index)
	_expect(engine.restore_state(state), "audio state restores")
	_expect_approx(
		AudioServer.get_bus_volume_db(music_index),
		settings_db,
		0.01,
		"restoring a save never overwrites the player's volume settings",
	)
	_expect_equal(
		engine.active_music().get("event_id", &""), &"bgm_a", "restore replays the music event"
	)
	_free_node(engine)


func _test_controller_voice_priority() -> void:
	await process_frame
	var controller := CONTROLLER_SCRIPT.new()
	controller.background_music_player = AudioStreamPlayer.new()
	controller.voice_player = AudioStreamPlayer.new()
	controller.sound_effect_player = AudioStreamPlayer.new()
	for player: AudioStreamPlayer in [
		controller.background_music_player, controller.voice_player, controller.sound_effect_player
	]:
		controller.add_child(player)
	root.add_child(controller)
	controller.play_voice(_make_stream(0.3), 5)
	_expect(controller.is_voice_playing(), "voice starts playing")
	controller.play_voice(_make_stream(0.3), 1)
	_expect(controller.is_voice_playing(), "a lower-priority voice does not interrupt")
	controller.play_voice(_make_stream(0.3), 9)
	_expect(controller.is_voice_playing(), "a higher-priority voice replaces the current one")
	controller.stop_voice()
	_expect(not controller.is_voice_playing(), "stop_voice stops playback")
	var events := controller.capture_state()
	_expect(events.has("voice"), "captured state always carries the voice channel")
	_free_node(controller)


## 示例工程已完整迁移到事件：事件库、Bank 与脚本引用必须自洽。
func _test_demo_library() -> void:
	var library := load(DEMO_LIBRARY_PATH) as KonadoAudioEventLibrary
	_expect(library != null, "the demo audio library loads")
	if library == null:
		return
	library.rebuild()
	for event_id: StringName in [&"echo", &"voice_01", &"voice_02", &"ui_click"]:
		_expect(library.has_event(event_id), "demo event '%s' is registered" % event_id)
	_expect(library.validate().is_empty(), "the demo library has no problems")
	var echo := library.lookup(&"echo")
	_expect(echo != null and echo.is_music() and echo.loop, "echo is a looping music event")
	_expect(
		echo != null and not echo.parameters.is_empty(),
		"echo carries an RTPC binding for %love",
	)
	var click := library.lookup(&"ui_click")
	_expect(
		click != null and click.stream_count() == 4 and click.max_instances == 6,
		"ui_click is a four-stream random container with an instance limit",
	)
	_expect(library.bank_names().has("demo_audio"), "the demo bank is indexed")


## 扫描示例脚本：play/stop 与语音引用的事件必须存在于示例事件库。
func _test_demo_scripts_reference_known_events() -> void:
	var library := load(DEMO_LIBRARY_PATH) as KonadoAudioEventLibrary
	if library == null:
		_expect(false, "the demo audio library loads")
		return
	library.rebuild()
	var directory := DirAccess.open(DEMO_SCRIPT_DIR)
	if directory == null:
		_expect(false, "the demo script directory is readable")
		return
	var play_pattern := RegEx.create_from_string("^play\\s+(?:bgm|sfx)\\s+(\\S+)")
	var voice_pattern := RegEx.create_from_string("\\s(voice_[A-Za-z0-9_]+)\\s*(?:\\[|$)")
	var missing: Array[String] = []
	for file_name: String in directory.get_files():
		if not file_name.ends_with(".ks"):
			continue
		var content := FileAccess.get_file_as_string("%s/%s" % [DEMO_SCRIPT_DIR, file_name])
		for raw_line: String in content.split("\n"):
			var line := raw_line.strip_edges()
			if line.is_empty() or line.begins_with("#"):
				continue
			var play_match := play_pattern.search(line)
			if play_match != null:
				var event_id := StringName(play_match.get_string(1))
				if not library.has_event(event_id):
					missing.append("%s -> %s" % [file_name, event_id])
			var voice_match := voice_pattern.search(line)
			if voice_match != null:
				var voice_id := StringName(voice_match.get_string(1))
				if not library.has_event(voice_id):
					missing.append("%s -> %s" % [file_name, voice_id])
	_expect(missing.is_empty(), "demo scripts reference known audio events: %s" % [missing])


## 示例场景必须真正接上事件库，否则剧本里的 play bgm 跑起来会失败。
func _test_demo_scene_wiring() -> void:
	var scene := load("res://sample/demo/demo.tscn") as PackedScene
	_expect(scene != null, "the demo scene loads")
	if scene == null:
		return
	var instance := scene.instantiate()
	var manager := instance.get_node_or_null("KonadoDialogue") as KonadoDialogueManager
	_expect(manager != null, "the demo scene exposes the dialogue manager")
	if manager != null:
		_expect(
			manager.audio_event_library != null,
			"the demo manager wires an audio event library",
		)
		if manager.audio_event_library != null:
			manager.audio_event_library.rebuild()
			_expect(
				manager.audio_event_library.has_event(&"echo"),
				"the demo library resolves the echo event",
			)
	instance.free()
