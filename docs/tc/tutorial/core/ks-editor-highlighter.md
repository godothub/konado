---
title: 語法高亮度
order: 5
---

# KND_KsHighlighter 編輯器語法高亮度

## 前言

語法高亮度是編輯器的重要組成部分，它能幫助開發者直觀地識別程式碼結構，進而提升編寫效率與可讀性。  
`KND_KsHighlighter` 是基於 Godot 引擎的 `SyntaxHighlighter` 實現的一款高亮度器，專門用於 KS 腳本。它將高亮度規則集中定義在單個腳本中，使得自定義與擴充變得非常靈活——你可以輕鬆調整現有規則，也可以加入全新的配色方案。

## 基本實現

在 `KND_KsHighlighter` 中，高亮度規則儲存為一個陣列，每個陣列元素都是一個字典，包含兩個鍵：

- `regex`：用於比對文字的正則表達式（Godot 的 RegEx 語法）。
- `color`：比對文字的顏色，使用 `Color(r, g, b, a)` 表示，其中 `a` 為透明度（可選，預設為 1.0）。

範例結構如下：
```gdscript
{
	"regex": "\\b(if|else|endif)\\b",
	"color": Color(1.0, 0.8, 0.2)
}
```

高亮度器會按陣列順序依次比對，後套用的規則可能會覆蓋先前的比對結果，因此規則的順序至關重要（建議將通用指令放在前面，字串與註解放在後面，以保證覆蓋效果合理）。

## 自定義配色方案

你可以透過兩種方式為編輯器套用自定義高亮度：

### 方式一：修改資源檔案（推薦）

預設的配色方案以資源檔案形式儲存在：
```
res://addons/konado/editor/ks_editor/ks_syntax_highlighter.tres
```

直接編輯該資源檔案可以保留修改，並避免每次重新產生。  
在程式碼中載入並使用該資源：
```gdscript
set_syntax_highlighter(load("res://addons/konado/editor/ks_editor/ks_syntax_highlighter.tres"))
```

### 方式二：動態建立執行實例

你也可以在程式碼中直接建立一個新的 `KND_KsHighlighter` 執行實例，並為其設定自定義規則（例如透過修改腳本中的 `highlight_rules`）：
```gdscript
set_syntax_highlighter(KND_KsHighlighter.new())
```

> **注意**：如果直接修改了 `KND_KsHighlighter.gd` 腳本，可能需要重新產生資源檔案才能使更動生效。推薦優先使用資源檔案方式，以便更清晰地管理配色。
