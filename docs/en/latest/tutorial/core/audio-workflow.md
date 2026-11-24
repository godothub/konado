---
title: Audio Workflow
order: 11
---

# Audio Workflow

This page covers the end-to-end flow from receiving audio files to shipping a build. For the
script syntax see [Audio Events and Mixing](tutorial/script/audio.html); for the editor controls
see [Editing Audio in the Editor](tutorial/core/audio-editor.html).

## 1. Roles and outputs

| Role | Owns | Output |
| --- | --- | --- |
| Audio designer | File standards, loudness, loop points, container splits | Audio and events under `res://audio/**` |
| Writer | Event ids, fades, volume offsets, conditional sounds | `play` / `stop` in `.ks` |
| Programmer | Library wiring, buses, rollback/save behavior | `audio_event_library` on scenes such as `demo.tscn` |
| QA | Auditioning, problem list, rollback and save regression | Accept/reject notes |

The migrated sample is the reference implementation: `res://audio/` (events, bank, library) and
`sample/demo/demo.tscn` (`audio_event_library` on the `KonadoDialogue` node).

## 2. Folders and naming

```text
res://audio/                          raw audio (loop flags live in the import panel)
res://audio/events/<id>.tres          one event per file
res://audio/banks/<name>.tres         banks grouped per chapter/locale
res://audio/audio_event_library.tres  the library the manager references
```

| Object | Convention | Example |
| --- | --- | --- |
| Event id | lower snake_case, no extension | `chapter_01`, `ui_click` |
| Bank name | `<chapter>_<purpose>` | `chapter_01_bgm`, `chapter_01_voice_zh` |
| Voice event | `<scene>_<index>`, aligned with the line id | `cafe_greeting_01` |
| File name | identical to the event id | `ui_click.tres` |

Only events under `res://audio` or `res://events` appear in the `Konado Audio` dock.

## 3. The flow

### 3.1 Import assets

1. Put audio under `res://audio/` (separate BGM / SFX / voice folders).
2. Import panel: enable `Loop` for BGM (OGG) or `Loop Mode = Forward` (WAV); never loop voice.
3. Normalize loudness (around -16 LUFS) so switching tracks does not jump in volume.
4. **Never** mutate the loop flag of an imported resource at runtime; Konado duplicates looping
   streams before enabling the loop.

### 3.2 Create the event

Checklist in the event inspector:

- [ ] `id` matches the file name
- [ ] `bus` is correct (Music / SFX / Voice / Ambience / UI)
- [ ] `streams` has at least one entry; multiple streams use `random` or `sequence`
- [ ] Music has `loop` plus `fade_in` / `fade_out`
- [ ] Effects set `max_instances`, `steal_policy`, `cooldown`
- [ ] Music/ambience set `restore_policy` (default `seek`)

### 3.3 Bind parameters (RTPC)

Audio that follows the story gets a `KonadoAudioParameter`:

```text
variable = "%love"
minimum = 0    maximum = 100
gain_floor = 0.85    gain_ceiling = 1.0
gates_event = false
```

- Enable `gates_event` when the sound should only exist while a condition holds.
- The engine is updated whenever a script runs `set` / `add`, so playing music retargets
  **without restarting**.

### 3.4 Create banks

1. Create a `KonadoAudioBank` named after the chapter.
2. Drag events into `events`; for voice banks fill `locale` (e.g. `zh`).
3. One voice bank per language: switching language only swaps voice banks, music keeps playing.

### 3.5 Wire the library

1. Create a `KonadoAudioEventLibrary` and drag banks into `banks`.
2. Assign it to `audio_event_library` on the dialogue manager (e.g. `KonadoDialogue` in
   `sample/demo/demo.tscn`).
3. With several chapters, use one library per chapter and swap the reference on chapter change.

> The legacy `background_music_list` / `sound_effect_list` / `voice_list` resources still work:
> an event id wins when the library has it, otherwise the legacy stream is used, so migration can
> be incremental.

### 3.6 Reference from scripts

```text
play bgm echo [fade=2.0]
play sfx ui_click [count=3] [volume=-4]
stop bgm [fade=2.0]
```

- Prefer configuring fades on the event and overriding them in the script only when needed.
- Re-playing the same event crossfades instead of hard-cutting.
- A missing event reports `audio.event_not_found` and shows up in the failure panel.

### 3.7 Audition and validate

1. Select the event and press **▶ Preview** in the inspector (uses the event bus/volume/pitch/loop).
2. In the `Konado Audio` dock drag the **parameter slider** to confirm gain and gate behavior.
3. Read the **Problems** list: duplicate ids, missing streams, unsaved streams, invalid variables.

### 3.8 Pre-release checks

```bash
# In the editor: Konado Audio → Refresh → the Problems list is empty
python tests/tools/repository_architecture_check.py
python .github/scripts/check_error_codes.py
python .github/scripts/check_doc_resource_paths.py docs/zh/latest docs/en/latest
godot --headless --path . --script tests/audio/test_audio_engine.gd
```

Regression focus:

- [ ] Stepping back restores the music position and does not replay voice
- [ ] Loading a save keeps the player's current volume settings
- [ ] Switching language swaps voice but never interrupts music
- [ ] Rapid sound effects overlap and respect instance limits/stealing

## 4. Runtime contracts

| Item | Contract |
| --- | --- |
| Volume | Stored on the `Music/SFX/Voice/Ambience/UI` buses, never in saves |
| Music state | "Event id + playback position"; rollback follows `restore_policy` |
| One-shot effects | Never replayed on rollback |
| Voice | Higher priority interrupts lower; music ducks by 6 dB while playing |
| Banks | Currently grouping/validation units; events load with the library |

## 5. Troubleshooting

| Symptom | Look at |
| --- | --- |
| `play bgm` is silent | Event has no `streams`; RTPC gate fails; manager has no `audio_event_library` |
| Plays only once | `loop` is off, or `max_instances`/`cooldown` blocked the repeat |
| Audible gap between tracks | Both script and event set `fade=0`; use a 0.5–2 s crossfade |
| Effects cut each other off | The legacy list path has a single player; use events with a higher `max_instances` |
| Volume changes after loading | Still using the legacy list path or a custom state capture |
| Dock shows no events | Events are outside `res://audio` / `res://events` |
| No preview buttons | The editor plugin was not reloaded; reopen the editor |

## 6. Definition of Done

- [ ] Every new sound has an event whose id matches the file name
- [ ] The event is in a bank and the bank is wired into the library
- [ ] Music has fades; effects have instance limits and cooldowns
- [ ] Voice events are split per language with `locale` filled in
- [ ] The dock Problems list is empty
- [ ] Rollback / save / language-switch regression passed

## 7. Not available yet

- On-demand bank loading with reference counting (events load with the library today)
- Music segments and beat-synced transitions (`AudioStreamInteractive` + BPM)
- Mix snapshot commands (`audio state`)
- Waveform preview in the editor (OGG/MP3 expose no decoded samples, only duration)

Until these exist, approximate them with multiple events, RTPC bindings and fades.
