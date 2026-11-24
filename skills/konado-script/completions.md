# 代码补全

## 主关键字（顶层命令）

| 触发词 | 说明 |
|--------|------|
| `background` | 切换背景图片，可选过渡效果 |
| `actor show` | 创建演员并显示立绘 |
| `actor exit` | 移除演员 |
| `actor change` | 切换演员状态/表情 |
| `actor move` | 移动演员到指定位置 |
| `actor motion` | 播放演员动作 |
| `play bgm` | 播放背景音乐 |
| `play sfx` | 播放音效 |
| `stop bgm` | 停止背景音乐 |
| `screentext` | 显示全屏文本块 |
| `showtextbox` | 显示对话框 |
| `hidetextbox` | 隐藏对话框 |
| `waitsignal` | 等待外部信号 |
| `choice` | 创建选项（需配合 `branch`，可选 `if` 条件与 `once`） |
| `branch` | 定义分支/标签块 |
| `if` | 条件判断开始 |
| `else` | 条件分支的否则块 |
| `endif` | 条件判断结束 |
| `end` | 终止对话流程 |
| `signal` | 发送自定义信号 |
| `achievement` | 成就系统操作 |
| `jump_branch` | 跳转到指定分支 |
| `call` | 调用当前剧本内的分支，遇到 `return` 时回到下一行 |
| `return` | 从被调用的分支返回；调用栈为空时结束当前镜头 |
| `jump` | 跳转到另一个脚本文件 |
| `cam` | 执行并等待镜头移动、复位或晃动 |
| `asyncam` | 启动、停止非阻塞镜头操作 |

## 变量操作关键字

| 触发词 | 说明 |
|--------|------|
| `set` | 设置变量值（`set %var = value`） |
| `add` | 变量加法（`add %var value`） |
| `sub` | 变量减法 |
| `mul` | 变量乘法 |
| `div` | 变量除法 |

## 子关键字

| 触发词 | 说明 |
|--------|------|
| `show` | `actor show` 的子命令 |
| `exit` | `actor exit` 的子命令 |
| `change` | `actor change` 的子命令 |
| `move` | `actor move` 的子命令 |
| `at` | 演员位置修饰符 |
| `bgm` | `play bgm` / `stop bgm` |
| `sfx` | `play sfx` 的子修饰符 |
| `unlock` | `achievement unlock` |
| `increment` | `achievement increment` |
| `set_flag` | `achievement set_flag` |
| `motion` | `actor motion` 的子命令 |
| `reset` | `cam reset` / `asyncam reset` |
| `shake` | `cam shake` / `asyncam shake` |

## 内置效果值（background 效果）

| 触发词 | 说明 |
|--------|------|
| `none` | 立即切换（默认） |
| `fade` | 淡入淡出 |
| `erase` | 擦除 |
| `blinds` | 百叶窗 |
| `wave` | 波浪 |
| `vortex` | 旋涡 |
| `windmill` | 风车 |
| `cyberglitch` | 赛博故障 |
| `blink` | 闪烁 |

## 镜头过渡值

| 触发词 | 说明 |
|--------|------|
| `none` | 立即完成 |
| `linear` | 线性过渡 |
| `ease_in_out` | 缓入缓出 |

## 行级命名参数

命名参数统一写在指令末尾的方括号内。所有可执行指令均可使用
`[id=step_id]` 声明稳定指令 ID；支持动画的指令可使用
`[duration=0.3]`。对话还支持 `[speed=1.5]` 或 `[interval=0.03]`，二者不能同时设置。

## 比较运算符（if 条件中）

| 触发词 | 说明 |
|--------|------|
| `==` | 等于 |
| `!=` | 不等于 |
| `>` | 大于 |
| `<` | 小于 |
| `>=` | 大于等于 |
| `<=` | 小于等于 |

## 布尔字面量

| 触发词 | 说明 |
|--------|------|
| `true` | 布尔真 |
| `false` | 布尔假 |

---

## 代码片段

### 1. 普通对话（`conv`）
**触发词**：`conv`
```
${1:角色ID} "${2:对话文本}"
```

### 2. 带配音对话（`convv`）
**触发词**：`convv`
```
${1:角色ID} "${2:对话文本}" ${3:voice_tag}
```

### 3. 旁白（`narr`）
**触发词**：`narr`
```
"narrator" "${1:旁白文本}"
```

### 4. 选项组（`choices`）
**触发词**：`choices`
```
choice "${1:选项一}" -> ${2:branch_name_1}
choice "${3:选项二}" -> ${4:branch_name_2}
```

### 5. 分支块（`branch-block`）
**触发词**：`br`
```
branch ${1:label_id}
	${2}
```

### 6. 条件分支（`ifblock`）
**触发词**：`ifblock`
```
if %${1:变量名} == ${2:值}:
	${3}
else:
	${4}
endif
```

### 7. 创建演员（`ashow`）
**触发词**：`ashow`
```
actor show ${1:角色ID} ${2:状态} at ${3:位置}
```

### 8. 背景切换（`bg`）
**触发词**：`bg`
```
background ${1:图片资源名} ${2:fade}
```

### 9. BGM 播放（`bgm`）
**触发词**：`bgm`
```
play bgm ${1:音乐名称}
```

### 10. 变量设置（`vset`）
**触发词**：`vset`
```
set ${1:%变量名} = ${2:值}
```

### 11. 完整选项跳转结构（`choice-flow`）
**触发词**：`choice-flow`
```
choice "${1:选项文本}" -> ${2:branch_id}

branch ${2:branch_id}
    ${3}
```

### 12. 结束对话收尾（`finish`）
**触发词**：`finish`
```
actor exit ${1:角色ID}
background ${2:bg_end} fade
end
```

### 13. 带行级参数的对话（`conv-speed`）
**触发词**：`conv-speed`
```
${1:角色ID} "${2:对话文本}" [speed=${3:1.5}]
```

### 14. 调用子程序（`calls`）
**触发词**：`calls`
```
call ${1:branch_name}
```

### 15. 子程序返回（`ret`）
**触发词**：`ret`
```
return
```

### 16. 条件选项（`choice-if`）
**触发词**：`choice-if`
```
choice "${1:选项文本}" -> ${2:branch_id} if %${3:变量名} == ${4:值}
```

### 17. 一次性选项（`choice-once`）
**触发词**：`choice-once`
```
choice "${1:选项文本}" -> ${2:branch_id} once
```

演员 ID 使用裸标识符；`$speaker` 和 `%speaker` 表示从变量读取演员 ID；只有纯文本署名才使用双引号，例如 `"旁白" "..."`。
