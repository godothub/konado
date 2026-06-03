---
title: Typewriter Animation
order: 5
---

# Typewriter Effect

## Overview

Konado provides a powerful typewriter effect component. It supports GPU-accelerated per-character fade-in, making game dialogue more vivid and engaging.

## Core Features

- **GPU-accelerated rendering** - Uses a dedicated shader for per-character rendering with excellent performance
- **BBCode rich text support** - Supports bold, italic, color, underline, strikethrough, and more
- **Multiple fade directions** - Fade direction can be set to any angle
- **Spatial blending** - Can blend character order with spatial order for the fade effect
- **CJK multilingual support** - Fully supports multibyte characters such as Chinese, Japanese, and Korean

## Basic Usage

### Use in a Dialogue Box

In the `KND_DialogueBox` component, you can enable the typewriter effect directly:

1. Select the `KND_DialogueBox` node in the scene
2. Find the corresponding settings in the Inspector panel
3. Enable typewriter mode

### Use from Code

```gdscript
var typewriter = $KND_TypewriterText
typewriter.set_bbcode("[color=yellow]Hello[/color], [b]player[/b]!")
typewriter.start()
typewriter.skip()
typewriter.reset()
```

## BBCode Rich Text

| Tag | Description | Example |
|------|------|------|
| `[b]` | Bold | `[b]Bold text[/b]` |
| `[i]` | Italic | `[i]Italic text[/i]` |
| `[u]` | Underline | `[u]Underlined text[/u]` |
| `[s]` | Strikethrough | `[s]Struck text[/s]` |
| `[color=color]` | Text color | `[color=red]Red[/color]` |
| `[font=font]` | Specific font | `[font=my_font]Special font[/font]` |

```bbcode
[color=#FF5733]Orange text[/color]
[color=green]Green text[/color]
[color=#3498db]Blue text[/color]
[color=yellow]Yellow text[/color]
```

## Fade Configuration

- `fade_angle`: Direction angle. `0°` left to right, `90°` top to bottom, `-90°` bottom to top, `180°` right to left, or any custom angle.
- `spatial_blend`: Blend between character order and spatial order. `0.0` means character order, `0.5` mixed, `1.0` spatial order.
- `fade_width`: Controls softness. Larger values make edges softer.

## Signals

| Signal | Description |
|------|------|
| `typewriter_started` | Triggered when the typewriter effect starts |
| `typewriter_finished` | Triggered when the typewriter effect finishes |
| `typewriter_skipped` | Triggered when the effect is skipped |
| `character_revealed(index)` | Triggered when each character is shown; index is the character index |

```gdscript
func _ready():
    var typewriter = $KND_TypewriterText
    typewriter.typewriter_started.connect(_on_typewriter_started)
    typewriter.typewriter_finished.connect(_on_typewriter_finished)
    typewriter.character_revealed.connect(_on_character_revealed)

func _on_typewriter_started():
    print("Typewriter effect started!")

func _on_typewriter_finished():
    print("Typewriter effect finished!")

func _on_character_revealed(index: int):
    print("Character shown: ", index)
```

## API Reference

| Property | Type | Default | Description |
|------|------|--------|------|
| `bbcode_text` | String | "" | BBCode text to display |
| `font` | Font | null | Custom font |
| `font_size` | int | 20 | Font size |
| `font_color` | Color | WHITE | Text color |
| `chars_per_second` | float | 25.0 | Characters displayed per second |
| `fade_width` | float | 3.0 | Fade width |
| `fade_angle` | float | 0.0 | Fade angle in degrees |
| `spatial_blend` | float | 0.15 | Spatial blend ratio |
| `auto_start` | bool | true | Whether to start automatically |

| Method | Description |
|------|------|
| `start()` | Start the typewriter effect |
| `skip()` | Skip and show all text immediately |
| `reset()` | Reset and hide all text |
| `set_bbcode(text, autoplay)` | Set BBCode text |
| `is_playing()` | Whether it is playing |
| `is_finished()` | Whether it has finished |
| `get_progress()` | Get current progress |

## Advanced Usage

```gdscript
# Fast display
typewriter.chars_per_second = 100.0

# Slow typing for atmosphere
typewriter.chars_per_second = 5.0

# Custom fade
typewriter.fade_angle = 45.0
typewriter.fade_width = 5.0
typewriter.spatial_blend = 0.5
```

```gdscript
func _ready():
    var typewriter = $KND_TypewriterText
    typewriter.typewriter_finished.connect(_on_finished)

func _on_finished():
    # Run actions after typing completes
    show_continue_button()
```

## Performance Optimization

- Uses GPU shader rendering with excellent performance
- Supports large amounts of text without stuttering
- On mobile platforms, lowering `chars_per_second` appropriately is recommended

## Notes

1. **BBCode tags must be paired** - Each opening tag must have a corresponding closing tag
2. **Color values are customizable** - Hex colors such as `#FF5733` are supported
3. **Editor preview** - When running in the editor, all text is displayed directly for convenient preview
4. **Line breaks** - Use `\n` for line breaks
