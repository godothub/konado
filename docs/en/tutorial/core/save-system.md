---
title: Save System
order: 2
---

# Save System

## Usage

### Save Game

```gdscript
# Save to specified slot
dialogue_manager.save_game(1)  # Save to slot 1

# Or use the save system directly
save_system.save_game(2)  # Save to slot 2
```

### Load Game

```gdscript
# Load from specified slot
dialogue_manager.load_game(1)  # Load from slot 1

# Or use the save system directly
save_system.load_game(2)  # Load from slot 2
```

### Delete Save

```gdscript
# Delete the save in the specified slot
dialogue_manager.delete_save(1)  # Delete save in slot 1

# Or use the save system directly
save_system.delete_save(2)  # Delete save in slot 2
```

### Get Save Information

```gdscript
# Get save information for a specified slot
var save_info = dialogue_manager.get_save_info(1)
print("Save time: " + str(save_info.get("save_time", {})))

# Get all save information
var all_save_infos = dialogue_manager.get_all_save_info()
for i in range(all_save_infos.size()):
    if all_save_infos[i].get("exists", false):
        print("Save " + str(i) + " exists")
```

### Configure Save Strategy

```gdscript
# Custom save strategy
var custom_strategy = {
    "include_dialogue_state": true,    # Include dialogue state
    "include_variables": true,          # Include variables
    "include_audio_state": false,       # Do not include audio state
    "include_actor_state": false,       # Do not include actor state
    "include_background_state": false   # Do not include background state
}

dialogue_manager.set_save_strategy(custom_strategy)
```

## Save Data Structure

Save data contains the following:

- **dialogue_state** - Dialogue state, including current shot, dialogue index, and dialogue status
- **variables** - Game variables
- **audio_state** - Audio state (reserved)
- **actor_state** - Actor state (reserved)
- **background_state** - Background state (reserved)
- **save_time** - Save time
- **version** - Save version

## Save File Format

Save files are stored in JSON format under the `user://saves/` directory, with file names in the format `[slot ID].sav`.
