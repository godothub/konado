background 00 fade


if %love == 0:
    "" "看来你是新手呢"
else:
    "" "你应该已经学会了"
endif

# 逻辑判断 %是获取变量
# 此处变量在KonadoDialogueManager的Global Variable处设置。
if %love <= 0:
    "" "要开始吗？"
else:
    "" "要再看一遍吗？"
endif


choice "开始" -> start_choice

choice "不看了" -> exit_choice

choice "我要看看变量系统" -> goto_ks3

branch start_choice
    background 01 fade
    actor show 可娜 介绍正常 at 1 9 scale 0.3
    "Kona" "首先将Konado加载进插件列表。"
    background 02 cyberglitch
    actor change 可娜 介绍说话
    "Kona" "如果你是第一次使用，建议先从Demo开始，我带你简单熟悉一下KonadoDialogueManager的设置。"
    actor change 可娜 介绍正常
    "Kona" "在界面左侧场景树中选择KonadoDialogueManager。"
    background 03 cyberglitch
    actor change 可娜 介绍说话
    "Kona" "右侧的属性列表向下拉，Dialogue Resources一栏中储存着对话需要的资源，你可以在这里添加角色立绘、背景、音乐、语音、音效等。"
    background 04 cyberglitch
    "Kona" "下一步就可以编辑对话了，请在界面最上方点击Konado进入脚本页面。"
    actor change 可娜 介绍正常
    "Kona" "您可以在此打开示例文件，更多的命令教学请查看文档。"
    actor change 可娜 正常
    "Kona" "感谢你的使用，简易介绍就到这里！"
    actor exit 可娜

    # 会发射一个参数为"好感度上升"的信号！
    signal 好感度上升
    
    # 回到开始询问玩家是否再来一遍
    jump res://sample/demo/demo_02.ks
    

branch exit_choice
    actor show 可娜 正常 at 1 9 scale 0.3
    "Kona" "感谢你的使用，再见！"
    actor exit 可娜
    background bg_end fade
    end
    
branch goto_ks3
    jump res://sample/demo/demo_03_variable.ks
# 一定要随时点上面红色的保存按钮啊！Ctrl+S不保存脚本的！