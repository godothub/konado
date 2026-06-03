---
title: 背景切り替えエフェクト
order: 3
---

# 背景トランジションエフェクト

## はじめに

背景トランジションエフェクトとは、シーン切り替え時に現在の背景画像が退出し、新しいシーンの背景画像が入ってくる効果です。この効果は視覚的なインパクトを高め、ユーザー体験を向上させます。この章では、カスタム背景トランジションエフェクトの実装を支援します。

## 背景切り替え Shader 規約

背景トランジションエフェクトを統一的に管理・再生するため、以下の Shader 規約を定めます。

shader タイプは `canvas_item` でなければなりません。

```glsl
shader_type canvas_item;
```

以下の 3 つのパラメーターを実装する必要があります。

```glsl
uniform float progress : hint_range(0, 1) = 0.0; // トランジション進捗 0=現在のみ 1=ターゲットのみ
uniform sampler2D current_texture : hint_default_black; // 現在のテクスチャ
uniform sampler2D target_texture : hint_default_black; // ターゲットテクスチャ
```

- progress：トランジション進捗。範囲は 0~1。0 は現在のテクスチャのみ表示、1 はターゲットテクスチャのみ表示を意味します。
- current_texture：現在のテクスチャ。シーン切り替え前に表示されるテクスチャです。
- target_texture：ターゲットテクスチャ。シーン切り替え後に表示されるテクスチャです。

## 背景切り替えエフェクト設定

背景切り替えは動的な処理であるため、以下も追加する必要があります。

BackgroundTransitionEffectsType enum を定義し、背景切り替えエフェクトタイプを識別します。
```
YOUR_EFFECT_SHADER
```

shader 変数を定義します。`preload` 関数で Shader ファイルを読み込むことを推奨します。
```
var your_effect_shader: Shader = preload("res://path/to/your_effect_shader.shader")
```

次に、YOUR_EFFECT_SHADER タイプの背景切り替えエフェクト設定を実装します。

```gdscript
BackgroundTransitionEffectsType.YOUR_EFFECT_SHADER: {
	"shader": your_effect_shader,  // 背景切り替え Shader。上記の変数と一致させます
	"duration": 1.0,  // トランジション時間。デフォルトは1.0s
	"progress_target": 1.0,  // 目標進捗。デフォルトは1.0
	"tween_trans": Tween.TRANS_LINEAR  // 切り替え時のイージングタイプ
}
```

続いて背景切り替えエフェクトをテストします。シーン切り替え時に以下のテストコードを追加し、効果が期待どおりか確認してください。

```gdscript
bg.material.set("shader", your_effect_shader)

bg.material.set_shader_parameter("progress", 0.0)
bg.material.set_shader_parameter("current_texture", current_texture)
bg.material.set_shader_parameter("target_texture", tex)

# トランジションアニメーションを作成して設定
effect_tween = get_tree().create_tween()
effect_tween.tween_property(
	bg.material, 
	"shader_parameter/progress", 
	1.0, 
	1.0
)

effect_tween.play()
```
