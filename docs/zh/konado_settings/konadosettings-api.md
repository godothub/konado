---
title: 使用API
order: 2
---

# Konado Settings API 文档

## 设置管理器 (KND_Settings)

设置管理器是一个自动加载的单例，用于管理所有设置项。

### 信号

#### `setting_changed(category: String, key: String, value: Variant)`
- **描述**：当设置值改变时发出的信号
- **参数**：
  - `category`：设置分类
  - `key`：设置项的键
  - `value`：新的设置值

### 方法

#### `get_setting(category: String, key: String) -> Variant`
- **描述**：获取设置的当前值
- **参数**：
  - `category`：设置分类
  - `key`：设置项的键
- **返回值**：设置值，如果不存在则返回默认值或 null

#### `set_setting(category: String, key: String, value: Variant) -> void`
- **描述**：修改设置，持久化并发出信号
- **参数**：
  - `category`：设置分类
  - `key`：设置项的键
  - `value`：新的设置值

#### `register_category(cat: SettingCategory) -> void`
- **描述**：在运行时注册额外的设置分类
- **参数**：
  - `cat`：要注册的设置分类

#### `reset_category(category_id: String) -> void`
- **描述**：将指定分类的所有设置重置为默认值
- **参数**：
  - `category_id`：分类 ID

#### `get_categories() -> Array`
- **描述**：获取所有注册的分类（根据当前平台过滤）
- **返回值**：过滤后的分类数组

#### `get_category(id: String) -> SettingCategory`
- **描述**：根据 ID 获取单个分类（根据当前平台过滤）
- **参数**：
  - `id`：分类 ID
- **返回值**：过滤后的分类对象

## 设置分类 (SettingCategory)

设置分类用于将相关的设置项分组在一起。

### 属性

- **id: String**：分类的唯一标识符
- **display_name: String**：分类的显示名称
- **items: Array[SettingItem]**：分类包含的设置项数组

### 示例

```gdscript
var video_cat = SettingCategory.new()
video_cat.id = "video"
video_cat.display_name = "视频"

# 添加设置项
video_cat.items.append(resolution_item)

# 注册分类
KND_Settings.register_category(video_cat)
```

## 设置项 (SettingItem)

设置项是单个可配置的设置单元。

### 枚举

#### `Type`
- **SLIDER (0)**：滑块类型，用于数值调节
- **TOGGLE (1)**：开关类型，用于布尔值
- **OPTION (2)**：选项类型，用于下拉选择

### 属性

- **key: String**：设置项的唯一标识符
- **label: String**：设置项的显示标签
- **type: Type**：设置项的类型
- **min_value: float**：滑块最小值（仅 SLIDER 类型）
- **max_value: float**：滑块最大值（仅 SLIDER 类型）
- **step: float**：滑块步长（仅 SLIDER 类型）
- **options: Array[String]**：选项列表（仅 OPTION 类型）
- **platforms: Array[String]**：平台过滤，空数组表示在所有平台可见
- **default_value: Variant**：默认值 - SLIDER 使用 float，TOGGLE 使用 bool，OPTION 使用 String

### 示例

#### 创建滑块类型设置项

```gdscript
var volume_item = SettingItem.new()
volume_item.key = "master_volume"
volume_item.label = "主音量"
volume_item.type = SettingItem.Type.SLIDER
volume_item.min_value = 0.0
volume_item.max_value = 1.0
volume_item.step = 0.01
volume_item.default_value = 1.0
volume_item.platforms = ["all"]
```

#### 创建开关类型设置项

```gdscript
var fullscreen_item = SettingItem.new()
fullscreen_item.key = "fullscreen"
fullscreen_item.label = "全屏"
fullscreen_item.type = SettingItem.Type.TOGGLE
fullscreen_item.default_value = false
```

#### 创建选项类型设置项

```gdscript
var language_item = SettingItem.new()
language_item.key = "language"
language_item.label = "语言"
language_item.type = SettingItem.Type.OPTION
language_item.options = ["zh", "tc", "en", "ja", "ko"]
language_item.default_value = "zh"
```

## UI 工厂 (UIFactory)

UI 工厂用于创建设置项的控制界面。

### 方法

#### `create_control(cat_id: String, item: SettingItem, callback: Callable) -> HBoxContainer`
- **描述**：为给定的设置项创建一个行（HBoxContainer）并返回
- **参数**：
  - `cat_id`：分类 ID
  - `item`：设置项
  - `callback`：回调函数，格式为 `callback(category_id: String, key: String, value: Variant)`
- **返回值**：创建的 HBoxContainer

### 示例

```gdscript
var row = UIFactory.create_control("audio", volume_item, func(category, key, value):
	print("设置变更: %s/%s = %s" % [category, key, value])
	KND_Settings.set_setting(category, key, value)
)

# 添加到容器
vbox_container.add_child(row)
```

## 设置面板 (SettingsPanel)

设置面板是一个可视化界面，用于显示和管理设置。

### 属性

- **_tab_container: TabContainer**：标签容器，用于显示不同分类的设置
- **btn_reset: Button**：恢复默认按钮
- **btn_close: Button**：关闭按钮

### 方法

#### `rebuild() -> void`
- **描述**：重建 UI（在注册新分类后有用）

### 信号

- **btn_reset.pressed**：当点击恢复默认按钮时发出
- **btn_close.pressed**：当点击关闭按钮时发出

### 示例

```gdscript
# 加载设置面板场景
var settings_panel = preload("res://addons/universal_settings/scenes/settings_panel.tscn").instantiate()
add_child(settings_panel)

# 显示设置面板
settings_panel.show()

# 注册新分类后重建面板
KND_Settings.register_category(new_category)
settings_panel.rebuild()
```

## 平台检测

设置系统会自动检测当前运行平台，并根据设置项的 `platforms` 属性过滤显示。

### 平台标识

- `all` - 所有平台
- `android` - Android
- `bsd` - BSD
- `linux` - Linux
- `macos` - macOS
- `ios` - iOS
- `visionos` - visionOS
- `windows` - Windows
- `linuxbsd` - Linux或BSD
- `debug` - 调试版本
- `release` - 发布版本
- `editor` - 编辑器构建

### 平台检测逻辑

1. 首先检测是否在编辑器中运行
2. 使用 `OS.has_feature()` 检测具体平台
3. 根据检测结果设置当前平台标识
4. 在获取分类时根据平台过滤设置项

## 持久化存储

设置值会自动保存到 `user://knd_settings.cfg` 文件中，使用 Godot 的 `ConfigFile` 格式。

### 保存时机

- 当调用 `set_setting()` 方法时
- 会自动将设置值写入配置文件

### 加载时机

- 插件初始化时
- 会自动从配置文件加载已保存的设置值

## 完整使用示例

### 1. 基本使用

```gdscript
# 获取设置值
var master_volume = KND_Settings.get_setting("audio", "master_volume")

# 设置值
KND_Settings.set_setting("audio", "master_volume", 0.8)

# 监听设置变更
KND_Settings.setting_changed.connect(func(category, key, value):
	if category == "audio" and key == "master_volume":
		# 处理音量变更
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(value))
)
```

### 2. 运行时注册新设置

```gdscript
# 创建新的设置分类
var video_cat = SettingCategory.new()
video_cat.id = "video"
video_cat.display_name = "视频"

# 创建设置项
var resolution_item = SettingItem.new()
resolution_item.key = "resolution"
resolution_item.label = "分辨率"
resolution_item.type = SettingItem.Type.OPTION
resolution_item.options = ["1280x720", "1920x1080", "2560x1440"]
resolution_item.default_value = "1920x1080"

# 添加到分类
video_cat.items.append(resolution_item)

# 注册分类
KND_Settings.register_category(video_cat)

# 重建设置面板（如果已显示）
if settings_panel:
	settings_panel.rebuild()
```

### 3. 自定义设置面板

```gdscript
# 创建自定义设置面板
var panel = CanvasLayer.new()

# 创建标签容器
var tab_container = TabContainer.new()
tab_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
tab_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
panel.add_child(tab_container)

# 构建设置界面
var mgr = KND_Settings
for cat in mgr.get_categories():
	var scroll = ScrollContainer.new()
	scroll.name = cat.display_name
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(vbox)

	for item in cat.items:
		var row = UIFactory.create_control(cat.id, item, func(cat_id, key, value):
			mgr.set_setting(cat_id, key, value)
		)
		vbox.add_child(row)

	tab_container.add_child(scroll)

# 添加到场景
add_child(panel)
```

## 注意事项

- 所有 API 调用都应该在游戏启动后进行
- 注册新分类后需要调用 `rebuild()` 方法更新设置面板
- 平台过滤只影响设置项的显示，不影响设置值的存储
- 设置项的 `key` 在分类内必须唯一
- 对于选项类型，默认值必须在 `options` 列表中

## 错误处理

- 如果设置项不存在，`get_setting()` 会返回 null 并发出警告
- 如果配置文件格式错误，会发出警告并使用默认值
- 如果平台检测失败，会默认为 `all` 平台

## 性能考虑

- 设置系统使用延迟加载，只在需要时解析配置文件
- 平台过滤在获取分类时进行，不会影响设置值的访问性能
- UI 创建是按需进行的，只在显示设置面板时创建控件

## 扩展建议

1. **添加新设置类型**：
   - 在 `SettingItem.Type` 中添加新枚举值
   - 在 `UIFactory` 中添加相应的创建逻辑

2. **自定义存储方式**：
   - 修改 `settings_manager.gd` 中的 `_load_saved()` 和 `set_setting()` 方法
   - 实现自定义的存储和加载逻辑

3. **添加设置验证**：
   - 在 `set_setting()` 中添加值验证逻辑
   - 确保设置值在有效范围内

4. **国际化支持**：
   - 修改 `display_name` 和 `label` 的处理逻辑
   - 支持多语言设置界面
