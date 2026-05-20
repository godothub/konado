---
title: Typewriter Sound Effect
order: 8
---

# Typing Sound Effect

## Overview

Konado's dialogue box component supports typewriter sound effects, playing a "click" sound while typing to enhance immersion and feedback.

## Sound Directory

Typewriter sound effect files are stored in the following directory:

```
res://addons/konado/audioeffect/typewriter/
```

## Supported Audio Formats

| Format | Description |
|--------|-------------|
| `.wav` | Uncompressed audio, recommended |
| `.ogg` | Ogg Vorbis compressed format |
| `.mp3` | MP3 compressed format |

## Basic Configuration

In the `KND_DialogueBox` component's Inspector panel, you can find the typewriter sound effect settings:

### Sound Toggle

```gdscript
@export var enable_typing_effect_audio: bool = true
```

Set to `true` to enable the typewriter sound effect, `false` to disable it.

### Audio Resource

```gdscript
@export var typing_effect_audio: AudioStream
```

Select a sound effect file from the editor dropdown menu, or load it via code:

```gdscript
# Set sound effect via code
dialogue_box.typing_effect_audio = load("res://addons/konado/audioeffect/typewriter/click.wav")
```

## Sound Trigger Configuration

### Trigger Probability

```gdscript
@export var audio_trigger_chance: float = 0.8
```

Controls the probability of triggering the sound effect, ranging from 0.0 to 1.0:

- `1.0` — Always plays
- `0.8` — 80% chance of playing (default)
- `0.5` — 50% chance of playing
- `0.0` — Never plays

### Play Interval

```gdscript
@export var min_audio_interval: float = 0.02   # Minimum interval (seconds)
@export var max_audio_interval: float = 0.08   # Maximum interval (seconds)
```

The random interval range for sound effect playback, used to match different typing rhythms:

- **Fast clicking**: Set a smaller interval, e.g. `0.02 – 0.05`
- **Slow typing**: Set a larger interval, e.g. `0.05 – 0.15`

After each playback, a new random interval value is generated between the minimum and maximum values.
