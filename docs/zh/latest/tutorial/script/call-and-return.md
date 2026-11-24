---
title: 子程序调用（call / return）
order: 9
---

# 子程序调用（call / return）

## 功能描述

`call` 把当前剧本里的一个 `branch` 当作子程序调用：进入分支执行，遇到 `return` 时回到 `call` 的下一行继续。

- 与 `jump_branch` 的区别：`jump_branch` 是尾跳转，不会回来；`call` 会把返回点压入调用栈。
- 与 `jump` 的区别：`jump` 切换剧本（镜头），并清空尚未 `return` 的调用栈；跨剧本调用暂不支持。
- 调用栈属于运行期状态，会随“上一句”回退、检查点与存档一起保存和恢复。
- 编译期会拒绝递归调用（直接或间接），并限制最大调用链长度（256 层）。
- 调用栈为空时执行 `return` 等价于 `end`（结束当前镜头）。

## 语法结构

```text
call <branch_name>
return
```

## 参数说明

| 参数 | 必需 | 示例 | 说明 |
|------|------|------|------|
| branch_name | 是 | `gift_scene` | 当前剧本内已声明的分支标识符 |

## 示例

```text
call gift_scene
Kona "回到调用点之后。"

branch gift_scene
	Kona "这里是公用桥段。"
	return
```

嵌套调用：

```text
call chapter_intro

branch chapter_intro
	Kona "第一章开始。"
	call phone_ring
	Kona "第一章结束。"
	return

branch phone_ring
	Kona "电话响了。"
	return
```

## 被调分支的结束方式

- 显式 `return`：最清晰，回到调用点。
- 分支自然结束：会接到编译器生成的 `halt`，等同于结束整个镜头。因此**被调用的分支建议显式写 `return`**。

## 注意事项

1. `call` 的目标必须是当前剧本内的分支；跨剧本请使用 `jump`。
2. `call` 不能形成递归（包括间接递归），否则编译失败。
3. `jump` 会丢弃当前镜头未返回的调用帧；不要依赖跨镜头的 `return`。
4. 选项、分支与条件块中都可以使用 `call` 与 `return`。
5. 运行时错误恢复面板对 `call` 只提供“重试/停止”，不提供“跳过”：跳过会进入没有返回帧的分支。
