---
title: API Usage
order: 2
---

# Konado Settings API Documentation

## Settings Manager (KND_Settings)

The settings manager is an autoloaded singleton that manages all setting items.

### Signal

#### `setting_changed(category: String, key: String, value: Variant)`
- **Description**: Emitted when a setting value changes.
- **Parameters**:
  - `category`: Setting category.
  - `key`: Key of the setting item.
  - `value`: New setting value.

### Methods

#### `get_setting(category: String, key: String) -> Variant`
- **Description**: Gets the current value of a setting.
- **Parameters**:
  - `category`: Setting category.
  - `key`: Key of the setting item.
- **Return value**: The setting value. If it does not exist, returns the default value or null.

#### `set_setting(category: String, key: String, value: Variant) -> void`
- **Description**: Updates a setting, persists it, and emits the change signal.
- **Parameters**:
  - `category`: Setting category.
  - `key`: Key of the setting item.
  - `value`: New setting value.

#### `register_category(cat: SettingCategory) -> void`
- **Description**: Registers an additional setting category at runtime.
- **Parameters**:
  - `cat`: The setting category to register.

#### `reset_category(category_id: String) -> void`
- **Description**: Resets all settings in the specified category to their default values.
- **Parameters**:
  - `category_id`: Category ID.

#### `get_categories() -> Array`
- **Description**: Gets all registered categories, filtered for the current platform.
- **Return value**: The filtered category array.

#### `get_category(id: String) -> SettingCategory`
- **Description**: Gets a single category by ID, filtered for the current platform.
- **Parameters**:
  - `id`: Category ID.
- **Return value**: The filtered category object.

## Setting Category (SettingCategory)

A setting category groups related setting items together.

### Properties

- **id: String**: Unique identifier of the category.
- **display_name: String**: Display name of the category.
- **items: Array[SettingItem]**: Array of setting items contained in the category.

### Example

```gdscript
var video_cat = SettingCategory.new()
video_cat.id = "video"
video_cat.display_name = "Video"

# Add setting item
video_cat.items.append(resolution_item)

# Register category
KND_Settings.register_category(video_cat)
```

## Setting Item (SettingItem)

A setting item is a single configurable unit.

### Enum

#### `Type`
- **SLIDER (0)**: Slider type, used for numeric adjustment.
- **TOGGLE (1)**: Toggle type, used for boolean values.
- **OPTION (2)**: Option type, used for drop-down selection.

### Properties

- **key: String**: Unique identifier of the setting item.
- **label: String**: Display label of the setting item.
- **type: Type**: Type of the setting item.
- **min_value: float**: Minimum slider value, only for SLIDER items.
- **max_value: float**: Maximum slider value, only for SLIDER items.
- **step: float**: Slider step, only for SLIDER items.
- **options: Array[String]**: Option list, only for OPTION items.
- **platforms: Array[String]**: Platform filter. An empty array means visible on all platforms.
- **default_value: Variant**: Default value. SLIDER uses float, TOGGLE uses bool, and OPTION uses String.

### Examples

#### Create a Slider Setting Item

```gdscript
var volume_item = SettingItem.new()
volume_item.key = "master_volume"
volume_item.label = "Master Volume"
volume_item.type = SettingItem.Type.SLIDER
volume_item.min_value = 0.0
volume_item.max_value = 1.0
volume_item.step = 0.01
volume_item.default_value = 1.0
volume_item.platforms = ["all"]
```

#### Create a Toggle Setting Item

```gdscript
var fullscreen_item = SettingItem.new()
fullscreen_item.key = "fullscreen"
fullscreen_item.label = "Fullscreen"
fullscreen_item.type = SettingItem.Type.TOGGLE
fullscreen_item.default_value = false
```

#### Create an Option Setting Item

```gdscript
var language_item = SettingItem.new()
language_item.key = "language"
language_item.label = "Language"
language_item.type = SettingItem.Type.OPTION
language_item.options = ["zh", "tc", "en", "ja", "ko"]
language_item.default_value = "zh"
```

## UI Factory (UIFactory)

The UI factory creates controls for setting items.

### Method

#### `create_control(cat_id: String, item: SettingItem, callback: Callable) -> HBoxContainer`
- **Description**: Creates and returns a row (HBoxContainer) for the given setting item.
- **Parameters**:
  - `cat_id`: Category ID.
  - `item`: Setting item.
  - `callback`: Callback function in the format `callback(category_id: String, key: String, value: Variant)`.
- **Return value**: The created HBoxContainer.

### Example

```gdscript
var row = UIFactory.create_control("audio", volume_item, func(category, key, value):
	print("Setting changed: %s/%s = %s" % [category, key, value])
	KND_Settings.set_setting(category, key, value)
)

# Add to container
vbox_container.add_child(row)
```

## Settings Panel (SettingsPanel)

The settings panel is a visual interface for displaying and managing settings.

### Properties

- **_tab_container: TabContainer**: Tab container used to display settings from different categories.
- **btn_reset: Button**: Restore defaults button.
- **btn_close: Button**: Close button.

### Method

#### `rebuild() -> void`
- **Description**: Rebuilds the UI. Useful after registering a new category.

### Signals

- **btn_reset.pressed**: Emitted when the restore defaults button is clicked.
- **btn_close.pressed**: Emitted when the close button is clicked.

### Example

```gdscript
# Load the settings panel scene
var settings_panel = preload("res://addons/universal_settings/scenes/settings_panel.tscn").instantiate()
add_child(settings_panel)

# Show the settings panel
settings_panel.show()

# Rebuild the panel after registering a new category
KND_Settings.register_category(new_category)
settings_panel.rebuild()
```

## Platform Detection

The settings system automatically detects the current runtime platform and filters displayed items according to each setting item's `platforms` property.

### Platform Identifiers

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

### Platform Detection Logic

1. First checks whether the game is running in the editor.
2. Uses `OS.has_feature()` to detect the specific platform.
3. Sets the current platform identifier based on the detection result.
4. Filters setting items by platform when categories are retrieved.

## Persistent Storage

Setting values are automatically saved to `user://knd_settings.cfg` using Godot's `ConfigFile` format.

### Save Timing

- When `set_setting()` is called.
- Setting values are automatically written to the configuration file.

### Load Timing

- When the plugin is initialized.
- Saved setting values are automatically loaded from the configuration file.

## Complete Usage Examples

### 1. Basic Usage

```gdscript
# Get a setting value
var master_volume = KND_Settings.get_setting("audio", "master_volume")

# Set a value
KND_Settings.set_setting("audio", "master_volume", 0.8)

# Listen for setting changes
KND_Settings.setting_changed.connect(func(category, key, value):
	if category == "audio" and key == "master_volume":
		# Handle volume changes
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(value))
)
```

### 2. Register New Settings at Runtime

```gdscript
# Create a new setting category
var video_cat = SettingCategory.new()
video_cat.id = "video"
video_cat.display_name = "Video"

# Create setting item
var resolution_item = SettingItem.new()
resolution_item.key = "resolution"
resolution_item.label = "Resolution"
resolution_item.type = SettingItem.Type.OPTION
resolution_item.options = ["1280x720", "1920x1080", "2560x1440"]
resolution_item.default_value = "1920x1080"

# Add to category
video_cat.items.append(resolution_item)

# Register category
KND_Settings.register_category(video_cat)

# Rebuild the settings panel if it is already visible
if settings_panel:
	settings_panel.rebuild()
```

### 3. Custom Settings Panel

```gdscript
# Create a custom settings panel
var panel = CanvasLayer.new()

# Create tab container
var tab_container = TabContainer.new()
tab_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
tab_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
panel.add_child(tab_container)

# Build settings UI
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

# Add to scene
add_child(panel)
```

## Notes

- All API calls should be made after the game has started.
- After registering a new category, call `rebuild()` to update the settings panel.
- Platform filtering only affects whether setting items are displayed. It does not affect storage of setting values.
- Each setting item's `key` must be unique within its category.
- For OPTION items, the default value must exist in the `options` list.

## Error Handling

- If a setting item does not exist, `get_setting()` returns null and emits a warning.
- If the configuration file format is invalid, a warning is emitted and default values are used.
- If platform detection fails, the platform defaults to `all`.

## Performance Considerations

- The settings system uses lazy loading and parses the configuration file only when needed.
- Platform filtering is performed when categories are retrieved and does not affect setting value access performance.
- UI creation is on demand. Controls are created only when the settings panel is displayed.

## Extension Suggestions

1. **Add a new setting type**:
   - Add a new enum value to `SettingItem.Type`.
   - Add the corresponding creation logic in `UIFactory`.

2. **Customize the storage method**:
   - Modify `_load_saved()` and `set_setting()` in `settings_manager.gd`.
   - Implement custom save and load logic.

3. **Add setting validation**:
   - Add value validation logic in `set_setting()`.
   - Ensure setting values stay within valid ranges.

4. **Add internationalization support**:
   - Modify how `display_name` and `label` are processed.
   - Support multilingual settings interfaces.
