---
title: 문법 하이라이터
order: 5
---

# KND_KsHighlighter 에디터 문법 하이라이트

## 머리말

문법 하이라이트는 에디터의 중요한 구성 요소입니다. 개발자가 코드 구조를 직관적으로 식별하도록 도와 작성 효율과 가독성을 높입니다.  
`KND_KsHighlighter`는 Godot 엔진의 `SyntaxHighlighter`를 기반으로 구현된 하이라이터이며 KS 스크립트 전용입니다. 하이라이트 규칙을 하나의 스크립트에 집중 정의하여 사용자 지정과 확장이 매우 유연합니다. 기존 규칙을 쉽게 조정할 수 있고 완전히 새로운 색상方案도 추가할 수 있습니다.

## 기본 구현

`KND_KsHighlighter`에서 하이라이트 규칙은 배열로 저장됩니다. 각 배열 요소는 두 개의 키를 가진 딕셔너리입니다.

- `regex`: 텍스트를 매칭하는 정규식(Godot RegEx 문법).
- `color`: 매칭된 텍스트의 색상. `Color(r, g, b, a)`로 표현하며, `a`는 투명도입니다(선택, 기본값 1.0).

예시 구조:
```gdscript
{
	"regex": "\\b(if|else|endif)\\b",
	"color": Color(1.0, 0.8, 0.2)
}
```

하이라이터는 배열 순서대로 규칙을 매칭합니다. 나중에 적용된 규칙이 이전 매칭을 덮어쓸 수 있으므로 규칙 순서가 매우 중요합니다. 일반 명령은 앞에, 문자열과 주석은 뒤에 두어 덮어쓰기 효과가 합리적으로 작동하도록 하는 것을 권장합니다.

## 사용자 지정 색상方案

에디터에 사용자 지정 하이라이트를 적용하는 방법은 두 가지입니다.

### 방법 1: 리소스 파일 수정(권장)

기본 색상方案은 리소스 파일 형태로 다음 위치에 저장됩니다.
```
res://addons/konado/editor/ks_editor/ks_syntax_highlighter.tres
```

이 리소스 파일을 직접 편집하면 수정 사항을 유지할 수 있고 매번 다시 생성할 필요가 없습니다.  
코드에서 이 리소스를 로드해 사용합니다.
```gdscript
set_syntax_highlighter(load("res://addons/konado/editor/ks_editor/ks_syntax_highlighter.tres"))
```

### 방법 2: 인스턴스 동적 생성

코드에서 새 `KND_KsHighlighter` 인스턴스를 직접 만들고 사용자 지정 규칙을 설정할 수도 있습니다. 예를 들어 스크립트의 `highlight_rules`를 수정합니다.
```gdscript
set_syntax_highlighter(KND_KsHighlighter.new())
```

> **주의**: `KND_KsHighlighter.gd` 스크립트를 직접 수정한 경우 변경 사항을 적용하려면 리소스 파일을 다시 생성해야 할 수 있습니다. 색상 관리를 더 명확하게 하기 위해 리소스 파일 방식을 우선 사용하는 것을 권장합니다.
