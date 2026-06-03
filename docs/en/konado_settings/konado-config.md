---
title: Configuration File
order: 1
---

# Settings Configuration Guide

## Configuration File Structure

The default settings configuration file is located at `res://addons/konado_settings/resources/default_settings.json` and uses JSON to define settings.

### Basic Structure

```json
{
	"categories": [
		{
			"id": "audio",
			"display_name": "Audio",
			"items": [
				{
					"key": "master_volume",
					"label": "Master Volume",
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

## Configuration Description

- **categories**: Array of setting categories containing all setting groups
- **id**: Unique category identifier used by code
- **display_name**: Category display name shown in the settings panel
- **items**: Array of settings under the category
- **key**: Unique setting identifier inside the category
- **label**: Display label shown in the settings panel
- **type**: Setting type: `0` slider, `1` toggle, `2` option

### Type-Specific Properties

- SLIDER: `min_value`, `max_value`, `step`, `default_value` (float)
- TOGGLE: `default_value` (bool)
- OPTION: `options` (Array[String]), `default_value` (String and must exist in options)
- Common: `platforms`; empty array or `"all"` means visible on all platforms

## Supported Platform Identifiers

- `all` - All platforms
- `android` - Android
- `bsd` - BSD
- `linux` - Linux
- `macos` - macOS
- `ios` - iOS
- `visionos` - visionOS
- `windows` - Windows
- `linuxbsd` - Linux or BSD
- `debug` - Debug build
- `release` - Release build
- `editor` - Editor build

## Platform Filtering Rules

1. Empty array: visible on all platforms
2. Contains `"all"`: visible on all platforms
3. Specific platform: visible only on that platform
4. Platform alias: `linuxbsd` matches Linux or BSD
5. Build type: `debug` and `release` are filtered by build type

## Examples

### Slider

```json
{
	"key": "text_speed",
	"label": "Text Speed",
	"type": 0,
	"min_value": 0.01,
	"max_value": 0.2,
	"step": 0.005,
	"default_value": 0.05
}
```

### Toggle

```json
{
	"key": "auto_mode",
	"label": "Auto Mode",
	"type": 1,
	"default_value": false
}
```

### Option

```json
{
	"key": "quality",
	"label": "Graphics Quality",
	"type": 2,
	"options": ["Low", "Medium", "High", "Ultra"],
	"default_value": "Medium"
}
```

## Best Practices

1. Use lowercase letters and underscores for `id` and `key`.
2. Use user-friendly names for `display_name`.
3. Use `"platforms": ["all"]` for common settings.
4. Clearly specify platforms for platform-specific settings.
5. Provide reasonable default values for all settings.
