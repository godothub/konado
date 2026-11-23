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
| Command schema | 3 | 4 |
| Runtime state schema | 2 | 3 |

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
