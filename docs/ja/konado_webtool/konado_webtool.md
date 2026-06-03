---
title: 紹介
order: 1
---

# Konado WebTool

## はじめに

Konado WebTool は、Konado プロジェクトに Web プラットフォーム向け開発ツールサポートを提供するプラグインです。Godot 4.x は Web プラットフォーム上でデフォルトですべてのキーボードショートカットを捕捉して無効化するため、F12 や F5 などのブラウザ開発者ツールのショートカットが正常に使えません。このプラグインはその問題を解決し、Web プラットフォーム上で一般的なブラウザ開発者ツールのショートカットを使えるようにして、Web 環境でのデバッグと開発を容易にします。

## 動作原理

Konado WebTool は Web プラットフォーム上で JavaScript コードを注入し、ショートカットを通過させます。処理内容は次のとおりです。

1. 現在のプラットフォームが Web かどうかを検出します
2. Web プラットフォームで開発者ツールサポートが有効な場合、ショートカット処理コードを注入します
3. 設定に基づいて許可するショートカット一覧を動的に構築します
4. キーボードイベントを監視し、許可されたショートカットのデフォルト動作を阻止してブラウザへ通します

### 他の解決策との比較

| 解決策 | 利点 | 欠点 |
|----------|------|------|
| Konado WebTool | 簡単に使える、設定しやすい、保守しやすい | 明確な欠点なし |
| エクスポートテンプレートを手動修正 | 完全に制御できる | 技術要件が高く、頻繁な更新が必要 |
| 開発環境を切り替える | デスクトッププラットフォームでデバッグ可能 | Web プラットフォーム固有の問題を捕捉できない |

## 対応するブラウザショートカット

これらのショートカット仕様は、Chrome、Firefox、Edge など主要ブラウザの開発者ツール標準ショートカットに基づき、各ブラウザの公式ドキュメントを参照しています。

- [Firefox DevTools](https://developer.mozilla.org/en-US/docs/Tools/Keyboard_shortcuts)
- [Edge DevTools](https://learn.microsoft.com/en-us/microsoft-edge/devtools-guide-chromium/shortcuts/)
- [Chrome DevTools](https://developer.chrome.com/docs/devtools/shortcuts/)
- [Safari DevTools（WebKit）](https://webkit.org/web-inspector/keyboard-shortcuts/)

| ショートカット | 機能 | 有効化オプション |
|--------|------|----------|
| F12 | 開発者ツールを開く | `enable_f12` |
| F5 | ページを再読み込み | `enable_f5` |
| F11 | フルスクリーン切り替え | `enable_f11` |
| Ctrl+Shift+I (Win/Linux) / Cmd+Opt+I (Mac) | Elements パネルを開く | `enable_ctrl_shift_i` |
| Ctrl+Shift+J (Win/Linux) / Cmd+Opt+J (Mac) | Console を開く | `enable_ctrl_shift_j` |
| Ctrl+Shift+C (Win/Linux) / Cmd+Shift+C (Mac) | 要素検査モード | `enable_ctrl_shift_c` |
| Ctrl+U (Win/Linux) / Cmd+U (Mac) | ページソースを表示 | `enable_ctrl_u` |
| Ctrl+R (Win/Linux) / Cmd+R (Mac) | ページを再読み込み | `enable_ctrl_r` |

## 設定オプション

自動読み込みされる `KND_WebTool` ノードで、以下のプロパティを設定できます。

| プロパティ | 型 | デフォルト | 説明 |
|------|------|--------|------|
| `enable_web_devtool` | bool | true | Web 開発者ツールショートカットの通過を有効にするか |
| `enable_f12` | bool | true | F12 ショートカットを有効にするか |
| `enable_f5` | bool | true | F5 ショートカットを有効にするか |
| `enable_f11` | bool | true | F11 ショートカットを有効にするか |
| `enable_ctrl_shift_i` | bool | true | Ctrl+Shift+I ショートカットを有効にするか |
| `enable_ctrl_shift_j` | bool | true | Ctrl+Shift+J ショートカットを有効にするか |
| `enable_ctrl_shift_c` | bool | true | Ctrl+Shift+C ショートカットを有効にするか |
| `enable_ctrl_u` | bool | true | Ctrl+U ショートカットを有効にするか |
| `enable_ctrl_r` | bool | true | Ctrl+R ショートカットを有効にするか |
