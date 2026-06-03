---
title: Logger
order: 4
---

# ロガー KND_Logger

## はじめに

KND_Logger は Godot Logger の実装を基にしたログモジュールです。ログレベル、ログ形式、ログ出力、ログファイルなどをサポートし、Konado 実行時のログ情報を記録するために使用します。

## ログパス

ログファイルのデフォルトパスは `C:\Users\{ユーザー名}\AppData\Roaming\Godot\app_userdata\Konado Project\konado_log.log` です。`KND_Logger` の `LOG_FILE_PATH` プロパティを変更することで、ログファイルパスを変更できます。

## 画面オーバーレイログ

エラー発生時、会話シーンは画面上にログウィンドウを重ねて表示し、エラー情報を示してゲーム実行を中断します。この機能を無効にしたい場合は、`KND_DialogueManager` の `enable_overlay_log` プロパティを `false` に設定してください。

## ログコールバック

KND_Logger はログコールバック機能を提供します。以下の方法でログコールバックを接続できます。

```gdscript
logger.error_caught.connect(_show_error, ConnectFlags.CONNECT_DEFERRED)

func _show_error(msg: String) -> void:
	print(msg)
```
