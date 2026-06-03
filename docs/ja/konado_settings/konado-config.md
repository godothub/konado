---
title: 設定ファイル
order: 1
---

# 設定ファイルガイド

## 設定ファイルの構造

デフォルト設定ファイルは `res://addons/konado_settings/resources/default_settings.json` にあります。設定項目は JSON 形式で定義します。

### 基本構造

```json
{
	"categories": [
		{
			"id": "audio",
			"display_name": "オーディオ",
			"items": [
				{
					"key": "master_volume",
					"label": "マスター音量",
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

## 設定項目の説明

### トップレベル構造

- **categories**: すべての設定カテゴリを含む配列です。

### カテゴリのプロパティ

- **id**: カテゴリの一意な識別子です。コードから参照するときに使用します。
- **display_name**: 設定パネルに表示されるカテゴリ名です。
- **items**: そのカテゴリに含まれる設定項目の配列です。

### 設定項目のプロパティ

- **key**: 設定項目の一意な識別子です。同じカテゴリ内で重複してはいけません。
- **label**: 設定パネルに表示されるラベルです。
- **type**: 設定タイプです。
  - `0`: スライダー（SLIDER）
  - `1`: トグル（TOGGLE）
  - `2`: オプション（OPTION）

#### スライダー型（SLIDER）専用プロパティ

- **min_value**: 最小値
- **max_value**: 最大値
- **step**: ステップ幅
- **default_value**: デフォルト値（float 型）

#### トグル型（TOGGLE）専用プロパティ

- **default_value**: デフォルト値（bool 型）

#### オプション型（OPTION）専用プロパティ

- **options**: 選択肢の一覧（Array[String]）
- **default_value**: デフォルト値（String 型）。`options` の中に含まれている必要があります。

#### 共通プロパティ

- **platforms**: 表示対象のプラットフォーム一覧です。空配列、または `"all"` を含む場合はすべてのプラットフォームで表示されます。

## 対応プラットフォーム識別子

- `all` - すべてのプラットフォーム
- `android` - Android
- `bsd` - BSD
- `linux` - Linux
- `macos` - macOS
- `ios` - iOS
- `visionos` - visionOS
- `windows` - Windows
- `linuxbsd` - Linux または BSD
- `debug` - デバッグビルド
- `release` - リリースビルド
- `editor` - エディタービルド

## プラットフォームフィルタのルール

1. **空配列**: すべてのプラットフォームで表示されます。
2. **"all" を含む**: すべてのプラットフォームで表示されます。
3. **特定プラットフォーム**: 指定したプラットフォームでのみ表示されます。
4. **プラットフォーム別名**: `linuxbsd` は Linux または BSD に一致します。
5. **ビルド種別**: `debug` と `release` はビルド種別に応じてフィルタされます。

## 設定例

### 完全な設定例

```json
{
	"categories": [
		{
			"id": "audio",
			"display_name": "オーディオ",
			"items": [
				{
					"key": "master_volume",
					"label": "マスター音量",
					"type": 0,
					"min_value": 0.0,
					"max_value": 1.0,
					"step": 0.01,
					"default_value": 1.0,
					"platforms": ["all"]
				},
				{
					"key": "music_volume",
					"label": "音楽音量",
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
			"display_name": "表示",
			"items": [
				{
					"key": "fullscreen",
					"label": "フルスクリーン",
					"type": 1,
					"default_value": false
				},
				{
					"key": "language",
					"label": "言語",
					"type": 2,
					"options": ["zh", "tc", "en", "ja", "ko"],
					"default_value": "zh"
				},
				{
					"key": "debug_mode",
					"label": "デバッグモード",
					"type": 1,
					"default_value": false,
					"platforms": ["debug"]
				},
				{
					"key": "windows_only",
					"label": "Windows 専用",
					"type": 1,
					"default_value": false,
					"platforms": ["windows"]
				}
			]
		}
	]
}
```

### 型別の設定項目例

#### スライダー型

```json
{
	"key": "text_speed",
	"label": "文字速度",
	"type": 0,
	"min_value": 0.01,
	"max_value": 0.2,
	"step": 0.005,
	"default_value": 0.05
}
```

#### トグル型

```json
{
	"key": "auto_mode",
	"label": "自動モード",
	"type": 1,
	"default_value": false
}
```

#### オプション型

```json
{
	"key": "quality",
	"label": "画質",
	"type": 2,
	"options": ["低", "中", "高", "最高"],
	"default_value": "中"
}
```

## 設定のベストプラクティス

1. **命名規則**
   - `id` と `key` には小文字とアンダースコアを使用します。
   - `display_name` にはユーザーに分かりやすい名前を使用します。

2. **プラットフォーム設定**
   - 汎用設定には `"platforms": ["all"]` を使用します。
   - プラットフォーム固有の設定では対象プラットフォームを明示します。

3. **デフォルト値**
   - すべての設定項目に妥当なデフォルト値を用意します。
   - デフォルト値の型が設定タイプと一致していることを確認します。

4. **整理方法**
   - 機能ごとに設定をカテゴリへ分けます。
   - カテゴリ数は適切に保ち、多くなりすぎないようにします。

5. **形式チェック**
   - JSON 検証ツールで設定ファイルの形式を確認します。
   - 必須プロパティがすべて設定されていることを確認します。

## 注意事項

- 設定項目の `key` は同じカテゴリ内で一意にしてください。
- スライダー型では `min_value` < `max_value` になるようにしてください。
- オプション型では `options` 配列を空にしないでください。
- 設定ファイルを変更した後は、ゲームを再起動するか `rebuild()` を呼び出して設定パネルを更新する必要があります。
