---
title: 使用 API
order: 2
---

# Konado .NET API

Konado.NET 是主插件的强类型 C# 适配层。启用 `Konado` 和 `Konado.NET` 后，通过 `KonadoApi` 自动加载入口访问运行时服务。

## 快速开始

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

`DialogueManagerApi.IsReady` 表示当前是否已绑定有效的 `KonadoDialogueManager`。多管理器场景可调用 `BindDialogueManager(node)` 明确指定目标。

## DialogueManagerApi

### 播放控制

| 成员 | 用途 |
| --- | --- |
| `BindDialogueManager(Node? source = null)` | 自动查找或绑定指定管理器。 |
| `SetShot(KonadoShot shot)` / `SetShot(Resource shot)` | 设置待播放镜头。 |
| `InitDialogue()` / `InitDialogue(Callable callback)` | 重置当前镜头的播放会话，可在初始化完成后调用回调。 |
| `StartDialogue()` / `StopDialogue()` | 开始或停止播放。 |
| `StartAutoplay(bool value)` | 开关自动播放。 |
| `EmitWaitSignal(string signalName)` | 继续等待指定信号的指令。 |
| `GetDialogueVariable(string key)` | 读取一个对话变量的当前值与作用域信息。 |
| `ReloadLocalizedScript(string locale)` | 按指定语言重新加载当前剧情。 |

资源属性包括 `CharacterList`、`BackgroundList`、`BgmList`、`VoiceList`、`SoundEffectList` 和 `VariableStore`。

### 事件

`ShotStart`、`ShotEnd`、`DialogueLineStart`、`DialogueLineEnd`、`CustomSignal`、`RuntimeFailed` 和 `RuntimeFailureReported` 均为标准 C# 事件。`DialogueLineStart` 与 `DialogueLineEnd` 提供稳定指令 ID；`RuntimeFailed` 保留简化的兼容接口，`RuntimeFailureReported` 提供错误代码、具体操作、资源、源码路径、行号、指令 ID 和程序位置。

### 存档与回滚

`SaveGame`、`LoadGame`、`DeleteSave`、`GetSaveInfo` 和 `GetAllSaveInfo` 管理存档。`CanRollback`、`Rollback`、`GetExecutionHistory`、`ClearExecutionHistory`、`CreateCheckpoint` 和 `RestoreCheckpoint` 管理 2.9 指令虚拟机的历史与检查点。

## StoryLocalizationApi

语言切换、UI 翻译和可用语言列表直接使用 Godot 的 `TranslationServer`。`KonadoApi.StoryLocalizationApi` 通过 `IsReady` 与 `Source` 暴露当前绑定状态，必要时可调用 `Bind(Node? source = null)` 重新绑定。它只提供 KonadoScript 专用的 `ResolveScriptPath` 与 `LoadLocalizedScript`；`warnOnFallback` 用于控制缺少对应剧情语言文件时是否报告回退。

## 编译与运行数据

- `KonadoScriptCompiler.CompileFile(path)` 编译完整 `.ks` 文件并返回 `KonadoShot`。
- `KonadoScriptCompiler.CompileLine(line, lineNumber, path = "")` 编译单条指令，主要用于工具集成；来源路径可省略。
- `KonadoShot` 提供 `SourcePath`、`ShotId`、`Program`、`DependentCharacters`、`InstructionCount`、`EntryPc` 和 `ProgramFingerprint`。
- `KonadoProgram` 提供 `IsValid`、`InstructionCount`、`EntryPc`、`Fingerprint`、`PcForKey()` 和 `InstructionAt()`。
- `KonadoInstruction` 提供 `Opcode`、`StableKey`、`SourceLine`、`NextPc`、`TruePc`、`FalsePc` 和 `GetValue()`。

`KonadoProgram` 与 `KonadoInstruction` 是只读运行视图。业务代码通常应通过 `DialogueManagerApi` 播放，不应修改编译结果。
