@tool
extends ScriptExtension
class_name KonadoShot

static var _konado_script_language: KonadoScriptLanguage

@export var source_path: String = "null"

@export var shot_id: String = "新镜头"

## Konado 2.9 唯一可执行产物。
@export_storage var program: KonadoProgram
@export_storage var locale_overlay: KonadoLocaleOverlay

## 依赖角色
@export var dependent_characters: Array[String] = []
## 编译期提取的资源依赖清单，供编辑器、导出检查和诊断复用。
@export var dependencies: Dictionary = {}

@export_storage var _protection_version := 0
@export_storage var _protection_serialized_size := 0
@export_storage var _protection_iv := PackedByteArray()
@export_storage var _protection_wrapped_key := PackedByteArray()
@export_storage var _protection_ciphertext := PackedByteArray()
@export_storage var _protection_mac := PackedByteArray()

var _protection_attempted := false
var _source_code := ""
var _source_loaded := false


## Expose loaded KonadoScript data as an editor-only script document.
##
## Runtime dialogue behavior remains resource-based. Implementing ScriptExtension
## lets Godot's native Script Editor own editing, saving, diagnostics, completion,
## navigation, and external-change handling for the original .ks source.
func _editor_can_reload_from_file() -> bool:
	return true


func _can_instantiate() -> bool:
	return false


func _get_base_script() -> Script:
	return null


func _get_global_name() -> StringName:
	return &""


func _inherits_script(_script: Script) -> bool:
	return false


func _get_instance_base_type() -> StringName:
	return &""


func _has_source_code() -> bool:
	return true


func _get_source_code() -> String:
	_load_source_code()
	return _source_code


func _set_source_code(source: String) -> void:
	_source_code = source
	_source_loaded = true


func _reload(_keep_state: bool) -> Error:
	_source_loaded = false
	_source_code = ""
	_load_source_code()
	return OK if _source_loaded else ERR_FILE_CANT_OPEN


func _get_doc_class_name() -> StringName:
	return &""


func _get_documentation() -> Array[Dictionary]:
	return []


func _get_method_info(_method: StringName) -> Dictionary:
	return {}


func _is_valid() -> bool:
	return true


func _is_tool() -> bool:
	return false


func _get_language() -> ScriptLanguage:
	if _konado_script_language == null:
		_konado_script_language = KonadoScriptLanguage.new()
	return _konado_script_language


func _has_method(_method: StringName) -> bool:
	return false


func _has_static_method(_method: StringName) -> bool:
	return false


func _has_script_signal(_signal: StringName) -> bool:
	return false


func _get_script_signal_list() -> Array[Dictionary]:
	return []


func _has_property_default_value(_property: StringName) -> bool:
	return false


func _get_property_default_value(_property: StringName) -> Variant:
	return null


func _update_exports() -> void:
	pass


func _get_script_method_list() -> Array[Dictionary]:
	return []


func _get_script_property_list() -> Array[Dictionary]:
	return []


func _get_member_line(_member: StringName) -> int:
	return -1


func _get_constants() -> Dictionary:
	return {}


func _get_members() -> Array[StringName]:
	return []


func _is_placeholder_fallback_enabled() -> bool:
	return false


func _get_rpc_config() -> Variant:
	return {}


func _load_source_code() -> void:
	if _source_loaded:
		return
	if not Engine.is_editor_hint() or source_path.is_empty() or source_path == "null":
		_source_loaded = true
		return
	var file := FileAccess.open(source_path, FileAccess.READ)
	if file == null:
		return
	_source_code = file.get_as_text()
	_source_loaded = true


## Convert this shot into an encrypted export resource.
func protect_script_for_export(build_key: PackedByteArray) -> bool:
	if is_script_protected():
		return true
	if program == null or not program.is_valid():
		push_error("[Konado] %s：没有可保护的有效 Program" % source_path)
		return false
	var result := KonadoScriptProtection.protect_program(program, build_key, source_path)
	if not result.get("ok", false):
		push_error("[Konado] %s：%s" % [source_path, result.get("error", "未知加密错误")])
		return false
	_protection_version = result["version"]
	_protection_serialized_size = result["serialized_size"]
	_protection_iv = result["iv"]
	_protection_wrapped_key = result["wrapped_key"]
	_protection_ciphertext = result["ciphertext"]
	_protection_mac = result["mac"]
	program = null
	_protection_attempted = false
	return true


## Restore protected dialogue nodes in memory on their first runtime access.
func ensure_script_ready() -> bool:
	if not is_script_protected():
		return true
	if _protection_attempted:
		return false
	_protection_attempted = true
	var result := KonadoScriptProtection.unprotect(
		_protection_version,
		_protection_serialized_size,
		_protection_iv,
		_protection_wrapped_key,
		_protection_ciphertext,
		_protection_mac,
		source_path
	)
	if not result.get("ok", false):
		push_error("[Konado] %s：%s" % [source_path, result.get("error", "未知解密错误")])
		return false
	program = result["program"]
	_clear_script_protection()
	return true


func is_script_protected() -> bool:
	return _protection_version > 0


func _clear_script_protection() -> void:
	_protection_version = 0
	_protection_serialized_size = 0
	_protection_iv.clear()
	_protection_wrapped_key.clear()
	_protection_ciphertext.clear()
	_protection_mac.clear()
	_protection_attempted = false


func install_program(value: KonadoProgram) -> void:
	program = value if value != null and value.seal() else null
	locale_overlay = null


func install_locale_overlay(value: KonadoLocaleOverlay) -> bool:
	if value != null and not value.is_compatible(program):
		return false
	locale_overlay = value
	return true


func instruction_count() -> int:
	if not ensure_script_ready():
		return 0
	return program.instruction_count() if program != null and program.is_valid() else 0


func entry_pc() -> int:
	if not ensure_script_ready():
		return KonadoProgram.INVALID_PC
	return program.entry_pc if program != null and program.is_valid() else KonadoProgram.INVALID_PC


func pc_for_key(key: String) -> int:
	if not ensure_script_ready():
		return KonadoProgram.INVALID_PC
	return (
		program.pc_for_key(key)
		if program != null and program.is_valid()
		else KonadoProgram.INVALID_PC
	)


func key_for_pc(pc: int) -> String:
	if not ensure_script_ready():
		return ""
	return program.key_for_pc(pc) if program != null and program.is_valid() else ""


func instruction_at(pc: int) -> KonadoInstruction:
	if not ensure_script_ready():
		return null
	return (
		KonadoInstruction.new(program, pc, locale_overlay)
		if program != null and program.is_valid() and pc >= 0 and pc < program.instruction_count()
		else null
	)


func program_fingerprint() -> String:
	if not ensure_script_ready():
		return ""
	return program.fingerprint() if program != null and program.is_valid() else ""
