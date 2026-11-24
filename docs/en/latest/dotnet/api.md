---
title: API Usage
order: 2
---

# Konado .NET API

Konado.NET is the strongly typed C# adapter for the main plugin. After enabling both `Konado` and `Konado.NET`, use the `KonadoApi` autoload to access runtime services.

## Quick start

```csharp
using Konado.Runtime.Api;
using Konado.Runtime.Resources;

var dialogue = KonadoApi.DialogueManagerApi;
var compiler = new KonadoScriptCompiler();
var shot = compiler.CompileFile("res://story/intro.ks");

if (dialogue is not null && shot is not null)
{
    dialogue.SetShot(shot);
    dialogue.InitDialogue();
    dialogue.StartDialogue();
}
```

`DialogueManagerApi.IsReady` reports whether a valid `KonadoDialogueManager` is bound. In scenes with multiple managers, call `BindDialogueManager(node)` to select one explicitly.

## DialogueManagerApi

### Playback

| Member | Purpose |
| --- | --- |
| `BindDialogueManager(Node? source = null)` | Finds a manager or binds the supplied node. |
| `SetShot(KonadoShot shot)` / `SetShot(Resource shot)` | Selects the shot to play. |
| `InitDialogue()` / `InitDialogue(Callable callback)` | Resets the current playback session and optionally invokes a completion callback. |
| `StartDialogue()` / `StopDialogue()` | Starts or stops playback. |
| `StartAutoplay(bool value)` | Enables or disables autoplay. |
| `EmitWaitSignal(string signalName)` | Resumes an instruction waiting for that signal. |
| `GetDialogueVariable(string key)` | Reads the current value and scope information for a dialogue variable. |
| `ReloadLocalizedScript(string locale)` | Reloads the current story for the supplied locale. |

Resource properties are `CharacterList`, `BackgroundList`, `BgmList`, `VoiceList`, `SoundEffectList`, and `VariableStore`.

### Events

`ShotStart`, `ShotEnd`, `DialogueLineStart`, `DialogueLineEnd`, `CustomSignal`, `RuntimeFailed`, and `RuntimeFailureReported` are standard C# events. Line events provide a stable instruction ID. `RuntimeFailed` remains the compact compatibility event; `RuntimeFailureReported` includes the stable error code, operation, resource, source path and line, instruction ID, and program counter.

### Saves and rollback

Use `SaveGame`, `LoadGame`, `DeleteSave`, `GetSaveInfo`, and `GetAllSaveInfo` for saves. Use `CanRollback`, `Rollback`, `GetExecutionHistory`, `ClearExecutionHistory`, `CreateCheckpoint`, and `RestoreCheckpoint` for the 2.9 instruction VM history and checkpoints.

## StoryLocalizationApi

Use Godot's `TranslationServer` directly for locale selection, UI translation, and available locales. `KonadoApi.StoryLocalizationApi` exposes its binding through `IsReady` and `Source`; call `Bind(Node? source = null)` when an explicit rebind is needed. It only provides the KonadoScript-specific `ResolveScriptPath` and `LoadLocalizedScript` operations. `warnOnFallback` controls whether a missing story locale reports its fallback.

## Compilation and runtime data

- `KonadoScriptCompiler.CompileFile(path)` compiles a complete `.ks` file into a `KonadoShot`.
- `KonadoScriptCompiler.CompileLine(line, lineNumber, path = "")` compiles one instruction for tooling integrations; the source path is optional.
- `KonadoShot` exposes `SourcePath`, `ShotId`, `Program`, `DependentCharacters`, `InstructionCount`, `EntryPc`, and `ProgramFingerprint`.
- `KonadoProgram` exposes `IsValid`, `InstructionCount`, `EntryPc`, `Fingerprint`, `PcForKey()`, and `InstructionAt()`.
- `KonadoInstruction` exposes `Opcode`, `StableKey`, `SourceLine`, `NextPc`, `TruePc`, `FalsePc`, and `GetValue()`.

`KonadoProgram` and `KonadoInstruction` are read-only runtime views. Application code should normally play a shot through `DialogueManagerApi` instead of mutating compiled data.
