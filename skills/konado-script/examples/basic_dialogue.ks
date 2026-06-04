# 基础对话示例
# 展示：普通对话、场景切换、BGM、演员创建与退场

# ==== 场景初始化 ====
play bgm peaceful_morning
background morning_forest fade
actor show Kona 正常 at 2

# ==== 开场对话 ====
"Kona" "早上好！今天天气真好。"
"narrator" "阳光透过树叶洒在小路上，微风轻拂过脸庞。"

# ==== 互动对话 ====
"Kona" "你准备好开始今天的冒险了吗？"
"narrator" "Kona 微笑着看向你，眼中闪烁着期待。"
"Kona" "让我带你去看看周围的风景吧。" kona_happy_01

# ==== 场景切换 ====
actor exit Kona
background night_street fade
play bgm tension_theme
actor show Kona 害羞 at 3

# ==== 新场景 ====
"Kona" "天色渐渐暗下来了..."
"Kona" "但我并不害怕，因为有你在身边。"
"narrator" "夜幕降临，路灯亮起，照亮了前方的道路。"

# ==== 尾声 ====
stop bgm
play bgm ending_theme
actor change Kona 正常
"Kona" "今天的旅程就到这里，我们下次再见！"
actor exit Kona
background bg_end fade
end