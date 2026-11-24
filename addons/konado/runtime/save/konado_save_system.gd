extends Node
class_name KonadoSaveSystem

## Atomic, versioned save system for the Konado 2.9 Program VM.

signal save_completed(save_id: int, success: bool)
signal load_completed(save_id: int, success: bool)

const SAVE_DIR := "user://konado_saves/"
const SAVE_EXT := ".kns"

@export var max_save_slots := 20

var dialogue_manager: KonadoDialogueManager
var save_dir := SAVE_DIR


func _ready() -> void:
	_ensure_save_directory()


func set_dialogue_manager(manager: KonadoDialogueManager) -> void:
	dialogue_manager = manager


func save_game(save_id: int) -> bool:
	if not _valid_slot(save_id):
		return _save_failed(save_id, "存档编号超出范围")
	if dialogue_manager == null:
		return _save_failed(save_id, "对话管理器未设置")
	var snapshot := dialogue_manager._capture_execution_snapshot()
	if snapshot.is_empty():
		return _save_failed(save_id, "当前没有可保存的原子执行边界")
	var data := KonadoSaveData.new()
	data.execution = snapshot.execution
	data.runtime_state = snapshot.runtime_state
	data.save_time = Time.get_datetime_dict_from_system()
	var content := KonadoSaveCodec.encode(data.to_dict())
	if content.is_empty() or not _write_save_file(_get_save_path(save_id), content):
		return _save_failed(save_id, "无法安全写入存档")
	save_completed.emit(save_id, true)
	return true


func load_game(save_id: int) -> bool:
	if not _valid_slot(save_id):
		return _load_failed(save_id, "存档编号超出范围")
	if dialogue_manager == null:
		return _load_failed(save_id, "对话管理器未设置")
	var parsed := _read_save_file(_get_save_path(save_id))
	if parsed.is_empty():
		return _load_failed(save_id, "存档不存在或内容损坏")
	var data := KonadoSaveData.new()
	if not data.from_dict(parsed):
		return _load_failed(save_id, "存档格式与 Konado 2.9 不匹配（2.8 及更早的存档不再支持）")
	if not dialogue_manager._restore_execution_snapshot(
		{"execution": data.execution, "runtime_state": data.runtime_state}
	):
		return _load_failed(save_id, "存档引用的剧本版本或指令已失效")
	load_completed.emit(save_id, true)
	return true


func delete_save(save_id: int) -> bool:
	if not _valid_slot(save_id):
		return false
	var path := _get_save_path(save_id)
	return not FileAccess.file_exists(path) or DirAccess.remove_absolute(path) == OK


func get_save_info(save_id: int) -> Dictionary:
	if not _valid_slot(save_id):
		return {"exists": false}
	var parsed := _read_save_file(_get_save_path(save_id))
	if parsed.is_empty():
		return {"exists": false}
	return {
		"exists": true,
		"save_time": parsed.get("save_time", {}),
		"format_version": int(parsed.get("format_version", -1)),
		"compiler_abi": String(parsed.get("compiler_abi", "")),
	}


func get_all_save_info() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for save_id in range(max_save_slots):
		result.append(get_save_info(save_id))
	return result


func _valid_slot(save_id: int) -> bool:
	return save_id >= 0 and save_id < max_save_slots


func _get_save_path(save_id: int) -> String:
	return save_dir.path_join("%d%s" % [save_id, SAVE_EXT])


func _ensure_save_directory() -> bool:
	if DirAccess.dir_exists_absolute(save_dir):
		return true
	return DirAccess.make_dir_recursive_absolute(save_dir) == OK


func _read_save_file(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	if (
		file.get_length() <= 0
		or file.get_length() > KonadoSaveCodec.HEADER_SIZE + KonadoSaveCodec.MAX_PAYLOAD_BYTES
	):
		return {}
	return KonadoSaveCodec.decode(file.get_buffer(file.get_length()))


func _write_save_file(path: String, content: PackedByteArray) -> bool:
	if not _ensure_save_directory():
		return false
	var temporary := path + ".tmp"
	var backup := path + ".bak"
	if FileAccess.file_exists(temporary):
		DirAccess.remove_absolute(temporary)
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		return false
	file.store_buffer(content)
	file.flush()
	var write_error := file.get_error()
	file.close()
	if write_error != OK:
		DirAccess.remove_absolute(temporary)
		return false
	if FileAccess.file_exists(backup):
		DirAccess.remove_absolute(backup)
	var had_previous := FileAccess.file_exists(path)
	if had_previous and DirAccess.rename_absolute(path, backup) != OK:
		DirAccess.remove_absolute(temporary)
		return false
	if DirAccess.rename_absolute(temporary, path) != OK:
		if had_previous:
			DirAccess.rename_absolute(backup, path)
		return false
	if had_previous:
		DirAccess.remove_absolute(backup)
	return true


func _save_failed(save_id: int, message: String) -> bool:
	push_error("Konado: %s" % message)
	save_completed.emit(save_id, false)
	return false


func _load_failed(save_id: int, message: String) -> bool:
	push_error("Konado: %s" % message)
	load_completed.emit(save_id, false)
	return false
