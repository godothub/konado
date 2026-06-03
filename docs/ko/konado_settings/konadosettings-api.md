---
title: API 사용
order: 2
---

# Konado Settings API 문서

## 설정 관리자(KND_Settings)

설정 관리자는 자동으로 로드되는 싱글톤이며 모든 설정 항목을 관리합니다.

### 시그널

#### `setting_changed(category: String, key: String, value: Variant)`
- **설명**: 설정 값이 변경될 때 발생하는 시그널입니다.
- **매개변수**:
  - `category`: 설정 카테고리.
  - `key`: 설정 항목의 키.
  - `value`: 새 설정 값.

### 메서드

#### `get_setting(category: String, key: String) -> Variant`
- **설명**: 설정의 현재 값을 가져옵니다.
- **매개변수**:
  - `category`: 설정 카테고리.
  - `key`: 설정 항목의 키.
- **반환값**: 설정 값입니다. 존재하지 않으면 기본값 또는 null을 반환합니다.

#### `set_setting(category: String, key: String, value: Variant) -> void`
- **설명**: 설정을 변경하고 저장한 뒤 시그널을 발생시킵니다.
- **매개변수**:
  - `category`: 설정 카테고리.
  - `key`: 설정 항목의 키.
  - `value`: 새 설정 값.

#### `register_category(cat: SettingCategory) -> void`
- **설명**: 실행 중에 추가 설정 카테고리를 등록합니다.
- **매개변수**:
  - `cat`: 등록할 설정 카테고리.

#### `reset_category(category_id: String) -> void`
- **설명**: 지정한 카테고리의 모든 설정을 기본값으로 되돌립니다.
- **매개변수**:
  - `category_id`: 카테고리 ID.

#### `get_categories() -> Array`
- **설명**: 등록된 모든 카테고리를 현재 플랫폼에 맞게 필터링해 가져옵니다.
- **반환값**: 필터링된 카테고리 배열.

#### `get_category(id: String) -> SettingCategory`
- **설명**: ID로 단일 카테고리를 가져오며, 현재 플랫폼에 맞게 필터링합니다.
- **매개변수**:
  - `id`: 카테고리 ID.
- **반환값**: 필터링된 카테고리 객체.

## 설정 카테고리(SettingCategory)

설정 카테고리는 관련된 설정 항목을 함께 묶는 데 사용합니다.

### 속성

- **id: String**: 카테고리의 고유 식별자.
- **display_name: String**: 카테고리의 표시 이름.
- **items: Array[SettingItem]**: 카테고리에 포함된 설정 항목 배열.

### 예시

```gdscript
var video_cat = SettingCategory.new()
video_cat.id = "video"
video_cat.display_name = "비디오"

# 설정 항목 추가
video_cat.items.append(resolution_item)

# 카테고리 등록
KND_Settings.register_category(video_cat)
```

## 설정 항목(SettingItem)

설정 항목은 하나의 구성 가능한 설정 단위입니다.

### 열거형

#### `Type`
- **SLIDER (0)**: 슬라이더 타입. 숫자 값을 조정할 때 사용합니다.
- **TOGGLE (1)**: 토글 타입. 불리언 값에 사용합니다.
- **OPTION (2)**: 옵션 타입. 드롭다운 선택에 사용합니다.

### 속성

- **key: String**: 설정 항목의 고유 식별자.
- **label: String**: 설정 항목의 표시 라벨.
- **type: Type**: 설정 항목 타입.
- **min_value: float**: 슬라이더 최솟값. SLIDER 타입에서만 사용합니다.
- **max_value: float**: 슬라이더 최댓값. SLIDER 타입에서만 사용합니다.
- **step: float**: 슬라이더 단계 값. SLIDER 타입에서만 사용합니다.
- **options: Array[String]**: 옵션 목록. OPTION 타입에서만 사용합니다.
- **platforms: Array[String]**: 플랫폼 필터입니다. 빈 배열이면 모든 플랫폼에서 표시됩니다.
- **default_value: Variant**: 기본값입니다. SLIDER는 float, TOGGLE은 bool, OPTION은 String을 사용합니다.

### 예시

#### 슬라이더 타입 설정 항목 만들기

```gdscript
var volume_item = SettingItem.new()
volume_item.key = "master_volume"
volume_item.label = "마스터 볼륨"
volume_item.type = SettingItem.Type.SLIDER
volume_item.min_value = 0.0
volume_item.max_value = 1.0
volume_item.step = 0.01
volume_item.default_value = 1.0
volume_item.platforms = ["all"]
```

#### 토글 타입 설정 항목 만들기

```gdscript
var fullscreen_item = SettingItem.new()
fullscreen_item.key = "fullscreen"
fullscreen_item.label = "전체 화면"
fullscreen_item.type = SettingItem.Type.TOGGLE
fullscreen_item.default_value = false
```

#### 옵션 타입 설정 항목 만들기

```gdscript
var language_item = SettingItem.new()
language_item.key = "language"
language_item.label = "언어"
language_item.type = SettingItem.Type.OPTION
language_item.options = ["zh", "tc", "en", "ja", "ko"]
language_item.default_value = "zh"
```

## UI 팩토리(UIFactory)

UI 팩토리는 설정 항목의 조작 UI를 만드는 데 사용합니다.

### 메서드

#### `create_control(cat_id: String, item: SettingItem, callback: Callable) -> HBoxContainer`
- **설명**: 지정한 설정 항목에 대한 한 줄(HBoxContainer)을 만들고 반환합니다.
- **매개변수**:
  - `cat_id`: 카테고리 ID.
  - `item`: 설정 항목.
  - `callback`: 콜백 함수. 형식은 `callback(category_id: String, key: String, value: Variant)`입니다.
- **반환값**: 생성된 HBoxContainer.

### 예시

```gdscript
var row = UIFactory.create_control("audio", volume_item, func(category, key, value):
	print("설정 변경: %s/%s = %s" % [category, key, value])
	KND_Settings.set_setting(category, key, value)
)

# 컨테이너에 추가
vbox_container.add_child(row)
```

## 설정 패널(SettingsPanel)

설정 패널은 설정을 표시하고 관리하는 시각적 인터페이스입니다.

### 속성

- **_tab_container: TabContainer**: 서로 다른 카테고리의 설정을 표시하는 탭 컨테이너.
- **btn_reset: Button**: 기본값 복원 버튼.
- **btn_close: Button**: 닫기 버튼.

### 메서드

#### `rebuild() -> void`
- **설명**: UI를 다시 빌드합니다. 새 카테고리를 등록한 뒤 유용합니다.

### 시그널

- **btn_reset.pressed**: 기본값 복원 버튼을 클릭했을 때 발생합니다.
- **btn_close.pressed**: 닫기 버튼을 클릭했을 때 발생합니다.

### 예시

```gdscript
# 설정 패널 씬 로드
var settings_panel = preload("res://addons/universal_settings/scenes/settings_panel.tscn").instantiate()
add_child(settings_panel)

# 설정 패널 표시
settings_panel.show()

# 새 카테고리를 등록한 뒤 패널 다시 빌드
KND_Settings.register_category(new_category)
settings_panel.rebuild()
```

## 플랫폼 감지

설정 시스템은 현재 실행 플랫폼을 자동으로 감지하고, 설정 항목의 `platforms` 속성에 따라 표시 항목을 필터링합니다.

### 플랫폼 식별자

- `all` - 모든 플랫폼
- `android` - Android
- `bsd` - BSD
- `linux` - Linux
- `macos` - macOS
- `ios` - iOS
- `visionos` - visionOS
- `windows` - Windows
- `linuxbsd` - Linux 또는 BSD
- `debug` - 디버그 빌드
- `release` - 릴리스 빌드
- `editor` - 에디터 빌드

### 플랫폼 감지 로직

1. 먼저 에디터에서 실행 중인지 확인합니다.
2. `OS.has_feature()`로 구체적인 플랫폼을 감지합니다.
3. 감지 결과에 따라 현재 플랫폼 식별자를 설정합니다.
4. 카테고리를 가져올 때 플랫폼에 따라 설정 항목을 필터링합니다.

## 영구 저장

설정 값은 Godot의 `ConfigFile` 형식으로 `user://knd_settings.cfg` 파일에 자동 저장됩니다.

### 저장 시점

- `set_setting()` 메서드를 호출할 때.
- 설정 값이 자동으로 설정 파일에 기록됩니다.

### 로드 시점

- 플러그인이 초기화될 때.
- 저장된 설정 값이 설정 파일에서 자동으로 로드됩니다.

## 전체 사용 예시

### 1. 기본 사용

```gdscript
# 설정 값 가져오기
var master_volume = KND_Settings.get_setting("audio", "master_volume")

# 값 설정
KND_Settings.set_setting("audio", "master_volume", 0.8)

# 설정 변경 감지
KND_Settings.setting_changed.connect(func(category, key, value):
	if category == "audio" and key == "master_volume":
		# 볼륨 변경 처리
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(value))
)
```

### 2. 실행 중 새 설정 등록

```gdscript
# 새 설정 카테고리 만들기
var video_cat = SettingCategory.new()
video_cat.id = "video"
video_cat.display_name = "비디오"

# 설정 항목 만들기
var resolution_item = SettingItem.new()
resolution_item.key = "resolution"
resolution_item.label = "해상도"
resolution_item.type = SettingItem.Type.OPTION
resolution_item.options = ["1280x720", "1920x1080", "2560x1440"]
resolution_item.default_value = "1920x1080"

# 카테고리에 추가
video_cat.items.append(resolution_item)

# 카테고리 등록
KND_Settings.register_category(video_cat)

# 설정 패널이 이미 표시되어 있다면 다시 빌드
if settings_panel:
	settings_panel.rebuild()
```

### 3. 사용자 정의 설정 패널

```gdscript
# 사용자 정의 설정 패널 만들기
var panel = CanvasLayer.new()

# 탭 컨테이너 만들기
var tab_container = TabContainer.new()
tab_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
tab_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
panel.add_child(tab_container)

# 설정 UI 구성
var mgr = KND_Settings
for cat in mgr.get_categories():
	var scroll = ScrollContainer.new()
	scroll.name = cat.display_name
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(vbox)

	for item in cat.items:
		var row = UIFactory.create_control(cat.id, item, func(cat_id, key, value):
			mgr.set_setting(cat_id, key, value)
		)
		vbox.add_child(row)

	tab_container.add_child(scroll)

# 씬에 추가
add_child(panel)
```

## 주의 사항

- 모든 API 호출은 게임이 시작된 뒤에 수행해야 합니다.
- 새 카테고리를 등록한 뒤에는 `rebuild()` 메서드를 호출해 설정 패널을 갱신해야 합니다.
- 플랫폼 필터링은 설정 항목의 표시 여부에만 영향을 주며, 설정 값 저장에는 영향을 주지 않습니다.
- 설정 항목의 `key`는 카테고리 안에서 고유해야 합니다.
- 옵션 타입에서는 기본값이 반드시 `options` 목록 안에 있어야 합니다.

## 오류 처리

- 설정 항목이 존재하지 않으면 `get_setting()`은 null을 반환하고 경고를 발생시킵니다.
- 설정 파일 형식이 잘못되면 경고를 발생시키고 기본값을 사용합니다.
- 플랫폼 감지에 실패하면 기본값으로 `all` 플랫폼을 사용합니다.

## 성능 고려 사항

- 설정 시스템은 지연 로드를 사용하며 필요할 때만 설정 파일을 파싱합니다.
- 플랫폼 필터링은 카테고리를 가져올 때 수행되므로 설정 값 접근 성능에는 영향을 주지 않습니다.
- UI는 필요할 때 생성되며, 설정 패널을 표시할 때만 컨트롤을 만듭니다.

## 확장 제안

1. **새 설정 타입 추가**:
   - `SettingItem.Type`에 새 열거형 값을 추가합니다.
   - `UIFactory`에 대응하는 생성 로직을 추가합니다.

2. **저장 방식 사용자 정의**:
   - `settings_manager.gd`의 `_load_saved()`와 `set_setting()` 메서드를 수정합니다.
   - 사용자 정의 저장 및 로드 로직을 구현합니다.

3. **설정 검증 추가**:
   - `set_setting()`에 값 검증 로직을 추가합니다.
   - 설정 값이 유효한 범위 안에 있는지 보장합니다.

4. **국제화 지원 추가**:
   - `display_name`과 `label` 처리 로직을 수정합니다.
   - 다국어 설정 인터페이스를 지원합니다.
