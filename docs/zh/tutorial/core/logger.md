---
title: Logger
order: 4
---

# 日志器 KND_Logger

## 前言

KND_Logger 是基于Godot Logger实现的日志模块，支持日志级别、日志格式、日志输出、日志文件等功能，用于记录Konado运行时的日志信息。

## 日志路径

日志文件默认路径为`C:\Users\{用户名}\AppData\Roaming\Godot\app_userdata\Konado Project\konado_log.log`，可以通过修改`KND_Logger`的`LOG_FILE_PATH`属性来更改日志文件路径。

## 屏幕覆盖日志

在报错时，对话场景会在屏幕上覆盖一个日志窗口，用于显示错误信息并中断游戏运行，如果您希望关闭该功能，可以将`KND_DialogueManager`的`enable_overlay_log`属性中设置为`false`。

## 日志回调

KND_Logger 提供了日志回调功能，您可以通过以下方式连接日志回调：

```gdscript
logger.error_caught.connect(_show_error, ConnectFlags.CONNECT_DEFERRED)

func _show_error(msg: String) -> void:
	print(msg)
```
