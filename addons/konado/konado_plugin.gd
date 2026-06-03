@tool
extends EditorPlugin
class_name KonadoEditorPlugin
# Konado框架入口文件，负责初始化插件和注册相关功能

const VERSION: String = "2.4.0"
const CODENAME: String = "Cannoli"

## 自定义EditorImportPlugin脚本
const KS_IMPORTER_SCRIPT := preload("uid://rp35gse7j4sv")
const KDIC_IMPORTER_SCRIPT := preload("uid://b7a8r75oh165c")

## 翻译文件路径
const TRANSLATION_PATHS: PackedStringArray = [
	#"res://addons/konado/i18n/i18n.zh.translation",
	#"res://addons/konado/i18n/i18n.zh_HK.translation",
	#"res://addons/konado/i18n/i18n.en.translation",
	#"res://addons/konado/i18n/i18n.ja.translation",
	#"res://addons/konado/i18n/i18n.ko.translation",
	#"res://addons/konado/i18n/i18n.de.translation"
]


## 插件实例变量
var ks_import_plugin: EditorImportPlugin
var kdic_import_plugin: EditorImportPlugin

# 文件系统dock
var filesystem_dock: FileSystemDock
var ks_tooltip_plugin: EditorResourceTooltipPlugin

var ks_editor: KsEditorWindow
var ks_dock :EditorDock


var inspector_plugin: EditorInspectorPlugin = null


func _has_main_screen() -> bool:
	return false

func _enter_tree() -> void:
	_setup_import_plugins()
	_print_loading_message()
	
	filesystem_dock = get_editor_interface().get_file_system_dock()
	ks_tooltip_plugin = preload("res://addons/konado/ks/ks_tooltip_plugin.gd").new()
	filesystem_dock.add_resource_tooltip_plugin(ks_tooltip_plugin)
	
	ks_dock = EditorDock.new()
	ks_dock.title = "KonadoEdit"
	# 4.5改用 EditorPlugin
	#ks_dock.default_slot = EditorPlugin.DOCK_SLOT_BOTTOM
	# 4.6以上改用 EditorDock
	ks_dock.default_slot = EditorDock.DOCK_SLOT_BOTTOM
	ks_editor = load("res://addons/konado/editor/ks_editor/ks_editor.tscn").instantiate() as KsEditorWindow
	ks_dock.add_child(ks_editor)
	ks_editor.visible = true
	add_dock(ks_dock)

	var inspector_plugin = preload("res://addons/konado/audioeffect/audioeffect_inspector_plugin.gd").new()
	# add_inspector_plugin完成注册
	add_inspector_plugin(inspector_plugin)
	
# 控制显示
#func _make_visible(visible: bool) -> void:
	#ks_dock.visible = visible

func _exit_tree() -> void:
	_cleanup_import_plugins()
	
	if filesystem_dock:
		filesystem_dock.remove_resource_tooltip_plugin(ks_tooltip_plugin)
		ks_tooltip_plugin = null
	
	if ks_dock:
		remove_dock(ks_dock)
		ks_dock.queue_free()


	if inspector_plugin != null:
		remove_inspector_plugin(inspector_plugin)
		inspector_plugin = null
	print("Konado unloaded")

## 用于处理ks文件和KND_Shot资源
func _handles(object: Object) -> bool:
	if object is Resource and object.resource_path.get_extension() == "ks":
		return true
	return false


func _edit(object: Object) -> void:
	if object is Resource and object.resource_path.get_extension() == "ks":
		ks_editor.edit(object.resource_path)
		ks_dock.make_visible()
	
	
## 设置导入插件
func _setup_import_plugins() -> void:
	ks_import_plugin = KS_IMPORTER_SCRIPT.new()
	kdic_import_plugin = KDIC_IMPORTER_SCRIPT.new()
	
	add_import_plugin(ks_import_plugin)
	add_import_plugin(kdic_import_plugin)
	
	
# 设置国际化
#func _setup_internationalization() -> void:
	#ProjectSettings.set_setting("internationalization/locale/translations", TRANSLATION_PATHS)
	#ProjectSettings.set_setting("internationalization/locale/locale_filter_mode", 1)  # 允许所有区域
	#ProjectSettings.save()
	#

## 清理导入插件
func _cleanup_import_plugins() -> void:
	if ks_import_plugin:
		remove_import_plugin(ks_import_plugin)
		ks_import_plugin = null
		
	if kdic_import_plugin:
		remove_import_plugin(kdic_import_plugin)
		kdic_import_plugin = null
		
		
## 打印加载信息
func _print_loading_message() -> void:
	print("Konado %s %s" % [VERSION, CODENAME])
	print("Konado loaded")
