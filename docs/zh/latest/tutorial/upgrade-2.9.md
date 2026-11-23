---
title: 升级到 2.9
order: 4
---

# 升级到 2.9

2.9 新增 `call` / `return` 子程序与条件/一次性选项（`choice ... if` / `once`），并**不再兼容 2.8 的存档与已导出的剧本数据**。

## 不兼容项

| 项 | 2.8 | 2.9 |
| --- | --- | --- |
| 编译器 ABI | `konado-2.8` | `konado-2.9` |
| 命令 Schema | 3 | 4 |
| 运行期状态 Schema | 2 | 3 |

- 2.8 的 `.kns` 存档会被明确拒绝（提示“存档格式与 Konado 2.9 不匹配”），不会以空状态继续运行。
- 2.8 导出的剧本数据（加密 `.res` 或 PCK 内的编译产物）与新 ABI 不一致，需要重新导出。
- 2.9 不提供存档转换工具；如需保留玩家进度，请在 2.8 版本内自行结算或转档。

## 升级步骤

1. 用 2.9 的完整插件目录替换旧版本，并重新打开 Godot（`.ks` 会重新导入编译）。
2. 重新导出游戏；只替换已发布包里的插件不能完成升级。
3. 确认所有使用到 `choice` / `call` 的剧本已重新编译通过。

## 2.9 新语法速览

```text
call common_scene
return

choice "Option" -> branch_name if %love >= 5
choice "Ask once" -> branch_name once
```

详见“子程序调用（call / return）”与“选项”页面。
