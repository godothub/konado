---
title: 介紹
order: 1
---

# Konado WebTool

## 前言

Konado WebTool 是一個為 Konado 專案提供 Web 平台開發工具支援的插件。由於 Godot 4.x 在 Web 平台上預設會捕獲並禁用所有鍵盤快捷鍵，導致瀏覽器開發者工具快捷鍵（如 F12、F5 等）無法正常使用。這個插件專門解決此問題，允許在 Web 平台上使用常見的瀏覽器開發者工具快捷鍵，方便開發者在 Web 環境中進行除錯與開發。

## 工作原理

Konado WebTool 透過在 Web 平台上注入 JavaScript 程式碼來實現快捷鍵放行。它會：

1. 檢測目前平台是否為 Web 平台
2. 如果是 Web 平台且啟用了開發者工具支援，則注入快捷鍵處理程式碼
3. 根據設定動態建構允許的快捷鍵列表
4. 監聽鍵盤事件，對允許的快捷鍵阻止預設行為，從而放行到瀏覽器

### 與其他解決方案比較

| 解決方案 | 優勢 | 劣勢 |
|----------|------|------|
| Konado WebTool | 簡單易用、可設定性強、維護性好 | 無明顯劣勢 |
| 手動修改匯出範本 | 完全控制 | 技術要求高，需頻繁更新 |
| 開發環境切換 | 可在桌面平台除錯 | 無法捕捉 Web 平台特有問題 |

## 支援的瀏覽器快捷鍵

這些快捷鍵規範基於主流瀏覽器（如 Chrome、Firefox、Edge 等）的開發者工具標準快捷鍵，並參考各瀏覽器官方文件：

- [Firefox DevTools](https://developer.mozilla.org/en-US/docs/Tools/Keyboard_shortcuts)
- [Edge DevTools](https://learn.microsoft.com/en-us/microsoft-edge/devtools-guide-chromium/shortcuts/)
- [Chrome DevTools](https://developer.chrome.com/docs/devtools/shortcuts/)
- [Safari DevTools（WebKit）](https://webkit.org/web-inspector/keyboard-shortcuts/)

| 快捷鍵 | 功能 | 啟用選項 |
|--------|------|----------|
| F12 | 開啟開發者工具 | `enable_f12` |
| F5 | 重新整理頁面 | `enable_f5` |
| F11 | 全螢幕切換 | `enable_f11` |
| Ctrl+Shift+I (Win/Linux) / Cmd+Opt+I (Mac) | 開啟元素面板 | `enable_ctrl_shift_i` |
| Ctrl+Shift+J (Win/Linux) / Cmd+Opt+J (Mac) | 開啟控制台 | `enable_ctrl_shift_j` |
| Ctrl+Shift+C (Win/Linux) / Cmd+Shift+C (Mac) | 檢查元素模式 | `enable_ctrl_shift_c` |
| Ctrl+U (Win/Linux) / Cmd+U (Mac) | 查看頁面原始碼 | `enable_ctrl_u` |
| Ctrl+R (Win/Linux) / Cmd+R (Mac) | 重新整理頁面 | `enable_ctrl_r` |

## 設定選項

在自動載入的 `KND_WebTool` 節點中，您可以透過以下屬性進行設定：

| 屬性 | 類型 | 預設值 | 描述 |
|------|------|--------|------|
| `enable_web_devtool` | bool | true | 是否啟用 Web 開發者工具快捷鍵放行 |
| `enable_f12` | bool | true | 是否啟用 F12 快捷鍵 |
| `enable_f5` | bool | true | 是否啟用 F5 快捷鍵 |
| `enable_f11` | bool | true | 是否啟用 F11 快捷鍵 |
| `enable_ctrl_shift_i` | bool | true | 是否啟用 Ctrl+Shift+I 快捷鍵 |
| `enable_ctrl_shift_j` | bool | true | 是否啟用 Ctrl+Shift+J 快捷鍵 |
| `enable_ctrl_shift_c` | bool | true | 是否啟用 Ctrl+Shift+C 快捷鍵 |
| `enable_ctrl_u` | bool | true | 是否啟用 Ctrl+U 快捷鍵 |
| `enable_ctrl_r` | bool | true | 是否啟用 Ctrl+R 快捷鍵 |
