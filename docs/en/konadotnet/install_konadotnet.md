---
title: Installation
order: 1
---

# Installation

## Basic Dependencies

1. Install the Konado plugin (required)
2. A Godot version that supports C# (Godot 4.6 or later recommended)
3. Open the project with the Godot .NET editor. The regular Godot editor cannot compile or load C# addon scripts.

## Installation Steps

1. Extract the konadotnet plugin into the `addons` directory of your Godot project
2. Make sure the main `addons/konado` plugin is also present
3. In the Godot editor, open `Project -> Project Settings -> Plugins` and enable `Konado` first
4. Build the C# project and make sure MSBuild reports no errors
5. Enable the `Konadotnet` plugin
6. Reopen the project so autoloads and C# scripts are refreshed

## First Enable Errors

When enabling Konadotnet for the first time before the C# project has been built, you may see:

```text
Unable to load addon script from path: 'res://addons/konadotnet/Konadotnet.cs'.
```

This is usually not a main Konado plugin issue. Build the project with the Godot .NET editor, reopen the project, then enable the plugin again.

## Enable Order

Konadotnet depends on the main Konado plugin. Recommended order:

1. Enable `Konado`
2. Build the C# project
3. Enable `Konadotnet`

If Konadotnet is enabled first, it checks the main plugin status and will not register the API autoload when the main plugin is disabled.

## Scene Requirement

`DialogueManagerAPI` requires a `KND_DialogueManager` node in the current scene. Konadotnet searches automatically and supports common node names:

- `DialogManager`
- `DialogueManager`
- `KonadoDialogueManager`

If a scene contains multiple dialogue managers, bind one manually:

```csharp
var manager = GetNode<Node>("UI/KonadoDialogueManager");
Konado.Runtime.API.KonadoAPI.DialogueManagerApi.BindDialogueManager(manager);
```
