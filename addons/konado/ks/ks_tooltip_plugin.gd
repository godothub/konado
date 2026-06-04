@tool
extends EditorResourceTooltipPlugin

func _handles(type: String) -> bool:
	if type == "Resource":
		return true
	return false
	
	
func _make_tooltip_for_path(path: String, metadata: Dictionary, base: Control) -> Control:
	if path.get_extension() == "ks":
		var vbox = VBoxContainer.new()
		# 显示文件类型信息
		var type_label = Label.new()
		type_label.text = "Konado Script"
		vbox.add_child(type_label)
		
		# 获取并显示文件行数
		var line_count = _get_file_line_count(path)
		var line_label = Label.new()
		line_label.text = "脚本行数: " + str(line_count)
		vbox.add_child(line_label)
		
		var shot: KND_Shot = load(path)
		
		if shot:
			# 显示对话数量
			var dc: int = shot.dialogues.size()
			var dc_label = Label.new()
			dc_label.text = "对话数量: " + str(dc)
			vbox.add_child(dc_label)
			
			# 显示依赖角色
			var dep_characters = shot.dep_characters
			var c_s: String
			c_s = ", ".join(dep_characters)
			var dep_characters_label = Label.new()
			dep_characters_label.text = "依赖角色: " + str(c_s)
			vbox.add_child(dep_characters_label)
		else:
			var error_label = Label.new()
			error_label.text = "请右键重新导入"
			vbox.add_child(error_label)
			
		base.add_child(vbox)
	return base
	
	
func _get_file_line_count(file_path: String) -> int:
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		return -1
	
	var line_count = 0
	while not file.eof_reached():
		file.get_line()
		line_count += 1
	
	file.close()
	return line_count
