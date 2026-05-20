extends Node
class_name KND_ChoiceInterface

## 对话选项UI接口

## 对话选项按钮容器
@export var _choice_container: Container

## 完成创建选项的信号
signal finish_display_options

## 初始化对话框
func init_dialog_box() -> void:
	distroy_options()


func distroy_options() -> void:
	# 隐藏选项容器
	_choice_container.hide()
	# 删除原有选项
	if _choice_container.get_child_count() != 0:
		for child in _choice_container.get_children():
			child.queue_free()

## 显示对话选项的方法
func display_options(choices: Array[KND_DialogueChoice], manager: KND_DialogueManager, choices_font_size: int = 32) -> void:
	distroy_options()
	
	var tmp_list: Array[Button] = []
	
	# 生成新选项
	for choice in choices:
		var choiceButton: Button = Button.new()
		# 选项文本内容
		choiceButton.set_text(choice.choice_text)
		choiceButton.add_theme_font_size_override("font_size", int(choices_font_size))
		# 选项触发
		choiceButton.pressed.connect(
			func():
				await get_tree().process_frame
				manager.on_option_triggered(choice)
				choiceButton.set_disabled(true)
				print_rich("[color=green]选项被触发: [/color]"+str(choice))
				)
		choiceButton.gui_input.connect(func(event: InputEvent):
			if event.is_action_pressed("ui_accept") || event.is_action_pressed("ui_select"):
				choiceButton.pressed.emit()
			)
		# 添加到选项容器
		_choice_container.add_child(choiceButton)
		print_rich("[color=cyan]生成选项按钮: [/color]"+str(choiceButton))
		
		tmp_list.append(choiceButton)
		
	# 显示选项容器
	_choice_container.show()
	
	var list_size = tmp_list.size()
	
	for index in range(list_size):
		var c = tmp_list[index]
		var tc = tmp_list[index - 1]
		c.set_focus_neighbor(SIDE_TOP, tc.get_path())
		if index < list_size - 1:
			var bc = tmp_list[index + 1]
			c.set_focus_neighbor(SIDE_BOTTOM, bc.get_path())
		if index == list_size - 1:
			var bc = tmp_list[0]
			c.set_focus_neighbor(SIDE_BOTTOM, bc.get_path())
	
	# 自动焦点
	if tmp_list.size() > 0:
		tmp_list[0].grab_focus.call_deferred()
