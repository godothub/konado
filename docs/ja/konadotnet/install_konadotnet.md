---
title: インストール
order: 1
---

# インストール

## 基本依存関係

1. Konado プラグインをインストールします（必須）
2. C# をサポートする Godot バージョン（Godot 4.6 以降を推奨）
3. プロジェクトを Godot .NET エディターで開いてください。通常版の Godot エディターでは C# アドオンスクリプトをコンパイルまたは読み込みできません。

## インストール手順

1. konadotnet プラグインを Godot プロジェクトの `addons` ディレクトリへ展開します
2. `addons/konado` のメインプラグインも存在することを確認します
3. Godot エディターで `Project -> Project Settings -> Plugins` を開き、先に `Konado` を有効化します
4. C# プロジェクトをビルドし、MSBuild エラーがないことを確認します
5. `Konadotnet` プラグインを有効化します
6. プロジェクトを開き直し、自動読み込みノードと C# スクリプト状態を更新します

## 初回有効化時のよくあるエラー

C# プロジェクトをまだビルドしていない場合、初回有効化時に次のエラーが出ることがあります。

```text
Unable to load addon script from path: 'res://addons/konadotnet/Konadotnet.cs'.
```

Godot .NET エディターでプロジェクトをビルドし、開き直してから再度有効化してください。

## シーン要件

`DialogueManagerAPI` を使うには、現在のシーンに `KND_DialogueManager` ノードが必要です。Konadotnet は次の一般的なノード名にも対応します。

- `DialogManager`
- `DialogueManager`
- `KonadoDialogueManager`

複数の会話マネージャーがある場合は手動でバインドしてください。
