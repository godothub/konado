extends RefCounted
class_name KonadoCallStack

## call/return 调用栈。每帧记录返回点、调用指令键与调用时的 Program 指纹。
## 栈属于运行期状态：会随 delta 历史、行快照与存档一起保存/恢复。
## 语义分析器会在编译期拒绝递归调用，MAX_DEPTH 仅作为运行期防御。

const MAX_DEPTH := 256

var frames: Array[Dictionary] = []


## 压入一个调用帧。返回点必须落在当前 Program 内；达到层数上限时不修改栈。
func push(return_pc: int, instruction_key: String, program_fingerprint: String) -> bool:
	if return_pc < 0 or frames.size() >= MAX_DEPTH:
		return false
	(
		frames
		. append(
			{
				"return_pc": return_pc,
				"key": instruction_key,
				"program": program_fingerprint,
			}
		)
	)
	return true


## 读取最内层调用帧；空栈返回空字典。
func peek() -> Dictionary:
	if frames.is_empty():
		return {}
	return frames[frames.size() - 1].duplicate(true)


## 弹出最内层调用帧；空栈返回空字典。
func pop() -> Dictionary:
	if frames.is_empty():
		return {}
	return (frames.pop_back() as Dictionary).duplicate(true)


func clear() -> void:
	frames.clear()


func is_empty() -> bool:
	return frames.is_empty()


func depth() -> int:
	return frames.size()


## 导出为纯数据，供状态捕获与存档持有；调用方不得依赖内部引用。
func export_frames() -> Array:
	var result: Array = []
	for frame: Dictionary in frames:
		result.append(frame.duplicate(true))
	return result


## 从状态/存档恢复调用栈。任一帧非法时整体拒绝，避免把 pc 跳到错误位置。
func restore_frames(value: Variant, instruction_count := -1) -> bool:
	if not is_valid_frames(value, instruction_count):
		return false
	frames.clear()
	for entry: Variant in value as Array:
		var frame: Dictionary = entry
		(
			frames
			. append(
				{
					"return_pc": int(frame.get("return_pc", 0)),
					"key": String(frame.get("key", "")),
					"program": String(frame.get("program", "")),
				}
			)
		)
	return true


## 校验调用栈数据；instruction_count 用于拒绝指向 Program 之外的返回点。
static func is_valid_frames(value: Variant, instruction_count := -1) -> bool:
	if not value is Array or (value as Array).size() > MAX_DEPTH:
		return false
	for entry: Variant in value as Array:
		if not entry is Dictionary:
			return false
		var frame: Dictionary = entry
		var return_pc: Variant = frame.get("return_pc", null)
		if not return_pc is int or int(return_pc) < 0:
			return false
		if instruction_count >= 0 and int(return_pc) >= instruction_count:
			return false
		if not frame.get("key", "") is String or not frame.get("program", "") is String:
			return false
	return true
