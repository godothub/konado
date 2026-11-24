@tool
extends RefCounted
class_name KonadoScriptProjectIndex

## Cached, side-effect-free project symbol index for KonadoScript language services.
##
## Textual `.tres` and `.tscn` files are parsed without loading or instantiating
## project scenes. Each symbol keeps its declaration file, source line and final
## resource target so completion, diagnostics and navigation share one source of
## truth without executing user tool scripts while the editor is typing.

const RESOURCE_SCHEMAS: Dictionary = {
	"actors": {"name": "character_id", "target": "character_scene"},
	"backgrounds": {"name": "background_name", "target": "background_scene"},
	"background_music_tracks": {"name": "background_music_name", "target": "stream"},
	"sfx": {"name": "sound_effect_name", "target": "stream"},
	"voices": {"name": "voice_name", "target": "stream"},
}
const SCOPED_PROPERTY_SCHEMAS: Dictionary = {
	"states": "status_name",
	"cameras": "marker_id",
}
const ANIMATION_PATTERN := '"name"\\s*:\\s*&?"([^"]+)"'
const MOTION_PATTERN := '(?m)^\\s*resource_name\\s*=\\s*"([^"]+)"'
const EXT_RESOURCE_HEADER_PATTERN := "(?m)^\\[ext_resource[^\\]]*\\]$"
const BLOCK_HEADER_PATTERN := "(?m)^\\[(?:sub_resource|resource|node)[^\\]]*\\]$"
const SCANNED_EXTENSIONS := ["ks", "tres", "tscn"]
const IGNORED_DIRECTORIES := [
	"node_modules",
	"build",
	"dist",
]
const MAX_TEXT_RESOURCE_BYTES := 8 * 1024 * 1024
const DUPLICATE_GLOBAL_KINDS := [
	"actors", "backgrounds", "background_music_tracks", "sfx", "voices"
]

static var _shared_instance: KonadoScriptProjectIndex
static var _regex_cache: Dictionary = {}

var _symbols := {}
var _symbol_sets := {}
var _definitions := {}
var _file_cache := {}
var _script_default_cache := {}
var _seen_paths := {}
var _dirty_paths := {}
var _dirty := true
var _inventory_dirty := true
var _filesystem_connected := false
var _inventory_refresh_scheduled := false


static func shared() -> KonadoScriptProjectIndex:
	if _shared_instance == null:
		_shared_instance = KonadoScriptProjectIndex.new()
	return _shared_instance


func get_values(kind: String) -> PackedStringArray:
	_ensure_index()
	return PackedStringArray(_symbols.get(kind, PackedStringArray()))


func get_definitions(kind: String, name: String = "") -> Array[Dictionary]:
	_ensure_index()
	var results: Array[Dictionary] = []
	var by_name: Dictionary = _definitions.get(kind, {})
	if not name.is_empty():
		for definition: Dictionary in by_name.get(name, []):
			results.append(definition.duplicate(true))
		return results
	for symbol_name: String in by_name:
		for definition: Dictionary in by_name[symbol_name]:
			results.append(definition.duplicate(true))
	return results


func get_definition(kind: String, name: String) -> Dictionary:
	var definitions := get_definitions(kind, name)
	if definitions.size() != 1:
		return {}
	return definitions[0]


func get_navigation_targets(kind: String, name: String) -> Array[Dictionary]:
	var targets: Array[Dictionary] = []
	var seen := {}
	for definition: Dictionary in get_definitions(kind, name):
		var target_path := String(definition.get("target_path", ""))
		if target_path.is_empty():
			target_path = String(definition.get("owner_path", ""))
		if target_path.is_empty() or seen.has(target_path):
			continue
		seen[target_path] = true
		var target := definition.duplicate(true)
		target["path"] = target_path
		targets.append(target)
	return targets


func get_duplicate_definitions() -> Array[Dictionary]:
	_ensure_index()
	var duplicates: Array[Dictionary] = []
	for kind: String in DUPLICATE_GLOBAL_KINDS:
		var by_name: Dictionary = _definitions.get(kind, {})
		for name: String in by_name:
			var definitions: Array = by_name[name]
			if definitions.size() > 1:
				(
					duplicates
					. append(
						{
							"kind": kind,
							"name": name,
							"definitions": definitions.duplicate(true),
						}
					)
				)
	return duplicates


func get_actor_scoped_values(actor_name: String, kind: String) -> PackedStringArray:
	_ensure_index()
	if kind not in ["states", "motions"]:
		return PackedStringArray()
	var actor_definitions := get_definitions("actors", actor_name)
	var owner_paths := {}
	for actor_definition: Dictionary in actor_definitions:
		var actor_scene := String(actor_definition.get("target_path", ""))
		if not actor_scene.is_empty():
			owner_paths[actor_scene] = true
		var motion_scene := String(actor_definition.get("motion_path", ""))
		if not motion_scene.is_empty():
			owner_paths[motion_scene] = true
	if kind == "motions" and owner_paths.is_empty():
		return get_values(kind)
	var values := PackedStringArray()
	var seen_values := {}
	for definition: Dictionary in get_definitions(kind):
		if owner_paths.has(String(definition.get("owner_path", ""))):
			var value := String(definition.get("name", ""))
			if not value.is_empty() and not seen_values.has(value):
				values.append(value)
				seen_values[value] = true
	if kind == "motions" and values.is_empty():
		return get_values(kind)
	values.sort()
	return values


func get_actor_scoped_targets(
	actor_name: String,
	kind: String,
	name: String,
) -> Array[Dictionary]:
	if kind not in ["states", "motions"]:
		return get_navigation_targets(kind, name)
	var actor_definitions := get_definitions("actors", actor_name)
	var owner_paths := {}
	for actor_definition: Dictionary in actor_definitions:
		var actor_scene := String(actor_definition.get("target_path", ""))
		var motion_scene := String(actor_definition.get("motion_path", ""))
		if kind == "states" and not actor_scene.is_empty():
			owner_paths[actor_scene] = true
		if kind == "motions" and not motion_scene.is_empty():
			owner_paths[motion_scene] = true
	var targets: Array[Dictionary] = []
	var seen_paths := {}
	for definition: Dictionary in get_definitions(kind, name):
		if not owner_paths.is_empty() and not owner_paths.has(definition.get("owner_path")):
			continue
		var target := definition.duplicate(true)
		var target_path := String(definition.get("target_path", definition.get("owner_path", "")))
		if target_path.is_empty() or seen_paths.has(target_path):
			continue
		seen_paths[target_path] = true
		target["path"] = target_path
		targets.append(target)
	if kind == "motions" and targets.is_empty() and owner_paths.is_empty():
		return get_navigation_targets(kind, name)
	return targets


func invalidate() -> void:
	_dirty = true
	_inventory_dirty = true
	_inventory_refresh_scheduled = false


func invalidate_path(path: String) -> void:
	if path.get_extension().to_lower() not in SCANNED_EXTENSIONS:
		return
	_dirty_paths[path] = true
	_dirty = true


func update_document(document: KonadoScriptDocument) -> void:
	if (
		document == null
		or not document.path.begins_with("res://")
		or document.path.get_extension().to_lower() != "ks"
	):
		return
	var path := document.path
	var cached: Dictionary = _file_cache.get(path, {})
	if cached.get("revision") == document.revision:
		return
	var file_exists := FileAccess.file_exists(path)
	_file_cache[path] = {
		"modified_time": FileAccess.get_modified_time(path) if file_exists else 0,
		"file_size": FileAccess.get_size(path) if file_exists else document.source.length(),
		"revision": document.revision,
		"definitions": _collect_script_definitions(document),
	}
	_seen_paths[path] = true
	_dirty_paths.erase(path)
	if not _inventory_dirty:
		_rebuild_indexes()
		_dirty = false
	else:
		_dirty = true


func _ensure_index() -> void:
	_connect_filesystem_signal()
	if not _dirty:
		return
	# Keep the last immutable snapshot responsive while an editor filesystem
	# inventory refresh is already queued for the idle loop. Initial indexing and
	# explicit invalidation remain synchronous so callers never receive no data.
	if _inventory_dirty and _inventory_refresh_scheduled and not _file_cache.is_empty():
		return
	_rebuild_dirty_index()


func _rebuild_dirty_index() -> void:
	if _inventory_dirty:
		_seen_paths.clear()
		_scan_directory("res://")
		for cached_path: String in _file_cache.keys():
			if not _seen_paths.has(cached_path):
				_file_cache.erase(cached_path)
	else:
		for path: String in _dirty_paths:
			if FileAccess.file_exists(path):
				_scan_file(path)
			else:
				_file_cache.erase(path)
	_dirty_paths.clear()
	_inventory_dirty = false
	_rebuild_indexes()
	_dirty = false


func _rebuild_indexes() -> void:
	_symbols = {}
	_symbol_sets = {}
	_definitions = {}
	for kind: String in [
		"actors",
		"backgrounds",
		"background_music_tracks",
		"sfx",
		"voices",
		"states",
		"motions",
		"cameras",
		"scripts",
		"branches",
		"variables",
		"signals",
		"achievements",
	]:
		_symbols[kind] = PackedStringArray()
		_symbol_sets[kind] = {}
		_definitions[kind] = {}
	for cached: Dictionary in _file_cache.values():
		_merge_file_definitions(cached.get("definitions", {}))
	for kind: String in _symbols:
		var values: PackedStringArray = _symbols[kind]
		values.sort()


func _connect_filesystem_signal() -> void:
	if _filesystem_connected or not Engine.is_editor_hint():
		return
	var filesystem := EditorInterface.get_resource_filesystem()
	if filesystem == null:
		return
	var callback := Callable(self, "_on_filesystem_changed")
	if not filesystem.filesystem_changed.is_connected(callback):
		filesystem.filesystem_changed.connect(callback)
	var paths_callback := Callable(self, "_invalidate_paths")
	for signal_name: StringName in [&"resources_reimported", &"resources_reload"]:
		if (
			filesystem.has_signal(signal_name)
			and not filesystem.is_connected(signal_name, paths_callback)
		):
			filesystem.connect(signal_name, paths_callback)
	_filesystem_connected = true


func _on_filesystem_changed() -> void:
	_dirty = true
	_inventory_dirty = true
	if not _inventory_refresh_scheduled:
		_inventory_refresh_scheduled = true
		_refresh_inventory_deferred.call_deferred()


func _refresh_inventory_deferred() -> void:
	_inventory_refresh_scheduled = false
	if _dirty and _inventory_dirty:
		_rebuild_dirty_index()


func _invalidate_paths(paths: PackedStringArray) -> void:
	var document_store := KonadoScriptDocumentStore.shared()
	for path: String in paths:
		_file_cache.erase(path)
		_script_default_cache.erase(path)
		if path.get_extension().to_lower() in SCANNED_EXTENSIONS:
			_dirty_paths[path] = true
		if path.get_extension().to_lower() == "ks":
			document_store.invalidate(path)
	_dirty = true


func _scan_directory(path: String) -> void:
	var directory := DirAccess.open(path)
	if directory == null:
		return
	directory.list_dir_begin()
	var entry := directory.get_next()
	while not entry.is_empty():
		if entry.begins_with("."):
			entry = directory.get_next()
			continue
		var entry_path := path.path_join(entry)
		if directory.current_is_dir():
			if entry not in IGNORED_DIRECTORIES and not directory.is_link(entry):
				_scan_directory(entry_path)
		else:
			_scan_file(entry_path)
		entry = directory.get_next()
	directory.list_dir_end()


func _scan_file(path: String) -> void:
	var extension := path.get_extension().to_lower()
	if extension not in SCANNED_EXTENSIONS:
		return
	_seen_paths[path] = true
	if extension == "ks":
		_scan_script_file(path)
		return
	var modified_time := FileAccess.get_modified_time(path)
	var file_size := FileAccess.get_size(path)
	var cached: Dictionary = _file_cache.get(path, {})
	if cached.get("modified_time") == modified_time and cached.get("file_size") == file_size:
		return
	if file_size > MAX_TEXT_RESOURCE_BYTES:
		_file_cache[path] = {
			"modified_time": modified_time,
			"file_size": file_size,
			"definitions": {},
		}
		return
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return
	var source := file.get_as_text()
	var file_definitions := _parse_text_resource(path, source, extension)
	_file_cache[path] = {
		"modified_time": modified_time,
		"file_size": file_size,
		"definitions": file_definitions,
	}


func _scan_script_file(path: String) -> void:
	var modified_time := FileAccess.get_modified_time(path)
	var file_size := FileAccess.get_size(path)
	var cached: Dictionary = _file_cache.get(path, {})
	if (
		cached.get("modified_time") == modified_time
		and cached.get("file_size") == file_size
		and not _dirty_paths.has(path)
	):
		return
	var document := KonadoScriptDocumentStore.shared().get_document(path)
	if (
		cached.get("modified_time") == modified_time
		and cached.get("file_size") == file_size
		and cached.get("revision") == document.revision
	):
		return
	_file_cache[path] = {
		"modified_time": modified_time,
		"file_size": file_size,
		"revision": document.revision,
		"definitions": _collect_script_definitions(document),
	}


func _collect_script_definitions(document: KonadoScriptDocument) -> Dictionary:
	var path := document.path
	var definitions := {
		"scripts":
		[
			_make_definition("scripts", path, path, 1, path),
		]
	}
	for reference: Dictionary in document.references:
		var kind := String(reference.get("kind", ""))
		if reference.get("role") != "definition" and kind != "achievements":
			continue
		if kind not in ["branches", "variables", "signals", "achievements"]:
			continue
		_append_definition(
			definitions,
			_make_definition(
				kind,
				String(reference.get("name", "")),
				path,
				int(reference.get("line", 1)),
				path,
			),
		)
	return definitions


func _parse_text_resource(path: String, source: String, extension: String) -> Dictionary:
	var definitions := {}
	var line_starts := _build_line_starts(source)
	var external_resources := _collect_external_resources(source)
	for block: Dictionary in _collect_blocks(source):
		var block_source := String(block["source"])
		for kind: String in RESOURCE_SCHEMAS:
			var schema: Dictionary = RESOURCE_SCHEMAS[kind]
			var name_match := _find_property(block_source, String(schema["name"]))
			if name_match.is_empty():
				continue
			var target_path := _resolve_property_target(
				block_source,
				String(schema["target"]),
				external_resources,
			)
			var definition := _make_definition(
				kind,
				String(name_match["value"]),
				path,
				_line_at(line_starts, int(block["start"]) + int(name_match["start"])),
				target_path,
			)
			if kind == "actors":
				definition["motion_path"] = _resolve_property_target(
					block_source,
					"actor_motion_layer",
					external_resources,
				)
			_append_definition(definitions, definition)
		for scoped_kind: String in SCOPED_PROPERTY_SCHEMAS:
			var name_match := _find_property_or_script_default(
				block_source,
				String(SCOPED_PROPERTY_SCHEMAS[scoped_kind]),
				external_resources,
			)
			if name_match.is_empty():
				continue
			_append_definition(
				definitions,
				_make_definition(
					scoped_kind,
					String(name_match["value"]),
					path,
					_line_at(line_starts, int(block["start"]) + int(name_match["start"])),
					path,
				),
			)
	if extension == "tres":
		_collect_audio_event_definitions(definitions, source, path, line_starts, external_resources)
	if extension == "tscn":
		_collect_pattern_definitions(
			definitions, source, path, "states", ANIMATION_PATTERN, line_starts
		)
		_collect_pattern_definitions(
			definitions, source, path, "motions", MOTION_PATTERN, line_starts
		)
	return definitions


## 音频事件（KonadoAudioEvent）按总线映射到 bgm / sfx / voices，
## 使 `play bgm <id>` 的补全、跳转与重命名对事件同样生效。
func _collect_audio_event_definitions(
	definitions: Dictionary,
	source: String,
	path: String,
	line_starts: PackedInt32Array,
	external_resources: Dictionary,
) -> void:
	if not source.contains("KonadoAudioEvent"):
		return
	for block: Dictionary in _collect_blocks(source):
		var block_source := String(block["source"])
		var id_match := _find_string_name_property(block_source, "id")
		if id_match.is_empty():
			continue
		var bus_match := _find_string_name_property(block_source, "bus")
		var bus := String(bus_match["value"]) if not bus_match.is_empty() else "SFX"
		_append_definition(
			definitions,
			_make_definition(
				_audio_kind_for_bus(bus),
				String(id_match["value"]),
				path,
				_line_at(line_starts, int(block["start"]) + int(id_match["start"])),
				_resolve_first_ext_resource(block_source, "streams", external_resources),
			),
		)


func _audio_kind_for_bus(bus: String) -> String:
	if bus == "Music" or bus == "Ambience":
		return "background_music_tracks"
	if bus == "Voice":
		return "voices"
	return "sfx"


## 事件里的 `id = &"echo"` 使用 StringName 写法，需要兼容前导 &。
func _find_string_name_property(block_source: String, property_name: String) -> Dictionary:
	var regex := _get_regex('(?m)^\\s*%s\\s*=\\s*&?"([^"]+)"' % property_name)
	if regex == null:
		return {}
	var match_result := regex.search(block_source)
	if match_result == null:
		return {}
	return {"value": match_result.get_string(1), "start": match_result.get_start(1)}


## `streams = Array[AudioStream]([ExtResource("x")])` 取第一条外部音频流作为跳转目标。
func _resolve_first_ext_resource(
	block_source: String, property_name: String, external_resources: Dictionary
) -> String:
	var regex := _get_regex('(?m)^\\s*%s\\s*=\\s*[^\\n]*ExtResource\\("([^"]+)"\\)' % property_name)
	if regex == null:
		return ""
	var match_result := regex.search(block_source)
	if match_result == null:
		return ""
	return String(external_resources.get(match_result.get_string(1), ""))


func _collect_external_resources(source: String) -> Dictionary:
	var resources := {}
	var regex := _get_regex(EXT_RESOURCE_HEADER_PATTERN)
	if regex == null:
		return resources
	for match_result: RegExMatch in regex.search_all(source):
		var header := match_result.get_string()
		var resource_id := _get_header_attribute(header, "id")
		var resource_path := _get_header_attribute(header, "path")
		if not resource_id.is_empty() and not resource_path.is_empty():
			resources[resource_id] = resource_path
	return resources


func _collect_blocks(source: String) -> Array[Dictionary]:
	var blocks: Array[Dictionary] = []
	var regex := _get_regex(BLOCK_HEADER_PATTERN)
	if regex == null:
		return blocks
	var headers := regex.search_all(source)
	for index: int in headers.size():
		var content_start := headers[index].get_end()
		var content_end := source.length()
		if index + 1 < headers.size():
			content_end = headers[index + 1].get_start()
		(
			blocks
			. append(
				{
					"start": content_start,
					"source": source.substr(content_start, content_end - content_start),
				}
			)
		)
	return blocks


func _get_header_attribute(header: String, attribute: String) -> String:
	var regex := _get_regex('(?:^|\\s)%s="([^"]+)"' % attribute)
	if regex == null:
		return ""
	var match_result := regex.search(header)
	return "" if match_result == null else match_result.get_string(1)


func _find_property(block_source: String, property_name: String) -> Dictionary:
	var regex := _get_regex('(?m)^\\s*%s\\s*=\\s*"([^"]+)"' % property_name)
	if regex == null:
		return {}
	var match_result := regex.search(block_source)
	if match_result == null:
		return {}
	return {
		"value": match_result.get_string(1),
		"start": match_result.get_start(1),
	}


func _find_property_or_script_default(
	block_source: String,
	property_name: String,
	external_resources: Dictionary,
) -> Dictionary:
	var property := _find_property(block_source, property_name)
	if not property.is_empty():
		return property
	var script_path := _resolve_property_target(block_source, "script", external_resources)
	var defaults := _get_script_string_defaults(script_path)
	if not defaults.has(property_name):
		return {}
	return {
		"value": String(defaults[property_name]),
		"start": 0,
	}


func _get_script_string_defaults(path: String) -> Dictionary:
	if path.get_extension().to_lower() != "gd" or not FileAccess.file_exists(path):
		return {}
	var modified_time := FileAccess.get_modified_time(path)
	var file_size := FileAccess.get_size(path)
	var cached: Dictionary = _script_default_cache.get(path, {})
	if cached.get("modified_time") == modified_time and cached.get("file_size") == file_size:
		return cached.get("defaults", {})
	if file_size > MAX_TEXT_RESOURCE_BYTES:
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var regex := _get_regex(
		(
			"(?m)^\\s*(?:@export(?:_[A-Za-z0-9_]+)?(?:\\([^\\n]*\\))?\\s+)?"
			+ 'var\\s+([A-Za-z_][A-Za-z0-9_]*)\\s*(?::[^=\\n]+)?=\\s*"([^"]*)"'
		)
	)
	if regex == null:
		return {}
	var defaults := {}
	for match_result: RegExMatch in regex.search_all(file.get_as_text()):
		defaults[match_result.get_string(1)] = match_result.get_string(2)
	_script_default_cache[path] = {
		"modified_time": modified_time,
		"file_size": file_size,
		"defaults": defaults,
	}
	return defaults


func _resolve_property_target(
	block_source: String,
	property_name: String,
	external_resources: Dictionary,
) -> String:
	var regex := _get_regex('(?m)^\\s*%s\\s*=\\s*ExtResource\\("([^"]+)"\\)' % property_name)
	if regex == null:
		return ""
	var match_result := regex.search(block_source)
	if match_result == null:
		return ""
	return String(external_resources.get(match_result.get_string(1), ""))


func _collect_pattern_definitions(
	definitions: Dictionary,
	source: String,
	path: String,
	kind: String,
	pattern: String,
	line_starts: PackedInt32Array,
) -> void:
	var regex := _get_regex(pattern)
	if regex == null:
		return
	for match_result: RegExMatch in regex.search_all(source):
		var name := match_result.get_string(1)
		if name.is_empty():
			continue
		_append_definition(
			definitions,
			_make_definition(
				kind,
				name,
				path,
				_line_at(line_starts, match_result.get_start(1)),
				path,
			),
		)


func _make_definition(
	kind: String,
	name: String,
	owner_path: String,
	line: int,
	target_path: String,
) -> Dictionary:
	return {
		"kind": kind,
		"name": name,
		"owner_path": owner_path,
		"line": line,
		"target_path": target_path,
	}


func _append_definition(definitions: Dictionary, definition: Dictionary) -> void:
	var kind := String(definition.get("kind", ""))
	var name := String(definition.get("name", ""))
	if kind.is_empty() or name.is_empty():
		return
	if not definitions.has(kind):
		definitions[kind] = []
	var kind_definitions: Array = definitions[kind]
	for existing: Dictionary in kind_definitions:
		if (
			existing.get("name") == name
			and existing.get("owner_path") == definition.get("owner_path")
			and existing.get("line") == definition.get("line")
		):
			return
	kind_definitions.append(definition)


func _merge_file_definitions(file_definitions: Dictionary) -> void:
	for kind: String in file_definitions:
		for definition: Dictionary in file_definitions[kind]:
			_add_index_definition(definition)


func _add_index_definition(definition: Dictionary) -> void:
	var kind := String(definition.get("kind", ""))
	var name := String(definition.get("name", ""))
	if not _symbols.has(kind) or name.is_empty():
		return
	var names: Dictionary = _symbol_sets[kind]
	if not names.has(name):
		names[name] = true
		var values: PackedStringArray = _symbols[kind]
		values.append(name)
	var by_name: Dictionary = _definitions[kind]
	if not by_name.has(name):
		by_name[name] = []
	var definitions: Array = by_name[name]
	for existing: Dictionary in definitions:
		if (
			existing.get("owner_path") == definition.get("owner_path")
			and existing.get("line") == definition.get("line")
		):
			return
	definitions.append(definition)


func _build_line_starts(source: String) -> PackedInt32Array:
	var result := PackedInt32Array([0])
	var offset := source.find("\n")
	while offset >= 0:
		result.append(offset + 1)
		offset = source.find("\n", offset + 1)
	return result


func _line_at(line_starts: PackedInt32Array, offset: int) -> int:
	var low := 0
	var high := line_starts.size()
	while low < high:
		var middle := (low + high) >> 1
		if line_starts[middle] <= offset:
			low = middle + 1
		else:
			high = middle
	return maxi(1, low)


static func _get_regex(pattern: String) -> RegEx:
	var cached: RegEx = _regex_cache.get(pattern)
	if cached != null:
		return cached
	var regex := RegEx.new()
	if regex.compile(pattern) != OK:
		return null
	_regex_cache[pattern] = regex
	return regex
