# ============================================================
# 条件选项（if）与一次性选项（once）演示
# ============================================================

background 01 fade
actor show Kona 正常 at 1

if %love == 0:
	Kona "这个演示会用到好感度变量，当前是 0。"
else:
	Kona "当前好感度是 %love。"

endif

jump_branch menu

branch menu
	choice "普通选项：随便聊聊" -> chat
	choice "条件选项：好感度 5 以上才能选" -> gift if %love >= 5
	choice "一次性选项：只能问一次" -> rumor once
	choice "离开" -> leave

branch chat
	Kona "好呀，我们聊聊。"
	jump_branch menu

branch gift
	Kona "谢谢你的礼物！好感度 +1。"
	add %love 1
	jump_branch menu

branch rumor
	Kona "我只告诉你一次：据说图书馆的钟声会停在午夜。"
	jump_branch menu

branch leave
	Kona "再见，期待下次见面！"
	actor exit Kona
	background bg_end fade
	end
