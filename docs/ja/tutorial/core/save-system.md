---
title: セーブシステム
order: 2
---

# セーブシステム

## 使用方法

### ゲームを保存

```gdscript
# 指定スロットへ保存
dialogue_manager.save_game(1)  # スロット 1 へ保存

# またはセーブシステムを直接使用
save_system.save_game(2)  # スロット 2 へ保存
```

### ゲームを読み込み

```gdscript
# 指定スロットから読み込み
dialogue_manager.load_game(1)  # スロット 1 から読み込み

# またはセーブシステムを直接使用
save_system.load_game(2)  # スロット 2 から読み込み
```

### セーブを削除

```gdscript
# 指定スロットのセーブを削除
dialogue_manager.delete_save(1)  # スロット 1 のセーブを削除

# またはセーブシステムを直接使用
save_system.delete_save(2)  # スロット 2 のセーブを削除
```

### セーブ情報を取得

```gdscript
# 指定スロットのセーブ情報を取得
var save_info = dialogue_manager.get_save_info(1)
print("保存時間: " + str(save_info.get("save_time", {})))

# すべてのセーブ情報を取得
var all_save_infos = dialogue_manager.get_all_save_info()
for i in range(all_save_infos.size()):
    if all_save_infos[i].get("exists", false):
        print("セーブ " + str(i) + " が存在します")
```

### セーブ戦略を設定

```gdscript
# カスタムセーブ戦略
var custom_strategy = {
    "include_dialogue_state": true,    # 会話状態を含める
    "include_variables": true,          # 変数を含める
    "include_audio_state": false,       # オーディオ状態を含めない
    "include_actor_state": false,       # アクター状態を含めない
    "include_background_state": false   # 背景状態を含めない
}

dialogue_manager.set_save_strategy(custom_strategy)
```

## セーブデータ構造

セーブデータには以下が含まれます。

- **dialogue_state** - 会話状態。現在のショット、会話インデックス、会話状態を含みます
- **variables** - ゲーム変数
- **audio_state** - オーディオ状態（予約）
- **actor_state** - アクター状態（予約）
- **background_state** - 背景状態（予約）
- **save_time** - 保存時間
- **version** - セーブバージョン

## セーブファイル形式

セーブファイルは JSON 形式で保存され、`user://saves/` ディレクトリ下に置かれます。ファイル名は `[スロットID].sav` です。
