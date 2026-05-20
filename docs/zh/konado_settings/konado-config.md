---
title: 配置文件
order: 1
---

# 设置配置指南

## 配置文件结构

默认设置配置文件位于 `res://addons/konado_settings/resources/default_settings.json`，使用 JSON 格式定义设置项。

### 基本结构

```json
{
	"categories": [
		{
			"id": "audio",
			"display_name": "音频",
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

## 配置说明

### 顶层结构

- **categories**：设置分类数组，包含所有设置分类

### 分类属性

- **id**：分类唯一标识符，用于程序中访问
- **display_name**：分类显示名称，在设置面板中显示
- **items**：设置项数组，包含该分类下的所有设置项

### 设置项属性

- **key**：设置项唯一标识符，在分类内必须唯一
- **label**：设置项显示标签，在设置面板中显示
- **type**：设置类型
  - `0`：滑块（SLIDER）
  - `1`：开关（TOGGLE）
  - `2`：选项（OPTION）

#### 滑块类型（SLIDER）特有属性

- **min_value**：最小值
- **max_value**：最大值
- **step**：步长
- **default_value**：默认值（float 类型）

#### 开关类型（TOGGLE）特有属性

- **default_value**：默认值（bool 类型）

#### 选项类型（OPTION）特有属性

- **options**：选项列表（Array[String]）
- **default_value**：默认值（String 类型，必须在 options 列表中）

#### 通用属性

- **platforms**：平台列表，空数组或包含 "all" 表示所有平台

## 支持的平台标识

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

## 平台过滤规则

1. **空数组**：表示在所有平台可见
2. **包含 "all"**：表示在所有平台可见
3. **特定平台**：只在指定的平台可见
4. **平台别名**：`linuxbsd` 会匹配 Linux 或 BSD 平台
5. **构建类型**：`debug` 和 `release` 根据构建类型过滤

## 示例配置

### 完整配置示例

```json
{
	"categories": [
		{
			"id": "audio",
			"display_name": "音频",
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
					"label": "音乐音量",
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
			"display_name": "画面",
			"items": [
				{
					"key": "fullscreen",
					"label": "全屏",
					"type": 1,
					"default_value": false
				},
				{
					"key": "language",
					"label": "语言",
					"type": 2,
					"options": ["zh", "en", "ja"],
					"default_value": "zh"
				},
				{
					"key": "debug_mode",
					"label": "调试模式",
					"type": 1,
					"default_value": false,
					"platforms": ["debug"]
				},
				{
					"key": "windows_only",
					"label": "Windows专属",
					"type": 1,
					"default_value": false,
					"platforms": ["windows"]
				}
			]
		}
	]
}
```

### 不同类型设置项示例

#### 滑块类型

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

#### 开关类型

```json
{
	"key": "auto_mode",
	"label": "自动模式",
	"type": 1,
	"default_value": false
}
```

#### 选项类型

```json
{
	"key": "quality",
	"label": "画面质量",
	"type": 2,
	"options": ["低", "中", "高", "极高"],
	"default_value": "中"
}
```

## 配置最佳实践

1. **命名规范**
   - 使用小写字母和下划线命名 `id` 和 `key`
   - `display_name` 使用用户友好的名称

2. **平台配置**
   - 对于通用设置，使用 `"platforms": ["all"]`
   - 对于平台特定设置，明确指定平台

3. **默认值**
   - 为所有设置项提供合理的默认值
   - 确保默认值类型与设置类型匹配

4. **组织方式**
   - 按功能将设置分组到不同分类
   - 保持分类数量合理，避免过多分类

5. **格式检查**
   - 使用 JSON 验证工具检查配置文件格式
   - 确保所有必需属性都已设置

## 注意事项

- 确保设置项的 `key` 在分类内唯一
- 对于滑块类型，确保 `min_value` < `max_value`
- 对于选项类型，确保 `options` 数组不为空
- 配置文件变更后，需要重启游戏或调用 `rebuild()` 方法更新设置面板
