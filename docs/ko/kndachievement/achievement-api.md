---
title: API 사용
order: 3
---

# KND_AchievementManager API 참조

## 시그널

업적 시스템은 다음 시그널을 제공하며, 업적 관련 이벤트를 감시하고 사용자 지정 로직을 실행하는 데 사용할 수 있습니다.

### achievement_unlocked

**시그널 시그니처:** `achievement_unlocked(achievement_id: String, data: Dictionary)`

**트리거 시점:** 어떤 업적이든 해금될 때 트리거됩니다

**매개변수 설명:**
- `achievement_id`: 해금된 업적 ID
- `data`: 업적의 전체 데이터 딕셔너리. 이름, 설명, 아이콘 등의 정보를 포함합니다

**사용 사례:** 업적 해금 시 보상 로직 실행, 축하 애니메이션 재생, 사용자 지정 알림 표시 등에 사용합니다

**예시 코드:**
```gdscript
# 시그널 연결
KND_AchievementManager.achievement_unlocked.connect(_on_achievement_unlocked)

# 시그널 처리 함수
func _on_achievement_unlocked(achievement_id: String, data: Dictionary) -> void:
    print("업적 해금: " + data.get("name"))
    # 업적 해금 효과음 재생
    # 사용자 지정 축하 애니메이션 표시
    # 플레이어에게 보상 지급
```

### achievement_progress_updated

**시그널 시그니처:** `achievement_progress_updated(achievement_id: String, current: float, target: float)`

**트리거 시점:** 업적의 진행도 값이 업데이트될 때 트리거됩니다

**매개변수 설명:**
- `achievement_id`: 진행도가 업데이트된 업적 ID
- `current`: 현재 진행도 값
- `target`: 목표 진행도 값

**사용 사례:** 업적 진행도 바 표시, 진행도 피드백 제공, UI 표시 업데이트 등에 사용합니다

**예시 코드:**
```gdscript
# 시그널 연결
KND_AchievementManager.achievement_progress_updated.connect(_on_progress_updated)

# 시그널 처리 함수
func _on_progress_updated(achievement_id: String, current: float, target: float) -> void:
    var progress_percentage = (current / target) * 100
    print("업적 진행도 업데이트: " + achievement_id + " - " + str(progress_percentage) + "%")
    # UI 진행도 바 업데이트
    # 진행도 안내 표시
```

### achievements_reset

**시그널 시그니처:** `achievements_reset()`

**트리거 시점:** 모든 업적이 초기화될 때 트리거됩니다

**매개변수 설명:** 매개변수 없음

**사용 사례:** 업적 초기화 후 UI 업데이트, 초기화 알림 표시, 정리 작업 실행 등에 사용합니다

**예시 코드:**
```gdscript
# 시그널 연결
KND_AchievementManager.achievements_reset.connect(_on_achievements_reset)

# 시그널 처리 함수
func _on_achievements_reset() -> void:
    print("모든 업적이 초기화되었습니다")
    # 업적 패널 업데이트
    # 초기화 알림 표시
```

### achievements_loaded

**시그널 시그니처:** `achievements_loaded()`

**트리거 시점:** 업적 시스템 로드가 완료될 때 트리거됩니다

**매개변수 설명:** 매개변수 없음

**사용 사례:** 업적 로드 완료 후 UI 초기화, 업적 데이터에 의존하는 로직 실행 등에 사용합니다

**예시 코드:**
```gdscript
# 시그널 연결
KND_AchievementManager.achievements_loaded.connect(_on_achievements_loaded)

# 시그널 처리 함수
func _on_achievements_loaded() -> void:
    print("업적 데이터 로드 완료")
    # 업적 패널 초기화
    # 업적 데이터에 의존하는 로직 실행
```

## 핵심 메서드

### 업적 해금

```gdscript
# ID로 업적을 직접 해금
KND_AchievementManager.unlock_achievement("achievement_id")
```

### 진행도 관리

```gdscript
# 카운터 값 증가
KND_AchievementManager.increment_progress("counter_key", 1.0)

# 플래그 값 설정
KND_AchievementManager.set_flag("flag_key", true)
```

### 업적 조회

```gdscript
# 업적이 해금되었는지 확인
KND_AchievementManager.is_unlocked("achievement_id")

# 단일 업적 데이터 가져오기
KND_AchievementManager.get_achievement("achievement_id")

# 모든 업적 가져오기
KND_AchievementManager.get_all_achievements()

# 해금된 업적 가져오기
KND_AchievementManager.get_unlocked_achievements()

# 잠긴 업적 가져오기
KND_AchievementManager.get_locked_achievements()

# 해금 비율 가져오기
KND_AchievementManager.get_unlock_percentage()
```

### 패널 관리

```gdscript
# 업적 패널 표시
KND_AchievementManager.show_panel()

# 업적 패널 숨김
KND_AchievementManager.hide_panel()

# 업적 패널 표시 상태 전환
KND_AchievementManager.toggle_panel()

# 패널이 보이는지 확인
KND_AchievementManager.is_panel_visible()
```

#### 초기화 기능
```gdscript
# 모든 업적 초기화
KND_AchievementManager.reset_all()

# 단일 업적 초기화
KND_AchievementManager.reset_achievement("achievement_id")
```
