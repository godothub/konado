---
title: 使用 API
order: 2
---

# Konado .NET API

> Konado .NET 仍屬實驗性功能。

## 簡介

Konado.NET 是 Konado 對話系統的 C# API 擴充。它不會取代 Konado 主插件，而是提供一層 C# 介面，用於尋找並控制 `KND_DialogueManager`、監聽對話流程訊號、解析 `.ks` 腳本，以及操作 Konado 的 GDScript 資料資源。

Konado.NET 會透過自動載入節點 `KonadoAPI` 提供入口。通常從 `KonadoAPI.DialogueManagerApi` 開始使用。

## 使用前提

Konado.NET 只能在支援 C# 的 Godot 專案中使用。請使用 Godot 4.6 或更高版本的 .NET 編輯器。若在非 .NET 專案中啟用，編輯器可能無法載入 `res://addons/konadotnet/Konadotnet.cs`，此時 Konado 主插件仍可使用，但 C# API 不可用。

請先啟用 `Konado`，再啟用 `Konadotnet`。場景中需要有 `KND_DialogueManager` 節點；Konado.NET 會依腳本類型尋找，也相容 `DialogManager`、`DialogueManager`、`KonadoDialogueManager` 等常見名稱。多管理器場景請使用 `BindDialogueManager(Node source)` 手動指定。

## 快速開始

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
            GD.Print($"節點開始: {nodeId}");
        };

        dialogueManager.CustomSignal += (string content) =>
        {
            GD.Print($"自訂訊號: {content}");
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

| 成員 | 類型 | 說明 |
| --- | --- | --- |
| `IsApiReady` | `bool` | `KonadoAPI` 自動載入節點是否初始化完成。不代表已找到 `KND_DialogueManager`。 |
| `API` | `static KonadoAPI` | 目前自動載入節點的靜態參照。 |
| `DialogueManagerApi` | `static DialogueManagerAPI` | 對話管理器 API 實例，也是主要入口。 |

## DialogueManagerAPI

`DialogueManagerAPI` 是 `KND_DialogueManager` 的 C# 控制層，會將呼叫轉發到 GDScript 節點。

### 屬性

| 屬性 | 類型 | 說明 |
| --- | --- | --- |
| `IsReady` | `bool` | 是否已綁定到可用的 `KND_DialogueManager`。 |
| `Source` | `Node` | 目前綁定的原始 Godot 節點。 |

### 方法

| 方法 | 說明 |
| --- | --- |
| `bool BindDialogueManager(Node source = null)` | 綁定指定對話管理器；省略時自動遍歷場景樹。成功回傳 `true`。 |
| `void InitDialogue()` | 呼叫 `init_dialogue()`，通常在 `SetShot()` 之後、`StartDialogue()` 之前呼叫。 |
| `void SetShot(Resource shot)` | 呼叫 `set_shot()` 切換目前 `KND_Shot`。傳入包裝物件時使用 `KndShot.SourceResource`。 |
| `void StartDialogue()` | 呼叫 `start_dialogue()` 開始播放。 |
| `void StopDialogue()` | 呼叫 `stop_dialogue()` 停止播放。 |
| `void StartAutoplay(bool value)` | 切換自動播放。 |
| `bool SaveGame(int saveId)` | 儲存進度。API 未就緒或儲存失敗時回傳 `false`。 |
| `bool LoadGame(int saveId)` | 讀取指定存檔。 |
| `bool DeleteSave(int saveId)` | 刪除指定存檔。 |
| `Dictionary GetSaveInfo(int saveId)` | 取得單一存檔資訊；API 未就緒時回傳空字典。 |
| `Array<Dictionary> GetAllSaveInfo()` | 取得全部存檔資訊；API 未就緒時回傳空陣列。 |

典型播放流程：

```csharp
var shot = interpreter.ProcessScriptsToData("res://dialogues/chapter_01.ks");
dialogueManager.SetShot(shot.SourceResource);
dialogueManager.InitDialogue();
dialogueManager.StartDialogue();
```

### 事件

| 事件 | 說明 |
| --- | --- |
| `ShotStart` | 綁定 `shot_start`，鏡頭開始時觸發。 |
| `ShotEnd` | 綁定 `shot_end`，鏡頭結束時觸發。 |
| `DialogueLineStart(string nodeId)` | 綁定 `dialogue_line_start(node_id)`。Konado 2.4 使用節點 ID，而不是舊版行號。 |
| `DialogueLineEnd(string nodeId)` | 綁定 `dialogue_line_end(node_id)`。 |
| `CustomSignal(string content)` | 綁定 `custom_signal(content)`，由 `.ks` 的 `signal` 語句觸發。 |

## ActingInterface

| 枚舉值 | 對應效果 |
| --- | --- |
| `NoneEffect` | 無效果 |
| `EraseEffect` | 擦除效果 |
| `BlindsEffect` | 百葉窗效果 |
| `WaveEffect` | 波浪效果 |
| `AlphaFadeEffect` | 透明度漸變效果 |
| `VortexSwapEffect` | 漩渦切換效果 |
| `WindmillEffect` | 風車效果 |
| `CyberGlitchEffect` | 賽博故障效果 |

## Wrapper 類別

Wrapper 類別是 Konado GDScript 資源的輕量 C# 封裝。包裝已有資源時會驗證腳本是否匹配；新建包裝物件時會建立底層 GDScript 資源。需要傳回 Konado API 時，請使用 `SourceResource`。

## Dialogue

`Dialogue` 包裝 `KND_Dialogue`：`res://addons/konado/scripts/dialogue/knd_dialogue.gd`。

| 成員 | 說明 |
| --- | --- |
| `Dialogue()` | 建立新的 `KND_Dialogue` 資源。 |
| `Dialogue(GodotObject source)` | 包裝已有 `KND_Dialogue`。來源無效時會拋出例外。 |
| `SourceResource` | 回傳底層 `Resource`。 |

| 屬性 | 類型 | 說明 |
| --- | --- | --- |
| `SourceFileLine` | `int` | 原始 `.ks` 行號，用於除錯與錯誤定位。 |
| `DialogueType` | `Dialogue.Type` | 節點類型，決定主插件如何處理此節點。 |
| `NodeId` | `string` | 對話圖節點 ID。 |
| `NextId` | `string` | 預設下一個節點 ID。 |
| `IfNextId` | `string` | 條件成立時的目標節點。 |
| `ElseNextId` | `string` | 條件不成立時的目標節點。 |
| `VarName` | `string` | 條件判斷使用的變數名。 |
| `ConditionOperator` | `int` | 條件操作符：`0 ==`、`1 >`、`2 <`、`3 >=`、`4 <=`。 |
| `TargetValue` | `int` | 條件比較目標值。 |
| `CharacterId` | `string` | 說話角色 ID。 |
| `DialogueContent` | `string` | 對話文字。 |
| `VoiceId` | `string` | 語音 ID。 |
| `CharacterName` | `string` | 要顯示或建立的角色 ID。 |
| `CharacterState` | `string` | 角色狀態或立繪狀態 ID。 |
| `ActorPosition` | `Vector2` | 角色位置。Konado 2.4 使用網格定位。 |
| `ExitActor` | `string` | 要退出或隱藏的角色 ID。 |
| `ChangeStateActor` | `string` | 要切換狀態的角色 ID。 |
| `ChangeState` | `string` | 目標狀態 ID。 |
| `TargetMoveChara` | `string` | 要移動的角色 ID。 |
| `TargetMovePos` | `Vector2` | 移動目標位置。 |
| `Choices` | `Array<DialogueChoice>` | 選項列表，每個選項透過 `NextId` 指向目標節點。 |
| `JumpShotPath` | `string` | 跳轉到其他 `KND_Shot` 的資源路徑。 |
| `JumpBranchTarget` | `string` | 目前鏡頭內的分支標籤目標。 |
| `BgmName` | `string` | 要播放的 BGM 名稱。 |
| `SoundeffectName` | `string` | 要播放的音效名稱。 |
| `BackgroundImageName` | `string` | 要切換的背景圖片名稱。 |
| `BackgroundToggleEffects` | `BackgroundTransitionEffectsType` | 背景切換效果。 |
| `CustomSignalName` | `string` | 透過 `CustomSignal` 事件送出的內容。 |
| `AchievementId` | `string` | 成就 ID。 |
| `AchievementValue` | `int` | 成就進度值。 |
| `AchievementFlagName` | `string` | 成就標籤名。 |
| `AchievementFlagValue` | `bool` | 成就標籤值。 |
| `VariableName` | `string` | 要操作的變數名。 |
| `VariableOperation` | `int` | 變數操作：`0 SET`、`1 ADD`、`2 SUB`、`3 MUL`、`4 DIV`。 |
| `VariableOperand` | `string` | 操作數，以文字儲存並由主插件在執行期解析。 |
| `IsPersistent` | `bool` | 是否為持久變數。通常 `%` 變數為持久，`$` 變數為臨時。 |

### Dialogue.Type

| 枚舉值 | 說明 |
| --- | --- |
| `OrdinaryDialog` | 普通對話。 |
| `DisplayActor` | 顯示或建立角色。 |
| `ActorChangeState` | 切換角色狀態。 |
| `MoveActor` | 移動角色。 |
| `SwitchBackground` | 切換背景。 |
| `ExitActor` | 角色退出。 |
| `PlayBgm` | 播放 BGM。 |
| `StopBgm` | 停止 BGM。 |
| `PlaySoundEffect` | 播放音效。 |
| `ShowChoice` | 顯示選項。 |
| `IfElseBranch` | 條件分支。 |
| `Branch` | 舊分支類型，保留作為相容枚舉。 |
| `Jump` | 跳轉節點。 |
| `JumpBranch` | 跳轉到分支標籤。 |
| `Signal` | 自訂訊號節點。 |
| `AchievementUnlock` | 解鎖成就。 |
| `AchievementProgress` | 更新成就進度。 |
| `AchievementFlag` | 設定成就標籤。 |
| `SetVariable` | 設定或修改變數。 |
| `TheEnd` | 結束節點。 |

## DialogueChoice

| 屬性 | 類型 | 說明 |
| --- | --- | --- |
| `ChoiceText` | `string` | 顯示給玩家的選項文字。 |
| `NextId` | `string` | 選擇後跳轉到的目標節點 ID。 |

## KndData

`KndData` 是 Konado 資料資源的基礎包裝類。多數情況會直接使用 `KndShot`、`Dialogue`、`DialogueChoice` 等具體類別。

## KndShot

| 屬性 | 類型 | 說明 |
| --- | --- | --- |
| `KsPath` | `string` | 來源 `.ks` 路徑。 |
| `ShotId` | `string` | 鏡頭 ID。 |
| `StartNodeId` | `string` | 起始節點 ID，為空時通常使用第一個節點。 |
| `Dialogues` | `Array<Dialogue>` | 此鏡頭包含的全部對話節點。 |

| 方法 | 說明 |
| --- | --- |
| `Dialogue FindNode(string nodeId)` | 依 `node_id` 查找節點，找不到時回傳 `null`。 |
| `Dialogue GetStartNode()` | 取得起始節點。 |

## KonadoScriptsInterpreter

| 成員 | 說明 |
| --- | --- |
| `KonadoScriptsInterpreter(Dictionary<string, Variant> flags = null)` | 建立新的解譯器。`flags` 目前保留作相容用途。 |
| `KonadoScriptsInterpreter(GodotObject source)` | 包裝已有解譯器物件。 |
| `KndShot ProcessScriptsToData(string path)` | 將 `.ks` 檔案解析為 `KND_Shot`。 |
| `Dialogue ParseSingleLine(string line, long lineNumber, string path)` | 解析單行 Konado 腳本。 |

## 範例

```csharp
var interpreter = new KonadoScriptsInterpreter();
var shot = interpreter.ProcessScriptsToData("res://sample/demo/demo_01.ks");

var api = KonadoAPI.DialogueManagerApi;
api.SetShot(shot.SourceResource);
api.InitDialogue();
api.StartDialogue();
```

## 常見問題

### `IsApiReady` 為 true，但 `DialogueManagerApi.IsReady` 為 false

`IsApiReady` 只代表 Konado.NET 自動載入節點已初始化。請確認目前場景有 `KND_DialogueManager`，或手動綁定：

```csharp
KonadoAPI.DialogueManagerApi.BindDialogueManager(GetNode<Node>("path/to/manager"));
```

### `SetShot` 後沒有播放

`SetShot()` 只會切換鏡頭，請依序呼叫：

```csharp
api.SetShot(shot.SourceResource);
api.InitDialogue();
api.StartDialogue();
```
