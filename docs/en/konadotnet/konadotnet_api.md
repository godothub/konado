---
title: API Usage
order: 2
---

# Konado .NET API

> Konado .NET is still experimental. 

## Introduction

Konado.NET is the C# API extension for the Konado dialogue system. It does not replace the main Konado plugin; it provides a C# layer for:

- Finding and controlling `KND_DialogueManager`
- Listening to Konado dialogue flow signals
- Parsing `.ks` scripts from C#
- Reading and creating wrappers for Konado GDScript resources
- Calling Konado 2.4 autoplay and save APIs

Konado.NET exposes the `KonadoAPI` autoload. Most C# code starts from `KonadoAPI.DialogueManagerApi`.

## Requirements

### Project Type

Konado.NET only works in Godot projects with C# support. Use the .NET build of Godot 4.6 or later.

If the plugin is enabled in a non-.NET project, the editor may fail to load:

```text
res://addons/konadotnet/Konadotnet.cs
```

This does not affect the main Konado plugin, but the C# API cannot be used until the project is opened and built with Godot .NET.

### Plugin Order

Enable the `Konado` plugin first, then enable `Konadotnet`. Konadotnet checks that `res://addons/konado/plugin.cfg` exists and that the main plugin is enabled.

### Dialogue Manager Node

The current scene must contain a `KND_DialogueManager` node. Konado.NET searches by script type first:

```text
res://addons/konado/scripts/dialogue/knd_dialogue_manager.gd
```

It also supports common node names for compatibility:

- `DialogManager`
- `DialogueManager`
- `KonadoDialogueManager`

If a scene contains multiple dialogue managers, bind one explicitly with `BindDialogueManager(Node source)`.

## Quick Start

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

## API Entry Point

### KonadoAPI

`KonadoAPI` is the autoload node created by the Konadotnet plugin.

| Member | Type | Description |
| --- | --- | --- |
| `IsApiReady` | `bool` | Whether the `KonadoAPI` autoload has initialized. This does not guarantee that a `KND_DialogueManager` was found; use `DialogueManagerApi.IsReady` for that. |
| `API` | `static KonadoAPI` | Static reference to the current autoload instance. Usually not created manually. |
| `DialogueManagerApi` | `static DialogueManagerAPI` | Dialogue manager API instance and the main entry point for runtime control. |

```csharp
if (KonadoAPI.API.IsApiReady && KonadoAPI.DialogueManagerApi.IsReady)
{
    KonadoAPI.DialogueManagerApi.StartDialogue();
}
```

## DialogueManagerAPI

`DialogueManagerAPI` is the C# control layer for `KND_DialogueManager`. It forwards calls to the underlying GDScript node.

### Properties

| Property | Type | Description |
| --- | --- | --- |
| `IsReady` | `bool` | Whether the API is bound to a usable `KND_DialogueManager`. |
| `Source` | `Node` | The bound source Godot node. Use this only when direct GDScript access is needed. |

### Methods

| Method | Description |
| --- | --- |
| `bool BindDialogueManager(Node source = null)` | Bind a specific dialogue manager, or traverse the scene tree when omitted. Returns `true` on success. |
| `void InitDialogue()` | Calls `init_dialogue()`. Usually called after `SetShot()` and before `StartDialogue()`. |
| `void SetShot(Resource shot)` | Calls `set_shot()` with a `KND_Shot` resource. Use `KndShot.SourceResource` when passing a wrapper. |
| `void StartDialogue()` | Calls `start_dialogue()` and starts playback. |
| `void StopDialogue()` | Calls `stop_dialogue()` and stops playback. |
| `void StartAutoplay(bool value)` | Toggles autoplay. |
| `bool SaveGame(int saveId)` | Saves progress to a save slot. Returns `false` if the API is not ready or saving fails. |
| `bool LoadGame(int saveId)` | Loads a save slot. |
| `bool DeleteSave(int saveId)` | Deletes a save slot. |
| `Dictionary GetSaveInfo(int saveId)` | Gets one save record. Returns an empty dictionary when the API is not ready. |
| `Array<Dictionary> GetAllSaveInfo()` | Gets all save records. Returns an empty array when the API is not ready. |

Manual binding example:

```csharp
var manager = GetNode<Node>("UI/KonadoDialogueManager");
KonadoAPI.DialogueManagerApi.BindDialogueManager(manager);
```

Typical playback order:

```csharp
var shot = interpreter.ProcessScriptsToData("res://dialogues/chapter_01.ks");
dialogueManager.SetShot(shot.SourceResource);
dialogueManager.InitDialogue();
dialogueManager.StartDialogue();
```

### Events

| Event | Description |
| --- | --- |
| `ShotStart` | Bound to `shot_start`. Fired when a shot starts. |
| `ShotEnd` | Bound to `shot_end`. Fired when a shot ends. |
| `DialogueLineStart(string nodeId)` | Bound to `dialogue_line_start(node_id)`. Konado 2.4 uses node IDs rather than old line numbers. |
| `DialogueLineEnd(string nodeId)` | Bound to `dialogue_line_end(node_id)`. |
| `CustomSignal(string content)` | Bound to `custom_signal(content)`. Fired by `.ks` lines such as `signal something`. |

```csharp
dialogueManager.CustomSignal += (string content) =>
{
    if (content == "affection_up")
    {
        GD.Print("Handle affection update");
    }
};
```

## ActingInterface

`ActingInterface` currently exposes the background transition enum used by the main plugin.

| Enum Value | Effect |
| --- | --- |
| `NoneEffect` | No transition |
| `EraseEffect` | Erase transition |
| `BlindsEffect` | Blinds transition |
| `WaveEffect` | Wave transition |
| `AlphaFadeEffect` | Alpha fade transition |
| `VortexSwapEffect` | Vortex swap transition |
| `WindmillEffect` | Windmill transition |
| `CyberGlitchEffect` | Cyber glitch transition |

## Wrapper Classes

Wrapper classes are lightweight C# wrappers around Konado GDScript resources.

General rules:

- Constructors for existing resources validate that the resource script matches.
- Empty constructors create the underlying GDScript resource.
- Use `SourceResource` when passing a wrapper back to Konado APIs.
- Wrappers do not clone data; property reads and writes act on the underlying GDScript object.

## Dialogue

`Dialogue` wraps `KND_Dialogue`:

```text
res://addons/konado/scripts/dialogue/knd_dialogue.gd
```

### Constructors

| Member | Description |
| --- | --- |
| `Dialogue()` | Creates a new `KND_Dialogue` resource. |
| `Dialogue(GodotObject source)` | Wraps an existing `KND_Dialogue` resource. Throws if the source is invalid. |
| `SourceResource` | Returns the underlying `Resource`. |

### Properties

| Property | Type | Description |
| --- | --- | --- |
| `SourceFileLine` | `int` | Source `.ks` line number for debugging and errors. |
| `DialogueType` | `Dialogue.Type` | Node type used by the main plugin playback logic. |
| `NodeId` | `string` | Dialogue graph node ID. |
| `NextId` | `string` | Default next node ID. |
| `IfNextId` | `string` | Node ID used when a condition is true. |
| `ElseNextId` | `string` | Node ID used when a condition is false. |
| `VarName` | `string` | Variable name used by conditional nodes. |
| `ConditionOperator` | `int` | Condition operator: `0 ==`, `1 >`, `2 <`, `3 >=`, `4 <=`. |
| `TargetValue` | `int` | Target value for conditional comparison. |
| `CharacterId` | `string` | Speaker character ID. |
| `DialogueContent` | `string` | Dialogue text. |
| `VoiceId` | `string` | Voice ID for the dialogue line. |
| `CharacterName` | `string` | Character ID to display or create. |
| `CharacterState` | `string` | Character state or portrait state ID. |
| `ActorPosition` | `Vector2` | Actor display position. Konado 2.4 uses grid-style positioning. |
| `ExitActor` | `string` | Actor ID to hide or remove. |
| `ChangeStateActor` | `string` | Actor ID whose state should change. |
| `ChangeState` | `string` | Target state ID. |
| `TargetMoveChara` | `string` | Actor ID to move. |
| `TargetMovePos` | `Vector2` | Target movement position. |
| `Choices` | `Array<DialogueChoice>` | Choice list. Each choice points to a target node through `NextId`. |
| `JumpShotPath` | `string` | Resource path for jumping to another `KND_Shot`. |
| `JumpBranchTarget` | `string` | Branch label target in the current shot. |
| `BgmName` | `string` | BGM name to play. |
| `SoundeffectName` | `string` | Sound effect name to play. |
| `BackgroundImageName` | `string` | Background image name to switch to. |
| `BackgroundToggleEffects` | `BackgroundTransitionEffectsType` | Background transition effect. |
| `CustomSignalName` | `string` | Payload emitted through `CustomSignal`. |
| `AchievementId` | `string` | Achievement ID. |
| `AchievementValue` | `int` | Achievement progress value. |
| `AchievementFlagName` | `string` | Achievement flag name. |
| `AchievementFlagValue` | `bool` | Achievement flag value. |
| `VariableName` | `string` | Variable name to modify. |
| `VariableOperation` | `int` | Variable operation: `0 SET`, `1 ADD`, `2 SUB`, `3 MUL`, `4 DIV`. |
| `VariableOperand` | `string` | Operand stored as text and parsed by the main plugin at runtime. |
| `IsPersistent` | `bool` | Whether the variable is persistent. `%` variables are usually persistent; `$` variables are temporary. |

### Dialogue.Type

| Value | Description |
| --- | --- |
| `OrdinaryDialog` | Regular dialogue text. |
| `DisplayActor` | Display or create an actor. |
| `ActorChangeState` | Change actor state. |
| `MoveActor` | Move an actor. |
| `SwitchBackground` | Switch background. |
| `ExitActor` | Hide or remove an actor. |
| `PlayBgm` | Play BGM. |
| `StopBgm` | Stop BGM. |
| `PlaySoundEffect` | Play sound effect. |
| `ShowChoice` | Show choices. |
| `IfElseBranch` | Conditional branch. |
| `Branch` | Deprecated compatibility enum value. |
| `Jump` | Jump node. |
| `JumpBranch` | Jump to branch label. |
| `Signal` | Custom signal node. |
| `AchievementUnlock` | Unlock achievement. |
| `AchievementProgress` | Update achievement progress. |
| `AchievementFlag` | Set achievement flag. |
| `SetVariable` | Set or modify variable. |
| `TheEnd` | End node. |

## DialogueChoice

`DialogueChoice` wraps `KND_DialogueChoice`:

```text
res://addons/konado/scripts/dialogue/knd_dialogue_choice.gd
```

| Member | Description |
| --- | --- |
| `DialogueChoice()` | Creates a new choice resource. |
| `DialogueChoice(GodotObject source)` | Wraps an existing choice resource. |
| `SourceResource` | Underlying `Resource`. |

| Property | Type | Description |
| --- | --- | --- |
| `ChoiceText` | `string` | Text displayed to the player. |
| `NextId` | `string` | Target node ID selected by this choice. |

```csharp
var choice = new DialogueChoice
{
    ChoiceText = "Continue",
    NextId = "node_004"
};
```

## KndData

`KndData` is the base wrapper for Konado data resources. Most code uses concrete wrappers such as `KndShot`, `Dialogue`, or `DialogueChoice`.

| Member | Description |
| --- | --- |
| `KndData()` | Creates a new `KND_Data` resource. |
| `KndData(GodotObject source)` | Wraps an existing resource. |
| `SourceResource` | Returns the underlying `Resource`. |

## KndShot

`KndShot` wraps `KND_Shot`:

```text
res://addons/konado/scripts/dialogue/knd_shot.gd
```

| Property | Type | Description |
| --- | --- | --- |
| `KsPath` | `string` | Source `.ks` path. Written by the interpreter. |
| `ShotId` | `string` | Shot ID. |
| `StartNodeId` | `string` | Start node ID. When empty, the first dialogue node is usually used. |
| `Dialogues` | `Array<Dialogue>` | All dialogue nodes in the shot graph. |

| Method | Description |
| --- | --- |
| `Dialogue FindNode(string nodeId)` | Finds a dialogue node by `node_id`. Returns `null` when not found. |
| `Dialogue GetStartNode()` | Gets the start node using `StartNodeId`, or the first dialogue node when empty. |

## KonadoScriptsInterpreter

`KonadoScriptsInterpreter` wraps:

```text
res://addons/konado/ks/ks_interpreter.gd
```

| Member | Description |
| --- | --- |
| `KonadoScriptsInterpreter(Dictionary<string, Variant> flags = null)` | Creates a new interpreter. Konado 2.4 currently does not require extra flags; the parameter remains for compatibility. |
| `KonadoScriptsInterpreter(GodotObject source)` | Wraps an existing interpreter object. |
| `KndShot ProcessScriptsToData(string path)` | Parses a `.ks` file into a `KND_Shot`. |
| `Dialogue ParseSingleLine(string line, long lineNumber, string path)` | Parses one Konado script line, mainly for tools and debugging. |

## Complete Examples

### Bind and Listen

```csharp
using Godot;
using Konado.Runtime.API;

public partial class DialogueEvents : Node
{
    public override void _Ready()
    {
        var api = KonadoAPI.DialogueManagerApi;

        if (!api.IsReady)
        {
            api.BindDialogueManager();
        }

        api.ShotStart += () => GD.Print("Shot started");
        api.ShotEnd += () => GD.Print("Shot ended");
        api.DialogueLineStart += (string nodeId) => GD.Print($"Node started: {nodeId}");
        api.DialogueLineEnd += (string nodeId) => GD.Print($"Node ended: {nodeId}");
        api.CustomSignal += (string content) => GD.Print($"Custom signal: {content}");
    }
}
```

### Parse and Play a Script

```csharp
using Godot;
using Konado.Runtime.API;
using Konado.Wrapper;

public partial class PlayKsFile : Node
{
    public override void _Ready()
    {
        var interpreter = new KonadoScriptsInterpreter();
        var shot = interpreter.ProcessScriptsToData("res://sample/demo/demo_01.ks");

        var api = KonadoAPI.DialogueManagerApi;
        api.SetShot(shot.SourceResource);
        api.InitDialogue();
        api.StartDialogue();
    }
}
```

### Save Info

```csharp
using Godot;
using Konado.Runtime.API;

public partial class SaveInfoExample : Node
{
    public override void _Ready()
    {
        var api = KonadoAPI.DialogueManagerApi;

        if (api.SaveGame(1))
        {
            var info = api.GetSaveInfo(1);
            GD.Print(info);
        }

        var allSaves = api.GetAllSaveInfo();
        GD.Print($"Save count: {allSaves.Count}");
    }
}
```

## FAQ

### `IsApiReady` is true, but `DialogueManagerApi.IsReady` is false

`IsApiReady` only means the Konado.NET autoload initialized. `DialogueManagerApi.IsReady` means a `KND_DialogueManager` was found. Confirm that the current scene contains a dialogue manager, or bind one manually:

```csharp
KonadoAPI.DialogueManagerApi.BindDialogueManager(GetNode<Node>("path/to/manager"));
```

### Events do not fire

Check that dialogue playback has started and that the bound `KND_DialogueManager` is the node you expect. In multi-manager scenes, automatic search binds the first matching node.

### `SetShot` does not start playback

`SetShot()` only changes the current shot. Use this order:

```csharp
api.SetShot(shot.SourceResource);
api.InitDialogue();
api.StartDialogue();
```
