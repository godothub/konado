---
title: 打字機音效
order: 6
---

# 打字機音效 (Typing Sound Effect)

## 概述

Konado 對話框組件支援打字機音效功能，在打字過程中播放「滴滴」聲，增強遊戲的沉浸感與回饋體驗。

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

## 基本配置

在 `KND_DialogueBox` 組件的 Inspector 面板中，可以找到打字機音效的相關配置：

### 音效開關

```gdscript
 @export_presets.cfg var enable_typing_effect_audio: bool = true
```

設置為 `true` 啟用打字機音效，`false` 禁用。

### 音效資源

```gdscript
 @export_presets.cfg var typing_effect_audio: AudioStream
```

透過編輯器下拉選單選擇音效檔案，或透過程式碼載入：

```gdscript
# 程式碼方式設置音效
dialogue_box.typing_effect_audio = load("res://addons/konado/audioeffect/typewriter/click.wav")
```

## 音效觸發配置

### 觸發機率

```gdscript
 @export_presets.cfg var audio_trigger_chance: float = 0.8
```

控制音效觸發的機率，範圍 0.0-1.0：

- `1.0` - 每次必播
- `0.8` - 80% 機率播放（預設）
- `0.5` - 50% 機率播放
- `0.0` - 不播放

### 播放間隔

```gdscript
 @export_presets.cfg var min_audio_interval: float = 0.02   # 最小間隔（秒）
 @export_presets.cfg var max_audio_interval: float = 0.08   # 最大間隔（秒）
```

音效播放的隨機間隔範圍，用於適配不同節奏的滴滴聲：

- **快速滴滴聲**：設置較小的間隔，如 `0.02 - 0.05`
- **慢速打字聲**：設置較大的間隔，如 `0.05 - 0.15`

每次播放後會隨機生成一個新的間隔值，介於最小與最大值之間。

### 音量控制

```gdscript
 @export_presets.cfg var audio_volumn: float = 0.6
```

音效音量，範圍 0.0-1.0：

- `1.0` - 最大音量
- `0.6` - 60% 音量（預設）
- `0.0` - 静音

## 使用範例

### 基礎使用

1. 將音效檔案放入 `res://addons/konado/audioeffect/typewriter/` 目錄
2. 選中場景中的 `KND_DialogueBox` 節點
3. 在 Inspector 中啟用 `Enable Typing Effect Audio`
4. 透過下拉選單選擇音效檔案
5. 調整音量和其他參數

### 程式碼控制

```gdscript
# 獲取對話框實例
var dialogue_box = $KND_DialogueBox

# 啟用音效
dialogue_box.enable_typing_effect_audio = true

# 設置音效
dialogue_box.typing_effect_audio = load("res://addons/konado/audioeffect/typewriter/my_click.wav")

# 設置觸發機率（每次都播）
dialogue_box.audio_trigger_chance = 1.0

# 設置音量
dialogue_box.audio_volumn = 0.8

# 設置播放間隔
dialogue_box.min_audio_interval = 0.02
dialogue_box.max_audio_interval = 0.06
```

## 推薦音效

### 打字機滴滴聲

適合快速、密集的打字效果，建議間隔設置較小：

```
min_audio_interval: 0.02
max_audio_interval: 0.05
audio_trigger_chance: 0.8
```

### 機械鍵盤聲

適合打字感強的遊戲：

```
min_audio_interval: 0.03
max_audio_interval: 0.08
audio_trigger_chance: 0.9
```

### 輕柔點擊聲

適合休閒、舒緩的遊戲氛圍：

```
min_audio_interval: 0.05
max_audio_interval: 0.12
audio_trigger_chance: 0.7
audio_volumn: 0.5
```

## 音效觸發時機

打字機音效在以下情況下觸發：

1. **打字動畫播放中** - 對話文字正在逐字元顯示
2. **距離上次播放超過隨機間隔** - 避免音效過於密集
3. **通過隨機機率檢查** - 根據 `audio_trigger_chance` 設置
4. **文本未顯示完成** - 如果已顯示完則不觸發

## 注意事項

1. **音效檔案命名** - 建議使用英文命名，避免特殊字元
2. **音效長度** - 建議音效時長在 0.1 秒以內效果最佳
3. **音量平衡** - 確保打字音效不會蓋過背景音樂
4. **移動平台** - 行動裝置上建議使用壓縮格式（ogg/mp3）以節省空間
5. **音效同步** - 音效會與打字進度自動同步，無需手動控制

## 效能優化

- 使用短音效檔案（< 100KB）
- 優先使用 `.ogg` 格式（壓縮率高）
- 避免同時播放多個相同音效實例
- 在不需要音效時可設置 `enable_typing_effect_audio = false` 禁用

## 疑難排解

### 音效不播放

1. 檢查 `enable_typing_effect_audio` 是否為 `true`
2. 檢查 `typing_effect_audio` 是否已正確設置
3. 確認音效檔案路徑是否存在
4. 檢查音量是否設置為 0

### 音效過於密集

1. 增大 `min_audio_interval` 與 `max_audio_interval` 的值
2. 降低 `audio_trigger_chance` 的值

### 音效過於稀疏

1. 減小 `min_audio_interval` 與 `max_audio_interval` 的值
2. 增大 `audio_trigger_chance` 的值
