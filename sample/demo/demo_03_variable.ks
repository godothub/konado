# ============================================================
# Konado 变量系统完整演示
# %变量 = 持久变量（跨镜头保留，随存档保存，可在检查器预设）
# $变量 = 临时变量（仅当前镜头有效，切换镜头时重置）
# ============================================================

play bgm echo
background bg1 fade

# ============================================================
# 第一部分：持久变量（%）基础操作
# %love 已在检查器中预设为 0，这里演示各种操作
# ============================================================

actor show Kona 正常 at 3
"Kona" "欢迎来到变量系统演示！" voice_01
"Kona" "首先来看持久变量（%前缀）的操作。"

actor change Kona 介绍说话

"Kona" "当前好感度是 %love，让我们来修改它。"

# --- SET：设置变量 ---
set %love = 10

"Kona" "使用 set 将好感度设为 10，现在是：%love"

# --- ADD：加法 ---
add %love 5

"Kona" "使用 add 加 5，好感度变为：%love"

# --- SUB：减法 ---
sub %love 3

"Kona" "使用 sub 减 3，好感度变为：%love"

# --- MUL：乘法 ---
mul %love 2

"Kona" "使用 mul 乘 2，好感度变为：%love"

# --- DIV：除法 ---
div %love 4

"Kona" "使用 div 除 4，好感度变为：%love"

actor change Kona 正常

"Kona" "持久变量会随存档保存，切换镜头也不会丢失。"

# ============================================================
# 第二部分：临时变量（$）基础操作
# ============================================================

background 00 fade

actor change Kona 介绍说话

"Kona" "接下来是临时变量（$前缀），只在当前镜头有效。"

# --- SET：初始化临时变量 ---

set $round = 1

set $bonus = 100

"Kona" "初始化了临时变量：回合=$round，奖金=$bonus"

# --- ADD ---
add $round 1

add $bonus 50

"Kona" "第 $round 回合，奖金增加到 $bonus"

# --- SUB ---
sub $bonus 30

"Kona" "扣除一些后奖金为 $bonus"

# --- MUL ---
set $multiplier = 3

mul $bonus 3

"Kona" "三倍奖励！奖金变为 $bonus"

# --- DIV ---
div $bonus 2

"Kona" "平分后每人 $bonus"

actor change Kona 正常

"Kona" "临时变量切换镜头后会重置，不会保存到存档。"

# ============================================================
# 第三部分：变量插值 —— 在对话中引用变量
# ============================================================

background 01 fade
actor change Kona 介绍说话
"Kona" "你可以在对话中直接引用变量值。"

set %player_name "玩家"
set $stage "新手村"
"Kona" "你好，%player_name！你现在在 $stage。"
"Kona" "你的好感度是 %love，当前是第 $round 回合。"

actor change Kona 害羞
"Kona" "字符串变量也可以正常显示哦，%player_name。"

# ============================================================
# 第四部分：条件判断 —— 所有比较运算符
# ============================================================

background 02 cyberglitch
actor change Kona 介绍正常
"Kona" "接下来演示条件判断，支持六种比较运算符。"

# --- == 等于 ---
set %love = 5
if %love == 5:
    "Kona" "== 等于判断：好感度正好是 5！"
else:
    "Kona" "== 判断失败"
endif

# --- != 不等于 ---
if %love != 10:
    "Kona" "!= 不等于判断：好感度确实不是 10。"
else:
    "Kona" "!= 判断失败"
endif

# --- > 大于 ---
if %love > 3:
    "Kona" "> 大于判断：好感度大于 3，关系不错！"
else:
    "Kona" "> 判断失败"
endif

# --- < 小于 ---
if %love < 10:
    "Kona" "< 小于判断：好感度小于 10，还有提升空间。"
else:
    "Kona" "< 判断失败"
endif

# --- >= 大于等于 ---
if %love >= 5:
    "Kona" ">= 大于等于判断：好感度至少是 5。"
else:
    "Kona" ">= 判断失败"
endif

# --- <= 小于等于 ---
if %love <= 5:
    "Kona" "<= 小于等于判断：好感度不超过 5。"
else:
    "Kona" "<= 判断失败"
endif

# ============================================================
# 第五部分：临时变量条件判断
# ============================================================

background 03 cyberglitch
actor change Kona 介绍说话
"Kona" "条件判断也完全支持临时变量（$前缀）。"

set $score = 85

if $score >= 90:
    "Kona" "优秀！"
endif

if $score >= 80:
    "Kona" "良好！$score 分，不错哦。"
endif

if $score >= 60:
    "Kona" "及格，继续努力。"
endif

if $score < 60:
    "Kona" "需要加油了。"
endif

# ============================================================
# 第六部分：布尔变量
# ============================================================

background 04 cyberglitch
actor change Kona 正常
"Kona" "变量也支持布尔类型（true/false）。"

set %unlocked true
set $visited false

if %unlocked == 1:
    "Kona" "布尔变量 %unlocked 为 true，功能已解锁！"
else:
    "Kona" "功能未解锁。"
endif

set $visited true
if $visited == 1:
    "Kona" "临时布尔变量 $visited 已设为 true。"
endif

# ============================================================
# 第七部分：选项 + 变量联动
# ============================================================

background 01 fade
actor change Kona 介绍说话
"Kona" "现在来做一些选择吧，你的选择会影响变量值。"

set $choice_made = 0

choice "送礼物（好感+10）" -> gift_choice
choice "聊天（好感+5）" -> chat_choice
choice "无视（好感-5）" -> ignore_choice

branch gift_choice
    add %love 10
    set $choice_made = 1
    actor change Kona 害羞
    "Kona" "谢谢你！好感度提升到 %love！"
    jump_branch after_choice

branch chat_choice
    add %love 5
    set $choice_made = 2
    actor change Kona 介绍说话
    "Kona" "和你聊天很开心，好感度现在是 %love。"
    jump_branch after_choice

branch ignore_choice
    sub %love 5
    set $choice_made = 3
    actor change Kona 惊讶
    "Kona" "......好感度降到了 %love。"
    jump_branch after_choice

branch after_choice
    background 00 fade
    actor change Kona 正常
    "Kona" "你的选择已被记录。"

    # 根据选择给出不同反馈
    if $choice_made == 1:
        "Kona" "你选择了送礼物，真是个温柔的人呢。"
    endif

    if $choice_made == 2:
        "Kona" "你选择了聊天，沟通很重要。"
    endif

    if $choice_made == 3:
        "Kona" "你选择了无视...也许下次可以试试别的选项。"
    endif
    jump_branch final

branch final
    actor change Kona 害羞
    "Kona" "变量系统演示到此结束，感谢观看！"

    actor exit Kona
    background bg_end fade
    end
