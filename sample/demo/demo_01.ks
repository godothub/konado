# 播放bgm语句，<bgm名称>为背景列表中的bgm_name
play bgm echo

# 背景语句：
# background bg1 windmill
# background bg1 wave
# background bg1 erase
# background bg1 cyberglitch
# 背景名称后面的代号为效果，效果有8种可以自己试试。
background bg1 none


# 演员显示语句：actor show <角色名称> <角色状态> at <x坐标> <y坐标> scale <缩放比例> [mirror]
# 写mirror会使演员镜像显示（位置不变）
actor show Kona 正常 at 3

# 对话语句：
# 第一个""中为名字，第二个""中为对话内容，后面的编号为语音列表中的voice_name
"Kona" "你好！欢迎来到我们的咖啡馆。" voice_01

achievement unlock "first_blood"

achievement increment "explorer" 1

achievement set_flag "secret_ending_found" true

# 演员移动指令：actor move Kona 1
# 参数含义：数字 1 为横向列索引
# 定位规则：角色图片以底部为基点显示在对应网格位置
# 屏幕划分份数可在 KonadoDialogueManager 的 UI Settings 中修改
actor move Kona 1

# 改变角色的表情
actor change Kona 介绍说话

"Kona" "和我一起用Konado做视觉小说吧！"

# 演员退出
actor exit Kona


# 跳转语句，可以打开demo_02继续看示例文件的分支部分。
jump res://sample/demo/demo_02.ks

# 结束语句，是关闭对话框的作用
end