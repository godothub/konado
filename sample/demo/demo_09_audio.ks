# ============================================================
# 音频事件完整演示：RTPC、淡入淡出、音量偏移与音效叠加
# 事件与 Bank 位于 res://audio，接线见 sample/demo/demo.tscn
# ============================================================

background 01 fade
actor show Kona 正常 at 1

# echo 事件绑定了 RTPC：%love 从 0 到 100 时音乐增益从 0.85 升到 1.0
set %love = 0
play bgm echo [fade=1.5]

Kona "好感度为 0 时，事件上的 RTPC 会把音乐压得略轻。"

add %love 100

Kona "好感度拉满后，同一首 BGM 立刻变响，不需要重新播放。"

# [count=3] 同一次指令叠加三次音效，[volume=-4] 再降低 4dB
play sfx ui_click [count=3] [volume=-4]

Kona "一次指令触发三次音效（随机容器 + 并发池），并按 -4dB 播放。"

# 再播放同一事件会做交叉淡入，而不是硬切
play bgm echo [fade=0.8] [volume=-3]

Kona "重新播放同一事件只做交叉淡入，音量再低 3dB。"

stop bgm [fade=2.0]

Kona "音乐淡出两秒后停止，演示结束。"

actor exit Kona
background bg_end fade
end
