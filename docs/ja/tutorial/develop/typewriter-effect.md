---
title: タイプライター演出
order: 5
---

# タイプライター効果 (Typewriter Effect)

## 概要

Konado は強力なタイプライター効果コンポーネントを提供します。GPU 加速による文字単位のフェードインに対応し、ゲームの会話をより生き生きと楽しいものにします。

## コア機能

- **GPU 加速レンダリング** - 専用シェーダーで文字単位に描画し、高い性能を発揮します
- **BBCode リッチテキスト対応** - 太字、斜体、色、下線、取り消し線などに対応します
- **複数のフェード方向** - 任意角度のフェード方向を設定できます
- **空間ブレンド** - 文字順序と空間順序を混合したフェード効果が可能です
- **CJK 多言語対応** - 中国語、日本語、韓国語などのマルチバイト文字を完全にサポートします

## 基本使用

### 会話ボックスで使用

`KND_DialogueBox` コンポーネントでは、タイプライター効果を直接有効化できます。

1. シーン内の `KND_DialogueBox` ノードを選択
2. Inspector パネルで対応する設定項目を探す
3. タイプライターモードを有効化

### コードから使用

```gdscript
var typewriter = $KND_TypewriterText
typewriter.set_bbcode("[color=yellow]こんにちは[/color]、[b]プレイヤー[/b]！")
typewriter.start()
typewriter.skip()
typewriter.reset()
```

## BBCode リッチテキスト

| タグ | 説明 | 例 |
|------|------|------|
| `[b]` | 太字 | `[b]太字テキスト[/b]` |
| `[i]` | 斜体 | `[i]斜体テキスト[/i]` |
| `[u]` | 下線 | `[u]下線テキスト[/u]` |
| `[s]` | 取り消し線 | `[s]取り消し線テキスト[/s]` |
| `[color=色]` | 文字色 | `[color=red]赤色[/color]` |
| `[font=フォント]` | 指定フォント | `[font=my_font]特殊フォント[/font]` |

```bbcode
[color=#FF5733]オレンジ色の文字[/color]
[color=green]緑色の文字[/color]
[color=#3498db]青色の文字[/color]
[color=yellow]黄色の文字[/color]
```

## フェード設定

- `fade_angle`：文字のフェード方向角度。`0°` は左から右、`90°` は上から下、`-90°` は下から上、`180°` は右から左、任意角度も指定できます。
- `spatial_blend`：文字表示順と空間位置の混合度。`0.0` は文字順、`0.5` は混合、`1.0` は空間位置順です。
- `fade_width`：フェード効果の柔らかさ。値が大きいほど端が柔らかくなります。

## シグナル

| シグナル | 説明 |
|------|------|
| `typewriter_started` | タイプライター効果開始時に発火 |
| `typewriter_finished` | タイプライター効果完了時に発火 |
| `typewriter_skipped` | 効果をスキップしたときに発火 |
| `character_revealed(index)` | 各文字表示時に発火。index は文字インデックス |

## API リファレンス

| プロパティ | 型 | デフォルト | 説明 |
|------|------|--------|------|
| `bbcode_text` | String | "" | 表示する BBCode テキスト |
| `font` | Font | null | カスタムフォント |
| `font_size` | int | 20 | フォントサイズ |
| `font_color` | Color | WHITE | 文字色 |
| `chars_per_second` | float | 25.0 | 1 秒あたりの表示文字数 |
| `fade_width` | float | 3.0 | フェード幅 |
| `fade_angle` | float | 0.0 | フェード角度（度） |
| `spatial_blend` | float | 0.15 | 空間ブレンド比率 |
| `auto_start` | bool | true | 自動開始するか |

| メソッド | 説明 |
|------|------|
| `start()` | タイプライター効果を開始 |
| `skip()` | スキップしてすべて即時表示 |
| `reset()` | リセットしてすべてのテキストを非表示 |
| `set_bbcode(text, autoplay)` | BBCode テキストを設定 |
| `is_playing()` | 再生中か |
| `is_finished()` | 完了済みか |
| `get_progress()` | 現在の進捗を取得 |

## 高度な使い方

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
    # タイピング完了後に処理を実行
    show_continue_button()
```

## パフォーマンス最適化

- GPU シェーダーレンダリングを使用し、高い性能を発揮します
- 大量のテキストでもカクつきにくいです
- モバイルプラットフォームでは `chars_per_second` を適切に下げることを推奨します

## 注意事項

1. **BBCode タグは必ずペアにする**
2. **色値はカスタム可能** - `#FF5733` などの 16 進カラーコードに対応
3. **エディタープレビュー** - エディター実行時はプレビューしやすいよう全テキストが直接表示されます
4. **改行** - `\n` を使用します
