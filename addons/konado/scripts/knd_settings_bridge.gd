extends Node
class_name KND_SettingsBridge

## KND_SettingsBridge - 设置桥接器
## 
## 作为 konado 和 konado_settings 两个模块之间的解耦通信层，
## 提供统一的设置访问接口，实现模块间数据互通但保持高度解耦。


## 设置变更信号
## @param category: 设置分类
## @param key: 设置项的键
## @param value: 新的设置值
signal setting_changed(category: String, key: String, value: Variant)

## 设置管理器引用（动态获取）
var _settings_manager: Node = null

## 缓存的设置值，用于快速访问
var _cached_settings: Dictionary = {}

## 设置键常量定义
const CATEGORY_AUDIO: String = "audio"
const CATEGORY_TEXT: String = "text"
const CATEGORY_DISPLAY: String = "display"

const KEY_MASTER_VOLUME: String = "master_volume"
const KEY_MUSIC_VOLUME: String = "music_volume"
const KEY_SFX_VOLUME: String = "sfx_volume"
const KEY_VOICE_VOLUME: String = "voice_volume"
const KEY_TEXT_SPEED: String = "text_speed"
const KEY_AUTO_DELAY: String = "auto_delay"
const KEY_AUTO_MODE: String = "auto_mode"
const KEY_SKIP_READ: String = "skip_read"
const KEY_SKIP_ALL: String = "skip_all"
const KEY_FULLSCREEN: String = "fullscreen"
const KEY_LANGUAGE: String = "language"

## 获取设置管理器实例
## @return: 设置管理器节点，如果不存在返回 null
func _get_settings_manager() -> Node:
	if _settings_manager == null:
		_settings_manager = get_tree().root.get_node_or_null("KND_Settings")
	return _settings_manager

## 通用设置获取方法
## @param category: 设置分类
## @param key: 设置项的键
## @param default_value: 默认值
## @return: 设置值
func get_setting(category: String, key: String, default_value: Variant = null) -> Variant:
	var mgr = _get_settings_manager()
	if mgr == null:
		return default_value
	
	var value = mgr.call("get_setting", category, key)
	if value == null:
		return default_value
	return value

## 通用设置设置方法
## @param category: 设置分类
## @param key: 设置项的键
## @param value: 新的设置值
func set_setting(category: String, key: String, value: Variant) -> void:
	var mgr = _get_settings_manager()
	if mgr != null:
		mgr.call("set_setting", category, key, value)

## 音频设置相关方法

func get_master_volume() -> float:
	return get_setting(CATEGORY_AUDIO, KEY_MASTER_VOLUME, 1.0)

func get_music_volume() -> float:
	return get_setting(CATEGORY_AUDIO, KEY_MUSIC_VOLUME, 0.8)

func get_sfx_volume() -> float:
	return get_setting(CATEGORY_AUDIO, KEY_SFX_VOLUME, 1.0)

func get_voice_volume() -> float:
	return get_setting(CATEGORY_AUDIO, KEY_VOICE_VOLUME, 1.0)

## 文本播放设置相关方法

func get_text_speed() -> float:
	return get_setting(CATEGORY_TEXT, KEY_TEXT_SPEED, 0.05)

func get_auto_delay() -> float:
	return get_setting(CATEGORY_TEXT, KEY_AUTO_DELAY, 2.0)

func get_auto_mode() -> bool:
	return get_setting(CATEGORY_TEXT, KEY_AUTO_MODE, false)

func get_skip_read() -> bool:
	return get_setting(CATEGORY_TEXT, KEY_SKIP_READ, false)

func get_skip_all() -> bool:
	return get_setting(CATEGORY_TEXT, KEY_SKIP_ALL, false)

## 显示设置相关方法

func get_fullscreen() -> bool:
	return get_setting(CATEGORY_DISPLAY, KEY_FULLSCREEN, false)

func get_language() -> String:
	return get_setting(CATEGORY_DISPLAY, KEY_LANGUAGE, "zh")

## 订阅设置变更
## @param category: 设置分类（可选，为 null 时监听所有分类）
## @param key: 设置键（可选，为 null 时监听该分类下所有键）
## @param callback: 回调函数
func subscribe_to_setting(category: String , key: String , callback: Callable) -> void:
	var mgr = _get_settings_manager()
	if mgr != null and callback != null:
		mgr.setting_changed.connect(callback)

## 节点就绪时连接设置变更信号
func _ready() -> void:
	var mgr = _get_settings_manager()
	if mgr != null:
		mgr.setting_changed.connect(_on_setting_changed)

## 设置变更处理
func _on_setting_changed(category: String, key: String, value: Variant) -> void:
	# 更新缓存
	if not _cached_settings.has(category):
		_cached_settings[category] = {}
	_cached_settings[category][key] = value
	
	# 转发信号
	setting_changed.emit(category, key, value)

## 检查设置系统是否可用
## @return: 设置系统是否可用
func is_settings_available() -> bool:
	return _get_settings_manager() != null

## 获取所有分类信息
## @return: 分类数组
func get_categories() -> Array:
	var mgr = _get_settings_manager()
	if mgr != null:
		return mgr.call("get_categories")
	return []

## 重置指定分类的设置
## @param category_id: 分类ID
func reset_category(category_id: String) -> void:
	var mgr = _get_settings_manager()
	if mgr != null:
		mgr.call("reset_category", category_id)
		
## 显示设置面板
func show_settings_panel() -> void:
	var load_path: String = "res://addons/konado_settings/scenes/settings_panel.tscn"
	if not ResourceLoader.exists(load_path):
		printerr("未安装Konado Settings")
		return
	var settings_panel = load("res://addons/konado_settings/scenes/settings_panel.tscn").instantiate()
	add_child(settings_panel)
	# 显示设置面板
	settings_panel.show()
