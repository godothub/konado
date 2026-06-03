---
title: Variable System
order: 8
---

# Variable System

## Feature Overview

The variable system lets you define, read, modify, and check variables in scripts, enabling dynamic dialogue text, conditional branches, and state tracking. Variable values can be referenced directly in dialogue text, and they can also be used as conditions to control the story flow.

There are two kinds of variables:

| Type | Prefix | Lifetime | Persistence | Initialization |
|------|--------|----------|-------------|----------------|
| Persistent variable | `%` | Preserved across shots | Saved with save data | Preset in the inspector / initialized in code |
| Temporary variable | `$` | Valid only in the current shot | Not saved | Initialized with `set` in scripts |

---

## Variable Operations

Five basic operations are supported. The syntax is:

```
<operation> <variable_name> <value>
```

You can also write it with an equals sign:

```
<operation> <variable_name> = <value>
```

### Operation List

| Operation | Description | Example |
|-----------|-------------|---------|
| `set` | Sets the variable value | `set %love = 10` |
| `add` | Addition; numeric addition or string concatenation | `add %love 5` |
| `sub` | Subtraction | `sub %love 3` |
| `mul` | Multiplication | `mul %love 2` |
| `div` | Division; reports an error when dividing by zero | `div %love 4` |

### Parameters

| Parameter | Required | Example | Description |
|-----------|----------|---------|-------------|
| Operation | Yes | `set` | One of the five operations |
| Variable name | Yes | `%love` | `%` starts a persistent variable, `$` starts a temporary variable |
| Value | Yes | `10` | Integer, float, boolean (`true`/`false`), or string wrapped in double quotes |

### Examples

```
set %love = 10
add %love 5
sub %love 3
mul %love 2
div %love 4

set $round = 1
add $round 1

set %player_name "Player"
set $stage "Starter Village"
set %unlocked true
```

---

## Variable Interpolation

Use `%variable_name` or `$variable_name` directly in dialogue text to reference a variable value. At runtime, it is replaced with the actual value.

### Syntax

```
"Character Name" "Dialogue text containing %variable_name or $variable_name"
```

### Examples

```
set %player_name "Alex"
set $stage "Starter Village"

"Kona" "Hello, %player_name! You are now in $stage."
"Kona" "Your affection is %love, and this is round $round."
```

Runtime output:

```
Kona: "Hello, Alex! You are now in Starter Village."
Kona: "Your affection is 12, and this is round 2."
```

---

## Conditional Checks

Use `if` / `else` / `endif` blocks to decide which dialogue to play based on variable values. Six comparison operators are supported.

### Syntax

```
if <variable_name> <operator> <value>:
    <dialogue content>
else:
    <dialogue content>
endif
```

The `else:` block is optional. If it is omitted and the condition is false, the whole `if` block is skipped.

### Supported Operators

| Operator | Description | Example |
|----------|-------------|---------|
| `==` | Equal to | `if %love == 5:` |
| `!=` | Not equal to | `if %love != 10:` |
| `>` | Greater than | `if %love > 3:` |
| `<` | Less than | `if %love < 10:` |
| `>=` | Greater than or equal to | `if %love >= 5:` |
| `<=` | Less than or equal to | `if %love <= 5:` |

### Parameters

| Parameter | Required | Example | Description |
|-----------|----------|---------|-------------|
| Variable name | Yes | `%love` | Persistent variable with `%` or temporary variable with `$` |
| Operator | Yes | `==` | One of the six comparison operators |
| Value | Yes | `5` | Integer comparison value |

### Examples

```
if %love == 5:
    "Kona" "Affection is exactly 5!"
else:
    "Kona" "Affection is not 5."
endif

if $score >= 80:
    "Kona" "Good!"
endif

if $score >= 60:
    "Kona" "Passed."
endif
```

### Notes

1. `if` / `else` / `endif` must use the same indentation level as their surrounding context.
2. Conditional checks **do not support nesting**. An `if` block cannot contain another `if`.
3. Multiple independent conditions should use flat `if` / `endif` structures instead of nesting.
4. Conditional checks can be used inside `branch` blocks.

---

## Using Conditions Inside Branches

A `branch` block can contain `if` / `endif` conditional checks, allowing dynamic dialogue inside a branch.

### Example

```
branch after_choice
    "Kona" "Your choice has been recorded."

    if $choice_made == 1:
        "Kona" "You chose to give a gift. That was kind of you."
    endif

    if $choice_made == 2:
        "Kona" "You chose to chat. Communication matters."
    endif

    if $choice_made == 3:
        "Kona" "You chose to ignore me... maybe try another option next time."
    endif
```

---

## Linking Choices With Variables

By combining `choice` and `branch`, you can modify variables after the player makes a choice, letting choices affect later story content.

### Example

```
set $choice_made = 0

choice "Give a gift (affection +10)" -> gift_choice
choice "Chat (affection +5)" -> chat_choice
choice "Ignore (affection -5)" -> ignore_choice

branch gift_choice
    add %love 10
    set $choice_made = 1
    "Kona" "Thank you! Affection increased to %love!"
    jump_branch after_choice

branch chat_choice
    add %love 5
    set $choice_made = 2
    "Kona" "I enjoyed talking with you. Affection is now %love."
    jump_branch after_choice

branch ignore_choice
    sub %love 5
    set $choice_made = 3
    "Kona" "......Affection dropped to %love."
    jump_branch after_choice

branch after_choice
    "Kona" "Your choice has been recorded."
```

---

## Boolean Variables

Variables support boolean values. Use `true` / `false` for assignment. In conditional checks, `true` is equivalent to `1`, and `false` is equivalent to `0`.

### Example

```
set %unlocked true
set $visited false

if %unlocked == 1:
    "Kona" "Feature unlocked!"
endif

set $visited true
if $visited == 1:
    "Kona" "The visited flag has been set."
endif
```

---

## Variable Initialization

### Persistent Variables (`%`)

Persistent variables must be initialized before the script runs. There are two ways to do this:

**Method 1: Inspector preset (recommended)**

Create a `KND_VariableStore` resource in the editor, set the initial variable values in the inspector, and assign it to the `variable_store` property of `KND_DialogueManager`.

**Method 2: Code initialization**

```gdscript
func _ready() -> void:
    if dialogue_manager.variable_store == null:
        var store = KND_VariableStore.new()
        store.set_value("love", 0)
        store.set_value("player_name", "")
        store.set_value("unlocked", false)
        dialogue_manager.variable_store = store
```

### Temporary Variables (`$`)

Temporary variables do not need presets. They are created automatically the first time `set` is used in a script. They are reset automatically when switching shots.

---

## Complete Example

The following combined demo covers all variable features:

```
play bgm echo
background bg1 fade

actor show Kona Normal at 3 9 scale 0.3
"Kona" "Welcome to the variable system demo!"

set %love = 10
"Kona" "Affection has been set to 10. Current value: %love"

add %love 5
"Kona" "After adding 5, affection is: %love"

sub %love 3
"Kona" "After subtracting 3, affection is: %love"

mul %love 2
"Kona" "After multiplying by 2, affection is: %love"

div %love 4
"Kona" "After dividing by 4, affection is: %love"

set $round = 1
set $bonus = 100
"Kona" "round=$round, bonus=$bonus"

add $round 1
add $bonus 50
"Kona" "Round $round, bonus $bonus"

set %player_name "Player"
"Kona" "Hello, %player_name! Affection %love, round $round."

if %love == 6:
    "Kona" "Affection is exactly 6!"
else:
    "Kona" "Affection is not 6."
endif

if %love > 3:
    "Kona" "Affection is greater than 3!"
endif

if %love < 10:
    "Kona" "Affection is less than 10."
endif

set $score = 85

if $score >= 90:
    "Kona" "Excellent!"
endif

if $score >= 80:
    "Kona" "Good!"
endif

set %unlocked true
if %unlocked == 1:
    "Kona" "Feature unlocked!"
endif

choice "Give a gift (affection +10)" -> gift
choice "Ignore (affection -5)" -> ignore

branch gift
    add %love 10
    "Kona" "Thank you! Affection %love!"
    jump_branch done

branch ignore
    sub %love 5
    "Kona" "......Affection %love."
    jump_branch done

branch done
    actor exit Kona
    background bg_end fade
    end
```

---

## Notes

1. **Variable names** can contain only letters, numbers, and underscores, and are case-sensitive.
2. **Persistent variables** (`%`) are saved with save data. They are suitable for cross-shot state such as affection values and story flags.
3. **Temporary variables** (`$`) are cleared automatically when switching shots. They are suitable for temporary state inside the current shot.
4. A **division operation** with a zero divisor triggers an error and skips that operation.
5. **Conditional checks** do not support nesting. Use flat `if` / `endif` structures for multiple conditions.
6. When using conditional checks inside a `branch` block, the indentation of `if` / `endif` must match other content inside the branch.
7. Uninitialized variables are treated as false in conditional checks.
