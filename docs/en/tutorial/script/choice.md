---
title: Choice
order: 7
---

# Choice Jump

## Overview
This feature must be used together with the **branch feature**. Its core purpose is to configure jump logic inside interactive option tags. After the player clicks the corresponding option, the script can jump directly to the specified branch node. Each `choice` statement creates one option. Multiple adjacent `choice` lines are merged into one option group and shown together during interaction.

## Syntax

```
choice "option text" -> branch_name
```

| Parameter | Required | Example | Description |
|------------|------|-----------------|--------------------------|
| Option text | Yes | "Choose coffee" | Option text shown during interaction |
| Branch name | Yes | coffee_choice | Unique identifier of the target branch |

## Usage Examples

Each option can be written on its own line:

```
choice "Green tea" -> green_tea
choice "Black tea" -> black_tea
```

Multiple options can also be written continuously on one line:

```
choice "Green tea" -> green_tea "Black tea" -> black_tea
```

## Notes
1. The branch name must exactly match the branch identifier defined in the project. It is case-sensitive and cannot contain spaces or special symbols.
2. Option text must be wrapped in English double quotes and supports regular text characters.
3. `->` is the separator between the option and the branch name and cannot be omitted.
