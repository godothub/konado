---
title: 存檔系統
order: 2
---

# 存檔系統

## 使用方法

### 儲存遊戲

```gdscript
# 儲存到指定槽位
dialogue_manager.save_game(1)  # 儲存到 1 號槽位

# 或者直接使用存檔系統
save_system.save_game(2)  # 儲存到 2 號槽位
```

### 載入遊戲

```gdscript
# 從指定槽位載入
dialogue_manager.load_game(1)  # 從 1 號槽位載入

# 或者直接使用存檔系統
save_system.load_game(2)  # 從 2 號槽位載入
```

### 刪除存檔

```gdscript
# 刪除指定槽位的存檔
dialogue_manager.delete_save(1)  # 刪除 1 號槽位的存檔

# 或者直接使用存檔系統
save_system.delete_save(2)  # 刪除 2 號槽位的存檔
```

### 取得存檔資訊

```gdscript
# 取得指定槽位的存檔資訊
var save_info = dialogue_manager.get_save_info(1)
print("存檔時間: " + str(save_info.get("save_time", {})))

# 取得所有存檔資訊
var all_save_infos = dialogue_manager.get_all_save_info()
for i in range(all_save_infos.size()):
    if all_save_infos[i].get("exists", false):
        print("存檔 " + str(i) + " 存在")
```

### 設定存檔策略

```gdscript
# 自訂存檔策略
var custom_strategy = {
    "include_dialogue_state": true,    # 包含對話狀態
    "include_variables": true,          # 包含變數
    "include_audio_state": false,       # 不包含音訊狀態
    "include_actor_state": false,       # 不包含演員狀態
    "include_background_state": false   # 不包含背景狀態
}

dialogue_manager.set_save_strategy(custom_strategy)
```

## 存檔資料結構

存檔資料包含以下內容：

- **dialogue_state** - 對話狀態，包括目前鏡頭、對話索引和對話狀態
- **variables** - 遊戲變數
- **audio_state** - 音訊狀態（預留）
- **actor_state** - 演員狀態（預留）
- **background_state** - 背景狀態（預留）
- **save_time** - 存檔時間
- **version** - 存檔版本

## 存檔檔案格式

存檔檔案使用 JSON 格式儲存，保存在 `user://saves/` 目錄下，檔案名稱為 `[槽位ID].sav`。
