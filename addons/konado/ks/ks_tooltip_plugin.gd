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
		line_label.text = "行数: " + str(line_count)
		vbox.add_child(line_label)
		
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
