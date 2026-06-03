---
title: 安装
order: 1
---

# 安装

## 基础依赖

1. 安装 Konado 插件（必须）
2. 支持 C# 的 Godot 版本（推荐 4.6 或更高版本）
3. 项目需要使用 Godot .NET 编辑器打开，普通 Godot 编辑器无法编译和加载 C# 插件脚本。

## 安装步骤

1. 将 konadotnet 插件解压缩到 Godot 项目的 `addons` 目录下
2. 确认 `addons/konado` 主插件也在项目中
3. 在 Godot 编辑器中，进入 `项目 -> 项目设置 -> 插件`，先启用 `Konado`
4. 构建 C# 项目，确保 MSBuild 没有报错
5. 再启用 `Konadotnet` 插件
6. 重新打开项目，让自动加载节点和 C# 脚本状态刷新

## 首次启用时的常见报错

首次启用 Konadotnet 时，如果项目还没有完成 C# 构建，可能出现类似错误：

```text
Unable to load addon script from path: 'res://addons/konadotnet/Konadotnet.cs'.
```

这通常不是 Konado 主插件问题。请先在 Godot .NET 编辑器中构建项目，再重新打开项目并启用插件。

## 启用顺序

Konadotnet 依赖 Konado 主插件。推荐顺序是：

1. 启用 `Konado`
2. 构建 C# 项目
3. 启用 `Konadotnet`

如果先启用了 Konadotnet，插件会检查主插件状态；主插件未启用时，Konadotnet 不会继续注册 API 自动加载节点。

## 场景要求

使用 `DialogueManagerAPI` 时，当前场景需要包含 `KND_DialogueManager` 节点。Konadotnet 会自动查找该节点，也兼容常见节点名：

- `DialogManager`
- `DialogueManager`
- `KonadoDialogueManager`

如果场景中存在多个对话管理器，请在 C# 中手动绑定：

```csharp
var manager = GetNode<Node>("UI/KonadoDialogueManager");
Konado.Runtime.API.KonadoAPI.DialogueManagerApi.BindDialogueManager(manager);
```
