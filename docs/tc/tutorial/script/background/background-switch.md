---
title: 背景切換
order: 1
---

# 背景切換

## 功能描述
切換遊戲場景的背景圖片，支援過渡效果

## 語法結構
```text
background [圖片資源名稱] <效果類型>
```

## 參數說明
| 參數 | 必填 | 範例值 | 說明 |
|------|------|--------|------|
| 圖片資源名稱 | 是 | `morning_forest` | 不含副檔名的紋理檔案名稱 |
| 效果類型 | 否 | `fade` | 過渡效果（預設：立即切換） |

### 支援的效果類型

以下是支援的背景切換效果類型，每種效果都有其獨特的視覺效果：

| 效果 | 描述 |
|------|------|
| `none` | 立即切換 |
| `fade` | 淡入淡出 |
| `erase` | 擦除 |
| `blinds` | 百葉窗 | 
| `wave` | 波浪 |
| `vortex` | 旋渦 |
| `windmill` | 風車 |
| `cyberglitch` | 賽博故障 |

如果不指定效果類型，預設使用 `none`（立即切換）


## 範例
```text
# 白天切換到夜晚（淡入效果）
background night_street fade

# 戰鬥場景切換（立即切換）
background battle_field none

# 回憶場景（擦除效果）
background memory_flash erase

# 夢幻場景（旋渦效果）
background dream vortex
```
