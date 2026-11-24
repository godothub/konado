play bgm echo [fade=2.0]
screentext {
    "This is full-screen text"
    "This is full-screen text"
    "This is full-screen text"
}
background bg_para none
asyncam shake 10.0
asyncam stop
actor show Kona 正常 at 3
showtextbox 1.2
Kona "Hello! Welcome to our cafe." voice_01
asyncam move cam2 linear 1.0
achievement unlock "first_blood"
achievement increment "explorer" 1
achievement set_flag "secret_ending_found" true
actor move Kona 1
actor change Kona 介绍说话
Kona "Let's create a visual novel with Konado!"
asyncam move cam1 linear 1.0
actor exit Kona
asyncam reset linear 1.0
jump res://sample/demo/demo_02.ks
