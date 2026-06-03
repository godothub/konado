---
title: Logger
order: 4
---

# Logger KND_Logger

## Preface

KND_Logger is a logging module based on the Godot Logger implementation. It supports log levels, log formats, log output, log files, and other features, and is used to record Konado runtime log information.

## Log Path

The default log file path is `C:\Users\{username}\AppData\Roaming\Godot\app_userdata\Konado Project\konado_log.log`. You can change the log file path by modifying the `LOG_FILE_PATH` property of `KND_Logger`.

## On-Screen Overlay Log

When an error occurs, the dialogue scene overlays a log window on the screen to show error information and interrupt game execution. If you want to disable this feature, set the `enable_overlay_log` property of `KND_DialogueManager` to `false`.

## Log Callback

KND_Logger provides log callback support. You can connect a log callback as follows:

```gdscript
logger.error_caught.connect(_show_error, ConnectFlags.CONNECT_DEFERRED)

func _show_error(msg: String) -> void:
	print(msg)
```
