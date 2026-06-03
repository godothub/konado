---
title: API 사용
order: 2
---

# Konado .NET API

> 이 기능은 아직 실험적입니다. 

## 소개

Konado.NET은 Konado 대화 시스템의 C# API 확장입니다. Konado 기본 플러그인을 대체하는 것이 아니라, C#에서 `KND_DialogueManager`를 제어하고, 대화 흐름 신호를 구독하고, `.ks` 스크립트를 파싱하며, Konado GDScript 데이터 리소스를 다루기 위한 얇은 레이어입니다.

진입점은 자동 로드 노드 `KonadoAPI`입니다. 일반적으로 `KonadoAPI.DialogueManagerApi`에서 시작합니다.

## 사용 조건

Konado.NET은 C#을 지원하는 Godot 프로젝트에서만 사용할 수 있습니다. Godot 4.6 이상의 .NET 에디터를 사용하세요. 비 .NET 프로젝트에서 활성화하면 `res://addons/konadotnet/Konadotnet.cs`를 로드하지 못할 수 있습니다. 이 경우 Konado 기본 플러그인은 사용할 수 있지만 C# API는 사용할 수 없습니다.

먼저 `Konado` 플러그인을 활성화하고, 그다음 `Konadotnet`을 활성화하세요. 장면에는 `KND_DialogueManager` 노드가 필요합니다. Konado.NET은 스크립트 타입으로 검색하며 `DialogManager`, `DialogueManager`, `KonadoDialogueManager` 같은 일반적인 노드 이름도 지원합니다. 대화 관리자가 여러 개라면 `BindDialogueManager(Node source)`로 명시적으로 지정하세요.

## 빠른 시작

```csharp
using Godot;
using Konado.Runtime.API;
using Konado.Wrapper;

public partial class DialogueExample : Node
{
    public override void _Ready()
    {
        var dialogueManager = KonadoAPI.DialogueManagerApi;

        dialogueManager.DialogueLineStart += (string nodeId) =>
        {
            GD.Print($"Node started: {nodeId}");
        };

        dialogueManager.CustomSignal += (string content) =>
        {
            GD.Print($"Custom signal: {content}");
        };

        var interpreter = new KonadoScriptsInterpreter();
        var shot = interpreter.ProcessScriptsToData("res://sample/demo/demo_01.ks");

        dialogueManager.SetShot(shot.SourceResource);
        dialogueManager.InitDialogue();
        dialogueManager.StartDialogue();
    }
}
```

## KonadoAPI

| 멤버 | 타입 | 설명 |
| --- | --- | --- |
| `IsApiReady` | `bool` | `KonadoAPI` 자동 로드 노드가 초기화되었는지 여부입니다. `KND_DialogueManager`를 찾았다는 뜻은 아닙니다. |
| `API` | `static KonadoAPI` | 현재 자동 로드 인스턴스의 정적 참조입니다. |
| `DialogueManagerApi` | `static DialogueManagerAPI` | 대화 관리자 API 인스턴스이며 주요 런타임 진입점입니다. |

## DialogueManagerAPI

`DialogueManagerAPI`는 `KND_DialogueManager`의 C# 제어 레이어이며 호출을 GDScript 노드로 전달합니다.

### 속성

| 속성 | 타입 | 설명 |
| --- | --- | --- |
| `IsReady` | `bool` | 사용할 수 있는 `KND_DialogueManager`에 바인딩되었는지 여부입니다. |
| `Source` | `Node` | 현재 바인딩된 원본 Godot 노드입니다. |

### 메서드

| 메서드 | 설명 |
| --- | --- |
| `bool BindDialogueManager(Node source = null)` | 지정한 대화 관리자에 바인딩합니다. 생략하면 장면 트리를 순회합니다. 성공하면 `true`를 반환합니다. |
| `void InitDialogue()` | `init_dialogue()`를 호출합니다. 보통 `SetShot()` 뒤, `StartDialogue()` 앞에서 호출합니다. |
| `void SetShot(Resource shot)` | `set_shot()`으로 현재 `KND_Shot`을 변경합니다. 래퍼를 전달할 때는 `KndShot.SourceResource`를 사용합니다. |
| `void StartDialogue()` | `start_dialogue()`를 호출해 재생을 시작합니다. |
| `void StopDialogue()` | `stop_dialogue()`를 호출해 재생을 중지합니다. |
| `void StartAutoplay(bool value)` | 자동 재생을 전환합니다. |
| `bool SaveGame(int saveId)` | 진행 상황을 저장합니다. API가 준비되지 않았거나 저장에 실패하면 `false`를 반환합니다. |
| `bool LoadGame(int saveId)` | 지정한 저장 슬롯을 불러옵니다. |
| `bool DeleteSave(int saveId)` | 지정한 저장 슬롯을 삭제합니다. |
| `Dictionary GetSaveInfo(int saveId)` | 단일 저장 정보를 가져옵니다. API가 준비되지 않았으면 빈 딕셔너리를 반환합니다. |
| `Array<Dictionary> GetAllSaveInfo()` | 모든 저장 정보를 가져옵니다. API가 준비되지 않았으면 빈 배열을 반환합니다. |

일반적인 재생 순서:

```csharp
var shot = interpreter.ProcessScriptsToData("res://dialogues/chapter_01.ks");
dialogueManager.SetShot(shot.SourceResource);
dialogueManager.InitDialogue();
dialogueManager.StartDialogue();
```

### 이벤트

| 이벤트 | 설명 |
| --- | --- |
| `ShotStart` | `shot_start`에 연결됩니다. 샷이 시작될 때 발생합니다. |
| `ShotEnd` | `shot_end`에 연결됩니다. 샷이 끝날 때 발생합니다. |
| `DialogueLineStart(string nodeId)` | `dialogue_line_start(node_id)`에 연결됩니다. Konado 2.4는 이전 줄 번호 대신 노드 ID를 사용합니다. |
| `DialogueLineEnd(string nodeId)` | `dialogue_line_end(node_id)`에 연결됩니다. |
| `CustomSignal(string content)` | `custom_signal(content)`에 연결됩니다. `.ks`의 `signal` 문에서 발생합니다. |

## ActingInterface

| 열거값 | 효과 |
| --- | --- |
| `NoneEffect` | 효과 없음 |
| `EraseEffect` | 지우기 효과 |
| `BlindsEffect` | 블라인드 효과 |
| `WaveEffect` | 웨이브 효과 |
| `AlphaFadeEffect` | 알파 페이드 효과 |
| `VortexSwapEffect` | 소용돌이 전환 효과 |
| `WindmillEffect` | 풍차 효과 |
| `CyberGlitchEffect` | 사이버 글리치 효과 |

## Wrapper 클래스

Wrapper 클래스는 Konado GDScript 리소스를 감싸는 가벼운 C# 래퍼입니다. 기존 리소스를 감쌀 때는 스크립트 타입을 검증하고, 새 래퍼를 만들 때는 대응하는 GDScript 리소스를 생성합니다. Konado API에 다시 전달할 때는 `SourceResource`를 사용하세요.

## Dialogue

`Dialogue`는 `KND_Dialogue`를 감쌉니다: `res://addons/konado/scripts/dialogue/knd_dialogue.gd`.

| 멤버 | 설명 |
| --- | --- |
| `Dialogue()` | 새 `KND_Dialogue` 리소스를 생성합니다. |
| `Dialogue(GodotObject source)` | 기존 `KND_Dialogue`를 감쌉니다. 잘못된 소스면 예외를 던집니다. |
| `SourceResource` | 원본 `Resource`를 반환합니다. |

| 속성 | 타입 | 설명 |
| --- | --- | --- |
| `SourceFileLine` | `int` | 원본 `.ks` 줄 번호입니다. 디버깅과 오류 위치에 사용합니다. |
| `DialogueType` | `Dialogue.Type` | 노드 타입이며 재생 처리 방식을 결정합니다. |
| `NodeId` | `string` | 대화 그래프 노드 ID입니다. |
| `NextId` | `string` | 기본 다음 노드 ID입니다. |
| `IfNextId` | `string` | 조건이 참일 때 이동할 노드입니다. |
| `ElseNextId` | `string` | 조건이 거짓일 때 이동할 노드입니다. |
| `VarName` | `string` | 조건 판단에 사용할 변수명입니다. |
| `ConditionOperator` | `int` | 조건 연산자: `0 ==`, `1 >`, `2 <`, `3 >=`, `4 <=`. |
| `TargetValue` | `int` | 조건 비교 대상 값입니다. |
| `CharacterId` | `string` | 말하는 캐릭터 ID입니다. |
| `DialogueContent` | `string` | 대화 텍스트입니다. |
| `VoiceId` | `string` | 음성 ID입니다. |
| `CharacterName` | `string` | 표시하거나 생성할 캐릭터 ID입니다. |
| `CharacterState` | `string` | 캐릭터 상태 또는 일러스트 상태 ID입니다. |
| `ActorPosition` | `Vector2` | 캐릭터 위치입니다. Konado 2.4는 그리드 기반 배치를 사용합니다. |
| `ExitActor` | `string` | 퇴장 또는 숨길 캐릭터 ID입니다. |
| `ChangeStateActor` | `string` | 상태를 변경할 캐릭터 ID입니다. |
| `ChangeState` | `string` | 대상 상태 ID입니다. |
| `TargetMoveChara` | `string` | 이동할 캐릭터 ID입니다. |
| `TargetMovePos` | `Vector2` | 이동 목표 위치입니다. |
| `Choices` | `Array<DialogueChoice>` | 선택지 목록입니다. 각 선택지는 `NextId`로 대상 노드를 가리킵니다. |
| `JumpShotPath` | `string` | 다른 `KND_Shot`으로 이동할 리소스 경로입니다. |
| `JumpBranchTarget` | `string` | 현재 샷 내부의 분기 라벨입니다. |
| `BgmName` | `string` | 재생할 BGM 이름입니다. |
| `SoundeffectName` | `string` | 재생할 효과음 이름입니다. |
| `BackgroundImageName` | `string` | 전환할 배경 이미지 이름입니다. |
| `BackgroundToggleEffects` | `BackgroundTransitionEffectsType` | 배경 전환 효과입니다. |
| `CustomSignalName` | `string` | `CustomSignal` 이벤트로 전달되는 내용입니다. |
| `AchievementId` | `string` | 업적 ID입니다. |
| `AchievementValue` | `int` | 업적 진행 값입니다. |
| `AchievementFlagName` | `string` | 업적 플래그 이름입니다. |
| `AchievementFlagValue` | `bool` | 업적 플래그 값입니다. |
| `VariableName` | `string` | 조작할 변수명입니다. |
| `VariableOperation` | `int` | 변수 연산: `0 SET`, `1 ADD`, `2 SUB`, `3 MUL`, `4 DIV`. |
| `VariableOperand` | `string` | 문자열로 저장되며 런타임에 기본 플러그인이 해석하는 피연산자입니다. |
| `IsPersistent` | `bool` | 지속 변수 여부입니다. 보통 `%`는 지속 변수, `$`는 임시 변수입니다. |

### Dialogue.Type

| 값 | 설명 |
| --- | --- |
| `OrdinaryDialog` | 일반 대화. |
| `DisplayActor` | 캐릭터 표시 또는 생성. |
| `ActorChangeState` | 캐릭터 상태 변경. |
| `MoveActor` | 캐릭터 이동. |
| `SwitchBackground` | 배경 전환. |
| `ExitActor` | 캐릭터 퇴장. |
| `PlayBgm` | BGM 재생. |
| `StopBgm` | BGM 중지. |
| `PlaySoundEffect` | 효과음 재생. |
| `ShowChoice` | 선택지 표시. |
| `IfElseBranch` | 조건 분기. |
| `Branch` | 호환성을 위해 남겨진 이전 분기 값. |
| `Jump` | 점프 노드. |
| `JumpBranch` | 분기 라벨로 점프. |
| `Signal` | 사용자 정의 신호 노드. |
| `AchievementUnlock` | 업적 잠금 해제. |
| `AchievementProgress` | 업적 진행 업데이트. |
| `AchievementFlag` | 업적 플래그 설정. |
| `SetVariable` | 변수 설정 또는 변경. |
| `TheEnd` | 종료 노드. |

## DialogueChoice

| 속성 | 타입 | 설명 |
| --- | --- | --- |
| `ChoiceText` | `string` | 플레이어에게 표시되는 선택지 텍스트입니다. |
| `NextId` | `string` | 선택 후 이동할 대상 노드 ID입니다. |

## KndData

`KndData`는 Konado 데이터 리소스의 기본 래퍼입니다. 대부분의 경우 `KndShot`, `Dialogue`, `DialogueChoice` 같은 구체 클래스를 사용합니다.

## KndShot

| 속성 | 타입 | 설명 |
| --- | --- | --- |
| `KsPath` | `string` | 원본 `.ks` 경로입니다. |
| `ShotId` | `string` | 샷 ID입니다. |
| `StartNodeId` | `string` | 시작 노드 ID입니다. 비어 있으면 보통 첫 노드를 사용합니다. |
| `Dialogues` | `Array<Dialogue>` | 샷에 포함된 모든 대화 노드입니다. |

| 메서드 | 설명 |
| --- | --- |
| `Dialogue FindNode(string nodeId)` | `node_id`로 노드를 찾습니다. 없으면 `null`을 반환합니다. |
| `Dialogue GetStartNode()` | 시작 노드를 가져옵니다. |

## KonadoScriptsInterpreter

| 멤버 | 설명 |
| --- | --- |
| `KonadoScriptsInterpreter(Dictionary<string, Variant> flags = null)` | 새 인터프리터를 생성합니다. `flags`는 호환성을 위해 남겨져 있습니다. |
| `KonadoScriptsInterpreter(GodotObject source)` | 기존 인터프리터 객체를 감쌉니다. |
| `KndShot ProcessScriptsToData(string path)` | `.ks` 파일을 `KND_Shot`으로 파싱합니다. |
| `Dialogue ParseSingleLine(string line, long lineNumber, string path)` | Konado 스크립트 한 줄을 파싱합니다. |

## 예시

```csharp
var interpreter = new KonadoScriptsInterpreter();
var shot = interpreter.ProcessScriptsToData("res://sample/demo/demo_01.ks");

var api = KonadoAPI.DialogueManagerApi;
api.SetShot(shot.SourceResource);
api.InitDialogue();
api.StartDialogue();
```

## FAQ

### `IsApiReady`는 true이지만 `DialogueManagerApi.IsReady`가 false입니다

`IsApiReady`는 Konado.NET 자동 로드 노드 초기화 상태만 의미합니다. 현재 장면에 `KND_DialogueManager`가 있는지 확인하거나 수동으로 바인딩하세요.

```csharp
KonadoAPI.DialogueManagerApi.BindDialogueManager(GetNode<Node>("path/to/manager"));
```

### `SetShot` 후 재생되지 않습니다

`SetShot()`은 샷만 변경합니다. 다음 순서로 호출하세요.

```csharp
api.SetShot(shot.SourceResource);
api.InitDialogue();
api.StartDialogue();
```
