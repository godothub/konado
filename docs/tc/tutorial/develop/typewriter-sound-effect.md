---
title: 打字機音效
order: 6
---

# 打字機音效 (Typing Sound Effect)

## 概述

Konado 對話框元件支援打字機音效功能，可在打字過程中播放「滴滴」聲，增強遊戲沉浸感與回饋體驗。

## 音效目錄

打字機音效檔案存放在以下目錄：

```
res://addons/konado/audioeffect/typewriter/
```

## 支援的音訊格式

| 格式 | 說明 |
|------|------|
| `.wav` | 無壓縮音訊，推薦使用 |
| `.ogg` | Ogg Vorbis 壓縮格式 |
| `.mp3` | MP3 壓縮格式 |

## 基本設定

在 `KND_DialogueBox` 元件的 Inspector 面板中，可以找到打字機音效相關設定：

```gdscript
@export var enable_typing_effect_audio: bool = true
@export var typing_effect_audio: AudioStream
```

將 `enable_typing_effect_audio` 設為 `true` 可啟用打字機音效，`false` 則禁用。可透過編輯器下拉選單選擇音效檔案，或透過程式碼載入：

```gdscript
dialogue_box.typing_effect_audio = load("res://addons/konado/audioeffect/typewriter/click.wav")
```

## 音效觸發設定

```gdscript
@export var audio_trigger_chance: float = 0.8
@export var min_audio_interval: float = 0.02
@export var max_audio_interval: float = 0.08
@export var audio_volumn: float = 0.6
```

- `audio_trigger_chance`：音效觸發機率，範圍 0.0-1.0；`1.0` 每次必播，`0.8` 表示 80% 機率播放，`0.0` 不播放。
- `min_audio_interval` / `max_audio_interval`：音效播放的隨機間隔範圍，用於適配不同節奏的滴滴聲。
- `audio_volumn`：音效音量，範圍 0.0-1.0。

## 使用範例

1. 將音效檔案放入 `res://addons/konado/audioeffect/typewriter/` 目錄
2. 選中場景中的 `KND_DialogueBox` 節點
3. 在 Inspector 中啟用 `Enable Typing Effect Audio`
4. 透過下拉選單選擇音效檔案
5. 調整音量和其他參數

```gdscript
var dialogue_box = $KND_DialogueBox
dialogue_box.enable_typing_effect_audio = true
dialogue_box.typing_effect_audio = load("res://addons/konado/audioeffect/typewriter/my_click.wav")
dialogue_box.audio_trigger_chance = 1.0
dialogue_box.audio_volumn = 0.8
dialogue_box.min_audio_interval = 0.02
dialogue_box.max_audio_interval = 0.06
```

## 推薦音效

- **打字機滴滴聲**：適合快速、密集的打字效果，建議 `0.02 - 0.05`，`audio_trigger_chance: 0.8`
- **機械鍵盤聲**：適合打字感強的遊戲，建議 `0.03 - 0.08`，`audio_trigger_chance: 0.9`
- **輕柔點擊聲**：適合休閒、舒緩氛圍，建議 `0.05 - 0.12`，`audio_trigger_chance: 0.7`，`audio_volumn: 0.5`

## 音效觸發時機

打字機音效會在打字動畫播放中、距離上次播放超過隨機間隔、通過隨機機率檢查，且文字尚未顯示完成時觸發。

## 注意事項與效能最佳化

1. 建議音效檔案使用英文命名，避免特殊字元。
2. 建議音效時長在 0.1 秒以內效果最佳。
3. 確保打字音效不會蓋過背景音樂。
4. 行動平台建議使用 ogg/mp3 等壓縮格式節省空間。
5. 使用短音效檔案（建議小於 100 KB），不需要音效時可設為 `enable_typing_effect_audio = false` 禁用。

## 故障排除

- 音效不播放時，檢查 `enable_typing_effect_audio`、`typing_effect_audio`、檔案路徑與音量。
- 音效過於密集時，增大間隔值或降低 `audio_trigger_chance`。
- 音效過於稀疏時，減小間隔值或增大 `audio_trigger_chance`。
