---
title: 演員移動
order: 3
---

# 演員移動

## 功能描述
將指定的角色移動到指定的位置。


## 語法結構
```text
actor move [角色ID] [目標v] [目標h]
```

## 參數詳解
| 參數 | 必需 | 範例 | 說明 |
|------|------|------|------|
| 角色ID | 是 | `alice` | 角色資源識別碼 |
| 目標v | 是 | `3` | 目標位置的 x 座標 |
| 目標h | 是 | `5` | 目標位置的 y 座標 |

關於座標，請參考[演員座標和縮放](/tc/tutorial/actor-coordinate-and-scaling)

## 範例

```text
actor move alice 3 5
```
