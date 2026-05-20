---
title: 打字機動效
order: 5
---

# 打字機效果 (Typewriter Effect)

## 概述

Konado 提供了強大的打字機效果元件，支援 GPU 加速的逐字元淡入效果，讓你的遊戲對話更加生動有趣。

## 核心特性

- **GPU 加速渲染** - 使用專用著色器逐字元渲染，效能優異
- **BBCode 富文本支援** - 支援粗體、斜體、顏色、底線、刪除線等
- **多種淡入方向** - 可以設定任意角度的淡入效果方向
- **空間混合** - 可以混合字元順序和時間空間順序的淡入效果
- **CJK 多語言支援** - 完整支援中文、日文、韓文等多位元組字元

## 基本使用

### 在對話框中使用

在 `KND_DialogueBox` 元件中，可以直接選擇開啟打字機效果：

1. 選中場景中的 `KND_DialogueBox` 節點
2. 在 Inspector 面板中找到相應的設定選項
3. 啟用打字機模式

### 程式化方式使用

```gdscript
# 取得打字機元件
var typewriter = $KND_TypewriterText

# 設定要顯示的文字（支援 BBCode）
typewriter.set_bbcode("[color=yellow]你好[/color]，[b]玩家[/b]！")

# 手動開始打字效果
typewriter.start()

# 跳過打字效果，立即顯示全部
typewriter.skip()

# 重設，隱藏所有文字
typewriter.reset()
```

## BBCode 富文本

### 支援的標籤

| 標籤 | 說明 | 範例 |
|------|------|------|
| `[b]` | 粗體 | `[b]粗體文字[/b]` |
| `[i]` | 斜體 | `[i]斜體文字[/i]` |
| `[u]` | 底線 | `[u]底線文字[/u]` |
| `[s]` | 刪除線 | `[s]刪除線文字[/s]` |
| `[color=顏色]` | 文字顏色 | `[color=red]紅色[/color]` |
| `[font=字體]` | 指定字體 | `[font=my_font]特殊字體[/font]` |

### 顏色範例

```bbcode
[color=#FF5733]橙色文字[/color]
[color=green]綠色文字[/color]
[color=#3498db]藍色文字[/color]
[color=yellow]黃色文字[/color]
```

## 淡入效果配置

### 淡入方向 (Fade Angle)

設定字元淡入的方向角度：

- `0°` - 從左到右（預設）
- `90°` - 從上到下
- `-90°` - 從下到上
- `180°` - 從右到左
- 任意角度值 - 自定義方向

### 空間混合 (Spatial Blend)

控制字元顯示順序和空間位置的混合程度：

- `0.0` - 完全按字元順序顯示
- `0.5` - 混合模式
- `1.0` - 完全按空間位置顯示

### 柔和度 (Softness)

控制淡入效果的柔和程度，值越大邊緣越柔和。

## 訊號 (Signals)

打字機元件提供以下訊號，方便你監聽狀態變化：

| 訊號 | 說明 |
|------|------|
| `typewriter_started` | 打字機效果開始時觸發 |
| `typewriter_finished` | 打字機效果完成時觸發 |
| `typewriter_skipped` | 跳過打字效果時觸發 |
| `character_revealed(index)` | 每個字元顯示時觸發，index 為字元索引 |

### 訊號使用範例

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

### 屬性

| 屬性 | 類型 | 預設值 | 說明 |
|------|------|--------|------|
| `bbcode_text` | String | "" | 要顯示的 BBCode 文字 |
| `font` | Font | null | 自定義字體 |
| `font_size` | int | 20 | 字體大小 |
| `font_color` | Color | WHITE | 文字顏色 |
| `chars_per_second` | float | 25.0 | 每秒顯示字元數 |
| `fade_width` | float | 3.0 | 淡入寬度 |
| `fade_angle` | float | 0.0 | 淡入角度（度） |
| `spatial_blend` | float | 0.15 | 空間混合比例 |
| `auto_start` | bool | true | 是否自動開始 |

### 方法

| 方法 | 說明 |
|------|------|
| `start()` | 開始打字效果 |
| `skip()` | 跳過，立即顯示全部 |
| `reset()` | 重設，隱藏所有文字 |
| `set_bbcode(text, autoplay)` | 設定 BBCode 文字 |
| `is_playing()` | 是否正在播放 |
| `is_finished()` | 是否已完成 |
| `get_progress()` | 獲取當前進度 |

## 進階用法

### 自定義打字速度

```gdscript
# 快速顯示
typewriter.chars_per_second = 100.0

# 慢速打字，營造氛圍
typewriter.chars_per_second = 5.0
```

### 自定義淡入效果

```gdscript
# 設定淡入方向（45度角）
typewriter.fade_angle = 45.0

# 設定柔和度
typewriter.fade_width = 5.0

# 設定空間混合
typewriter.spatial_blend = 0.5
```

### 監聽打字完成事件

```gdscript
func _ready():
    var typewriter = $KND_TypewriterText
    typewriter.typewriter_finished.connect(_on_finished)

func _on_finished():
    # 打字完成后執行某些操作
    show_continue_button()
```

## 效能優化

- 使用 GPU 著色器渲染，效能優異
- 支援大量文字而不卡頓
- 建議在行動平台上適當降低 `chars_per_second` 值

## 注意事項

1. **BBCode 標籤必須成對出現** - 確保每個起始標籤都有對應的結束標籤
2. **顏色值可以自定義** - 支援十六進位顏色碼如 `#FF5733`
3. **編輯器預覽** - 在編輯器中執行時，文字會直接全部顯示方便預覽
4. **換行符號** - 使用 `\n` 進行換行
