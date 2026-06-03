---
title: 立绘规范
order: 3
---

# 立绘规范

## 介绍

立绘就是游戏里角色的静态形象图，聊天对话界面里用来展示人物样子和各种表情。`Konado` 对话系统能用分区摆放的方式，灵活精准调好角色站位，还自带顺滑的渐变动画，切换画面自然流畅。


## 演员定位


不同于传统对话系统中的角色定位方式（如固定坐标位置、坐标偏移等），`Konado` 采用**区块模板**实现角色位置的精准、自适应定位，节省了手动调整角色位置的时间，并确保角色位置在对话场景中始终处于合理范围内，加快开发效率。

同时，这样定位也可以方便在设计师在其他设计工具中使用辅助线等工具进行角色定位，而无需在游戏引擎中手动调整角色位置。

<figure>
  <center>
    <img src="/images/tutorial/actor-positioning.png" alt="演员定位" />
  </center>
  <figcaption style="font-size: 14px; text-align: center; color: #666;">演员定位</figcaption>
</figure>

### 演员位置

画面会被分成若干等份（最少分 2 份，默认分 5 份），从左到右数，角色能放在`0/5`到`4/5`之间，比如`1/5`表示角色在画面的左侧位置。

<figure>
  <center>
    <img src="/images/tutorial/actor-position-5-1.png" alt="演员定位" />
  </center>
  <figcaption style="font-size: 14px; text-align: center; color: #666;">演员定位</figcaption>
</figure>


### 原理

组件将承载角色的 `Control` 节点画布容器横向等分为 `division` 个区块（区块数量可设置≥2），区块索引从**左到右递增**（0 为最左侧，division 为最右侧），

`character_position`（角色位置索引）的有效范围被限制为 `[1, division-1]`，避免角色完全贴左/贴右导致的视觉溢出问题，角色的**中心**将对齐区块分割线显示。


## 素材规范

想要让角色立绘在对话界面正常显示，素材请遵循以下制作规范。演示操作以Krita为例，也可使用其他绘图修图软件完成调整与裁剪。

请先下载 **[角色裁切参考模板](/images/tutorial/konado-portrait-crop-template.png)**，和 **[角色定位参考模板](/images/tutorial/konado-portrait-position-template.svg)**。


1.  **格式要求**：素材需保存为透明背景的PNG格式，不得包含白边、黑边或杂色背景。
2.  **安全边预留**：角色边缘（如发梢、衣角）建议预留少量缓冲空间，避免因不同设备的显示误差导致意外裁切。

### 规范

为确保角色立绘在对话场景中正常显示、适配界面布局与动画效果，制作立绘素材时请遵循以下规范，演示以`Krita`为例，也可使用其他绘图软件完成调整与裁切。多个立绘素材可以批量进行裁切来确保一致的显示效果。

<figure>
  <center>
    <img src="/images/tutorial/portrait-template-example.png" alt="演员定位" />
  </center>
  <figcaption style="font-size: 14px; text-align: center; color: #666;">演员定位</figcaption>
</figure>

#### 画布与整体边界规范
1.  **裁切框（画布外边界）**
    裁切框为素材文件的最终画布边界，是立绘渲染的安全范围。角色所有元素（含头发、装饰、肢体等）均需包含在裁切框内，避免出现透明边缘或显示不全的问题。

2.  **高度控制参考线**
    - **最高点参考线**：角色头顶、发饰等顶部元素不得超出该线，防止被界面顶部UI裁切。
    - **全身参考线**：角色脚底、裙摆等底部元素需对齐或不低于该线，保证角色在对话界面中完整呈现，无“断脚”问题。


#### 角色主体与定位规范
1.  **主体可视框（核心区域）**
    图中带控制点的矩形框为角色主体可视区域，是系统进行缩放、定位与动画的基准范围。角色核心部分（头、躯干、主要肢体）必须位于该框内，肢体、裙摆等次要元素若超出，需控制在合理范围，避免动画过程中穿模。

2.  **中心点（锚点基准）**
    画布中心十字线为角色定位锚点，是系统实现角色移动、淡入淡出等动画效果的核心参考。制作时需将角色重心（双脚中间、身体中垂线）对齐该中心点，避免角色在界面中出现偏移、错位问题。


#### 对话框避让规范
下方矩形区域为对话界面的对话框占位区，立绘素材制作时，**角色的关键元素（如手部、重要装饰）不得进入该区域**，防止被对话框遮挡，影响画面观感与角色识别度。示例中角色腿部的处理方式可作为参考，既完整展示角色，又避开对话框区域。






### 裁切和导出

调整好角色位置后，根据角色的主体可视框（核心区域），裁切出角色的主体部分。如Krita中裁切选中区域。

<figure>
  <center>
    <img src="/images/tutorial/krita-crop-selection.png" alt="演员定位" />
  </center>
  <figcaption style="font-size: 14px; text-align: center; color: #666;">演员定位</figcaption>
</figure>

使用Krita导出裁切后的图像，保存为PNG格式。


<figure>
  <center>
    <img src="/images/tutorial/krita-export-menu.png" alt="图像导出菜单" />
  </center>
  <figcaption style="font-size: 14px; text-align: center; color: #666;">图像导出菜单</figcaption>
</figure>

多个立绘素材可以批量导出。

<figure>
  <center>
    <img src="/images/tutorial/krita-batch-export.png" alt="批量导出" />
  </center>
  <figcaption style="font-size: 14px; text-align: center; color: #666;">批量导出</figcaption>
</figure>
