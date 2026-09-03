import{_ as s,o as n,c as e,a5 as p}from"./chunks/framework.BEZBAInb.js";const u=JSON.parse('{"title":"변수 시스템","description":"","frontmatter":{"title":"변수 시스템","order":8},"headers":[],"relativePath":"ko/latest/tutorial/script/variable-system.md","filePath":"ko/latest/tutorial/script/variable-system.md","lastUpdated":1788455378000}'),t={name:"ko/latest/tutorial/script/variable-system.md"};function i(l,a,o,d,c,h){return n(),e("div",null,[...a[0]||(a[0]=[p(`<h1 id="변수-시스템" tabindex="-1">변수 시스템 <a class="header-anchor" href="#변수-시스템" aria-label="Permalink to &quot;변수 시스템&quot;">​</a></h1><h2 id="기능-개요" tabindex="-1">기능 개요 <a class="header-anchor" href="#기능-개요" aria-label="Permalink to &quot;기능 개요&quot;">​</a></h2><p>변수 시스템을 사용하면 스크립트 안에서 변수를 정의하고, 읽고, 수정하고, 판단할 수 있습니다. 이를 통해 동적인 대사 내용, 조건 분기, 상태 추적을 구현할 수 있습니다. 변수 값은 대사 텍스트 안에서 직접 참조할 수 있으며, 조건 판단의 기준으로 사용해 이야기 흐름을 제어할 수도 있습니다.</p><p>변수는 두 종류로 나뉩니다.</p><table tabindex="0"><thead><tr><th>타입</th><th>접두사</th><th>생명 주기</th><th>영속화</th><th>초기화 방식</th></tr></thead><tbody><tr><td>영구 변수</td><td><code>%</code></td><td>샷을 넘어 유지</td><td>세이브 데이터와 함께 저장</td><td>인스펙터에서 미리 설정 / 코드로 초기화</td></tr><tr><td>임시 변수</td><td><code>$</code></td><td>현재 샷에서만 유효</td><td>저장하지 않음</td><td>스크립트 안에서 <code>set</code>으로 초기화</td></tr></tbody></table><hr><h2 id="변수-조작" tabindex="-1">변수 조작 <a class="header-anchor" href="#변수-조작" aria-label="Permalink to &quot;변수 조작&quot;">​</a></h2><p>다섯 가지 기본 조작을 지원합니다. 문법 형식은 다음과 같습니다.</p><div class="language-text vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">text</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span>&lt;조작&gt; &lt;변수명&gt; &lt;값&gt;</span></span></code></pre></div><p>등호를 넣은 형식도 사용할 수 있습니다.</p><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span>&lt;조작&gt; &lt;변수명&gt; = &lt;값&gt;</span></span></code></pre></div><h3 id="조작-목록" tabindex="-1">조작 목록 <a class="header-anchor" href="#조작-목록" aria-label="Permalink to &quot;조작 목록&quot;">​</a></h3><table tabindex="0"><thead><tr><th>조작</th><th>설명</th><th>예시</th></tr></thead><tbody><tr><td><code>set</code></td><td>변수 값을 설정합니다</td><td><code>set %love = 10</code></td></tr><tr><td><code>add</code></td><td>덧셈. 숫자 덧셈 또는 문자열 연결</td><td><code>add %love 5</code></td></tr><tr><td><code>sub</code></td><td>뺄셈</td><td><code>sub %love 3</code></td></tr><tr><td><code>mul</code></td><td>곱셈</td><td><code>mul %love 2</code></td></tr><tr><td><code>div</code></td><td>나눗셈. 0으로 나누면 오류가 발생합니다</td><td><code>div %love 4</code></td></tr></tbody></table><h3 id="매개변수-상세" tabindex="-1">매개변수 상세 <a class="header-anchor" href="#매개변수-상세" aria-label="Permalink to &quot;매개변수 상세&quot;">​</a></h3><table tabindex="0"><thead><tr><th>매개변수</th><th>필수</th><th>예시</th><th>설명</th></tr></thead><tbody><tr><td>조작</td><td>예</td><td><code>set</code></td><td>다섯 가지 조작 중 하나</td></tr><tr><td>변수명</td><td>예</td><td><code>%love</code></td><td><code>%</code>로 시작하면 영구 변수, <code>$</code>로 시작하면 임시 변수</td></tr><tr><td>값</td><td>예</td><td><code>10</code></td><td>정수, 실수, 불리언(<code>true</code>/<code>false</code>) 또는 큰따옴표로 감싼 문자열</td></tr></tbody></table><h3 id="예시" tabindex="-1">예시 <a class="header-anchor" href="#예시" aria-label="Permalink to &quot;예시&quot;">​</a></h3><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span>set %love = 10</span></span>
<span class="line"><span>add %love 5</span></span>
<span class="line"><span>sub %love 3</span></span>
<span class="line"><span>mul %love 2</span></span>
<span class="line"><span>div %love 4</span></span>
<span class="line"><span></span></span>
<span class="line"><span>set $round = 1</span></span>
<span class="line"><span>add $round 1</span></span>
<span class="line"><span></span></span>
<span class="line"><span>set %player_name &quot;플레이어&quot;</span></span>
<span class="line"><span>set $stage &quot;초보자 마을&quot;</span></span>
<span class="line"><span>set %unlocked true</span></span></code></pre></div><hr><h2 id="변수-보간" tabindex="-1">변수 보간 <a class="header-anchor" href="#변수-보간" aria-label="Permalink to &quot;변수 보간&quot;">​</a></h2><p>대사 텍스트 안에서 <code>%변수명</code> 또는 <code>$변수명</code>을 직접 사용하면, 실행 시 실제 값으로 치환됩니다.</p><h3 id="문법" tabindex="-1">문법 <a class="header-anchor" href="#문법" aria-label="Permalink to &quot;문법&quot;">​</a></h3><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span>Kona &quot;대사 텍스트. %변수명 또는 $변수명을 포함할 수 있습니다&quot;</span></span></code></pre></div><h3 id="예시-1" tabindex="-1">예시 <a class="header-anchor" href="#예시-1" aria-label="Permalink to &quot;예시&quot;">​</a></h3><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span>set %player_name &quot;민수&quot;</span></span>
<span class="line"><span>set $stage &quot;초보자 마을&quot;</span></span>
<span class="line"><span></span></span>
<span class="line"><span>Kona &quot;안녕하세요, %player_name! 지금 있는 곳은 $stage입니다.&quot;</span></span>
<span class="line"><span>Kona &quot;호감도는 %love이고, 현재는 $round 라운드입니다.&quot;</span></span></code></pre></div><p>실행 시 출력:</p><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span>Kona: &quot;안녕하세요, 민수! 지금 있는 곳은 초보자 마을입니다.&quot;</span></span>
<span class="line"><span>Kona: &quot;호감도는 12이고, 현재는 2 라운드입니다.&quot;</span></span></code></pre></div><hr><h2 id="조건-판단" tabindex="-1">조건 판단 <a class="header-anchor" href="#조건-판단" aria-label="Permalink to &quot;조건 판단&quot;">​</a></h2><p><code>if</code> / <code>else</code> / <code>endif</code> 구조를 사용해 변수 값에 따라 어떤 대사를 재생할지 결정합니다. 여섯 가지 비교 연산자를 지원합니다.</p><h3 id="문법-구조" tabindex="-1">문법 구조 <a class="header-anchor" href="#문법-구조" aria-label="Permalink to &quot;문법 구조&quot;">​</a></h3><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span>if &lt;변수명&gt; &lt;연산자&gt; &lt;값&gt;:</span></span>
<span class="line"><span>    &lt;대사 내용&gt;</span></span>
<span class="line"><span>else:</span></span>
<span class="line"><span>    &lt;대사 내용&gt;</span></span>
<span class="line"><span>endif</span></span></code></pre></div><p><code>else:</code> 블록은 선택 사항입니다. 생략했을 때 조건이 성립하지 않으면 전체 <code>if</code> 블록을 건너뜁니다.</p><h3 id="지원-연산자" tabindex="-1">지원 연산자 <a class="header-anchor" href="#지원-연산자" aria-label="Permalink to &quot;지원 연산자&quot;">​</a></h3><table tabindex="0"><thead><tr><th>연산자</th><th>설명</th><th>예시</th></tr></thead><tbody><tr><td><code>==</code></td><td>같음</td><td><code>if %love == 5:</code></td></tr><tr><td><code>!=</code></td><td>같지 않음</td><td><code>if %love != 10:</code></td></tr><tr><td><code>&gt;</code></td><td>큼</td><td><code>if %love &gt; 3:</code></td></tr><tr><td><code>&lt;</code></td><td>작음</td><td><code>if %love &lt; 10:</code></td></tr><tr><td><code>&gt;=</code></td><td>크거나 같음</td><td><code>if %love &gt;= 5:</code></td></tr><tr><td><code>&lt;=</code></td><td>작거나 같음</td><td><code>if %love &lt;= 5:</code></td></tr></tbody></table><h3 id="매개변수-상세-1" tabindex="-1">매개변수 상세 <a class="header-anchor" href="#매개변수-상세-1" aria-label="Permalink to &quot;매개변수 상세&quot;">​</a></h3><table tabindex="0"><thead><tr><th>매개변수</th><th>필수</th><th>예시</th><th>설명</th></tr></thead><tbody><tr><td>변수명</td><td>예</td><td><code>%love</code></td><td><code>%</code> 영구 변수 또는 <code>$</code> 임시 변수</td></tr><tr><td>연산자</td><td>예</td><td><code>==</code></td><td>여섯 가지 비교 연산자 중 하나</td></tr><tr><td>값</td><td>예</td><td><code>5</code></td><td>비교에 사용할 정수 값</td></tr></tbody></table><h3 id="예시-2" tabindex="-1">예시 <a class="header-anchor" href="#예시-2" aria-label="Permalink to &quot;예시&quot;">​</a></h3><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span>if %love == 5:</span></span>
<span class="line"><span>    Kona &quot;호감도가 정확히 5입니다!&quot;</span></span>
<span class="line"><span>else:</span></span>
<span class="line"><span>    Kona &quot;호감도가 5가 아닙니다.&quot;</span></span>
<span class="line"><span>endif</span></span>
<span class="line"><span></span></span>
<span class="line"><span>if $score &gt;= 80:</span></span>
<span class="line"><span>    Kona &quot;좋습니다!&quot;</span></span>
<span class="line"><span>endif</span></span>
<span class="line"><span></span></span>
<span class="line"><span>if $score &gt;= 60:</span></span>
<span class="line"><span>    Kona &quot;합격입니다.&quot;</span></span>
<span class="line"><span>endif</span></span></code></pre></div><h3 id="주의-사항" tabindex="-1">주의 사항 <a class="header-anchor" href="#주의-사항" aria-label="Permalink to &quot;주의 사항&quot;">​</a></h3><ol><li><code>if</code> / <code>else</code> / <code>endif</code>는 현재 문맥과 같은 들여쓰기 수준에 있어야 합니다.</li><li>조건 판단은 <strong>중첩을 지원하지 않습니다</strong>. 즉, <code>if</code> 블록 안에 다시 <code>if</code>를 넣을 수 없습니다.</li><li>여러 개의 독립 조건은 중첩하지 말고 평평한 <code>if</code> / <code>endif</code> 구조로 작성해야 합니다.</li><li>조건 판단은 <code>branch</code> 분기 블록 안에서도 사용할 수 있습니다.</li></ol><hr><h2 id="분기-안에서-조건-판단-사용" tabindex="-1">분기 안에서 조건 판단 사용 <a class="header-anchor" href="#분기-안에서-조건-판단-사용" aria-label="Permalink to &quot;분기 안에서 조건 판단 사용&quot;">​</a></h2><p><code>branch</code> 블록 안에는 <code>if</code> / <code>endif</code> 조건 판단을 포함할 수 있습니다. 이를 통해 분기 안에서도 동적인 대사를 만들 수 있습니다.</p><h3 id="예시-3" tabindex="-1">예시 <a class="header-anchor" href="#예시-3" aria-label="Permalink to &quot;예시&quot;">​</a></h3><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span>branch after_choice</span></span>
<span class="line"><span>    Kona &quot;당신의 선택이 기록되었습니다.&quot;</span></span>
<span class="line"><span></span></span>
<span class="line"><span>    if $choice_made == 1:</span></span>
<span class="line"><span>        Kona &quot;선물을 주기로 했군요. 정말 다정하네요.&quot;</span></span>
<span class="line"><span>    endif</span></span>
<span class="line"><span></span></span>
<span class="line"><span>    if $choice_made == 2:</span></span>
<span class="line"><span>        Kona &quot;대화하기로 했군요. 소통은 중요합니다.&quot;</span></span>
<span class="line"><span>    endif</span></span>
<span class="line"><span></span></span>
<span class="line"><span>    if $choice_made == 3:</span></span>
<span class="line"><span>        Kona &quot;무시하기로 했군요... 다음에는 다른 선택지도 시도해 보세요.&quot;</span></span>
<span class="line"><span>    endif</span></span></code></pre></div><hr><h2 id="선택지와-변수-연동" tabindex="-1">선택지와 변수 연동 <a class="header-anchor" href="#선택지와-변수-연동" aria-label="Permalink to &quot;선택지와 변수 연동&quot;">​</a></h2><p><code>choice</code>와 <code>branch</code>를 조합하면 사용자가 선택한 뒤 변수 값을 수정할 수 있으며, 선택이 이후 이야기 전개에 영향을 주도록 만들 수 있습니다.</p><h3 id="예시-4" tabindex="-1">예시 <a class="header-anchor" href="#예시-4" aria-label="Permalink to &quot;예시&quot;">​</a></h3><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span>set $choice_made = 0</span></span>
<span class="line"><span></span></span>
<span class="line"><span>choice &quot;선물하기(호감도+10)&quot; -&gt; gift_choice</span></span>
<span class="line"><span>choice &quot;대화하기(호감도+5)&quot; -&gt; chat_choice</span></span>
<span class="line"><span>choice &quot;무시하기(호감도-5)&quot; -&gt; ignore_choice</span></span>
<span class="line"><span></span></span>
<span class="line"><span>branch gift_choice</span></span>
<span class="line"><span>    add %love 10</span></span>
<span class="line"><span>    set $choice_made = 1</span></span>
<span class="line"><span>    Kona &quot;고마워요! 호감도가 %love까지 올랐어요!&quot;</span></span>
<span class="line"><span>    jump_branch after_choice</span></span>
<span class="line"><span></span></span>
<span class="line"><span>branch chat_choice</span></span>
<span class="line"><span>    add %love 5</span></span>
<span class="line"><span>    set $choice_made = 2</span></span>
<span class="line"><span>    Kona &quot;당신과 이야기해서 즐거웠어요. 지금 호감도는 %love입니다.&quot;</span></span>
<span class="line"><span>    jump_branch after_choice</span></span>
<span class="line"><span></span></span>
<span class="line"><span>branch ignore_choice</span></span>
<span class="line"><span>    sub %love 5</span></span>
<span class="line"><span>    set $choice_made = 3</span></span>
<span class="line"><span>    Kona &quot;......호감도가 %love까지 내려갔어요.&quot;</span></span>
<span class="line"><span>    jump_branch after_choice</span></span>
<span class="line"><span></span></span>
<span class="line"><span>branch after_choice</span></span>
<span class="line"><span>    Kona &quot;당신의 선택이 기록되었습니다.&quot;</span></span></code></pre></div><hr><h2 id="불리언-변수" tabindex="-1">불리언 변수 <a class="header-anchor" href="#불리언-변수" aria-label="Permalink to &quot;불리언 변수&quot;">​</a></h2><p>변수는 불리언 타입을 지원하며, <code>true</code> / <code>false</code>로 값을 대입합니다. 조건 판단에서는 <code>true</code>가 <code>1</code>, <code>false</code>가 <code>0</code>과 같습니다.</p><h3 id="예시-5" tabindex="-1">예시 <a class="header-anchor" href="#예시-5" aria-label="Permalink to &quot;예시&quot;">​</a></h3><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span>set %unlocked true</span></span>
<span class="line"><span>set $visited false</span></span>
<span class="line"><span></span></span>
<span class="line"><span>if %unlocked == 1:</span></span>
<span class="line"><span>    Kona &quot;기능이 잠금 해제되었습니다!&quot;</span></span>
<span class="line"><span>endif</span></span>
<span class="line"><span></span></span>
<span class="line"><span>set $visited true</span></span>
<span class="line"><span>if $visited == 1:</span></span>
<span class="line"><span>    Kona &quot;방문 플래그가 설정되었습니다.&quot;</span></span>
<span class="line"><span>endif</span></span></code></pre></div><hr><h2 id="변수-초기화" tabindex="-1">변수 초기화 <a class="header-anchor" href="#변수-초기화" aria-label="Permalink to &quot;변수 초기화&quot;">​</a></h2><h3 id="영구-변수" tabindex="-1">영구 변수(<code>%</code>) <a class="header-anchor" href="#영구-변수" aria-label="Permalink to &quot;영구 변수(\`%\`)&quot;">​</a></h3><p>영구 변수는 스크립트가 실행되기 전에 초기화해야 합니다. 방법은 두 가지입니다.</p><p><strong>방법 1: 인스펙터에서 미리 설정(권장)</strong></p><p>에디터에서 <code>KonadoVariableStore</code> 리소스를 만들고, 인스펙터에서 초기 변수 값을 설정한 뒤 <code>KonadoDialogueManager</code>의 <code>variable_store</code> 속성에 할당합니다.</p><p><strong>방법 2: 코드로 초기화</strong></p><div class="language-gdscript vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">gdscript</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">func</span><span style="--shiki-light:#6F42C1;--shiki-dark:#B392F0;"> _ready</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">() </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">-&gt;</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;"> void</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">:</span></span>
<span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">    if</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> dialogue_manager</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">.</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">variable_store </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">==</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> null</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">:</span></span>
<span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">        var</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> store </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#6F42C1;--shiki-dark:#B392F0;"> KonadoVariableStore</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">.</span><span style="--shiki-light:#6F42C1;--shiki-dark:#B392F0;">new</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">()</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">        store</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">.</span><span style="--shiki-light:#6F42C1;--shiki-dark:#B392F0;">set_value</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;love&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">0</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">        store</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">.</span><span style="--shiki-light:#6F42C1;--shiki-dark:#B392F0;">set_value</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;player_name&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">        store</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">.</span><span style="--shiki-light:#6F42C1;--shiki-dark:#B392F0;">set_value</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;unlocked&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">false</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">        dialogue_manager</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">.</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">variable_store </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> store</span></span></code></pre></div><h3 id="임시-변수" tabindex="-1">임시 변수(<code>$</code>) <a class="header-anchor" href="#임시-변수" aria-label="Permalink to &quot;임시 변수(\`$\`)&quot;">​</a></h3><p>임시 변수는 미리 설정할 필요가 없습니다. 스크립트에서 처음 <code>set</code>을 사용할 때 자동으로 생성됩니다. 샷을 전환하면 자동으로 초기화됩니다.</p><hr><h2 id="전체-예시" tabindex="-1">전체 예시 <a class="header-anchor" href="#전체-예시" aria-label="Permalink to &quot;전체 예시&quot;">​</a></h2><p>다음은 모든 변수 기능을 포함한 종합 데모입니다.</p><div class="language-text vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">text</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span>play bgm echo</span></span>
<span class="line"><span>background bg1 fade</span></span>
<span class="line"><span></span></span>
<span class="line"><span>actor show 코나 보통 at 3</span></span>
<span class="line"><span>Kona &quot;변수 시스템 데모에 오신 것을 환영합니다!&quot;</span></span>
<span class="line"><span></span></span>
<span class="line"><span>set %love = 10</span></span>
<span class="line"><span>Kona &quot;호감도를 10으로 설정했습니다. 현재 값: %love&quot;</span></span>
<span class="line"><span></span></span>
<span class="line"><span>add %love 5</span></span>
<span class="line"><span>Kona &quot;5를 더한 뒤 호감도: %love&quot;</span></span>
<span class="line"><span></span></span>
<span class="line"><span>sub %love 3</span></span>
<span class="line"><span>Kona &quot;3을 뺀 뒤 호감도: %love&quot;</span></span>
<span class="line"><span></span></span>
<span class="line"><span>mul %love 2</span></span>
<span class="line"><span>Kona &quot;2를 곱한 뒤 호감도: %love&quot;</span></span>
<span class="line"><span></span></span>
<span class="line"><span>div %love 4</span></span>
<span class="line"><span>Kona &quot;4로 나눈 뒤 호감도: %love&quot;</span></span>
<span class="line"><span></span></span>
<span class="line"><span>set $round = 1</span></span>
<span class="line"><span>set $bonus = 100</span></span>
<span class="line"><span>Kona &quot;라운드=$round, 보너스=$bonus&quot;</span></span>
<span class="line"><span></span></span>
<span class="line"><span>add $round 1</span></span>
<span class="line"><span>add $bonus 50</span></span>
<span class="line"><span>Kona &quot;$round 라운드, 보너스 $bonus&quot;</span></span>
<span class="line"><span></span></span>
<span class="line"><span>set %player_name &quot;플레이어&quot;</span></span>
<span class="line"><span>Kona &quot;안녕하세요, %player_name! 호감도 %love, $round 라운드입니다.&quot;</span></span>
<span class="line"><span></span></span>
<span class="line"><span>if %love == 6:</span></span>
<span class="line"><span>    Kona &quot;호감도가 정확히 6입니다!&quot;</span></span>
<span class="line"><span>else:</span></span>
<span class="line"><span>    Kona &quot;호감도가 6이 아닙니다.&quot;</span></span>
<span class="line"><span>endif</span></span>
<span class="line"><span></span></span>
<span class="line"><span>if %love &gt; 3:</span></span>
<span class="line"><span>    Kona &quot;호감도가 3보다 큽니다!&quot;</span></span>
<span class="line"><span>endif</span></span>
<span class="line"><span></span></span>
<span class="line"><span>if %love &lt; 10:</span></span>
<span class="line"><span>    Kona &quot;호감도가 10보다 작습니다.&quot;</span></span>
<span class="line"><span>endif</span></span>
<span class="line"><span></span></span>
<span class="line"><span>set $score = 85</span></span>
<span class="line"><span></span></span>
<span class="line"><span>if $score &gt;= 90:</span></span>
<span class="line"><span>    Kona &quot;훌륭합니다!&quot;</span></span>
<span class="line"><span>endif</span></span>
<span class="line"><span></span></span>
<span class="line"><span>if $score &gt;= 80:</span></span>
<span class="line"><span>    Kona &quot;좋습니다!&quot;</span></span>
<span class="line"><span>endif</span></span>
<span class="line"><span></span></span>
<span class="line"><span>set %unlocked true</span></span>
<span class="line"><span>if %unlocked == 1:</span></span>
<span class="line"><span>    Kona &quot;기능이 잠금 해제되었습니다!&quot;</span></span>
<span class="line"><span>endif</span></span>
<span class="line"><span></span></span>
<span class="line"><span>choice &quot;선물하기(호감도+10)&quot; -&gt; gift</span></span>
<span class="line"><span>choice &quot;무시하기(호감도-5)&quot; -&gt; ignore</span></span>
<span class="line"><span></span></span>
<span class="line"><span>branch gift</span></span>
<span class="line"><span>    add %love 10</span></span>
<span class="line"><span>    Kona &quot;고마워요! 호감도 %love!&quot;</span></span>
<span class="line"><span>    jump_branch done</span></span>
<span class="line"><span></span></span>
<span class="line"><span>branch ignore</span></span>
<span class="line"><span>    sub %love 5</span></span>
<span class="line"><span>    Kona &quot;......호감도 %love.&quot;</span></span>
<span class="line"><span>    jump_branch done</span></span>
<span class="line"><span></span></span>
<span class="line"><span>branch done</span></span>
<span class="line"><span>    actor exit 코나</span></span>
<span class="line"><span>    background bg_end fade</span></span>
<span class="line"><span>    end</span></span></code></pre></div><hr><h2 id="주의-사항-1" tabindex="-1">주의 사항 <a class="header-anchor" href="#주의-사항-1" aria-label="Permalink to &quot;주의 사항&quot;">​</a></h2><ol><li><strong>변수명</strong>은 문자, 숫자, 밑줄만 포함할 수 있으며 대소문자를 구분합니다.</li><li><strong>영구 변수</strong>(<code>%</code>) 값은 세이브 데이터와 함께 저장됩니다. 호감도, 스토리 플래그처럼 샷을 넘어 유지해야 하는 상태를 기록하는 데 적합합니다.</li><li><strong>임시 변수</strong>(<code>$</code>)는 샷을 전환할 때 자동으로 비워집니다. 현재 샷 안의 임시 상태를 기록하는 데 적합합니다.</li><li><strong>나눗셈 조작</strong>에서 제수가 0이면 오류가 발생하고 해당 조작을 건너뜁니다.</li><li><strong>조건 판단</strong>은 중첩을 지원하지 않습니다. 여러 조건은 평평한 <code>if</code> / <code>endif</code> 구조로 작성하세요.</li><li><code>branch</code> 블록 안에서 조건 판단을 사용할 때는 <code>if</code> / <code>endif</code>의 들여쓰기가 분기 안의 다른 내용과 일치해야 합니다.</li><li>초기화되지 않은 변수는 조건 판단에서 조건이 성립하지 않는 것으로 처리됩니다.</li></ol>`,72)])])}const k=s(t,[["render",i]]);export{u as __pageData,k as default};
