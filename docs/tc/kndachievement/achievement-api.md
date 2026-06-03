---
title: 使用 API
order: 3
---

# KND_AchievementManager API 參考

## 訊號

成就系統提供以下訊號，可用於監聽成就相關事件並執行自訂邏輯：

### achievement_unlocked

**訊號簽名：** `achievement_unlocked(achievement_id: String, data: Dictionary)`

**觸發時機：** 當任何成就被解鎖時觸發

**參數說明：**
- `achievement_id`: 被解鎖的成就 ID
- `data`: 成就的完整資料字典，包含名稱、描述、圖示等資訊

**使用場景：** 用於在成就解鎖時執行獎勵邏輯、播放慶祝動畫、顯示自訂通知等

**範例程式碼：**
```gdscript
# 連接訊號
KND_AchievementManager.achievement_unlocked.connect(_on_achievement_unlocked)

# 訊號處理函式
func _on_achievement_unlocked(achievement_id: String, data: Dictionary) -> void:
    print("成就解鎖: " + data.get("name"))
    # 播放成就解鎖音效
    # 顯示自訂慶祝動畫
    # 給予玩家獎勵
```

### achievement_progress_updated

**訊號簽名：** `achievement_progress_updated(achievement_id: String, current: float, target: float)`

**觸發時機：** 當成就的進度值更新時觸發

**參數說明：**
- `achievement_id`: 進度更新的成就 ID
- `current`: 目前進度值
- `target`: 目標進度值

**使用場景：** 用於顯示成就進度條、提供進度回饋、更新 UI 顯示等

**範例程式碼：**
```gdscript
# 連接訊號
KND_AchievementManager.achievement_progress_updated.connect(_on_progress_updated)

# 訊號處理函式
func _on_progress_updated(achievement_id: String, current: float, target: float) -> void:
    var progress_percentage = (current / target) * 100
    print("成就進度更新: " + achievement_id + " - " + str(progress_percentage) + "%")
    # 更新 UI 進度條
    # 顯示進度提示
```

### achievements_reset

**訊號簽名：** `achievements_reset()`

**觸發時機：** 當所有成就被重置時觸發

**參數說明：** 無參數

**使用場景：** 用於在成就重置後更新 UI、顯示重置通知、執行清理操作等

**範例程式碼：**
```gdscript
# 連接訊號
KND_AchievementManager.achievements_reset.connect(_on_achievements_reset)

# 訊號處理函式
func _on_achievements_reset() -> void:
    print("所有成就已重置")
    # 更新成就面板
    # 顯示重置通知
```

### achievements_loaded

**訊號簽名：** `achievements_loaded()`

**觸發時機：** 當成就系統完成載入時觸發

**參數說明：** 無參數

**使用場景：** 用於在成就載入完成後初始化 UI、執行依賴成就資料的邏輯等

**範例程式碼：**
```gdscript
# 連接訊號
KND_AchievementManager.achievements_loaded.connect(_on_achievements_loaded)

# 訊號處理函式
func _on_achievements_loaded() -> void:
    print("成就資料載入完成")
    # 初始化成就面板
    # 執行依賴成就資料的邏輯
```

## 核心方法

### 解鎖成就

```gdscript
# 透過 ID 直接解鎖成就
KND_AchievementManager.unlock_achievement("achievement_id")
```

### 進度管理

```gdscript
# 增加計數器值
KND_AchievementManager.increment_progress("counter_key", 1.0)

# 設定標誌值
KND_AchievementManager.set_flag("flag_key", true)
```

### 成就查詢

```gdscript
# 檢查成就是否已解鎖
KND_AchievementManager.is_unlocked("achievement_id")

# 取得單個成就資料
KND_AchievementManager.get_achievement("achievement_id")

# 取得所有成就
KND_AchievementManager.get_all_achievements()

# 取得已解鎖成就
KND_AchievementManager.get_unlocked_achievements()

# 取得未解鎖成就
KND_AchievementManager.get_locked_achievements()

# 取得解鎖百分比
KND_AchievementManager.get_unlock_percentage()
```

### 面板管理

```gdscript
# 顯示成就面板
KND_AchievementManager.show_panel()

# 隱藏成就面板
KND_AchievementManager.hide_panel()

# 切換成就面板顯示狀態
KND_AchievementManager.toggle_panel()

# 檢查面板是否可見
KND_AchievementManager.is_panel_visible()
```

#### 重置功能
```gdscript
# 重置所有成就
KND_AchievementManager.reset_all()

# 重置單個成就
KND_AchievementManager.reset_achievement("achievement_id")
```
