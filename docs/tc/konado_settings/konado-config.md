---
title: 設定檔
order: 1
---

# 設定配置指南

## 設定檔結構

預設設定檔位於 `res://addons/konado_settings/resources/default_settings.json`，使用 JSON 格式定義設定項。

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

- **categories**：設定分類陣列，包含所有設定分類
- **id**：分類唯一識別符，用於程式中存取
- **display_name**：分類顯示名稱，在設定面板中顯示
- **items**：設定項陣列，包含該分類下的所有設定項
- **key**：設定項唯一識別符，在分類內必須唯一
- **label**：設定項顯示標籤，在設定面板中顯示
- **type**：設定類型：`0` 滑塊，`1` 開關，`2` 選項

### 類型特有屬性

- SLIDER：`min_value`、`max_value`、`step`、`default_value`（float）
- TOGGLE：`default_value`（bool）
- OPTION：`options`（Array[String]）、`default_value`（String，且必須存在於 options）
- 通用：`platforms`，空陣列或包含 `"all"` 表示所有平台可見

## 支援的平台標識

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
- `editor` - 編輯器構建

## 平台過濾規則

1. 空陣列：表示在所有平台可見
2. 包含 `"all"`：表示在所有平台可見
3. 特定平台：只在指定平台可見
4. 平台別名：`linuxbsd` 會匹配 Linux 或 BSD 平台
5. 構建類型：`debug` 和 `release` 依構建類型過濾

## 範例

### 滑塊類型

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

### 開關類型

```json
{
	"key": "auto_mode",
	"label": "自動模式",
	"type": 1,
	"default_value": false
}
```

### 選項類型

```json
{
	"key": "quality",
	"label": "畫面品質",
	"type": 2,
	"options": ["低", "中", "高", "極高"],
	"default_value": "中"
}
```

## 配置最佳實踐

1. `id` 和 `key` 使用小寫字母與底線命名。
2. `display_name` 使用對使用者友好的名稱。
3. 通用設定使用 `"platforms": ["all"]`。
4. 平台特定設定請明確指定平台。
5. 為所有設定項提供合理的預設值。
