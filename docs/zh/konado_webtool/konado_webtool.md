---
title: 介绍
order: 1
---

# Konado WebTool

## 前言

Konado WebTool 是一个为 Konado 项目提供 Web 平台开发工具支持的插件。由于 Godot4.x 在 Web 平台上默认会捕获并禁用所有键盘快捷键，导致浏览器的开发者工具快捷键（如 F12、F5 等）无法正常使用，这个插件专门解决了这个问题，允许在 Web 平台上使用常见的浏览器开发者工具快捷键，方便开发者在 Web 环境中进行调试和开发。


## 工作原理

Konado WebTool 通过在 Web 平台上注入 JavaScript 代码来实现快捷键的放行。它会：

1. 检测当前平台是否为 Web 平台
2. 如果是 Web 平台且启用了开发者工具支持，则注入快捷键处理代码
3. 根据配置动态构建允许的快捷键列表
4. 监听键盘事件，对允许的快捷键阻止默认行为，从而放行到浏览器

### 与其他解决方案比较

| 解决方案 | 优势 | 劣势 |
|----------|------|------|
| Konado WebTool | 简单易用、可配置性强、维护性好 | 无明显劣势 |
| 手动修改导出模板 | 完全控制 | 技术要求高，需频繁更新 |
| 开发环境切换 | 可在桌面平台调试 | 无法捕获 Web 平台特有问题 |


## 支持的浏览器快捷键

这些快捷键规范基于主流浏览器（如 Chrome、Firefox、Edge 等）的开发者工具标准快捷键，参考了各浏览器的官方文档：

- [Firefox DevTools](https://developer.mozilla.org/en-US/docs/Tools/Keyboard_shortcuts)
- [Edge DevTools](https://learn.microsoft.com/en-us/microsoft-edge/devtools-guide-chromium/shortcuts/)
- [Chrome DevTools](https://developer.chrome.com/docs/devtools/shortcuts/)
- [Safari DevTools（WebKit）](https://webkit.org/web-inspector/keyboard-shortcuts/)

| 快捷键 | 功能 | 启用选项 |
|--------|------|----------|
| F12 | 打开开发者工具 | `enable_f12` |
| F5 | 刷新页面 | `enable_f5` |
| F11 | 全屏切换 | `enable_f11` |
| Ctrl+Shift+I (Win/Linux) / Cmd+Opt+I (Mac) | 打开元素面板 | `enable_ctrl_shift_i` |
| Ctrl+Shift+J (Win/Linux) / Cmd+Opt+J (Mac) | 打开控制台 | `enable_ctrl_shift_j` |
| Ctrl+Shift+C (Win/Linux) / Cmd+Shift+C (Mac) | 检查元素模式 | `enable_ctrl_shift_c` |
| Ctrl+U (Win/Linux) / Cmd+U (Mac) | 查看页面源码 | `enable_ctrl_u` |
| Ctrl+R (Win/Linux) / Cmd+R (Mac) | 刷新页面 | `enable_ctrl_r` |

## 配置选项

在自动加载的 `KND_WebTool` 节点中，您可以通过以下属性进行配置：

| 属性 | 类型 | 默认值 | 描述 |
|------|------|--------|------|
| `enable_web_devtool` | bool | true | 是否启用 Web 开发者工具快捷键放行 |
| `enable_f12` | bool | true | 是否启用 F12 快捷键 |
| `enable_f5` | bool | true | 是否启用 F5 快捷键 |
| `enable_f11` | bool | true | 是否启用 F11 快捷键 |
| `enable_ctrl_shift_i` | bool | true | 是否启用 Ctrl+Shift+I 快捷键 |
| `enable_ctrl_shift_j` | bool | true | 是否启用 Ctrl+Shift+J 快捷键 |
| `enable_ctrl_shift_c` | bool | true | 是否启用 Ctrl+Shift+C 快捷键 |
| `enable_ctrl_u` | bool | true | 是否启用 Ctrl+U 快捷键 |
| `enable_ctrl_r` | bool | true | 是否启用 Ctrl+R 快捷键 |



