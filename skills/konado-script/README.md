# Konado Script Skill Plugin

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](./LICENSE)

视觉小说引擎 **Konado** DSL（`.ks` 文件）的编辑器增强技能包。提供 Konado Script 的语法高亮、代码补全、静态诊断和代码格式化配置参考。

## AtomCode Plugin 安装

```bash
# 本地安装
atomcode /plugin install ./skills/konado-script
```

或手动将此目录复制到 `.atomcode/plugins/konado-script/`。

## 功能

| 功能 | 说明 |
|------|------|
| **语法高亮** | 13 种 Token 类型的正则与 TextMate 作用域定义 |
| **代码补全** | 50+ 关键字补全项 + 12 个代码片段 |
| **静态诊断** | 10 条检查规则（未定义标签、重复演员、分支嵌套等） |
| **代码格式化** | 缩进、换行、命名约定建议 |
| **示例脚本** | 2 个可直接运行的 `.ks` 示例 |



## 许可

[MIT License](./LICENSE)