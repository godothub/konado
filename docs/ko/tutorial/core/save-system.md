---
title: 저장 시스템
order: 2
---

# 저장 시스템

## 사용 방법

### 게임 저장

```gdscript
# 지정 슬롯에 저장
dialogue_manager.save_game(1)  # 1번 슬롯에 저장

# 또는 저장 시스템을 직접 사용
save_system.save_game(2)  # 2번 슬롯에 저장
```

### 게임 불러오기

```gdscript
# 지정 슬롯에서 불러오기
dialogue_manager.load_game(1)  # 1번 슬롯에서 불러오기

# 또는 저장 시스템을 직접 사용
save_system.load_game(2)  # 2번 슬롯에서 불러오기
```

### 저장 삭제

```gdscript
# 지정 슬롯의 저장 삭제
dialogue_manager.delete_save(1)  # 1번 슬롯 저장 삭제

# 또는 저장 시스템을 직접 사용
save_system.delete_save(2)  # 2번 슬롯 저장 삭제
```

### 저장 정보 가져오기

```gdscript
# 지정 슬롯의 저장 정보 가져오기
var save_info = dialogue_manager.get_save_info(1)
print("저장 시간: " + str(save_info.get("save_time", {})))

# 모든 저장 정보 가져오기
var all_save_infos = dialogue_manager.get_all_save_info()
for i in range(all_save_infos.size()):
    if all_save_infos[i].get("exists", false):
        print("저장 " + str(i) + " 존재")
```

### 저장 전략 설정

```gdscript
# 사용자 지정 저장 전략
var custom_strategy = {
    "include_dialogue_state": true,    # 대화 상태 포함
    "include_variables": true,          # 변수 포함
    "include_audio_state": false,       # 오디오 상태 미포함
    "include_actor_state": false,       # 액터 상태 미포함
    "include_background_state": false   # 배경 상태 미포함
}

dialogue_manager.set_save_strategy(custom_strategy)
```

## 저장 데이터 구조

저장 데이터에는 다음 내용이 포함됩니다.

- **dialogue_state** - 대화 상태. 현재 샷, 대화 인덱스, 대화 상태를 포함합니다
- **variables** - 게임 변수
- **audio_state** - 오디오 상태(예약)
- **actor_state** - 액터 상태(예약)
- **background_state** - 배경 상태(예약)
- **save_time** - 저장 시간
- **version** - 저장 버전

## 저장 파일 형식

저장 파일은 JSON 형식으로 저장되며 `user://saves/` 디렉터리 아래에 있습니다. 파일 이름은 `[슬롯ID].sav`입니다.
