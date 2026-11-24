---
title: Upgrade to 2.9
order: 4
---

# Upgrade to 2.9

Konado 2.9 adds `call` / `return` subroutines and conditional / one-time choices (`choice ... if` / `once`), and **drops compatibility with 2.8 saves and previously exported script data**.

## Incompatibilities

| Item | 2.8 | 2.9 |
| --- | --- | --- |
| Compiler ABI | `konado-2.8` | `konado-2.9` |
| Command schema | 3 | 5 |
| Runtime state schema | 2 | 4 |

- 2.8 `.kns` saves are rejected explicitly ("存档格式与 Konado 2.9 不匹配") instead of loading with empty state.
- Script data exported by 2.8 (encrypted `.res` or compiled data inside a PCK) no longer matches the ABI and must be re-exported.
- 2.9 ships no save-conversion tool; settle or migrate player progress inside a 2.8 build if you need it.

## Upgrade steps

1. Replace the old plugin directories with the complete 2.9 set and reopen Godot so `.ks` files recompile.
2. Re-export the game; swapping the plugin inside an already shipped build is not supported.
3. Make sure every script that uses `choice` / `call` recompiles without diagnostics.

## New syntax at a glance

```text
call common_scene
return

choice "Option" -> branch_name if %love >= 5
choice "Ask once" -> branch_name once
```

See "Subroutine Calls (call / return)" and "Choice" for details.

## Audio in 2.9

2.9 rebuilds audio around events: bus mixing, music crossfades, a sound-effect voice pool,
automatic voice ducking, and RTPC (story variables driving gain). Scripts only add named
parameters to the existing commands:

```text
play bgm chapter_01 [fade=1.5] [volume=-3]
play sfx coin [volume=-2] [count=3]
stop bgm [fade=2.0]
```

- Legacy `background_music_list` / `sound_effect_list` / `voice_list` resources keep working:
  an event id wins when the library has it, otherwise the legacy stream is used.
- Saves no longer store player volumes; volume lives on the `Music/SFX/Voice` buses, so
  loading a save never overwrites the player's settings.
- See `tutorial/core/audio-editor.html` for the event and bank authoring workflow.
