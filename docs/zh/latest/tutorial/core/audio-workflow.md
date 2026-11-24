---
title: 音频工作流程
order: 11
---

# 音频工作流程

本文是从「拿到音频文件」到「进包发布」的完整流程。语法细节见
[音频事件与混音](tutorial/script/audio.html)，编辑器控件说明见
[编辑器里的音频编辑](tutorial/core/audio-editor.html)。

## 1. 角色与产物

| 角色 | 负责 | 产物 |
| --- | --- | --- |
| 音频设计 | 文件规范、响度、循环点、容器拆分 | `res://audio/**` 下的音频与事件 |
| 编剧 | 事件 ID、淡入淡出、音量偏移、条件音效 | `.ks` 里的 `play` / `stop` |
| 程序 | 事件库接线、总线、回退/存档行为 | `demo.tscn` 等场景的 `audio_event_library` |
| QA | 试听、问题清单、回退与读档回归 | 问题记录与验收清单 |

示例工程的完整迁移结果可直接参考：`res://audio/`（事件、Bank、事件库）与
`sample/demo/demo.tscn`（Manager 的 `audio_event_library` 接线）。

## 2. 目录与命名规范

```text
res://audio/                     原始音频（导入面板里设循环）
res://audio/events/<id>.tres     一个事件一个文件
res://audio/banks/<name>.tres    Bank（按章节/语言分组）
res://audio/audio_event_library.tres  事件库（Manager 引用它）
```

| 对象 | 规范 | 示例 |
| --- | --- | --- |
| 事件 ID | 小写 + 下划线，全部小写，不含扩展名 | `chapter_01`、`ui_click` |
| Bank 名 | `<章节>_<用途>` | `chapter_01_bgm`、`chapter_01_voice_zh` |
| 语音事件 | `<场景>_<序号>`，与台词 ID 对齐 | `cafe_greeting_01` |
| 文件名 | 与事件 ID 完全一致 | `ui_click.tres` |

事件放在 `res://audio` 或 `res://events` 下才会出现在 `Konado Audio` 面板里。

## 3. 流程

### 3.1 资产导入

1. 音频放入 `res://audio/`（BGM / SFX / Voice 分开子目录）。
2. 导入面板：BGM 勾选 `Loop`（OGG）或 `Loop Mode = Forward`（WAV）；语音不要循环。
3. 统一响度（建议 -16 LUFS 左右），避免"切歌突然变大声"。
4. **不要**在运行期修改导入资源的循环标记；Konado 播放循环音频时会自动复制一份再设置。

### 3.2 创建事件

在事件的检查器里依次确认：

- [ ] `id` 与文件名一致
- [ ] `bus` 正确（Music / SFX / Voice / Ambience / UI）
- [ ] `streams` 至少一条；多条时选 `random` 或 `sequence`
- [ ] 音乐勾选 `loop`，并设置 `fade_in` / `fade_out`
- [ ] 音效设置 `max_instances`、`steal_policy`、`cooldown`
- [ ] 音乐/环境音设置 `restore_policy`（默认 `seek`）

### 3.3 绑定参数（RTPC）

需要随剧情变化的音频，在事件里加 `KonadoAudioParameter`：

```text
variable = "%love"
minimum = 0    maximum = 100
gain_floor = 0.85    gain_ceiling = 1.0
gates_event = false
```

- 只想"条件出现"时把 `gates_event` 勾上（例如紧张时才出现的环境音）。
- 变量由剧本的 `set` / `add` 修改，运行期会自动推送给音频内核，**不需要重新播放**。

### 3.4 创建 Bank

1. 新建 `KonadoAudioBank`，`bank_name` 按章节命名。
2. 把事件拖进 `events`；语音 Bank 填 `locale`（如 `zh`）。
3. 一个语言一个语音 Bank，切语言时只需替换语音 Bank，音乐音效不受影响。

### 3.5 接线

1. 新建 `KonadoAudioEventLibrary`，把 Bank 拖进 `banks`。
2. 在对话 Manager（如 `sample/demo/demo.tscn` 的 `KonadoDialogue` 节点）上设置
   `audio_event_library`。
3. 需要多个章节时，每个章节一个事件库，切换章节时替换该引用。

> 旧版 `background_music_list` / `sound_effect_list` / `voice_list` 仍然兼容：
> 事件库命中 ID 时优先走事件，未命中才回退到列表。迁移期间两者可以并存。

### 3.6 剧本引用

```text
play bgm echo [fade=2.0]
play sfx ui_click [count=3] [volume=-4]
stop bgm [fade=2.0]
```

- 淡入淡出优先写在事件上，剧本只在需要"这一次不同"时覆盖。
- 同一个事件重复 `play` 是交叉淡入，不会硬切。
- 事件不存在时运行期返回结构化错误 `audio.event_not_found`，可在失败面板看到。

### 3.7 试听与校验

1. 选中事件，点检查器里的 **▶ 试听**（按事件的总线/音量/音高/循环播放）。
2. 在 `Konado Audio` 面板里选中事件，拖动 **参数模拟** 滑条，确认增益与条件是否符合预期。
3. 看面板 **问题** 列表：重复 ID、缺少音频流、未保存的流、参数变量非法。

### 3.8 出包前检查

```bash
# 编辑器内：Konado Audio → 刷新 → 问题列表为空
python tests/tools/repository_architecture_check.py
python .github/scripts/check_error_codes.py
python .github/scripts/check_doc_resource_paths.py docs/zh/latest docs/en/latest
godot --headless --path . --script tests/audio/test_audio_engine.gd
```

回归重点：

- [ ] 回退（Backlog 上一步）后音乐位置正确、语音不重播
- [ ] 读档后音量与当前设置一致（不被存档覆盖）
- [ ] 切语言后语音换成对应语言，音乐不中断
- [ ] 同一音效连续触发不互相打断，超过并发上限按策略抢占

## 4. 运行期约定

| 项目 | 约定 |
| --- | --- |
| 音量 | 写在 `Music/SFX/Voice/Ambience/UI` 总线，不进入存档 |
| 音乐状态 | 记录"事件 ID + 播放位置"，回退按 `restore_policy` 恢复 |
| 一次性音效 | 回退时不重放 |
| 语音 | 高优先级可打断低优先级；播放时音乐自动压低 6dB |
| Bank | 目前是分组与校验单位；事件随事件库一起载入 |

## 5. 常见故障排查

| 现象 | 排查方向 |
| --- | --- |
| `play bgm` 没有声音 | 事件没有 `streams`；RTPC 条件不成立；Manager 没设 `audio_event_library` |
| 只响一次就没了 | 事件 `loop` 未勾选，或 `max_instances`/`cooldown` 拦掉了重复触发 |
| 切歌有断点 | 剧本与事件都设了 `fade=0`；改为 0.5~2 秒交叉淡入 |
| 音效互相打断 | `sound_effect_list` 旧路径只有单播放器；改用事件并调大 `max_instances` |
| 读档后音量变了 | 检查是否仍在使用旧版列表路径或自定义状态捕获 |
| 面板看不到事件 | 事件不在 `res://audio` / `res://events` 下 |
| 试听按钮不出现 | 编辑器未重新加载插件，重开编辑器 |

## 6. 团队约定（Definition of Done）

- [ ] 新音频都有事件，且 ID 与文件名一致
- [ ] 事件加入了对应 Bank，Bank 已挂到事件库
- [ ] 音乐有淡入/淡出，音效有并发上限与冷却
- [ ] 语音按语言分包，`locale` 已填写
- [ ] 面板问题列表为空
- [ ] 回退/读档/切语言回归通过

## 7. 尚未提供的能力

- Bank 的按需加载与引用计数卸载（当前随事件库整体载入）
- 音乐段落/按拍切换（`AudioStreamInteractive` + BPM）
- 混音快照指令（`audio state`）
- 编辑器波形预览（OGG/MP3 无法读取采样，只有时长信息）

需要这些能力时，可先在团队内用"多事件 + RTPC + 淡入淡出"近似实现。
