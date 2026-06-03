---
title: Create Actor
order: 1
---

# Create Actor

## Description

Create an actor in the dialogue scene.

## Syntax

```text
actor show [character ID] [state] at [horizontal coordinate]
```

## Parameters

| Parameter | Required | Example | Description |
|------|------|------|------|
| Character ID | Yes | `alice` | Character resource identifier |
| State | Yes | `angry` | Portrait state |
| Horizontal coordinate | Yes | `2` | Horizontal position, expressed as a division index |

## Example
```text
# Show character
actor show alice normal at 2
```
