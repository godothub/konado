---
title: 설치
order: 1
---

# 설치

## 기본 의존성

1. Konado 플러그인 설치(필수)
2. C#을 지원하는 Godot 버전(Godot 4.6 이상 권장)
3. 프로젝트를 Godot .NET 에디터로 열어야 합니다. 일반 Godot 에디터는 C# 애드온 스크립트를 컴파일하거나 로드할 수 없습니다.

## 설치 단계

1. konadotnet 플러그인을 Godot 프로젝트의 `addons` 디렉터리에 압축 해제합니다
2. 기본 `addons/konado` 플러그인도 프로젝트에 있는지 확인합니다
3. Godot 에디터에서 `Project -> Project Settings -> Plugins`로 이동해 먼저 `Konado`를 활성화합니다
4. C# 프로젝트를 빌드하고 MSBuild 오류가 없는지 확인합니다
5. `Konadotnet` 플러그인을 활성화합니다
6. 프로젝트를 다시 열어 자동 로드 노드와 C# 스크립트 상태를 갱신합니다

## 처음 활성화할 때의 흔한 오류

C# 프로젝트를 아직 빌드하지 않았다면 다음 오류가 나타날 수 있습니다.

```text
Unable to load addon script from path: 'res://addons/konadotnet/Konadotnet.cs'.
```

Godot .NET 에디터에서 프로젝트를 빌드한 뒤 다시 열고 플러그인을 활성화하세요.

## 장면 요구 사항

`DialogueManagerAPI`를 사용하려면 현재 장면에 `KND_DialogueManager` 노드가 필요합니다. Konadotnet은 다음 일반적인 노드 이름도 지원합니다.

- `DialogManager`
- `DialogueManager`
- `KonadoDialogueManager`

대화 관리자가 여러 개라면 수동으로 바인딩하세요.
