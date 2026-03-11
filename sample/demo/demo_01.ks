play bgm echo

background bg1 none

actor show 可娜 正常 at 2 5 scale 0.3

"Kona" "你好！欢迎来到我们的咖啡馆。" 01

#jump res://sample/demo/demo_02.ks

actor move 可娜 4 5

actor change 可娜 害羞

"Kona" "今天想喝点什么？" 02

actor change 可娜 正常

# 111
#background bg2 cyberglitch

#global num_value += 1
# 逻辑判断 %是获取变量
if %love == 0:
    "Kona" "今天想喝点什么？"
#else:
    "Kona" "又见面了朋友！"
    "Kona" "又见面了！今天想喝点什么？"
endif


background bg1 windmill

#background bg2 wave

#background bg1 erase

choice "Coffee" coffee_choice "Tea" tea_choice

branch coffee_choice
    "Kona" "很棒的选择！我们的咖啡都是现煮的。"
    "Kona" "你想要热的还是冰的？"
    choice "Hot" coffee_hot "Iced" coffee_iced

branch coffee_hot
    "Kona" "一杯热咖啡马上就来！"
    "Kona" "一共4.5美元。请找位置坐，我很快给您送过去。"
    end
    
branch coffee_iced
    "Kona" "很适合暖和的天气！一杯冰咖啡马上准备。"
    "Kona" "一共5美元。我这就为您制作。"
    end

branch tea_choice
    "Kona" "非常好！我们有多种茶叶。"
    "Kona" "你想要绿茶还是红茶？"
    choice "Green tea" green_tea "Black tea" black_tea

branch green_tea
    "Kona" "绝佳的选择！我们的绿茶是从中国进口的。"
    "Kona" "一共3.75美元。我会为您泡到最佳口感。"
    end
    
branch black_tea
    "Kona" "经典之选！我们的红茶味道浓郁醇厚。"
    "Kona" "一共3.5美元。需要加牛奶还是柠檬？"
    choice "Milk" with_milk "Lemon" with_lemon "Nothing, thanks" plain_tea
    
branch with_milk
    "Kona" "红茶加牛奶——完美的搭配！"
    "Kona" "我马上给您送过来。"
    end
        
branch with_lemon
    "Kona" "红茶加一片柠檬——很清爽！"
    "Kona" "马上就来！"
    end
        
branch plain_tea
    "Kona" "简单又优雅。我这就为您准备红茶。"
    "Kona" "请享用您的茶！"
    end