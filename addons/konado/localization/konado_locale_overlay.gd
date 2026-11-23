extends Resource
class_name KonadoLocaleOverlay

## Localizable values layered over one immutable default Program.

@export_storage var locale := ""
@export_storage var program_control_flow_sha256 := ""
@export_storage var values: Dictionary = {}  # stable key -> operand name -> decoded value


func is_compatible(program: KonadoProgram) -> bool:
	return (
		program != null
		and program.is_valid()
		and not program_control_flow_sha256.is_empty()
		and program_control_flow_sha256 == program.control_flow_sha256
	)


func value_for(stable_key: String, operand: StringName, default: Variant) -> Variant:
	var instruction_values: Dictionary = values.get(stable_key, {})
	return instruction_values.get(String(operand), default)


static func build(
	base: KonadoProgram, localized: KonadoProgram, target_locale: String
) -> Dictionary:
	var errors: Array[String] = []
	if base == null or localized == null or not base.is_valid() or not localized.is_valid():
		return {"ok": false, "errors": ["本地化 Program 无效"]}
	if base.instruction_count() != localized.instruction_count():
		return {"ok": false, "errors": ["本地化剧本的指令数与默认剧本不一致"]}
	var overlay := KonadoLocaleOverlay.new()
	overlay.locale = target_locale
	overlay.program_control_flow_sha256 = base.control_flow_sha256
	for pc in range(base.instruction_count()):
		if base.opcode_at(pc) != localized.opcode_at(pc):
			errors.append("第 %d 行：本地化指令类型与默认剧本不一致" % localized.line_for_pc(pc))
			continue
		if base.key_for_pc(pc) != localized.key_for_pc(pc):
			errors.append("第 %d 行：本地化指令 ID 与默认剧本不一致" % localized.line_for_pc(pc))
			continue
		if not _same_edges(base, localized, pc):
			errors.append("第 %d 行：本地化剧本不得修改控制流" % localized.line_for_pc(pc))
			continue
		var base_instruction := base.instruction_at(pc)
		var localized_instruction := localized.instruction_at(pc)
		var localized_values := {}
		for field: Array in KonadoScriptCommandRegistry.schema_for(base.opcode_at(pc)):
			var name := StringName(field[0])
			var base_value := base_instruction.value(name)
			var localized_value := localized_instruction.value(name)
			if _is_speaker_variable(base_instruction, name):
				if localized_value != base_value:
					errors.append("第 %d 行：本地化剧本不得修改署名变量" % localized.line_for_pc(pc))
				continue
			if String(field[1]) == KonadoScriptCommandRegistry.CHOICES:
				var choice_result := _localized_choices(
					base_value, localized_value, localized.line_for_pc(pc)
				)
				if not bool(choice_result["ok"]):
					errors.append_array(choice_result["errors"])
				elif choice_result["value"] != base_value:
					localized_values[String(name)] = choice_result["value"]
				continue
			if bool(field[2]):
				if localized_value != base_value:
					localized_values[String(name)] = localized_value
			elif localized_value != base_value:
				errors.append(
					"第 %d 行：本地化剧本修改了结构字段 '%s'" % [localized.line_for_pc(pc), String(name)]
				)
		if not localized_values.is_empty():
			overlay.values[base.key_for_pc(pc)] = localized_values
	return {"ok": errors.is_empty(), "errors": errors, "overlay": overlay}


static func _is_speaker_variable(instruction: KonadoInstruction, name: StringName) -> bool:
	if instruction.opcode() != KonadoOpcode.Type.DIALOGUE or name != &"speaker":
		return false
	return (
		int(instruction.value(&"speaker_kind"))
		in [
			KonadoScriptSyntaxTree.DialogueNode.SpeakerKind.TEMPORARY_VARIABLE,
			KonadoScriptSyntaxTree.DialogueNode.SpeakerKind.PERSISTENT_VARIABLE,
		]
	)


static func _localized_choices(base: Array, localized: Array, line: int) -> Dictionary:
	var errors: Array[String] = []
	if base.size() != localized.size():
		return {
			"ok": false,
			"errors": ["第 %d 行：本地化选项数与默认剧本不一致" % line],
			"value": [],
		}
	var value: Array[Dictionary] = []
	for index in range(base.size()):
		var base_choice: Dictionary = base[index]
		var localized_choice: Dictionary = localized[index]
		if int(base_choice.get("target_pc", -1)) != int(localized_choice.get("target_pc", -1)):
			errors.append("第 %d 行：本地化选项 %d 不得修改跳转目标" % [line, index + 1])
		if int(base_choice.get("index", -1)) != int(localized_choice.get("index", -1)):
			errors.append("第 %d 行：本地化选项顺序与默认剧本不一致" % line)
		(
			value
			. append(
				{
					"text": String(localized_choice.get("text", "")),
					"target_pc": int(base_choice.get("target_pc", -1)),
					"index": int(base_choice.get("index", -1)),
				}
			)
		)
	return {"ok": errors.is_empty(), "errors": errors, "value": value}


static func _same_edges(left: KonadoProgram, right: KonadoProgram, pc: int) -> bool:
	return (
		left.next_pcs[pc] == right.next_pcs[pc]
		and left.true_pcs[pc] == right.true_pcs[pc]
		and left.false_pcs[pc] == right.false_pcs[pc]
	)
