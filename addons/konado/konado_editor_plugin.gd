@tool
extends EditorPlugin

## Konado 编辑器插件入口。所有注册操作均在对应的清理方法中成对释放。

const PLUGIN_CONFIG_PATH := "res://addons/konado/plugin.cfg"
const STORY_LOCALIZATION_AUTOLOAD_NAME := "KonadoStoryLocalization"
const STORY_LOCALIZATION_PATH := "res://addons/konado/localization/konado_story_localization.gd"
const ENABLED_PLUGINS_SETTING := "editor_plugins/enabled"
const LEGACY_PLUGIN_PATH_MIGRATIONS := {
	"res://addons/konado_webtool/plugin.cfg": "res://addons/konado_web_tool/plugin.cfg",
	"res://addons/konadotnet/plugin.cfg": "res://addons/konado_dotnet/plugin.cfg",
}
const LEGACY_AUTOLOAD_MIGRATIONS: Array[Dictionary] = [
	{
		"old_name": "KND_I18n",
		"owned_values":
		[
			"uid://c8y8inlr3ga6w",
			"res://addons/konado/i18n/knd_i18n.gd",
		],
		"new_name": STORY_LOCALIZATION_AUTOLOAD_NAME,
		"new_path": STORY_LOCALIZATION_PATH,
	},
	{
		"old_name": "KonadoLocalization",
		"owned_values": ["res://addons/konado/localization/konado_localization.gd"],
		"new_name": STORY_LOCALIZATION_AUTOLOAD_NAME,
		"new_path": STORY_LOCALIZATION_PATH,
	},
	{
		"old_name": "KND_AchievementManager",
		"owned_values":
		[
			"uid://dlhxd0ixnuo6i",
			"res://addons/konado_achievement/achievement_manager.gd",
			"res://addons/konado_achievement/runtime/konado_achievement_manager.gd",
		],
		"new_name": "KonadoAchievements",
		"new_path": "res://addons/konado_achievement/runtime/konado_achievement_manager.gd",
	},
	{
		"old_name": "KND_Settings",
		"owned_values":
		[
			"uid://crc32ueqs8u1w",
			"res://addons/konado_settings/scripts/settings_manager.gd",
			"res://addons/konado_settings/runtime/konado_settings_manager.gd",
		],
		"new_name": "KonadoSettings",
		"new_path": "res://addons/konado_settings/runtime/konado_settings_manager.gd",
	},
	{
		"old_name": "KND_WebTool",
		"owned_values":
		[
			"uid://b4rup11rlc0uk",
			"res://addons/konado_webtool/konado_webtool.gd",
			"res://addons/konado_web_tool/runtime/konado_web_tool.gd",
		],
		"new_name": "KonadoWebTool",
		"new_path": "res://addons/konado_web_tool/runtime/konado_web_tool.gd",
	},
	{
		"old_name": "KonadoAPI",
		"owned_values": ["res://addons/konadotnet/Runtime/API/KonadoAPI.cs"],
		"new_name": "KonadoApi",
		"new_path": "res://addons/konado_dotnet/runtime/api/KonadoApi.cs",
	},
]
const RUNTIME_TRANSLATION_PATHS: Array[String] = [
	"res://addons/konado/localization/translations/konado.zh_Hans.po",
	"res://addons/konado/localization/translations/konado.zh_Hant.po",
	"res://addons/konado/localization/translations/konado.en.po",
	"res://addons/konado/localization/translations/konado.ja.po",
	"res://addons/konado/localization/translations/konado.ko.po",
]
const TRANSLATIONS_SETTING := "internationalization/locale/translations"

const KONADO_SCRIPT_EXPORT_PLUGIN_SCRIPT := preload(
	"res://addons/konado/export/konado_script_export_plugin.gd"
)
const KONADO_SCRIPT_HIGHLIGHTER_SCRIPT := preload(
	"res://addons/konado/editor/script_editor/konado_script_syntax_highlighter.gd"
)
const KONADO_SCRIPT_RESOURCE_LOADER_SCRIPT := preload(
	"res://addons/konado/language/integration/konado_script_resource_loader.gd"
)
const KONADO_SCRIPT_SOURCE_SAVER_SCRIPT := preload(
	"res://addons/konado/editor/script_editor/konado_script_source_saver.gd"
)
const KONADO_SCRIPT_CREATE_MENU_SCRIPT := preload(
	"res://addons/konado/editor/script_editor/konado_script_create_menu.gd"
)
const KONADO_SCRIPT_CODE_CONTEXT_MENU_SCRIPT := preload(
	"res://addons/konado/editor/script_editor/konado_script_code_context_menu.gd"
)
const KONADO_SCRIPT_EDITOR_INTEGRATION_SCRIPT := preload(
	"res://addons/konado/editor/script_editor/konado_script_editor_integration.gd"
)
const KONADO_SCRIPT_TOOLTIP_PLUGIN_SCRIPT := preload(
	"res://addons/konado/editor/script_editor/konado_script_tooltip_plugin.gd"
)
const TYPEWRITER_AUDIO_INSPECTOR_SCRIPT := preload(
	"res://addons/konado/editor/inspectors/audio_effect/typewriter_audio_inspector_plugin.gd"
)
const AUDIO_EVENT_INSPECTOR_SCRIPT := preload(
	"res://addons/konado/editor/inspectors/audio_event/konado_audio_event_inspector_plugin.gd"
)
const AUDIO_DOCK_SCRIPT := preload("res://addons/konado/editor/audio/konado_audio_dock.gd")

var _script_export_plugin: EditorExportPlugin
var _script_resource_loader: ResourceFormatLoader
var _script_source_saver: ResourceFormatSaver
var _script_highlighter: EditorSyntaxHighlighter
var _script_create_menu: EditorContextMenuPlugin
var _script_code_context_menu: EditorContextMenuPlugin
var _script_editor_integration: KonadoScriptEditorIntegration
var _script_debugger_plugin: EditorDebuggerPlugin

var _file_system_dock: FileSystemDock
var _script_tooltip_plugin: EditorResourceTooltipPlugin

var _typewriter_audio_inspector: EditorInspectorPlugin = null
var _audio_event_inspector: EditorInspectorPlugin = null
var _audio_dock: Control = null
var _plugin_version := ""
var _debugger_registered := false


func _has_main_screen() -> bool:
	return false


func _enter_tree() -> void:
	_plugin_version = _read_plugin_version()
	if _plugin_version.is_empty():
		push_error("Konado failed to read its version from %s" % PLUGIN_CONFIG_PATH)
		return
	_migrate_legacy_project_settings()
	_ensure_story_localization_autoload()
	_ensure_runtime_translations()
	_setup_script_resources()
	_setup_export_plugin()
	_setup_script_editor()
	_print_loading_message()

	_file_system_dock = get_editor_interface().get_file_system_dock()
	_script_tooltip_plugin = KONADO_SCRIPT_TOOLTIP_PLUGIN_SCRIPT.new()
	_file_system_dock.add_resource_tooltip_plugin(_script_tooltip_plugin)

	_typewriter_audio_inspector = TYPEWRITER_AUDIO_INSPECTOR_SCRIPT.new()
	add_inspector_plugin(_typewriter_audio_inspector)

	_audio_event_inspector = AUDIO_EVENT_INSPECTOR_SCRIPT.new()
	add_inspector_plugin(_audio_event_inspector)

	_audio_dock = AUDIO_DOCK_SCRIPT.new()
	add_control_to_dock(DOCK_SLOT_RIGHT_UL, _audio_dock)


func _exit_tree() -> void:
	_cleanup_script_editor()
	_cleanup_export_plugin()

	if _file_system_dock and _script_tooltip_plugin:
		_file_system_dock.remove_resource_tooltip_plugin(_script_tooltip_plugin)
		_script_tooltip_plugin = null
	_file_system_dock = null

	if _typewriter_audio_inspector != null:
		remove_inspector_plugin(_typewriter_audio_inspector)
		_typewriter_audio_inspector = null

	if _audio_event_inspector != null:
		remove_inspector_plugin(_audio_event_inspector)
		_audio_event_inspector = null

	if _audio_dock != null:
		remove_control_from_docks(_audio_dock)
		_audio_dock.queue_free()
		_audio_dock = null


func _disable_plugin() -> void:
	# Godot clears custom resource handlers before EditorPlugin._exit_tree during
	# editor shutdown. Remove them here for live plugin disable/re-enable, while
	# allowing the engine to own shutdown cleanup.
	_detach_debugger_plugin()
	_cleanup_script_resources()
	var setting_name := "autoload/" + STORY_LOCALIZATION_AUTOLOAD_NAME
	if (
		ProjectSettings.has_setting(setting_name)
		and (
			_resolve_autoload_path(ProjectSettings.get_setting(setting_name))
			== STORY_LOCALIZATION_PATH
		)
	):
		remove_autoload_singleton(STORY_LOCALIZATION_AUTOLOAD_NAME)
	_remove_runtime_translations()


func _ensure_story_localization_autoload() -> void:
	var setting_name := "autoload/" + STORY_LOCALIZATION_AUTOLOAD_NAME
	if not ProjectSettings.has_setting(setting_name):
		add_autoload_singleton(STORY_LOCALIZATION_AUTOLOAD_NAME, STORY_LOCALIZATION_PATH)
		return
	var configured_path := _resolve_autoload_path(ProjectSettings.get_setting(setting_name))
	if configured_path != STORY_LOCALIZATION_PATH:
		push_error(
			(
				"Cannot enable Konado: autoload '%s' already points to '%s'."
				% [STORY_LOCALIZATION_AUTOLOAD_NAME, configured_path]
			)
		)


func _migrate_legacy_project_settings() -> void:
	var changed := _migrate_legacy_plugin_paths()
	for migration: Dictionary in LEGACY_AUTOLOAD_MIGRATIONS:
		changed = _migrate_owned_autoload(migration) or changed
	if not changed:
		return
	var error := ProjectSettings.save()
	if error != OK:
		push_error("Konado could not save migrated project settings: %s" % error)
		return
	print("Konado migrated project settings from an earlier installation.")


func _migrate_legacy_plugin_paths() -> bool:
	var configured := PackedStringArray(
		ProjectSettings.get_setting(ENABLED_PLUGINS_SETTING, PackedStringArray())
	)
	var installed_targets := PackedStringArray()
	for target: String in LEGACY_PLUGIN_PATH_MIGRATIONS.values():
		if FileAccess.file_exists(target):
			installed_targets.append(target)
	var migrated := migrate_enabled_plugin_paths(configured, installed_targets)
	if migrated == configured:
		return false
	ProjectSettings.set_setting(ENABLED_PLUGINS_SETTING, migrated)
	return true


func _migrate_owned_autoload(migration: Dictionary) -> bool:
	var old_name := String(migration.old_name)
	var setting_name := "autoload/" + old_name
	if not ProjectSettings.has_setting(setting_name):
		return false
	var configured_value: Variant = ProjectSettings.get_setting(setting_name)
	if not is_owned_legacy_autoload(configured_value, migration.owned_values):
		push_warning(
			(
				"Konado left autoload '%s' unchanged because its path is not owned by Konado."
				% old_name
			)
		)
		return false
	var new_path := String(migration.new_path)
	if not FileAccess.file_exists(new_path):
		push_warning(
			(
				"Konado left legacy autoload '%s' active because its replacement is not installed."
				% old_name
			)
		)
		return false
	remove_autoload_singleton(old_name)
	_ensure_migrated_autoload(String(migration.new_name), new_path)
	return true


func _ensure_migrated_autoload(autoload_name: String, autoload_path: String) -> void:
	if not FileAccess.file_exists(autoload_path):
		push_warning(
			(
				"Konado could not migrate optional autoload '%s' because %s is not installed."
				% [autoload_name, autoload_path]
			)
		)
		return
	var setting_name := "autoload/" + autoload_name
	if not ProjectSettings.has_setting(setting_name):
		add_autoload_singleton(autoload_name, autoload_path)
		return
	var configured_path := _resolve_autoload_path(ProjectSettings.get_setting(setting_name))
	if configured_path != autoload_path:
		push_warning(
			(
				"Konado did not replace autoload '%s' because it points to '%s'."
				% [autoload_name, configured_path]
			)
		)


static func migrate_enabled_plugin_paths(
	configured: PackedStringArray, installed_targets: PackedStringArray
) -> PackedStringArray:
	var migrated := PackedStringArray()
	for plugin_path: String in configured:
		var target := String(LEGACY_PLUGIN_PATH_MIGRATIONS.get(plugin_path, plugin_path))
		if target != plugin_path and target not in installed_targets:
			target = plugin_path
		if target not in migrated:
			migrated.append(target)
	return migrated


static func is_owned_legacy_autoload(value: Variant, owned_values: Array) -> bool:
	var raw_path := String(value).trim_prefix("*")
	if raw_path in owned_values:
		return true
	return _resolve_autoload_path(value) in owned_values


func _ensure_runtime_translations() -> void:
	var configured := PackedStringArray(
		ProjectSettings.get_setting(TRANSLATIONS_SETTING, PackedStringArray())
	)
	var changed := false
	for translation_path: String in RUNTIME_TRANSLATION_PATHS:
		if translation_path in configured:
			continue
		configured.append(translation_path)
		changed = true
	if changed:
		ProjectSettings.set_setting(TRANSLATIONS_SETTING, configured)
		var error := ProjectSettings.save()
		if error != OK:
			push_error("Konado could not save native translation settings: %s" % error)


func _remove_runtime_translations() -> void:
	var configured := PackedStringArray(
		ProjectSettings.get_setting(TRANSLATIONS_SETTING, PackedStringArray())
	)
	var changed := false
	for translation_path: String in RUNTIME_TRANSLATION_PATHS:
		if translation_path not in configured:
			continue
		configured.remove_at(configured.find(translation_path))
		changed = true
	if changed:
		ProjectSettings.set_setting(TRANSLATIONS_SETTING, configured)
		var error := ProjectSettings.save()
		if error != OK:
			push_error("Konado could not save native translation settings: %s" % error)


static func _resolve_autoload_path(value: Variant) -> String:
	var path := String(value).trim_prefix("*")
	if path.begins_with("uid://"):
		return ResourceUID.get_id_path(ResourceUID.text_to_id(path))
	return path


func _setup_script_editor() -> void:
	var script_editor := get_editor_interface().get_script_editor()
	_script_highlighter = KONADO_SCRIPT_HIGHLIGHTER_SCRIPT.new()
	script_editor.register_syntax_highlighter(_script_highlighter)
	_script_editor_integration = KONADO_SCRIPT_EDITOR_INTEGRATION_SCRIPT.new()
	_script_editor_integration.setup(script_editor, _plugin_version)
	# 无界面编辑器没有可交互调试会话，注册调试器会干扰退出清理。
	if DisplayServer.get_name() != "headless":
		var debugger_script := (
			load("res://addons/konado/editor/script_editor/konado_script_debugger_plugin.gd")
			as GDScript
		)
		_script_debugger_plugin = debugger_script.new()
		add_debugger_plugin(_script_debugger_plugin)
		_debugger_registered = true
		var base_control := get_editor_interface().get_base_control()
		if not base_control.tree_exiting.is_connected(_detach_debugger_plugin):
			base_control.tree_exiting.connect(_detach_debugger_plugin)
	_script_create_menu = KONADO_SCRIPT_CREATE_MENU_SCRIPT.new()
	add_context_menu_plugin(
		EditorContextMenuPlugin.CONTEXT_SLOT_FILESYSTEM_CREATE,
		_script_create_menu,
	)
	_script_code_context_menu = KONADO_SCRIPT_CODE_CONTEXT_MENU_SCRIPT.new()
	add_context_menu_plugin(
		EditorContextMenuPlugin.CONTEXT_SLOT_SCRIPT_EDITOR_CODE,
		_script_code_context_menu,
	)


func _setup_script_resources() -> void:
	_script_resource_loader = KONADO_SCRIPT_RESOURCE_LOADER_SCRIPT.new()
	_script_source_saver = KONADO_SCRIPT_SOURCE_SAVER_SCRIPT.new()
	ResourceLoader.add_resource_format_loader(_script_resource_loader, true)
	ResourceSaver.add_resource_format_saver(_script_source_saver, true)


func _cleanup_script_resources() -> void:
	if _script_source_saver:
		ResourceSaver.remove_resource_format_saver(_script_source_saver)
		_script_source_saver = null
	if _script_resource_loader:
		ResourceLoader.remove_resource_format_loader(_script_resource_loader)
		_script_resource_loader = null


func _cleanup_script_editor() -> void:
	_detach_debugger_plugin()
	if _script_editor_integration:
		_script_editor_integration.cleanup()
		_script_editor_integration = null
	if _script_code_context_menu:
		remove_context_menu_plugin(_script_code_context_menu)
		if _script_code_context_menu.has_method("cleanup"):
			_script_code_context_menu.cleanup()
		_script_code_context_menu = null
	if _script_create_menu:
		remove_context_menu_plugin(_script_create_menu)
		if _script_create_menu.has_method("cleanup"):
			_script_create_menu.cleanup()
		_script_create_menu = null
	if _script_highlighter:
		get_editor_interface().get_script_editor().unregister_syntax_highlighter(
			_script_highlighter
		)
		_script_highlighter = null


func _detach_debugger_plugin() -> void:
	if not _debugger_registered or _script_debugger_plugin == null:
		return
	if _script_debugger_plugin.has_method("cleanup"):
		_script_debugger_plugin.cleanup()
	remove_debugger_plugin(_script_debugger_plugin)
	_debugger_registered = false
	_script_debugger_plugin = null


func _setup_export_plugin() -> void:
	_script_export_plugin = KONADO_SCRIPT_EXPORT_PLUGIN_SCRIPT.new()
	add_export_plugin(_script_export_plugin)


func _cleanup_export_plugin() -> void:
	if _script_export_plugin:
		remove_export_plugin(_script_export_plugin)
		_script_export_plugin = null


func _print_loading_message() -> void:
	print("Konado %s" % _plugin_version)


static func _read_plugin_version() -> String:
	var config := ConfigFile.new()
	if config.load(PLUGIN_CONFIG_PATH) != OK:
		return ""
	return String(config.get_value("plugin", "version", "")).strip_edges()
