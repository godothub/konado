---
title: 背景切換特效
order: 3
---

# 背景轉場特效

## 前言

背景轉場特效，是指在切換場景時，背景圖片從當前場景退出，同時新場景的背景圖片進入的效果。這種特效可以增加視覺衝擊力，提升使用者體驗。閱讀本章節可以幫助您實現自定義的背景轉場特效。

## 背景切換 Shader 規範

為了統一管理和播放背景轉場特效，我們約定了一個 Shader 規範，具體如下：

Shader 類型必須是 `canvas_item`

```glsl
shader_type canvas_item;
```

必須實作以下三個參數：

```glsl
uniform float progress : hint_range(0, 1) = 0.0; // 轉場進度 0=僅 current 1=僅 target
uniform sampler2D current_texture : hint_default_black; // 當前紋理
uniform sampler2D target_texture : hint_default_black; // 目標紋理
```

- progress：轉場進度，取值範圍 0~1，0 表示僅顯示當前紋理，1 表示僅顯示目標紋理。
- current_texture：當前紋理，未切換場景時顯示的紋理。
- target_texture：目標紋理，切換場景後顯示的紋理。

## 背景切換特效配置

同時，切換背景是一個動態的過程，因此還需要補充以下：

定義 `BackgroundTransitionEffectsType` 列舉，用於標識背景切換特效類型。
```
YOUR_EFFECT_SHADER
```

定義 Shader 變數，推薦使用 `preload` 函式載入 Shader 檔案。
```
var your_effect_shader: Shader = preload("res://path/to/your_effect_shader.shader")
```

接下來需要實作 `YOUR_EFFECT_SHADER` 類型的背景切換特效配置。

```gdscript
BackgroundTransitionEffectsType.YOUR_EFFECT_SHADER: {
	"shader": your_effect_shader,  // 背景切換 Shader，應與上文中的變數一致
	"duration": 1.0,  // 轉場時長，預設為 1.0s
	"progress_target": 1.0,  // 目標進度，預設為 1.0
	"tween_trans": Tween.TRANS_LINEAR  // 切換時緩動類型
}
```

接下來測試一下背景切換特效，在切換場景時，添加以下測試程式碼，觀察背景切換效果是否符合預期。

```gdscript
bg.material.set("shader", your_effect_shader)

bg.material.set_shader_parameter("progress", 0.0)
bg.material.set_shader_parameter("current_texture", current_texture)
bg.material.set_shader_parameter("target_texture", tex)

# 建立並設定過渡動畫
effect_tween = get_tree().create_tween()
effect_tween.tween_property(
	bg.material, 
	"shader_parameter/progress", 
	1.0, 
	1.0
)

effect_tween.play()
```
