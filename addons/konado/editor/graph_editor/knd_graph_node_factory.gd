@tool
class_name KndGraphNodeFactory

const FLOW_PORT := 0
const BRANCH_PORT := 0
const FLOW_COLOR := Color(0.85, 0.85, 0.85)
const BRANCH_COLOR := Color(1.0, 0.75, 0.2)
const TRUE_COLOR := Color(0.3, 0.9, 0.3)
const FALSE_COLOR := Color(0.9, 0.3, 0.3)

const TYPE_TITLES := {
	KND_Dialogue.Type.ORDINARY_DIALOG: "Dialogue",
	KND_Dialogue.Type.DISPLAY_ACTOR: "Actor Show",
	KND_Dialogue.Type.ACTOR_CHANGE_STATE: "Actor Change",
	KND_Dialogue.Type.MOVE_ACTOR: "Actor Move",
	KND_Dialogue.Type.EXIT_ACTOR: "Actor Exit",
	KND_Dialogue.Type.SWITCH_BACKGROUND: "Background",
	KND_Dialogue.Type.PLAY_BGM: "Play BGM",
	KND_Dialogue.Type.STOP_BGM: "Stop BGM",
	KND_Dialogue.Type.PLAY_SOUND_EFFECT: "Play SFX",
	KND_Dialogue.Type.SHOW_CHOICE: "Choice",
	KND_Dialogue.Type.IFELSE_BRANCH: "Condition",
	KND_Dialogue.Type.BRANCH: "Branch",
	KND_Dialogue.Type.JUMP: "Jump",
	KND_Dialogue.Type.SIGNAL: "Signal",
	KND_Dialogue.Type.THE_END: "End",
}

const TYPE_COLORS := {
	KND_Dialogue.Type.ORDINARY_DIALOG: Color("3a6fdb"),
	KND_Dialogue.Type.DISPLAY_ACTOR: Color("2d8a4e"),
	KND_Dialogue.Type.ACTOR_CHANGE_STATE: Color("2d8a4e"),
	KND_Dialogue.Type.MOVE_ACTOR: Color("2d8a4e"),
	KND_Dialogue.Type.EXIT_ACTOR: Color("8a2d2d"),
	KND_Dialogue.Type.SWITCH_BACKGROUND: Color("7a3dba"),
	KND_Dialogue.Type.PLAY_BGM: Color("ba7a3d"),
	KND_Dialogue.Type.STOP_BGM: Color("ba7a3d"),
	KND_Dialogue.Type.PLAY_SOUND_EFFECT: Color("ba7a3d"),
	KND_Dialogue.Type.SHOW_CHOICE: Color("b8a832"),
	KND_Dialogue.Type.IFELSE_BRANCH: Color("ba5a2d"),
	KND_Dialogue.Type.BRANCH: Color("4a8a3d"),
	KND_Dialogue.Type.JUMP: Color("2da5a5"),
	KND_Dialogue.Type.SIGNAL: Color("a53da5"),
	KND_Dialogue.Type.THE_END: Color("a52d2d"),
}


static func create(type: KND_Dialogue.Type, d: KND_Dialogue = null) -> GraphNode:
	match type:
		KND_Dialogue.Type.ORDINARY_DIALOG: return _dialogue(d)
		KND_Dialogue.Type.DISPLAY_ACTOR: return _actor_show(d)
		KND_Dialogue.Type.ACTOR_CHANGE_STATE: return _actor_change(d)
		KND_Dialogue.Type.MOVE_ACTOR: return _actor_move(d)
		KND_Dialogue.Type.EXIT_ACTOR: return _actor_exit(d)
		KND_Dialogue.Type.SWITCH_BACKGROUND: return _background(d)
		KND_Dialogue.Type.PLAY_BGM: return _play_bgm(d)
		KND_Dialogue.Type.STOP_BGM: return _stop_bgm(d)
		KND_Dialogue.Type.PLAY_SOUND_EFFECT: return _play_sfx(d)
		KND_Dialogue.Type.SHOW_CHOICE: return _choice(d)
		KND_Dialogue.Type.IFELSE_BRANCH: return _condition(d)
		KND_Dialogue.Type.JUMP: return _jump(d)
		KND_Dialogue.Type.SIGNAL: return _signal_node(d)
		KND_Dialogue.Type.THE_END: return _end(d)
	return _base("Unknown", Color.GRAY)


static func read_fields(node: GraphNode) -> KND_Dialogue:
	var d := KND_Dialogue.new()
	var type: KND_Dialogue.Type = node.get_meta("dialogue_type")
	d.dialog_type = type
	var f: Dictionary = node.get_meta("fields", {})
	match type:
		KND_Dialogue.Type.ORDINARY_DIALOG:
			d.character_id = _val(f, "character_id")
			d.dialog_content = _tval(f, "dialog_content")
			d.voice_id = _val(f, "voice_id")
		KND_Dialogue.Type.DISPLAY_ACTOR:
			d.character_name = _val(f, "character_name")
			d.character_state = _val(f, "character_state")
			d.actor_position = Vector2(_fval(f, "pos_x"), _fval(f, "pos_y"))
			d.actor_scale = _fval(f, "actor_scale")
		KND_Dialogue.Type.ACTOR_CHANGE_STATE:
			d.change_state_actor = _val(f, "change_state_actor")
			d.change_state = _val(f, "change_state")
		KND_Dialogue.Type.MOVE_ACTOR:
			d.target_move_chara = _val(f, "target_move_chara")
			d.target_move_pos = Vector2(_fval(f, "pos_x"), _fval(f, "pos_y"))
		KND_Dialogue.Type.EXIT_ACTOR:
			d.exit_actor = _val(f, "exit_actor")
		KND_Dialogue.Type.SWITCH_BACKGROUND:
			d.background_image_name = _val(f, "bg_name")
			d.background_toggle_effects = _ival(f, "bg_effect") as KND_ActingInterface.BackgroundTransitionEffectsType
		KND_Dialogue.Type.PLAY_BGM:
			d.bgm_name = _val(f, "bgm_name")
		KND_Dialogue.Type.STOP_BGM:
			pass
		KND_Dialogue.Type.PLAY_SOUND_EFFECT:
			d.soundeffect_name = _val(f, "sfx_name")
		KND_Dialogue.Type.SHOW_CHOICE:
			var choice_fields: Array = f.get("choices", [])
			for cf in choice_fields:
				var c := KND_DialogueChoice.new()
				c.choice_text = cf["text"].text if cf.has("text") else ""
				# next_id is set by graph connections in the converter, not from UI fields
				d.choices.append(c)
		KND_Dialogue.Type.IFELSE_BRANCH:
			d.varname = _val(f, "varname")
			d.target_value = int(_val(f, "target_value"))
		KND_Dialogue.Type.JUMP:
			d.jump_shot_path = _val(f, "jump_path")
		KND_Dialogue.Type.SIGNAL:
			d.custom_signal_name = _val(f, "signal_name")
		KND_Dialogue.Type.THE_END:
			pass
	return d


# --- Node Builders ---

static func _base(title_text: String, color: Color) -> GraphNode:
	var n := GraphNode.new()
	n.title = title_text
	n.custom_minimum_size.x = 260
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_content_margin_all(6)
	sb.set_corner_radius_all(4)
	n.add_theme_stylebox_override("titlebar", sb)
	var sb_sel := sb.duplicate()
	sb_sel.bg_color = color.lightened(0.25)
	n.add_theme_stylebox_override("titlebar_selected", sb_sel)
	return n


static func _dialogue(d: KND_Dialogue) -> GraphNode:
	var n := _base("Dialogue", TYPE_COLORS[KND_Dialogue.Type.ORDINARY_DIALOG])
	n.set_meta("dialogue_type", KND_Dialogue.Type.ORDINARY_DIALOG)
	var f1 := _add_field(n, "Character", d.character_id if d else "")
	var te := TextEdit.new()
	te.text = d.dialog_content if d else ""
	te.custom_minimum_size = Vector2(220, 50)
	te.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	n.add_child(te)
	var f2 := _add_field(n, "Voice", d.voice_id if d else "")
	n.set_meta("fields", {"character_id": f1, "dialog_content": te, "voice_id": f2})
	n.set_slot(0, true, FLOW_PORT, FLOW_COLOR, true, FLOW_PORT, FLOW_COLOR)
	return n


static func _actor_show(d: KND_Dialogue) -> GraphNode:
	var n := _base("Actor Show", TYPE_COLORS[KND_Dialogue.Type.DISPLAY_ACTOR])
	n.set_meta("dialogue_type", KND_Dialogue.Type.DISPLAY_ACTOR)
	var f1 := _add_field(n, "Name", d.character_name if d else "")
	var f2 := _add_field(n, "State", d.character_state if d else "")
	var f3 := _add_field(n, "Pos X", str(d.actor_position.x) if d else "3")
	var f4 := _add_field(n, "Pos Y", str(d.actor_position.y) if d else "9")
	var f5 := _add_field(n, "Scale", str(d.actor_scale) if d else "0.3")

	n.set_meta("fields", {"character_name": f1, "character_state": f2, "pos_x": f3, "pos_y": f4, "actor_scale": f5})
	n.set_slot(0, true, FLOW_PORT, FLOW_COLOR, true, FLOW_PORT, FLOW_COLOR)
	return n


static func _actor_change(d: KND_Dialogue) -> GraphNode:
	var n := _base("Actor Change", TYPE_COLORS[KND_Dialogue.Type.ACTOR_CHANGE_STATE])
	n.set_meta("dialogue_type", KND_Dialogue.Type.ACTOR_CHANGE_STATE)
	var f1 := _add_field(n, "Actor", d.change_state_actor if d else "")
	var f2 := _add_field(n, "State", d.change_state if d else "")
	n.set_meta("fields", {"change_state_actor": f1, "change_state": f2})
	n.set_slot(0, true, FLOW_PORT, FLOW_COLOR, true, FLOW_PORT, FLOW_COLOR)
	return n


static func _actor_move(d: KND_Dialogue) -> GraphNode:
	var n := _base("Actor Move", TYPE_COLORS[KND_Dialogue.Type.MOVE_ACTOR])
	n.set_meta("dialogue_type", KND_Dialogue.Type.MOVE_ACTOR)
	var f1 := _add_field(n, "Actor", d.target_move_chara if d else "")
	var f2 := _add_field(n, "Pos X", str(d.target_move_pos.x) if d else "0")
	var f3 := _add_field(n, "Pos Y", str(d.target_move_pos.y) if d else "0")
	n.set_meta("fields", {"target_move_chara": f1, "pos_x": f2, "pos_y": f3})
	n.set_slot(0, true, FLOW_PORT, FLOW_COLOR, true, FLOW_PORT, FLOW_COLOR)
	return n


static func _actor_exit(d: KND_Dialogue) -> GraphNode:
	var n := _base("Actor Exit", TYPE_COLORS[KND_Dialogue.Type.EXIT_ACTOR])
	n.set_meta("dialogue_type", KND_Dialogue.Type.EXIT_ACTOR)
	var f1 := _add_field(n, "Actor", d.exit_actor if d else "")
	n.set_meta("fields", {"exit_actor": f1})
	n.set_slot(0, true, FLOW_PORT, FLOW_COLOR, true, FLOW_PORT, FLOW_COLOR)
	return n


static func _background(d: KND_Dialogue) -> GraphNode:
	var n := _base("Background", TYPE_COLORS[KND_Dialogue.Type.SWITCH_BACKGROUND])
	n.set_meta("dialogue_type", KND_Dialogue.Type.SWITCH_BACKGROUND)
	var f1 := _add_field(n, "Name", d.background_image_name if d else "")
	var opt := OptionButton.new()
	opt.add_item("none", 0)
	opt.add_item("erase", 1)
	opt.add_item("blinds", 2)
	opt.add_item("wave", 3)
	opt.add_item("fade", 4)
	opt.add_item("vortex", 5)
	opt.add_item("windmill", 6)
	opt.add_item("cyberglitch", 7)
	if d:
		opt.selected = d.background_toggle_effects
	n.add_child(opt)
	n.set_meta("fields", {"bg_name": f1, "bg_effect": opt})
	n.set_slot(0, true, FLOW_PORT, FLOW_COLOR, true, FLOW_PORT, FLOW_COLOR)
	return n


static func _play_bgm(d: KND_Dialogue) -> GraphNode:
	var n := _base("Play BGM", TYPE_COLORS[KND_Dialogue.Type.PLAY_BGM])
	n.set_meta("dialogue_type", KND_Dialogue.Type.PLAY_BGM)
	var f1 := _add_field(n, "BGM", d.bgm_name if d else "")
	n.set_meta("fields", {"bgm_name": f1})
	n.set_slot(0, true, FLOW_PORT, FLOW_COLOR, true, FLOW_PORT, FLOW_COLOR)
	return n


static func _stop_bgm(_d: KND_Dialogue) -> GraphNode:
	var n := _base("Stop BGM", TYPE_COLORS[KND_Dialogue.Type.STOP_BGM])
	n.set_meta("dialogue_type", KND_Dialogue.Type.STOP_BGM)
	var lbl := Label.new()
	lbl.text = "Stops current BGM"
	lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	n.add_child(lbl)
	n.set_meta("fields", {})
	n.set_slot(0, true, FLOW_PORT, FLOW_COLOR, true, FLOW_PORT, FLOW_COLOR)
	return n


static func _play_sfx(d: KND_Dialogue) -> GraphNode:
	var n := _base("Play SFX", TYPE_COLORS[KND_Dialogue.Type.PLAY_SOUND_EFFECT])
	n.set_meta("dialogue_type", KND_Dialogue.Type.PLAY_SOUND_EFFECT)
	var f1 := _add_field(n, "SFX", d.soundeffect_name if d else "")
	n.set_meta("fields", {"sfx_name": f1})
	n.set_slot(0, true, FLOW_PORT, FLOW_COLOR, true, FLOW_PORT, FLOW_COLOR)
	return n


static func _choice(d: KND_Dialogue) -> GraphNode:
	var n := _base("Choice", TYPE_COLORS[KND_Dialogue.Type.SHOW_CHOICE])
	n.set_meta("dialogue_type", KND_Dialogue.Type.SHOW_CHOICE)
	var header := Label.new()
	header.text = "Player Choices"
	n.add_child(header)
	n.set_slot(0, true, FLOW_PORT, FLOW_COLOR, false, 0, FLOW_COLOR)
	var choice_fields: Array = []
	var choices_data: Array = d.choices if d else []
	if choices_data.size() == 0:
		choices_data = []
		var c1 := KND_DialogueChoice.new()
		c1.choice_text = "Option 1"
		c1.next_id = ""
		choices_data.append(c1)
	for i in range(choices_data.size()):
		var c: KND_DialogueChoice = choices_data[i]
		var hbox := HBoxContainer.new()
		var te := LineEdit.new()
		te.text = c.choice_text
		te.placeholder_text = "Text"
		te.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(te)
		var tg := LineEdit.new()
		tg.text = ""
		tg.placeholder_text = "Label"
		tg.custom_minimum_size.x = 80
		hbox.add_child(tg)
		n.add_child(hbox)
		n.set_slot(i + 1, false, 0, FLOW_COLOR, true, FLOW_PORT, BRANCH_COLOR)
		choice_fields.append({"text": te, "tag": tg})
	n.set_meta("fields", {"choices": choice_fields})

	var add_btn := Button.new()
	add_btn.text = "Add Option"
	n.add_child(add_btn)
	# Disable the slot for the button row itself (no port on that row)
	n.set_slot(n.get_child_count() - 1, false, 0, FLOW_COLOR, false, 0, FLOW_COLOR)
	add_btn.pressed.connect(_on_choice_add_option.bind(n))
	return n


static func _condition(d: KND_Dialogue) -> GraphNode:
	var n := _base("Condition", TYPE_COLORS[KND_Dialogue.Type.IFELSE_BRANCH])
	n.set_meta("dialogue_type", KND_Dialogue.Type.IFELSE_BRANCH)
	var hbox := HBoxContainer.new()
	var lv := Label.new()
	lv.text = "if %"
	hbox.add_child(lv)
	var fvar := LineEdit.new()
	fvar.text = d.varname if d else ""
	fvar.placeholder_text = "var"
	fvar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(fvar)
	var fop := OptionButton.new()
	fop.add_item("==")
	fop.add_item(">")
	fop.add_item("<")
	fop.add_item(">=")
	fop.add_item("<=")
	if d and d.condition_operator > 0:
		fop.select(d.condition_operator)
	else:
		fop.select(0)
	fop.custom_minimum_size.x = 50
	hbox.add_child(fop)
	var fval := LineEdit.new()
	fval.text = str(d.target_value) if d else "0"
	fval.custom_minimum_size.x = 50
	hbox.add_child(fval)
	n.add_child(hbox)
	n.set_slot(0, true, FLOW_PORT, FLOW_COLOR, false, 0, FLOW_COLOR)
	var if_lbl := Label.new()
	if_lbl.text = "If True ->"
	if_lbl.add_theme_color_override("font_color", TRUE_COLOR)
	n.add_child(if_lbl)
	n.set_slot(1, false, 0, FLOW_COLOR, true, FLOW_PORT, TRUE_COLOR)
	var else_lbl := Label.new()
	else_lbl.text = "If False ->"
	else_lbl.add_theme_color_override("font_color", FALSE_COLOR)
	n.add_child(else_lbl)
	n.set_slot(2, false, 0, FLOW_COLOR, true, FLOW_PORT, FALSE_COLOR)
	var after_lbl := Label.new()
	after_lbl.text = "After ->"
	after_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.9))
	n.add_child(after_lbl)
	n.set_slot(3, false, 0, FLOW_COLOR, true, FLOW_PORT, FLOW_COLOR)
	n.set_meta("fields", {"varname": fvar, "condition_operator": fop, "target_value": fval})
	return n


static func _jump(d: KND_Dialogue) -> GraphNode:
	var n := _base("Jump", TYPE_COLORS[KND_Dialogue.Type.JUMP])
	n.set_meta("dialogue_type", KND_Dialogue.Type.JUMP)
	var f1 := _add_field(n, "Path", d.jump_shot_path if d else "res://")
	n.set_meta("fields", {"jump_path": f1})
	n.set_slot(0, true, FLOW_PORT, FLOW_COLOR, false, 0, FLOW_COLOR)
	return n


static func _signal_node(d: KND_Dialogue) -> GraphNode:
	var n := _base("Signal", TYPE_COLORS[KND_Dialogue.Type.SIGNAL])
	n.set_meta("dialogue_type", KND_Dialogue.Type.SIGNAL)
	var f1 := _add_field(n, "Name", d.custom_signal_name if d else "")
	n.set_meta("fields", {"signal_name": f1})
	n.set_slot(0, true, FLOW_PORT, FLOW_COLOR, true, FLOW_PORT, FLOW_COLOR)
	return n


static func _end(_d: KND_Dialogue) -> GraphNode:
	var n := _base("End", TYPE_COLORS[KND_Dialogue.Type.THE_END])
	n.set_meta("dialogue_type", KND_Dialogue.Type.THE_END)
	var lbl := Label.new()
	lbl.text = "End of dialogue"
	lbl.add_theme_color_override("font_color", Color(0.9, 0.4, 0.4))
	n.add_child(lbl)
	n.set_meta("fields", {})
	n.set_slot(0, true, FLOW_PORT, FLOW_COLOR, false, 0, FLOW_COLOR)
	return n


# --- Helpers ---

static func _on_choice_add_option(n: GraphNode) -> void:
	var choice_fields: Array = n.get_meta("fields").get("choices", [])
	var idx := choice_fields.size()
	var hbox := HBoxContainer.new()
	var te := LineEdit.new()
	te.text = "Option %d" % (idx + 1)
	te.placeholder_text = "Text"
	te.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(te)
	var tg := LineEdit.new()
	tg.text = ""
	tg.placeholder_text = "Label"
	tg.custom_minimum_size.x = 80
	hbox.add_child(tg)
	# Insert the new row before the "Add Option" button (last child)
	var btn_index := n.get_child_count() - 1
	n.add_child(hbox)
	n.move_child(hbox, btn_index)
	n.set_port_right_count(idx)
	# Set the slot for the new choice row (child index = idx + 1, after the header)
	n.set_slot(idx + 1, false, 0, FLOW_COLOR, true, FLOW_PORT, BRANCH_COLOR)
	# Disable the slot on the button row (now at new last index)
	n.set_slot(n.get_child_count() - 1, false, 0, FLOW_COLOR, false, 0, FLOW_COLOR)
	choice_fields.append({"text": te, "tag": tg})
	n.get_meta("fields")["choices"] = choice_fields


static func _add_field(node: GraphNode, label_text: String, default_val: String) -> LineEdit:
	var hbox := HBoxContainer.new()
	var lbl := Label.new()
	lbl.text = label_text
	lbl.custom_minimum_size.x = 70
	hbox.add_child(lbl)
	var le := LineEdit.new()
	le.text = default_val
	le.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(le)
	node.add_child(hbox)
	return le


static func _val(f: Dictionary, key: String) -> String:
	if f.has(key) and f[key] is LineEdit:
		return f[key].text
	return ""


static func _tval(f: Dictionary, key: String) -> String:
	if f.has(key) and f[key] is TextEdit:
		return f[key].text
	return ""


static func _fval(f: Dictionary, key: String) -> float:
	return _val(f, key).to_float()


static func _ival(f: Dictionary, key: String) -> int:
	if f.has(key) and f[key] is OptionButton:
		return f[key].selected
	return _val(f, key).to_int()


static func _bval(f: Dictionary, key: String) -> bool:
	if f.has(key) and f[key] is CheckBox:
		return f[key].button_pressed
	return false
