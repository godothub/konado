import{_ as s,o as n,c as e,a5 as t}from"./chunks/framework.BEZBAInb.js";const u=JSON.parse('{"title":"Variable System","description":"","frontmatter":{"title":"Variable System","order":8},"headers":[],"relativePath":"en/latest/tutorial/script/variable-system.md","filePath":"en/latest/tutorial/script/variable-system.md","lastUpdated":1788455378000}'),i={name:"en/latest/tutorial/script/variable-system.md"};function p(l,a,o,d,c,r){return n(),e("div",null,[...a[0]||(a[0]=[t(`<h1 id="variable-system" tabindex="-1">Variable System <a class="header-anchor" href="#variable-system" aria-label="Permalink to &quot;Variable System&quot;">​</a></h1><h2 id="feature-overview" tabindex="-1">Feature Overview <a class="header-anchor" href="#feature-overview" aria-label="Permalink to &quot;Feature Overview&quot;">​</a></h2><p>The variable system lets you define, read, modify, and check variables in scripts, enabling dynamic dialogue text, conditional branches, and state tracking. Variable values can be referenced directly in dialogue text, and they can also be used as conditions to control the story flow.</p><p>There are two kinds of variables:</p><table tabindex="0"><thead><tr><th>Type</th><th>Prefix</th><th>Lifetime</th><th>Persistence</th><th>Initialization</th></tr></thead><tbody><tr><td>Persistent variable</td><td><code>%</code></td><td>Preserved across shots</td><td>Saved with save data</td><td>Preset in the inspector / initialized in code</td></tr><tr><td>Temporary variable</td><td><code>$</code></td><td>Valid only in the current shot</td><td>Not saved</td><td>Initialized with <code>set</code> in scripts</td></tr></tbody></table><hr><h2 id="variable-operations" tabindex="-1">Variable Operations <a class="header-anchor" href="#variable-operations" aria-label="Permalink to &quot;Variable Operations&quot;">​</a></h2><p>Five basic operations are supported. The syntax is:</p><div class="language-text vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">text</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span>&lt;operation&gt; &lt;variable_name&gt; &lt;value&gt;</span></span></code></pre></div><p>You can also write it with an equals sign:</p><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span>&lt;operation&gt; &lt;variable_name&gt; = &lt;value&gt;</span></span></code></pre></div><h3 id="operation-list" tabindex="-1">Operation List <a class="header-anchor" href="#operation-list" aria-label="Permalink to &quot;Operation List&quot;">​</a></h3><table tabindex="0"><thead><tr><th>Operation</th><th>Description</th><th>Example</th></tr></thead><tbody><tr><td><code>set</code></td><td>Sets the variable value</td><td><code>set %love = 10</code></td></tr><tr><td><code>add</code></td><td>Addition; numeric addition or string concatenation</td><td><code>add %love 5</code></td></tr><tr><td><code>sub</code></td><td>Subtraction</td><td><code>sub %love 3</code></td></tr><tr><td><code>mul</code></td><td>Multiplication</td><td><code>mul %love 2</code></td></tr><tr><td><code>div</code></td><td>Division; reports an error when dividing by zero</td><td><code>div %love 4</code></td></tr></tbody></table><h3 id="parameters" tabindex="-1">Parameters <a class="header-anchor" href="#parameters" aria-label="Permalink to &quot;Parameters&quot;">​</a></h3><table tabindex="0"><thead><tr><th>Parameter</th><th>Required</th><th>Example</th><th>Description</th></tr></thead><tbody><tr><td>Operation</td><td>Yes</td><td><code>set</code></td><td>One of the five operations</td></tr><tr><td>Variable name</td><td>Yes</td><td><code>%love</code></td><td><code>%</code> starts a persistent variable, <code>$</code> starts a temporary variable</td></tr><tr><td>Value</td><td>Yes</td><td><code>10</code></td><td>Integer, float, boolean (<code>true</code>/<code>false</code>), or string wrapped in double quotes</td></tr></tbody></table><h3 id="examples" tabindex="-1">Examples <a class="header-anchor" href="#examples" aria-label="Permalink to &quot;Examples&quot;">​</a></h3><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span>set %love = 10</span></span>
<span class="line"><span>add %love 5</span></span>
<span class="line"><span>sub %love 3</span></span>
<span class="line"><span>mul %love 2</span></span>
<span class="line"><span>div %love 4</span></span>
<span class="line"><span></span></span>
<span class="line"><span>set $round = 1</span></span>
<span class="line"><span>add $round 1</span></span>
<span class="line"><span></span></span>
<span class="line"><span>set %player_name &quot;Player&quot;</span></span>
<span class="line"><span>set $stage &quot;Starter Village&quot;</span></span>
<span class="line"><span>set %unlocked true</span></span></code></pre></div><hr><h2 id="variable-interpolation" tabindex="-1">Variable Interpolation <a class="header-anchor" href="#variable-interpolation" aria-label="Permalink to &quot;Variable Interpolation&quot;">​</a></h2><p>Use <code>%variable_name</code> or <code>$variable_name</code> directly in dialogue text to reference a variable value. At runtime, it is replaced with the actual value.</p><h3 id="syntax" tabindex="-1">Syntax <a class="header-anchor" href="#syntax" aria-label="Permalink to &quot;Syntax&quot;">​</a></h3><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span>Kona &quot;Dialogue text containing %variable_name or $variable_name&quot;</span></span></code></pre></div><h3 id="examples-1" tabindex="-1">Examples <a class="header-anchor" href="#examples-1" aria-label="Permalink to &quot;Examples&quot;">​</a></h3><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span>set %player_name &quot;Alex&quot;</span></span>
<span class="line"><span>set $stage &quot;Starter Village&quot;</span></span>
<span class="line"><span></span></span>
<span class="line"><span>Kona &quot;Hello, %player_name! You are now in $stage.&quot;</span></span>
<span class="line"><span>Kona &quot;Your affection is %love, and this is round $round.&quot;</span></span></code></pre></div><p>Runtime output:</p><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span>Kona: &quot;Hello, Alex! You are now in Starter Village.&quot;</span></span>
<span class="line"><span>Kona: &quot;Your affection is 12, and this is round 2.&quot;</span></span></code></pre></div><hr><h2 id="conditional-checks" tabindex="-1">Conditional Checks <a class="header-anchor" href="#conditional-checks" aria-label="Permalink to &quot;Conditional Checks&quot;">​</a></h2><p>Use <code>if</code> / <code>else</code> / <code>endif</code> blocks to decide which dialogue to play based on variable values. Six comparison operators are supported.</p><h3 id="syntax-1" tabindex="-1">Syntax <a class="header-anchor" href="#syntax-1" aria-label="Permalink to &quot;Syntax&quot;">​</a></h3><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span>if &lt;variable_name&gt; &lt;operator&gt; &lt;value&gt;:</span></span>
<span class="line"><span>    &lt;dialogue content&gt;</span></span>
<span class="line"><span>else:</span></span>
<span class="line"><span>    &lt;dialogue content&gt;</span></span>
<span class="line"><span>endif</span></span></code></pre></div><p>The <code>else:</code> block is optional. If it is omitted and the condition is false, the whole <code>if</code> block is skipped.</p><h3 id="supported-operators" tabindex="-1">Supported Operators <a class="header-anchor" href="#supported-operators" aria-label="Permalink to &quot;Supported Operators&quot;">​</a></h3><table tabindex="0"><thead><tr><th>Operator</th><th>Description</th><th>Example</th></tr></thead><tbody><tr><td><code>==</code></td><td>Equal to</td><td><code>if %love == 5:</code></td></tr><tr><td><code>!=</code></td><td>Not equal to</td><td><code>if %love != 10:</code></td></tr><tr><td><code>&gt;</code></td><td>Greater than</td><td><code>if %love &gt; 3:</code></td></tr><tr><td><code>&lt;</code></td><td>Less than</td><td><code>if %love &lt; 10:</code></td></tr><tr><td><code>&gt;=</code></td><td>Greater than or equal to</td><td><code>if %love &gt;= 5:</code></td></tr><tr><td><code>&lt;=</code></td><td>Less than or equal to</td><td><code>if %love &lt;= 5:</code></td></tr></tbody></table><h3 id="parameters-1" tabindex="-1">Parameters <a class="header-anchor" href="#parameters-1" aria-label="Permalink to &quot;Parameters&quot;">​</a></h3><table tabindex="0"><thead><tr><th>Parameter</th><th>Required</th><th>Example</th><th>Description</th></tr></thead><tbody><tr><td>Variable name</td><td>Yes</td><td><code>%love</code></td><td>Persistent variable with <code>%</code> or temporary variable with <code>$</code></td></tr><tr><td>Operator</td><td>Yes</td><td><code>==</code></td><td>One of the six comparison operators</td></tr><tr><td>Value</td><td>Yes</td><td><code>5</code></td><td>Integer comparison value</td></tr></tbody></table><h3 id="examples-2" tabindex="-1">Examples <a class="header-anchor" href="#examples-2" aria-label="Permalink to &quot;Examples&quot;">​</a></h3><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span>if %love == 5:</span></span>
<span class="line"><span>    Kona &quot;Affection is exactly 5!&quot;</span></span>
<span class="line"><span>else:</span></span>
<span class="line"><span>    Kona &quot;Affection is not 5.&quot;</span></span>
<span class="line"><span>endif</span></span>
<span class="line"><span></span></span>
<span class="line"><span>if $score &gt;= 80:</span></span>
<span class="line"><span>    Kona &quot;Good!&quot;</span></span>
<span class="line"><span>endif</span></span>
<span class="line"><span></span></span>
<span class="line"><span>if $score &gt;= 60:</span></span>
<span class="line"><span>    Kona &quot;Passed.&quot;</span></span>
<span class="line"><span>endif</span></span></code></pre></div><h3 id="notes" tabindex="-1">Notes <a class="header-anchor" href="#notes" aria-label="Permalink to &quot;Notes&quot;">​</a></h3><ol><li><code>if</code> / <code>else</code> / <code>endif</code> must use the same indentation level as their surrounding context.</li><li>Conditional checks <strong>do not support nesting</strong>. An <code>if</code> block cannot contain another <code>if</code>.</li><li>Multiple independent conditions should use flat <code>if</code> / <code>endif</code> structures instead of nesting.</li><li>Conditional checks can be used inside <code>branch</code> blocks.</li></ol><hr><h2 id="using-conditions-inside-branches" tabindex="-1">Using Conditions Inside Branches <a class="header-anchor" href="#using-conditions-inside-branches" aria-label="Permalink to &quot;Using Conditions Inside Branches&quot;">​</a></h2><p>A <code>branch</code> block can contain <code>if</code> / <code>endif</code> conditional checks, allowing dynamic dialogue inside a branch.</p><h3 id="example" tabindex="-1">Example <a class="header-anchor" href="#example" aria-label="Permalink to &quot;Example&quot;">​</a></h3><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span>branch after_choice</span></span>
<span class="line"><span>    Kona &quot;Your choice has been recorded.&quot;</span></span>
<span class="line"><span></span></span>
<span class="line"><span>    if $choice_made == 1:</span></span>
<span class="line"><span>        Kona &quot;You chose to give a gift. That was kind of you.&quot;</span></span>
<span class="line"><span>    endif</span></span>
<span class="line"><span></span></span>
<span class="line"><span>    if $choice_made == 2:</span></span>
<span class="line"><span>        Kona &quot;You chose to chat. Communication matters.&quot;</span></span>
<span class="line"><span>    endif</span></span>
<span class="line"><span></span></span>
<span class="line"><span>    if $choice_made == 3:</span></span>
<span class="line"><span>        Kona &quot;You chose to ignore me... maybe try another option next time.&quot;</span></span>
<span class="line"><span>    endif</span></span></code></pre></div><hr><h2 id="linking-choices-with-variables" tabindex="-1">Linking Choices With Variables <a class="header-anchor" href="#linking-choices-with-variables" aria-label="Permalink to &quot;Linking Choices With Variables&quot;">​</a></h2><p>By combining <code>choice</code> and <code>branch</code>, you can modify variables after the player makes a choice, letting choices affect later story content.</p><h3 id="example-1" tabindex="-1">Example <a class="header-anchor" href="#example-1" aria-label="Permalink to &quot;Example&quot;">​</a></h3><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span>set $choice_made = 0</span></span>
<span class="line"><span></span></span>
<span class="line"><span>choice &quot;Give a gift (affection +10)&quot; -&gt; gift_choice</span></span>
<span class="line"><span>choice &quot;Chat (affection +5)&quot; -&gt; chat_choice</span></span>
<span class="line"><span>choice &quot;Ignore (affection -5)&quot; -&gt; ignore_choice</span></span>
<span class="line"><span></span></span>
<span class="line"><span>branch gift_choice</span></span>
<span class="line"><span>    add %love 10</span></span>
<span class="line"><span>    set $choice_made = 1</span></span>
<span class="line"><span>    Kona &quot;Thank you! Affection increased to %love!&quot;</span></span>
<span class="line"><span>    jump_branch after_choice</span></span>
<span class="line"><span></span></span>
<span class="line"><span>branch chat_choice</span></span>
<span class="line"><span>    add %love 5</span></span>
<span class="line"><span>    set $choice_made = 2</span></span>
<span class="line"><span>    Kona &quot;I enjoyed talking with you. Affection is now %love.&quot;</span></span>
<span class="line"><span>    jump_branch after_choice</span></span>
<span class="line"><span></span></span>
<span class="line"><span>branch ignore_choice</span></span>
<span class="line"><span>    sub %love 5</span></span>
<span class="line"><span>    set $choice_made = 3</span></span>
<span class="line"><span>    Kona &quot;......Affection dropped to %love.&quot;</span></span>
<span class="line"><span>    jump_branch after_choice</span></span>
<span class="line"><span></span></span>
<span class="line"><span>branch after_choice</span></span>
<span class="line"><span>    Kona &quot;Your choice has been recorded.&quot;</span></span></code></pre></div><hr><h2 id="boolean-variables" tabindex="-1">Boolean Variables <a class="header-anchor" href="#boolean-variables" aria-label="Permalink to &quot;Boolean Variables&quot;">​</a></h2><p>Variables support boolean values. Use <code>true</code> / <code>false</code> for assignment. In conditional checks, <code>true</code> is equivalent to <code>1</code>, and <code>false</code> is equivalent to <code>0</code>.</p><h3 id="example-2" tabindex="-1">Example <a class="header-anchor" href="#example-2" aria-label="Permalink to &quot;Example&quot;">​</a></h3><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span>set %unlocked true</span></span>
<span class="line"><span>set $visited false</span></span>
<span class="line"><span></span></span>
<span class="line"><span>if %unlocked == 1:</span></span>
<span class="line"><span>    Kona &quot;Feature unlocked!&quot;</span></span>
<span class="line"><span>endif</span></span>
<span class="line"><span></span></span>
<span class="line"><span>set $visited true</span></span>
<span class="line"><span>if $visited == 1:</span></span>
<span class="line"><span>    Kona &quot;The visited flag has been set.&quot;</span></span>
<span class="line"><span>endif</span></span></code></pre></div><hr><h2 id="variable-initialization" tabindex="-1">Variable Initialization <a class="header-anchor" href="#variable-initialization" aria-label="Permalink to &quot;Variable Initialization&quot;">​</a></h2><h3 id="persistent-variables" tabindex="-1">Persistent Variables (<code>%</code>) <a class="header-anchor" href="#persistent-variables" aria-label="Permalink to &quot;Persistent Variables (\`%\`)&quot;">​</a></h3><p>Persistent variables must be initialized before the script runs. There are two ways to do this:</p><p><strong>Method 1: Inspector preset (recommended)</strong></p><p>Create a <code>KonadoVariableStore</code> resource in the editor, set the initial variable values in the inspector, and assign it to the <code>variable_store</code> property of <code>KonadoDialogueManager</code>.</p><p><strong>Method 2: Code initialization</strong></p><div class="language-gdscript vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">gdscript</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">func</span><span style="--shiki-light:#6F42C1;--shiki-dark:#B392F0;"> _ready</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">() </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">-&gt;</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;"> void</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">:</span></span>
<span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">    if</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> dialogue_manager</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">.</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">variable_store </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">==</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> null</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">:</span></span>
<span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">        var</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> store </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#6F42C1;--shiki-dark:#B392F0;"> KonadoVariableStore</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">.</span><span style="--shiki-light:#6F42C1;--shiki-dark:#B392F0;">new</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">()</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">        store</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">.</span><span style="--shiki-light:#6F42C1;--shiki-dark:#B392F0;">set_value</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;love&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">0</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">        store</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">.</span><span style="--shiki-light:#6F42C1;--shiki-dark:#B392F0;">set_value</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;player_name&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">        store</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">.</span><span style="--shiki-light:#6F42C1;--shiki-dark:#B392F0;">set_value</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;unlocked&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">false</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">        dialogue_manager</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">.</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">variable_store </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> store</span></span></code></pre></div><h3 id="temporary-variables" tabindex="-1">Temporary Variables (<code>$</code>) <a class="header-anchor" href="#temporary-variables" aria-label="Permalink to &quot;Temporary Variables (\`$\`)&quot;">​</a></h3><p>Temporary variables do not need presets. They are created automatically the first time <code>set</code> is used in a script. They are reset automatically when switching shots.</p><hr><h2 id="complete-example" tabindex="-1">Complete Example <a class="header-anchor" href="#complete-example" aria-label="Permalink to &quot;Complete Example&quot;">​</a></h2><p>The following combined demo covers all variable features:</p><div class="language-text vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">text</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span>play bgm echo</span></span>
<span class="line"><span>background bg1 fade</span></span>
<span class="line"><span></span></span>
<span class="line"><span>actor show Kona Normal at 3</span></span>
<span class="line"><span>Kona &quot;Welcome to the variable system demo!&quot;</span></span>
<span class="line"><span></span></span>
<span class="line"><span>set %love = 10</span></span>
<span class="line"><span>Kona &quot;Affection has been set to 10. Current value: %love&quot;</span></span>
<span class="line"><span></span></span>
<span class="line"><span>add %love 5</span></span>
<span class="line"><span>Kona &quot;After adding 5, affection is: %love&quot;</span></span>
<span class="line"><span></span></span>
<span class="line"><span>sub %love 3</span></span>
<span class="line"><span>Kona &quot;After subtracting 3, affection is: %love&quot;</span></span>
<span class="line"><span></span></span>
<span class="line"><span>mul %love 2</span></span>
<span class="line"><span>Kona &quot;After multiplying by 2, affection is: %love&quot;</span></span>
<span class="line"><span></span></span>
<span class="line"><span>div %love 4</span></span>
<span class="line"><span>Kona &quot;After dividing by 4, affection is: %love&quot;</span></span>
<span class="line"><span></span></span>
<span class="line"><span>set $round = 1</span></span>
<span class="line"><span>set $bonus = 100</span></span>
<span class="line"><span>Kona &quot;round=$round, bonus=$bonus&quot;</span></span>
<span class="line"><span></span></span>
<span class="line"><span>add $round 1</span></span>
<span class="line"><span>add $bonus 50</span></span>
<span class="line"><span>Kona &quot;Round $round, bonus $bonus&quot;</span></span>
<span class="line"><span></span></span>
<span class="line"><span>set %player_name &quot;Player&quot;</span></span>
<span class="line"><span>Kona &quot;Hello, %player_name! Affection %love, round $round.&quot;</span></span>
<span class="line"><span></span></span>
<span class="line"><span>if %love == 6:</span></span>
<span class="line"><span>    Kona &quot;Affection is exactly 6!&quot;</span></span>
<span class="line"><span>else:</span></span>
<span class="line"><span>    Kona &quot;Affection is not 6.&quot;</span></span>
<span class="line"><span>endif</span></span>
<span class="line"><span></span></span>
<span class="line"><span>if %love &gt; 3:</span></span>
<span class="line"><span>    Kona &quot;Affection is greater than 3!&quot;</span></span>
<span class="line"><span>endif</span></span>
<span class="line"><span></span></span>
<span class="line"><span>if %love &lt; 10:</span></span>
<span class="line"><span>    Kona &quot;Affection is less than 10.&quot;</span></span>
<span class="line"><span>endif</span></span>
<span class="line"><span></span></span>
<span class="line"><span>set $score = 85</span></span>
<span class="line"><span></span></span>
<span class="line"><span>if $score &gt;= 90:</span></span>
<span class="line"><span>    Kona &quot;Excellent!&quot;</span></span>
<span class="line"><span>endif</span></span>
<span class="line"><span></span></span>
<span class="line"><span>if $score &gt;= 80:</span></span>
<span class="line"><span>    Kona &quot;Good!&quot;</span></span>
<span class="line"><span>endif</span></span>
<span class="line"><span></span></span>
<span class="line"><span>set %unlocked true</span></span>
<span class="line"><span>if %unlocked == 1:</span></span>
<span class="line"><span>    Kona &quot;Feature unlocked!&quot;</span></span>
<span class="line"><span>endif</span></span>
<span class="line"><span></span></span>
<span class="line"><span>choice &quot;Give a gift (affection +10)&quot; -&gt; gift</span></span>
<span class="line"><span>choice &quot;Ignore (affection -5)&quot; -&gt; ignore</span></span>
<span class="line"><span></span></span>
<span class="line"><span>branch gift</span></span>
<span class="line"><span>    add %love 10</span></span>
<span class="line"><span>    Kona &quot;Thank you! Affection %love!&quot;</span></span>
<span class="line"><span>    jump_branch done</span></span>
<span class="line"><span></span></span>
<span class="line"><span>branch ignore</span></span>
<span class="line"><span>    sub %love 5</span></span>
<span class="line"><span>    Kona &quot;......Affection %love.&quot;</span></span>
<span class="line"><span>    jump_branch done</span></span>
<span class="line"><span></span></span>
<span class="line"><span>branch done</span></span>
<span class="line"><span>    actor exit Kona</span></span>
<span class="line"><span>    background bg_end fade</span></span>
<span class="line"><span>    end</span></span></code></pre></div><hr><h2 id="notes-1" tabindex="-1">Notes <a class="header-anchor" href="#notes-1" aria-label="Permalink to &quot;Notes&quot;">​</a></h2><ol><li><strong>Variable names</strong> can contain only letters, numbers, and underscores, and are case-sensitive.</li><li><strong>Persistent variables</strong> (<code>%</code>) are saved with save data. They are suitable for cross-shot state such as affection values and story flags.</li><li><strong>Temporary variables</strong> (<code>$</code>) are cleared automatically when switching shots. They are suitable for temporary state inside the current shot.</li><li>A <strong>division operation</strong> with a zero divisor triggers an error and skips that operation.</li><li><strong>Conditional checks</strong> do not support nesting. Use flat <code>if</code> / <code>endif</code> structures for multiple conditions.</li><li>When using conditional checks inside a <code>branch</code> block, the indentation of <code>if</code> / <code>endif</code> must match other content inside the branch.</li><li>Uninitialized variables are treated as false in conditional checks.</li></ol>`,72)])])}const b=s(i,[["render",p]]);export{u as __pageData,b as default};
