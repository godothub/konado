extends Resource
class_name KonadoAudioParameter

## 剧情变量到音频增益的映射（对标 Wwise RTPC / FMOD Parameter）。
## curve 横轴为变量值、纵轴为线性增益倍率；没有 curve 时按 minimum/maximum 线性插值。

## 变量引用，例如 "%love"（持久变量）或 "$tension"（临时变量）。
@export var variable := ""
## 变量低于 minimum 或高于 maximum 时是否直接跳过事件（用于“条件音效”）。
@export var gates_event := false
@export var minimum := 0.0
@export var maximum := 100.0
@export var gain_floor := 1.0
@export var gain_ceiling := 1.0
@export var curve: Curve = null


func is_valid() -> bool:
	return variable.begins_with("%") or variable.begins_with("$")


## 返回 {gated: bool, gain: float}；gain 为线性倍率。
func evaluate(values: Dictionary) -> Dictionary:
	var raw: Variant = values.get(variable)
	if raw == null:
		return {"gated": gates_event, "gain": 1.0}
	var value := float(raw)
	if gates_event and (value < minimum or value > maximum):
		return {"gated": true, "gain": 0.0}
	if curve != null:
		var sampled := curve.sample_baked(clampf(value, minimum, maximum))
		return {"gated": false, "gain": maxf(0.0, sampled)}
	var span := maximum - minimum
	var weight := 0.0 if is_zero_approx(span) else clampf((value - minimum) / span, 0.0, 1.0)
	return {"gated": false, "gain": lerpf(gain_floor, gain_ceiling, weight)}
