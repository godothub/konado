## 2.4.3 LTS - Macaron

Konado 2.4.3 is officially released. This version is a Long-Term Support (LTS) maintenance update for the 2.4 series. It focuses on editor interaction fixes, dialogue playback flow improvements, and sample asset completion, further improving out-of-the-box stability and usability.

### Fixes

#### Performance System

- Removed the ShaderMaterial from the scene and now dynamically creates and assigns it to the background node in the ready function. This unifies material initialization and prevents issues where the material is null and cannot be configured when the scene loads.


## 2.4.2 LTS - Macaron

Konado 2.4.2 is officially released. This version is a Long-Term Support (LTS) maintenance update for the 2.4 series. It focuses on editor interaction fixes, dialogue playback flow improvements, and sample asset completion, further improving out-of-the-box stability and usability.

### Fixes

#### Editor

- Fixed the KS editor display logic so it no longer leaves an abnormal blank area occupying the main screen.
- Fixed visibility control in the editor `_edit` method by using `ks_dock.make_visible()` instead of the incorrect `ks_editor.show()` approach.

#### Dialogue System

- Fixed dialogue manager autoplay logic by adjusting the execution flow after typewriter completion and moving `_process_next()` to the correct branch. This resolves incorrect flow jumps in scenes that do not wait for voice playback.
- Improved voice playback logic by refactoring `_play_voice` to return the audio duration, optimizing the timing coordination between autoplay and waiting for voice playback after typewriter completion.
- Fixed autoplay settings loading timing so settings are loaded during dialogue manager initialization instead of being read on demand at runtime.

### Improvements

#### Dialogue Manager

- Added exception handling for empty current dialogue to avoid blank dialogue causing the flow to stall.
- Optimized debug log output with clearer runtime status messages to make troubleshooting easier.

#### Samples and Assets

- Added the missing Demo scene voice list resource `voice_list.tres`, including sample voice entries.
- Renamed `new_resource.tres` to `character_list.tres` to standardize resource naming.
- Completed resource references for the character list, background list, BGM list, and voice list in the Demo scene.

### Compatibility Notes

- 2.4.2 continues the bottom Dock layout introduced in 2.4.1, but adjusts the visibility control logic.
- Godot 4.6.2 or later is recommended.


## 2.4.1 LTS - Macaron

Konado 2.4.1 is officially released. This version is a Long-Term Support (LTS) maintenance update for the 2.4 series. Compared with version 2.4.0, this update focuses on editor interface experience optimization and core functionality improvements, while comprehensively fixing various issues reported by the community, further enhancing stability and usability.

### Changes

- Added the KND_SettingsBridge settings bridge node for dialogue settings access.
- Added settings listener and settings button functionality to the dialogue manager.
- Integrated volume synchronization logic in the audio interface.

### Fixes

#### Editor

- Fixed theme and button styles, reset the editor position to the bottom, and allowed it to pop up freely for convenient simultaneous preview of game scenes and dialogue editing.
- Fixed the editor panel minimum height to 300px, ensuring the editor panel is visible during initialization.
- Fixed compatibility issues with Godot 4.6 API changes.

### Improvements

#### Themes, Samples, and Assets

- Added `NotoSansSC-VF.otf` and `ResourceHanRoundedCN-Medium.ttf` font files and corresponding SIL OFL license documents.
- Fixed font file paths in `left_theme.tres` and `middle_theme.tres` theme resources.

#### Documentation

- Added `.gdignore` configuration in the `docs` directory to prevent Godot from abnormally loading unnecessary documentation files.
- Updated documentation and syntax highlighter instructions.
- Optimized multilingual Konado project descriptions.

### Compatibility Notes

- 2.4.1 adjusts the editor panel position to the bottom. It is recommended to disable the old plugin version first, exit the project for a complete update, and then re-enable it to avoid cache issues.
- Due to Godot 4.6 API changes, older versions of Godot may not work properly and need to be upgraded to Godot 4.6 or later.
- Since new font files have been imported, if they do not take effect, it is recommended to delete the font resource cache files under the `.godot` directory.

## 2.4.0 LTS - Macaron

Konado 2.4.0 is a long-term support release. Compared with 2.3, this version focuses on the core dialogue flow, variable and save/load capabilities, reusable plugin ecosystem, template assets, and documentation system, bringing a major improvement in both functionality and stability.

### Highlights

- Added a complete variable system with persistent variables, temporary variables, variable interpolation, and conditional checks.
- Added a complete save/load system that can store dialogue state, variables, audio, actors, and background state.
- Added a fade-in typewriter text component with BBCode rich text support and GPU-accelerated per-character fade-in rendering.
- Added three standalone plugins: Konado Achievement, Konado Settings, and Konado WebTool.
- Reworked the documentation site into Chinese, English, and Traditional Chinese multilingual structures, with 2.4-related tutorials completed.
- Added the Graph Editor (Beta), which uses visual graph nodes to organize dialogue flow, branches, and jumps.

### Changes

#### Dialogue System and Script Capabilities

- Added the `addons/konado/graph_editor` graph editor module:
  - `knd_graph_edit.gd`: visual graph editor.
  - `knd_graph_node_factory.gd`: dialogue node factory.
  - `knd_graph_converter.gd`: converter between KS scripts and graph structures.
- Added `%variable_name` persistent variables and `$variable_name` temporary variables.
- Added variable operation statements: `set`, `add`, `sub`, `mul`, and `div`.
- Added dialogue text variable interpolation, allowing variables such as `%love` and `$score` to be displayed directly in dialogue lines.
- Added `if / else / endif` conditional branches with support for `==`, `!=`, `>`, `<`, `>=`, and `<=`.
- Improved choice and branch jumps, optimizing parsing and execution for `choice`, `branch`, and `jump_branch`.
- Added the custom signal instruction `signal <name>`, allowing dialogue scripts to trigger external game logic.
- Added achievement script instruction examples, including direct unlocks, counter progress, and flag conditions.
- Added background clearing.
- Added dialogue visibility checks.

#### Save System

- Added `KND_SaveSystem`, providing APIs such as `save_game()`, `load_game()`, `delete_save()`, and `get_save_info()`.
- Added `KND_SaveData`, which serializes dialogue, variables, audio, actors, background state, and save metadata in one structure.
- Added automatic save toggle and auto-save interval settings.
- Added save strategy configuration, allowing projects to choose whether to save dialogue state, variables, audio, actors, and background state.
- Updated the save UI component with support for save slots, saving, loading, deletion, and preview information.

#### Text Rendering and Audio

- Added the `KND_TypewriterText` fade-in typewriter text component.
- Added `typewriter_fade.gdshader`, using a CanvasItem shader for per-character fade-in rendering.
- Added BBCode parsing support for bold, italic, underline, strikethrough, color, and font size.
- Added multiline text fade-in support.
- Added documentation for typewriter sound effects.

#### Plugins

- Added the **Achievement System** plugin (`addons/konado_achievement`):
  - JSON-based achievement data configuration.
  - Support for direct unlocks, counters, flag conditions, and hidden achievements.
  - Achievement popup, achievement panel, progress statistics, and reset APIs.
  - Support for custom save/load backends and external platform SDK sync callbacks.
- Added the **Settings System** plugin (`addons/konado_settings`):
  - Dynamically generates settings panels from JSON configuration.
  - Built-in categories for audio, text playback, display, and more.
  - Support for sliders, toggles, option controls, and other UI items.
  - Support for filtering settings by platform and build type.
- Added the **WebTool** plugin (`addons/konado_webtool`):
  - Allows common browser shortcuts in Web exports.
  - Supports configurable F12, F5, F11, Ctrl/Cmd shortcut combinations, and more.

#### Templates, Samples, and Assets

- Added left-aligned and centered dialogue box and dialogue scene templates.
- Added `left_theme.tres` and `middle_theme.tres` theme resources.
- Added the complete variable system sample `sample/demo/demo_03_variable.ks`.
- Added the Konado 2.4 startup banner.
- Added Kona emoji GIF assets.
- Added updated character portrait assets and supporting materials for portrait import and cropping guides.
- Added Chinese font resources: `NotoSansSC-VF.otf` and `ResourceHanRoundedCN-Medium.ttf`.

### Documentation

- Reworked the VitePress documentation configuration and added the sidebar generation script `genSidebar.ts`.
- Added Chinese, English, and Traditional Chinese multilingual documentation structures.
- Added documentation for the achievement system, settings system, WebTool, and Konado .NET API.
- Added tutorials for the variable system, conditional branches, custom signals, typewriter effect, and typewriter sound effects.
- Added core tutorials for the save system, background transitions, script highlighting, logging, shots, and dialogue.
- Added community contribution, documentation contribution, feedback, resources, and join-us pages.
- Updated the version roadmap: 2.4 is codenamed Macaron and marked as LTS.

### Improvements

- Updated the main Konado plugin version to `2.4.0`.
- Refactored `KND_DialogueManager` and the KS interpreter to support variables, conditions, branches, and save state management.
- Improved integration between actor management and the save system.
- Improved actor layout logic so character images are positioned from their bottom anchor on grid positions.
- Improved highlighting logic and added BBCode syntax definitions.
- Improved move instructions and sample resources.
- Improved the Konado Settings panel UI and cleaned up redundant configuration.
- Updated the plugin author list.
- Updated README multilingual links and project description.
- Updated LICENSE copyright information.

### Fixes

- Fixed texture expand and stretch mode configuration in the character template.
- Fixed some documentation paths, image import paths, and sidebar generation configuration.

### Removed

- Removed old unused shots editor plugin files from the Inspector integration.
- Removed old actor scaling, mirroring, and vertical positioning parameters. Actor display and movement now use horizontal grid positions.
- Removed outdated documentation directories such as `docs/about`, old `docs/script`, and old `docs/tutorial`.
- Removed Spanish and French README links and their corresponding README files.
- Removed old `assets/kona/1.0` portrait assets.

### Compatibility Notes

- 2.4.0 changes the actor positioning model. Old scripts that rely on `actor show ... at <x> <y> scale <value> [mirror]` need to migrate to the new grid-based positioning approach.
- The variable system is split into persistent variables (`%`) and temporary variables (`$`). Persistent variables are included in save data, while temporary variables are only used in the current flow.
- WebTool is only enabled on the Web platform and does not inject browser shortcut handling logic on other platforms.
