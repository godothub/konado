import{_ as s,o as n,c as e,a5 as p}from"./chunks/framework.BEZBAInb.js";const u=JSON.parse('{"title":"変数システム","description":"","frontmatter":{"title":"変数システム","order":8},"headers":[],"relativePath":"ja/latest/tutorial/script/variable-system.md","filePath":"ja/latest/tutorial/script/variable-system.md","lastUpdated":1788455378000}'),t={name:"ja/latest/tutorial/script/variable-system.md"};function i(l,a,o,d,c,h){return n(),e("div",null,[...a[0]||(a[0]=[p(`<h1 id="変数システム" tabindex="-1">変数システム <a class="header-anchor" href="#変数システム" aria-label="Permalink to &quot;変数システム&quot;">​</a></h1><h2 id="機能概要" tabindex="-1">機能概要 <a class="header-anchor" href="#機能概要" aria-label="Permalink to &quot;機能概要&quot;">​</a></h2><p>変数システムを使うと、スクリプト内で変数の定義、読み取り、変更、判定を行えます。これにより、動的な会話文、条件分岐、状態追跡を実現できます。変数値は会話テキスト内で直接参照でき、条件判定の根拠としてストーリーの流れを制御することもできます。</p><p>変数には 2 種類あります。</p><table tabindex="0"><thead><tr><th>種類</th><th>接頭辞</th><th>ライフサイクル</th><th>永続化</th><th>初期化方法</th></tr></thead><tbody><tr><td>永続変数</td><td><code>%</code></td><td>ショットをまたいで保持</td><td>セーブデータと一緒に保存</td><td>インスペクターでプリセット / コードで初期化</td></tr><tr><td>一時変数</td><td><code>$</code></td><td>現在のショット内のみ有効</td><td>保存されない</td><td>スクリプト内の <code>set</code> で初期化</td></tr></tbody></table><hr><h2 id="変数操作" tabindex="-1">変数操作 <a class="header-anchor" href="#変数操作" aria-label="Permalink to &quot;変数操作&quot;">​</a></h2><p>5 種類の基本操作に対応しています。構文は次のとおりです。</p><div class="language-text vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">text</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span>&lt;操作&gt; &lt;変数名&gt; &lt;値&gt;</span></span></code></pre></div><p>等号を付けた形式も使用できます。</p><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span>&lt;操作&gt; &lt;変数名&gt; = &lt;値&gt;</span></span></code></pre></div><h3 id="操作一覧" tabindex="-1">操作一覧 <a class="header-anchor" href="#操作一覧" aria-label="Permalink to &quot;操作一覧&quot;">​</a></h3><table tabindex="0"><thead><tr><th>操作</th><th>説明</th><th>例</th></tr></thead><tbody><tr><td><code>set</code></td><td>変数値を設定します</td><td><code>set %love = 10</code></td></tr><tr><td><code>add</code></td><td>加算。数値の加算、または文字列の連結</td><td><code>add %love 5</code></td></tr><tr><td><code>sub</code></td><td>減算</td><td><code>sub %love 3</code></td></tr><tr><td><code>mul</code></td><td>乗算</td><td><code>mul %love 2</code></td></tr><tr><td><code>div</code></td><td>除算。除数が 0 の場合はエラー</td><td><code>div %love 4</code></td></tr></tbody></table><h3 id="引数の詳細" tabindex="-1">引数の詳細 <a class="header-anchor" href="#引数の詳細" aria-label="Permalink to &quot;引数の詳細&quot;">​</a></h3><table tabindex="0"><thead><tr><th>引数</th><th>必須</th><th>例</th><th>説明</th></tr></thead><tbody><tr><td>操作</td><td>はい</td><td><code>set</code></td><td>5 種類の操作のいずれか</td></tr><tr><td>変数名</td><td>はい</td><td><code>%love</code></td><td><code>%</code> で始まるものは永続変数、<code>$</code> で始まるものは一時変数</td></tr><tr><td>値</td><td>はい</td><td><code>10</code></td><td>整数、浮動小数点数、真偽値（<code>true</code>/<code>false</code>）、または二重引用符で囲んだ文字列</td></tr></tbody></table><h3 id="例" tabindex="-1">例 <a class="header-anchor" href="#例" aria-label="Permalink to &quot;例&quot;">​</a></h3><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span>set %love = 10</span></span>
<span class="line"><span>add %love 5</span></span>
<span class="line"><span>sub %love 3</span></span>
<span class="line"><span>mul %love 2</span></span>
<span class="line"><span>div %love 4</span></span>
<span class="line"><span></span></span>
<span class="line"><span>set $round = 1</span></span>
<span class="line"><span>add $round 1</span></span>
<span class="line"><span></span></span>
<span class="line"><span>set %player_name &quot;プレイヤー&quot;</span></span>
<span class="line"><span>set $stage &quot;はじまりの村&quot;</span></span>
<span class="line"><span>set %unlocked true</span></span></code></pre></div><hr><h2 id="変数の補間" tabindex="-1">変数の補間 <a class="header-anchor" href="#変数の補間" aria-label="Permalink to &quot;変数の補間&quot;">​</a></h2><p>会話テキスト内で <code>%変数名</code> または <code>$変数名</code> を直接使用すると、実行時に実際の値へ置き換えられます。</p><h3 id="構文" tabindex="-1">構文 <a class="header-anchor" href="#構文" aria-label="Permalink to &quot;構文&quot;">​</a></h3><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span>Kona &quot;会話テキスト。%変数名 または $変数名 を含められます&quot;</span></span></code></pre></div><h3 id="例-1" tabindex="-1">例 <a class="header-anchor" href="#例-1" aria-label="Permalink to &quot;例&quot;">​</a></h3><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span>set %player_name &quot;太郎&quot;</span></span>
<span class="line"><span>set $stage &quot;はじまりの村&quot;</span></span>
<span class="line"><span></span></span>
<span class="line"><span>Kona &quot;こんにちは、%player_name！今いる場所は $stage です。&quot;</span></span>
<span class="line"><span>Kona &quot;好感度は %love、現在は第 $round ラウンドです。&quot;</span></span></code></pre></div><p>実行時の出力:</p><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span>Kona: &quot;こんにちは、太郎！今いる場所は はじまりの村 です。&quot;</span></span>
<span class="line"><span>Kona: &quot;好感度は 12、現在は第 2 ラウンドです。&quot;</span></span></code></pre></div><hr><h2 id="条件判定" tabindex="-1">条件判定 <a class="header-anchor" href="#条件判定" aria-label="Permalink to &quot;条件判定&quot;">​</a></h2><p><code>if</code> / <code>else</code> / <code>endif</code> 構造を使い、変数値に応じて再生する会話を決定します。6 種類の比較演算子に対応しています。</p><h3 id="構文-1" tabindex="-1">構文 <a class="header-anchor" href="#構文-1" aria-label="Permalink to &quot;構文&quot;">​</a></h3><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span>if &lt;変数名&gt; &lt;演算子&gt; &lt;値&gt;:</span></span>
<span class="line"><span>    &lt;会話内容&gt;</span></span>
<span class="line"><span>else:</span></span>
<span class="line"><span>    &lt;会話内容&gt;</span></span>
<span class="line"><span>endif</span></span></code></pre></div><p><code>else:</code> ブロックは省略できます。省略した場合、条件が成立しなければ <code>if</code> ブロック全体がスキップされます。</p><h3 id="対応する演算子" tabindex="-1">対応する演算子 <a class="header-anchor" href="#対応する演算子" aria-label="Permalink to &quot;対応する演算子&quot;">​</a></h3><table tabindex="0"><thead><tr><th>演算子</th><th>説明</th><th>例</th></tr></thead><tbody><tr><td><code>==</code></td><td>等しい</td><td><code>if %love == 5:</code></td></tr><tr><td><code>!=</code></td><td>等しくない</td><td><code>if %love != 10:</code></td></tr><tr><td><code>&gt;</code></td><td>より大きい</td><td><code>if %love &gt; 3:</code></td></tr><tr><td><code>&lt;</code></td><td>より小さい</td><td><code>if %love &lt; 10:</code></td></tr><tr><td><code>&gt;=</code></td><td>以上</td><td><code>if %love &gt;= 5:</code></td></tr><tr><td><code>&lt;=</code></td><td>以下</td><td><code>if %love &lt;= 5:</code></td></tr></tbody></table><h3 id="引数の詳細-1" tabindex="-1">引数の詳細 <a class="header-anchor" href="#引数の詳細-1" aria-label="Permalink to &quot;引数の詳細&quot;">​</a></h3><table tabindex="0"><thead><tr><th>引数</th><th>必須</th><th>例</th><th>説明</th></tr></thead><tbody><tr><td>変数名</td><td>はい</td><td><code>%love</code></td><td><code>%</code> の永続変数、または <code>$</code> の一時変数</td></tr><tr><td>演算子</td><td>はい</td><td><code>==</code></td><td>6 種類の比較演算子のいずれか</td></tr><tr><td>値</td><td>はい</td><td><code>5</code></td><td>比較に使用する整数値</td></tr></tbody></table><h3 id="例-2" tabindex="-1">例 <a class="header-anchor" href="#例-2" aria-label="Permalink to &quot;例&quot;">​</a></h3><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span>if %love == 5:</span></span>
<span class="line"><span>    Kona &quot;好感度はちょうど 5 です！&quot;</span></span>
<span class="line"><span>else:</span></span>
<span class="line"><span>    Kona &quot;好感度は 5 ではありません。&quot;</span></span>
<span class="line"><span>endif</span></span>
<span class="line"><span></span></span>
<span class="line"><span>if $score &gt;= 80:</span></span>
<span class="line"><span>    Kona &quot;良好です！&quot;</span></span>
<span class="line"><span>endif</span></span>
<span class="line"><span></span></span>
<span class="line"><span>if $score &gt;= 60:</span></span>
<span class="line"><span>    Kona &quot;合格です。&quot;</span></span>
<span class="line"><span>endif</span></span></code></pre></div><h3 id="注意事項" tabindex="-1">注意事項 <a class="header-anchor" href="#注意事項" aria-label="Permalink to &quot;注意事項&quot;">​</a></h3><ol><li><code>if</code> / <code>else</code> / <code>endif</code> は、周囲のコンテキストと同じインデント階層にしてください。</li><li>条件判定は<strong>ネストに対応していません</strong>。つまり、<code>if</code> ブロック内にさらに <code>if</code> を含めることはできません。</li><li>複数の独立した条件判定は、ネストではなく平坦な <code>if</code> / <code>endif</code> 構造で記述してください。</li><li>条件判定は <code>branch</code> ブロック内でも使用できます。</li></ol><hr><h2 id="分岐内で条件判定を使う" tabindex="-1">分岐内で条件判定を使う <a class="header-anchor" href="#分岐内で条件判定を使う" aria-label="Permalink to &quot;分岐内で条件判定を使う&quot;">​</a></h2><p><code>branch</code> ブロック内には <code>if</code> / <code>endif</code> 条件判定を含められます。これにより、分岐内でも動的な会話を実現できます。</p><h3 id="例-3" tabindex="-1">例 <a class="header-anchor" href="#例-3" aria-label="Permalink to &quot;例&quot;">​</a></h3><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span>branch after_choice</span></span>
<span class="line"><span>    Kona &quot;あなたの選択は記録されました。&quot;</span></span>
<span class="line"><span></span></span>
<span class="line"><span>    if $choice_made == 1:</span></span>
<span class="line"><span>        Kona &quot;プレゼントを贈ることを選びましたね。優しいですね。&quot;</span></span>
<span class="line"><span>    endif</span></span>
<span class="line"><span></span></span>
<span class="line"><span>    if $choice_made == 2:</span></span>
<span class="line"><span>        Kona &quot;会話することを選びましたね。コミュニケーションは大切です。&quot;</span></span>
<span class="line"><span>    endif</span></span>
<span class="line"><span></span></span>
<span class="line"><span>    if $choice_made == 3:</span></span>
<span class="line"><span>        Kona &quot;無視することを選びました……次は別の選択肢も試してみてください。&quot;</span></span>
<span class="line"><span>    endif</span></span></code></pre></div><hr><h2 id="選択肢と変数の連動" tabindex="-1">選択肢と変数の連動 <a class="header-anchor" href="#選択肢と変数の連動" aria-label="Permalink to &quot;選択肢と変数の連動&quot;">​</a></h2><p><code>choice</code> と <code>branch</code> を組み合わせると、ユーザーが選択した後に変数値を変更できます。これにより、選択が後続のストーリーに影響するようになります。</p><h3 id="例-4" tabindex="-1">例 <a class="header-anchor" href="#例-4" aria-label="Permalink to &quot;例&quot;">​</a></h3><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span>set $choice_made = 0</span></span>
<span class="line"><span></span></span>
<span class="line"><span>choice &quot;プレゼントを贈る（好感度+10）&quot; -&gt; gift_choice</span></span>
<span class="line"><span>choice &quot;会話する（好感度+5）&quot; -&gt; chat_choice</span></span>
<span class="line"><span>choice &quot;無視する（好感度-5）&quot; -&gt; ignore_choice</span></span>
<span class="line"><span></span></span>
<span class="line"><span>branch gift_choice</span></span>
<span class="line"><span>    add %love 10</span></span>
<span class="line"><span>    set $choice_made = 1</span></span>
<span class="line"><span>    Kona &quot;ありがとうございます！好感度が %love まで上がりました！&quot;</span></span>
<span class="line"><span>    jump_branch after_choice</span></span>
<span class="line"><span></span></span>
<span class="line"><span>branch chat_choice</span></span>
<span class="line"><span>    add %love 5</span></span>
<span class="line"><span>    set $choice_made = 2</span></span>
<span class="line"><span>    Kona &quot;あなたと話せて楽しかったです。今の好感度は %love です。&quot;</span></span>
<span class="line"><span>    jump_branch after_choice</span></span>
<span class="line"><span></span></span>
<span class="line"><span>branch ignore_choice</span></span>
<span class="line"><span>    sub %love 5</span></span>
<span class="line"><span>    set $choice_made = 3</span></span>
<span class="line"><span>    Kona &quot;……好感度が %love まで下がりました。&quot;</span></span>
<span class="line"><span>    jump_branch after_choice</span></span>
<span class="line"><span></span></span>
<span class="line"><span>branch after_choice</span></span>
<span class="line"><span>    Kona &quot;あなたの選択は記録されました。&quot;</span></span></code></pre></div><hr><h2 id="真偽値変数" tabindex="-1">真偽値変数 <a class="header-anchor" href="#真偽値変数" aria-label="Permalink to &quot;真偽値変数&quot;">​</a></h2><p>変数は真偽値に対応しています。代入には <code>true</code> / <code>false</code> を使用します。条件判定では、<code>true</code> は <code>1</code>、<code>false</code> は <code>0</code> と同等です。</p><h3 id="例-5" tabindex="-1">例 <a class="header-anchor" href="#例-5" aria-label="Permalink to &quot;例&quot;">​</a></h3><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span>set %unlocked true</span></span>
<span class="line"><span>set $visited false</span></span>
<span class="line"><span></span></span>
<span class="line"><span>if %unlocked == 1:</span></span>
<span class="line"><span>    Kona &quot;機能がアンロックされました！&quot;</span></span>
<span class="line"><span>endif</span></span>
<span class="line"><span></span></span>
<span class="line"><span>set $visited true</span></span>
<span class="line"><span>if $visited == 1:</span></span>
<span class="line"><span>    Kona &quot;訪問済みフラグが設定されました。&quot;</span></span>
<span class="line"><span>endif</span></span></code></pre></div><hr><h2 id="変数の初期化" tabindex="-1">変数の初期化 <a class="header-anchor" href="#変数の初期化" aria-label="Permalink to &quot;変数の初期化&quot;">​</a></h2><h3 id="永続変数" tabindex="-1">永続変数（%） <a class="header-anchor" href="#永続変数" aria-label="Permalink to &quot;永続変数（%）&quot;">​</a></h3><p>永続変数は、スクリプト実行前に初期化する必要があります。方法は 2 つあります。</p><p><strong>方法 1: インスペクターでプリセット（推奨）</strong></p><p>エディターで <code>KonadoVariableStore</code> リソースを作成し、インスペクターで初期変数値を設定してから、<code>KonadoDialogueManager</code> の <code>variable_store</code> プロパティへ割り当てます。</p><p><strong>方法 2: コードで初期化</strong></p><div class="language-gdscript vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">gdscript</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">func</span><span style="--shiki-light:#6F42C1;--shiki-dark:#B392F0;"> _ready</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">() </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">-&gt;</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;"> void</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">:</span></span>
<span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">    if</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> dialogue_manager</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">.</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">variable_store </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">==</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> null</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">:</span></span>
<span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">        var</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> store </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#6F42C1;--shiki-dark:#B392F0;"> KonadoVariableStore</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">.</span><span style="--shiki-light:#6F42C1;--shiki-dark:#B392F0;">new</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">()</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">        store</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">.</span><span style="--shiki-light:#6F42C1;--shiki-dark:#B392F0;">set_value</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;love&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">0</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">        store</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">.</span><span style="--shiki-light:#6F42C1;--shiki-dark:#B392F0;">set_value</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;player_name&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">        store</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">.</span><span style="--shiki-light:#6F42C1;--shiki-dark:#B392F0;">set_value</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;unlocked&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">false</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">        dialogue_manager</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">.</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">variable_store </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> store</span></span></code></pre></div><h3 id="一時変数" tabindex="-1">一時変数（$） <a class="header-anchor" href="#一時変数" aria-label="Permalink to &quot;一時変数（$）&quot;">​</a></h3><p>一時変数にプリセットは不要です。スクリプト内で初めて <code>set</code> を使用したときに自動作成されます。ショットを切り替えると自動的にリセットされます。</p><hr><h2 id="完全な例" tabindex="-1">完全な例 <a class="header-anchor" href="#完全な例" aria-label="Permalink to &quot;完全な例&quot;">​</a></h2><p>次は、すべての変数機能を含む総合デモです。</p><div class="language-text vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">text</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span>play bgm echo</span></span>
<span class="line"><span>background bg1 fade</span></span>
<span class="line"><span></span></span>
<span class="line"><span>actor show コナ 通常 at 3</span></span>
<span class="line"><span>Kona &quot;変数システムのデモへようこそ！&quot;</span></span>
<span class="line"><span></span></span>
<span class="line"><span>set %love = 10</span></span>
<span class="line"><span>Kona &quot;好感度を 10 に設定しました。現在の値：%love&quot;</span></span>
<span class="line"><span></span></span>
<span class="line"><span>add %love 5</span></span>
<span class="line"><span>Kona &quot;5 を加えた後の好感度：%love&quot;</span></span>
<span class="line"><span></span></span>
<span class="line"><span>sub %love 3</span></span>
<span class="line"><span>Kona &quot;3 を引いた後の好感度：%love&quot;</span></span>
<span class="line"><span></span></span>
<span class="line"><span>mul %love 2</span></span>
<span class="line"><span>Kona &quot;2 を掛けた後の好感度：%love&quot;</span></span>
<span class="line"><span></span></span>
<span class="line"><span>div %love 4</span></span>
<span class="line"><span>Kona &quot;4 で割った後の好感度：%love&quot;</span></span>
<span class="line"><span></span></span>
<span class="line"><span>set $round = 1</span></span>
<span class="line"><span>set $bonus = 100</span></span>
<span class="line"><span>Kona &quot;ラウンド=$round、ボーナス=$bonus&quot;</span></span>
<span class="line"><span></span></span>
<span class="line"><span>add $round 1</span></span>
<span class="line"><span>add $bonus 50</span></span>
<span class="line"><span>Kona &quot;第 $round ラウンド、ボーナス $bonus&quot;</span></span>
<span class="line"><span></span></span>
<span class="line"><span>set %player_name &quot;プレイヤー&quot;</span></span>
<span class="line"><span>Kona &quot;こんにちは、%player_name！好感度 %love、第 $round ラウンドです。&quot;</span></span>
<span class="line"><span></span></span>
<span class="line"><span>if %love == 6:</span></span>
<span class="line"><span>    Kona &quot;好感度はちょうど 6 です！&quot;</span></span>
<span class="line"><span>else:</span></span>
<span class="line"><span>    Kona &quot;好感度は 6 ではありません。&quot;</span></span>
<span class="line"><span>endif</span></span>
<span class="line"><span></span></span>
<span class="line"><span>if %love &gt; 3:</span></span>
<span class="line"><span>    Kona &quot;好感度は 3 より大きいです！&quot;</span></span>
<span class="line"><span>endif</span></span>
<span class="line"><span></span></span>
<span class="line"><span>if %love &lt; 10:</span></span>
<span class="line"><span>    Kona &quot;好感度は 10 より小さいです。&quot;</span></span>
<span class="line"><span>endif</span></span>
<span class="line"><span></span></span>
<span class="line"><span>set $score = 85</span></span>
<span class="line"><span></span></span>
<span class="line"><span>if $score &gt;= 90:</span></span>
<span class="line"><span>    Kona &quot;優秀です！&quot;</span></span>
<span class="line"><span>endif</span></span>
<span class="line"><span></span></span>
<span class="line"><span>if $score &gt;= 80:</span></span>
<span class="line"><span>    Kona &quot;良好です！&quot;</span></span>
<span class="line"><span>endif</span></span>
<span class="line"><span></span></span>
<span class="line"><span>set %unlocked true</span></span>
<span class="line"><span>if %unlocked == 1:</span></span>
<span class="line"><span>    Kona &quot;機能がアンロックされました！&quot;</span></span>
<span class="line"><span>endif</span></span>
<span class="line"><span></span></span>
<span class="line"><span>choice &quot;プレゼントを贈る（好感度+10）&quot; -&gt; gift</span></span>
<span class="line"><span>choice &quot;無視する（好感度-5）&quot; -&gt; ignore</span></span>
<span class="line"><span></span></span>
<span class="line"><span>branch gift</span></span>
<span class="line"><span>    add %love 10</span></span>
<span class="line"><span>    Kona &quot;ありがとうございます！好感度 %love！&quot;</span></span>
<span class="line"><span>    jump_branch done</span></span>
<span class="line"><span></span></span>
<span class="line"><span>branch ignore</span></span>
<span class="line"><span>    sub %love 5</span></span>
<span class="line"><span>    Kona &quot;……好感度 %love。&quot;</span></span>
<span class="line"><span>    jump_branch done</span></span>
<span class="line"><span></span></span>
<span class="line"><span>branch done</span></span>
<span class="line"><span>    actor exit コナ</span></span>
<span class="line"><span>    background bg_end fade</span></span>
<span class="line"><span>    end</span></span></code></pre></div><hr><h2 id="注意事項-1" tabindex="-1">注意事項 <a class="header-anchor" href="#注意事項-1" aria-label="Permalink to &quot;注意事項&quot;">​</a></h2><ol><li><strong>変数名</strong>には英字、数字、アンダースコアのみ使用でき、大文字と小文字は区別されます。</li><li><strong>永続変数</strong>（<code>%</code>）の値はセーブデータと一緒に保存されます。好感度やストーリーフラグなど、ショットをまたぐ状態の記録に適しています。</li><li><strong>一時変数</strong>（<code>$</code>）はショットを切り替えると自動的に消去されます。現在のショット内だけで使う一時状態の記録に適しています。</li><li><strong>除算操作</strong>で除数が 0 の場合はエラーが発生し、その操作はスキップされます。</li><li><strong>条件判定</strong>はネストに対応していません。複数の条件は平坦な <code>if</code> / <code>endif</code> 構造で記述してください。</li><li><code>branch</code> ブロック内で条件判定を使う場合、<code>if</code> / <code>endif</code> のインデントは分岐内の他の内容と一致させてください。</li><li>初期化されていない変数は、条件判定では条件不成立として扱われます。</li></ol>`,72)])])}const k=s(t,[["render",i]]);export{u as __pageData,k as default};
