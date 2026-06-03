---
title: 文件貢獻
order: 4
---

# 文件貢獻指南

## 線上編輯

若要線上編輯文件，請點擊線上文件左下角的 `在線編輯此頁`。瀏覽器會跳轉到倉庫中對應文件所在的位置。此時點擊右上角的 `編輯` 按鈕，修改後預覽效果，確認無誤後點擊 `提交修改` 提交。

提交後會經過審查，通過後合併到主倉庫。一般主倉庫合併後，線上文件會自動更新；如果沒有更新，請手動重新整理頁面，或提交後等待幾分鐘再重新整理。

## 本機編輯

文件可以直接向 `master` 分支`提交 PR`，不必建立特性分支。

在提交程式碼之前，請先確認已在本機完成 Git 的全域設定：

```shell
git config --global user.name 你的 Git 使用者名稱
git config --global user.email 你的提交信箱，必須與程式碼平台帳戶信箱一致
```

1. **Fork 專案**：點擊右上角 Fork 到自己的倉庫  
2. **克隆倉庫**：`git clone`  
3. **編輯文件**：在 `docs` 目錄下找到需要修改的文件，使用 Markdown 語法進行編輯（參考 [Markdown 語法](https://www.markdownguide.org/basic-syntax)）
4. **提交變更**：`git commit -m "描述你的文件變更"`  
5. **推送分支**：`git push origin master`

提交後，在自己 fork 的倉庫頁面點擊 `Pull Request` 按鈕，建立 PR。

## 本機預覽 Konado 文件

Konado 文件基於 [VitePress](https://vitepress.dev/) 構建。為確保文件修改內容符合預期，建議先在本機預覽驗證後再提交程式碼。

### 前置準備：安裝 Node.js

VitePress 依賴 Node.js 環境執行，因此需先安裝符合版本要求的 Node.js：

1. **版本要求**：建議安裝 Node.js 18.x 及以上版本（LTS 長期支援版最佳，兼容性更好）。
2. **下載安裝**：
   - 前往 Node.js 官方下載地址：[https://nodejs.org/](https://nodejs.org/)
   - 根據作業系統（Windows/macOS/Linux）選擇對應安裝包，依照精靈完成安裝（Windows 建議勾選「Add to PATH」選項）。
3. **驗證安裝**：
   開啟終端機（Windows 為命令提示字元/PowerShell，macOS/Linux 為終端機），執行以下命令驗證 Node.js 與 npm（Node.js 內建套件管理器）是否安裝成功：
   ```shell
   # 查看 Node.js 版本
   node -v
   # 查看 npm 版本
   npm -v
   ```
   若輸出清晰的版本號（如 `v20.10.0`、`10.2.3`），表示安裝成功。

> 可選最佳化：若 npm 下載依賴速度較慢，可設定國內鏡像提升速度：
> ```shell
> npm config set registry https://registry.npmmirror.com
> ```

### 安裝專案依賴

進入 Konado 專案根目錄，執行以下命令安裝文件預覽所需依賴：

```shell
npm install
```

等待命令執行完成，終端機無報錯即表示依賴安裝成功。

### 啟動本機預覽服務

依賴安裝完成後，執行以下命令啟動 VitePress 開發服務：

```shell
npm run docs:dev
```

### 存取預覽文件

命令執行成功後，終端機會輸出類似以下資訊：

```shell
vitepress v1.6.4

➜  Local:   http://localhost:5173/konado/
➜  Network: use --host to expose
➜  press h to show help
```

開啟瀏覽器，存取輸出資訊中的 `Local` 位址（預設：`http://localhost:5173/konado/`），即可查看本機文件。

### 補充說明

1. 即時重新整理：修改文件內容後，無需重啟服務，瀏覽器會自動重新整理頁面，即時展示修改後的效果；
2. 連接埠異常：若 `localhost:5173` 連接埠被占用，VitePress 會自動切換到可用連接埠（如 5174），請以終端機實際輸出的位址為準；
3. 區域網路存取：如需在區域網路內其他裝置（如手機、另一台電腦）預覽文件，可執行 `npm run docs:dev -- --host` 命令，終端機會輸出網路可存取的 IP 位址；
4. 停止伺服器：在終端機中按下 `Ctrl + C` 即可停止本機預覽服務。
