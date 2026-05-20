---
title: 存档系统
order: 2
---

# 存档系统

## 使用方法

### 保存游戏

```gdscript
# 保存到指定槽位
dialogue_manager.save_game(1)  # 保存到 1 号槽位

# 或者直接使用存档系统
save_system.save_game(2)  # 保存到 2 号槽位
```

### 加载游戏

```gdscript
# 从指定槽位加载
dialogue_manager.load_game(1)  # 从 1 号槽位加载

# 或者直接使用存档系统
save_system.load_game(2)  # 从 2 号槽位加载
```

### 删除存档

```gdscript
# 删除指定槽位的存档
dialogue_manager.delete_save(1)  # 删除 1 号槽位的存档

# 或者直接使用存档系统
save_system.delete_save(2)  # 删除 2 号槽位的存档
```

### 获取存档信息

```gdscript
# 获取指定槽位的存档信息
var save_info = dialogue_manager.get_save_info(1)
print("存档时间: " + str(save_info.get("save_time", {})))

# 获取所有存档信息
var all_save_infos = dialogue_manager.get_all_save_info()
for i in range(all_save_infos.size()):
    if all_save_infos[i].get("exists", false):
        print("存档 " + str(i) + " 存在")
```

### 配置存档策略

```gdscript
# 自定义存档策略
var custom_strategy = {
    "include_dialogue_state": true,    # 包含对话状态
    "include_variables": true,          # 包含变量
    "include_audio_state": false,       # 不包含音频状态
    "include_actor_state": false,       # 不包含演员状态
    "include_background_state": false   # 不包含背景状态
}

dialogue_manager.set_save_strategy(custom_strategy)
```

## 存档数据结构

存档数据包含以下内容：

- **dialogue_state** - 对话状态，包括当前镜头、对话索引和对话状态
- **variables** - 游戏变量
- **audio_state** - 音频状态（预留）
- **actor_state** - 演员状态（预留）
- **background_state** - 背景状态（预留）
- **save_time** - 存档时间
- **version** - 存档版本



## 存档文件格式

存档文件使用 JSON 格式存储，保存在 `user://saves/` 目录下，文件名为 `[槽位ID].sav`。