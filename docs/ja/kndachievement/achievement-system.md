---
title: 実績システム
order: 2
---

# 実績システム KonadoAchievement

## はじめに

KonadoAchievement は、Konado 向けに設計された軽量なデータ駆動型の実績システムプラグインです。実績の解除、進捗追跡、ポップアップ通知、実績パネルなどの包括的な機能を提供します。Konado と連携して使用することも、単独で動作させることもできます。

### 設定ファイル

実績システムは JSON 設定ファイルで実績を定義します。デフォルトのパスは `res://addons/konado_achievement/data/achievements.json` で、`KND_AchievementManager` から別のパスを設定できます。

設定ファイル構造の例：

```json
{
  "achievements": [
    {
      "id": "first_blood",
      "name": "初めての章",
      "description": "最初のメインストーリー分岐を解除する。",
      "icon": "",
      "hidden": false,
      "category": "story",
      "points": 10,
      "conditions": {
        "type": "counter",
        "target_key": "story_branch_unlocked",
        "target_value": 1
      }
    }
  ]
}
```

### 設定オプション（任意）

`KND_AchievementManager` では、以下のプロパティを設定できます。

- `config_path`: 実績設定ファイルのパス
- `save_path`: 実績進捗の保存パス
- `popup_duration`: 実績解除ポップアップ通知の表示時間
- `popup_position`: ポップアップ通知の位置（top_left, top_right, bottom_left, bottom_right）

::tip
この部分は将来、より柔軟な設定オプションを提供するためにリファクタリングされる可能性があります。
::

## コア機能

### 実績解除

実績システムは 2 種類の解除方法をサポートします。

1. **直接解除**：API を通じて実績を直接解除します
2. **条件解除**：特定の条件を満たしたときに実績を自動的に解除します

### 進捗追跡

システムは 2 種類の進捗追跡をサポートします。

1. **カウンター**：累計値が目標値に到達したときに解除します
2. **フラグ**：フラグが特定の値に設定されたときに解除します

### 通知システム

実績が解除されると、システムは実績名、説明、アイコンを含むポップアップ通知を表示します。

### 実績パネル

解除済みと未解除の実績、および解除進捗を含む、すべての実績を表示できるパネルを提供します。

## 実績設定の詳細

### 実績プロパティ

各実績には以下のプロパティを含めることができます。

- `id`: 実績の一意な識別子
- `name`: 実績名
- `description`: 実績の説明
- `icon`: 実績アイコンのパス（任意）
- `hidden`: 非表示にするかどうか（未解除時に名前と説明を表示しない）
- `category`: 実績カテゴリ（任意）
- `points`: 実績ポイント（任意）
- `conditions`: 解除条件

### 条件タイプ

#### カウンタータイプ

```json
{
  "type": "counter",
  "target_key": "counter_key",
  "target_value": 10
}
```

`counter_key` の値が `target_value` に到達、またはそれを超えたときに解除されます。

#### フラグタイプ

```json
{
  "type": "flag",
  "target_key": "flag_key",
  "target_value": true
}
```

`flag_key` の値が `target_value` と等しいときに解除されます。

## 使用例

### 基本的な使い方

```gdscript
# カウンター値を増やす
KND_AchievementManager.increment_progress("story_branch_unlocked", 1)

# フラグを設定
KND_AchievementManager.set_flag("secret_ending_unlocked", true)

# 実績を直接解除
KND_AchievementManager.unlock_achievement("special_achievement")

# 実績パネルを表示
KND_AchievementManager.show_panel()
```

### シグナルの監視

```gdscript
# 実績解除イベントを監視
KND_AchievementManager.achievement_unlocked.connect(_on_achievement_unlocked)

func _on_achievement_unlocked(achievement_id: String, data: Dictionary) -> void:
    print("実績解除: " + data.get("name"))
    # ここに追加の報酬ロジックを記述できます
```

### カスタム保存/読み込み

```gdscript
# カスタム保存処理を設定
KND_AchievementManager.custom_save_handler = Callable(self, "_custom_save")
KND_AchievementManager.custom_load_handler = Callable(self, "_custom_load")

func _custom_save(data: Dictionary) -> void:
    # カスタム保存ロジック
    pass

func _custom_load() -> Dictionary:
    # カスタム読み込みロジック
    return {"unlocked": {}, "progress": {}}
```

### 外部連携

```gdscript
# 外部解除コールバックを設定
KND_AchievementManager.on_external_unlock = Callable(self, "_on_external_unlock")

func _on_external_unlock(achievement_id: String, data: Dictionary) -> void:
    # 外部バックエンドへ同期
    pass
```
