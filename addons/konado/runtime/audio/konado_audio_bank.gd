extends Resource
class_name KonadoAudioBank

## 音频资源包：按章节/场景/语言分组事件，运行期可按需加载与统计体积。
## 对标 Wwise SoundBank / FMOD Bank。

@export var bank_name: StringName = &""
## 语言标记（例如 "zh"、"en"）；为空表示与语言无关（BGM/SFX）。
## 剧本热切换语言时只会重新装载语言包，音乐音效不受影响。
@export var locale := ""
@export var events: Array[KonadoAudioEvent] = []
