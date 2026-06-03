---
title: Typing Sound Effect
order: 6
---

# Typing Sound Effect

## Overview

The Konado dialogue box component supports typing sound effects. It can play short "click" sounds during typing to enhance immersion and feedback.

## Sound Effect Directory

Typing sound effect files are stored in:

```
res://addons/konado/audioeffect/typewriter/
```

## Supported Audio Formats

| Format | Description |
|------|------|
| `.wav` | Uncompressed audio, recommended |
| `.ogg` | Ogg Vorbis compressed format |
| `.mp3` | MP3 compressed format |

## Basic Configuration

In the Inspector panel of `KND_DialogueBox`, you can find typing sound effect settings:

```gdscript
@export var enable_typing_effect_audio: bool = true
@export var typing_effect_audio: AudioStream
```

Set `enable_typing_effect_audio` to `true` to enable typing sound effects, or `false` to disable them. Select an audio file from the editor dropdown, or load it from code:

```gdscript
dialogue_box.typing_effect_audio = load("res://addons/konado/audioeffect/typewriter/click.wav")
```

## Trigger Configuration

```gdscript
@export var audio_trigger_chance: float = 0.8
@export var min_audio_interval: float = 0.02
@export var max_audio_interval: float = 0.08
@export var audio_volumn: float = 0.6
```

- `audio_trigger_chance`: Trigger probability from 0.0 to 1.0. `1.0` always plays, `0.8` plays 80% of the time, `0.0` never plays.
- `min_audio_interval` / `max_audio_interval`: Random interval range between sound plays, used to fit different typing rhythms.
- `audio_volumn`: Sound effect volume from 0.0 to 1.0.

## Usage Example

1. Put sound files into `res://addons/konado/audioeffect/typewriter/`
2. Select the `KND_DialogueBox` node in the scene
3. Enable `Enable Typing Effect Audio` in the Inspector
4. Select the sound file from the dropdown
5. Adjust volume and other parameters

```gdscript
var dialogue_box = $KND_DialogueBox
dialogue_box.enable_typing_effect_audio = true
dialogue_box.typing_effect_audio = load("res://addons/konado/audioeffect/typewriter/my_click.wav")
dialogue_box.audio_trigger_chance = 1.0
dialogue_box.audio_volumn = 0.8
dialogue_box.min_audio_interval = 0.02
dialogue_box.max_audio_interval = 0.06
```

## Recommended Sounds

- **Typewriter clicks**: use small intervals such as `0.02 - 0.05`, with `audio_trigger_chance: 0.8`
- **Mechanical keyboard**: use `0.03 - 0.08`, with `audio_trigger_chance: 0.9`
- **Soft clicks**: use `0.05 - 0.12`, with `audio_trigger_chance: 0.7` and `audio_volumn: 0.5`

## Trigger Timing

Typing sounds trigger when the typing animation is playing, the random interval since the last sound has elapsed, the random probability check passes, and the text has not finished displaying.

## Notes and Optimization

1. Use English file names and avoid special characters.
2. Sound length is best kept under 0.1 seconds.
3. Keep typing sound volume balanced so it does not cover background music.
4. On mobile platforms, compressed formats such as ogg/mp3 are recommended to save space.
5. Use short sound files, preferably under 100 KB, and disable the feature with `enable_typing_effect_audio = false` when not needed.

## Troubleshooting

- If no sound plays, check `enable_typing_effect_audio`, `typing_effect_audio`, file path, and volume.
- If sounds are too dense, increase interval values or lower `audio_trigger_chance`.
- If sounds are too sparse, decrease interval values or increase `audio_trigger_chance`.
