---
title: 타자기 효과음
order: 6
---

# 타자기 효과음 (Typing Sound Effect)

## 개요

Konado 대화 상자 컴포넌트는 타자기 효과음 기능을 지원합니다. 타이핑 중 짧은 "딸깍" 소리를 재생해 게임의 몰입감과 피드백 경험을 높입니다.

## 효과음 디렉터리

타자기 효과음 파일은 다음 디렉터리에 저장합니다.

```
res://addons/konado/audioeffect/typewriter/
```

## 지원 오디오 형식

| 형식 | 설명 |
|------|------|
| `.wav` | 비압축 오디오, 권장 |
| `.ogg` | Ogg Vorbis 압축 형식 |
| `.mp3` | MP3 압축 형식 |

## 기본 설정

`KND_DialogueBox` 컴포넌트의 Inspector 패널에서 타자기 효과음 관련 설정을 찾을 수 있습니다.

```gdscript
@export var enable_typing_effect_audio: bool = true
@export var typing_effect_audio: AudioStream
```

`enable_typing_effect_audio`를 `true`로 설정하면 효과음이 활성화되고, `false`로 설정하면 비활성화됩니다. 에디터 드롭다운 메뉴에서 효과음 파일을 선택하거나 코드로 로드할 수 있습니다.

```gdscript
dialogue_box.typing_effect_audio = load("res://addons/konado/audioeffect/typewriter/click.wav")
```

## 효과음 트리거 설정

```gdscript
@export var audio_trigger_chance: float = 0.8
@export var min_audio_interval: float = 0.02
@export var max_audio_interval: float = 0.08
@export var audio_volumn: float = 0.6
```

- `audio_trigger_chance`: 효과음 트리거 확률, 범위 0.0-1.0. `1.0`은 항상 재생, `0.8`은 80% 확률, `0.0`은 재생하지 않음.
- `min_audio_interval` / `max_audio_interval`: 효과음 재생의 랜덤 간격 범위로, 다양한 타이핑 리듬에 맞춥니다.
- `audio_volumn`: 효과음 음량, 범위 0.0-1.0.

## 사용 예시

```gdscript
var dialogue_box = $KND_DialogueBox
dialogue_box.enable_typing_effect_audio = true
dialogue_box.typing_effect_audio = load("res://addons/konado/audioeffect/typewriter/my_click.wav")
dialogue_box.audio_trigger_chance = 1.0
dialogue_box.audio_volumn = 0.8
dialogue_box.min_audio_interval = 0.02
dialogue_box.max_audio_interval = 0.06
```

## 추천 효과음

- **타자기 딸깍 소리**: 빠르고 밀도 높은 타이핑 효과에 적합하며 `0.02 - 0.05`, `audio_trigger_chance: 0.8` 권장
- **기계식 키보드 소리**: 타건감이 강한 게임에 적합하며 `0.03 - 0.08`, `audio_trigger_chance: 0.9` 권장
- **부드러운 클릭 소리**: 캐주얼하고 편안한 분위기에 적합하며 `0.05 - 0.12`, `audio_trigger_chance: 0.7`, `audio_volumn: 0.5` 권장

## 효과음 트리거 시점

타자기 효과음은 타이핑 애니메이션 재생 중이고, 마지막 재생 이후 랜덤 간격을 넘었으며, 확률 검사에 통과하고, 텍스트 표시가 아직 끝나지 않았을 때 트리거됩니다.

## 주의 사항과 최적화

1. 효과음 파일 이름은 영어를 권장하며 특수 문자를 피하세요.
2. 효과음 길이는 0.1초 이내가 가장 좋습니다.
3. 타자 효과음이 배경 음악을 덮지 않도록 음량 균형을 맞추세요.
4. 모바일 플랫폼에서는 공간 절약을 위해 ogg/mp3 같은 압축 형식을 권장합니다.
5. 짧은 효과음 파일(100 KB 미만 권장)을 사용하고, 필요 없을 때는 `enable_typing_effect_audio = false`로 비활성화하세요.

## 문제 해결

- 효과음이 재생되지 않으면 `enable_typing_effect_audio`, `typing_effect_audio`, 파일 경로, 음량을 확인하세요.
- 효과음이 너무 촘촘하면 간격 값을 늘리거나 `audio_trigger_chance`를 낮추세요.
- 효과음이 너무 드물면 간격 값을 줄이거나 `audio_trigger_chance`를 높이세요.
