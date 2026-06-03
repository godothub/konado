---
title: Syntax Highlighter
order: 5
---

# KND_KsHighlighter Editor Syntax Highlighting

## Preface

Syntax highlighting is an important part of an editor. It helps developers visually identify code structure, improving writing efficiency and readability.  
`KND_KsHighlighter` is a highlighter based on Godot's `SyntaxHighlighter`, designed specifically for KS scripts. It centralizes highlighting rules in a single script, making customization and extension very flexible. You can easily adjust existing rules or add entirely new color schemes.

## Basic Implementation

In `KND_KsHighlighter`, highlighting rules are stored as an array. Each array element is a dictionary containing two keys:

- `regex`: Regular expression used to match text (Godot RegEx syntax).
- `color`: Color for matched text, represented by `Color(r, g, b, a)`, where `a` is opacity (optional, default 1.0).

Example structure:
```gdscript
{
	"regex": "\\b(if|else|endif)\\b",
	"color": Color(1.0, 0.8, 0.2)
}
```

The highlighter matches rules in array order. Rules applied later may override earlier matches, so rule order is important. It is recommended to put general commands earlier and strings/comments later, so overriding behaves reasonably.

## Custom Color Scheme

You can apply custom highlighting to the editor in two ways:

### Method 1: Modify the Resource File (Recommended)

The default color scheme is stored as a resource file at:
```
res://addons/konado/editor/ks_editor/ks_syntax_highlighter.tres
```

Editing this resource file directly preserves changes and avoids regenerating it every time.  
Load and use the resource in code:
```gdscript
set_syntax_highlighter(load("res://addons/konado/editor/ks_editor/ks_syntax_highlighter.tres"))
```

### Method 2: Create an Instance Dynamically

You can also create a new `KND_KsHighlighter` instance directly in code and set custom rules for it, such as by modifying `highlight_rules` in the script:
```gdscript
set_syntax_highlighter(KND_KsHighlighter.new())
```

> **Note**: If you modify the `KND_KsHighlighter.gd` script directly, you may need to regenerate the resource file for changes to take effect. Prefer using the resource file method for clearer color management.
