---
title: API Usage
order: 3
---

# KND_AchievementManager API Reference

## Signals

The achievement system provides the following signals, which can be used to listen for achievement-related events and run custom logic:

### achievement_unlocked

**Signal signature:** `achievement_unlocked(achievement_id: String, data: Dictionary)`

**Triggered when:** Any achievement is unlocked

**Parameters:**
- `achievement_id`: ID of the unlocked achievement
- `data`: Full achievement data dictionary, including name, description, icon, and other information

**Use cases:** Run reward logic, play celebration animations, display custom notifications, and so on when an achievement is unlocked

**Example code:**
```gdscript
# Connect signal
KND_AchievementManager.achievement_unlocked.connect(_on_achievement_unlocked)

# Signal handler
func _on_achievement_unlocked(achievement_id: String, data: Dictionary) -> void:
    print("Achievement unlocked: " + data.get("name"))
    # Play achievement unlock sound effect
    # Display custom celebration animation
    # Give player rewards
```

### achievement_progress_updated

**Signal signature:** `achievement_progress_updated(achievement_id: String, current: float, target: float)`

**Triggered when:** An achievement progress value is updated

**Parameters:**
- `achievement_id`: ID of the achievement whose progress was updated
- `current`: Current progress value
- `target`: Target progress value

**Use cases:** Display achievement progress bars, provide progress feedback, update UI display, and so on

**Example code:**
```gdscript
# Connect signal
KND_AchievementManager.achievement_progress_updated.connect(_on_progress_updated)

# Signal handler
func _on_progress_updated(achievement_id: String, current: float, target: float) -> void:
    var progress_percentage = (current / target) * 100
    print("Achievement progress updated: " + achievement_id + " - " + str(progress_percentage) + "%")
    # Update UI progress bar
    # Display progress hint
```

### achievements_reset

**Signal signature:** `achievements_reset()`

**Triggered when:** All achievements are reset

**Parameters:** None

**Use cases:** Update UI after achievement reset, display reset notifications, perform cleanup operations, and so on

**Example code:**
```gdscript
# Connect signal
KND_AchievementManager.achievements_reset.connect(_on_achievements_reset)

# Signal handler
func _on_achievements_reset() -> void:
    print("All achievements have been reset")
    # Update achievement panel
    # Display reset notification
```

### achievements_loaded

**Signal signature:** `achievements_loaded()`

**Triggered when:** The achievement system finishes loading

**Parameters:** None

**Use cases:** Initialize UI after achievements finish loading, run logic that depends on achievement data, and so on

**Example code:**
```gdscript
# Connect signal
KND_AchievementManager.achievements_loaded.connect(_on_achievements_loaded)

# Signal handler
func _on_achievements_loaded() -> void:
    print("Achievement data loaded")
    # Initialize achievement panel
    # Run logic that depends on achievement data
```

## Core Methods

### Unlock Achievement

```gdscript
# Directly unlock an achievement by ID
KND_AchievementManager.unlock_achievement("achievement_id")
```

### Progress Management

```gdscript
# Increase counter value
KND_AchievementManager.increment_progress("counter_key", 1.0)

# Set flag value
KND_AchievementManager.set_flag("flag_key", true)
```

### Achievement Queries

```gdscript
# Check whether an achievement is unlocked
KND_AchievementManager.is_unlocked("achievement_id")

# Get data for a single achievement
KND_AchievementManager.get_achievement("achievement_id")

# Get all achievements
KND_AchievementManager.get_all_achievements()

# Get unlocked achievements
KND_AchievementManager.get_unlocked_achievements()

# Get locked achievements
KND_AchievementManager.get_locked_achievements()

# Get unlock percentage
KND_AchievementManager.get_unlock_percentage()
```

### Panel Management

```gdscript
# Show achievement panel
KND_AchievementManager.show_panel()

# Hide achievement panel
KND_AchievementManager.hide_panel()

# Toggle achievement panel visibility
KND_AchievementManager.toggle_panel()

# Check whether the panel is visible
KND_AchievementManager.is_panel_visible()
```

#### Reset Functions
```gdscript
# Reset all achievements
KND_AchievementManager.reset_all()

# Reset a single achievement
KND_AchievementManager.reset_achievement("achievement_id")
```
