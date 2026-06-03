---
title: 설정 파일
order: 1
---

# 설정 파일 가이드

## 설정 파일 구조

기본 설정 파일은 `res://addons/konado_settings/resources/default_settings.json`에 있으며, 설정 항목은 JSON 형식으로 정의합니다.

### 기본 구조

```json
{
	"categories": [
		{
			"id": "audio",
			"display_name": "오디오",
			"items": [
				{
					"key": "master_volume",
					"label": "마스터 볼륨",
					"type": 0,
					"min_value": 0.0,
					"max_value": 1.0,
					"step": 0.01,
					"default_value": 1.0,
					"platforms": ["all"]
				}
			]
		}
	]
}
```

## 설정 설명

### 최상위 구조

- **categories**: 모든 설정 카테고리를 담는 배열입니다.

### 카테고리 속성

- **id**: 카테고리의 고유 식별자이며, 코드에서 접근할 때 사용합니다.
- **display_name**: 설정 패널에 표시되는 카테고리 이름입니다.
- **items**: 해당 카테고리에 포함된 설정 항목 배열입니다.

### 설정 항목 속성

- **key**: 설정 항목의 고유 식별자입니다. 같은 카테고리 안에서 중복될 수 없습니다.
- **label**: 설정 패널에 표시되는 라벨입니다.
- **type**: 설정 타입입니다.
  - `0`: 슬라이더(SLIDER)
  - `1`: 토글(TOGGLE)
  - `2`: 옵션(OPTION)

#### 슬라이더 타입(SLIDER) 전용 속성

- **min_value**: 최솟값
- **max_value**: 최댓값
- **step**: 단계 값
- **default_value**: 기본값(float 타입)

#### 토글 타입(TOGGLE) 전용 속성

- **default_value**: 기본값(bool 타입)

#### 옵션 타입(OPTION) 전용 속성

- **options**: 옵션 목록(Array[String])
- **default_value**: 기본값(String 타입). 반드시 `options` 목록 안에 있어야 합니다.

#### 공통 속성

- **platforms**: 플랫폼 목록입니다. 빈 배열이거나 `"all"`을 포함하면 모든 플랫폼에서 표시됩니다.

## 지원되는 플랫폼 식별자

- `all` - 모든 플랫폼
- `android` - Android
- `bsd` - BSD
- `linux` - Linux
- `macos` - macOS
- `ios` - iOS
- `visionos` - visionOS
- `windows` - Windows
- `linuxbsd` - Linux 또는 BSD
- `debug` - 디버그 빌드
- `release` - 릴리스 빌드
- `editor` - 에디터 빌드

## 플랫폼 필터 규칙

1. **빈 배열**: 모든 플랫폼에서 표시됩니다.
2. **"all" 포함**: 모든 플랫폼에서 표시됩니다.
3. **특정 플랫폼**: 지정한 플랫폼에서만 표시됩니다.
4. **플랫폼 별칭**: `linuxbsd`는 Linux 또는 BSD 플랫폼과 일치합니다.
5. **빌드 타입**: `debug`와 `release`는 빌드 타입에 따라 필터링됩니다.

## 설정 예시

### 전체 설정 예시

```json
{
	"categories": [
		{
			"id": "audio",
			"display_name": "오디오",
			"items": [
				{
					"key": "master_volume",
					"label": "마스터 볼륨",
					"type": 0,
					"min_value": 0.0,
					"max_value": 1.0,
					"step": 0.01,
					"default_value": 1.0,
					"platforms": ["all"]
				},
				{
					"key": "music_volume",
					"label": "음악 볼륨",
					"type": 0,
					"min_value": 0.0,
					"max_value": 1.0,
					"step": 0.01,
					"default_value": 0.8
				}
			]
		},
		{
			"id": "display",
			"display_name": "화면",
			"items": [
				{
					"key": "fullscreen",
					"label": "전체 화면",
					"type": 1,
					"default_value": false
				},
				{
					"key": "language",
					"label": "언어",
					"type": 2,
					"options": ["zh", "tc", "en", "ja", "ko"],
					"default_value": "zh"
				},
				{
					"key": "debug_mode",
					"label": "디버그 모드",
					"type": 1,
					"default_value": false,
					"platforms": ["debug"]
				},
				{
					"key": "windows_only",
					"label": "Windows 전용",
					"type": 1,
					"default_value": false,
					"platforms": ["windows"]
				}
			]
		}
	]
}
```

### 타입별 설정 항목 예시

#### 슬라이더 타입

```json
{
	"key": "text_speed",
	"label": "텍스트 속도",
	"type": 0,
	"min_value": 0.01,
	"max_value": 0.2,
	"step": 0.005,
	"default_value": 0.05
}
```

#### 토글 타입

```json
{
	"key": "auto_mode",
	"label": "자동 모드",
	"type": 1,
	"default_value": false
}
```

#### 옵션 타입

```json
{
	"key": "quality",
	"label": "화질",
	"type": 2,
	"options": ["낮음", "중간", "높음", "매우 높음"],
	"default_value": "중간"
}
```

## 설정 모범 사례

1. **이름 규칙**
   - `id`와 `key`는 소문자와 밑줄로 작성합니다.
   - `display_name`은 사용자가 이해하기 쉬운 이름을 사용합니다.

2. **플랫폼 설정**
   - 공통 설정에는 `"platforms": ["all"]`을 사용합니다.
   - 플랫폼별 설정에는 대상 플랫폼을 명확히 지정합니다.

3. **기본값**
   - 모든 설정 항목에 합리적인 기본값을 제공합니다.
   - 기본값의 타입이 설정 타입과 일치하는지 확인합니다.

4. **구성 방식**
   - 기능별로 설정을 서로 다른 카테고리에 묶습니다.
   - 카테고리 수가 지나치게 많아지지 않도록 적절히 유지합니다.

5. **형식 검사**
   - JSON 검증 도구로 설정 파일 형식을 확인합니다.
   - 모든 필수 속성이 설정되어 있는지 확인합니다.

## 주의 사항

- 설정 항목의 `key`는 같은 카테고리 안에서 고유해야 합니다.
- 슬라이더 타입에서는 `min_value` < `max_value`가 되도록 해야 합니다.
- 옵션 타입에서는 `options` 배열이 비어 있지 않아야 합니다.
- 설정 파일을 변경한 뒤에는 게임을 다시 시작하거나 `rebuild()` 메서드를 호출해 설정 패널을 갱신해야 합니다.
