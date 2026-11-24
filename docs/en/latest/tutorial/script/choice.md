---
title: Choice
order: 7
---

# Choice Jump

## Overview

This feature must be used together with the **branch feature**. It configures jump logic inside interactive options: clicking an option jumps to the specified branch. Each `choice` statement creates one option, and multiple adjacent `choice` lines are merged into one option group shown together.

An option can carry a **visibility condition** (`if`) and a **one-time flag** (`once`), which covers common needs such as "only show this when affection is high enough" or "ask this only once".

## Syntax

```text
choice "option text" -> branch_name [if %variable operator value] [once]
```

| Parameter | Required | Example | Description |
|------------|------|-----------------|--------------------------|
| Option text | Yes | `"Choose coffee"` | Option text shown during interaction |
| Branch name | Yes | `coffee_choice` | Unique identifier of the target branch |
| `if` condition | No | `if %love >= 5` | Show the option only when the condition holds |
| `once` | No | `once` | Hide the option after it has been picked |

`if` and `once` may appear in any order, but each at most once. Conditions support the same six comparison operators as `if` statements, and the value may be a number, string, boolean, or variable.

## Usage Examples

Each option can be written on its own line:

```text
choice "Green tea" -> green_tea
choice "Black tea" -> black_tea
```

Conditional and one-time options:

```text
choice "Give flowers (+10)" -> gift_flower
choice "Give a book (+5)" -> gift_book if %love >= 5
choice "(Asked before) Town rumor" -> rumor
choice "(Ask once) Mysterious merchant" -> merchant once
choice "Give nothing" -> gift_none
```

## Behavior

- **Condition is false**: the option is hidden. If no option in the group is available, execution continues with the statement after the choice group; an empty menu is never shown.
- **Missing or type-incompatible condition variable**: treated as false, with a single console warning instead of failing the shot.
- **`once` identity**: composed of the choice instruction's stable key, the target branch's stable key, and the option index. Translating or rewriting option text does not reset it; reordering options is treated as a different option.
- **Rollback and saves**: the usage record is runtime state, restored by "previous line", checkpoints, and saves; `init_dialogue()` clears it for a new game.
- **Named parameters**: group-level parameters such as `[id=...]` may only be written on the first option line.

## Notes

1. The branch name must exactly match a branch identifier in the script. It is case-sensitive and cannot contain spaces or special symbols.
2. Option text must be wrapped in English double quotes.
3. `->` is the separator between the option and the branch name and cannot be omitted.
4. `once` records the menu item, not the branch: options in different menus that target the same branch do not affect each other.
