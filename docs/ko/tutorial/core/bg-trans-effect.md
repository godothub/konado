---
title: 배경 전환 특수 효과
order: 3
---

# 배경 트랜지션 특수 효과

## 머리말

배경 트랜지션 특수 효과란 장면을 전환할 때 현재 장면의 배경 이미지가 나가고 새 장면의 배경 이미지가 들어오는 효과를 말합니다. 이러한 효과는 시각적 충격을 높이고 사용자 경험을 개선할 수 있습니다. 이 장은 사용자 지정 배경 트랜지션 효과를 구현하는 데 도움이 됩니다.

## 배경 전환 Shader 규격

배경 트랜지션 효과를 통일해서 관리하고 재생하기 위해 다음 Shader 규격을 정합니다.

shader 유형은 반드시 `canvas_item`이어야 합니다.

```glsl
shader_type canvas_item;
```

다음 세 매개변수를 반드시 구현해야 합니다.

```glsl
uniform float progress : hint_range(0, 1) = 0.0; // 트랜지션 진행도 0=현재만 1=대상만
uniform sampler2D current_texture : hint_default_black; // 현재 텍스처
uniform sampler2D target_texture : hint_default_black; // 대상 텍스처
```

- progress: 트랜지션 진행도. 값 범위는 0~1이며, 0은 현재 텍스처만 표시하고 1은 대상 텍스처만 표시합니다.
- current_texture: 현재 텍스처. 장면 전환 전 표시되는 텍스처입니다.
- target_texture: 대상 텍스처. 장면 전환 후 표시되는 텍스처입니다.

## 배경 전환 효과 설정

배경 전환은 동적인 과정이므로 다음 내용도 추가해야 합니다.

BackgroundTransitionEffectsType 열거형을 정의해 배경 전환 효과 유형을 식별합니다.
```
YOUR_EFFECT_SHADER
```

shader 변수를 정의합니다. `preload` 함수로 Shader 파일을 로드하는 것을 권장합니다.
```
var your_effect_shader: Shader = preload("res://path/to/your_effect_shader.shader")
```

다음으로 YOUR_EFFECT_SHADER 유형의 배경 전환 효과 설정을 구현해야 합니다.

```gdscript
BackgroundTransitionEffectsType.YOUR_EFFECT_SHADER: {
	"shader": your_effect_shader,  // 배경 전환 Shader, 위 변수와 일치해야 합니다
	"duration": 1.0,  // 트랜지션 시간, 기본값 1.0s
	"progress_target": 1.0,  // 목표 진행도, 기본값 1.0
	"tween_trans": Tween.TRANS_LINEAR  // 전환 시 이징 유형
}
```

이제 배경 전환 효과를 테스트합니다. 장면을 전환할 때 다음 테스트 코드를 추가하고, 배경 전환 효과가 예상과 맞는지 확인합니다.

```gdscript
bg.material.set("shader", your_effect_shader)

bg.material.set_shader_parameter("progress", 0.0)
bg.material.set_shader_parameter("current_texture", current_texture)
bg.material.set_shader_parameter("target_texture", tex)

# 전환 애니메이션 생성 및 설정
effect_tween = get_tree().create_tween()
effect_tween.tween_property(
	bg.material, 
	"shader_parameter/progress", 
	1.0, 
	1.0
)

effect_tween.play()
```
