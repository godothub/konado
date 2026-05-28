@tool
extends Panel
class_name KsEditorWindow

@onready var code_editor: CodeEdit = %CodeEdit
@onready var new_button: Button = $dock/MarginContainer/BoxContainer/New
@onready var open_button: Button = $dock/MarginContainer/BoxContainer/Open
@onready var save_button: Button = $dock/MarginContainer/BoxContainer/Save
@onready var file_label: Label = $dock/MarginContainer/BoxContainer/FilePath
@onready var close_button: Button = $dock/MarginContainer/BoxContainer/Close

var current_file_path: String = ""
var is_modified: bool = false
var last_saved_content: String = ""


func _ready() -> void:
	if not Engine.is_editor_hint():
		return
	
	# 连接信号
	new_button.pressed.connect(_on_new_button_pressed)
	open_button.pressed.connect(_on_open_button_pressed)
	save_button.pressed.connect(_on_save_button_pressed)
	close_button.pressed.connect(close_file)
	if code_editor:
		code_editor.text_changed.connect(_on_text_changed)

	# 初始化时如果没有打开文件，禁止编辑
	call_deferred("update_editor_state")

func edit(path: String) -> void:
	current_file_path = path
	
	# 显示文件名
	var file_name = path.get_file()
	file_label.text = "正在编辑: %s" % file_name
	
	# 读取文件内容
	var file = FileAccess.open(path, FileAccess.READ)
	if file:
		var content = file.get_as_text()
		code_editor.text = content
		last_saved_content = content
		is_modified = false
		update_save_button()
		file.close()
		
		# 启用编辑
		code_editor.editable = true
		code_editor.mouse_filter = Control.MOUSE_FILTER_STOP
	else:
		push_error("无法打开文件: %s" % path)
		code_editor.text = ""
		last_saved_content = ""
		is_modified = false
	# 文件打开失败，保持不可编辑状态
	update_editor_state()

func _on_text_changed() -> void:
	# 只有在有打开文件时才处理文本变化
	if current_file_path.is_empty():
		return
	
	is_modified = (code_editor.text != last_saved_content)
	update_save_button()
	
	# 如果有修改，在文件名后显示星号
	var file_name = current_file_path.get_file()
	if is_modified:
		file_label.text = "正在编辑: %s *" % file_name
	else:
		file_label.text = "正在编辑: %s" % file_name

func _on_new_button_pressed() -> void:
	# 先检查是否有未保存的更改
	if has_unsaved_changes():
		var dialog = ConfirmationDialog.new()
		dialog.title = "新建文件"
		dialog.dialog_text = "当前文件有未保存的更改。\n是否要保存当前文件？"
		
		dialog.get_ok_button().text = "保存"
		dialog.get_cancel_button().text = "不保存"
		
		# 添加第三个按钮 - 取消
		var cancel_button = Button.new()
		cancel_button.text = "取消"
		dialog.add_button(cancel_button)
		
		var editor_interface = EditorInterface.get_base_control()
		editor_interface.add_child(dialog)
		
		dialog.confirmed.connect(func(): 
			if save_file():
				create_new_file()
			dialog.queue_free())
		
		# 不保存直接新建
		dialog.canceled.connect(func(): 
			create_new_file()
			dialog.queue_free())
		
		# 取消按钮 - 关闭对话框，不执行任何操作
		cancel_button.pressed.connect(func(): 
			dialog.queue_free())
		
		dialog.popup_centered(Vector2i(400, 150))
	else:
		create_new_file()
		
	call_deferred("update_editor_state")

func create_new_file() -> void:
	# 使用编辑器文件对话框创建新文件
	var file_dialog = EditorFileDialog.new()
	file_dialog.file_mode = EditorFileDialog.FILE_MODE_SAVE_FILE
	file_dialog.title = "新建文件"
	
	# 设置文件过滤器
	file_dialog.add_filter("*.ks;KS Files")
	
	# 设置默认目录
	file_dialog.current_dir = "res://"
	
	var editor_interface = EditorInterface.get_base_control()
	editor_interface.add_child(file_dialog)
	
	file_dialog.file_selected.connect(func(path: String):
		# 检查文件是否已存在
		if FileAccess.file_exists(path):
			var overwrite_dialog = ConfirmationDialog.new()
			overwrite_dialog.title = "文件已存在"
			overwrite_dialog.dialog_text = "文件 '%s' 已存在。\n是否要覆盖？" % path.get_file()
			
			editor_interface.add_child(overwrite_dialog)
			
			overwrite_dialog.confirmed.connect(func(): 
				create_empty_file(path)
				overwrite_dialog.queue_free())
			
			overwrite_dialog.canceled.connect(func(): 
				overwrite_dialog.queue_free())
			
			overwrite_dialog.popup_centered(Vector2i(400, 120))
		else:
			create_empty_file(path)
		
		file_dialog.queue_free())
	
	file_dialog.canceled.connect(func():
		file_dialog.queue_free())
	
	file_dialog.popup_centered_ratio(0.75)

func create_empty_file(path: String) -> void:
	# 创建空文件
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string("")
		file.close()
		
		# 编辑新创建的文件
		edit(path)
		
		# 刷新文件系统
		if Engine.is_editor_hint():
			EditorInterface.get_resource_filesystem().scan()
			
		print("已创建新文件: %s" % path)
	else:
		push_error("无法创建文件: %s" % path)

func _on_open_button_pressed() -> void:
	# 先检查是否有未保存的更改
	if has_unsaved_changes():
		var dialog = ConfirmationDialog.new()
		dialog.title = "打开文件"
		dialog.dialog_text = "当前文件有未保存的更改。\n是否要保存当前文件？"
		
		dialog.get_ok_button().text = "保存"
		dialog.get_cancel_button().text = "不保存"
		
		# 添加第三个按钮 - 取消
		var cancel_button = Button.new()
		cancel_button.text = "取消"
		dialog.add_button(cancel_button)
		
		var editor_interface = EditorInterface.get_base_control()
		editor_interface.add_child(dialog)
		
		dialog.confirmed.connect(func(): 
			if save_file():
				show_open_dialog()
			dialog.queue_free())
		
		dialog.canceled.connect(func(): 
			show_open_dialog()
			dialog.queue_free())
		
		cancel_button.pressed.connect(func(): 
			dialog.queue_free())
		
		dialog.popup_centered(Vector2i(400, 150))
	else:
		show_open_dialog()
		
	call_deferred("update_editor_state")

func show_open_dialog() -> void:
	# 使用编辑器文件对话框打开文件
	var file_dialog = EditorFileDialog.new()
	file_dialog.file_mode = EditorFileDialog.FILE_MODE_OPEN_FILE
	file_dialog.title = "打开文件"
	
	# 设置文件过滤器
	file_dialog.add_filter("*.ks;KS Files")
	
	# 设置默认目录
	file_dialog.current_dir = "res://"
	
	var editor_interface = EditorInterface.get_base_control()
	editor_interface.add_child(file_dialog)
	
	file_dialog.file_selected.connect(func(path: String):
		# 打开选中的文件
		edit(path)
		file_dialog.queue_free())
	
	file_dialog.canceled.connect(func():
		file_dialog.queue_free())
	
	file_dialog.popup_centered_ratio(0.75)

func _on_save_button_pressed() -> void:
	if current_file_path.is_empty():
		push_warning("没有打开的文件")
		return
	
	save_file()

func save_file() -> bool:
	if current_file_path.is_empty():
		return false
	
	var file = FileAccess.open(current_file_path, FileAccess.WRITE)
	if file:
		var content = code_editor.text
		file.store_string(content)
		last_saved_content = content
		is_modified = false
		update_save_button()
		file.close()
		
		# 更新标签
		file_label.text = "正在编辑: %s" % current_file_path.get_file()
		
		# 发送保存成功的信号
		if Engine.is_editor_hint():
			#EditorInterface.get_resource_filesystem().scan()
			# 强制触发重新导入
			EditorInterface.get_resource_filesystem().reimport_files([current_file_path])
		
		print("文件已保存: %s" % current_file_path)
		
		
		return true
	push_error("无法保存文件: %s" % current_file_path)
	return false

func update_save_button() -> void:
	save_button.disabled = not is_modified or current_file_path.is_empty()
	if is_modified:
		save_button.tooltip_text = "保存更改"
		save_button.add_theme_color_override("font_color", Color(1, 0.5, 0.5))
	else:
		save_button.tooltip_text = "无更改"
		save_button.remove_theme_color_override("font_color")

func get_current_content() -> String:
	return code_editor.text

func has_unsaved_changes() -> bool:
	if current_file_path.is_empty() :
		return false
	return is_modified

func update_editor_state() -> void:
	# 根据是否有打开的文件来更新编辑器状态
	if current_file_path.is_empty():
		# 没有打开文件，禁止编辑
		code_editor.editable = false
		code_editor.text = "请先打开一个文件"
		code_editor.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		# 更新标签
		file_label.text = "未打开文件"
		
		# 禁用保存按钮
		save_button.disabled = true
		save_button.tooltip_text = "没有打开的文件"
		
		# 禁用关闭按钮
		close_button.disabled = true
		close_button.tooltip_text = "没有打开的文件"
		
		# 移除保存按钮的颜色覆盖
		save_button.remove_theme_color_override("font_color")
	else:
		# 有打开文件，允许编辑
		code_editor.editable = true
		code_editor.mouse_filter = Control.MOUSE_FILTER_STOP
		code_editor.tooltip_text = ""
		
		print(current_file_path)
		print(close_button.disabled)
		close_button.disabled = false
		close_button.tooltip_text = ""
		
		# 更新保存按钮状态
		update_save_button()

func close_file() -> void:
	# 如果没有打开文件，直接返回
	if current_file_path.is_empty():
		return
	
	# 如果没有修改，直接关闭
	if not is_modified:
		reset_editor_state()
		return
	
	# 创建保存提示对话框
	var dialog = ConfirmationDialog.new()
	dialog.title = "保存更改"
	dialog.dialog_text = "文件 '%s' 有未保存的更改。\n是否要保存更改？" % current_file_path.get_file()
	
	# 添加按钮
	dialog.get_ok_button().text = "保存"
	dialog.get_cancel_button().text = "不保存"
	
	# 将对话框添加到编辑器界面
	var editor_interface = EditorInterface.get_base_control()
	editor_interface.add_child(dialog)
	
	dialog.confirmed.connect(func(): 
		save_file()
		reset_editor_state()
		dialog.queue_free())
	
	dialog.canceled.connect(func(): 
		reset_editor_state()
		dialog.queue_free())
	
	# 显示对话框
	dialog.popup_centered(Vector2i(400, 150))

func reset_editor_state() -> void:
	# 重置所有状态
	current_file_path = ""
	last_saved_content = ""
	is_modified = false
	
	call_deferred("update_editor_state")
	
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.ctrl_pressed and event.keycode == KEY_S and event.pressed:
		if has_unsaved_changes():
			save_file()
