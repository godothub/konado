---
title: Conditional Branch
order: 5
---

# If Else Branch

## Description

Choose which dialogue content to play based on a numeric condition. If the condition is not met, the dialogue inside `else` is played. If there is no `else`, no dialogue is played.
Variables are custom variables whose values are integers. They can be set in dialogue management and referenced with `%variable_name`. `==` is the comparison condition and means equal to.

## Syntax
```
if %variable == value:
    <dialogue>
    <dialogue>
else:
    <dialogue>
endif
```

## Example

```
if %love == 0:
    "Kona" "What would you like to drink today?"
else:
    "Kona" "Nice to see you again!"
    "Kona" "What would you like to drink today?"
endif
```
