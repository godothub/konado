---
title: Editing Audio in the Editor
order: 10
---

# Editing Audio in the Editor

## Folder layout

```text
res://audio/                     raw audio (loop flags live in the import panel)
res://audio/events/              one .tres per event (recommended)
res://audio/banks/               banks grouping events per chapter/locale
```

The `Konado Audio` dock scans `res://audio` and `res://events` for `.tres` files. Events stored
elsewhere still work — they simply do not show up in the dock list.

## Import settings

| Format | Recommendation |
| --- | --- |
| OGG | Enable `Loop` for BGM, keep it off for voice |
| WAV | Use for short effects; set `Loop Mode = Forward` when needed |
| MP3 | Avoid for BGM (silent padding breaks seamless loops) |

> Never mutate `loop` on an imported resource at runtime — the shared resource changes globally.
> Konado duplicates looping streams before enabling the loop flag.

## Creating an event

1. Right-click `res://audio/events` → New Resource → `KonadoAudioEvent`.
2. Set `id` (matching the file name is recommended; scripts use `play bgm <id>`).
3. Pick a `bus`: `Music` / `SFX` / `Voice` / `Ambience` / `UI`.
4. Drag audio into `streams`; with several streams set `container` to `random` or `sequence`
   to avoid machine-gun repetition.
5. Configure `loop`, `fade_in` / `fade_out`, `cooldown`, `max_instances`, `priority`,
   `steal_policy` and `restore_policy` as needed.

### Event inspector

Opening a `KonadoAudioEvent` adds a button row at the top of the inspector:

- **▶ Preview** — plays with the event's bus, volume, pitch and loop
- **■ Stop** — stops the preview
- **Copy ID** — copies the event id for pasting into a script

Below the buttons is a summary line (bus, stream count, duration, instances, priority, loop,
parameter count).

## Parameters (RTPC)

Add `KonadoAudioParameter` entries to the event's `parameters` array:

- `variable`: `%love`, `$tension`, ...
- `gates_event`: skip the event when the condition fails
- `minimum` / `maximum`: valid variable range
- `curve`: variable value → linear gain (without a curve the gain interpolates between
  `gain_floor` and `gain_ceiling`)

## The Konado Audio dock

The dock on the right side of the editor provides:

| Area | Function |
| --- | --- |
| Event tree | Events under `res://audio`, grouped by bank (unbanked events go to an "ungrouped" group) with bus/stream/instance/loop/parameter info |
| Search | Filter by event id |
| ▶ Preview / ■ Stop | Audition the selected event |
| Parameter slider | Simulate a variable value and see the resulting gain / gate state |
| Problems | Duplicate ids, missing streams, unsaved streams, invalid parameter variables |
| + Event | Create an empty event under `res://audio/events` and open it in the inspector |
| Library | Open `res://audio/audio_event_library.tres` in the inspector so banks can be dragged in |
| Import legacy lists | Select `background_music_list` / `sound_effect_list` / `voice_list` in the FileSystem and generate `res://audio/events/<id>.tres` |

Double-clicking an event opens it in the inspector. The dock listens to filesystem changes and
refreshes after you save a resource.

> If `audio_event_library` is not assigned on the manager, the controller still loads the
> convention path `res://audio/audio_event_library.tres`, so a library in the standard location
> never goes silent.

## Migrating legacy lists

1. Select the old BGM/SFX/Voice list resource(s) in the FileSystem.
2. Press **Import legacy lists** in the dock.
3. Generated events reference the existing streams (files are not copied) and reuse the names.
4. Legacy lists can be removed gradually; unmigrated entries still fall back to them at runtime.

The sample project is already migrated and can be used as a reference: `res://audio/events/*.tres`,
`res://audio/banks/demo_audio.tres`, `res://audio/audio_event_library.tres`, wired to the manager
in `sample/demo/demo.tscn`. See [Audio Workflow](tutorial/core/audio-workflow.html) for the full
pipeline.

## Troubleshooting

| Symptom | Cause |
| --- | --- |
| No events in the dock | The events are not under `res://audio` or `res://events` |
| No preview buttons | The editor plugin was not reloaded; reopen the editor or reload the plugin |
| No waveform for OGG/MP3 | Godot does not expose decoded samples; only duration and bus are shown |
| `play bgm` is silent | The event has no `streams`, or an RTPC condition fails (see the Problems list) |
