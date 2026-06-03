---
title: Play Sound Effect
order: 3
---

# Play Sound Effect

## Overview
Used to play a specified sound effect file in a particular scene or interaction node, enhancing scene atmosphere and interaction feedback. Playing a sound effect is executed immediately and does not block subsequent script execution.

## Syntax
```
play sfx <sound effect name>
```

## Parameters
| Parameter | Required | Example | Description |
|------------|----------|--------------|--------------------------|
| Sound effect name | Yes | door_open | Identifier of the sound effect file to play |

## Code Examples
```
play sfx door_open
play sfx button_click
play sfx notification
```
