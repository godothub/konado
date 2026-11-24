play bgm echo [fade=2.0]
screentext {
    "전체 화면 텍스트입니다"
    "전체 화면 텍스트입니다"
    "전체 화면 텍스트입니다"
}
background bg_para none
asyncam shake 10.0
asyncam stop
actor show Kona 正常 at 3
showtextbox 1.2
Kona "안녕하세요! 저희 카페에 오신 것을 환영합니다." voice_01
asyncam move cam2 linear 1.0
achievement unlock "first_blood"
achievement increment "explorer" 1
achievement set_flag "secret_ending_found" true
actor move Kona 1
actor change Kona 介绍说话
Kona "Konado로 함께 비주얼 노벨을 만들어 봐요!"
asyncam move cam1 linear 1.0
actor exit Kona
asyncam reset linear 1.0
jump res://sample/demo/demo_02.ks
