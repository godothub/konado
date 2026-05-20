---
title: 使用 API
order: 2
---

# Konado Settings API 文件

## 設定管理器 (KND_Settings)

設定管理器是一個自動載入的單例 (Singleton)，用於管理所有設定項目。

### 訊號

#### `setting_changed(category: String, key: String, value: Variant)`
- **描述**：當設定值改變時發出的訊號
- **參數**：
  - `category`：設定分類
  - `key`：設定項目的鍵
  - `value`：新的設定值

### 方法

#### `get_setting(category: String, key: String) -> Variant`
- **描述**：取得設定的當前值
- **參數**：
  - `category`：設定分類
  - `key`：設定項目的鍵
- **回傳值**：設定值，如果不存在則回傳預設值或 null

#### `set_setting(category: String, key: String, value: Variant) -> void`
- **描述**：修改設定，進行持久化儲存並發出訊號
- **參數**：
  - `category`：設定分類
  - `key`：設定項目的鍵
  - `value`：新的設定值

#### `register_category(cat: SettingCategory) -> void`
- **描述**：在執行時註冊額外的設定分類
- **參數**：
  - `cat`：要註冊的設定分類

#### `reset_category(category_id: String) -> void`
- **描述**：將指定分類的所有設定重設為預設值
- **參數**：
  - `category_id`：分類 ID

#### `get_categories() -> Array`
- **描述**：取得所有註冊的分類（根據當前平台過濾）
- **回傳值**：過濾後的分類陣列

#### `get_category(id: String) -> SettingCategory`
- **描述**：根據 ID 取得單一分類（根據當前平台過濾）
- **參數**：
  - `id`：分類 ID
- **回傳值**：過濾後的分類物件

## 設定分類 (SettingCategory)

設定分類用於將相關的設定項目分組在一起。

### 屬性

- **id: String**：分類的唯一識別碼
- **display_name: String**：分類的顯示名稱
- **items: Array[SettingItem]**：分類包含的設定項目陣列

### 範例

```gdscript
var video_cat = SettingCategory.new()
video_cat.id = "video"
video_cat.display_name = "影片"

# 新增設定項目
video_cat.items.append(resolution_item)

# 註冊分類
KND_Settings.register_category(video_cat)
```

## 設定項目 (SettingItem)

設定項目是單個可配置的設定單元。

### 列舉 (Enum)

#### `Type`
- **SLIDER (0)**：滑桿類型，用於數值調節
- **TOGGLE (1)**：切換類型，用於布林值
- **OPTION (2)**：選項類型，用於下拉選單選擇

### 屬性

- **key: String**：設定項目的唯一識別碼
- **label: String**：設定項目的顯示標籤
- **type: Type**：設定項目的類型
- **min_value: float**：滑桿最小值（僅限 SLIDER 類型）
- **max_value: float**：滑桿最大值（僅限 SLIDER 類型）
- **step: float**：滑桿步長（僅限 SLIDER 類型）
- **options: Array[String]**：選項列表（僅限 OPTION 類型）
- **platforms: Array[String]**：平台過濾，空陣列表示在所有平台可見
- **default_value: Variant**：預設值 - SLIDER 使用 float，TOGGLE 使用 bool，OPTION 使用 String

### 範例

#### 建立滑桿類型設定項目

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

#### 建立切換類型設定項目

```gdscript
var fullscreen_item = SettingItem.new()
fullscreen_item.key = "fullscreen"
fullscreen_item.label = "全螢幕"
fullscreen_item.type = SettingItem.Type.TOGGLE
fullscreen_item.default_value = false
```

#### 建立選項類型設定項目

```gdscript
var language_item = SettingItem.new()
language_item.key = "language"
language_item.label = "語言"
language_item.type = SettingItem.Type.OPTION
language_item.options = ["zh", "en", "ja"]
language_item.default_value = "zh"
```

## UI 工廠 (UIFactory)

UI 工廠用於建立設定項目的控制介面。

### 方法

#### `create_control(cat_id: String, item: SettingItem, callback: Callable) -> HBoxContainer`
- **描述**：為給定的設定項目建立一列 (HBoxContainer) 並回傳
- **參數**：
  - `cat_id`：分類 ID
  - `item`：設定項目
  - `callback`：回呼函式，格式為 `callback(category_id: String, key: String, value: Variant)`
- **回傳值**：建立的 HBoxContainer

### 範例

```gdscript
var row = UIFactory.create_control("audio", volume_item, func(category, key, value):
	print("設定變更: %s/%s = %s" % [category, key, value])
	KND_Settings.set_setting(category, key, value)
)

# 新增到容器
vbox_container.add_child(row)
```

## 設定面板 (SettingsPanel)

設定面板是一個視覺化介面，用於顯示和管理設定。

### 屬性

- **_tab_container: TabContainer**：分頁容器，用於顯示不同分類的設定
- **btn_reset: Button**：重設為預設值按鈕
- **btn_close: Button**：關閉按鈕

### 方法

#### `rebuild() -> void`
- **描述**：重建 UI（在註冊新分類後非常有用）

### 訊號

- **btn_reset.pressed**：當點擊重設為預設值按鈕時發出
- **btn_close.pressed**：當點擊關閉按鈕時發出

### 範例

```gdscript
# 載入設定面板場景
var settings_panel = preload("res://addons/universal_settings/scenes/settings_panel.tscn").instantiate()
add_child(settings_panel)

# 顯示設定面板
settings_panel.show()

# 註冊新分類後重建面板
KND_Settings.register_category(new_category)
settings_panel.rebuild()
```

## 平台偵測

設定系統會自動偵測當前執行的平台，並根據設定項目的 `platforms` 屬性進行過濾顯示。

### 平台識別碼

- `all` - 所有平台
- `android` - Android
- `bsd` - BSD
- `linux` - Linux
- `macos` - macOS
- `ios` - iOS
- `visionos` - visionOS
- `windows` - Windows
- `linuxbsd` - Linux 或 BSD
- `debug` - 除錯版本
- `release` - 發布版本
- `editor` - 編輯器建置

### 平台偵測邏輯

1. 首先偵測是否在編輯器中執行
2. 使用 `OS.has_feature()` 偵測具體平台
3. 根據偵測結果設置當前平台識別碼
4. 在取得分類時根據平台過濾設定項目

## 持久化儲存

設定值會自動儲存到 `user://knd_settings.cfg` 檔案中，使用 Godot 的 `ConfigFile` 格式。

### 儲存時機

- 當呼叫 `set_setting()` 方法時
- 會自動將設定值寫入設定檔

### 載入時機

- 外掛程式初始化時
- 會自動從設定檔載入已儲存的設定值

## 完整使用範例

### 1. 基本使用

```gdscript
# 取得設定值
var master_volume = KND_Settings.get_setting("audio", "master_volume")

# 設定值
KND_Settings.set_setting("audio", "master_volume", 0.8)

# 監聽設定變更
KND_Settings.setting_changed.connect(func(category, key, value):
	if category == "audio" and key == "master_volume":
		# 處理音量變更
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(value))
)
```

### 2. 執行時註冊新設定

```gdscript
# 建立新的設定分類
var video_cat = SettingCategory.new()
video_cat.id = "video"
video_cat.display_name = "影片"

# 建立設定項目
var resolution_item = SettingItem.new()
resolution_item.key = "resolution"
resolution_item.label = "解析度"
resolution_item.type = SettingItem.Type.OPTION
resolution_item.options = ["1280x720", "1920x1080", "2560x1440"]
resolution_item.default_value = "1920x1080"

# 新增到分類
video_cat.items.append(resolution_item)

# 註冊分類
KND_Settings.register_category(video_cat)

# 重建設定面板（如果已顯示）
if settings_panel:
	settings_panel.rebuild()
```

### 3. 自定義設定面板

```gdscript
# 建立自定義設定面板
var panel = CanvasLayer.new()

# 建立分頁容器
var tab_container = TabContainer.new()
tab_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
tab_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
panel.add_child(tab_container)

# 建置設定介面
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

# 新增到場景
add_child(panel)
```

## 注意事項

- 所有 API 呼叫都應該在遊戲啟動後進行
- 註冊新分類後需要呼叫 `rebuild()` 方法更新設定面板
- 平台過濾只影響設定項目的顯示，不影響設定值的儲存
- 設定項目的 `key` 在分類內必須唯一
- 對於選項類型，預設值必須在 `options` 列表中

## 錯誤處理

- 如果設定項目不存在，`get_setting()` 會回傳 null 並發出警告
- 如果設定檔格式錯誤，會發出警告並使用預設值
- 如果平台偵測失敗，會預設為 `all` 平台

## 效能考慮

- 設定系統使用延遲載入，只在需要時解析設定檔
- 平台過濾在取得分類時進行，不會影響設定值的存取效能
- UI 建立是按需進行的，只在顯示設定面板時建立控制項

## 擴充建議

1. **新增設定類型**：
   - 在 `SettingItem.Type` 中新增列舉值
   - 在 `UIFactory` 中新增相應的建立邏輯

2. **自定義儲存方式**：
   - 修改 `settings_manager.gd` 中的 `_load_saved()` 和 `set_setting()` 方法
   - 實作自定義的儲存和載入邏輯

3. **新增設定驗證**：
   - 在 `set_setting()` 中新增值驗證邏輯
   - 確保設定值在有效範圍內

4. **在地化支援**：
   - 修改 `display_name` 和 `label` 的處理邏輯
   - 支援多語言設定介面
