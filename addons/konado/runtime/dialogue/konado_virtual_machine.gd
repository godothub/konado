extends RefCounted
class_name KonadoVirtualMachine

## Atomic Program counter and bounded execution history.

enum Result { COMPLETED, WAITING, CANCELLED, FAILED, BARRIER, SKIPPED }

const DEFAULT_HISTORY_LIMIT := 512
const DEFAULT_CHECKPOINT_LIMIT := 32
const DEFAULT_HISTORY_BYTES_LIMIT := 8 * 1024 * 1024
const DEFAULT_CHECKPOINT_BYTES_LIMIT := 8 * 1024 * 1024
const MAX_HISTORY_LIMIT := 100_000
const MAX_CHECKPOINT_LIMIT := 4096
const MAX_RETENTION_BYTES := 256 * 1024 * 1024

var program: KonadoProgram
var pc := KonadoProgram.INVALID_PC
var generation := 0
var history_limit := DEFAULT_HISTORY_LIMIT
var checkpoint_limit := DEFAULT_CHECKPOINT_LIMIT
var history_bytes_limit := DEFAULT_HISTORY_BYTES_LIMIT
var checkpoint_bytes_limit := DEFAULT_CHECKPOINT_BYTES_LIMIT

var _active_token: Dictionary = {}
var _rewind_skip_keys: Dictionary = {}
var _history_slots: Array[Dictionary] = []
var _history_head := 0
var _history_count := 0
var _checkpoints: Dictionary = {}
var _checkpoint_order := PackedStringArray()
var _checkpoint_serial := 0
var _current_state: Dictionary = {}
var _history_bytes_total := 0
var _checkpoint_bytes_total := 0
var _commit_serial := 0
var _last_restore_preserved := true


func install(new_program: KonadoProgram, start_pc := KonadoProgram.INVALID_PC) -> bool:
	if new_program == null or not new_program.is_valid():
		return false
	var target_pc := new_program.entry_pc if start_pc == KonadoProgram.INVALID_PC else start_pc
	if target_pc < 0 or target_pc >= new_program.instruction_count():
		return false
	cancel()
	program = null
	pc = KonadoProgram.INVALID_PC
	_current_state.clear()
	clear_history()
	program = new_program
	pc = target_pc
	return true


func current() -> KonadoInstruction:
	return program.instruction_at(pc) if program != null else null


func begin(state_before: Dictionary) -> Dictionary:
	return _begin(state_before, false)


func begin_patch(state_before_patch: Dictionary) -> Dictionary:
	return _begin(state_before_patch, true)


func _begin(state_before: Dictionary, is_patch: bool) -> Dictionary:
	if program == null or _active_token.size() > 0 or pc < 0 or pc >= program.instruction_count():
		return {}
	_current_state = (
		KonadoStateDelta.apply(_current_state, state_before)
		if is_patch
		else KonadoStateDelta.merge(_current_state, state_before)
	)
	_active_token = {
		"generation": generation,
		"pc": pc,
		"key": program.key_for_pc(pc),
	}
	return _active_token.duplicate(true)


func commit(
	token: Dictionary,
	next_pc: int,
	state_after: Dictionary,
	result := Result.COMPLETED,
) -> bool:
	return _commit(token, program, next_pc, state_after, result, false)


func commit_patch(
	token: Dictionary,
	next_pc: int,
	state_after_patch: Dictionary,
	result := Result.COMPLETED,
) -> bool:
	return _commit(token, program, next_pc, state_after_patch, result, true)


func transition(
	token: Dictionary,
	new_program: KonadoProgram,
	start_pc: int,
	state_after: Dictionary,
) -> bool:
	if new_program == null or not new_program.is_valid():
		return false
	return _commit(token, new_program, start_pc, state_after, Result.COMPLETED, false)


func _commit(
	token: Dictionary,
	destination_program: KonadoProgram,
	next_pc: int,
	state_after: Dictionary,
	result: int,
	is_patch: bool,
) -> bool:
	if not _token_is_current(token):
		return false
	var source_program := program
	var opcode := program.opcode_at(pc)
	if (
		next_pc != KonadoProgram.INVALID_PC
		and (next_pc < 0 or next_pc >= destination_program.instruction_count())
	):
		return false
	var delta := KonadoStateDelta.for_patch(_current_state, state_after) if is_patch else {}
	var next_state := (
		KonadoStateDelta.apply(_current_state, delta.forward)
		if is_patch
		else KonadoStateDelta.merge(_current_state, state_after)
	)
	if not is_patch:
		delta = KonadoStateDelta.between(_current_state, next_state)
	_commit_serial += 1
	var record := {
		"serial": _commit_serial,
		"pc": pc,
		"key": program.key_for_pc(pc),
		"opcode": opcode,
		"opcode_name": KonadoOpcode.name_of(opcode),
		"line": program.line_for_pc(pc),
		"source_path": program.source_path,
		"result": result,
		"barrier":
		(
			KonadoScriptCommandRegistry.rollback_policy(opcode)
			== KonadoScriptCommandRegistry.ROLLBACK_BARRIER
		),
		"reverse_delta": delta.reverse,
		"forward_delta": delta.forward,
		"committed_usec": Time.get_ticks_usec(),
		"_program_before": source_program,
		"_program_after": destination_program,
	}
	record["estimated_bytes"] = (
		256
		+ KonadoStateDelta.estimate_bytes(record.reverse_delta)
		+ KonadoStateDelta.estimate_bytes(record.forward_delta)
	)
	_append_history(record)
	while _history_count > 0 and _history_bytes_total > _history_bytes_capacity():
		_remove_oldest()
	_current_state = next_state
	program = destination_program
	pc = next_pc
	_active_token.clear()
	return true


func fail(token: Dictionary) -> bool:
	if not _token_is_current(token):
		return false
	_active_token.clear()
	return true


func _commit_skipped(token: Dictionary, next_pc: int) -> bool:
	return _commit(token, program, next_pc, {}, Result.SKIPPED, true)


func cancel() -> void:
	generation += 1
	_active_token.clear()


func can_rollback(steps := 1, allow_cancelling_active := false, allow_barriers := false) -> bool:
	if (
		steps <= 0
		or steps > _history_count
		or (not allow_cancelling_active and not _active_token.is_empty())
	):
		return false
	for offset in range(steps - 1, -1, -1):
		# allow_barriers 供“回到上一句”这类玩家回退使用：不可逆副作用不阻断回退，
		# 由调用方保证重放时不重复执行这些指令。
		if allow_barriers or not bool(_record_from_end(offset)["barrier"]):
			continue
		return false
	return true


func rollback(
	steps: int, restore: Callable, allow_cancelling_active := false, allow_barriers := false
) -> bool:
	_last_restore_preserved = true
	if not can_rollback(steps, allow_cancelling_active, allow_barriers) or not restore.is_valid():
		return false
	var restored_state := _current_state.duplicate(true)
	for offset in range(steps):
		restored_state = KonadoStateDelta.apply(
			restored_state, _record_from_end(offset).reverse_delta
		)
	var target := _record_from_end(steps - 1)
	var previous_program := program
	var previous_state := _current_state.duplicate(true)
	program = target.get("_program_before") as KonadoProgram
	if program == null:
		program = previous_program
		return false
	if not bool(restore.call(restored_state)):
		program = previous_program
		# A restore implementation may have applied part of the candidate state before
		# reporting failure. Reapply the last committed boundary so an active failure
		# transaction remains safely retryable.
		_last_restore_preserved = bool(restore.call(previous_state))
		return false
	_active_token.clear()
	pc = int(target["pc"])
	for _index in range(steps):
		_pop_newest()
	_current_state = restored_state
	generation += 1
	return true


## 登记“回退时已跨越、重放时不得重复执行”的不可逆指令键。
## 同一指令在回退区间内可能执行多次（例如循环），因此按次数登记，
## 重放时每遇到一次消费一次，避免只跳过第一次而让后续执行二次累计。
func _prepare_rewind_skips(keys: PackedStringArray) -> void:
	for key: String in keys:
		if not key.is_empty():
			_rewind_skip_keys[key] = int(_rewind_skip_keys.get(key, 0)) + 1


## 跳过键带上剧本来源路径，避免不同剧本复用相同稳定键时误用。
func _rewind_skip_key(instruction_key: String) -> String:
	var source_path := program.source_path if program != null else ""
	return "%s|%s" % [source_path, instruction_key]


func _should_skip_rewind(instruction_key: String) -> bool:
	return int(_rewind_skip_keys.get(_rewind_skip_key(instruction_key), 0)) > 0


func _consume_rewind_skip(instruction_key: String) -> void:
	var key := _rewind_skip_key(instruction_key)
	var remaining := int(_rewind_skip_keys.get(key, 0))
	if remaining <= 1:
		_rewind_skip_keys.erase(key)
	else:
		_rewind_skip_keys[key] = remaining - 1


func create_checkpoint(label: String, state: Dictionary) -> String:
	if _checkpoint_capacity() <= 0 or _checkpoint_bytes_capacity() <= 0:
		return ""
	_checkpoint_serial += 1
	var checkpoint_id := label if not label.is_empty() else "checkpoint-%d" % _checkpoint_serial
	return _store_checkpoint(checkpoint_id, pc, state)


func _store_checkpoint(checkpoint_id: String, checkpoint_pc: int, state: Dictionary) -> String:
	if program == null or checkpoint_pc < 0 or checkpoint_pc >= program.instruction_count():
		return ""
	var estimated_bytes := KonadoStateDelta.estimate_bytes(state) + 192
	if estimated_bytes > _checkpoint_bytes_capacity():
		return ""
	if _checkpoints.has(checkpoint_id):
		_checkpoint_serial += 1
		checkpoint_id += "-%d" % _checkpoint_serial
	_checkpoints[checkpoint_id] = {
		"fingerprint": program.fingerprint() if program != null else "",
		"program": program,
		"pc": checkpoint_pc,
		"state": state.duplicate(true),
		"estimated_bytes": estimated_bytes,
	}
	_checkpoint_bytes_total += estimated_bytes
	_checkpoint_order.append(checkpoint_id)
	while (
		_checkpoint_order.size() > _checkpoint_capacity()
		or _checkpoint_bytes_total > _checkpoint_bytes_capacity()
	):
		_remove_oldest_checkpoint()
	return checkpoint_id


func _can_restore_checkpoint(checkpoint_id: String, allow_cancelling_active := false) -> bool:
	if (
		not _checkpoints.has(checkpoint_id)
		or (not allow_cancelling_active and not _active_token.is_empty())
	):
		return false
	var checkpoint: Dictionary = _checkpoints[checkpoint_id]
	var checkpoint_program := checkpoint.get("program") as KonadoProgram
	return not (
		checkpoint_program == null
		or not checkpoint_program.is_valid()
		or checkpoint["fingerprint"] != checkpoint_program.fingerprint()
		or int(checkpoint.get("pc", KonadoProgram.INVALID_PC)) < 0
		or (
			int(checkpoint.get("pc", KonadoProgram.INVALID_PC))
			>= checkpoint_program.instruction_count()
		)
		or not checkpoint.get("state", {}) is Dictionary
	)


func restore_checkpoint(
	checkpoint_id: String, restore: Callable, allow_cancelling_active := false
) -> bool:
	_last_restore_preserved = true
	if (
		not _can_restore_checkpoint(checkpoint_id, allow_cancelling_active)
		or not restore.is_valid()
	):
		return false
	var checkpoint: Dictionary = _checkpoints[checkpoint_id]
	var checkpoint_program := checkpoint.get("program") as KonadoProgram
	var previous_program := program
	var previous_state := _current_state.duplicate(true)
	program = checkpoint_program
	if not bool(restore.call(checkpoint["state"])):
		program = previous_program
		_last_restore_preserved = bool(restore.call(previous_state))
		return false
	cancel()
	pc = int(checkpoint["pc"])
	_current_state = checkpoint["state"].duplicate(true)
	# Records after the restored boundary belong to an abandoned timeline and
	# must not remain rollback candidates.
	_clear_history_records(false)
	return true


func history(limit := 0) -> Array[Dictionary]:
	var start := 0 if limit <= 0 else maxi(0, _history_count - limit)
	var result: Array[Dictionary] = []
	for offset in range(start, _history_count):
		var index := (_history_head + offset) % _history_slots.size()
		result.append(_public_record(_history_slots[index]))
	return result


func history_size() -> int:
	return _history_count


func snapshot_state() -> Dictionary:
	return _current_state.duplicate(true)


func has_state() -> bool:
	return not _current_state.is_empty()


func synchronize_state(state: Dictionary) -> void:
	_current_state = state.duplicate(true)


func restore_boundary(new_program: KonadoProgram, start_pc: int, state: Dictionary) -> bool:
	if not install(new_program, start_pc):
		return false
	_current_state = state.duplicate(true)
	return true


func clear_history() -> void:
	_clear_history_records(true)
	_checkpoints.clear()
	_checkpoint_order.clear()
	_checkpoint_bytes_total = 0
	# 已登记的重放跳过键指向的是被清掉的历史记录，必须同时失效。
	_rewind_skip_keys.clear()


func _last_failed_restore_preserved_state() -> bool:
	return _last_restore_preserved


func _clear_history_records(reset_serial: bool) -> void:
	_history_slots.clear()
	_history_slots.resize(_history_capacity())
	_history_head = 0
	_history_count = 0
	_history_bytes_total = 0
	if reset_serial:
		_commit_serial = 0


func _append_history(record: Dictionary) -> void:
	var capacity := _history_capacity()
	if capacity <= 0 or _history_bytes_capacity() <= 0:
		_resize_history_storage(0)
		return
	if _history_slots.size() != capacity:
		_resize_history_storage(capacity)
	if _history_count == _history_slots.size():
		_remove_oldest()
	var index := (_history_head + _history_count) % _history_slots.size()
	_history_slots[index] = record
	_history_count += 1
	_history_bytes_total += int(record.get("estimated_bytes", 0))


func _resize_history_storage(capacity: int) -> void:
	var retained: Array[Dictionary] = []
	var retain_count := mini(_history_count, maxi(0, capacity))
	var start := _history_count - retain_count
	for offset in range(start, _history_count):
		var index := (_history_head + offset) % _history_slots.size()
		retained.append(_history_slots[index])
	_history_slots.clear()
	_history_slots.resize(maxi(0, capacity))
	_history_head = 0
	_history_count = retained.size()
	_history_bytes_total = 0
	for index in range(retained.size()):
		_history_slots[index] = retained[index]
		_history_bytes_total += int(retained[index].get("estimated_bytes", 0))


func _remove_oldest() -> void:
	if _history_count <= 0:
		return
	var removed := _history_slots[_history_head]
	_history_bytes_total -= int(removed.get("estimated_bytes", 0))
	_history_slots[_history_head] = {}
	_history_head = (_history_head + 1) % _history_slots.size()
	_history_count -= 1


func _record_from_end(offset: int) -> Dictionary:
	var chronological_offset := _history_count - 1 - offset
	var index := (_history_head + chronological_offset) % _history_slots.size()
	return _history_slots[index]


func _pop_newest() -> void:
	if _history_count <= 0:
		return
	var index := (_history_head + _history_count - 1) % _history_slots.size()
	var removed := _history_slots[index]
	_history_bytes_total -= int(removed.get("estimated_bytes", 0))
	_history_slots[index] = {}
	_history_count -= 1


func _remove_oldest_checkpoint() -> void:
	if _checkpoint_order.is_empty():
		return
	var checkpoint_id := _checkpoint_order[0]
	var checkpoint: Dictionary = _checkpoints.get(checkpoint_id, {})
	_checkpoint_bytes_total -= int(checkpoint.get("estimated_bytes", 0))
	_checkpoints.erase(checkpoint_id)
	_checkpoint_order.remove_at(0)


func _history_capacity() -> int:
	return clampi(history_limit, 0, MAX_HISTORY_LIMIT)


func _checkpoint_capacity() -> int:
	return clampi(checkpoint_limit, 0, MAX_CHECKPOINT_LIMIT)


func _history_bytes_capacity() -> int:
	return clampi(history_bytes_limit, 0, MAX_RETENTION_BYTES)


func _checkpoint_bytes_capacity() -> int:
	return clampi(checkpoint_bytes_limit, 0, MAX_RETENTION_BYTES)


func _token_is_current(token: Dictionary) -> bool:
	return (
		not token.is_empty()
		and token == _active_token
		and int(token.get("generation", -1)) == generation
		and int(token.get("pc", KonadoProgram.INVALID_PC)) == pc
	)


func _public_record(record: Dictionary) -> Dictionary:
	var result := record.duplicate(true)
	result.erase("_program_before")
	result.erase("_program_after")
	return result
