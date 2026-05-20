---
title: Typewriter Effect
order: 7
---

# Typewriter Effect

## Overview

Konado provides a powerful typewriter effect component with GPU-accelerated character-by-character fade-in, bringing your game's dialogue to life.

## Core Features

- **GPU-accelerated rendering** — Uses a dedicated shader for per-character rendering with excellent performance
- **BBCode rich text support** — Supports bold, italic, colour, underline and strikethrough
- **Multiple fade-in directions** — Set fade-in direction at any angle
- **Spatial blend** — Mix character order and spatial order for fade-in effects
- **CJK multilingual support** — Full support for Chinese, Japanese, Korean and other multi-byte characters

## Basic Usage

### Using in a Dialogue Box

In the `KND_DialogueBox` component, you can enable the typewriter effect directly:

1. Select the `KND_DialogueBox` node in your scene
2. Find the relevant settings in the Inspector panel
3. Enable typewriter mode

### Using via Code

```gdscript
# Get the typewriter component
var typewriter = $KND_TypewriterText

# Set the text to display (supports BBCode)
typewriter.set_bbcode("[color=yellow]Hello[/color], [b]player[/b]!")

# Start the typewriter effect manually
typewriter.start()

# Skip the typewriter effect, show all text immediately
typewriter.skip()

# Reset, hiding all text
typewriter.reset()
```

## BBCode Rich Text

### Supported Tags

| Tag | Description | Example |
|-----|-------------|---------|
| `[b]` | Bold | `[b]bold text[/b]` |
| `[i]` | Italic | `[i]italic text[/i]` |
| `[u]` | Underline | `[u]underlined text[/u]` |
| `[s]` | Strikethrough | `[s]strikethrough text[/s]` |
| `[color=colour]` | Text colour | `[color=red]red text[/color]` |
| `[font=font]` | Specify font | `[font=my_font]custom font[/font]` |

### Colour Examples

```bbcode
[color=#FF5733]orange text[/color]
[color=green]green text[/color]
[color=#3498db]blue text[/color]
[color=yellow]yellow text[/color]
```

## Fade-in Effect Configuration

### Fade Angle

Sets the directional angle of character fade-in:

- `0°` — Left to right (default)
- `90°` — Top to bottom
- `-90°` — Bottom to top
- `180°` — Right to left
