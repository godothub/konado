---
name: konado-script
description: 视觉小说引擎 Konado DSL (.ks) 的编辑器增强技能包，提供语法高亮、代码补全、静态诊断和代码格式化参考配置。
version: 1.0.0
author: DSOE1024
tags: [visual-novel, dsl, konado]
license: MIT
---

# Konado Script Skill

Konado Script Skill是Konado项目的一部分。

用于视觉小说引擎框架 **Konado** 的 DSL（`.ks` 文件）编辑器增强技能包，为支持 Konado Script 语法高亮、代码补全、静态诊断和代码格式化的工具提供配置参考。

## 适用 DSL

- **语言名称**：Konado Script
- **文件扩展名**：`.ks`
- **编码**：UTF-8
- **设计理念**：将故事内容与程序逻辑分离，编剧无需编程知识即可创作

## 配置到工具中

1. 将本目录下各 `.md` 文件中的正则、补全项、诊断规则按目标工具的配置格式转换。
2. 将 `examples/` 下的 `.ks` 示例脚本放入项目模板目录。
3. 补全项与代码片段定义见 [completions.md](./completions.md)。
4. 静态检查规则见 [diagnostics.md](./diagnostics.md)。

## 文件清单

| 文件 | 作用 |
|------|------|
| `SKILL.md` | 本文件，技能说明与文件索引 |
| `completions.md` | 命令/关键字补全项与代码片段 |
| `diagnostics.md` | 静态检查规则（错误/警告） |
| `formatting.md` | 缩进、换行、命名约定等风格建议 |
| `examples/basic_dialogue.ks` | 示例：基础对话、场景切换、BGM |
| `examples/branch_story.ks` | 示例：选择分支、变量操作、跳转 |

## License

这个技能包的许可证是 [MIT License](./LICENSE)