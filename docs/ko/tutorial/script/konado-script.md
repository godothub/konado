---
title: Konado 스크립트
order: 1
---

# Konado Scripts

Konado Scripts는 비주얼 노벨에 맞춰 설계된 창작 언어입니다(파일 확장자는 `.ks`).

더 강력하고 구조화된 "소설 대본"이라고 생각할 수 있습니다. 개발자는 복잡한 코드를 작성하지 않고도 이야기 대화, 캐릭터 스탠딩 이미지, 배경 전환, 음악과 효과음, 이야기 분기와 선택지를 제어할 수 있습니다.

## 설계 철학

Konado Script의 핵심 설계 철학은 **이야기 내용**과 **프로그램 로직**을 분리하는 것입니다.
- 작가는 프로그래밍 지식 없이 서사 내용에 집중할 수 있습니다
- 프로그래머는 이야기 창작에 개입하지 않고 엔진 개발에 집중할 수 있습니다
- 리소스 관리(이미지, 오디오)는 식별자를 통해 참조하며 스크립트와 분리됩니다
- 모듈식 명령 집합으로 새 기능을 쉽게 확장할 수 있습니다
- Git 등 버전 관리 시스템과 호환됩니다
- 텍스트 형식은 본질적으로 크로스 플랫폼입니다
- 리소스 참조는 플랫폼에 의존하지 않습니다

## 자주 묻는 질문

### 1. 파싱 실패 후 저장해도 다시 파싱되지 않음

콘솔에는 오류 메시지가 표시되지만, 저장 후 자동으로 다시 파싱되지 않습니다. 이는 재가져오기가 정상적으로 트리거되지 않았기 때문입니다.

```text
5번째 줄 내용: a1ctor show Kona normal at 2 5 scale 0.3
  ERROR: core/variant/variant_utility.cpp:1024 - 오류: res://sample/demo/demo_01.ks [줄: 5] 파싱 실패: 인식할 수 없는 문법으로 파싱 중단: a1ctor show Kona normal at 2 5 scale 0.3 
  ERROR: Failed to process scripts
  ERROR: Error importing 'res://sample/demo/demo_01.ks'.
  ERROR: Failed loading resource: res://sample/demo/demo_01.ks.

```

해당 스크립트 파일을 찾아 마우스 오른쪽 버튼을 클릭한 뒤 다시 가져오기를 선택하세요.

![스크립트 다시 가져오기](/images/tutorial/script/reimport.png)

### 2. 스크립트 파일 인코딩 문제

스크립트 파일이 UTF-8로 인코딩되어 있는지 확인하세요. 그렇지 않으면 글자가 깨질 수 있습니다. 기본적으로 생성되는 스크립트 파일의 인코딩은 UTF-8입니다.
