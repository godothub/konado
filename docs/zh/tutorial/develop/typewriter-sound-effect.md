---
title: 打字机音效
order: 6
---

# 打字机音效 (Typing Sound Effect)

## 概述

Konado 对话框组件支持打字机音效功能，在打字过程中播放"滴滴"声，增强游戏的沉浸感和反馈体验。

## 音效目录

打字机音效文件存放在以下目录：

```
res://addons/konado/audioeffect/typewriter/
```

## 支持的音频格式

| 格式 | 说明 |
|------|------|
| `.wav` | 无压缩音频，推荐使用 |
| `.ogg` | Ogg Vorbis 压缩格式 |
| `.mp3` | MP3 压缩格式 |

## 基本配置

在 `KND_DialogueBox` 组件的 Inspector 面板中，可以找到打字机音效的相关配置：

### 音效开关

```gdscript
@export var enable_typing_effect_audio: bool = true
```

设置为 `true` 启用打字机音效，`false` 禁用。

### 音效资源

```gdscript
@export var typing_effect_audio: AudioStream
```

通过编辑器下拉菜单选择音效文件，或通过代码加载：

```gdscript
# 代码方式设置音效
dialogue_box.typing_effect_audio = load("res://addons/konado/audioeffect/typewriter/click.wav")
```

## 音效触发配置

### 触发概率

```gdscript
@export var audio_trigger_chance: float = 0.8
```

控制音效触发的概率，范围 0.0-1.0：

- `1.0` - 每次必播
- `0.8` - 80%概率播放（默认）
- `0.5` - 50%概率播放
- `0.0` - 不播放

### 播放间隔

```gdscript
@export var min_audio_interval: float = 0.02   # 最小间隔（秒）
@export var max_audio_interval: float = 0.08   # 最大间隔（秒）
```

音效播放的随机间隔范围，用于适配不同节奏的滴滴声：

- **快速滴滴声**：设置较小的间隔，如 `0.02 - 0.05`
- **慢速打字声**：设置较大的间隔，如 `0.05 - 0.15`

每次播放后会随机生成一个新的间隔值，介于最小和最大值之间。

### 音量控制

```gdscript
@export var audio_volumn: float = 0.6
```

音效音量，范围 0.0-1.0：

- `1.0` - 最大音量
- `0.6` - 60%音量（默认）
- `0.0` - 静音

## 使用示例

### 基础使用

1. 将音效文件放入 `res://addons/konado/audioeffect/typewriter/` 目录
2. 选中场景中的 `KND_DialogueBox` 节点
3. 在 Inspector 中启用 `Enable Typing Effect Audio`
4. 通过下拉菜单选择音效文件
5. 调整音量和其他参数

### 代码控制

```gdscript
# 获取对话框实例
var dialogue_box = $KND_DialogueBox

# 启用音效
dialogue_box.enable_typing_effect_audio = true

# 设置音效
dialogue_box.typing_effect_audio = load("res://addons/konado/audioeffect/typewriter/my_click.wav")

# 设置触发概率（每次都播）
dialogue_box.audio_trigger_chance = 1.0

# 设置音量
dialogue_box.audio_volumn = 0.8

# 设置播放间隔
dialogue_box.min_audio_interval = 0.02
dialogue_box.max_audio_interval = 0.06
```

## 推荐音效

### 打字机滴滴声

适合快速、密集的打字效果，建议间隔设置较小：

```
min_audio_interval: 0.02
max_audio_interval: 0.05
audio_trigger_chance: 0.8
```

### 机械键盘声

适合打字感强的游戏：

```
min_audio_interval: 0.03
max_audio_interval: 0.08
audio_trigger_chance: 0.9
```

### 轻柔点击声

适合休闲、舒缓的游戏氛围：

```
min_audio_interval: 0.05
max_audio_interval: 0.12
audio_trigger_chance: 0.7
audio_volumn: 0.5
```

## 音效触发时机

打字机音效在以下情况下触发：

1. **打字动画播放中** - 对话文字正在逐字符显示
2. **距离上次播放超过随机间隔** - 避免音效过于密集
3. **通过随机概率检查** - 根据 `audio_trigger_chance` 设置
4. **文本未显示完成** - 如果已显示完则不触发

## 注意事项

1. **音效文件命名** - 建议使用英文命名，避免特殊字符
2. **音效长度** - 建议音效时长在 0.1 秒以内效果最佳
3. **音量平衡** - 确保打字音效不会盖过背景音乐
4. **移动平台** - 移动设备上建议使用压缩格式（ogg/mp3）以节省空间
5. **音效同步** - 音效会与打字进度自动同步，无需手动控制

## 性能优化

- 使用短音效文件（< 100KB）
- 优先使用 `.ogg` 格式（压缩率高）
- 避免同时播放多个相同音效实例
- 在不需要音效时可设置 `enable_typing_effect_audio = false` 禁用

## 故障排除

### 音效不播放

1. 检查 `enable_typing_effect_audio` 是否为 `true`
2. 检查 `typing_effect_audio` 是否已正确设置
3. 确认音效文件路径是否存在
4. 检查音量是否设置为 0

### 音效过于密集

1. 增大 `min_audio_interval` 和 `max_audio_interval` 的值
2. 降低 `audio_trigger_chance` 的值

### 音效过于稀疏

1. 减小 `min_audio_interval` 和 `max_audio_interval` 的值
2. 增大 `audio_trigger_chance` 的值
