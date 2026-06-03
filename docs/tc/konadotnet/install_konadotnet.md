---
title: 安裝
order: 1
---

# 安裝

## 基礎依賴

1. 安裝 Konado 插件（必須）
2. 支援 C# 的 Godot 版本（推薦 4.6 或更高版本）
3. 專案需要使用 Godot .NET 編輯器開啟，普通 Godot 編輯器無法編譯與載入 C# 插件腳本。

## 安裝步驟

1. 將 konadotnet 插件解壓縮到 Godot 專案的 `addons` 目錄下
2. 確認 `addons/konado` 主插件也在專案中
3. 在 Godot 編輯器中，進入 `專案 -> 專案設定 -> 插件`，先啟用 `Konado`
4. 建構 C# 專案，確保 MSBuild 沒有錯誤
5. 再啟用 `Konadotnet` 插件
6. 重新開啟專案，讓自動載入節點與 C# 腳本狀態刷新

## 首次啟用時的常見錯誤

若專案尚未完成 C# 建構，首次啟用可能出現：

```text
Unable to load addon script from path: 'res://addons/konadotnet/Konadotnet.cs'.
```

請先使用 Godot .NET 編輯器建構專案，再重新開啟專案並啟用插件。

## 場景要求

使用 `DialogueManagerAPI` 時，目前場景需要包含 `KND_DialogueManager` 節點。Konadotnet 也相容常見節點名稱：

- `DialogManager`
- `DialogueManager`
- `KonadoDialogueManager`

若有多個對話管理器，請手動綁定。
