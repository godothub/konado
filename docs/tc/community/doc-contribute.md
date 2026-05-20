---
title: 文件貢獻
order: 4
---

# 文件貢獻指南

## 線上編輯

線上編輯文件，點擊線上文件左下角的 `線上編輯此頁`，瀏覽器會跳轉到儲存庫檔案所在目錄位置，此時點擊右上角 `編輯` 按鈕，修改後預覽查看效果，確認無誤後點擊 `提交修改` 提交。

提交後會經過審查，通過後合併到主儲存庫。一般主儲存庫合併後，線上文件會自動更新，如果沒有更新，請手動重新整理頁面，或者提交後等待幾分鐘再重新整理。

## 本地編輯

文件可以直接向 `master` 分支`提交 PR`，不必建立特性分支。

在提交程式碼之前請確保在本地完成了 Git 的全域設定
```
git config --global user.name 你的 Git 使用者名稱
git config --global user.email 你的提交信箱，必須與程式碼平台帳戶信箱一致
```

1. **Fork 專案**：點擊右上角 Fork 到自己的儲存庫  
2. **複製儲存庫**：`git clone`  
3. **編輯文件**：在 `docs` 目錄下找到需要修改的檔案，使用 Markdown 語法進行編輯（參考 [Markdown 語法](https://www.markdownguide.org/basic-syntax)）
4. **提交更改**：`git commit -m "描述你的文件更改"`  
5. **推送到分支**：`git push origin master`

提交後，在自己 Fork 的儲存庫頁面、點擊 `Pull Request` 按鈕，建立 PR。

## 本地預覽 Konado 文件
Konado 文件基於 [VitePress](https://vitepress.dev/) 建構，為確保文件修改內容符合預期，建議先在本地預覽驗證後再提交程式碼。

### 前置準備：安裝 Node.js
VitePress 依賴 Node.js 環境執行，需先安裝符合版本要求的 Node.js：
1. **版本要求**：推薦安裝 Node.js 18.x 及以上版本（LTS 長期支援版最佳，相容性更優）。
2. **下載安裝**：
   - 訪問 Node.js 官方下載地址：[https://nodejs.org/](https://nodejs.org/)
   - 根據作業系統（Windows/macOS/Linux）選擇對應安裝套件，按精靈完成安裝（Windows 建議勾選「Add to PATH」選項）。
3. **驗證安裝**：
   打開終端機（Windows 為命令提示字元/PowerShell，macOS/Linux 為終端機），執行以下指令驗證 Node.js 和 npm（Node.js 內建套件管理員）是否安裝成功：
   ```shell
   # 查看 Node.js 版本
   node -v
   # 查看 npm 版本
   npm -v
   ```
   若輸出清晰的版本號（如 `v20.10.0`、`10.2.3`），說明安裝成功。

### 安裝專案相依套件
進入 Konado 專案的根目錄，執行以下指令安裝文件預覽所需的相依套件：
```shell
npm install
```
等待指令執行完成，終端機無報錯即表示相依套件安裝成功。

### 啟動本地預覽服務
相依套件安裝完成後，執行以下指令啟動 VitePress 開發服務：
```shell
npm run docs:dev
```

### 訪問預覽文件
指令執行成功後，終端機會輸出類似以下的資訊：
```shell
vitepress v1.6.4

➜  Local:   http://localhost:5173/konado/
➜  Network: use --host to expose
➜  press h to show help
```
打開瀏覽器，訪問輸出資訊中的 `Local` 位址（預設：`http://localhost:5173/konado/`），即可查看本地文件。

### 補充說明
1. 即時重新整理：修改文件內容後，無需重啟服務，瀏覽器會自動重新整理頁面，即時展示修改後的效果；
2. 埠號異常：若 `localhost:5173` 埠號被佔用，VitePress 會自動切換到可用埠號（如 5174），請以終端機實際輸出的位址為準；
3. 區域網路訪問：如需在區域網路內其他裝置（如手機、另一台電腦）預覽文件，可執行 `npm run docs:dev -- --host` 指令，終端機會輸出網路可訪問的 IP 位址；
4. 停止伺服器：在終端機中按下 `Ctrl + C` 即可停止本地預覽服務。
