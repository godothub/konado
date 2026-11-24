---
title: 音频事件与混音
order: 10
---

# 音频事件与混音

## 概览

2.9 起，脚本里的音频命令既可以引用**音频事件**（推荐），也可以继续引用旧版资源列表里的名字：

- 事件（`KonadoAudioEvent`）：一条 ID 对应一条或多条音频流，并携带总线、循环、淡入淡出、并发上限、优先级与播放条件。
- 旧版列表（`background_music_list` / `sound_effect_list` / `voice_list`）：命中事件库时以事件为准，否则回退到列表中的同名音频流。

两者对剧本来说都是"一个名字"，旧脚本不需要修改。

## 语法

```text
play bgm <事件或资源名> [fade=<秒>] [volume=<dB>]
play sfx <事件或资源名> [volume=<dB>] [count=<1-8>]
stop bgm [fade=<秒>]
```

| 参数 | 适用命令 | 说明 |
| --- | --- | --- |
| `fade` | `play bgm`、`stop bgm` | 交叉淡入/淡出时长（秒）。省略时使用事件自带的 `fade_in` / `fade_out` |
| `volume` | `play bgm`、`play sfx` | 在事件音量基础上的 dB 偏移，可为负数 |
| `count` | `play sfx` | 同一次调用连续触发的次数（1–8），用于叠音效 |

`fade` 不能为负数，`count` 不能小于 1；越界会在编译期报错。

## 示例

```text
play bgm chapter_01 [fade=1.5]
Kona "音乐淡入完成。"

play sfx coin [volume=-2] [count=3]
Kona "三连金币音，音量比默认低 2dB。"

stop bgm [fade=2.0]
Kona "音乐淡出两秒后停止。"
```

完整可运行示例见 `sample/demo/demo_09_audio.ks`。

## 总线与音量

Konado 会在运行时确保以下总线存在（父总线均为 `Master`）：

| 总线 | 用途 |
| --- | --- |
| `Music` | 背景音乐 |
| `Ambience` | 环境音（与音乐并行，不会互相打断） |
| `SFX` | 音效（走并发池） |
| `Voice` | 语音 |
| `UI` | 界面音效 |

玩家音量由设置面板写入总线（`Master × 分类`），**不再保存在存档里**，因此读档不会覆盖玩家刚刚调整的音量。

## 剧情变量驱动音频（RTPC）

事件可以挂多个 `KonadoAudioParameter`：

- `variable`：`%持久变量` 或 `$临时变量`
- `gates_event`：变量超出 `minimum`–`maximum` 时直接跳过该事件（"条件音效"）
- `curve`：变量值 → 线性增益；没有曲线时按 `gain_floor`–`gain_ceiling` 线性插值

变量在剧本里被 `set`/`add` 修改后会自动推送给音频内核，正在播放的音乐会立即按新增益调整。

## 并发、抢占与冷却

| 字段 | 作用 |
| --- | --- |
| `max_instances` | 同一事件允许同时存在的实例数（音乐/环境音固定为 1） |
| `priority` | 抢占比较用，数值越大越重要 |
| `steal_policy` | `oldest` 抢最早的、`lowest_priority` 抢优先级更低的、`reject` 直接拒绝 |
| `cooldown` | 冷却时间（秒），冷却期内重复触发会被忽略 |

被忽略的触发不会中断剧情：运行时会返回 `ignored` 结果而不是失败。

## 语音

- 语音事件同样可以设置 `priority`；高优先级语音可以打断低优先级语音，反之会被忽略。
- 语音播放时默认把 `Music` 压低 6dB（`duck_music_for_voice` / `voice_duck_db` 可调），结束后自动恢复。
- 回退时语音不会重播；`restore_policy` 只影响音乐/环境音。

## 回退与存档

音乐与环境音会记录"事件 ID + 播放位置"：

| `restore_policy` | 行为 |
| --- | --- |
| `seek`（默认） | 回退/读档后回到同一位置继续播放 |
| `restart` | 从头重新播放 |
| `silent` | 不恢复（保持静音） |

一次性音效（`SFX`）不会在回退时重放，避免"回退一次响一次"。
