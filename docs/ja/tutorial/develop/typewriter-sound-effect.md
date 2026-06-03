---
title: タイプライター効果音
order: 6
---

# タイプライター効果音 (Typing Sound Effect)

## 概要

Konado の会話ボックスコンポーネントはタイプライター効果音に対応しています。タイピング中に短いクリック音を再生し、ゲームの没入感とフィードバックを高めます。

## 効果音ディレクトリ

タイプライター効果音ファイルは以下のディレクトリに配置します。

```
res://addons/konado/audioeffect/typewriter/
```

## 対応音声形式

| 形式 | 説明 |
|------|------|
| `.wav` | 非圧縮音声。推奨 |
| `.ogg` | Ogg Vorbis 圧縮形式 |
| `.mp3` | MP3 圧縮形式 |

## 基本設定

`KND_DialogueBox` コンポーネントの Inspector パネルで、タイプライター効果音の設定を確認できます。

```gdscript
@export var enable_typing_effect_audio: bool = true
@export var typing_effect_audio: AudioStream
```

`enable_typing_effect_audio` を `true` にすると効果音が有効になり、`false` にすると無効になります。エディターのドロップダウンから効果音ファイルを選択するか、コードで読み込めます。

```gdscript
dialogue_box.typing_effect_audio = load("res://addons/konado/audioeffect/typewriter/click.wav")
```

## 効果音トリガー設定

```gdscript
@export var audio_trigger_chance: float = 0.8
@export var min_audio_interval: float = 0.02
@export var max_audio_interval: float = 0.08
@export var audio_volumn: float = 0.6
```

- `audio_trigger_chance`：効果音の発生確率。範囲は 0.0-1.0。`1.0` は毎回再生、`0.8` は 80% の確率、`0.0` は再生しません。
- `min_audio_interval` / `max_audio_interval`：効果音再生のランダム間隔範囲です。異なるタイピングリズムに合わせて調整します。
- `audio_volumn`：効果音音量。範囲は 0.0-1.0。

## 使用例

```gdscript
var dialogue_box = $KND_DialogueBox
dialogue_box.enable_typing_effect_audio = true
dialogue_box.typing_effect_audio = load("res://addons/konado/audioeffect/typewriter/my_click.wav")
dialogue_box.audio_trigger_chance = 1.0
dialogue_box.audio_volumn = 0.8
dialogue_box.min_audio_interval = 0.02
dialogue_box.max_audio_interval = 0.06
```

## 推奨効果音

- **タイプライタークリック音**：高速で密度の高いタイピングに適し、`0.02 - 0.05` と `audio_trigger_chance: 0.8` を推奨
- **メカニカルキーボード音**：タイピング感の強いゲームに適し、`0.03 - 0.08` と `audio_trigger_chance: 0.9` を推奨
- **柔らかいクリック音**：カジュアルで落ち着いた雰囲気に適し、`0.05 - 0.12`、`audio_trigger_chance: 0.7`、`audio_volumn: 0.5` を推奨

## トリガータイミング

タイプライター効果音は、タイピングアニメーション再生中、前回再生からランダム間隔を超え、確率判定に成功し、テキスト表示がまだ完了していない場合に発生します。

## 注意事項と最適化

1. 効果音ファイル名は英語を推奨し、特殊文字を避けてください。
2. 効果音の長さは 0.1 秒以内が最適です。
3. タイピング効果音が BGM を覆わないよう音量バランスを調整してください。
4. モバイルでは容量節約のため ogg/mp3 などの圧縮形式を推奨します。
5. 短い効果音ファイル（100 KB 未満推奨）を使用し、不要な場合は `enable_typing_effect_audio = false` で無効化してください。

## トラブルシューティング

- 効果音が再生されない場合は、`enable_typing_effect_audio`、`typing_effect_audio`、ファイルパス、音量を確認してください。
- 効果音が密集しすぎる場合は、間隔値を大きくするか `audio_trigger_chance` を下げてください。
- 効果音が少なすぎる場合は、間隔値を小さくするか `audio_trigger_chance` を上げてください。
