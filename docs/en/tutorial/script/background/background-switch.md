---
title: Background Switch
order: 1
---

# Background Switch

## Description
Switch the background image of the game scene, with support for transition effects.

## Syntax
```text
background [image resource name] <effect type>
```

## Parameters
| Parameter | Required | Example | Description |
|------|------|--------|------|
| Image resource name | Yes | `morning_forest` | Texture file name without extension |
| Effect type | No | `fade` | Transition effect (default: instant switch) |

### Supported Effect Types

The following background switching effects are supported. Each effect has its own visual style:

| Effect | Description |
|------|------|
| `none` | Instant switch |
| `fade` | Fade in/out |
| `erase` | Erase |
| `blinds` | Blinds |
| `wave` | Wave |
| `vortex` | Vortex |
| `windmill` | Windmill |
| `cyberglitch` | Cyber glitch |

If no effect type is specified, `none` (instant switch) is used by default.

## Examples
```text
# Switch from daytime to night (fade effect)
background night_street fade

# Battle scene switch (instant switch)
background battle_field none

# Memory scene (erase effect)
background memory_flash erase

# Dream scene (vortex effect)
background dream vortex
```
