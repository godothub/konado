以下是翻譯成台灣慣用繁體中文（zh-TW）的文本：

---
title: 成就系統
order: 2
---

# 成就系統 KonadoAchievement

## 前言

KonadoAchievement 是一款輕量、資料驅動的成就系統插件，專為 Konado 設計，提供解鎖、進度追蹤、彈出通知、成就面板等完整功能。支援與 Konado 連動使用，也可獨立執行。


### 設定檔

成就系統使用 JSON 設定檔定義成就，預設路徑為 `res://addons/konado_achievement/data/achievements.json`，可以在 `KND_AchievementManager` 中設定其他路徑。



設定檔結構範例：

```json
{
  "achievements": [
    {
      "id": "first_blood",
      "name": "初遇篇章",
      "description": "解鎖第一條主線劇情分支。",
      "icon": "",
      "hidden": false,
      "category": "story",
      "points": 10,
      "conditions": {
        "type": "counter",
        "target_key": "story_branch_unlocked",
        "target_value": 1
      }
    }
  ]
}
```

### 設定選項（可選）

在 `KND_AchievementManager` 中，您可以透過以下屬性進行設定：

- `config_path`: 成就設定檔路徑
- `save_path`: 成就進度儲存路徑
- `popup_duration`: 成就解鎖彈出通知的顯示時長
- `popup_position`: 彈出通知的位置（top_left, top_right, bottom_left, bottom_right）

::tip
這部分未來可能會重構，以提供更靈活的設定選項。
::

## 核心功能

### 成就解鎖

成就系統支援兩種解鎖方式：

1. **直接解鎖**：透過 API 直接解鎖成就
2. **條件解鎖**：當滿足特定條件時自動解鎖成就

### 進度追蹤

系統支援兩種類型的進度追蹤：

1. **計數器**：累計數值達到目標值時解鎖
2. **旗標**：當旗標被設定為特定值時解鎖

### 通知系統

當成就解鎖時，系統會顯示一個彈出通知，包含成就名稱、描述和圖示。

### 成就面板

提供一個可顯示所有成就的面板，包括已解鎖和未解鎖的成就，以及解鎖進度。


## 成就設定詳解

### 成就屬性

每個成就可以包含以下屬性：

- `id`: 成就唯一識別碼
- `name`: 成就名稱
- `description`: 成就描述
- `icon`: 成就圖示路徑（可選）
- `hidden`: 是否隱藏（未解鎖時不顯示名稱和描述）
- `category`: 成就分類（可選）
- `points`: 成就點數（可選）
- `conditions`: 解鎖條件

### 條件類型

#### 計數器類型

```json
{
  "type": "counter",
  "target_key": "counter_key",
  "target_value": 10
}
```

當 `counter_key` 的值達到或超過 `target_value` 時解鎖。

#### 旗標類型

```json
{
  "type": "flag",
  "target_key": "flag_key",
  "target_value": true
}
```

當 `flag_key` 的值等於 `target_value` 時解鎖。

## 使用範例

### 基本使用

```gdscript
# 增加計數器值
KND_AchievementManager.increment_progress("story_branch_unlocked", 1)

# 設定旗標
KND_AchievementManager.set_flag("secret_ending_unlocked", true)

# 直接解鎖成就
KND_AchievementManager.unlock_achievement("special_achievement")

# 顯示成就面板
KND_AchievementManager.show_panel()
```

### 訊號監聽

```gdscript
# 監聽成就解鎖事件
KND_AchievementManager.achievement_unlocked.connect(_on_achievement_unlocked)

func _on_achievement_unlocked(achievement_id: String, data: Dictionary) -> void:
    print("成就解鎖: " + data.get("name"))
    # 可以在這裡添加額外的獎勵邏輯
```

### 自定義儲存/載入

```gdscript
# 設定自定義儲存處理
KND_AchievementManager.custom_save_handler = Callable(self, "_custom_save")
KND_AchievementManager.custom_load_handler = Callable(self, "_custom_load")

func _custom_save(data: Dictionary) -> void:
    # 自定義儲存邏輯
    pass

func _custom_load() -> Dictionary:
    # 自定義載入邏輯
    return {"unlocked": {}, "progress": {}}
```

### 外部整合

```gdscript
# 設定外部解鎖回呼
KND_AchievementManager.on_external_unlock = Callable(self, "_on_external_unlock")

func _on_external_unlock(achievement_id: String, data: Dictionary) -> void:
    # 同步到外部後端
    pass
```
