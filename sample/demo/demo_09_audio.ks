# ============================================================
# 音频事件与参数演示：淡入淡出、音量偏移与一次性音效
# 事件定义的编辑方式见 docs/latest/tutorial/core/audio-editor.md
# ============================================================

background 01 fade
actor show Kona 正常 at 1

# 淡入 1.5 秒；命中 res://audio/events 里的事件或旧版 BGM 列表的 echo
play bgm echo [fade=1.5]

Kona "音乐已经淡入。接下来演示按音量偏移播放。"

# [volume=-3] 是在事件音量基础上的 dB 偏移
play bgm echo [fade=0.8] [volume=-3]

Kona "同一首曲子也只会做交叉淡入，不会硬切。"

# 需要 sound_effect_list 中存在同名音效时才会播放
# play sfx ui_click [volume=-4] [count=2]

stop bgm [fade=2.0]

Kona "音乐淡出 2 秒后停止，演示结束。"

actor exit Kona
background bg_end fade
end
