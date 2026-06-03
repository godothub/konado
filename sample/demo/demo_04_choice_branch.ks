# 选项系统测试剧本

background 01 fade

actor show Kona 正常 at 1

"Kona" "你好！这是一个选项交互测试。"

"Kona" "请选择你想要赠送的礼物："

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