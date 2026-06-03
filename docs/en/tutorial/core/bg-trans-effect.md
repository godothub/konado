---
title: Background Switching Effects
order: 3
---

# Background Transition Effects

## Preface

Background transition effects refer to the effect where the current background image exits while the new scene's background image enters during a scene switch. This can increase visual impact and improve user experience. This chapter helps you implement custom background transition effects.

## Background Switching Shader Specification

To manage and play background transition effects consistently, we define a Shader specification as follows:

The shader type must be `canvas_item`:

```glsl
shader_type canvas_item;
```

The following three parameters must be implemented:

```glsl
uniform float progress : hint_range(0, 1) = 0.0; // Transition progress: 0=current only, 1=target only
uniform sampler2D current_texture : hint_default_black; // Current texture
uniform sampler2D target_texture : hint_default_black; // Target texture
```

- progress: Transition progress, range 0 to 1. 0 means only the current texture is shown, 1 means only the target texture is shown.
- current_texture: Current texture, displayed before the scene switches.
- target_texture: Target texture, displayed after the scene switches.

## Background Switching Effect Configuration

Because background switching is a dynamic process, the following also needs to be added:

Define the BackgroundTransitionEffectsType enum to identify the background switching effect type.
```
YOUR_EFFECT_SHADER
```

Define a shader variable. Using `preload` to load the Shader file is recommended.
```
var your_effect_shader: Shader = preload("res://path/to/your_effect_shader.shader")
```

Next, implement the background switching effect configuration for the YOUR_EFFECT_SHADER type.

```gdscript
BackgroundTransitionEffectsType.YOUR_EFFECT_SHADER: {
	"shader": your_effect_shader,  // Background switching Shader, should match the variable above
	"duration": 1.0,  // Transition duration, default 1.0s
	"progress_target": 1.0,  // Target progress, default 1.0
	"tween_trans": Tween.TRANS_LINEAR  // Easing type during switching
}
```

Then test the background switching effect. When switching scenes, add the following test code and observe whether the effect matches expectations.

```gdscript
bg.material.set("shader", your_effect_shader)

bg.material.set_shader_parameter("progress", 0.0)
bg.material.set_shader_parameter("current_texture", current_texture)
bg.material.set_shader_parameter("target_texture", tex)

# Create and configure transition animation
effect_tween = get_tree().create_tween()
effect_tween.tween_property(
	bg.material, 
	"shader_parameter/progress", 
	1.0, 
	1.0
)

effect_tween.play()
```
