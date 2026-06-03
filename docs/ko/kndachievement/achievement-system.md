---
title: 업적 시스템
order: 2
---

# 업적 시스템 KonadoAchievement

## 머리말

KonadoAchievement는 Konado를 위해 설계된 가볍고 데이터 기반의 업적 시스템 플러그인입니다. 업적 해금, 진행도 추적, 팝업 알림, 업적 패널 등 완전한 기능을 제공합니다. Konado와 연동해 사용할 수도 있고 독립적으로 실행할 수도 있습니다.

### 설정 파일

업적 시스템은 JSON 설정 파일로 업적을 정의합니다. 기본 경로는 `res://addons/konado_achievement/data/achievements.json`이며, `KND_AchievementManager`에서 다른 경로를 설정할 수 있습니다.

설정 파일 구조 예시:

```json
{
  "achievements": [
    {
      "id": "first_blood",
      "name": "첫 만남 장",
      "description": "첫 번째 메인 스토리 분기를 해금합니다.",
      "icon": "",
      "hidden": false,
      "category": "story",
      "points": 10,
      "conditions": {
        "type": "counter",
        "target_key": "story_branch_unlocked",
        "target_value": 1
      }
    }
  ]
}
```

### 설정 옵션(선택)

`KND_AchievementManager`에서 다음 속성을 설정할 수 있습니다.

- `config_path`: 업적 설정 파일 경로
- `save_path`: 업적 진행도 저장 경로
- `popup_duration`: 업적 해금 팝업 알림의 표시 시간
- `popup_position`: 팝업 알림 위치(top_left, top_right, bottom_left, bottom_right)

::tip
이 부분은 더 유연한 설정 옵션을 제공하기 위해 향후 리팩터링될 수 있습니다.
::

## 핵심 기능

### 업적 해금

업적 시스템은 두 가지 해금 방식을 지원합니다.

1. **직접 해금**: API를 통해 업적을 직접 해금합니다
2. **조건 해금**: 특정 조건을 만족하면 업적을 자동으로 해금합니다

### 진행도 추적

시스템은 두 가지 유형의 진행도 추적을 지원합니다.

1. **카운터**: 누적 값이 목표 값에 도달하면 해금합니다
2. **플래그**: 플래그가 특정 값으로 설정되면 해금합니다

### 알림 시스템

업적이 해금되면 시스템은 업적 이름, 설명, 아이콘을 포함한 팝업 알림을 표시합니다.

### 업적 패널

해금된 업적과 잠긴 업적, 그리고 해금 진행도를 포함해 모든 업적을 표시할 수 있는 패널을 제공합니다.

## 업적 설정 상세

### 업적 속성

각 업적은 다음 속성을 포함할 수 있습니다.

- `id`: 업적의 고유 식별자
- `name`: 업적 이름
- `description`: 업적 설명
- `icon`: 업적 아이콘 경로(선택)
- `hidden`: 숨김 여부(잠겨 있을 때 이름과 설명을 표시하지 않음)
- `category`: 업적 분류(선택)
- `points`: 업적 점수(선택)
- `conditions`: 해금 조건

### 조건 유형

#### 카운터 유형

```json
{
  "type": "counter",
  "target_key": "counter_key",
  "target_value": 10
}
```

`counter_key`의 값이 `target_value`에 도달하거나 이를 초과하면 해금됩니다.

#### 플래그 유형

```json
{
  "type": "flag",
  "target_key": "flag_key",
  "target_value": true
}
```

`flag_key`의 값이 `target_value`와 같으면 해금됩니다.

## 사용 예시

### 기본 사용

```gdscript
# 카운터 값 증가
KND_AchievementManager.increment_progress("story_branch_unlocked", 1)

# 플래그 설정
KND_AchievementManager.set_flag("secret_ending_unlocked", true)

# 업적 직접 해금
KND_AchievementManager.unlock_achievement("special_achievement")

# 업적 패널 표시
KND_AchievementManager.show_panel()
```

### 시그널 감시

```gdscript
# 업적 해금 이벤트 감시
KND_AchievementManager.achievement_unlocked.connect(_on_achievement_unlocked)

func _on_achievement_unlocked(achievement_id: String, data: Dictionary) -> void:
    print("업적 해금: " + data.get("name"))
    # 여기에 추가 보상 로직을 넣을 수 있습니다
```

### 사용자 지정 저장/로드

```gdscript
# 사용자 지정 저장 처리 설정
KND_AchievementManager.custom_save_handler = Callable(self, "_custom_save")
KND_AchievementManager.custom_load_handler = Callable(self, "_custom_load")

func _custom_save(data: Dictionary) -> void:
    # 사용자 지정 저장 로직
    pass

func _custom_load() -> Dictionary:
    # 사용자 지정 로드 로직
    return {"unlocked": {}, "progress": {}}
```

### 외부 통합

```gdscript
# 외부 해금 콜백 설정
KND_AchievementManager.on_external_unlock = Callable(self, "_on_external_unlock")

func _on_external_unlock(achievement_id: String, data: Dictionary) -> void:
    # 외부 백엔드에 동기화
    pass
```
