# 分支故事示例
# 展示：选择分支、变量操作、条件跳转、信号

# ==== 初始化 ====
play bgm main_theme
background cafe_inside fade
actor show Kona 正常 at 2

set %love = 0
set $round = 1

# ==== 开场 ====
"Kona" "欢迎来到咖啡厅！我是服务生 Kona。"
"Kona" "你想要点什么？"
"narrator" "第 $round 回合 —— 好感度：%love"

# ==== 第一轮选择 ====
choice "点一杯咖啡（好感+10）" -> coffee_choice
choice "点一杯茶（好感+5）" -> tea_choice
choice "什么都不点就离开" -> leave_early

# ==== 咖啡分支 ====
branch coffee_choice
    add %love 10
    set $round = 2
    actor change Kona 害羞
    "Kona" "好的，一杯温热的美式咖啡马上就来！"
    "Kona" "你看起来很喜欢咖啡呢。"
    signal 好感度上升
    jump_branch round_two

# ==== 茶分支 ====
branch tea_choice
    add %love 5
    set $round = 2
    actor change Kona 正常
    "Kona" "红茶很不错，我也很喜欢。"
    "Kona" "慢慢享用吧。"
    signal 好感度上升
    jump_branch round_two

# ==== 提前离开分支 ====
branch leave_early
    sub %love 5
    actor change Kona 惊讶
    "Kona" "诶？这么快就要走了吗..."
    "Kona" "下次再来吧。"
    signal 好感度下降
    actor exit Kona
    background bg_end fade
    play bgm ending_theme
    end

# ==== 第二轮 ====
branch round_two
    "narrator" "第 $round 回合 —— 好感度：%love"

    if %love >= 10:
        "Kona" "我们的关系似乎不错呢！"
    endif

    if %love < 10:
        "Kona" "还需要更多时间了解彼此呢。"
    endif

    choice "聊聊天（好感+5）" -> chat_choice
    choice "送礼物（好感+15）" -> gift_choice
    choice "道别离开" -> goodbye_choice

# ==== 聊天分支 ====
branch chat_choice
    add %love 5
    set $round = 3
    actor change Kona 害羞
    "Kona" "和你聊天很开心呢。"
    "Kona" "你平时喜欢做什么？"
    signal 好感度上升
    jump_branch round_three

# ==== 送礼分支 ====
branch gift_choice
    add %love 15
    set $round = 3
    actor change Kona 害羞
    "Kona" "哇！这是送给我的吗？"
    "Kona" "太感谢了，我一定会好好珍惜的！"
    signal 好感度大幅上升
    jump_branch round_three

# ==== 道别分支 ====
branch goodbye_choice
    actor change Kona 正常
    "Kona" "好的，今天很高兴见到你。"
    "Kona" "下次再来玩哦！"
    signal 好感度下降
    actor exit Kona
    background bg_end fade
    end

# ==== 第三轮 ====
branch round_three
    "narrator" "第 $round 回合 —— 好感度：%love"

    if %love >= 20:
        "Kona" "我觉得我们已经是好朋友了！"
        "Kona" "下次再来咖啡厅，我给你特调一杯！"
    endif

    if %love >= 10:
        "Kona" "和你在一起很开心，希望还能再见面。"
    endif

    if %love < 5:
        "Kona" "期待下次与你更好的相遇。"
    endif

    "Kona" "今天真是美好的一天，谢谢你！"
    actor change Kona 害羞
    "Kona" "再见啦！"
    actor exit Kona
    background bg_end fade
    stop bgm
    play bgm ending_theme
    end