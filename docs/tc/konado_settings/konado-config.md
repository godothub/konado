---
title: 設定檔
order: 1
---

# 設定配置指南

## 設定檔結構

預設設定檔位於 `res://addons/konado_settings/resources/default_settings.json`，使用 JSON 格式定義設定項目。

### 基本結構

```json
{
	"categories": [
		{
			"id": "audio",
			"display_name": "音訊",
			"items": [
				{
					"key": "master_volume",
					"label": "主音量",
					"type": 0,
					"min_value": 0.0,
					"max_value": 1.0,
					"step": 0.01,
					"default_value": 1.0,
					"platforms": ["all"]
				}
			]
		}
	]
}
```

## 配置說明

### 頂層結構

- **categories**：設定分類陣列，包含所有設定分類

### 分類屬性

- **id**：分類唯一識別碼，用於程式中存取
- **display_name**：分類顯示名稱，在設定面板中顯示
- **items**：設定項目陣列，包含該分類下的所有設定項目

### 設定項目屬性

- **key**：設定項目唯一識別碼，在分類內必須唯一
- **label**：設定項目顯示標籤，在設定面板中顯示
- **type**：設定類型
  - `0`：滑桿（SLIDER）
  - `1`：開關（TOGGLE）
  - `2`：選項（OPTION）

#### 滑桿類型（SLIDER）特有屬性

- **min_value**：最小值
- **max_value**：最大值
- **step**：步進值
- **default_value**：預設值（float 類型）

#### 開關類型（TOGGLE）特有屬性

- **default_value**：預設值（bool 類型）

#### 選項類型（OPTION）特有屬性

- **options**：選項列表（Array[String]）
- **default_value**：預設值（String 類型，必須在 options 列表中）

#### 通用屬性

- **platforms**：平台列表，空陣列或包含 "all" 表示所有平台

## 支援的平台識別碼

- `all` - 所有平台
- `android` - Android
- `bsd` - BSD
- `linux` - Linux
- `macos` - macOS
- `ios` - iOS
- `visionos` - visionOS
- `windows` - Windows
- `linuxbsd` - Linux 或 BSD
- `debug` - 偵錯版本
- `release` - 發佈版本
- `editor` - 編輯器構建

## 平台過濾規則

1. **空陣列**：表示在所有平台可見
2. **包含 "all"**：表示在所有平台可見
3. **特定平台**：只在指定的平台可見
4. **平台別名**：`linuxbsd` 會比對 Linux 或 BSD 平台
5. **構建類型**：`debug` 和 `release` 根據構建類型過濾

## 範例設定

### 完整設定範例

```json
{
	"categories": [
		{
			"id": "audio",
			"display_name": "音訊",
			"items": [
				{
					"key": "master_volume",
					"label": "主音量",
					"type": 0,
					"min_value": 0.0,
					"max_value": 1.0,
					"step": 0.01,
					"default_value": 1.0,
					"platforms": ["all"]
				},
				{
					"key": "music_volume",
					"label": "音樂音量",
					"type": 0,
					"min_value": 0.0,
					"max_value": 1.0,
					"step": 0.01,
					"default_value": 0.8
				}
			]
		},
		{
			"id": "display",
			"display_name": "畫面",
			"items": [
				{
					"key": "fullscreen",
					"label": "全螢幕",
					"type": 1,
					"default_value": false
				},
				{
					"key": "language",
					"label": "語言",
					"type": 2,
					"options": ["zh", "en", "ja"],
					"default_value": "zh"
				},
				{
					"key": "debug_mode",
					"label": "偵錯模式",
					"type": 1,
					"default_value": false,
					"platforms": ["debug"]
				},
				{
					"key": "windows_only",
					"label": "Windows 專屬",
					"type": 1,
					"default_value": false,
					"platforms": ["windows"]
				}
			]
		}
	]
}
```

### 不同類型設定項目範例

#### 滑桿類型

```json
{
	"key": "text_speed",
	"label": "文字速度",
	"type": 0,
	"min_value": 0.01,
	"max_value": 0.2,
	"step": 0.005,
	"default_value": 0.05
}
```

#### 開關類型

```json
{
	"key": "auto_mode",
	"label": "自動模式",
	"type": 1,
	"default_value": false
}
```

#### 選項類型

```json
{
	"key": "quality",
	"label": "畫面品質",
	"type": 2,
	"options": ["低", "中", "高", "極高"],
	"default_value": "中"
}
```

## 設定最佳實踐

1. **命名規範**
   - 使用小寫字母和下劃線命名 `id` 和 `key`
   - `display_name` 使用對使用者友善的名稱

2. **平台設定**
   - 對於通用設定，使用 `"platforms": ["all"]`
   - 對於平台特定設定，明確指定平台

3. **預設值**
   - 為所有設定項目提供合理的預設值
   - 確保預設值類型與設定類型相符

4. **組織方式**
   - 按功能將設定分組到不同分類
   - 保持分類數量合理，避免過多分類

5. **格式檢查**
   - 使用 JSON 驗證工具檢查設定檔格式
   - 確保所有必要屬性都已設置

## 注意事項

- 確保設定項目的 `key` 在分類內唯一
- 對於滑桿類型，確保 `min_value` < `max_value`
- 對於選項類型，確保 `options` 陣列不為空
- 設定檔變更後，需要重啟遊戲或呼叫 `rebuild()` 方法更新設定面板
