---
title: API の使用
order: 2
---

# Konado Settings API ドキュメント

## 設定マネージャー (KND_Settings)

設定マネージャーは自動読み込みされるシングルトンで、すべての設定項目を管理します。

### シグナル

#### `setting_changed(category: String, key: String, value: Variant)`
- **説明**: 設定値が変更されたときに送信されるシグナルです。
- **引数**:
  - `category`: 設定カテゴリ。
  - `key`: 設定項目のキー。
  - `value`: 新しい設定値。

### メソッド

#### `get_setting(category: String, key: String) -> Variant`
- **説明**: 設定の現在値を取得します。
- **引数**:
  - `category`: 設定カテゴリ。
  - `key`: 設定項目のキー。
- **戻り値**: 設定値。存在しない場合はデフォルト値、または null を返します。

#### `set_setting(category: String, key: String, value: Variant) -> void`
- **説明**: 設定を変更し、保存してシグナルを送信します。
- **引数**:
  - `category`: 設定カテゴリ。
  - `key`: 設定項目のキー。
  - `value`: 新しい設定値。

#### `register_category(cat: SettingCategory) -> void`
- **説明**: 実行時に追加の設定カテゴリを登録します。
- **引数**:
  - `cat`: 登録する設定カテゴリ。

#### `reset_category(category_id: String) -> void`
- **説明**: 指定したカテゴリ内のすべての設定をデフォルト値に戻します。
- **引数**:
  - `category_id`: カテゴリ ID。

#### `get_categories() -> Array`
- **説明**: 登録済みのすべてのカテゴリを、現在のプラットフォームに応じてフィルタして取得します。
- **戻り値**: フィルタ後のカテゴリ配列。

#### `get_category(id: String) -> SettingCategory`
- **説明**: ID から単一カテゴリを取得し、現在のプラットフォームに応じてフィルタします。
- **引数**:
  - `id`: カテゴリ ID。
- **戻り値**: フィルタ後のカテゴリオブジェクト。

## 設定カテゴリ (SettingCategory)

設定カテゴリは、関連する設定項目をまとめるために使用します。

### プロパティ

- **id: String**: カテゴリの一意な識別子。
- **display_name: String**: カテゴリの表示名。
- **items: Array[SettingItem]**: カテゴリに含まれる設定項目の配列。

### 例

```gdscript
var video_cat = SettingCategory.new()
video_cat.id = "video"
video_cat.display_name = "ビデオ"

# 設定項目を追加
video_cat.items.append(resolution_item)

# カテゴリを登録
KND_Settings.register_category(video_cat)
```

## 設定項目 (SettingItem)

設定項目は、個別に構成できる単位です。

### 列挙型

#### `Type`
- **SLIDER (0)**: スライダー型。数値調整に使用します。
- **TOGGLE (1)**: トグル型。真偽値に使用します。
- **OPTION (2)**: オプション型。ドロップダウン選択に使用します。

### プロパティ

- **key: String**: 設定項目の一意な識別子。
- **label: String**: 設定項目の表示ラベル。
- **type: Type**: 設定項目の型。
- **min_value: float**: スライダーの最小値。SLIDER 型のみ。
- **max_value: float**: スライダーの最大値。SLIDER 型のみ。
- **step: float**: スライダーのステップ幅。SLIDER 型のみ。
- **options: Array[String]**: 選択肢の一覧。OPTION 型のみ。
- **platforms: Array[String]**: プラットフォームフィルタ。空配列はすべてのプラットフォームで表示されることを意味します。
- **default_value: Variant**: デフォルト値。SLIDER は float、TOGGLE は bool、OPTION は String を使用します。

### 例

#### スライダー型の設定項目を作成する

```gdscript
var volume_item = SettingItem.new()
volume_item.key = "master_volume"
volume_item.label = "マスター音量"
volume_item.type = SettingItem.Type.SLIDER
volume_item.min_value = 0.0
volume_item.max_value = 1.0
volume_item.step = 0.01
volume_item.default_value = 1.0
volume_item.platforms = ["all"]
```

#### トグル型の設定項目を作成する

```gdscript
var fullscreen_item = SettingItem.new()
fullscreen_item.key = "fullscreen"
fullscreen_item.label = "フルスクリーン"
fullscreen_item.type = SettingItem.Type.TOGGLE
fullscreen_item.default_value = false
```

#### オプション型の設定項目を作成する

```gdscript
var language_item = SettingItem.new()
language_item.key = "language"
language_item.label = "言語"
language_item.type = SettingItem.Type.OPTION
language_item.options = ["zh", "tc", "en", "ja", "ko"]
language_item.default_value = "zh"
```

## UI ファクトリ (UIFactory)

UI ファクトリは、設定項目用の操作 UI を作成します。

### メソッド

#### `create_control(cat_id: String, item: SettingItem, callback: Callable) -> HBoxContainer`
- **説明**: 指定した設定項目に対応する 1 行（HBoxContainer）を作成して返します。
- **引数**:
  - `cat_id`: カテゴリ ID。
  - `item`: 設定項目。
  - `callback`: コールバック関数。形式は `callback(category_id: String, key: String, value: Variant)` です。
- **戻り値**: 作成された HBoxContainer。

### 例

```gdscript
var row = UIFactory.create_control("audio", volume_item, func(category, key, value):
	print("設定が変更されました: %s/%s = %s" % [category, key, value])
	KND_Settings.set_setting(category, key, value)
)

# コンテナへ追加
vbox_container.add_child(row)
```

## 設定パネル (SettingsPanel)

設定パネルは、設定を表示および管理するためのビジュアル UI です。

### プロパティ

- **_tab_container: TabContainer**: 異なるカテゴリの設定を表示するタブコンテナ。
- **btn_reset: Button**: デフォルトに戻すボタン。
- **btn_close: Button**: 閉じるボタン。

### メソッド

#### `rebuild() -> void`
- **説明**: UI を再構築します。新しいカテゴリを登録した後に便利です。

### シグナル

- **btn_reset.pressed**: デフォルトに戻すボタンがクリックされたときに送信されます。
- **btn_close.pressed**: 閉じるボタンがクリックされたときに送信されます。

### 例

```gdscript
# 設定パネルのシーンを読み込む
var settings_panel = preload("res://addons/universal_settings/scenes/settings_panel.tscn").instantiate()
add_child(settings_panel)

# 設定パネルを表示
settings_panel.show()

# 新しいカテゴリを登録した後にパネルを再構築
KND_Settings.register_category(new_category)
settings_panel.rebuild()
```

## プラットフォーム検出

設定システムは現在の実行プラットフォームを自動検出し、設定項目の `platforms` プロパティに応じて表示をフィルタします。

### プラットフォーム識別子

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

### プラットフォーム検出ロジック

1. まずエディター内で実行されているかを確認します。
2. `OS.has_feature()` を使用して具体的なプラットフォームを検出します。
3. 検出結果に基づいて現在のプラットフォーム識別子を設定します。
4. カテゴリ取得時に、プラットフォームに応じて設定項目をフィルタします。

## 永続化ストレージ

設定値は Godot の `ConfigFile` 形式で、`user://knd_settings.cfg` に自動保存されます。

### 保存タイミング

- `set_setting()` メソッドを呼び出したとき。
- 設定値は自動的に設定ファイルへ書き込まれます。

### 読み込みタイミング

- プラグイン初期化時。
- 保存済みの設定値は設定ファイルから自動的に読み込まれます。

## 完全な使用例

### 1. 基本的な使い方

```gdscript
# 設定値を取得
var master_volume = KND_Settings.get_setting("audio", "master_volume")

# 値を設定
KND_Settings.set_setting("audio", "master_volume", 0.8)

# 設定変更を監視
KND_Settings.setting_changed.connect(func(category, key, value):
	if category == "audio" and key == "master_volume":
		# 音量変更を処理
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(value))
)
```

### 2. 実行時に新しい設定を登録する

```gdscript
# 新しい設定カテゴリを作成
var video_cat = SettingCategory.new()
video_cat.id = "video"
video_cat.display_name = "ビデオ"

# 設定項目を作成
var resolution_item = SettingItem.new()
resolution_item.key = "resolution"
resolution_item.label = "解像度"
resolution_item.type = SettingItem.Type.OPTION
resolution_item.options = ["1280x720", "1920x1080", "2560x1440"]
resolution_item.default_value = "1920x1080"

# カテゴリへ追加
video_cat.items.append(resolution_item)

# カテゴリを登録
KND_Settings.register_category(video_cat)

# 設定パネルがすでに表示されている場合は再構築
if settings_panel:
	settings_panel.rebuild()
```

### 3. カスタム設定パネル

```gdscript
# カスタム設定パネルを作成
var panel = CanvasLayer.new()

# タブコンテナを作成
var tab_container = TabContainer.new()
tab_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
tab_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
panel.add_child(tab_container)

# 設定 UI を構築
var mgr = KND_Settings
for cat in mgr.get_categories():
	var scroll = ScrollContainer.new()
	scroll.name = cat.display_name
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(vbox)

	for item in cat.items:
		var row = UIFactory.create_control(cat.id, item, func(cat_id, key, value):
			mgr.set_setting(cat_id, key, value)
		)
		vbox.add_child(row)

	tab_container.add_child(scroll)

# シーンへ追加
add_child(panel)
```

## 注意事項

- すべての API 呼び出しは、ゲーム起動後に行ってください。
- 新しいカテゴリを登録した後は、`rebuild()` メソッドを呼び出して設定パネルを更新してください。
- プラットフォームフィルタは設定項目の表示にのみ影響し、設定値の保存には影響しません。
- 設定項目の `key` はカテゴリ内で一意である必要があります。
- オプション型では、デフォルト値が `options` 一覧に含まれている必要があります。

## エラー処理

- 設定項目が存在しない場合、`get_setting()` は null を返し、警告を出します。
- 設定ファイルの形式が不正な場合、警告を出してデフォルト値を使用します。
- プラットフォーム検出に失敗した場合、デフォルトで `all` プラットフォームになります。

## パフォーマンス上の考慮

- 設定システムは遅延読み込みを使用し、必要になったときだけ設定ファイルを解析します。
- プラットフォームフィルタはカテゴリ取得時に行われるため、設定値へのアクセス性能には影響しません。
- UI は必要に応じて作成され、設定パネルを表示するときだけコントロールが作成されます。

## 拡張の提案

1. **新しい設定タイプを追加する**:
   - `SettingItem.Type` に新しい列挙値を追加します。
   - `UIFactory` に対応する作成処理を追加します。

2. **保存方式をカスタマイズする**:
   - `settings_manager.gd` の `_load_saved()` と `set_setting()` メソッドを変更します。
   - 独自の保存・読み込み処理を実装します。

3. **設定値の検証を追加する**:
   - `set_setting()` に値の検証処理を追加します。
   - 設定値が有効な範囲内に収まるようにします。

4. **国際化対応を追加する**:
   - `display_name` と `label` の処理ロジックを変更します。
   - 多言語の設定画面に対応します。
