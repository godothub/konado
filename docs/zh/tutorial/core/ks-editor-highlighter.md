---
title: 语法高亮器
order: 5
---

# KND_KsHighlighter 编辑器语法高亮

## 前言

语法高亮是编辑器的重要组成部分，它能帮助开发者直观地识别代码结构，从而提升编写效率和可读性。  
`KND_KsHighlighter` 是基于 Godot 引擎的 `SyntaxHighlighter` 实现的一款高亮器，专门用于 KS 脚本。它将高亮规则集中定义在单个脚本中，使得自定义和扩展变得非常灵活——你可以轻松调整现有规则，也可以添加全新的配色方案。

## 基本实现

在 `KND_KsHighlighter` 中，高亮规则存储为一个数组，每个数组元素都是一个字典，包含两个键：

- `regex`：用于匹配文本的正则表达式（Godot 的 RegEx 语法）。
- `color`：匹配文本的颜色，使用 `Color(r, g, b, a)` 表示，其中 `a` 为透明度（可选，默认为 1.0）。

示例结构如下：
```gdscript
{
	"regex": "\\b(if|else|endif)\\b",
	"color": Color(1.0, 0.8, 0.2)
}
```

高亮器会按数组顺序依次匹配，后应用的规则可能覆盖先前的匹配，因此规则的顺序至关重要（建议将通用命令放在前面，字符串和注释放在后面，以保证覆盖效果合理）。

## 自定义配色方案

你可以通过两种方式为编辑器应用自定义高亮：

### 方式一：修改资源文件（推荐）

默认的配色方案以资源文件形式存储在：
```
res://addons/konado/editor/ks_editor/ks_syntax_highlighter.tres
```

直接编辑该资源文件可以保留修改，并避免每次重新生成。  
在代码中加载并使用该资源：
```gdscript
set_syntax_highlighter(load("res://addons/konado/editor/ks_editor/ks_syntax_highlighter.tres"))
```

### 方式二：动态创建实例

你也可以在代码中直接创建一个新的 `KND_KsHighlighter` 实例，并为其设置自定义规则（例如通过修改脚本中的 `highlight_rules`）：
```gdscript
set_syntax_highlighter(KND_KsHighlighter.new())
```

> **注意**：如果直接修改了 `KND_KsHighlighter.gd` 脚本，可能需要重新生成资源文件才能使更改生效。推荐优先使用资源文件方式，以便更清晰地管理配色。