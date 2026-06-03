---
title: Introduction
order: 1
---

# Konado WebTool

## Preface

Konado WebTool is a plugin that provides Web platform development tool support for Konado projects. Because Godot 4.x captures and disables all keyboard shortcuts by default on the Web platform, browser developer tool shortcuts such as F12 and F5 cannot be used normally. This plugin solves that problem by allowing common browser developer tool shortcuts on the Web platform, making it easier for developers to debug and develop in Web environments.

## How It Works

Konado WebTool works by injecting JavaScript code on the Web platform to let shortcuts pass through. It will:

1. Detect whether the current platform is Web
2. If it is Web and developer tool support is enabled, inject shortcut handling code
3. Dynamically build the allowed shortcut list based on configuration
4. Listen for keyboard events and prevent default behavior for allowed shortcuts, allowing them to pass through to the browser

### Comparison with Other Solutions

| Solution | Advantages | Disadvantages |
|----------|------|------|
| Konado WebTool | Easy to use, highly configurable, easy to maintain | No obvious disadvantages |
| Manually modify export template | Full control | High technical requirements, frequent updates needed |
| Switch development environment | Can debug on desktop platform | Cannot catch Web-platform-specific issues |

## Supported Browser Shortcuts

These shortcut specifications are based on standard developer tool shortcuts in mainstream browsers such as Chrome, Firefox, and Edge, and refer to official browser documentation:

- [Firefox DevTools](https://developer.mozilla.org/en-US/docs/Tools/Keyboard_shortcuts)
- [Edge DevTools](https://learn.microsoft.com/en-us/microsoft-edge/devtools-guide-chromium/shortcuts/)
- [Chrome DevTools](https://developer.chrome.com/docs/devtools/shortcuts/)
- [Safari DevTools (WebKit)](https://webkit.org/web-inspector/keyboard-shortcuts/)

| Shortcut | Function | Enable option |
|--------|------|----------|
| F12 | Open developer tools | `enable_f12` |
| F5 | Refresh page | `enable_f5` |
| F11 | Toggle full screen | `enable_f11` |
| Ctrl+Shift+I (Win/Linux) / Cmd+Opt+I (Mac) | Open Elements panel | `enable_ctrl_shift_i` |
| Ctrl+Shift+J (Win/Linux) / Cmd+Opt+J (Mac) | Open Console | `enable_ctrl_shift_j` |
| Ctrl+Shift+C (Win/Linux) / Cmd+Shift+C (Mac) | Inspect element mode | `enable_ctrl_shift_c` |
| Ctrl+U (Win/Linux) / Cmd+U (Mac) | View page source | `enable_ctrl_u` |
| Ctrl+R (Win/Linux) / Cmd+R (Mac) | Refresh page | `enable_ctrl_r` |

## Configuration Options

In the autoloaded `KND_WebTool` node, you can configure the following properties:

| Property | Type | Default | Description |
|------|------|--------|------|
| `enable_web_devtool` | bool | true | Whether to allow Web developer tool shortcuts |
| `enable_f12` | bool | true | Whether to enable F12 |
| `enable_f5` | bool | true | Whether to enable F5 |
| `enable_f11` | bool | true | Whether to enable F11 |
| `enable_ctrl_shift_i` | bool | true | Whether to enable Ctrl+Shift+I |
| `enable_ctrl_shift_j` | bool | true | Whether to enable Ctrl+Shift+J |
| `enable_ctrl_shift_c` | bool | true | Whether to enable Ctrl+Shift+C |
| `enable_ctrl_u` | bool | true | Whether to enable Ctrl+U |
| `enable_ctrl_r` | bool | true | Whether to enable Ctrl+R |
