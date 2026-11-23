# ============================================================
# call / return 子程序演示
# call 进入 branch，执行到 return 时回到调用点的下一行。
# ============================================================

background 01 fade

actor show Kona 正常 at 1

Kona "这是一个 call / return 子程序演示。"

Kona "接下来调用一个公用桥段，它会被多处复用。"

call common_greeting

Kona "已经回到调用点之后了，说明 return 生效。"

Kona "再来一次同一个桥段，验证调用栈可以重复使用。"

call common_greeting

Kona "演示结束，感谢观看！"

actor exit Kona
background bg_end fade
end

branch common_greeting
	actor change Kona 害羞
	Kona "（公用桥段：每次被调用都会执行这一段。）"
	actor change Kona 正常
	return
