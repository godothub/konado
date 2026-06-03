---
title: 타자기 동작 효과
order: 5
---

# 타자기 효과 (Typewriter Effect)

## 개요

Konado는 강력한 타자기 효과 컴포넌트를 제공합니다. GPU 가속 기반의 문자별 페이드 인 효과를 지원해 게임 대화를 더 생동감 있고 흥미롭게 만듭니다.

## 핵심 기능

- **GPU 가속 렌더링** - 전용 셰이더로 문자별 렌더링을 수행해 성능이 우수합니다
- **BBCode 리치 텍스트 지원** - 굵게, 기울임, 색상, 밑줄, 취소선 등을 지원합니다
- **다양한 페이드 방향** - 임의 각도의 페이드 방향을 설정할 수 있습니다
- **공간 블렌드** - 문자 순서와 공간 위치 순서를 혼합한 페이드 효과를 만들 수 있습니다
- **CJK 다국어 지원** - 중국어, 일본어, 한국어 등 멀티바이트 문자를 완전 지원합니다

## 기본 사용

### 대화 상자에서 사용

`KND_DialogueBox` 컴포넌트에서 타자기 효과를 직접 활성화할 수 있습니다.

1. 장면의 `KND_DialogueBox` 노드를 선택합니다
2. Inspector 패널에서 해당 설정 항목을 찾습니다
3. 타자기 모드를 활성화합니다

### 코드로 사용

```gdscript
var typewriter = $KND_TypewriterText
typewriter.set_bbcode("[color=yellow]안녕[/color], [b]플레이어[/b]!")
typewriter.start()
typewriter.skip()
typewriter.reset()
```

## BBCode 리치 텍스트

| 태그 | 설명 | 예시 |
|------|------|------|
| `[b]` | 굵게 | `[b]굵은 글자[/b]` |
| `[i]` | 기울임 | `[i]기울임 글자[/i]` |
| `[u]` | 밑줄 | `[u]밑줄 글자[/u]` |
| `[s]` | 취소선 | `[s]취소선 글자[/s]` |
| `[color=색상]` | 글자 색 | `[color=red]빨간색[/color]` |
| `[font=글꼴]` | 지정 글꼴 | `[font=my_font]특수 글꼴[/font]` |

## 페이드 설정

- `fade_angle`: 문자 페이드 방향 각도. `0°` 왼쪽에서 오른쪽, `90°` 위에서 아래, `-90°` 아래에서 위, `180°` 오른쪽에서 왼쪽, 임의 각도도 가능.
- `spatial_blend`: 문자 표시 순서와 공간 위치의 혼합 정도. `0.0`은 문자 순서, `0.5`는 혼합, `1.0`은 공간 위치 순서.
- `fade_width`: 페이드의 부드러움. 값이 클수록 가장자리가 부드러워집니다.

## 시그널

| 시그널 | 설명 |
|------|------|
| `typewriter_started` | 타자기 효과가 시작될 때 트리거 |
| `typewriter_finished` | 타자기 효과가 완료될 때 트리거 |
| `typewriter_skipped` | 타자 효과를 건너뛸 때 트리거 |
| `character_revealed(index)` | 각 문자가 표시될 때 트리거, index는 문자 인덱스 |

## API 참조

| 속성 | 유형 | 기본값 | 설명 |
|------|------|--------|------|
| `bbcode_text` | String | "" | 표시할 BBCode 텍스트 |
| `font` | Font | null | 사용자 지정 글꼴 |
| `font_size` | int | 20 | 글꼴 크기 |
| `font_color` | Color | WHITE | 글자 색 |
| `chars_per_second` | float | 25.0 | 초당 표시 문자 수 |
| `fade_width` | float | 3.0 | 페이드 폭 |
| `fade_angle` | float | 0.0 | 페이드 각도(도) |
| `spatial_blend` | float | 0.15 | 공간 블렌드 비율 |
| `auto_start` | bool | true | 자동 시작 여부 |

| 메서드 | 설명 |
|------|------|
| `start()` | 타자기 효과 시작 |
| `skip()` | 건너뛰고 즉시 전체 표시 |
| `reset()` | 리셋하고 모든 텍스트 숨김 |
| `set_bbcode(text, autoplay)` | BBCode 텍스트 설정 |
| `is_playing()` | 재생 중인지 여부 |
| `is_finished()` | 완료되었는지 여부 |
| `get_progress()` | 현재 진행도 가져오기 |

## 고급 사용법

```gdscript
typewriter.chars_per_second = 100.0
typewriter.chars_per_second = 5.0
typewriter.fade_angle = 45.0
typewriter.fade_width = 5.0
typewriter.spatial_blend = 0.5
```

```gdscript
func _ready():
    var typewriter = $KND_TypewriterText
    typewriter.typewriter_finished.connect(_on_finished)

func _on_finished():
    # 타자 완료 후 작업 실행
    show_continue_button()
```

## 성능 최적화

- GPU 셰이더 렌더링을 사용해 성능이 우수합니다
- 많은 텍스트도 끊김 없이 지원합니다
- 모바일 플랫폼에서는 `chars_per_second` 값을 적절히 낮추는 것을 권장합니다

## 주의 사항

1. **BBCode 태그는 반드시 쌍으로 작성해야 합니다**
2. **색상 값은 사용자 지정 가능** - `#FF5733` 같은 16진수 색상 코드를 지원합니다
3. **에디터 미리보기** - 에디터에서 실행할 때는 미리보기 편의를 위해 텍스트가 전체 표시됩니다
4. **줄바꿈** - `\n`을 사용합니다
