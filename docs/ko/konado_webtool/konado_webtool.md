---
title: 소개
order: 1
---

# Konado WebTool

## 머리말

Konado WebTool은 Konado 프로젝트에 Web 플랫폼 개발 도구 지원을 제공하는 플러그인입니다. Godot 4.x는 Web 플랫폼에서 기본적으로 모든 키보드 단축키를 캡처하고 비활성화하므로 F12, F5 같은 브라우저 개발자 도구 단축키를 정상적으로 사용할 수 없습니다. 이 플러그인은 이 문제를 해결하여 Web 플랫폼에서 일반적인 브라우저 개발자 도구 단축키를 사용할 수 있게 하고, 개발자가 Web 환경에서 더 쉽게 디버깅하고 개발할 수 있도록 합니다.

## 작동 원리

Konado WebTool은 Web 플랫폼에 JavaScript 코드를 주입해 단축키를 통과시키는 방식으로 동작합니다. 동작 과정은 다음과 같습니다.

1. 현재 플랫폼이 Web 플랫폼인지 확인합니다
2. Web 플랫폼이고 개발자 도구 지원이 활성화되어 있으면 단축키 처리 코드를 주입합니다
3. 설정에 따라 허용할 단축키 목록을 동적으로 구성합니다
4. 키보드 이벤트를 감시하고, 허용된 단축키에 대해 기본 동작을 막아 브라우저로 통과시킵니다

### 다른 해결책과 비교

| 해결책 | 장점 | 단점 |
|----------|------|------|
| Konado WebTool | 사용하기 쉽고, 설정 가능성이 높으며, 유지보수가 좋음 | 뚜렷한 단점 없음 |
| 내보내기 템플릿 수동 수정 | 완전한 제어 가능 | 기술 요구가 높고 자주 업데이트해야 함 |
| 개발 환경 전환 | 데스크톱 플랫폼에서 디버깅 가능 | Web 플랫폼 특유의 문제를 포착할 수 없음 |

## 지원되는 브라우저 단축키

이 단축키 규격은 Chrome, Firefox, Edge 등 주요 브라우저의 개발자 도구 표준 단축키를 기반으로 하며, 각 브라우저의 공식 문서를 참고했습니다.

- [Firefox DevTools](https://developer.mozilla.org/en-US/docs/Tools/Keyboard_shortcuts)
- [Edge DevTools](https://learn.microsoft.com/en-us/microsoft-edge/devtools-guide-chromium/shortcuts/)
- [Chrome DevTools](https://developer.chrome.com/docs/devtools/shortcuts/)
- [Safari DevTools(WebKit)](https://webkit.org/web-inspector/keyboard-shortcuts/)

| 단축키 | 기능 | 활성화 옵션 |
|--------|------|----------|
| F12 | 개발자 도구 열기 | `enable_f12` |
| F5 | 페이지 새로고침 | `enable_f5` |
| F11 | 전체 화면 전환 | `enable_f11` |
| Ctrl+Shift+I (Win/Linux) / Cmd+Opt+I (Mac) | Elements 패널 열기 | `enable_ctrl_shift_i` |
| Ctrl+Shift+J (Win/Linux) / Cmd+Opt+J (Mac) | Console 열기 | `enable_ctrl_shift_j` |
| Ctrl+Shift+C (Win/Linux) / Cmd+Shift+C (Mac) | 요소 검사 모드 | `enable_ctrl_shift_c` |
| Ctrl+U (Win/Linux) / Cmd+U (Mac) | 페이지 소스 보기 | `enable_ctrl_u` |
| Ctrl+R (Win/Linux) / Cmd+R (Mac) | 페이지 새로고침 | `enable_ctrl_r` |

## 설정 옵션

자동 로드되는 `KND_WebTool` 노드에서 다음 속성을 설정할 수 있습니다.

| 속성 | 유형 | 기본값 | 설명 |
|------|------|--------|------|
| `enable_web_devtool` | bool | true | Web 개발자 도구 단축키 통과를 활성화할지 여부 |
| `enable_f12` | bool | true | F12 단축키를 활성화할지 여부 |
| `enable_f5` | bool | true | F5 단축키를 활성화할지 여부 |
| `enable_f11` | bool | true | F11 단축키를 활성화할지 여부 |
| `enable_ctrl_shift_i` | bool | true | Ctrl+Shift+I 단축키를 활성화할지 여부 |
| `enable_ctrl_shift_j` | bool | true | Ctrl+Shift+J 단축키를 활성화할지 여부 |
| `enable_ctrl_shift_c` | bool | true | Ctrl+Shift+C 단축키를 활성화할지 여부 |
| `enable_ctrl_u` | bool | true | Ctrl+U 단축키를 활성화할지 여부 |
| `enable_ctrl_r` | bool | true | Ctrl+R 단축키를 활성화할지 여부 |
