---
title: API の使用
order: 3
---

# KND_AchievementManager API リファレンス

## シグナル

実績システムは以下のシグナルを提供します。実績関連イベントを監視し、カスタムロジックを実行できます。

### achievement_unlocked

**シグナルシグネチャ：** `achievement_unlocked(achievement_id: String, data: Dictionary)`

**トリガータイミング：** 任意の実績が解除されたとき

**引数：**
- `achievement_id`: 解除された実績の ID
- `data`: 実績の完全なデータ辞書。名前、説明、アイコンなどの情報を含みます

**使用場面：** 実績解除時に報酬ロジックを実行する、祝福アニメーションを再生する、カスタム通知を表示する場合など

**サンプルコード：**
```gdscript
# シグナルを接続
KND_AchievementManager.achievement_unlocked.connect(_on_achievement_unlocked)

# シグナル処理関数
func _on_achievement_unlocked(achievement_id: String, data: Dictionary) -> void:
    print("実績解除: " + data.get("name"))
    # 実績解除効果音を再生
    # カスタム祝福アニメーションを表示
    # プレイヤーに報酬を付与
```

### achievement_progress_updated

**シグナルシグネチャ：** `achievement_progress_updated(achievement_id: String, current: float, target: float)`

**トリガータイミング：** 実績の進捗値が更新されたとき

**引数：**
- `achievement_id`: 進捗が更新された実績の ID
- `current`: 現在の進捗値
- `target`: 目標進捗値

**使用場面：** 実績進捗バーを表示する、進捗フィードバックを提供する、UI 表示を更新する場合など

**サンプルコード：**
```gdscript
# シグナルを接続
KND_AchievementManager.achievement_progress_updated.connect(_on_progress_updated)

# シグナル処理関数
func _on_progress_updated(achievement_id: String, current: float, target: float) -> void:
    var progress_percentage = (current / target) * 100
    print("実績進捗更新: " + achievement_id + " - " + str(progress_percentage) + "%")
    # UI 進捗バーを更新
    # 進捗ヒントを表示
```

### achievements_reset

**シグナルシグネチャ：** `achievements_reset()`

**トリガータイミング：** すべての実績がリセットされたとき

**引数：** なし

**使用場面：** 実績リセット後に UI を更新する、リセット通知を表示する、クリーンアップ処理を実行する場合など

**サンプルコード：**
```gdscript
# シグナルを接続
KND_AchievementManager.achievements_reset.connect(_on_achievements_reset)

# シグナル処理関数
func _on_achievements_reset() -> void:
    print("すべての実績がリセットされました")
    # 実績パネルを更新
    # リセット通知を表示
```

### achievements_loaded

**シグナルシグネチャ：** `achievements_loaded()`

**トリガータイミング：** 実績システムの読み込みが完了したとき

**引数：** なし

**使用場面：** 実績読み込み完了後に UI を初期化する、実績データに依存するロジックを実行する場合など

**サンプルコード：**
```gdscript
# シグナルを接続
KND_AchievementManager.achievements_loaded.connect(_on_achievements_loaded)

# シグナル処理関数
func _on_achievements_loaded() -> void:
    print("実績データの読み込みが完了しました")
    # 実績パネルを初期化
    # 実績データに依存するロジックを実行
```

## コアメソッド

### 実績を解除

```gdscript
# ID で実績を直接解除
KND_AchievementManager.unlock_achievement("achievement_id")
```

### 進捗管理

```gdscript
# カウンター値を増やす
KND_AchievementManager.increment_progress("counter_key", 1.0)

# フラグ値を設定
KND_AchievementManager.set_flag("flag_key", true)
```

### 実績の照会

```gdscript
# 実績が解除済みか確認
KND_AchievementManager.is_unlocked("achievement_id")

# 単一の実績データを取得
KND_AchievementManager.get_achievement("achievement_id")

# すべての実績を取得
KND_AchievementManager.get_all_achievements()

# 解除済み実績を取得
KND_AchievementManager.get_unlocked_achievements()

# 未解除実績を取得
KND_AchievementManager.get_locked_achievements()

# 解除率を取得
KND_AchievementManager.get_unlock_percentage()
```

### パネル管理

```gdscript
# 実績パネルを表示
KND_AchievementManager.show_panel()

# 実績パネルを非表示
KND_AchievementManager.hide_panel()

# 実績パネルの表示状態を切り替え
KND_AchievementManager.toggle_panel()

# パネルが表示中か確認
KND_AchievementManager.is_panel_visible()
```

#### リセット機能
```gdscript
# すべての実績をリセット
KND_AchievementManager.reset_all()

# 単一の実績をリセット
KND_AchievementManager.reset_achievement("achievement_id")
```
