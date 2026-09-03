import{_ as s,o as n,c as e,a5 as p}from"./chunks/framework.BEZBAInb.js";const u=JSON.parse('{"title":"變數系統","description":"","frontmatter":{"title":"變數系統","order":8},"headers":[],"relativePath":"tc/latest/tutorial/script/variable-system.md","filePath":"tc/latest/tutorial/script/variable-system.md","lastUpdated":1788455378000}'),t={name:"tc/latest/tutorial/script/variable-system.md"};function i(l,a,o,d,c,h){return n(),e("div",null,[...a[0]||(a[0]=[p(`<h1 id="變數系統" tabindex="-1">變數系統 <a class="header-anchor" href="#變數系統" aria-label="Permalink to &quot;變數系統&quot;">​</a></h1><h2 id="功能概述" tabindex="-1">功能概述 <a class="header-anchor" href="#功能概述" aria-label="Permalink to &quot;功能概述&quot;">​</a></h2><p>變數系統允許在腳本中定義、讀取、修改和判斷變數，實現動態對話內容、條件分支和狀態追蹤。變數值可以在對話文字中直接引用，也可以作為條件判斷的依據來控制劇情走向。</p><p>變數分為兩種類型：</p><table tabindex="0"><thead><tr><th>類型</th><th>前綴</th><th>生命週期</th><th>持久化</th><th>初始化方式</th></tr></thead><tbody><tr><td>持久變數</td><td><code>%</code></td><td>跨鏡頭保留</td><td>隨存檔保存</td><td>檢查器中預設 / 程式碼初始化</td></tr><tr><td>臨時變數</td><td><code>$</code></td><td>僅目前鏡頭有效</td><td>不保存</td><td>腳本內 <code>set</code> 初始化</td></tr></tbody></table><hr><h2 id="變數操作" tabindex="-1">變數操作 <a class="header-anchor" href="#變數操作" aria-label="Permalink to &quot;變數操作&quot;">​</a></h2><p>支援五種基本操作，語法格式為：</p><div class="language-text vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">text</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span>&lt;操作&gt; &lt;變數名&gt; &lt;值&gt;</span></span></code></pre></div><p>或帶等號的形式：</p><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span>&lt;操作&gt; &lt;變數名&gt; = &lt;值&gt;</span></span></code></pre></div><h3 id="操作列表" tabindex="-1">操作列表 <a class="header-anchor" href="#操作列表" aria-label="Permalink to &quot;操作列表&quot;">​</a></h3><table tabindex="0"><thead><tr><th>操作</th><th>說明</th><th>範例</th></tr></thead><tbody><tr><td><code>set</code></td><td>設定變數值</td><td><code>set %love = 10</code></td></tr><tr><td><code>add</code></td><td>加法（數值相加、字串串接）</td><td><code>add %love 5</code></td></tr><tr><td><code>sub</code></td><td>減法</td><td><code>sub %love 3</code></td></tr><tr><td><code>mul</code></td><td>乘法</td><td><code>mul %love 2</code></td></tr><tr><td><code>div</code></td><td>除法（除數為零時報錯）</td><td><code>div %love 4</code></td></tr></tbody></table><h3 id="參數詳解" tabindex="-1">參數詳解 <a class="header-anchor" href="#參數詳解" aria-label="Permalink to &quot;參數詳解&quot;">​</a></h3><table tabindex="0"><thead><tr><th>參數</th><th>必需</th><th>範例</th><th>說明</th></tr></thead><tbody><tr><td>操作</td><td>是</td><td><code>set</code></td><td>五種操作之一</td></tr><tr><td>變數名</td><td>是</td><td><code>%love</code></td><td><code>%</code> 開頭為持久變數，<code>$</code> 開頭為臨時變數</td></tr><tr><td>值</td><td>是</td><td><code>10</code></td><td>整數、浮點數、布林值（<code>true</code>/<code>false</code>）或字串（以雙引號包裹）</td></tr></tbody></table><h3 id="範例" tabindex="-1">範例 <a class="header-anchor" href="#範例" aria-label="Permalink to &quot;範例&quot;">​</a></h3><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span>set %love = 10</span></span>
<span class="line"><span>add %love 5</span></span>
<span class="line"><span>sub %love 3</span></span>
<span class="line"><span>mul %love 2</span></span>
<span class="line"><span>div %love 4</span></span>
<span class="line"><span></span></span>
<span class="line"><span>set $round = 1</span></span>
<span class="line"><span>add $round 1</span></span>
<span class="line"><span></span></span>
<span class="line"><span>set %player_name &quot;玩家&quot;</span></span>
<span class="line"><span>set $stage &quot;新手村&quot;</span></span>
<span class="line"><span>set %unlocked true</span></span></code></pre></div><hr><h2 id="變數插值" tabindex="-1">變數插值 <a class="header-anchor" href="#變數插值" aria-label="Permalink to &quot;變數插值&quot;">​</a></h2><p>在對話文字中直接使用 <code>%變數名</code> 或 <code>$變數名</code> 引用變數值，執行時會被替換為實際值。</p><h3 id="語法" tabindex="-1">語法 <a class="header-anchor" href="#語法" aria-label="Permalink to &quot;語法&quot;">​</a></h3><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span>Kona &quot;對話文字，包含 %變數名 或 $變數名&quot;</span></span></code></pre></div><h3 id="範例-1" tabindex="-1">範例 <a class="header-anchor" href="#範例-1" aria-label="Permalink to &quot;範例&quot;">​</a></h3><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span>set %player_name &quot;小明&quot;</span></span>
<span class="line"><span>set $stage &quot;新手村&quot;</span></span>
<span class="line"><span></span></span>
<span class="line"><span>Kona &quot;你好，%player_name！你現在在 $stage。&quot;</span></span>
<span class="line"><span>Kona &quot;你的好感度是 %love，目前是第 $round 回合。&quot;</span></span></code></pre></div><p>執行時輸出：</p><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span>Kona: &quot;你好，小明！你現在在 新手村。&quot;</span></span>
<span class="line"><span>Kona: &quot;你的好感度是 12，目前是第 2 回合。&quot;</span></span></code></pre></div><hr><h2 id="條件判斷" tabindex="-1">條件判斷 <a class="header-anchor" href="#條件判斷" aria-label="Permalink to &quot;條件判斷&quot;">​</a></h2><p>使用 <code>if</code> / <code>else</code> / <code>endif</code> 結構，根據變數值決定播放哪段對話。支援六種比較運算子。</p><h3 id="語法結構" tabindex="-1">語法結構 <a class="header-anchor" href="#語法結構" aria-label="Permalink to &quot;語法結構&quot;">​</a></h3><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span>if &lt;變數名&gt; &lt;運算子&gt; &lt;值&gt;:</span></span>
<span class="line"><span>    &lt;對話內容&gt;</span></span>
<span class="line"><span>else:</span></span>
<span class="line"><span>    &lt;對話內容&gt;</span></span>
<span class="line"><span>endif</span></span></code></pre></div><p><code>else:</code> 區塊為可選；省略時，若條件不成立就會跳過整個 <code>if</code> 區塊。</p><h3 id="支援的運算子" tabindex="-1">支援的運算子 <a class="header-anchor" href="#支援的運算子" aria-label="Permalink to &quot;支援的運算子&quot;">​</a></h3><table tabindex="0"><thead><tr><th>運算子</th><th>說明</th><th>範例</th></tr></thead><tbody><tr><td><code>==</code></td><td>等於</td><td><code>if %love == 5:</code></td></tr><tr><td><code>!=</code></td><td>不等於</td><td><code>if %love != 10:</code></td></tr><tr><td><code>&gt;</code></td><td>大於</td><td><code>if %love &gt; 3:</code></td></tr><tr><td><code>&lt;</code></td><td>小於</td><td><code>if %love &lt; 10:</code></td></tr><tr><td><code>&gt;=</code></td><td>大於等於</td><td><code>if %love &gt;= 5:</code></td></tr><tr><td><code>&lt;=</code></td><td>小於等於</td><td><code>if %love &lt;= 5:</code></td></tr></tbody></table><h3 id="參數詳解-1" tabindex="-1">參數詳解 <a class="header-anchor" href="#參數詳解-1" aria-label="Permalink to &quot;參數詳解&quot;">​</a></h3><table tabindex="0"><thead><tr><th>參數</th><th>必需</th><th>範例</th><th>說明</th></tr></thead><tbody><tr><td>變數名</td><td>是</td><td><code>%love</code></td><td><code>%</code> 持久變數或 <code>$</code> 臨時變數</td></tr><tr><td>運算子</td><td>是</td><td><code>==</code></td><td>六種比較運算子之一</td></tr><tr><td>值</td><td>是</td><td><code>5</code></td><td>整數比較值</td></tr></tbody></table><h3 id="範例-2" tabindex="-1">範例 <a class="header-anchor" href="#範例-2" aria-label="Permalink to &quot;範例&quot;">​</a></h3><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span>if %love == 5:</span></span>
<span class="line"><span>    Kona &quot;好感度正好是 5！&quot;</span></span>
<span class="line"><span>else:</span></span>
<span class="line"><span>    Kona &quot;好感度不是 5。&quot;</span></span>
<span class="line"><span>endif</span></span>
<span class="line"><span></span></span>
<span class="line"><span>if $score &gt;= 80:</span></span>
<span class="line"><span>    Kona &quot;良好！&quot;</span></span>
<span class="line"><span>endif</span></span>
<span class="line"><span></span></span>
<span class="line"><span>if $score &gt;= 60:</span></span>
<span class="line"><span>    Kona &quot;及格。&quot;</span></span>
<span class="line"><span>endif</span></span></code></pre></div><h3 id="注意事項" tabindex="-1">注意事項 <a class="header-anchor" href="#注意事項" aria-label="Permalink to &quot;注意事項&quot;">​</a></h3><ol><li><code>if</code> / <code>else</code> / <code>endif</code> 必須與所在上下文的縮排層級一致；</li><li>條件判斷<strong>不支援巢狀結構</strong>，也就是 <code>if</code> 區塊內不能再包含 <code>if</code>；</li><li>多個獨立的條件判斷應使用平鋪的 <code>if</code> / <code>endif</code> 結構，而不是巢狀結構；</li><li>條件判斷可在 <code>branch</code> 分支區塊內使用。</li></ol><hr><h2 id="分支內使用條件判斷" tabindex="-1">分支內使用條件判斷 <a class="header-anchor" href="#分支內使用條件判斷" aria-label="Permalink to &quot;分支內使用條件判斷&quot;">​</a></h2><p><code>branch</code> 區塊內可以包含 <code>if</code> / <code>endif</code> 條件判斷，實現分支內的動態對話。</p><h3 id="範例-3" tabindex="-1">範例 <a class="header-anchor" href="#範例-3" aria-label="Permalink to &quot;範例&quot;">​</a></h3><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span>branch after_choice</span></span>
<span class="line"><span>    Kona &quot;你的選擇已被記錄。&quot;</span></span>
<span class="line"><span></span></span>
<span class="line"><span>    if $choice_made == 1:</span></span>
<span class="line"><span>        Kona &quot;你選擇了送禮物，真是個溫柔的人呢。&quot;</span></span>
<span class="line"><span>    endif</span></span>
<span class="line"><span></span></span>
<span class="line"><span>    if $choice_made == 2:</span></span>
<span class="line"><span>        Kona &quot;你選擇了聊天，溝通很重要。&quot;</span></span>
<span class="line"><span>    endif</span></span>
<span class="line"><span></span></span>
<span class="line"><span>    if $choice_made == 3:</span></span>
<span class="line"><span>        Kona &quot;你選擇了無視……也許下次可以試試別的選項。&quot;</span></span>
<span class="line"><span>    endif</span></span></code></pre></div><hr><h2 id="選項聯動變數" tabindex="-1">選項聯動變數 <a class="header-anchor" href="#選項聯動變數" aria-label="Permalink to &quot;選項聯動變數&quot;">​</a></h2><p>結合 <code>choice</code> 和 <code>branch</code>，可以在使用者做出選擇後修改變數值，實現選擇影響後續劇情。</p><h3 id="範例-4" tabindex="-1">範例 <a class="header-anchor" href="#範例-4" aria-label="Permalink to &quot;範例&quot;">​</a></h3><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span>set $choice_made = 0</span></span>
<span class="line"><span></span></span>
<span class="line"><span>choice &quot;送禮物（好感+10）&quot; -&gt; gift_choice</span></span>
<span class="line"><span>choice &quot;聊天（好感+5）&quot; -&gt; chat_choice</span></span>
<span class="line"><span>choice &quot;無視（好感-5）&quot; -&gt; ignore_choice</span></span>
<span class="line"><span></span></span>
<span class="line"><span>branch gift_choice</span></span>
<span class="line"><span>    add %love 10</span></span>
<span class="line"><span>    set $choice_made = 1</span></span>
<span class="line"><span>    Kona &quot;謝謝你！好感度提升到 %love！&quot;</span></span>
<span class="line"><span>    jump_branch after_choice</span></span>
<span class="line"><span></span></span>
<span class="line"><span>branch chat_choice</span></span>
<span class="line"><span>    add %love 5</span></span>
<span class="line"><span>    set $choice_made = 2</span></span>
<span class="line"><span>    Kona &quot;和你聊天很開心，好感度現在是 %love。&quot;</span></span>
<span class="line"><span>    jump_branch after_choice</span></span>
<span class="line"><span></span></span>
<span class="line"><span>branch ignore_choice</span></span>
<span class="line"><span>    sub %love 5</span></span>
<span class="line"><span>    set $choice_made = 3</span></span>
<span class="line"><span>    Kona &quot;……好感度降到了 %love。&quot;</span></span>
<span class="line"><span>    jump_branch after_choice</span></span>
<span class="line"><span></span></span>
<span class="line"><span>branch after_choice</span></span>
<span class="line"><span>    Kona &quot;你的選擇已被記錄。&quot;</span></span></code></pre></div><hr><h2 id="布林變數" tabindex="-1">布林變數 <a class="header-anchor" href="#布林變數" aria-label="Permalink to &quot;布林變數&quot;">​</a></h2><p>變數支援布林類型，使用 <code>true</code> / <code>false</code> 賦值。在條件判斷中，<code>true</code> 等價於 <code>1</code>，<code>false</code> 等價於 <code>0</code>。</p><h3 id="範例-5" tabindex="-1">範例 <a class="header-anchor" href="#範例-5" aria-label="Permalink to &quot;範例&quot;">​</a></h3><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span>set %unlocked true</span></span>
<span class="line"><span>set $visited false</span></span>
<span class="line"><span></span></span>
<span class="line"><span>if %unlocked == 1:</span></span>
<span class="line"><span>    Kona &quot;功能已解鎖！&quot;</span></span>
<span class="line"><span>endif</span></span>
<span class="line"><span></span></span>
<span class="line"><span>set $visited true</span></span>
<span class="line"><span>if $visited == 1:</span></span>
<span class="line"><span>    Kona &quot;已設定訪問標記。&quot;</span></span>
<span class="line"><span>endif</span></span></code></pre></div><hr><h2 id="變數初始化" tabindex="-1">變數初始化 <a class="header-anchor" href="#變數初始化" aria-label="Permalink to &quot;變數初始化&quot;">​</a></h2><h3 id="持久變數" tabindex="-1">持久變數（%） <a class="header-anchor" href="#持久變數" aria-label="Permalink to &quot;持久變數（%）&quot;">​</a></h3><p>持久變數需要在腳本執行前初始化。有兩種方式：</p><p><strong>方式一：檢查器預設（推薦）</strong></p><p>在編輯器中建立 <code>KonadoVariableStore</code> 資源，在檢查器中設定初始變數值，然後賦值給 <code>KonadoDialogueManager</code> 的 <code>variable_store</code> 屬性。</p><p><strong>方式二：程式碼初始化</strong></p><div class="language-gdscript vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">gdscript</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">func</span><span style="--shiki-light:#6F42C1;--shiki-dark:#B392F0;"> _ready</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">() </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">-&gt;</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;"> void</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">:</span></span>
<span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">    if</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> dialogue_manager</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">.</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">variable_store </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">==</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> null</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">:</span></span>
<span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">        var</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> store </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#6F42C1;--shiki-dark:#B392F0;"> KonadoVariableStore</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">.</span><span style="--shiki-light:#6F42C1;--shiki-dark:#B392F0;">new</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">()</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">        store</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">.</span><span style="--shiki-light:#6F42C1;--shiki-dark:#B392F0;">set_value</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;love&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">0</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">        store</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">.</span><span style="--shiki-light:#6F42C1;--shiki-dark:#B392F0;">set_value</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;player_name&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">        store</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">.</span><span style="--shiki-light:#6F42C1;--shiki-dark:#B392F0;">set_value</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;unlocked&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">false</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">        dialogue_manager</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">.</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">variable_store </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> store</span></span></code></pre></div><h3 id="臨時變數" tabindex="-1">臨時變數（$） <a class="header-anchor" href="#臨時變數" aria-label="Permalink to &quot;臨時變數（$）&quot;">​</a></h3><p>臨時變數無需預設，在腳本中首次使用 <code>set</code> 時會自動建立。切換鏡頭時會自動重設。</p><hr><h2 id="完整範例" tabindex="-1">完整範例 <a class="header-anchor" href="#完整範例" aria-label="Permalink to &quot;完整範例&quot;">​</a></h2><p>以下是一個綜合示範，涵蓋所有變數功能：</p><div class="language-text vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">text</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span>play bgm echo</span></span>
<span class="line"><span>background bg1 fade</span></span>
<span class="line"><span></span></span>
<span class="line"><span>actor show 可娜 正常 at 3</span></span>
<span class="line"><span>Kona &quot;歡迎來到變數系統示範！&quot;</span></span>
<span class="line"><span></span></span>
<span class="line"><span>set %love = 10</span></span>
<span class="line"><span>Kona &quot;好感度設為 10，現在是：%love&quot;</span></span>
<span class="line"><span></span></span>
<span class="line"><span>add %love 5</span></span>
<span class="line"><span>Kona &quot;加 5 後好感度：%love&quot;</span></span>
<span class="line"><span></span></span>
<span class="line"><span>sub %love 3</span></span>
<span class="line"><span>Kona &quot;減 3 後好感度：%love&quot;</span></span>
<span class="line"><span></span></span>
<span class="line"><span>mul %love 2</span></span>
<span class="line"><span>Kona &quot;乘 2 後好感度：%love&quot;</span></span>
<span class="line"><span></span></span>
<span class="line"><span>div %love 4</span></span>
<span class="line"><span>Kona &quot;除 4 後好感度：%love&quot;</span></span>
<span class="line"><span></span></span>
<span class="line"><span>set $round = 1</span></span>
<span class="line"><span>set $bonus = 100</span></span>
<span class="line"><span>Kona &quot;回合=$round，獎金=$bonus&quot;</span></span>
<span class="line"><span></span></span>
<span class="line"><span>add $round 1</span></span>
<span class="line"><span>add $bonus 50</span></span>
<span class="line"><span>Kona &quot;第 $round 回合，獎金 $bonus&quot;</span></span>
<span class="line"><span></span></span>
<span class="line"><span>set %player_name &quot;玩家&quot;</span></span>
<span class="line"><span>Kona &quot;你好，%player_name！好感度 %love，第 $round 回合。&quot;</span></span>
<span class="line"><span></span></span>
<span class="line"><span>if %love == 6:</span></span>
<span class="line"><span>    Kona &quot;好感度正好是 6！&quot;</span></span>
<span class="line"><span>else:</span></span>
<span class="line"><span>    Kona &quot;好感度不是 6。&quot;</span></span>
<span class="line"><span>endif</span></span>
<span class="line"><span></span></span>
<span class="line"><span>if %love &gt; 3:</span></span>
<span class="line"><span>    Kona &quot;好感度大於 3！&quot;</span></span>
<span class="line"><span>endif</span></span>
<span class="line"><span></span></span>
<span class="line"><span>if %love &lt; 10:</span></span>
<span class="line"><span>    Kona &quot;好感度小於 10。&quot;</span></span>
<span class="line"><span>endif</span></span>
<span class="line"><span></span></span>
<span class="line"><span>set $score = 85</span></span>
<span class="line"><span></span></span>
<span class="line"><span>if $score &gt;= 90:</span></span>
<span class="line"><span>    Kona &quot;優秀！&quot;</span></span>
<span class="line"><span>endif</span></span>
<span class="line"><span></span></span>
<span class="line"><span>if $score &gt;= 80:</span></span>
<span class="line"><span>    Kona &quot;良好！&quot;</span></span>
<span class="line"><span>endif</span></span>
<span class="line"><span></span></span>
<span class="line"><span>set %unlocked true</span></span>
<span class="line"><span>if %unlocked == 1:</span></span>
<span class="line"><span>    Kona &quot;功能已解鎖！&quot;</span></span>
<span class="line"><span>endif</span></span>
<span class="line"><span></span></span>
<span class="line"><span>choice &quot;送禮物（好感+10）&quot; -&gt; gift</span></span>
<span class="line"><span>choice &quot;無視（好感-5）&quot; -&gt; ignore</span></span>
<span class="line"><span></span></span>
<span class="line"><span>branch gift</span></span>
<span class="line"><span>    add %love 10</span></span>
<span class="line"><span>    Kona &quot;謝謝你！好感度 %love！&quot;</span></span>
<span class="line"><span>    jump_branch done</span></span>
<span class="line"><span></span></span>
<span class="line"><span>branch ignore</span></span>
<span class="line"><span>    sub %love 5</span></span>
<span class="line"><span>    Kona &quot;……好感度 %love。&quot;</span></span>
<span class="line"><span>    jump_branch done</span></span>
<span class="line"><span></span></span>
<span class="line"><span>branch done</span></span>
<span class="line"><span>    actor exit 可娜</span></span>
<span class="line"><span>    background bg_end fade</span></span>
<span class="line"><span>    end</span></span></code></pre></div><hr><h2 id="注意事項-1" tabindex="-1">注意事項 <a class="header-anchor" href="#注意事項-1" aria-label="Permalink to &quot;注意事項&quot;">​</a></h2><ol><li><strong>變數名</strong>只能包含字母、數字和底線，並區分大小寫；</li><li><strong>持久變數</strong>（<code>%</code>）的值會隨存檔保存，適合記錄好感度、劇情標記等跨鏡頭狀態；</li><li><strong>臨時變數</strong>（<code>$</code>）在切換鏡頭時自動清空，適合記錄目前鏡頭內的臨時狀態；</li><li><strong>除法操作</strong>時除數為零會觸發錯誤並跳過該操作；</li><li><strong>條件判斷</strong>不支援巢狀結構，多個條件請使用平鋪的 <code>if</code> / <code>endif</code> 結構；</li><li>在 <code>branch</code> 區塊內使用條件判斷時，<code>if</code> / <code>endif</code> 的縮排需與分支內其他內容一致；</li><li>未初始化的變數在條件判斷中視為條件不成立。</li></ol>`,72)])])}const k=s(t,[["render",i]]);export{u as __pageData,k as default};
