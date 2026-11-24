# 播放bgm语句，<bgm名称>为背景列表中的bgm_name
play bgm echo [fade=2.0]

screentext {
    "这是全屏文本"
    "这是全屏文本"
    "这是全屏文本"
}

# 背景语句：
# background bg1 windmill
# background bg1 wave
# background bg1 erase
# background bg1 cyberglitch
# 背景名称后面的代号为效果，效果有9种可以自己试试。
background bg_para none
asyncam shake 10.0
asyncam stop
# 演员显示语句：actor show <角色名称> <角色状态> at <x坐标>
# 写mirror会使演员镜像显示（位置不变）
actor show Kona 正常 at 3
# 多次show兼容，让已创建节点转为新状态
#actor show Kona 正常 at 2

showtextbox 1.2

#waitsignal over

# 对话语句：
# 第一个""中为名字，第二个""中为对话内容，后面的编号为语音列表中的voice_name
Kona "你好！欢迎来到我们的咖啡馆。" voice_01

asyncam move cam2 linear 1.0

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

Kona "和我一起用Konado做视觉小说吧！"

asyncam move cam1 linear 1.0

# 演员退出
actor exit Kona

asyncam reset linear 1.0

# 跳转语句，可以打开demo_02继续看示例文件的分支部分。
jump res://sample/demo/demo_02.ks
