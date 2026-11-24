---
title: Subroutine Calls (call / return)
order: 9
---

# Subroutine Calls (call / return)

## Overview

`call` runs a `branch` in the current script as a subroutine: control enters the branch and returns to the statement after the `call` when it reaches `return`.

- Unlike `jump_branch`, a `call` remembers its return address on a call stack.
- Unlike `jump`, a `call` stays inside the same shot. `jump` switches shots and discards pending call frames; cross-script calls are not supported yet.
- The call stack is runtime state: it is saved, restored, and rolled back together with the rest of the execution state.
- Recursive calls (direct or indirect) are rejected at compile time, and the call chain is capped at 256 levels.
- `return` with an empty call stack behaves like `end`: it finishes the current shot.

## Syntax

```text
call <branch_name>
return
```

## Parameters

| Parameter | Required | Example | Description |
|-----------|----------|---------|-------------|
| branch_name | Yes | `gift_scene` | A branch declared in the current script |

## Example

```text
call gift_scene
Kona "Back at the call site."

branch gift_scene
	Kona "This is a shared scene."
	return
```

Nested calls:

```text
call chapter_intro

branch chapter_intro
	Kona "The chapter starts."
	call phone_ring
	Kona "The chapter ends."
	return

branch phone_ring
	Kona "The phone rings."
	return
```

## How a called branch ends

- An explicit `return` is the clearest option: control goes back to the call site.
- Falling off the end of a branch connects to the compiler-generated `halt`, which finishes the whole shot. **Prefer an explicit `return` in every called branch.**

## Notes

1. The target must be a branch in the current script; use `jump` for another script.
2. Recursive calls (including mutual recursion) fail to compile.
3. `jump` discards pending call frames; do not rely on `return` across shots.
4. `call` and `return` work inside choices, branches, and conditional blocks.
5. The runtime failure panel offers retry/stop for `call`, never skip: skipping would enter a branch without a return frame.
