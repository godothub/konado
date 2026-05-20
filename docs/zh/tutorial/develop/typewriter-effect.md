---
title: 打字机动效
order: 5
---

# 打字机效果 (Typewriter Effect)

## 概述

Konado 提供了强大的打字机效果组件，支持 GPU 加速的逐字符淡入效果，让你的游戏对话更加生动有趣。

## 核心特性

- **GPU 加速渲染** - 使用专用着色器逐字符渲染，性能优异
- **BBCode 富文本支持** - 支持粗体、斜体、颜色、下划线、删除线等
- **多种淡入方向** - 可以设置任意角度的淡入效果方向
- **空间混合** - 可以混合字符顺序和时间空间顺序的淡入效果
- **CJK 多语言支持** - 完整支持中文、日文、韩文等多字节字符

## 基本使用

### 在对话框中使用

在 `KND_DialogueBox` 组件中，可以直接选择开启打字机效果：

1. 选中场景中的 `KND_DialogueBox` 节点
2. 在 Inspector 面板中找到相应的设置选项
3. 启用打字机模式

### 编程方式使用

```gdscript
# 获取打字机组件
var typewriter = $KND_TypewriterText

# 设置要显示的文本（支持 BBCode）
typewriter.set_bbcode("[color=yellow]你好[/color]，[b]玩家[/b]！")

# 手动开始打字效果
typewriter.start()

# 跳过打字效果，立即显示全部
typewriter.skip()

# 重置，隐藏所有文本
typewriter.reset()
```

## BBCode 富文本

### 支持的标签

| 标签 | 说明 | 示例 |
|------|------|------|
| `[b]` | 粗体 | `[b]粗体文字[/b]` |
| `[i]` | 斜体 | `[i]斜体文字[/i]` |
| `[u]` | 下划线 | `[u]下划线文字[/u]` |
| `[s]` | 删除线 | `[s]删除线文字[/s]` |
| `[color=颜色]` | 文字颜色 | `[color=red]红色[/color]` |
| `[font=字体]` | 指定字体 | `[font=my_font]特殊字体[/font]` |

### 颜色示例

```bbcode
[color=#FF5733]橙色文字[/color]
[color=green]绿色文字[/color]
[color=#3498db]蓝色文字[/color]
[color=yellow]黄色文字[/color]
```

## 淡入效果配置

### 淡入方向 (Fade Angle)

设置字符淡入的方向角度：

- `0°` - 从左到右（默认）
- `90°` - 从上到下
- `-90°` - 从下到上
- `180°` - 从右到左
- 任意角度值 - 自定义方向

### 空间混合 (Spatial Blend)

控制字符显示顺序和空间位置的混合程度：

- `0.0` - 完全按字符顺序显示
- `0.5` - 混合模式
- `1.0` - 完全按空间位置显示

### 柔和度 (Softness)

控制淡入效果的柔和程度，值越大边缘越柔和。

## 信号 (Signals)

打字机组件提供以下信号，方便你监听状态变化：

| 信号 | 说明 |
|------|------|
| `typewriter_started` | 打字机效果开始时触发 |
| `typewriter_finished` | 打字机效果完成时触发 |
| `typewriter_skipped` | 跳过打字效果时触发 |
| `character_revealed(index)` | 每个字符显示时触发，index 为字符索引 |

### 信号使用示例

```gdscript
func _ready():
    var typewriter = $KND_TypewriterText
    typewriter.typewriter_started.connect(_on_typewriter_started)
    typewriter.typewriter_finished.connect(_on_typewriter_finished)
    typewriter.character_revealed.connect(_on_character_revealed)

func _on_typewriter_started():
    print("打字效果开始！")

func _on_typewriter_finished():
    print("打字效果完成！")

func _on_character_revealed(index: int):
    print("显示字符: ", index)
```

## API 参考

### 属性

| 属性 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `bbcode_text` | String | "" | 要显示的 BBCode 文本 |
| `font` | Font | null | 自定义字体 |
| `font_size` | int | 20 | 字体大小 |
| `font_color` | Color | WHITE | 文字颜色 |
| `chars_per_second` | float | 25.0 | 每秒显示字符数 |
| `fade_width` | float | 3.0 | 淡入宽度 |
| `fade_angle` | float | 0.0 | 淡入角度（度） |
| `spatial_blend` | float | 0.15 | 空间混合比例 |
| `auto_start` | bool | true | 是否自动开始 |

### 方法

| 方法 | 说明 |
|------|------|
| `start()` | 开始打字效果 |
| `skip()` | 跳过，立即显示全部 |
| `reset()` | 重置，隐藏所有文本 |
| `set_bbcode(text, autoplay)` | 设置 BBCode 文本 |
| `is_playing()` | 是否正在播放 |
| `is_finished()` | 是否已完成 |
| `get_progress()` | 获取当前进度 |

## 高级用法

### 自定义打字速度

```gdscript
# 快速显示
typewriter.chars_per_second = 100.0

# 慢速打字，营造氛围
typewriter.chars_per_second = 5.0
```

### 自定义淡入效果

```gdscript
# 设置淡入方向（45度角）
typewriter.fade_angle = 45.0

# 设置柔和度
typewriter.fade_width = 5.0

# 设置空间混合
typewriter.spatial_blend = 0.5
```

### 监听打字完成事件

```gdscript
func _ready():
    var typewriter = $KND_TypewriterText
    typewriter.typewriter_finished.connect(_on_finished)

func _on_finished():
    # 打字完成后执行某些操作
    show_continue_button()
```

## 性能优化

- 使用 GPU 着色器渲染，性能优异
- 支持大量文本而不卡顿
- 建议在移动平台上适当降低 `chars_per_second` 值

## 注意事项

1. **BBCode 标签必须成对出现** - 确保每个开启标签都有对应的结束标签
2. **颜色值可以自定义** - 支持十六进制颜色码如 `#FF5733`
3. **编辑器预览** - 在编辑器中运行时，文本会直接全部显示方便预览
4. **换行符** - 使用 `\n` 进行换行

