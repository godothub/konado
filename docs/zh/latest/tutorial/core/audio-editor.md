---
title: 编辑器里的音频编辑
order: 10
---

# 编辑器里的音频编辑

## 目录约定

```text
res://audio/                     原始音频（在导入面板设置循环）
res://audio/events/              一个事件一个 .tres（推荐）
res://audio/banks/               Bank（按章节/语言分组事件）
```

`Konado Audio` 面板会扫描 `res://audio` 与 `res://events` 下的 `.tres`，也可以放在别处后
手动在检查器里打开——只是不会出现在面板列表里。

## 音频导入设置

| 格式 | 建议 |
| --- | --- |
| OGG | BGM 勾选 `Loop`；语音保持关闭 |
| WAV | 短音效使用；需要循环时设置 `Loop Mode = Forward` |
| MP3 | 不建议用于 BGM（首尾静音会让循环出现缝隙） |

> 不要在运行期直接修改导入资源的 `loop`，共享资源会被全局改掉。Konado 在播放循环音频时会
> 自动 `duplicate()` 一份再设置循环。

## 新建事件

1. 在 `res://audio/events` 上右键 → 新建资源 → `KonadoAudioEvent`。
2. 填写 `id`（建议与文件名一致，脚本里 `play bgm <id>` 就用它）。
3. 选择 `bus`：`Music` / `SFX` / `Voice` / `Ambience` / `UI`。
4. 把音频拖进 `streams`：拖入多条时把 `container` 设为 `random` 或 `sequence` 可避免"机关枪"重复感。
5. 按需设置 `loop`、`fade_in` / `fade_out`、`cooldown`、`max_instances`、`priority`、
   `steal_policy` 与 `restore_policy`。

### 事件检查器

打开任意 `KonadoAudioEvent`，检查器顶部会出现一排按钮：

- **▶ 试听**：按事件的总线、音量、音高与循环直接播放
- **■ 停止**：停止试听
- **复制 ID**：把事件 ID 复制到剪贴板，便于粘贴到剧本

按钮下方是一行摘要（总线、流数量、时长、并发、优先级、循环、参数数量）。

## 参数（RTPC）

在事件的 `parameters` 数组里添加 `KonadoAudioParameter`：

- `variable`：`%love`、`$tension` 这类变量名
- `gates_event`：条件不成立时跳过该事件
- `minimum` / `maximum`：变量有效区间
- `curve`：变量值 → 线性增益（没有曲线时用 `gain_floor`–`gain_ceiling` 插值）

## Konado Audio 面板

在编辑器右侧打开的 `Konado Audio` 面板提供：

| 区域 | 功能 |
| --- | --- |
| 事件树 | 按 Bank 分组列出 `res://audio` 下的事件（未加入 Bank 的进“未分组”），显示总线/流数量/并发/循环/参数 |
| 搜索 | 按 ID 过滤 |
| ▶ 试听 / ■ 停止 | 试听当前选中事件 |
| 参数模拟 | 拖动滑条模拟变量值，并显示当前增益与条件是否成立 |
| 问题 | 重复 ID、缺少音频流、未保存的流、参数变量非法 |
| ＋ 事件 | 在 `res://audio/events` 创建空事件并在检查器中打开 |
| 事件库 | 在检查器中打开 `res://audio/audio_event_library.tres`，方便把 Bank 拖进去 |
| 导入旧版列表 | 在文件系统里选中 `background_music_list` / `sound_effect_list` / `voice_list`，一键生成 `res://audio/events/<id>.tres` |

双击事件会在检查器中打开它。面板监听文件系统变化，保存资源后会自动刷新。

> 忘记在 Manager 上接 `audio_event_library` 时，控制器会自动加载约定路径
> `res://audio/audio_event_library.tres`，因此只要事件库放在约定位置就不会静音。

## 从旧版列表迁移

1. 在文件系统里选中旧的 BGM/SFX/Voice 列表资源（可以多选）。
2. 点击面板上的 **导入旧版列表**。
3. 生成的事件会引用原来的音频流（不复制文件），ID 使用列表里的名字。
4. 之后可以逐步删除旧列表；未迁移的条目仍会回退到旧列表播放。

示例工程已经完成迁移，可直接对照：`res://audio/events/*.tres`、`res://audio/banks/demo_audio.tres`、
`res://audio/audio_event_library.tres`，并在 `sample/demo/demo.tscn` 的 Manager 上接好
`audio_event_library`。完整流程见 [音频工作流程](tutorial/core/audio-workflow.html)。

## 常见问题

| 现象 | 原因 |
| --- | --- |
| 面板里看不到事件 | 事件不在 `res://audio` 或 `res://events` 下 |
| 检查器里没有试听按钮 | 脚本没有重新加载，重新打开编辑器或刷新插件 |
| OGG/MP3 没有波形 | Godot 不提供解码后的采样数据，只有时长与总线信息 |
| `play bgm` 没有声音 | 事件没有 `streams`，或 RTPC 条件不成立（面板问题列表会提示） |
