---
title: 배경 전환
order: 1
---

# 배경 전환

## 기능 설명
게임 장면의 배경 이미지를 전환하며, 전환 효과를 지원합니다.

## 문법 구조
```text
background [이미지 리소스 이름] <효과 유형>
```

## 매개변수 설명
| 매개변수 | 필수 | 예시 값 | 설명 |
|------|------|--------|------|
| 이미지 리소스 이름 | 예 | `morning_forest` | 확장자를 제외한 텍스처 파일 이름 |
| 효과 유형 | 아니요 | `fade` | 전환 효과(기본값: 즉시 전환) |

### 지원되는 효과 유형

다음 배경 전환 효과 유형을 지원합니다. 각 효과는 고유한 시각 효과를 가집니다.

| 효과 | 설명 |
|------|------|
| `none` | 즉시 전환 |
| `fade` | 페이드 인/아웃 |
| `erase` | 지우기 |
| `blinds` | 블라인드 |
| `wave` | 파동 |
| `vortex` | 소용돌이 |
| `windmill` | 풍차 |
| `cyberglitch` | 사이버 글리치 |

효과 유형을 지정하지 않으면 기본적으로 `none`(즉시 전환)을 사용합니다.

## 예시
```text
# 낮에서 밤으로 전환(페이드 효과)
background night_street fade

# 전투 장면 전환(즉시 전환)
background battle_field none

# 회상 장면(지우기 효과)
background memory_flash erase

# 몽환 장면(소용돌이 효과)
background dream vortex
```
