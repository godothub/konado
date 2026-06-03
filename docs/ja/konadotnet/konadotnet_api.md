---
title: API 使用
order: 2
---

# Konado .NET API

> この機能はまだ実験的です。

## 概要

Konado.NET は Konado 会話システムの C# API 拡張です。Konado 本体を置き換えるものではなく、C# から `KND_DialogueManager` を制御し、会話シグナルを購読し、`.ks` スクリプトを解析し、Konado の GDScript データリソースを扱うための薄いレイヤーです。

入口は自動読み込みノード `KonadoAPI` です。通常は `KonadoAPI.DialogueManagerApi` から使い始めます。

## 前提条件

Konado.NET は C# 対応の Godot プロジェクトでのみ使用できます。Godot 4.6 以降の .NET エディターを使用してください。非 .NET プロジェクトで有効化すると、`res://addons/konadotnet/Konadotnet.cs` を読み込めない場合があります。この場合、Konado 本体は使用できますが C# API は使用できません。

先に `Konado` プラグインを有効化し、その後 `Konadotnet` を有効化してください。シーンには `KND_DialogueManager` ノードが必要です。Konado.NET はスクリプト型で検索し、`DialogManager`、`DialogueManager`、`KonadoDialogueManager` という一般的なノード名にも対応します。複数の会話マネージャーがある場合は `BindDialogueManager(Node source)` で明示的に指定してください。

## クイックスタート

```csharp
using Godot;
using Konado.Runtime.API;
using Konado.Wrapper;

public partial class DialogueExample : Node
{
    public override void _Ready()
    {
        var dialogueManager = KonadoAPI.DialogueManagerApi;

        dialogueManager.DialogueLineStart += (string nodeId) =>
        {
            GD.Print($"Node started: {nodeId}");
        };

        dialogueManager.CustomSignal += (string content) =>
        {
            GD.Print($"Custom signal: {content}");
        };

        var interpreter = new KonadoScriptsInterpreter();
        var shot = interpreter.ProcessScriptsToData("res://sample/demo/demo_01.ks");

        dialogueManager.SetShot(shot.SourceResource);
        dialogueManager.InitDialogue();
        dialogueManager.StartDialogue();
    }
}
```

## KonadoAPI

| メンバー | 型 | 説明 |
| --- | --- | --- |
| `IsApiReady` | `bool` | `KonadoAPI` 自動読み込みノードが初期化済みかどうか。`KND_DialogueManager` が見つかったことは保証しません。 |
| `API` | `static KonadoAPI` | 現在の自動読み込みインスタンスへの静的参照。 |
| `DialogueManagerApi` | `static DialogueManagerAPI` | 会話マネージャー API インスタンス。主な実行時入口です。 |

## DialogueManagerAPI

`DialogueManagerAPI` は `KND_DialogueManager` の C# 制御レイヤーで、呼び出しを GDScript ノードへ転送します。

### プロパティ

| プロパティ | 型 | 説明 |
| --- | --- | --- |
| `IsReady` | `bool` | 使用可能な `KND_DialogueManager` にバインド済みかどうか。 |
| `Source` | `Node` | バインドされている元の Godot ノード。 |

### メソッド

| メソッド | 説明 |
| --- | --- |
| `bool BindDialogueManager(Node source = null)` | 指定した会話マネージャーへバインドします。省略時はシーンツリーを走査します。成功時は `true`。 |
| `void InitDialogue()` | `init_dialogue()` を呼び出します。通常は `SetShot()` の後、`StartDialogue()` の前に呼びます。 |
| `void SetShot(Resource shot)` | `set_shot()` を呼び出して現在の `KND_Shot` を切り替えます。ラッパーから渡す場合は `KndShot.SourceResource` を使います。 |
| `void StartDialogue()` | `start_dialogue()` を呼び出して再生を開始します。 |
| `void StopDialogue()` | `stop_dialogue()` を呼び出して再生を停止します。 |
| `void StartAutoplay(bool value)` | 自動再生を切り替えます。 |
| `bool SaveGame(int saveId)` | 進行状況を保存します。API 未準備または保存失敗時は `false`。 |
| `bool LoadGame(int saveId)` | 指定セーブを読み込みます。 |
| `bool DeleteSave(int saveId)` | 指定セーブを削除します。 |
| `Dictionary GetSaveInfo(int saveId)` | 1 件のセーブ情報を取得します。API 未準備時は空の辞書を返します。 |
| `Array<Dictionary> GetAllSaveInfo()` | すべてのセーブ情報を取得します。API 未準備時は空配列を返します。 |

標準的な再生順序:

```csharp
var shot = interpreter.ProcessScriptsToData("res://dialogues/chapter_01.ks");
dialogueManager.SetShot(shot.SourceResource);
dialogueManager.InitDialogue();
dialogueManager.StartDialogue();
```

### イベント

| イベント | 説明 |
| --- | --- |
| `ShotStart` | `shot_start` に対応。ショット開始時に発火します。 |
| `ShotEnd` | `shot_end` に対応。ショット終了時に発火します。 |
| `DialogueLineStart(string nodeId)` | `dialogue_line_start(node_id)` に対応。Konado 2.4 では旧行番号ではなくノード ID を使います。 |
| `DialogueLineEnd(string nodeId)` | `dialogue_line_end(node_id)` に対応。 |
| `CustomSignal(string content)` | `custom_signal(content)` に対応。`.ks` の `signal` 文で発火します。 |

## ActingInterface

| 列挙値 | 効果 |
| --- | --- |
| `NoneEffect` | 効果なし |
| `EraseEffect` | 消去効果 |
| `BlindsEffect` | ブラインド効果 |
| `WaveEffect` | 波効果 |
| `AlphaFadeEffect` | 透明度フェード |
| `VortexSwapEffect` | 渦巻き切り替え |
| `WindmillEffect` | 風車効果 |
| `CyberGlitchEffect` | サイバーグリッチ効果 |

## Wrapper クラス

Wrapper クラスは Konado GDScript リソースの軽量 C# ラッパーです。既存リソースを包む場合はスクリプト型を検証し、新規作成時は対応する GDScript リソースを生成します。Konado API へ戻すときは `SourceResource` を使用します。

## Dialogue

`Dialogue` は `KND_Dialogue` をラップします: `res://addons/konado/scripts/dialogue/knd_dialogue.gd`。

| メンバー | 説明 |
| --- | --- |
| `Dialogue()` | 新しい `KND_Dialogue` リソースを作成します。 |
| `Dialogue(GodotObject source)` | 既存の `KND_Dialogue` をラップします。無効なソースでは例外を投げます。 |
| `SourceResource` | 元の `Resource` を返します。 |

| プロパティ | 型 | 説明 |
| --- | --- | --- |
| `SourceFileLine` | `int` | 元の `.ks` 行番号。デバッグとエラー位置に使います。 |
| `DialogueType` | `Dialogue.Type` | ノード種別。再生時の処理を決定します。 |
| `NodeId` | `string` | 会話グラフのノード ID。 |
| `NextId` | `string` | 既定の次ノード ID。 |
| `IfNextId` | `string` | 条件が真のときの遷移先。 |
| `ElseNextId` | `string` | 条件が偽のときの遷移先。 |
| `VarName` | `string` | 条件判定に使う変数名。 |
| `ConditionOperator` | `int` | 条件演算子: `0 ==`、`1 >`、`2 <`、`3 >=`、`4 <=`。 |
| `TargetValue` | `int` | 条件比較の対象値。 |
| `CharacterId` | `string` | 話者キャラクター ID。 |
| `DialogueContent` | `string` | 会話テキスト。 |
| `VoiceId` | `string` | ボイス ID。 |
| `CharacterName` | `string` | 表示または作成するキャラクター ID。 |
| `CharacterState` | `string` | キャラクター状態または立ち絵状態 ID。 |
| `ActorPosition` | `Vector2` | キャラクター位置。Konado 2.4 はグリッド型配置を使います。 |
| `ExitActor` | `string` | 退出または非表示にするキャラクター ID。 |
| `ChangeStateActor` | `string` | 状態を変更するキャラクター ID。 |
| `ChangeState` | `string` | 変更先状態 ID。 |
| `TargetMoveChara` | `string` | 移動するキャラクター ID。 |
| `TargetMovePos` | `Vector2` | 移動先位置。 |
| `Choices` | `Array<DialogueChoice>` | 選択肢リスト。各選択肢は `NextId` で遷移先を指します。 |
| `JumpShotPath` | `string` | 別の `KND_Shot` へジャンプするリソースパス。 |
| `JumpBranchTarget` | `string` | 現在ショット内の分岐ラベル。 |
| `BgmName` | `string` | 再生する BGM 名。 |
| `SoundeffectName` | `string` | 再生する効果音名。 |
| `BackgroundImageName` | `string` | 切り替える背景画像名。 |
| `BackgroundToggleEffects` | `BackgroundTransitionEffectsType` | 背景切り替え効果。 |
| `CustomSignalName` | `string` | `CustomSignal` イベントで送られる内容。 |
| `AchievementId` | `string` | 実績 ID。 |
| `AchievementValue` | `int` | 実績進捗値。 |
| `AchievementFlagName` | `string` | 実績フラグ名。 |
| `AchievementFlagValue` | `bool` | 実績フラグ値。 |
| `VariableName` | `string` | 操作する変数名。 |
| `VariableOperation` | `int` | 変数操作: `0 SET`、`1 ADD`、`2 SUB`、`3 MUL`、`4 DIV`。 |
| `VariableOperand` | `string` | 文字列として保存され、実行時に本体側で解析される操作値。 |
| `IsPersistent` | `bool` | 永続変数かどうか。通常 `%` は永続、`$` は一時変数です。 |

### Dialogue.Type

| 値 | 説明 |
| --- | --- |
| `OrdinaryDialog` | 通常会話。 |
| `DisplayActor` | キャラクター表示または作成。 |
| `ActorChangeState` | キャラクター状態変更。 |
| `MoveActor` | キャラクター移動。 |
| `SwitchBackground` | 背景切り替え。 |
| `ExitActor` | キャラクター退出。 |
| `PlayBgm` | BGM 再生。 |
| `StopBgm` | BGM 停止。 |
| `PlaySoundEffect` | 効果音再生。 |
| `ShowChoice` | 選択肢表示。 |
| `IfElseBranch` | 条件分岐。 |
| `Branch` | 互換用に残された旧分岐値。 |
| `Jump` | ジャンプノード。 |
| `JumpBranch` | 分岐ラベルへジャンプ。 |
| `Signal` | カスタムシグナルノード。 |
| `AchievementUnlock` | 実績解除。 |
| `AchievementProgress` | 実績進捗更新。 |
| `AchievementFlag` | 実績フラグ設定。 |
| `SetVariable` | 変数設定または変更。 |
| `TheEnd` | 終了ノード。 |

## DialogueChoice

| プロパティ | 型 | 説明 |
| --- | --- | --- |
| `ChoiceText` | `string` | プレイヤーに表示する選択肢テキスト。 |
| `NextId` | `string` | 選択後の遷移先ノード ID。 |

## KndData

`KndData` は Konado データリソースの基底ラッパーです。通常は `KndShot`、`Dialogue`、`DialogueChoice` などの具体クラスを使います。

## KndShot

| プロパティ | 型 | 説明 |
| --- | --- | --- |
| `KsPath` | `string` | 元の `.ks` パス。 |
| `ShotId` | `string` | ショット ID。 |
| `StartNodeId` | `string` | 開始ノード ID。空の場合は通常最初のノードを使います。 |
| `Dialogues` | `Array<Dialogue>` | ショット内のすべての会話ノード。 |

| メソッド | 説明 |
| --- | --- |
| `Dialogue FindNode(string nodeId)` | `node_id` でノードを検索します。見つからない場合は `null`。 |
| `Dialogue GetStartNode()` | 開始ノードを取得します。 |

## KonadoScriptsInterpreter

| メンバー | 説明 |
| --- | --- |
| `KonadoScriptsInterpreter(Dictionary<string, Variant> flags = null)` | 新しいインタープリターを作成します。`flags` は互換用に残されています。 |
| `KonadoScriptsInterpreter(GodotObject source)` | 既存インタープリターをラップします。 |
| `KndShot ProcessScriptsToData(string path)` | `.ks` ファイルを `KND_Shot` に解析します。 |
| `Dialogue ParseSingleLine(string line, long lineNumber, string path)` | Konado スクリプトを 1 行解析します。 |

## 例

```csharp
var interpreter = new KonadoScriptsInterpreter();
var shot = interpreter.ProcessScriptsToData("res://sample/demo/demo_01.ks");

var api = KonadoAPI.DialogueManagerApi;
api.SetShot(shot.SourceResource);
api.InitDialogue();
api.StartDialogue();
```

## FAQ

### `IsApiReady` は true だが `DialogueManagerApi.IsReady` が false

`IsApiReady` は Konado.NET 自動読み込みノードの初期化状態だけを示します。現在シーンに `KND_DialogueManager` があるか確認するか、手動でバインドしてください。

```csharp
KonadoAPI.DialogueManagerApi.BindDialogueManager(GetNode<Node>("path/to/manager"));
```

### `SetShot` 後に再生されない

`SetShot()` はショットを切り替えるだけです。次の順序で呼び出してください。

```csharp
api.SetShot(shot.SourceResource);
api.InitDialogue();
api.StartDialogue();
```
