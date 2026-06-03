---
title: 打字機動效
order: 5
---

# 打字機效果 (Typewriter Effect)

## 概述

Konado 提供強大的打字機效果元件，支援 GPU 加速的逐字元淡入效果，讓你的遊戲對話更加生動有趣。

## 核心特性

- **GPU 加速渲染** - 使用專用著色器逐字元渲染，效能優異
- **BBCode 富文字支援** - 支援粗體、斜體、顏色、底線、刪除線等
- **多種淡入方向** - 可設定任意角度的淡入效果方向
- **空間混合** - 可混合字元順序與時間空間順序的淡入效果
- **CJK 多語言支援** - 完整支援中文、日文、韓文等多位元組字元

## 基本使用

### 在對話框中使用

在 `KND_DialogueBox` 元件中，可以直接選擇開啟打字機效果：

1. 選中場景中的 `KND_DialogueBox` 節點
2. 在 Inspector 面板中找到相應設定選項
3. 啟用打字機模式

### 以程式方式使用

```gdscript
var typewriter = $KND_TypewriterText
typewriter.set_bbcode("[color=yellow]你好[/color]，[b]玩家[/b]！")
typewriter.start()
typewriter.skip()
typewriter.reset()
```

## BBCode 富文字

| 標籤 | 說明 | 範例 |
|------|------|------|
| `[b]` | 粗體 | `[b]粗體文字[/b]` |
| `[i]` | 斜體 | `[i]斜體文字[/i]` |
| `[u]` | 底線 | `[u]底線文字[/u]` |
| `[s]` | 刪除線 | `[s]刪除線文字[/s]` |
| `[color=顏色]` | 文字顏色 | `[color=red]紅色[/color]` |
| `[font=字型]` | 指定字型 | `[font=my_font]特殊字型[/font]` |

```bbcode
[color=#FF5733]橙色文字[/color]
[color=green]綠色文字[/color]
[color=#3498db]藍色文字[/color]
[color=yellow]黃色文字[/color]
```

## 淡入效果設定

- `fade_angle`：字元淡入方向角度。`0°` 從左到右，`90°` 從上到下，`-90°` 從下到上，`180°` 從右到左，也可使用任意自訂角度。
- `spatial_blend`：控制字元顯示順序與空間位置的混合程度。`0.0` 完全按字元順序，`0.5` 混合模式，`1.0` 完全按空間位置。
- `fade_width`：控制淡入效果柔和度，值越大邊緣越柔和。

## 訊號 (Signals)

| 訊號 | 說明 |
|------|------|
| `typewriter_started` | 打字機效果開始時觸發 |
| `typewriter_finished` | 打字機效果完成時觸發 |
| `typewriter_skipped` | 跳過打字效果時觸發 |
| `character_revealed(index)` | 每個字元顯示時觸發，index 為字元索引 |

```gdscript
func _ready():
    var typewriter = $KND_TypewriterText
    typewriter.typewriter_started.connect(_on_typewriter_started)
    typewriter.typewriter_finished.connect(_on_typewriter_finished)
    typewriter.character_revealed.connect(_on_character_revealed)

func _on_typewriter_started():
    print("打字效果開始！")

func _on_typewriter_finished():
    print("打字效果完成！")

func _on_character_revealed(index: int):
    print("顯示字元: ", index)
```

## API 參考

| 屬性 | 類型 | 預設值 | 說明 |
|------|------|--------|------|
| `bbcode_text` | String | "" | 要顯示的 BBCode 文字 |
| `font` | Font | null | 自訂字型 |
| `font_size` | int | 20 | 字型大小 |
| `font_color` | Color | WHITE | 文字顏色 |
| `chars_per_second` | float | 25.0 | 每秒顯示字元數 |
| `fade_width` | float | 3.0 | 淡入寬度 |
| `fade_angle` | float | 0.0 | 淡入角度（度） |
| `spatial_blend` | float | 0.15 | 空間混合比例 |
| `auto_start` | bool | true | 是否自動開始 |

| 方法 | 說明 |
|------|------|
| `start()` | 開始打字效果 |
| `skip()` | 跳過，立即顯示全部 |
| `reset()` | 重置，隱藏所有文字 |
| `set_bbcode(text, autoplay)` | 設定 BBCode 文字 |
| `is_playing()` | 是否正在播放 |
| `is_finished()` | 是否已完成 |
| `get_progress()` | 取得目前進度 |

## 進階用法

```gdscript
typewriter.chars_per_second = 100.0
typewriter.chars_per_second = 5.0
typewriter.fade_angle = 45.0
typewriter.fade_width = 5.0
typewriter.spatial_blend = 0.5
```

```gdscript
func _ready():
    var typewriter = $KND_TypewriterText
    typewriter.typewriter_finished.connect(_on_finished)

func _on_finished():
    # 打字完成後執行某些操作
    show_continue_button()
```

## 效能最佳化

- 使用 GPU 著色器渲染，效能優異
- 支援大量文字而不卡頓
- 建議在行動平台上適當降低 `chars_per_second` 值

## 注意事項

1. **BBCode 標籤必須成對出現**
2. **顏色值可以自訂**，支援 `#FF5733` 等十六進位色碼
3. **編輯器預覽**：在編輯器中執行時，文字會直接全部顯示方便預覽
4. **換行符**：使用 `\n` 進行換行
