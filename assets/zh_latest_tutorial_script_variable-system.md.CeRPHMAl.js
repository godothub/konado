import{_ as s,o as n,c as e,a5 as p}from"./chunks/framework.BEZBAInb.js";const u=JSON.parse('{"title":"变量系统","description":"","frontmatter":{"title":"变量系统","order":8},"headers":[],"relativePath":"zh/latest/tutorial/script/variable-system.md","filePath":"zh/latest/tutorial/script/variable-system.md","lastUpdated":1788455378000}'),t={name:"zh/latest/tutorial/script/variable-system.md"};function i(l,a,o,d,c,h){return n(),e("div",null,[...a[0]||(a[0]=[p(`<h1 id="变量系统" tabindex="-1">变量系统 <a class="header-anchor" href="#变量系统" aria-label="Permalink to &quot;变量系统&quot;">​</a></h1><h2 id="功能概述" tabindex="-1">功能概述 <a class="header-anchor" href="#功能概述" aria-label="Permalink to &quot;功能概述&quot;">​</a></h2><p>变量系统允许在脚本中定义、读取、修改和判断变量，实现动态对话内容、条件分支和状态追踪。变量值可以在对话文本中直接引用，也可以作为条件判断的依据来控制剧情走向。</p><p>变量分为两种类型：</p><table tabindex="0"><thead><tr><th>类型</th><th>前缀</th><th>生命周期</th><th>持久化</th><th>初始化方式</th></tr></thead><tbody><tr><td>持久变量</td><td><code>%</code></td><td>跨镜头保留</td><td>随存档保存</td><td>检查器中预设 / 代码初始化</td></tr><tr><td>临时变量</td><td><code>$</code></td><td>仅当前镜头有效</td><td>不保存</td><td>脚本内 <code>set</code> 初始化</td></tr></tbody></table><hr><h2 id="变量操作" tabindex="-1">变量操作 <a class="header-anchor" href="#变量操作" aria-label="Permalink to &quot;变量操作&quot;">​</a></h2><p>支持五种基本操作，语法格式为：</p><div class="language-text vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">text</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span>&lt;操作&gt; &lt;变量名&gt; &lt;值&gt;</span></span></code></pre></div><p>或带等号的形式：</p><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span>&lt;操作&gt; &lt;变量名&gt; = &lt;值&gt;</span></span></code></pre></div><h3 id="操作列表" tabindex="-1">操作列表 <a class="header-anchor" href="#操作列表" aria-label="Permalink to &quot;操作列表&quot;">​</a></h3><table tabindex="0"><thead><tr><th>操作</th><th>说明</th><th>示例</th></tr></thead><tbody><tr><td><code>set</code></td><td>设置变量值</td><td><code>set %love = 10</code></td></tr><tr><td><code>add</code></td><td>加法（数值相加，字符串拼接）</td><td><code>add %love 5</code></td></tr><tr><td><code>sub</code></td><td>减法</td><td><code>sub %love 3</code></td></tr><tr><td><code>mul</code></td><td>乘法</td><td><code>mul %love 2</code></td></tr><tr><td><code>div</code></td><td>除法（除数为零时报错）</td><td><code>div %love 4</code></td></tr></tbody></table><h3 id="参数详解" tabindex="-1">参数详解 <a class="header-anchor" href="#参数详解" aria-label="Permalink to &quot;参数详解&quot;">​</a></h3><table tabindex="0"><thead><tr><th>参数</th><th>必需</th><th>示例</th><th>说明</th></tr></thead><tbody><tr><td>操作</td><td>是</td><td><code>set</code></td><td>五种操作之一</td></tr><tr><td>变量名</td><td>是</td><td><code>%love</code></td><td><code>%</code> 开头为持久变量，<code>$</code> 开头为临时变量</td></tr><tr><td>值</td><td>是</td><td><code>10</code></td><td>整数、浮点数、布尔值（<code>true</code>/<code>false</code>）或字符串（双引号包裹）</td></tr></tbody></table><h3 id="示例" tabindex="-1">示例 <a class="header-anchor" href="#示例" aria-label="Permalink to &quot;示例&quot;">​</a></h3><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span>set %love = 10</span></span>
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
<span class="line"><span>set %unlocked true</span></span></code></pre></div><hr><h2 id="变量插值" tabindex="-1">变量插值 <a class="header-anchor" href="#变量插值" aria-label="Permalink to &quot;变量插值&quot;">​</a></h2><p>在对话文本中直接使用 <code>%变量名</code> 或 <code>$变量名</code> 引用变量值，运行时会被替换为实际值。</p><h3 id="语法" tabindex="-1">语法 <a class="header-anchor" href="#语法" aria-label="Permalink to &quot;语法&quot;">​</a></h3><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span>Kona &quot;对话文本，包含 %变量名 或 $变量名&quot;</span></span></code></pre></div><h3 id="示例-1" tabindex="-1">示例 <a class="header-anchor" href="#示例-1" aria-label="Permalink to &quot;示例&quot;">​</a></h3><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span>set %player_name &quot;小明&quot;</span></span>
<span class="line"><span>set $stage &quot;新手村&quot;</span></span>
<span class="line"><span></span></span>
<span class="line"><span>Kona &quot;你好，%player_name！你现在在 $stage。&quot;</span></span>
<span class="line"><span>Kona &quot;你的好感度是 %love，当前是第 $round 回合。&quot;</span></span></code></pre></div><p>运行时输出：</p><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span>Kona: &quot;你好，小明！你现在在 新手村。&quot;</span></span>
<span class="line"><span>Kona: &quot;你的好感度是 12，当前是第 2 回合。&quot;</span></span></code></pre></div><hr><h2 id="条件判断" tabindex="-1">条件判断 <a class="header-anchor" href="#条件判断" aria-label="Permalink to &quot;条件判断&quot;">​</a></h2><p>使用 <code>if</code> / <code>else</code> / <code>endif</code> 结构，根据变量值决定播放哪段对话。支持六种比较运算符。</p><h3 id="语法结构" tabindex="-1">语法结构 <a class="header-anchor" href="#语法结构" aria-label="Permalink to &quot;语法结构&quot;">​</a></h3><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span>if &lt;变量名&gt; &lt;运算符&gt; &lt;值&gt;:</span></span>
<span class="line"><span>    &lt;对话内容&gt;</span></span>
<span class="line"><span>else:</span></span>
<span class="line"><span>    &lt;对话内容&gt;</span></span>
<span class="line"><span>endif</span></span></code></pre></div><p><code>else:</code> 块为可选，省略时条件不成立则跳过整个 <code>if</code> 块。</p><h3 id="支持的运算符" tabindex="-1">支持的运算符 <a class="header-anchor" href="#支持的运算符" aria-label="Permalink to &quot;支持的运算符&quot;">​</a></h3><table tabindex="0"><thead><tr><th>运算符</th><th>说明</th><th>示例</th></tr></thead><tbody><tr><td><code>==</code></td><td>等于</td><td><code>if %love == 5:</code></td></tr><tr><td><code>!=</code></td><td>不等于</td><td><code>if %love != 10:</code></td></tr><tr><td><code>&gt;</code></td><td>大于</td><td><code>if %love &gt; 3:</code></td></tr><tr><td><code>&lt;</code></td><td>小于</td><td><code>if %love &lt; 10:</code></td></tr><tr><td><code>&gt;=</code></td><td>大于等于</td><td><code>if %love &gt;= 5:</code></td></tr><tr><td><code>&lt;=</code></td><td>小于等于</td><td><code>if %love &lt;= 5:</code></td></tr></tbody></table><h3 id="参数详解-1" tabindex="-1">参数详解 <a class="header-anchor" href="#参数详解-1" aria-label="Permalink to &quot;参数详解&quot;">​</a></h3><table tabindex="0"><thead><tr><th>参数</th><th>必需</th><th>示例</th><th>说明</th></tr></thead><tbody><tr><td>变量名</td><td>是</td><td><code>%love</code></td><td><code>%</code> 持久变量或 <code>$</code> 临时变量</td></tr><tr><td>运算符</td><td>是</td><td><code>==</code></td><td>六种比较运算符之一</td></tr><tr><td>值</td><td>是</td><td><code>5</code></td><td>整数比较值</td></tr></tbody></table><h3 id="示例-2" tabindex="-1">示例 <a class="header-anchor" href="#示例-2" aria-label="Permalink to &quot;示例&quot;">​</a></h3><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span>if %love == 5:</span></span>
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
<span class="line"><span>endif</span></span></code></pre></div><h3 id="注意事项" tabindex="-1">注意事项 <a class="header-anchor" href="#注意事项" aria-label="Permalink to &quot;注意事项&quot;">​</a></h3><ol><li><code>if</code> / <code>else</code> / <code>endif</code> 必须与所在上下文的缩进层级一致；</li><li>条件判断<strong>不支持嵌套</strong>，即 <code>if</code> 块内不能再包含 <code>if</code>；</li><li>多个独立的条件判断应使用平铺的 <code>if</code> / <code>endif</code> 结构，而非嵌套；</li><li>条件判断可在 <code>branch</code> 分支块内使用。</li></ol><hr><h2 id="分支内使用条件判断" tabindex="-1">分支内使用条件判断 <a class="header-anchor" href="#分支内使用条件判断" aria-label="Permalink to &quot;分支内使用条件判断&quot;">​</a></h2><p><code>branch</code> 块内可以包含 <code>if</code> / <code>endif</code> 条件判断，实现分支内的动态对话。</p><h3 id="示例-3" tabindex="-1">示例 <a class="header-anchor" href="#示例-3" aria-label="Permalink to &quot;示例&quot;">​</a></h3><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span>branch after_choice</span></span>
<span class="line"><span>    Kona &quot;你的选择已被记录。&quot;</span></span>
<span class="line"><span></span></span>
<span class="line"><span>    if $choice_made == 1:</span></span>
<span class="line"><span>        Kona &quot;你选择了送礼物，真是个温柔的人呢。&quot;</span></span>
<span class="line"><span>    endif</span></span>
<span class="line"><span></span></span>
<span class="line"><span>    if $choice_made == 2:</span></span>
<span class="line"><span>        Kona &quot;你选择了聊天，沟通很重要。&quot;</span></span>
<span class="line"><span>    endif</span></span>
<span class="line"><span></span></span>
<span class="line"><span>    if $choice_made == 3:</span></span>
<span class="line"><span>        Kona &quot;你选择了无视...也许下次可以试试别的选项。&quot;</span></span>
<span class="line"><span>    endif</span></span></code></pre></div><hr><h2 id="选项联动变量" tabindex="-1">选项联动变量 <a class="header-anchor" href="#选项联动变量" aria-label="Permalink to &quot;选项联动变量&quot;">​</a></h2><p>结合 <code>choice</code> 和 <code>branch</code>，可以在用户做出选择后修改变量值，实现选择影响后续剧情。</p><h3 id="示例-4" tabindex="-1">示例 <a class="header-anchor" href="#示例-4" aria-label="Permalink to &quot;示例&quot;">​</a></h3><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span>set $choice_made = 0</span></span>
<span class="line"><span></span></span>
<span class="line"><span>choice &quot;送礼物（好感+10）&quot; -&gt; gift_choice</span></span>
<span class="line"><span>choice &quot;聊天（好感+5）&quot; -&gt; chat_choice</span></span>
<span class="line"><span>choice &quot;无视（好感-5）&quot; -&gt; ignore_choice</span></span>
<span class="line"><span></span></span>
<span class="line"><span>branch gift_choice</span></span>
<span class="line"><span>    add %love 10</span></span>
<span class="line"><span>    set $choice_made = 1</span></span>
<span class="line"><span>    Kona &quot;谢谢你！好感度提升到 %love！&quot;</span></span>
<span class="line"><span>    jump_branch after_choice</span></span>
<span class="line"><span></span></span>
<span class="line"><span>branch chat_choice</span></span>
<span class="line"><span>    add %love 5</span></span>
<span class="line"><span>    set $choice_made = 2</span></span>
<span class="line"><span>    Kona &quot;和你聊天很开心，好感度现在是 %love。&quot;</span></span>
<span class="line"><span>    jump_branch after_choice</span></span>
<span class="line"><span></span></span>
<span class="line"><span>branch ignore_choice</span></span>
<span class="line"><span>    sub %love 5</span></span>
<span class="line"><span>    set $choice_made = 3</span></span>
<span class="line"><span>    Kona &quot;......好感度降到了 %love。&quot;</span></span>
<span class="line"><span>    jump_branch after_choice</span></span>
<span class="line"><span></span></span>
<span class="line"><span>branch after_choice</span></span>
<span class="line"><span>    Kona &quot;你的选择已被记录。&quot;</span></span></code></pre></div><hr><h2 id="布尔变量" tabindex="-1">布尔变量 <a class="header-anchor" href="#布尔变量" aria-label="Permalink to &quot;布尔变量&quot;">​</a></h2><p>变量支持布尔类型，使用 <code>true</code> / <code>false</code> 赋值。在条件判断中，<code>true</code> 等价于 <code>1</code>，<code>false</code> 等价于 <code>0</code>。</p><h3 id="示例-5" tabindex="-1">示例 <a class="header-anchor" href="#示例-5" aria-label="Permalink to &quot;示例&quot;">​</a></h3><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span>set %unlocked true</span></span>
<span class="line"><span>set $visited false</span></span>
<span class="line"><span></span></span>
<span class="line"><span>if %unlocked == 1:</span></span>
<span class="line"><span>    Kona &quot;功能已解锁！&quot;</span></span>
<span class="line"><span>endif</span></span>
<span class="line"><span></span></span>
<span class="line"><span>set $visited true</span></span>
<span class="line"><span>if $visited == 1:</span></span>
<span class="line"><span>    Kona &quot;已访问标记已设置。&quot;</span></span>
<span class="line"><span>endif</span></span></code></pre></div><hr><h2 id="变量初始化" tabindex="-1">变量初始化 <a class="header-anchor" href="#变量初始化" aria-label="Permalink to &quot;变量初始化&quot;">​</a></h2><h3 id="持久变量" tabindex="-1">持久变量（%） <a class="header-anchor" href="#持久变量" aria-label="Permalink to &quot;持久变量（%）&quot;">​</a></h3><p>持久变量需要在脚本运行前初始化。有两种方式：</p><p><strong>方式一：检查器预设（推荐）</strong></p><p>在编辑器中创建 <code>KonadoVariableStore</code> 资源，在检查器中设置初始变量值，然后赋值给 <code>KonadoDialogueManager</code> 的 <code>variable_store</code> 属性。</p><p><strong>方式二：代码初始化</strong></p><div class="language-gdscript vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">gdscript</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">func</span><span style="--shiki-light:#6F42C1;--shiki-dark:#B392F0;"> _ready</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">() </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">-&gt;</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;"> void</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">:</span></span>
<span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">    if</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> dialogue_manager</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">.</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">variable_store </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">==</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> null</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">:</span></span>
<span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">        var</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> store </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#6F42C1;--shiki-dark:#B392F0;"> KonadoVariableStore</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">.</span><span style="--shiki-light:#6F42C1;--shiki-dark:#B392F0;">new</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">()</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">        store</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">.</span><span style="--shiki-light:#6F42C1;--shiki-dark:#B392F0;">set_value</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;love&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">0</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">        store</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">.</span><span style="--shiki-light:#6F42C1;--shiki-dark:#B392F0;">set_value</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;player_name&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">        store</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">.</span><span style="--shiki-light:#6F42C1;--shiki-dark:#B392F0;">set_value</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;unlocked&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">false</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">        dialogue_manager</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">.</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">variable_store </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> store</span></span></code></pre></div><h3 id="临时变量" tabindex="-1">临时变量（$） <a class="header-anchor" href="#临时变量" aria-label="Permalink to &quot;临时变量（$）&quot;">​</a></h3><p>临时变量无需预设，在脚本中首次使用 <code>set</code> 时自动创建。切换镜头时自动重置。</p><hr><h2 id="完整示例" tabindex="-1">完整示例 <a class="header-anchor" href="#完整示例" aria-label="Permalink to &quot;完整示例&quot;">​</a></h2><p>以下是一个综合演示，涵盖所有变量功能：</p><div class="language-text vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">text</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span>play bgm echo</span></span>
<span class="line"><span>background bg1 fade</span></span>
<span class="line"><span></span></span>
<span class="line"><span>actor show 可娜 正常 at 3</span></span>
<span class="line"><span>Kona &quot;欢迎来到变量系统演示！&quot;</span></span>
<span class="line"><span></span></span>
<span class="line"><span>set %love = 10</span></span>
<span class="line"><span>Kona &quot;好感度设为 10，现在是：%love&quot;</span></span>
<span class="line"><span></span></span>
<span class="line"><span>add %love 5</span></span>
<span class="line"><span>Kona &quot;加 5 后好感度：%love&quot;</span></span>
<span class="line"><span></span></span>
<span class="line"><span>sub %love 3</span></span>
<span class="line"><span>Kona &quot;减 3 后好感度：%love&quot;</span></span>
<span class="line"><span></span></span>
<span class="line"><span>mul %love 2</span></span>
<span class="line"><span>Kona &quot;乘 2 后好感度：%love&quot;</span></span>
<span class="line"><span></span></span>
<span class="line"><span>div %love 4</span></span>
<span class="line"><span>Kona &quot;除 4 后好感度：%love&quot;</span></span>
<span class="line"><span></span></span>
<span class="line"><span>set $round = 1</span></span>
<span class="line"><span>set $bonus = 100</span></span>
<span class="line"><span>Kona &quot;回合=$round，奖金=$bonus&quot;</span></span>
<span class="line"><span></span></span>
<span class="line"><span>add $round 1</span></span>
<span class="line"><span>add $bonus 50</span></span>
<span class="line"><span>Kona &quot;第 $round 回合，奖金 $bonus&quot;</span></span>
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
<span class="line"><span>    Kona &quot;好感度大于 3！&quot;</span></span>
<span class="line"><span>endif</span></span>
<span class="line"><span></span></span>
<span class="line"><span>if %love &lt; 10:</span></span>
<span class="line"><span>    Kona &quot;好感度小于 10。&quot;</span></span>
<span class="line"><span>endif</span></span>
<span class="line"><span></span></span>
<span class="line"><span>set $score = 85</span></span>
<span class="line"><span></span></span>
<span class="line"><span>if $score &gt;= 90:</span></span>
<span class="line"><span>    Kona &quot;优秀！&quot;</span></span>
<span class="line"><span>endif</span></span>
<span class="line"><span></span></span>
<span class="line"><span>if $score &gt;= 80:</span></span>
<span class="line"><span>    Kona &quot;良好！&quot;</span></span>
<span class="line"><span>endif</span></span>
<span class="line"><span></span></span>
<span class="line"><span>set %unlocked true</span></span>
<span class="line"><span>if %unlocked == 1:</span></span>
<span class="line"><span>    Kona &quot;功能已解锁！&quot;</span></span>
<span class="line"><span>endif</span></span>
<span class="line"><span></span></span>
<span class="line"><span>choice &quot;送礼物（好感+10）&quot; -&gt; gift</span></span>
<span class="line"><span>choice &quot;无视（好感-5）&quot; -&gt; ignore</span></span>
<span class="line"><span></span></span>
<span class="line"><span>branch gift</span></span>
<span class="line"><span>    add %love 10</span></span>
<span class="line"><span>    Kona &quot;谢谢你！好感度 %love！&quot;</span></span>
<span class="line"><span>    jump_branch done</span></span>
<span class="line"><span></span></span>
<span class="line"><span>branch ignore</span></span>
<span class="line"><span>    sub %love 5</span></span>
<span class="line"><span>    Kona &quot;......好感度 %love。&quot;</span></span>
<span class="line"><span>    jump_branch done</span></span>
<span class="line"><span></span></span>
<span class="line"><span>branch done</span></span>
<span class="line"><span>    actor exit 可娜</span></span>
<span class="line"><span>    background bg_end fade</span></span>
<span class="line"><span>    end</span></span></code></pre></div><hr><h2 id="注意事项-1" tabindex="-1">注意事项 <a class="header-anchor" href="#注意事项-1" aria-label="Permalink to &quot;注意事项&quot;">​</a></h2><ol><li><strong>变量名</strong>只能包含字母、数字和下划线，区分大小写；</li><li><strong>持久变量</strong>（<code>%</code>）的值会随存档保存，适合记录好感度、剧情标记等跨镜头状态；</li><li><strong>临时变量</strong>（<code>$</code>）在切换镜头时自动清空，适合记录当前镜头内的临时状态；</li><li><strong>除法操作</strong>时除数为零会触发错误并跳过该操作；</li><li><strong>条件判断</strong>不支持嵌套，多个条件请使用平铺的 <code>if</code> / <code>endif</code> 结构；</li><li>在 <code>branch</code> 块内使用条件判断时，<code>if</code> / <code>endif</code> 的缩进需与分支内其他内容一致；</li><li>未初始化的变量在条件判断中视为条件不成立。</li></ol>`,72)])])}const k=s(t,[["render",i]]);export{u as __pageData,k as default};
