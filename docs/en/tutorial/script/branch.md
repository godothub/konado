---
title: Branch
order: 4
---

# Branch

## Description

A branch is a way to organize script content. Branches make it easy to manage and call different parts of a script and are used to implement complex jump logic. This feature is usually used together with choices.

You can think of a label as a "bookmark" in the script. A label lets you quickly locate a specific position in the script. The content wrapped by the label and its indentation is the label content. This part of the script is added to the dialogue list when the current label dialogue is executed; otherwise, it is only stored in the label dialogue and does not trigger playback.

Branches cannot be nested. The indentation level of a branch must match the indentation level of dialogues, otherwise it will not be recognized correctly. The following is an incorrect example:

```text
# Incorrect example
branch drink_water
    "kona" "I want to drink water"
        branch eat_cake
            "kona" "I want to eat cake"
branch drink_tea
    "kona" "I want to drink tea"
```

## Syntax
```text
branch [label ID]
    [script content]
```

## Parameters
| Parameter | Required | Example | Description |
|------|------|------|------|
| Label ID | Yes | `drink_water` | Label identifier |

## Example

```text
branch drink_water
    "kona" "I want to drink water"
branch drink_tea
    "kona" "I want to drink tea"
```
