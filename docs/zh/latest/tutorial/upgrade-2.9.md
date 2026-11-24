---
title: 升级到 2.9
order: 4
---

# 升级到 2.9

2.9 新增 `call` / `return` 子程序与条件/一次性选项（`choice ... if` / `once`），并**不再兼容 2.8 的存档与已导出的剧本数据**。

## 不兼容项

| 项 | 2.8 | 2.9 |
| --- | --- | --- |
| 编译器 ABI | `konado-2.8` | `konado-2.9` |
| 命令 Schema | 3 | 5 |
| 运行期状态 Schema | 2 | 4 |

- 2.8 的 `.kns` 存档会被明确拒绝（提示“存档格式与 Konado 2.9 不匹配”），不会以空状态继续运行。
- 2.8 导出的剧本数据（加密 `.res` 或 PCK 内的编译产物）与新 ABI 不一致，需要重新导出。
- 2.9 不提供存档转换工具；如需保留玩家进度，请在 2.8 版本内自行结算或转档。

## 升级步骤

1. 用 2.9 的完整插件目录替换旧版本，并重新打开 Godot（`.ks` 会重新导入编译）。
2. 重新导出游戏；只替换已发布包里的插件不能完成升级。
3. 确认所有使用到 `choice` / `call` 的剧本已重新编译通过。

## 2.9 新语法速览

```text
call common_scene
return

choice "Option" -> branch_name if %love >= 5
choice "Ask once" -> branch_name once
```

详见“子程序调用（call / return）”与“选项”页面。

## 2.9 音频系统

2.9 把音频重构成事件驱动：总线混音、音乐交叉淡入、音效并发池、语音自动 ducking 与
RTPC（剧情变量驱动音量）。脚本侧只需要在原有命令上追加命名参数：

```text
play bgm chapter_01 [fade=1.5] [volume=-3]
play sfx coin [volume=-2] [count=3]
stop bgm [fade=2.0]
```

- 旧版 `background_music_list` / `sound_effect_list` / `voice_list` 仍然可用：
  命中事件库的 ID 优先使用事件，否则回退到列表里的同名音频流。
- 存档不再记录玩家音量；音量改为写在 `Music/SFX/Voice` 总线上，读档不会覆盖设置。
- 事件与 Bank 的编辑方式见 `tutorial/core/audio-editor.html`。
