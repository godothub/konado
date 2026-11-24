play bgm echo [fade=2.0]
screentext {
    "這是全螢幕文字"
    "這是全螢幕文字"
    "這是全螢幕文字"
}
background bg_para none
asyncam shake 10.0
asyncam stop
actor show Kona 正常 at 3
showtextbox 1.2
Kona "你好！歡迎來到我們的咖啡館。" voice_01
asyncam move cam2 linear 1.0
achievement unlock "first_blood"
achievement increment "explorer" 1
achievement set_flag "secret_ending_found" true
actor move Kona 1
actor change Kona 介绍说话
Kona "和我一起用 Konado 製作視覺小說吧！"
asyncam move cam1 linear 1.0
actor exit Kona
asyncam reset linear 1.0
jump res://sample/demo/demo_02.ks
