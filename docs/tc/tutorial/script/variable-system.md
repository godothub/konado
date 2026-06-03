---
title: 變數系統
order: 8
---

# 變數系統

## 功能概述

變數系統允許在腳本中定義、讀取、修改和判斷變數，實現動態對話內容、條件分支和狀態追蹤。變數值可以在對話文字中直接引用，也可以作為條件判斷的依據來控制劇情走向。

變數分為兩種類型：

| 類型 | 前綴 | 生命週期 | 持久化 | 初始化方式 |
|------|------|----------|--------|------------|
| 持久變數 | `%` | 跨鏡頭保留 | 隨存檔保存 | 檢查器中預設 / 程式碼初始化 |
| 臨時變數 | `$` | 僅目前鏡頭有效 | 不保存 | 腳本內 `set` 初始化 |

---

## 變數操作

支援五種基本操作，語法格式為：

```
<操作> <變數名> <值>
```

或帶等號的形式：

```
<操作> <變數名> = <值>
```

### 操作列表

| 操作 | 說明 | 範例 |
|------|------|------|
| `set` | 設定變數值 | `set %love = 10` |
| `add` | 加法（數值相加、字串串接） | `add %love 5` |
| `sub` | 減法 | `sub %love 3` |
| `mul` | 乘法 | `mul %love 2` |
| `div` | 除法（除數為零時報錯） | `div %love 4` |

### 參數詳解

| 參數 | 必需 | 範例 | 說明 |
|------|------|------|------|
| 操作 | 是 | `set` | 五種操作之一 |
| 變數名 | 是 | `%love` | `%` 開頭為持久變數，`$` 開頭為臨時變數 |
| 值 | 是 | `10` | 整數、浮點數、布林值（`true`/`false`）或字串（以雙引號包裹） |

### 範例

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

## 變數插值

在對話文字中直接使用 `%變數名` 或 `$變數名` 引用變數值，執行時會被替換為實際值。

### 語法

```
"角色名" "對話文字，包含 %變數名 或 $變數名"
```

### 範例

```
set %player_name "小明"
set $stage "新手村"

"Kona" "你好，%player_name！你現在在 $stage。"
"Kona" "你的好感度是 %love，目前是第 $round 回合。"
```

執行時輸出：

```
Kona: "你好，小明！你現在在 新手村。"
Kona: "你的好感度是 12，目前是第 2 回合。"
```

---

## 條件判斷

使用 `if` / `else` / `endif` 結構，根據變數值決定播放哪段對話。支援六種比較運算子。

### 語法結構

```
if <變數名> <運算子> <值>:
    <對話內容>
else:
    <對話內容>
endif
```

`else:` 區塊為可選；省略時，若條件不成立就會跳過整個 `if` 區塊。

### 支援的運算子

| 運算子 | 說明 | 範例 |
|--------|------|------|
| `==` | 等於 | `if %love == 5:` |
| `!=` | 不等於 | `if %love != 10:` |
| `>` | 大於 | `if %love > 3:` |
| `<` | 小於 | `if %love < 10:` |
| `>=` | 大於等於 | `if %love >= 5:` |
| `<=` | 小於等於 | `if %love <= 5:` |

### 參數詳解

| 參數 | 必需 | 範例 | 說明 |
|------|------|------|------|
| 變數名 | 是 | `%love` | `%` 持久變數或 `$` 臨時變數 |
| 運算子 | 是 | `==` | 六種比較運算子之一 |
| 值 | 是 | `5` | 整數比較值 |

### 範例

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

### 注意事項

1. `if` / `else` / `endif` 必須與所在上下文的縮排層級一致；
2. 條件判斷**不支援巢狀結構**，也就是 `if` 區塊內不能再包含 `if`；
3. 多個獨立的條件判斷應使用平鋪的 `if` / `endif` 結構，而不是巢狀結構；
4. 條件判斷可在 `branch` 分支區塊內使用。

---

## 分支內使用條件判斷

`branch` 區塊內可以包含 `if` / `endif` 條件判斷，實現分支內的動態對話。

### 範例

```
branch after_choice
    "Kona" "你的選擇已被記錄。"

    if $choice_made == 1:
        "Kona" "你選擇了送禮物，真是個溫柔的人呢。"
    endif

    if $choice_made == 2:
        "Kona" "你選擇了聊天，溝通很重要。"
    endif

    if $choice_made == 3:
        "Kona" "你選擇了無視……也許下次可以試試別的選項。"
    endif
```

---

## 選項聯動變數

結合 `choice` 和 `branch`，可以在使用者做出選擇後修改變數值，實現選擇影響後續劇情。

### 範例

```
set $choice_made = 0

choice "送禮物（好感+10）" -> gift_choice
choice "聊天（好感+5）" -> chat_choice
choice "無視（好感-5）" -> ignore_choice

branch gift_choice
    add %love 10
    set $choice_made = 1
    "Kona" "謝謝你！好感度提升到 %love！"
    jump_branch after_choice

branch chat_choice
    add %love 5
    set $choice_made = 2
    "Kona" "和你聊天很開心，好感度現在是 %love。"
    jump_branch after_choice

branch ignore_choice
    sub %love 5
    set $choice_made = 3
    "Kona" "……好感度降到了 %love。"
    jump_branch after_choice

branch after_choice
    "Kona" "你的選擇已被記錄。"
```

---

## 布林變數

變數支援布林類型，使用 `true` / `false` 賦值。在條件判斷中，`true` 等價於 `1`，`false` 等價於 `0`。

### 範例

```
set %unlocked true
set $visited false

if %unlocked == 1:
    "Kona" "功能已解鎖！"
endif

set $visited true
if $visited == 1:
    "Kona" "已設定訪問標記。"
endif
```

---

## 變數初始化

### 持久變數（%）

持久變數需要在腳本執行前初始化。有兩種方式：

**方式一：檢查器預設（推薦）**

在編輯器中建立 `KND_VariableStore` 資源，在檢查器中設定初始變數值，然後賦值給 `KND_DialogueManager` 的 `variable_store` 屬性。

**方式二：程式碼初始化**

```gdscript
func _ready() -> void:
    if dialogue_manager.variable_store == null:
        var store = KND_VariableStore.new()
        store.set_value("love", 0)
        store.set_value("player_name", "")
        store.set_value("unlocked", false)
        dialogue_manager.variable_store = store
```

### 臨時變數（$）

臨時變數無需預設，在腳本中首次使用 `set` 時會自動建立。切換鏡頭時會自動重設。

---

## 完整範例

以下是一個綜合示範，涵蓋所有變數功能：

```
play bgm echo
background bg1 fade

actor show 可娜 正常 at 3 9 scale 0.3
"Kona" "歡迎來到變數系統示範！"

set %love = 10
"Kona" "好感度設為 10，現在是：%love"

add %love 5
"Kona" "加 5 後好感度：%love"

sub %love 3
"Kona" "減 3 後好感度：%love"

mul %love 2
"Kona" "乘 2 後好感度：%love"

div %love 4
"Kona" "除 4 後好感度：%love"

set $round = 1
set $bonus = 100
"Kona" "回合=$round，獎金=$bonus"

add $round 1
add $bonus 50
"Kona" "第 $round 回合，獎金 $bonus"

set %player_name "玩家"
"Kona" "你好，%player_name！好感度 %love，第 $round 回合。"

if %love == 6:
    "Kona" "好感度正好是 6！"
else:
    "Kona" "好感度不是 6。"
endif

if %love > 3:
    "Kona" "好感度大於 3！"
endif

if %love < 10:
    "Kona" "好感度小於 10。"
endif

set $score = 85

if $score >= 90:
    "Kona" "優秀！"
endif

if $score >= 80:
    "Kona" "良好！"
endif

set %unlocked true
if %unlocked == 1:
    "Kona" "功能已解鎖！"
endif

choice "送禮物（好感+10）" -> gift
choice "無視（好感-5）" -> ignore

branch gift
    add %love 10
    "Kona" "謝謝你！好感度 %love！"
    jump_branch done

branch ignore
    sub %love 5
    "Kona" "……好感度 %love。"
    jump_branch done

branch done
    actor exit 可娜
    background bg_end fade
    end
```

---

## 注意事項

1. **變數名**只能包含字母、數字和底線，並區分大小寫；
2. **持久變數**（`%`）的值會隨存檔保存，適合記錄好感度、劇情標記等跨鏡頭狀態；
3. **臨時變數**（`$`）在切換鏡頭時自動清空，適合記錄目前鏡頭內的臨時狀態；
4. **除法操作**時除數為零會觸發錯誤並跳過該操作；
5. **條件判斷**不支援巢狀結構，多個條件請使用平鋪的 `if` / `endif` 結構；
6. 在 `branch` 區塊內使用條件判斷時，`if` / `endif` 的縮排需與分支內其他內容一致；
7. 未初始化的變數在條件判斷中視為條件不成立。
