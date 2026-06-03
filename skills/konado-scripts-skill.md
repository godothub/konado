---
name: "konado-script"
description: "协助处理视觉小说开发的 Konado Script (.ks)。当用户询问 Konado Script 语法、命令或需要帮助编写 .ks 脚本文件时调用。"
---

# Konado Script 助手

Konado Script 是一种用于视觉小说开发的领域特定语言（文件扩展名：`.ks`），它将故事内容与程序逻辑分离。

## 核心语法元素

### 1. 对话
```
"角色ID" "对话文本" 语音标签
```
- 旁白：`"narrator" "文本内容"`
- 角色：`"kona" "你好！" alice_intro_01`

### 2. 分支/标签
```
branch [标签ID]
    "角色" "对话内容"
```
- 创建用于跳转的命名区域
- 不能嵌套
- 与 `choice` 配合使用，处理玩家决策

### 3. 选择（玩家决策）
```
choice "选项文本" -> 分支名称
```
- 多个选项构成一个选项组
- 必须引用已有的分支名称
- 示例：
```
choice "绿茶" -> green_tea
choice "红茶" -> black_tea
```

### 4. 条件分支（If-Else）
```
if %变量 == 值:
    "角色" "条件为真时的对话"
else:
    "角色" "条件为假时的对话"
endif
```

### 5. 角色命令
| 命令 | 语法 |
|---------|--------|
| 显示角色 | `actor show [ID] [状态] at [位置]` |
| 移动角色 | `actor move [ID] [位置]` |
| 改变状态 | `actor change [名称] [新状态]` |
| 角色退场 | `actor exit [ID]` |

### 6. 背景
```
background [图片名称] [效果类型]
```
- 效果类型：`none`、`fade`、`erase`、`blinds`、`wave`、`vortex`、`windmill`、`cyberglitch`
- 默认：`none`（即时切换）

### 7. 音频
| 命令 | 语法 |
|---------|--------|
| 播放背景音乐 | `play bgm [音乐名称]` |
| 播放音效 | `play sfx [音效名称]` |
| 停止背景音乐 | `stop bgm` |

### 8. 变量系统

**变量类型：**
| 类型 | 前缀 | 持久性 |
|------|--------|-------------|
| 持久变量 | `%` | 随存档数据保存 |
| 临时变量 | `$` | 仅当前场景有效 |

**操作：**
```
set %变量 = 值
add %变量 值
sub %变量 值
mul %变量 值
div %变量 值
```

**对话中的变量插值：**
```
"角色" "你好，%玩家姓名！"
```

### 9. 信号
```
signal [自定义信号命令]
```
- 用于游戏事件的自定义信号（例如：`signal 好感度上升`）

### 10. 结束对话
```
end
```

## 常见问题与提示

1. **解析失败**：如果脚本无法解析，右键点击文件并选择“重新导入”
2. **编码**：确保 `.ks` 文件保存为 UTF-8 编码
3. **分支命名**：区分大小写，不能有空格或特殊字符
4. **引号语法**：字符串使用英文双引号

## 示例脚本
```
# 场景设置
background morning_forest fade
play bgm peaceful_morning
actor show kona normal at 2

# 对话
"Kona" "早上好！"
"narrator" "太阳从森林上方升起..."

# 玩家选择
choice "打招呼" -> greet
choice "保持沉默" -> silent

branch greet
    "Kona" "你好！很高兴认识你。"
    set %relationship = 1
branch silent
    "Kona" "哦...那好吧。"

# 条件判断
if %relationship > 0:
    "Kona" "我们做朋友吧！"
endif

end
```