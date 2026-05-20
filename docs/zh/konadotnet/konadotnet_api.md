---
title: 使用API
order: 2
---

# Konado .NET API

> 该功能仍属于实验性功能，可能存在一些问题。


## 简介

Konado.NET 是 Konado 对话系统的 C# API 扩展，通过 Konado.NET，开发者可以在 C# 项目中轻松地创建、管理和执行对话内容。

## 使用方法

### 非.NET 项目

如果在非.NET 项目中使用 Konado .NET API，会遇到如下报错，这是正常现象：
```
 ERROR: core/io/resource_loader.cpp:568 - Condition "local_path.is_empty()" is true. Returning: Ref<ResourceLoader::LoadToken>()
  ERROR: Failed to create an autoload, can't load from UID or path: uid://ptylvcqylq7j.
  ERROR: editor/settings/editor_autoload_settings.cpp:571 - Condition "!info->node" is true. Continuing.

```

这个问题不会影响 Konado 基础功能的使用，但无法使用 Konado .NET API。

### 启用插件


请先启用Konado插件，然后再启用Konado .NET API插件。

场景中应包含 DialogueManager 节点，否则 Konado .NET API 将无法正常工作。

首次启用 Konado.NET，会遇到如下报错：

```
无法从路径 “res://addons/konadotnet/Konadotnet.cs” 加载附加组件脚本：该脚本可能有代码错误。
正在禁用位于 “res://addons/konadotnet/plugin.cfg” 的附加组件以阻止其进一步报错。
```

```
Unable to load addon script from path: 'res://addons/konadotnet/Konadotnet.cs'.
```

这是正常现象，请重新在Godot编译 Konado.NET，然后重新打开项目即可解决。

如果无法启用插件，并且在MSBuild中没有任何报错，可以尝试关闭项目后，删除项目根目录的 .godot/ 文件夹，然后重新生成项目。


## API 参考

### KonadoAPI

核心 API 类，提供对 Konado 系统的访问。

#### 属性

- `bool IsApiReady`: 指示 API 是否已准备就绪
- `KonadoAPI API`: 静态实例，提供对 Konado API 的访问
- `DialogueManagerAPI DialogueManagerApi`: 对话管理器 API 实例

### DialogueManagerAPI

对话管理器 API，用于控制对话的执行。

#### 方法

- `InitDialogue()`: 初始化对话
- `StartDialogue()`: 开始对话
- `StopDialogue()`: 停止对话

#### 事件

- `ShotStart`: 对话场景开始时触发
- `ShotEnd`: 对话场景结束时触发
- `DialogueLineStart(int line)`: 对话行开始时触发
- `DialogueLineEnd(int line)`: 对话行结束时触发

### ActingInterface

表演接口，定义背景过渡效果类型。

#### 枚举

- `BackgroundTransitionEffectsType`: 背景过渡效果类型
  - `NoneEffect`: 无效果
  - `EraseEffect`: 擦除效果
  - `BlindsEffect`: 百叶窗效果
  - `WaveEffect`: 波浪效果
  - `AlphaFadeEffect`: 透明度渐变效果
  - `VortexSwapEffect`: 涡流切换效果
  - `WindmillEffect`: 风车效果
  - `CyberGlitchEffect`: 赛博故障效果

### Wrapper 类

Wrapper 类提供了对 GDScript 对象的 C# 封装，使开发者可以在 C# 中操作 Konado 的各种数据结构，不过目前这些类并未完全实现，仅提供了部分属性和方法，有待进一步完善。

#### Dialogue

对话对象包装器，表示单个对话元素。

##### 属性

- `Type DialogueType`: 对话类型（枚举）
- `string BranchId`: 分支 ID
- `Array<Dialogue> BranchDialogue`: 分支对话
- `bool IsBranchLoaded`: 分支是否已加载
- `string CharacterId`: 角色ID
- `string DialogueContent`: 对话内容
- `DialogueActor ShowActor`: 显示的角色
- `string ExitActor`: 退出的角色
- `string ChangeStateActor`: 状态变更的角色
- `string TargetMoveChara`: 移动目标角色
- `Vector2 TargetMovePos`: 移动目标位置
- `Array<DialogueChoice> Choices`: 对话选项
- `string BgmName`: 背景音乐名称
- `string VoiceId`: 语音 ID
- `string SoundeffectName`: 音效名称
- `string BackgroundImageName`: 背景图像名称
- `BackgroundTransitionEffectsType BackgroundToggleEffects`: 背景切换效果
- `string JumpShotId`: 跳转场景 ID
- `string LabelNotes`: 标签注释
- `Dictionary ActorSnapshots`: 角色快照

##### 对话类型枚举

- `Start`: 开始
- `OrdinaryDialog`: 普通对话
- `DisplayActor`: 显示角色
- `ActorChangeState`: 角色状态变更
- `MoveActor`: 移动角色
- `SwitchBackground`: 切换背景
- `ExitActor`: 角色退出
- `PlayBgm`: 播放背景音乐
- `StopBgm`: 停止背景音乐
- `PlaySoundEffect`: 播放音效
- `ShowChoice`: 显示选项
- `Branch`: 分支
- `JumpTag`: 跳转标签
- `JumpShot`: 跳转场景
- `TheEnd`: 结束
- `Label`: 标签

#### DialogueActor

对话角色包装器，表示对话中的角色对象。

##### 属性

- `string CharacterName`: 角色名称
- `string CharacterState`: 角色状态
- `Vector2 ActorPosition`: 角色位置
- `Vector2 ActorScale`: 角色缩放
- `bool ActorMirror`: 角色镜像

#### DialogueChoice

对话选项包装器，表示对话中的选项对象。

##### 属性

- `string ChoiceText`: 选项文本
- `string JumpTag`: 跳转标签

#### KndData

Konado KND_Data 数据基类包装器。

##### 属性

- `string Type`: 数据类型
- `bool Love`: 是否为喜爱内容
- `string Tip`: 提示信息

#### KndShot

Konado KND_Shot 镜头包装器，继承自 KndData。

##### 属性

- `string Name`: 场景名称
- `string ShotId`: 场景 ID
- `string SourceStory`: 源故事
- `Array<Dictionary> DialoguesSourceData`: 对话源数据
- `Dictionary Branches`: 分支
- `Dictionary<string, Dictionary> SourceBranches`: 源分支
- `Dictionary<string, int> ActorCharacterMap`: 角色映射

#### KonadoScriptsInterpreter

KonadoScriptsInterpreter 脚本解释器包装器，用于解析 Konado 脚本文件。

##### 方法

- `KndShot ProcessScriptsToData(string path)`: 处理脚本文件为数据
- `Dialogue ParseSingleLine(string line, long lineNumber, string path)`: 解析单行脚本

## 示例代码

### 对话管理

```csharp
using Konado.Runtime.API;

// 获取 Konado API 实例
var konadoAPI = KonadoAPI.API;
var dialogueManager = KonadoAPI.DialogueManagerApi;

// 检查 API 是否就绪
if (dialogueManager.IsReady)
{
    // 初始化对话
    dialogueManager.InitDialogue();

    // 开始对话
    dialogueManager.StartDialogue();

    // 停止对话
    dialogueManager.StopDialogue();
}
```

### 对话事件监听

```csharp
// 监听对话开始事件
dialogueManager.ShotStart += () => {
    GD.Print("对话场景开始");
};

// 监听对话结束事件
dialogueManager.ShotEnd += () => {
    GD.Print("对话场景结束");
};

// 监听对话行开始事件
dialogueManager.DialogueLineStart += (int line) => {
    GD.Print($"对话行 {line} 开始");
};

// 监听对话行结束事件
dialogueManager.DialogueLineEnd += (int line) => {
    GD.Print($"对话行 {line} 结束");
};
```

### 解析 Konado 脚本

```csharp
using Konado.Wrapper;

// 创建脚本解释器
var flags = new Godot.Collections.Dictionary<string, Variant>();
var interpreter = new KonadoScriptsInterpreter(flags);

// 解析整个脚本文件
var shot = interpreter.ProcessScriptsToData("res://dialogues/example.ks");
```