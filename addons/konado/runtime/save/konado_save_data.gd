class_name KonadoSaveData

## Konado 2.9 save envelope. The payload always references an exact Program
## fingerprint and an atomic execution boundary.

const FORMAT_VERSION := 2

var execution: Dictionary = {}
var runtime_state: Dictionary = {}
var save_time: Dictionary = {}
var format_version := FORMAT_VERSION
var compiler_abi := KonadoProgram.COMPILER_ABI


func to_dict() -> Dictionary:
	return {
		"format_version": format_version,
		"compiler_abi": compiler_abi,
		"execution": execution,
		"runtime_state": runtime_state,
		"save_time": save_time,
	}


func from_dict(data: Dictionary) -> bool:
	format_version = int(data.get("format_version", -1))
	compiler_abi = String(data.get("compiler_abi", ""))
	if format_version != FORMAT_VERSION or compiler_abi != KonadoProgram.COMPILER_ABI:
		return false
	execution = data.get("execution", {}).duplicate(true)
	runtime_state = data.get("runtime_state", {}).duplicate(true)
	save_time = data.get("save_time", {}).duplicate(true)
	return not execution.is_empty() and not runtime_state.is_empty()
