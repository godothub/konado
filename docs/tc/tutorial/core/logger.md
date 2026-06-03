---
title: Logger
order: 4
---

# 日誌器 KND_Logger

## 前言

KND_Logger 是基於 Godot Logger 實作的日誌模組，支援日誌級別、日誌格式、日誌輸出、日誌檔案等功能，用於記錄 Konado 執行時的日誌資訊。

## 日誌路徑

日誌檔案預設路徑為 `C:\Users\{使用者名稱}\AppData\Roaming\Godot\app_userdata\Konado Project\konado_log.log`，可以透過修改 `KND_Logger` 的 `LOG_FILE_PATH` 屬性來更改日誌檔案路徑。

## 螢幕覆蓋日誌

發生錯誤時，對話場景會在螢幕上覆蓋一個日誌視窗，用於顯示錯誤資訊並中斷遊戲執行。如果您希望關閉此功能，可以將 `KND_DialogueManager` 的 `enable_overlay_log` 屬性設定為 `false`。

## 日誌回呼

KND_Logger 提供日誌回呼功能，您可以透過以下方式連接日誌回呼：

```gdscript
logger.error_caught.connect(_show_error, ConnectFlags.CONNECT_DEFERRED)

func _show_error(msg: String) -> void:
	print(msg)
```
