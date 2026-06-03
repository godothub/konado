---
title: 立繪規範
order: 3
---

# 立繪規範

## 介紹

立繪就是遊戲裡角色的靜態形象圖，在聊天對話介面中用來展示人物樣貌和各種表情。`Konado` 對話系統能以分區擺放的方式，靈活且精準地調整角色站位，並內建順滑的漸變動畫，讓畫面切換自然流暢。

## 演員定位

不同於傳統對話系統中的角色定位方式（如固定座標位置、座標偏移等），`Konado` 採用**區塊範本**實現角色位置的精準、自適應定位，節省手動調整角色位置的時間，並確保角色位置在對話場景中始終處於合理範圍內，加快開發效率。

同時，這種定位方式也方便設計師在其他設計工具中使用輔助線等工具進行角色定位，而無需在遊戲引擎中手動調整角色位置。

<figure>
  <center>
    <img src="/images/tutorial/actor-positioning.png" alt="演員定位" />
  </center>
  <figcaption style="font-size: 14px; text-align: center; color: #666;">演員定位</figcaption>
</figure>

### 演員位置

畫面會被分成若干等份（最少分 2 份，預設分 5 份）。從左到右數，角色可放在 `0/5` 到 `4/5` 之間，例如 `1/5` 表示角色位於畫面左側位置。

<figure>
  <center>
    <img src="/images/tutorial/actor-position-5-1.png" alt="演員定位" />
  </center>
  <figcaption style="font-size: 14px; text-align: center; color: #666;">演員定位</figcaption>
</figure>

### 原理

元件會將承載角色的 `Control` 節點畫布容器橫向等分為 `division` 個區塊（區塊數量可設定為 ≥2），區塊索引從**左到右遞增**（0 為最左側，division 為最右側）。

`character_position`（角色位置索引）的有效範圍被限制為 `[1, division-1]`，避免角色完全貼左或貼右導致視覺溢出問題。角色的**中心**會對齊區塊分割線顯示。

## 素材規範

想要讓角色立繪在對話介面中正常顯示，素材請遵循以下製作規範。示範操作以 Krita 為例，也可使用其他繪圖修圖軟體完成調整與裁切。

請先下載 **[角色裁切參考範本](/images/tutorial/konado-portrait-crop-template.png)** 和 **[角色定位參考範本](/images/tutorial/konado-portrait-position-template.svg)**。

1. **格式要求**：素材需儲存為透明背景的 PNG 格式，不得包含白邊、黑邊或雜色背景。
2. **安全邊預留**：角色邊緣（如髮梢、衣角）建議預留少量緩衝空間，避免因不同裝置的顯示誤差導致意外裁切。

### 規範

為確保角色立繪在對話場景中正常顯示、適配介面布局與動畫效果，製作立繪素材時請遵循以下規範。示範以 `Krita` 為例，也可使用其他繪圖軟體完成調整與裁切。多個立繪素材可以批次裁切，以確保一致的顯示效果。

<figure>
  <center>
    <img src="/images/tutorial/portrait-template-example.png" alt="演員定位" />
  </center>
  <figcaption style="font-size: 14px; text-align: center; color: #666;">演員定位</figcaption>
</figure>

#### 畫布與整體邊界規範

1. **裁切框（畫布外邊界）**  
    裁切框為素材檔案的最終畫布邊界，是立繪渲染的安全範圍。角色所有元素（含頭髮、裝飾、肢體等）均需包含在裁切框內，避免出現透明邊緣或顯示不全的問題。

2. **高度控制參考線**
    - **最高點參考線**：角色頭頂、髮飾等頂部元素不得超出該線，防止被介面頂部 UI 裁切。
    - **全身參考線**：角色腳底、裙擺等底部元素需對齊或不低於該線，確保角色在對話介面中完整呈現，避免「斷腳」問題。

#### 角色主體與定位規範

1. **主體可視框（核心區域）**  
    圖中帶控制點的矩形框為角色主體可視區域，是系統進行縮放、定位與動畫的基準範圍。角色核心部分（頭、軀幹、主要肢體）必須位於該框內。肢體、裙擺等次要元素若超出，需控制在合理範圍，避免動畫過程中穿模。

2. **中心點（錨點基準）**  
    畫布中心十字線為角色定位錨點，是系統實現角色移動、淡入淡出等動畫效果的核心參考。製作時需將角色重心（雙腳中間、身體中垂線）對齊該中心點，避免角色在介面中出現偏移、錯位問題。

#### 對話框避讓規範

下方矩形區域為對話介面的對話框占位區。製作立繪素材時，**角色的關鍵元素（如手部、重要裝飾）不得進入該區域**，以免被對話框遮擋，影響畫面觀感與角色識別度。範例中角色腿部的處理方式可作為參考，既完整展示角色，又避開對話框區域。

### 裁切和匯出

調整好角色位置後，根據角色的主體可視框（核心區域），裁切出角色主體部分。例如在 Krita 中裁切選取區域。

<figure>
  <center>
    <img src="/images/tutorial/krita-crop-selection.png" alt="演員定位" />
  </center>
  <figcaption style="font-size: 14px; text-align: center; color: #666;">演員定位</figcaption>
</figure>

使用 Krita 匯出裁切後的圖像，儲存為 PNG 格式。

<figure>
  <center>
    <img src="/images/tutorial/krita-export-menu.png" alt="圖像匯出選單" />
  </center>
  <figcaption style="font-size: 14px; text-align: center; color: #666;">圖像匯出選單</figcaption>
</figure>

多個立繪素材可以批次匯出。

<figure>
  <center>
    <img src="/images/tutorial/krita-batch-export.png" alt="批次匯出" />
  </center>
  <figcaption style="font-size: 14px; text-align: center; color: #666;">批次匯出</figcaption>
</figure>
