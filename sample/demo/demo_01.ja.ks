play bgm echo [fade=2.0]
screentext {
    "これは全画面テキストです"
    "これは全画面テキストです"
    "これは全画面テキストです"
}
background bg_para none
asyncam shake 10.0
asyncam stop
actor show Kona 正常 at 3
showtextbox 1.2
Kona "こんにちは！私たちのカフェへようこそ。" voice_01
asyncam move cam2 linear 1.0
achievement unlock "first_blood"
achievement increment "explorer" 1
achievement set_flag "secret_ending_found" true
actor move Kona 1
actor change Kona 介绍说话
Kona "Konadoで一緒にビジュアルノベルを作りましょう！"
asyncam move cam1 linear 1.0
actor exit Kona
asyncam reset linear 1.0
jump res://sample/demo/demo_02.ks
