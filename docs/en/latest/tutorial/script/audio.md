---
title: Audio Events and Mixing
order: 10
---

# Audio Events and Mixing

## Overview

Since 2.9 an audio command in a script may reference an **audio event** (recommended) or keep
referencing a name from the legacy resource lists:

- An event (`KonadoAudioEvent`) maps one id to one or more streams and carries the bus, loop
  flag, fades, instance limit, priority and play conditions.
- Legacy lists (`background_music_list` / `sound_effect_list` / `voice_list`) still work: an
  event wins when the library has the id, otherwise the legacy stream is used.

Scripts treat both as "one name", so existing scripts keep running unchanged.

## Syntax

```text
play bgm <event_or_resource_name> [fade=<seconds>] [volume=<dB>]
play sfx <event_or_resource_name> [volume=<dB>] [count=<1-8>]
stop bgm [fade=<seconds>]
```

| Parameter | Commands | Meaning |
| --- | --- | --- |
| `fade` | `play bgm`, `stop bgm` | Crossfade duration in seconds. Defaults to the event's `fade_in` / `fade_out` |
| `volume` | `play bgm`, `play sfx` | dB offset on top of the event volume; negative values are allowed |
| `count` | `play sfx` | Repeat the trigger 1–8 times for layered effects |

`fade` cannot be negative and `count` cannot be below 1; out-of-range values fail at compile time.

## Example

```text
play bgm chapter_01 [fade=1.5]
Kona "The music faded in."

play sfx coin [volume=-2] [count=3]
Kona "Three coins, 2 dB below the default volume."

stop bgm [fade=2.0]
Kona "The music fades out over two seconds."
```

See `sample/demo/demo_09_audio.ks` for a runnable demo.

## Buses and volume

Konado ensures these buses exist at runtime (all routed to `Master`):

| Bus | Purpose |
| --- | --- |
| `Music` | Background music |
| `Ambience` | Ambience, mixed alongside music |
| `SFX` | Sound effects (voice pool) |
| `Voice` | Dialogue voice |
| `UI` | Interface sounds |

Player volume is written to the buses (`Master × category`) by the settings panel and is **no
longer stored in saves**, so loading a save never overrides the volume the player just set.

## Story variables driving audio (RTPC)

An event may carry any number of `KonadoAudioParameter` entries:

- `variable`: a `%persistent` or `$temporary` variable
- `gates_event`: skip the event entirely when the value is outside `minimum`–`maximum`
- `curve`: variable value → linear gain; without a curve the gain interpolates between
  `gain_floor` and `gain_ceiling`

When a script changes a variable through `set` / `add`, the new values are pushed to the audio
engine and playing music is retargeted immediately.

## Instances, stealing and cooldowns

| Field | Effect |
| --- | --- |
| `max_instances` | Concurrent instances of the same event (music/ambience are always 1) |
| `priority` | Compared when stealing; higher wins |
| `steal_policy` | `oldest`, `lowest_priority`, or `reject` |
| `cooldown` | Seconds during which a repeated trigger is ignored |

Ignored triggers never break the story: the runtime reports an `ignored` result instead of a failure.

## Voice

- Voice events also carry a `priority`; a higher-priority line may interrupt a lower one, while a
  lower-priority line is ignored.
- While a voice plays, `Music` is ducked by 6 dB by default (`duck_music_for_voice` /
  `voice_duck_db`), then released automatically.
- Rolling back never replays a voice line; `restore_policy` only affects music and ambience.

## Rollback and saves

Music and ambience store "event id + playback position":

| `restore_policy` | Behavior |
| --- | --- |
| `seek` (default) | Resume from the same position after rollback or load |
| `restart` | Restart from the beginning |
| `silent` | Do not restore (stay silent) |

One-shot `SFX` are never replayed on rollback, so stepping back does not fire them twice.

See [Audio Workflow](tutorial/core/audio-workflow.html) for the full pipeline (assets, banks, release checks).
