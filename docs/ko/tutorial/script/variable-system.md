---
title: 변수 시스템
order: 8
---

# 변수 시스템

## 기능 개요

변수 시스템을 사용하면 스크립트 안에서 변수를 정의하고, 읽고, 수정하고, 판단할 수 있습니다. 이를 통해 동적인 대사 내용, 조건 분기, 상태 추적을 구현할 수 있습니다. 변수 값은 대사 텍스트 안에서 직접 참조할 수 있으며, 조건 판단의 기준으로 사용해 이야기 흐름을 제어할 수도 있습니다.

변수는 두 종류로 나뉩니다.

| 타입 | 접두사 | 생명 주기 | 영속화 | 초기화 방식 |
|------|--------|-----------|--------|-------------|
| 영구 변수 | `%` | 샷을 넘어 유지 | 세이브 데이터와 함께 저장 | 인스펙터에서 미리 설정 / 코드로 초기화 |
| 임시 변수 | `$` | 현재 샷에서만 유효 | 저장하지 않음 | 스크립트 안에서 `set`으로 초기화 |

---

## 변수 조작

다섯 가지 기본 조작을 지원합니다. 문법 형식은 다음과 같습니다.

```
<조작> <변수명> <값>
```

등호를 넣은 형식도 사용할 수 있습니다.

```
<조작> <변수명> = <값>
```

### 조작 목록

| 조작 | 설명 | 예시 |
|------|------|------|
| `set` | 변수 값을 설정합니다 | `set %love = 10` |
| `add` | 덧셈. 숫자 덧셈 또는 문자열 연결 | `add %love 5` |
| `sub` | 뺄셈 | `sub %love 3` |
| `mul` | 곱셈 | `mul %love 2` |
| `div` | 나눗셈. 0으로 나누면 오류가 발생합니다 | `div %love 4` |

### 매개변수 상세

| 매개변수 | 필수 | 예시 | 설명 |
|----------|------|------|------|
| 조작 | 예 | `set` | 다섯 가지 조작 중 하나 |
| 변수명 | 예 | `%love` | `%`로 시작하면 영구 변수, `$`로 시작하면 임시 변수 |
| 값 | 예 | `10` | 정수, 실수, 불리언(`true`/`false`) 또는 큰따옴표로 감싼 문자열 |

### 예시

```
set %love = 10
add %love 5
sub %love 3
mul %love 2
div %love 4

set $round = 1
add $round 1

set %player_name "플레이어"
set $stage "초보자 마을"
set %unlocked true
```

---

## 변수 보간

대사 텍스트 안에서 `%변수명` 또는 `$변수명`을 직접 사용하면, 실행 시 실제 값으로 치환됩니다.

### 문법

```
"캐릭터 이름" "대사 텍스트. %변수명 또는 $변수명을 포함할 수 있습니다"
```

### 예시

```
set %player_name "민수"
set $stage "초보자 마을"

"Kona" "안녕하세요, %player_name! 지금 있는 곳은 $stage입니다."
"Kona" "호감도는 %love이고, 현재는 $round 라운드입니다."
```

실행 시 출력:

```
Kona: "안녕하세요, 민수! 지금 있는 곳은 초보자 마을입니다."
Kona: "호감도는 12이고, 현재는 2 라운드입니다."
```

---

## 조건 판단

`if` / `else` / `endif` 구조를 사용해 변수 값에 따라 어떤 대사를 재생할지 결정합니다. 여섯 가지 비교 연산자를 지원합니다.

### 문법 구조

```
if <변수명> <연산자> <값>:
    <대사 내용>
else:
    <대사 내용>
endif
```

`else:` 블록은 선택 사항입니다. 생략했을 때 조건이 성립하지 않으면 전체 `if` 블록을 건너뜁니다.

### 지원 연산자

| 연산자 | 설명 | 예시 |
|--------|------|------|
| `==` | 같음 | `if %love == 5:` |
| `!=` | 같지 않음 | `if %love != 10:` |
| `>` | 큼 | `if %love > 3:` |
| `<` | 작음 | `if %love < 10:` |
| `>=` | 크거나 같음 | `if %love >= 5:` |
| `<=` | 작거나 같음 | `if %love <= 5:` |

### 매개변수 상세

| 매개변수 | 필수 | 예시 | 설명 |
|----------|------|------|------|
| 변수명 | 예 | `%love` | `%` 영구 변수 또는 `$` 임시 변수 |
| 연산자 | 예 | `==` | 여섯 가지 비교 연산자 중 하나 |
| 값 | 예 | `5` | 비교에 사용할 정수 값 |

### 예시

```
if %love == 5:
    "Kona" "호감도가 정확히 5입니다!"
else:
    "Kona" "호감도가 5가 아닙니다."
endif

if $score >= 80:
    "Kona" "좋습니다!"
endif

if $score >= 60:
    "Kona" "합격입니다."
endif
```

### 주의 사항

1. `if` / `else` / `endif`는 현재 문맥과 같은 들여쓰기 수준에 있어야 합니다.
2. 조건 판단은 **중첩을 지원하지 않습니다**. 즉, `if` 블록 안에 다시 `if`를 넣을 수 없습니다.
3. 여러 개의 독립 조건은 중첩하지 말고 평평한 `if` / `endif` 구조로 작성해야 합니다.
4. 조건 판단은 `branch` 분기 블록 안에서도 사용할 수 있습니다.

---

## 분기 안에서 조건 판단 사용

`branch` 블록 안에는 `if` / `endif` 조건 판단을 포함할 수 있습니다. 이를 통해 분기 안에서도 동적인 대사를 만들 수 있습니다.

### 예시

```
branch after_choice
    "Kona" "당신의 선택이 기록되었습니다."

    if $choice_made == 1:
        "Kona" "선물을 주기로 했군요. 정말 다정하네요."
    endif

    if $choice_made == 2:
        "Kona" "대화하기로 했군요. 소통은 중요합니다."
    endif

    if $choice_made == 3:
        "Kona" "무시하기로 했군요... 다음에는 다른 선택지도 시도해 보세요."
    endif
```

---

## 선택지와 변수 연동

`choice`와 `branch`를 조합하면 사용자가 선택한 뒤 변수 값을 수정할 수 있으며, 선택이 이후 이야기 전개에 영향을 주도록 만들 수 있습니다.

### 예시

```
set $choice_made = 0

choice "선물하기(호감도+10)" -> gift_choice
choice "대화하기(호감도+5)" -> chat_choice
choice "무시하기(호감도-5)" -> ignore_choice

branch gift_choice
    add %love 10
    set $choice_made = 1
    "Kona" "고마워요! 호감도가 %love까지 올랐어요!"
    jump_branch after_choice

branch chat_choice
    add %love 5
    set $choice_made = 2
    "Kona" "당신과 이야기해서 즐거웠어요. 지금 호감도는 %love입니다."
    jump_branch after_choice

branch ignore_choice
    sub %love 5
    set $choice_made = 3
    "Kona" "......호감도가 %love까지 내려갔어요."
    jump_branch after_choice

branch after_choice
    "Kona" "당신의 선택이 기록되었습니다."
```

---

## 불리언 변수

변수는 불리언 타입을 지원하며, `true` / `false`로 값을 대입합니다. 조건 판단에서는 `true`가 `1`, `false`가 `0`과 같습니다.

### 예시

```
set %unlocked true
set $visited false

if %unlocked == 1:
    "Kona" "기능이 잠금 해제되었습니다!"
endif

set $visited true
if $visited == 1:
    "Kona" "방문 플래그가 설정되었습니다."
endif
```

---

## 변수 초기화

### 영구 변수(`%`)

영구 변수는 스크립트가 실행되기 전에 초기화해야 합니다. 방법은 두 가지입니다.

**방법 1: 인스펙터에서 미리 설정(권장)**

에디터에서 `KND_VariableStore` 리소스를 만들고, 인스펙터에서 초기 변수 값을 설정한 뒤 `KND_DialogueManager`의 `variable_store` 속성에 할당합니다.

**방법 2: 코드로 초기화**

```gdscript
func _ready() -> void:
    if dialogue_manager.variable_store == null:
        var store = KND_VariableStore.new()
        store.set_value("love", 0)
        store.set_value("player_name", "")
        store.set_value("unlocked", false)
        dialogue_manager.variable_store = store
```

### 임시 변수(`$`)

임시 변수는 미리 설정할 필요가 없습니다. 스크립트에서 처음 `set`을 사용할 때 자동으로 생성됩니다. 샷을 전환하면 자동으로 초기화됩니다.

---

## 전체 예시

다음은 모든 변수 기능을 포함한 종합 데모입니다.

```
play bgm echo
background bg1 fade

actor show 코나 보통 at 3 9 scale 0.3
"Kona" "변수 시스템 데모에 오신 것을 환영합니다!"

set %love = 10
"Kona" "호감도를 10으로 설정했습니다. 현재 값: %love"

add %love 5
"Kona" "5를 더한 뒤 호감도: %love"

sub %love 3
"Kona" "3을 뺀 뒤 호감도: %love"

mul %love 2
"Kona" "2를 곱한 뒤 호감도: %love"

div %love 4
"Kona" "4로 나눈 뒤 호감도: %love"

set $round = 1
set $bonus = 100
"Kona" "라운드=$round, 보너스=$bonus"

add $round 1
add $bonus 50
"Kona" "$round 라운드, 보너스 $bonus"

set %player_name "플레이어"
"Kona" "안녕하세요, %player_name! 호감도 %love, $round 라운드입니다."

if %love == 6:
    "Kona" "호감도가 정확히 6입니다!"
else:
    "Kona" "호감도가 6이 아닙니다."
endif

if %love > 3:
    "Kona" "호감도가 3보다 큽니다!"
endif

if %love < 10:
    "Kona" "호감도가 10보다 작습니다."
endif

set $score = 85

if $score >= 90:
    "Kona" "훌륭합니다!"
endif

if $score >= 80:
    "Kona" "좋습니다!"
endif

set %unlocked true
if %unlocked == 1:
    "Kona" "기능이 잠금 해제되었습니다!"
endif

choice "선물하기(호감도+10)" -> gift
choice "무시하기(호감도-5)" -> ignore

branch gift
    add %love 10
    "Kona" "고마워요! 호감도 %love!"
    jump_branch done

branch ignore
    sub %love 5
    "Kona" "......호감도 %love."
    jump_branch done

branch done
    actor exit 코나
    background bg_end fade
    end
```

---

## 주의 사항

1. **변수명**은 문자, 숫자, 밑줄만 포함할 수 있으며 대소문자를 구분합니다.
2. **영구 변수**(`%`) 값은 세이브 데이터와 함께 저장됩니다. 호감도, 스토리 플래그처럼 샷을 넘어 유지해야 하는 상태를 기록하는 데 적합합니다.
3. **임시 변수**(`$`)는 샷을 전환할 때 자동으로 비워집니다. 현재 샷 안의 임시 상태를 기록하는 데 적합합니다.
4. **나눗셈 조작**에서 제수가 0이면 오류가 발생하고 해당 조작을 건너뜁니다.
5. **조건 판단**은 중첩을 지원하지 않습니다. 여러 조건은 평평한 `if` / `endif` 구조로 작성하세요.
6. `branch` 블록 안에서 조건 판단을 사용할 때는 `if` / `endif`의 들여쓰기가 분기 안의 다른 내용과 일치해야 합니다.
7. 초기화되지 않은 변수는 조건 판단에서 조건이 성립하지 않는 것으로 처리됩니다.
