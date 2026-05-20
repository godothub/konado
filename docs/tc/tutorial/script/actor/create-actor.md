---
title: 建立演員
order: 1
---

# 建立演員

## 功能描述

在對話場景中建立一個演員

## 語法結構

```text
actor show [角色 ID] [狀態] at [v] [h] scale [比例] <mirror>
```

## 參數詳解
| 參數 | 必填 | 範例 | 說明 |
|------|------|------|------|
| 角色 ID | 是 | `alice` | 角色資源識別碼 |
| 狀態 | 是 | `angry` | 立繪狀態 |
| 橫向座標 | 是 | `2` | 水平位置 |
| 縱向座標 | 是 | `5` | 垂直位置 |
| 比例 | 是 | `1.3` | 縮放比例 |
| mirror | 否 | - | 水平鏡像翻轉 |



## 範例
```text
# 顯示角色（正常狀態）
actor show alice normal at 2 5 scale 1.3

# 顯示角色（水平鏡像翻轉）
actor show alice normal at 2 5 scale 1.3 mirror
```
