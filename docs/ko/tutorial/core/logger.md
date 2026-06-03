---
title: Logger
order: 4
---

# 로거 KND_Logger

## 머리말

KND_Logger는 Godot Logger 구현을 기반으로 한 로그 모듈입니다. 로그 레벨, 로그 형식, 로그 출력, 로그 파일 등의 기능을 지원하며 Konado 실행 중의 로그 정보를 기록하는 데 사용됩니다.

## 로그 경로

로그 파일 기본 경로는 `C:\Users\{사용자 이름}\AppData\Roaming\Godot\app_userdata\Konado Project\konado_log.log`입니다. `KND_Logger`의 `LOG_FILE_PATH` 속성을 수정해 로그 파일 경로를 변경할 수 있습니다.

## 화면 오버레이 로그

오류가 발생하면 대화 장면은 화면 위에 로그 창을 덮어 표시하여 오류 정보를 보여 주고 게임 실행을 중단합니다. 이 기능을 끄고 싶다면 `KND_DialogueManager`의 `enable_overlay_log` 속성을 `false`로 설정하세요.

## 로그 콜백

KND_Logger는 로그 콜백 기능을 제공합니다. 다음 방식으로 로그 콜백을 연결할 수 있습니다.

```gdscript
logger.error_caught.connect(_show_error, ConnectFlags.CONNECT_DEFERRED)

func _show_error(msg: String) -> void:
	print(msg)
```
