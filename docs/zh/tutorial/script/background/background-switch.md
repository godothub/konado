---
title: 背景切换
order: 1
---

# 背景切换

## 功能描述
切换游戏场景的背景图片，支持过渡效果

## 语法结构
```text
background [图片资源名] <效果类型>
```

## 参数说明
| 参数 | 必需 | 示例值 | 说明 |
|------|------|--------|------|
| 图片资源名 | 是 | `morning_forest` | 不带扩展名的纹理文件名 |
| 效果类型 | 否 | `fade` | 过渡效果（默认：立即切换） |

### 支持的效果类型

以下是支持的背景切换效果类型，每种效果都有其独特的视觉效果：

| 效果 | 描述 |
|------|------|
| `none` | 立即切换 |
| `fade` | 淡入淡出 |
| `erase` | 擦除 |
| `blinds` | 百叶窗 | 
| `wave` | 波浪 |
| `vortex` | 旋涡 |
| `windmill` | 风车 |
| `cyberglitch` | 赛博故障 |

如果不指定效果类型，默认使用`none`（立即切换）


## 示例
```text
# 白天切换到夜晚（淡入效果）
background night_street fade

# 战斗场景切换（立即切换）
background battle_field none

# 回忆场景（擦除效果）
background memory_flash erase

# 梦幻场景（漩涡效果）
background dream vortex
```

