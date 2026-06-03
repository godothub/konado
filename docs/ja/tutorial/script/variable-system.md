---
title: 変数システム
order: 8
---

# 変数システム

## 機能概要

変数システムを使うと、スクリプト内で変数の定義、読み取り、変更、判定を行えます。これにより、動的な会話文、条件分岐、状態追跡を実現できます。変数値は会話テキスト内で直接参照でき、条件判定の根拠としてストーリーの流れを制御することもできます。

変数には 2 種類あります。

| 種類 | 接頭辞 | ライフサイクル | 永続化 | 初期化方法 |
|------|--------|----------------|--------|------------|
| 永続変数 | `%` | ショットをまたいで保持 | セーブデータと一緒に保存 | インスペクターでプリセット / コードで初期化 |
| 一時変数 | `$` | 現在のショット内のみ有効 | 保存されない | スクリプト内の `set` で初期化 |

---

## 変数操作

5 種類の基本操作に対応しています。構文は次のとおりです。

```
<操作> <変数名> <値>
```

等号を付けた形式も使用できます。

```
<操作> <変数名> = <値>
```

### 操作一覧

| 操作 | 説明 | 例 |
|------|------|----|
| `set` | 変数値を設定します | `set %love = 10` |
| `add` | 加算。数値の加算、または文字列の連結 | `add %love 5` |
| `sub` | 減算 | `sub %love 3` |
| `mul` | 乗算 | `mul %love 2` |
| `div` | 除算。除数が 0 の場合はエラー | `div %love 4` |

### 引数の詳細

| 引数 | 必須 | 例 | 説明 |
|------|------|----|------|
| 操作 | はい | `set` | 5 種類の操作のいずれか |
| 変数名 | はい | `%love` | `%` で始まるものは永続変数、`$` で始まるものは一時変数 |
| 値 | はい | `10` | 整数、浮動小数点数、真偽値（`true`/`false`）、または二重引用符で囲んだ文字列 |

### 例

```
set %love = 10
add %love 5
sub %love 3
mul %love 2
div %love 4

set $round = 1
add $round 1

set %player_name "プレイヤー"
set $stage "はじまりの村"
set %unlocked true
```

---

## 変数の補間

会話テキスト内で `%変数名` または `$変数名` を直接使用すると、実行時に実際の値へ置き換えられます。

### 構文

```
"キャラクター名" "会話テキスト。%変数名 または $変数名 を含められます"
```

### 例

```
set %player_name "太郎"
set $stage "はじまりの村"

"Kona" "こんにちは、%player_name！今いる場所は $stage です。"
"Kona" "好感度は %love、現在は第 $round ラウンドです。"
```

実行時の出力:

```
Kona: "こんにちは、太郎！今いる場所は はじまりの村 です。"
Kona: "好感度は 12、現在は第 2 ラウンドです。"
```

---

## 条件判定

`if` / `else` / `endif` 構造を使い、変数値に応じて再生する会話を決定します。6 種類の比較演算子に対応しています。

### 構文

```
if <変数名> <演算子> <値>:
    <会話内容>
else:
    <会話内容>
endif
```

`else:` ブロックは省略できます。省略した場合、条件が成立しなければ `if` ブロック全体がスキップされます。

### 対応する演算子

| 演算子 | 説明 | 例 |
|--------|------|----|
| `==` | 等しい | `if %love == 5:` |
| `!=` | 等しくない | `if %love != 10:` |
| `>` | より大きい | `if %love > 3:` |
| `<` | より小さい | `if %love < 10:` |
| `>=` | 以上 | `if %love >= 5:` |
| `<=` | 以下 | `if %love <= 5:` |

### 引数の詳細

| 引数 | 必須 | 例 | 説明 |
|------|------|----|------|
| 変数名 | はい | `%love` | `%` の永続変数、または `$` の一時変数 |
| 演算子 | はい | `==` | 6 種類の比較演算子のいずれか |
| 値 | はい | `5` | 比較に使用する整数値 |

### 例

```
if %love == 5:
    "Kona" "好感度はちょうど 5 です！"
else:
    "Kona" "好感度は 5 ではありません。"
endif

if $score >= 80:
    "Kona" "良好です！"
endif

if $score >= 60:
    "Kona" "合格です。"
endif
```

### 注意事項

1. `if` / `else` / `endif` は、周囲のコンテキストと同じインデント階層にしてください。
2. 条件判定は**ネストに対応していません**。つまり、`if` ブロック内にさらに `if` を含めることはできません。
3. 複数の独立した条件判定は、ネストではなく平坦な `if` / `endif` 構造で記述してください。
4. 条件判定は `branch` ブロック内でも使用できます。

---

## 分岐内で条件判定を使う

`branch` ブロック内には `if` / `endif` 条件判定を含められます。これにより、分岐内でも動的な会話を実現できます。

### 例

```
branch after_choice
    "Kona" "あなたの選択は記録されました。"

    if $choice_made == 1:
        "Kona" "プレゼントを贈ることを選びましたね。優しいですね。"
    endif

    if $choice_made == 2:
        "Kona" "会話することを選びましたね。コミュニケーションは大切です。"
    endif

    if $choice_made == 3:
        "Kona" "無視することを選びました……次は別の選択肢も試してみてください。"
    endif
```

---

## 選択肢と変数の連動

`choice` と `branch` を組み合わせると、ユーザーが選択した後に変数値を変更できます。これにより、選択が後続のストーリーに影響するようになります。

### 例

```
set $choice_made = 0

choice "プレゼントを贈る（好感度+10）" -> gift_choice
choice "会話する（好感度+5）" -> chat_choice
choice "無視する（好感度-5）" -> ignore_choice

branch gift_choice
    add %love 10
    set $choice_made = 1
    "Kona" "ありがとうございます！好感度が %love まで上がりました！"
    jump_branch after_choice

branch chat_choice
    add %love 5
    set $choice_made = 2
    "Kona" "あなたと話せて楽しかったです。今の好感度は %love です。"
    jump_branch after_choice

branch ignore_choice
    sub %love 5
    set $choice_made = 3
    "Kona" "……好感度が %love まで下がりました。"
    jump_branch after_choice

branch after_choice
    "Kona" "あなたの選択は記録されました。"
```

---

## 真偽値変数

変数は真偽値に対応しています。代入には `true` / `false` を使用します。条件判定では、`true` は `1`、`false` は `0` と同等です。

### 例

```
set %unlocked true
set $visited false

if %unlocked == 1:
    "Kona" "機能がアンロックされました！"
endif

set $visited true
if $visited == 1:
    "Kona" "訪問済みフラグが設定されました。"
endif
```

---

## 変数の初期化

### 永続変数（%）

永続変数は、スクリプト実行前に初期化する必要があります。方法は 2 つあります。

**方法 1: インスペクターでプリセット（推奨）**

エディターで `KND_VariableStore` リソースを作成し、インスペクターで初期変数値を設定してから、`KND_DialogueManager` の `variable_store` プロパティへ割り当てます。

**方法 2: コードで初期化**

```gdscript
func _ready() -> void:
    if dialogue_manager.variable_store == null:
        var store = KND_VariableStore.new()
        store.set_value("love", 0)
        store.set_value("player_name", "")
        store.set_value("unlocked", false)
        dialogue_manager.variable_store = store
```

### 一時変数（$）

一時変数にプリセットは不要です。スクリプト内で初めて `set` を使用したときに自動作成されます。ショットを切り替えると自動的にリセットされます。

---

## 完全な例

次は、すべての変数機能を含む総合デモです。

```
play bgm echo
background bg1 fade

actor show コナ 通常 at 3 9 scale 0.3
"Kona" "変数システムのデモへようこそ！"

set %love = 10
"Kona" "好感度を 10 に設定しました。現在の値：%love"

add %love 5
"Kona" "5 を加えた後の好感度：%love"

sub %love 3
"Kona" "3 を引いた後の好感度：%love"

mul %love 2
"Kona" "2 を掛けた後の好感度：%love"

div %love 4
"Kona" "4 で割った後の好感度：%love"

set $round = 1
set $bonus = 100
"Kona" "ラウンド=$round、ボーナス=$bonus"

add $round 1
add $bonus 50
"Kona" "第 $round ラウンド、ボーナス $bonus"

set %player_name "プレイヤー"
"Kona" "こんにちは、%player_name！好感度 %love、第 $round ラウンドです。"

if %love == 6:
    "Kona" "好感度はちょうど 6 です！"
else:
    "Kona" "好感度は 6 ではありません。"
endif

if %love > 3:
    "Kona" "好感度は 3 より大きいです！"
endif

if %love < 10:
    "Kona" "好感度は 10 より小さいです。"
endif

set $score = 85

if $score >= 90:
    "Kona" "優秀です！"
endif

if $score >= 80:
    "Kona" "良好です！"
endif

set %unlocked true
if %unlocked == 1:
    "Kona" "機能がアンロックされました！"
endif

choice "プレゼントを贈る（好感度+10）" -> gift
choice "無視する（好感度-5）" -> ignore

branch gift
    add %love 10
    "Kona" "ありがとうございます！好感度 %love！"
    jump_branch done

branch ignore
    sub %love 5
    "Kona" "……好感度 %love。"
    jump_branch done

branch done
    actor exit コナ
    background bg_end fade
    end
```

---

## 注意事項

1. **変数名**には英字、数字、アンダースコアのみ使用でき、大文字と小文字は区別されます。
2. **永続変数**（`%`）の値はセーブデータと一緒に保存されます。好感度やストーリーフラグなど、ショットをまたぐ状態の記録に適しています。
3. **一時変数**（`$`）はショットを切り替えると自動的に消去されます。現在のショット内だけで使う一時状態の記録に適しています。
4. **除算操作**で除数が 0 の場合はエラーが発生し、その操作はスキップされます。
5. **条件判定**はネストに対応していません。複数の条件は平坦な `if` / `endif` 構造で記述してください。
6. `branch` ブロック内で条件判定を使う場合、`if` / `endif` のインデントは分岐内の他の内容と一致させてください。
7. 初期化されていない変数は、条件判定では条件不成立として扱われます。
