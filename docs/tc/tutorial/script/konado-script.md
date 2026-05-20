---
title: Konado 腳本
order: 1
---

# Konado Scripts

Konado Scripts 是一種為視覺小說量身定制的創作語言（檔案副檔名為 .ks）。

你可以把它想像成一種更強大、更結構化的「小說劇本」：開發者無需編寫複雜程式碼，就能控制劇情對話、角色立繪、背景切換、音樂音效，以及故事分支和選項。

## 設計理念

Konado Script 的核心設計理念是將**故事內容**與**程式邏輯**分離：
- 編劇專注於敘事內容，無需程式設計知識
- 程式設計師專注於引擎開發，無需介入故事創作
- 資源管理（圖片、音訊）透過識別碼引用，與腳本解耦
- 模組化指令集，易於擴充新功能
- 相容版本控制系統（Git 等）
- 文字格式天生跨平台
- 資源引用與平台無關



## 常見問題

### 1. 解析失敗後存檔無法觸發重新解析

主控台會提示錯誤訊息，但存檔後不會自動重新解析，這是由於未成功觸發重新匯入導致的。

```text
第5行內容：a1ctor show 可娜 正常 at 2 5 scale 0.3
  ERROR: core/variant/variant_utility.cpp:1024 - 錯誤：res://sample/demo/demo_01.ks [行：5] 解析失敗：無法辨識的語法，終止解析: a1ctor show 可娜 正常 at 2 5 scale 0.3 
  ERROR: Failed to process scripts
  ERROR: Error importing 'res://sample/demo/demo_01.ks'.
  ERROR: Failed loading resource: res://sample/demo/demo_01.ks.

```

找到對應的腳本檔案，右鍵選擇重新匯入即可。

![重新匯入腳本](reimport.png)

### 2. 腳本檔案編碼問題

確保腳本檔案編碼為 UTF-8，否則可能出現亂碼。預設情況下建立的腳本檔案編碼為 UTF-8。
