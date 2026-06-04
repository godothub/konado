---
title: 分支
order: 4
---

# 分支

## 功能描述

分支是用于组织脚本内容的一种方式，通过分支可以方便地管理和调用脚本中的不同部分，用于实现复杂的跳转逻辑，该功能一般搭配选项使用。

可以将标签理解为脚本中的“书签”，通过标签可以快速定位到脚本中的特定位置，由标签和缩进包裹的内容即为标签的内容，这部分脚本内容在执行当前标签对话的时候，会被添加到对话列表中，否则只会保存到标签对话中，不会触发播放。

分支不可以**嵌套使用**，分支的缩进层级必须和对话的缩进层级一致，否则会导致无法正常解析，以下是错误的示例：

```text
# 错误的示例：嵌套使用
branch drink_water
    "kona" "我想喝水"
        branch eat_cake
            "kona" "我想吃蛋糕"

# 错误的示例：缩进层级不一致，导致分支内无内容
branch drink_tea
"kona" "我想喝茶"
```

一般正确的分支结合选项使用，例如：

```
choice "送花（好感+10）" -> gift_flower

choice "送书（好感+5）" -> gift_book

choice "什么都不送（好感-5）" -> gift_none

choice "离开" -> exit_choice

branch gift_flower
    actor change Kona 害羞
    "Kona" "哇，花很漂亮！谢谢你！"
    
    choice "继续聊天" -> chat_more
    choice "告别离开" -> exit_choice

branch gift_book
    actor change Kona 惊讶
    "Kona" "这本书看起来很有趣，谢谢！"
    
    choice "继续聊天" -> chat_more
    choice "告别离开" -> exit_choice

branch gift_none
    actor change Kona 正常
    "Kona" "没关系，下次再送吧。"
    
    choice "继续聊天" -> chat_more
    choice "告别离开" -> exit_choice

branch chat_more
    actor change Kona 正常
    "Kona" "你想聊什么话题呢？"
    
    choice "聊聊旅行" -> topic_travel
    choice "聊聊美食" -> topic_food
    choice "告别离开" -> exit_choice

branch topic_travel
    actor change Kona 惊讶
    "Kona" "我也很喜欢旅行！下次一起去吧！"
    
    choice "送花" -> gift_flower
    choice "告别离开" -> exit_choice

branch topic_food
    actor change Kona 害羞
    "Kona" "美食话题我最喜欢了！"
    
    choice "送书" -> gift_book
    choice "告别离开" -> exit_choice

branch exit_choice
    actor change Kona 正常
    "Kona" "再见，期待下次见面！"
    actor exit Kona
    background bg_end fade
    end
```


## 语法结构
```text
branch [标签ID]
    [脚本内容]
```

## 参数详解
| 参数 | 必需 | 示例 | 说明 |
|------|------|------|------|
| 标签ID | 是 | `drink_water` | 标签标识符 |


## 示例

```text
branch drink_water
    "kona" "我想喝水"
branch drink_tea
    "kona" "我想喝茶"
```
