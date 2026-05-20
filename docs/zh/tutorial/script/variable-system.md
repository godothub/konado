---
title: 变量系统
order: 8
---

# 变量系统

## 功能概述

变量系统允许在脚本中定义、读取、修改和判断变量，实现动态对话内容、条件分支和状态追踪。变量值可以在对话文本中直接引用，也可以作为条件判断的依据来控制剧情走向。

变量分为两种类型：

| 类型 | 前缀 | 生命周期 | 持久化 | 初始化方式 |
|------|------|----------|--------|------------|
| 持久变量 | `%` | 跨镜头保留 | 随存档保存 | 检查器中预设 / 代码初始化 |
| 临时变量 | `$` | 仅当前镜头有效 | 不保存 | 脚本内 `set` 初始化 |

---

## 变量操作

支持五种基本操作，语法格式为：

```
<操作> <变量名> <值>
```

或带等号的形式：

```
<操作> <变量名> = <值>
```

### 操作列表

| 操作 | 说明 | 示例 |
|------|------|------|
| `set` | 设置变量值 | `set %love = 10` |
| `add` | 加法（数值相加，字符串拼接） | `add %love 5` |
| `sub` | 减法 | `sub %love 3` |
| `mul` | 乘法 | `mul %love 2` |
| `div` | 除法（除数为零时报错） | `div %love 4` |

### 参数详解

| 参数 | 必需 | 示例 | 说明 |
|------|------|------|------|
| 操作 | 是 | `set` | 五种操作之一 |
| 变量名 | 是 | `%love` | `%` 开头为持久变量，`$` 开头为临时变量 |
| 值 | 是 | `10` | 整数、浮点数、布尔值（`true`/`false`）或字符串（双引号包裹） |

### 示例

```
set %love = 10
add %love 5
sub %love 3
mul %love 2
div %love 4

set $round = 1
add $round 1

set %player_name "玩家"
set $stage "新手村"
set %unlocked true
```

---

## 变量插值

在对话文本中直接使用 `%变量名` 或 `$变量名` 引用变量值，运行时会被替换为实际值。

### 语法

```
"角色名" "对话文本，包含 %变量名 或 $变量名"
```

### 示例

```
set %player_name "小明"
set $stage "新手村"

"Kona" "你好，%player_name！你现在在 $stage。"
"Kona" "你的好感度是 %love，当前是第 $round 回合。"
```

运行时输出：

```
Kona: "你好，小明！你现在在 新手村。"
Kona: "你的好感度是 12，当前是第 2 回合。"
```

---

## 条件判断

使用 `if` / `else` / `endif` 结构，根据变量值决定播放哪段对话。支持六种比较运算符。

### 语法结构

```
if <变量名> <运算符> <值>:
    <对话内容>
else:
    <对话内容>
endif
```

`else:` 块为可选，省略时条件不成立则跳过整个 `if` 块。

### 支持的运算符

| 运算符 | 说明 | 示例 |
|--------|------|------|
| `==` | 等于 | `if %love == 5:` |
| `!=` | 不等于 | `if %love != 10:` |
| `>` | 大于 | `if %love > 3:` |
| `<` | 小于 | `if %love < 10:` |
| `>=` | 大于等于 | `if %love >= 5:` |
| `<=` | 小于等于 | `if %love <= 5:` |

### 参数详解

| 参数 | 必需 | 示例 | 说明 |
|------|------|------|------|
| 变量名 | 是 | `%love` | `%` 持久变量或 `$` 临时变量 |
| 运算符 | 是 | `==` | 六种比较运算符之一 |
| 值 | 是 | `5` | 整数比较值 |

### 示例

```
if %love == 5:
    "Kona" "好感度正好是 5！"
else:
    "Kona" "好感度不是 5。"
endif

if $score >= 80:
    "Kona" "良好！"
endif

if $score >= 60:
    "Kona" "及格。"
endif
```

### 注意事项

1. `if` / `else` / `endif` 必须与所在上下文的缩进层级一致；
2. 条件判断**不支持嵌套**，即 `if` 块内不能再包含 `if`；
3. 多个独立的条件判断应使用平铺的 `if` / `endif` 结构，而非嵌套；
4. 条件判断可在 `branch` 分支块内使用。

---

## 分支内使用条件判断

`branch` 块内可以包含 `if` / `endif` 条件判断，实现分支内的动态对话。

### 示例

```
branch after_choice
    "Kona" "你的选择已被记录。"

    if $choice_made == 1:
        "Kona" "你选择了送礼物，真是个温柔的人呢。"
    endif

    if $choice_made == 2:
        "Kona" "你选择了聊天，沟通很重要。"
    endif

    if $choice_made == 3:
        "Kona" "你选择了无视...也许下次可以试试别的选项。"
    endif
```

---

## 选项联动变量

结合 `choice` 和 `branch`，可以在用户做出选择后修改变量值，实现选择影响后续剧情。

### 示例

```
set $choice_made = 0

choice "送礼物（好感+10）" -> gift_choice
choice "聊天（好感+5）" -> chat_choice
choice "无视（好感-5）" -> ignore_choice

branch gift_choice
    add %love 10
    set $choice_made = 1
    "Kona" "谢谢你！好感度提升到 %love！"
    jump_branch after_choice

branch chat_choice
    add %love 5
    set $choice_made = 2
    "Kona" "和你聊天很开心，好感度现在是 %love。"
    jump_branch after_choice

branch ignore_choice
    sub %love 5
    set $choice_made = 3
    "Kona" "......好感度降到了 %love。"
    jump_branch after_choice

branch after_choice
    "Kona" "你的选择已被记录。"
```

---

## 布尔变量

变量支持布尔类型，使用 `true` / `false` 赋值。在条件判断中，`true` 等价于 `1`，`false` 等价于 `0`。

### 示例

```
set %unlocked true
set $visited false

if %unlocked == 1:
    "Kona" "功能已解锁！"
endif

set $visited true
if $visited == 1:
    "Kona" "已访问标记已设置。"
endif
```

---

## 变量初始化

### 持久变量（%）

持久变量需要在脚本运行前初始化。有两种方式：

**方式一：检查器预设（推荐）**

在编辑器中创建 `KND_VariableStore` 资源，在检查器中设置初始变量值，然后赋值给 `KND_DialogueManager` 的 `variable_store` 属性。

**方式二：代码初始化**

```gdscript
func _ready() -> void:
    if dialogue_manager.variable_store == null:
        var store = KND_VariableStore.new()
        store.set_value("love", 0)
        store.set_value("player_name", "")
        store.set_value("unlocked", false)
        dialogue_manager.variable_store = store
```

### 临时变量（$）

临时变量无需预设，在脚本中首次使用 `set` 时自动创建。切换镜头时自动重置。

---

## 完整示例

以下是一个综合演示，涵盖所有变量功能：

```
play bgm echo
background bg1 fade

actor show 可娜 正常 at 3 9 scale 0.3
"Kona" "欢迎来到变量系统演示！"

set %love = 10
"Kona" "好感度设为 10，现在是：%love"

add %love 5
"Kona" "加 5 后好感度：%love"

sub %love 3
"Kona" "减 3 后好感度：%love"

mul %love 2
"Kona" "乘 2 后好感度：%love"

div %love 4
"Kona" "除 4 后好感度：%love"

set $round = 1
set $bonus = 100
"Kona" "回合=$round，奖金=$bonus"

add $round 1
add $bonus 50
"Kona" "第 $round 回合，奖金 $bonus"

set %player_name "玩家"
"Kona" "你好，%player_name！好感度 %love，第 $round 回合。"

if %love == 6:
    "Kona" "好感度正好是 6！"
else:
    "Kona" "好感度不是 6。"
endif

if %love > 3:
    "Kona" "好感度大于 3！"
endif

if %love < 10:
    "Kona" "好感度小于 10。"
endif

set $score = 85

if $score >= 90:
    "Kona" "优秀！"
endif

if $score >= 80:
    "Kona" "良好！"
endif

set %unlocked true
if %unlocked == 1:
    "Kona" "功能已解锁！"
endif

choice "送礼物（好感+10）" -> gift
choice "无视（好感-5）" -> ignore

branch gift
    add %love 10
    "Kona" "谢谢你！好感度 %love！"
    jump_branch done

branch ignore
    sub %love 5
    "Kona" "......好感度 %love。"
    jump_branch done

branch done
    actor exit 可娜
    background bg_end fade
    end
```

---

## 注意事项

1. **变量名**只能包含字母、数字和下划线，区分大小写；
2. **持久变量**（`%`）的值会随存档保存，适合记录好感度、剧情标记等跨镜头状态；
3. **临时变量**（`$`）在切换镜头时自动清空，适合记录当前镜头内的临时状态；
4. **除法操作**时除数为零会触发错误并跳过该操作；
5. **条件判断**不支持嵌套，多个条件请使用平铺的 `if` / `endif` 结构；
6. 在 `branch` 块内使用条件判断时，`if` / `endif` 的缩进需与分支内其他内容一致；
7. 未初始化的变量在条件判断中视为条件不成立。
