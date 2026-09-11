## 2.8.1 - Nanguoli

### Feature Updates

- Added a Backlog panel to the default dialogue template for reviewing dialogue, choices, and full-screen text
- Added support for stepping back to the previous line or clicking a history entry to return to that point in the story, resume playback, or choose a different branch
- Added stable error IDs for actor, background, audio, camera, script, variable, compilation, resource, and achievement failures
- Error reports identify the failing function, file, resource, and script line; single-line compilation now also preserves the source path to help locate problems
- Added `KonadoResult` to represent successful data and structured errors consistently, making execution results easier for callers to handle

### Bug Fixes

- Fixed `actor move` failing to save the new character position, which caused save/load and rollback to restore the wrong position
- Fixed an engine error when looking up a stage actor with an empty actor name

## 2.8.0 - Nanguoli

### New Features

- Added named parameters for per-line typewriter speed and actor, background, and camera transition durations
- Unified dialogue syntax for static actors, actor variables, and interpolated text labels
- Added stable instruction IDs, execution history, checkpoints, and rollback APIs

### Improvements

- Rebuilt the KonadoScript compiler and runtime for more reliable nested conditions, branches, and cross-script jumps
- Significantly reduced memory usage and improved runtime performance for large scripts, with time-sliced execution for exceptionally long runs
- Improved cancellation and state handling so stopped or replaced asynchronous commands cannot leave stale work behind
- Adopted Godot's native `TranslationServer` and `.po` resources so locale selection, UI translation, and story localization share one locale state
- Fixed screen text remaining visible after its final line or a shot replacement and covering later story content
- Simplified Godot's Create New Node list by hiding template-only implementation nodes
- Fixed Konado.NET activation and completed the localized API documentation
- Improved compiler diagnostics and standardized plugin structure and naming

## 2.7.4 - Wontons

### Bug Fixes

- Fixed achievement panels, settings panels, and system messages potentially being obscured by the dialogue UI
- Fixed the achievement panel being impossible to close while paused and failing to restore keyboard focus after closing
- Fixed `KonadoCamera2D` target markers potentially taking over the active camera and offsetting complex background transitions
- Fixed `hidetextbox` retaining the previous line and potentially flashing it the next time the dialogue box is shown
- Fixed static portraits flashing or unexpectedly exposing the background during state blending
- Fixed invalid, asynchronous, superseded, or actor-exit state requests potentially desynchronizing visuals and persisted data or leaving story execution waiting
- Fixed invalid custom character scenes or motion layers replacing the active actor setup
- Fixed custom character scenes receiving their initial state before layout and out-of-bounds portraits being clipped during state blending
- Fixed repeated requests to an actor's in-progress destination potentially advancing the story before movement completed

### Other Improvements

- Added configurable layers for the achievement panel and unlock notifications, and documented the built-in UI layer contract
- Added explicit `dismiss_dialogue_box*()` APIs for hiding the dialogue box and clearing its content
- Added premultiplied-alpha blending for static portraits with safe fading for dynamic and complex custom scenes
- Expanded runtime regression coverage for achievement UI and camera targets in complex backgrounds

## 2.7.3 - Wontons

### Bug Fixes

- Fixed complex backgrounds rendering incorrectly during built-in transitions
- Fixed stale tasks potentially continuing after a background transition was cancelled or replaced
- Fixed KonadoScript diagnostic popups flickering and making action buttons difficult to click

### Other Improvements

- Made full-scene capture the default for background transitions, with an optional `DIRECT_TEXTURE` fast path for static backgrounds
- Improved the audio playback API documentation

## 2.7.2 - Wontons

### Bug Fixes

- Fixed an erroneous runtime warning when falling back to the default KonadoScript because no localized script is available for the current locale
- Fixed a new shot briefly showing the previous speaker and text while its dialogue box fades in
- Fixed shots without an explicit `end` entering the off state without full cleanup or a `shot_end` signal
- Fixed autoplay timers, command completion signals, choice callbacks, and camera animations from a stale node or previous shot advancing or affecting current playback
- Fixed repeated starts and stops, including stops made from a `shot_end` handler, potentially running lifecycle operations more than once
- Fixed replacing or stopping a shot from dialogue, audio, variable, achievement, or cleanup signal handlers potentially allowing the previous playback flow to continue, overwrite replacement state, or prevent the replacement shot from stopping
- Fixed runtime locale changes potentially re-running the active command, binding duplicate completion callbacks, emitting a false typing-completion event, or stalling when the localized script lacks the current node ID
- Fixed interrupted voice playback emitting a stale completion event after a later voice finishes, playback start failures waiting indefinitely, and repeated BGM playback accumulating loop callbacks; clarified `play_voice()` as non-blocking and added `play_voice_and_wait()` to distinguish natural completion from interruption
- Fixed stale animations clearing or interfering with replacement screen text, including after a runtime locale change
- Fixed `dialogue_line_end` being emitted early or more than once when skipping the typewriter animation, and its callbacks being able to re-enter the same advance
- Fixed disabling autoplay potentially advancing the current dialogue

## 2.7.1 - Wontons

### Bug Fixes

- Fixed `InitDialogue()` replacing the shot selected by `SetShot()`, aligning the GDScript and Konado.NET shot lifecycles
- Reworked dialogue-box visibility state management so fades, `hidetextbox`, and dialogue restarts reliably restore visible text
- Fixed consecutive lines not updating an already visible dialogue box, along with stale text-node and typing-audio state after interrupted transitions
- Fixed stale typing-completion callbacks after stopping or reinitializing dialogue, plus leaked fallback background nodes and disabled typing-audio players
- Fixed fade typewriter skipping potentially emitting its completion signal more than once

### Other Improvements

- Added runtime regression coverage for both typewriter modes, immediate and animated visibility changes, consecutive lines, shot switching, and dialogue restarts
- Updated the Konado.NET sample and localized API documentation to clarify the `SetShot()`, `InitDialogue()`, and `StartDialogue()` lifecycle

## 2.7 - Wontons

### Editor

- Integrated `.ks` files into Godot's native Script workspace with a component tree, locale switching, and versioned online documentation
- Added a shared semantic model and incremental project index for highlighting, diagnostics, completion, hover help, navigation, outlines, reference search, and safe rename
- Integrated formatting, diagnostic hover fixes, project-symbol navigation, and rollback-safe project rename directly into the active Script Editor
- Added KonadoScript breakpoint debugging with source navigation, variable inspection, continue, step, and pause-at-next-line controls
- Improved parser recovery, atomic saving, and automated coverage, fixing live-analysis stalls, compiler bounds errors, and camera-transition inconsistencies

### Security

- Added transparent script protection that encrypts compiled KonadoScript data with AES-256
- Added independently derived encryption and authentication keys, authenticated metadata, integrity verification, and a decompression size limit for encrypted payloads
- Added exported-package runtime verification to ensure all sample scripts are encrypted, loadable, and free of directly readable story plaintext

### Other Improvements

- Standardized the `KonadoScript` product name
- Updated documentation and showcase workflows to Node.js 24
- Removed the duplicated title from the MulanPSL 2.0 license text

## 2.6.1 - Ketchup

### Camera and Acting

- Added the non-blocking `asyncam` command with `move`, `reset`, `shake`, and `stop` operations, allowing camera animation and dialogue playback to run concurrently
- Added configurable actor background tint blending based on the active background scene
- Added smooth fade-out, state-change, and fade-in transitions for `actor change`, which can be configured or disabled in `KND_ActingInterface`
- Added cancellation and completion handling for overlapping or invalid actor state changes so dialogue flow cannot remain blocked

### Internationalization

- Rebuilt `KND_I18n` as a runtime service that centrally manages UI translations, locale persistence, localized `.ks` lookup, and dialogue reload notifications
- Added `KND_LocaleCatalog` to centrally manage built-in and custom locales, normalize locale codes, and migrate legacy locale values
- Added `KND_LocalizedScriptLoader` with sequential fallback through the full locale code, base language, and original script file
- Added stable dialogue position restoration by `node_id` when switching languages at runtime

### Konado.NET

- Added `InternationalizationAPI` for locale switching, locale normalization, translation registration, and localized script loading from C#
- Expanded `DialogueManagerAPI` with explicit lifecycle binding, typed signals, save/load access, localized script reload, and wait-signal forwarding
- Added CI tests for Konado.NET

### Other Improvements

- Extracted dialogue runtime responsibilities into dedicated services and added safe fallbacks when optional systems are unavailable
- Hardened actor, background, audio, typewriter, achievement, settings, web tool, and editor integration lifecycles
- Aligned Konado.NET wrappers with their GDScript resource contracts and allowed wrappers to accept GDScript resource subclasses
- Raised the supported Godot baseline and all official build/test images to Godot 4.7.1
- Added checks for GDScript linting and formatting, GDScript runtime architecture, Konado.NET compilation and runtime behavior, plugin metadata, resource boundaries, and documentation resource paths
- Excluded tests, skills, and editor-only Konado resources from release packages
- Added pull-request commit identity checks that reject prohibited AI attribution email addresses
- Removed the scheduled daily-build workflow and its prerelease publishing path
- Updated the 2.6 documentation and synchronized localization terminology, examples, demo resources, and GodotHub image links across languages
- Added documentation for asynchronous camera operations, actor state fade transitions, runtime story localization, and the updated Konado.NET APIs
- Removed the obsolete Konado.NET `DialogueActor` wrapper in favor of direct resource-backed dialogue properties

### Bug Fixes

- Fixed inconsistent localized demo script structures so all bundled languages now use the same dialogue structure and stable node identifiers
- Fixed legacy locale values such as `zh-TW`, `zh-CN`, and `tc` by migrating them to canonical locale codes when read
- Fixed actor state transitions that could duplicate visual nodes, lose the original alpha, apply a superseded state, or complete more than once
- Fixed actor and background transition failure paths so invalid resources safely release dialogue flow
- Fixed a mismatch between the default actor background tint intensity and its configured behavior
- Fixed save writes to use temporary and backup files, preventing incomplete writes from overwriting valid save data
- Fixed settings persistence so in-memory values are committed only after the configuration is written successfully
- Fixed KS parsing and analysis for malformed statements, actor command arguments, and conditional branch control flow

## 2.6 - Ketchup

Konado 2.6, codenamed Ketchup, strengthens real-time presentation and scripting. It adds camera controls, character entrance and exit animations, runtime internationalization, full-screen NVL text, dialogue box visibility controls, the ability to wait for external signals, and the Konado Showcase page.

### Added

#### Camera System

- Added the `cam move`, `cam reset`, and `cam shake` commands for script-level camera control
- Added the `KonadoCameraManager` node to manage multiple camera targets and transitions
- Added configurable durations to `cam shake`
- Added tween type and duration parameters for smooth camera transitions

#### Character Animation System

- Refactored the character animation system and added slide-in entrance and exit animations
- Added the `enter_exit_anim_config.gd` resource for configuring entrance and exit durations and easing curves
- Centralized character animation logic in `animated_actor_layer.gd`

#### NVL Screen Text (Overlay Text)

- Added the `screentext` command for full-screen NVL text
- Added the `KND_ScreenText` scene and component with line-by-line fade-in animation
- Rendered each line in a separate `RichTextLabel`, with configurable line spacing and left and top margins
- Added a blinking triangle indicator after each completed line to prompt the player to advance
- Added signals such as `display_finished` for seamless integration with dialogue flow

#### Dialogue Box Visibility

- Added the `showtextbox` command with a configurable fade-in duration
- Added the `hidetextbox` command with a configurable fade-out duration
- Allowed a duration of `0.0` to show or hide the dialogue box immediately
- Added `show_dialogue_box_with_duration()` and `hide_dialogue_box_with_duration()` to `KND_DialogueBox`

#### Waiting for External Signals

- Added the `waitsignal` command to pause dialogue flow until a specified external signal is received
- Added `emit_wait_signal(signal_name: String)` so external code can resume the dialogue
- Supports cutscenes, minigames, custom interactions, and similar use cases

#### Runtime Internationalization

- Added initial runtime script internationalization support, enabling languages to be switched during gameplay
- Added the `KND_I18n` internationalization service node with registration and translation APIs
- Added support for loading localized dialogue resources in the dialogue manager

#### Voice and Audio

- Added a voice playback progress indicator to the dialogue box
- Added the `voice_progress_display.tscn` template scene
- Added an option on the dialogue box node to disable the progress indicator

#### Documentation and Showcase

- Added a Konado Showcase page generator that automatically collects and displays games made with Konado

#### Other

- Adopted multiple licenses for the project and updated the documentation
- Changed the `middle` theme to inherit from the `default` scene, correcting its inheritance hierarchy

### Syntax Changes

- **New `screentext` command**: display full-screen NVL text
  ```ks
  screentext {
      "This is the first line of full-screen text"
      "This is the second line"
  }
  ```

- **New `showtextbox` / `hidetextbox` commands**: control dialogue box visibility
  ```ks
  showtextbox 1.0    # Show dialogue box with 1s fade-in animation
  hidetextbox 0.5    # Hide dialogue box with 0.5s fade-out animation
  showtextbox 0.0    # Disable animation, show instantly
  ```

- **New `waitsignal` command**: wait for an external signal
  ```ks
  waitsignal "over"        # Wait for signal named "over"
  waitsignal minigame_done # Identifier form
  ```

- **Extended `cam` command**: add camera shake
  ```ks
  cam shake          # Shake with default duration
  cam shake 2.0      # Shake for 2 seconds
  cam move target linear 1.0  # Linear transition over 1 second
  cam reset ease_in_out 2.0   # Ease-in-out transition over 2 seconds
  ```

### Fixed

- Fixed the node path used by the main menu's Quit button outside the editor
- Fixed the `middle` theme's inheritance from the default theme

### Improvements

- Centralized the character animation logic to make the system easier to extend
- Made the voice progress indicator optional to suit different project requirements
- Automated Konado Showcase generation to reduce community maintenance

### Compatibility Notes

- Godot 4.7 or later is recommended
- Direct upgrades from 2.4 to 2.6 are not supported; migrate the project instead
- Runtime internationalization requires additional `KND_I18n` node configuration and remains optional

## 2.5 - Diguoji

Konado 2.5, codenamed Diguoji, rounds out the game flow and improves the developer experience. It adds Quick Save and Quick Load, a main menu, scene-based characters, background transitions, a VS Code syntax-highlighting extension, and an editor skill package.

### Added

#### Save System

- Added Quick Save and Quick Load buttons to the dialogue templates
- Marked slot 0 as the quick-save slot in the save UI
- Added `_on_quick_save_pressed()` and `_on_quick_load_pressed()` to the dialogue manager
- Added a confirmation dialog before Quick Load to prevent accidental loss of unsaved progress
- Added lightweight toast notifications for save and load results

#### Game Interface

- Added a main menu (`main.tscn`) with Start Game, Load Game, Settings, and Quit buttons
- Added a themed background and consistent button styling to the main menu
- Automatically hid the Quit button on the Web platform

#### Character System

- Added optional scene-based character portraits, allowing character scenes to use any node type
- Added the `motion` command for performing stage actions
- Added custom animation support to `ActorMotionLayer`, including a sample animation
- Centralized motion logic in `actor_motion_layer` instead of hardcoding animations

#### Background System

- Converted backgrounds to scenes, allowing shaders to be used in them
- Added the `blink` background transition
- Added the `demo_06_bg_effects.ks` background-transition demo and supporting images
- Added warnings for invalid background transitions

#### Development Tools

- Added a VS Code extension that provides syntax highlighting for `.ks` files
- Added VS Code workspace extension recommendations in `.vscode/extensions.json`
- Improved the internal configuration of the KS syntax extension
- Added the Konado DSL editor skill package (`skills/konado-script`)
- Added `.marketplace.json` to register the `konado-script-skill` plugin and its skill paths

#### Documentation

- Added documentation for the scene-based architecture
- Added versioned documentation structure
- Updated README documentation links and embedded contributor information

#### Syntax Changes

- **New `actor motion` command**: perform character stage actions
  ```ks
  # Execute built-in motions
  actor motion Kona shake
  actor motion Kona jump
  actor motion Kona bounce
  
  # Motions defined in AnimationPlayer within actor_motion_layer.tscn
  ```

- **Simplified `actor show` command**: removed the redundant `y`, `scale`, and `mirror` parameters
  ```ks
  # 2.5 syntax (simplified)
  actor show Kona 正常 at 3
  
  # Old syntax (removed)
  # actor show Kona 正常 at 2 5 scale 0.3 mirror
  ```

- **`actor change` command**: change a character's state or expression
  ```ks
  actor change Kona 害羞
  actor change Kona 惊讶
  ```

- **Extended background transitions**: added the `blink` effect
  ```ks
  background bg1 fade    # Fade in/out
  background bg1 windmill # Windmill effect
  background bg1 blink    # Blink effect (new)
  ```

- **Repeated `actor show` support**: reuse an existing character node and switch it to a new state
  ```ks
  actor show Kona 正常 at 3
  actor show Kona 害羞 at 2  # Reuse node, change state and position
  ```

### Fixed

- Fixed an error when closing the achievement UI
- Fixed conditional-branch cleanup after `continue`, which could prevent `if` branches from jumping correctly
- Fixed unstable selection behavior in the version switcher
- Fixed repeated `actor show` statements so they reuse the existing node and apply the new state
- Fixed waiting for the actor's `shown` signal
- Fixed batch updates to actor stage positions
- Fixed the variable-system demo becoming unable to continue

### Improvements

- Expanded the documentation with Quick Save and Quick Load instructions
- Reworked the plugin README with supported editor versions and clearer installation steps
- Improved command descriptions in the KS syntax extension README
- Added the 2.5 documentation branch to the documentation site's version configuration
- Removed the redundant `y` coordinate and simplified character positioning
- Updated the demo scene, scripts, assets, and `.gitignore`
- Added the Tripo logo to the acknowledgements
- Added the game "雨夜重逢" and the Akonado fork to the community projects list

### Removed

- Removed support for switching expressions with images; character scenes are now required
- Removed support for the legacy image format; state changes are now handled in scenes

### Compatibility Notes

- Godot 4.7 or later is recommended
- 2.5 introduces a new main menu scene; configure it as the project's startup scene where appropriate
- Backgrounds and character portraits are now scene-based; legacy image formats must be migrated to scene resources
- Character positioning now uses horizontal grid positions only; the redundant `y` parameter has been removed

## 2.4.5 LTS - Macaron

Konado 2.4.5 is an LTS maintenance release for the 2.4 series. It rebuilds the KS compilation pipeline and adds practical editor tooling.

### Added

#### KS Compiler

- Rebuilt the KS compiler as a complete pipeline with a lexer, parser, semantic analyzer, and emitter
- Added editor tooltips for KS files showing the line count, dialogue count, and character dependencies

### Removed

- Removed the unused `konado_dialogue.tscn` scene left over from the 2.3 dialogue system

### Compatibility Notes

- Use the new `knd_dialogue_box_middle.tscn` and `knd_dialogue_box_left.tscn` templates in place of the removed legacy dialogue scene. Projects that depend on the old scene may break, so back them up before upgrading and migrate any missing scene references
- Godot 4.6.2 or later is recommended

## 2.4.4 LTS - Macaron

Konado 2.4.4 is an LTS maintenance release for the 2.4 series. It fixes option parsing in the KS interpreter, including option display and branch targets.

### Fixed

#### KS Interpreter

- Removed the legacy 2.3 syntax that allowed multiple options on one line. The unsupported `choice "text1" -> tag1 "text2" -> tag2` form must now be written as separate `choice "text" -> tag` lines
- Added a post-processing step that resolves branch option `next_id` values from labels to node IDs, fixing failed jumps from options inside branches
- Fixed consecutive `choice` lines inside branches so they are combined into one option node instead of displaying only one option

### Added

#### Samples and Assets

- Added `demo_choice_test.ks`, covering multiple main-flow options, options inside branches, and nested option jumps

### Compatibility Notes

- 2.4.4 requires one option per line. Existing scripts with multiple options on one line must split them across separate lines; this is a breaking syntax change
- Godot 4.6.2 or later is recommended

## 2.4.3 LTS - Macaron

Konado 2.4.3 is an LTS maintenance release for the 2.4 series, improving editor interaction, dialogue playback, and bundled sample assets.

### Fixed

#### Acting System

- Removed the `ShaderMaterial` from the scene and created it dynamically in `_ready()` before assigning it to the background node. This centralizes material initialization and prevents null-material errors during scene loading.


## 2.4.2 LTS - Macaron

Konado 2.4.2 is an LTS maintenance release for the 2.4 series, improving editor interaction, dialogue playback, and bundled sample assets.

### Fixed

#### Editor

- Fixed the KS editor occupying the main workspace with a blank panel
- Fixed visibility handling in `_edit()` by replacing the incorrect `ks_editor.show()` call with `ks_dock.make_visible()`

#### Dialogue System

- Fixed autoplay after typewriter completion by moving `_process_next()` to the correct branch, preventing incorrect advancement when voice playback is not awaited
- Refactored `_play_voice()` to return the audio duration, coordinating autoplay with voice completion after the typewriter finishes
- Loaded autoplay settings when the dialogue manager initializes instead of reading them on demand

### Improvements

#### Dialogue Manager

- Added a guard for an empty current dialogue so blank dialogue cannot stall the flow
- Improved debug logging with clearer runtime state messages

#### Samples and Assets

- Added the missing `voice_list.tres` resource and sample voice entries to the demo
- Renamed `new_resource.tres` to `character_list.tres`
- Completed the demo's references to its character, background, BGM, and voice lists

### Compatibility Notes

- 2.4.2 retains the bottom dock layout introduced in 2.4.1 but changes its visibility handling
- Godot 4.6.2 or later is recommended


## 2.4.1 LTS - Macaron

Konado 2.4.1 is an LTS maintenance release for the 2.4 series. Compared with 2.4.0, it improves the editor experience and core functionality while addressing issues reported by the community.

### Changes

- Added the `KND_SettingsBridge` node to expose dialogue settings
- Added settings change listeners and a Settings button to the dialogue manager
- Added volume synchronization to the audio interface

### Fixes

#### Editor

- Fixed theme and button styling, moved the editor panel to the bottom dock, and made it detachable so the game preview and dialogue editor can remain visible together
- Set the editor panel's minimum height to 300 px so it remains visible when initialized
- Updated the editor for Godot 4.6 API changes

### Improvements

#### Themes, Samples, and Assets

- Added the `NotoSansSC-VF.otf` and `ResourceHanRoundedCN-Medium.ttf` fonts and their SIL OFL license files
- Fixed font paths in `left_theme.tres` and `middle_theme.tres`

#### Documentation

- Added `docs/.gdignore` to keep Godot from importing documentation files
- Updated the documentation and syntax-highlighter instructions
- Improved the multilingual Konado project descriptions

### Compatibility Notes

- 2.4.1 moves the editor panel to the bottom dock. To avoid stale editor caches, disable the old plugin, close the project, update it fully, and then re-enable the plugin
- Godot 4.6 or later is required because of upstream API changes
- If the new fonts do not appear, delete the cached font resources under `.godot`

## 2.4.0 LTS - Macaron

Konado 2.4.0 is a long-term support release. Compared with 2.3, it significantly expands and stabilizes the core dialogue flow, variable and save systems, reusable plugin ecosystem, templates, and documentation.

### Highlights

- Added a complete variable system with persistent variables, temporary variables, variable interpolation, and conditional checks.
- Added a complete save and load system for dialogue state, variables, audio, actors, and backgrounds.
- Added a fade-in typewriter text component with BBCode rich text support and GPU-accelerated per-character fade-in rendering.
- Added three standalone plugins: Konado Achievement, Konado Settings, and Konado WebTool.
- Reworked the documentation site with Simplified Chinese, English, and Traditional Chinese editions, including the 2.4 tutorials.
- Added a node-based graph editor (Beta) for organizing dialogue flow, branches, and jumps.

### Changes

#### Dialogue System and Script Capabilities

- Added the `addons/konado/graph_editor` module:
  - `knd_graph_edit.gd`: visual graph editor.
  - `knd_graph_node_factory.gd`: dialogue node factory.
  - `knd_graph_converter.gd`: converter between KS scripts and graph structures.
- Added `%variable_name` persistent variables and `$variable_name` temporary variables.
- Added variable operation statements: `set`, `add`, `sub`, `mul`, and `div`.
- Added dialogue text variable interpolation, allowing variables such as `%love` and `$score` to be displayed directly in dialogue lines.
- Added `if / else / endif` conditional branches with support for `==`, `!=`, `>`, `<`, `>=`, and `<=`.
- Improved the parsing and execution of choices and branch jumps for `choice`, `branch`, and `jump_branch`.
- Added the custom signal command `signal <name>` so dialogue scripts can trigger external game logic.
- Added achievement command examples for direct unlocks, counter progress, and flag conditions.
- Added background clearing.
- Added dialogue visibility checks.

#### Save System

- Added `KND_SaveSystem`, providing APIs such as `save_game()`, `load_game()`, `delete_save()`, and `get_save_info()`.
- Added `KND_SaveData`, which serializes dialogue, variables, audio, actors, background state, and save metadata in one structure.
- Added an autosave toggle and configurable autosave interval.
- Added options controlling whether dialogue state, variables, audio, actors, and backgrounds are included in saves.
- Updated the save UI with save slots, save, load, delete, and metadata preview support.

#### Text Rendering and Audio

- Added the `KND_TypewriterText` fade-in typewriter text component.
- Added `typewriter_fade.gdshader`, which uses a `CanvasItem` shader for per-character fade-in rendering.
- Added BBCode parsing support for bold, italic, underline, strikethrough, color, and font size.
- Added multiline text fade-in support.
- Added typewriter sound-effect documentation.

#### Plugins

- Added the **Achievement System** plugin (`addons/konado_achievement`):
  - Configures achievement data through JSON.
  - Supports direct unlocks, counters, flag conditions, and hidden achievements.
  - Provides achievement popups, an achievement panel, progress statistics, and reset APIs.
  - Supports custom save and load backends and synchronization callbacks for external platform SDKs.
- Added the **Settings System** plugin (`addons/konado_settings`):
  - Generates settings panels dynamically from JSON.
  - Includes built-in categories for audio, text playback, display, and more.
  - Supports sliders, toggles, option selectors, and other UI controls.
  - Supports filtering settings by platform and build type.
- Added the **WebTool** plugin (`addons/konado_webtool`):
  - Preserves common browser shortcuts in Web exports.
  - Supports configurable F12, F5, F11, and Ctrl/Cmd key combinations.

#### Templates, Samples, and Assets

- Added left-aligned and centered dialogue box and dialogue scene templates.
- Added `left_theme.tres` and `middle_theme.tres` theme resources.
- Added the complete variable system sample `sample/demo/demo_03_variable.ks`.
- Added the Konado 2.4 startup banner.
- Added Kona reaction GIFs.
- Added updated character portraits and guide assets for importing and cropping portraits.
- Added Chinese font resources: `NotoSansSC-VF.otf` and `ResourceHanRoundedCN-Medium.ttf`.

### Documentation

- Reworked the VitePress configuration and added the `genSidebar.ts` sidebar generator.
- Added Simplified Chinese, English, and Traditional Chinese documentation.
- Added documentation for the achievement system, settings system, WebTool, and Konado .NET API.
- Added tutorials for the variable system, conditional branches, custom signals, typewriter effect, and typewriter sound effects.
- Added core tutorials covering the save system, background transitions, script highlighting, logging, shots, and dialogue.
- Added pages for community and documentation contributions, feedback, resources, and joining the community.
- Updated the roadmap to mark 2.4, codenamed Macaron, as an LTS release.

### Improvements

- Updated the main Konado plugin version to `2.4.0`.
- Refactored `KND_DialogueManager` and the KS interpreter to support variables, conditions, branches, and saved dialogue state.
- Improved integration between actor management and the save system.
- Improved actor layout so portraits are bottom-aligned at their grid positions.
- Improved highlighting logic and added BBCode syntax definitions.
- Improved movement commands and sample assets.
- Improved the Konado Settings panel UI and cleaned up redundant configuration.
- Updated the plugin author list.
- Updated the README's multilingual links and project description.
- Updated the copyright information in `LICENSE`.

### Fixes

- Fixed texture expansion and stretch-mode settings in the character template.
- Fixed documentation paths, image import paths, and sidebar generation settings.

### Removed

- Removed unused legacy shot-editor files from the Inspector plugin.
- Removed legacy actor scaling, mirroring, and vertical-position parameters. Actor display and movement now use horizontal grid positions.
- Removed outdated documentation directories such as `docs/about`, old `docs/script`, and old `docs/tutorial`.
- Removed Spanish and French README links and their corresponding README files.
- Removed old `assets/kona/1.0` portrait assets.

### Compatibility Notes

- 2.4.0 changes the actor positioning model. Scripts that use `actor show ... at <x> <y> scale <value> [mirror]` must migrate to the new grid-based positioning.
- The variable system distinguishes persistent variables (`%`) from temporary variables (`$`). Persistent variables are saved; temporary variables exist only for the current dialogue flow.
- WebTool is enabled only on the Web platform and does not install browser shortcut handling on other platforms.
