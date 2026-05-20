@tool
class_name KND_SettingsUIFactory
extends RefCounted

## 设置UI工厂类用于创建设置项的控制界面

## 为给定的设置项创建一个行（HBoxContainer）并返回
## 连接值变化信号到提供的回调函数：
##   callback(category_id: String, key: String, value: Variant)
## @param cat_id: 分类ID
## @param item: 设置项
## @param callback: 回调函数
## @return: 创建的HBoxContainer
static func create_control(cat_id: String, item: KND_SettingItem, callback: Callable) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var lbl := Label.new()
	lbl.text = item.label
	lbl.custom_minimum_size.x = 160
	# tooltip
	if item.tooltip != "":
		lbl.set_mouse_filter(Control.MOUSE_FILTER_STOP)
		lbl.tooltip_text = item.tooltip
	row.add_child(lbl)

	match item.type:
		KND_SettingItem.Type.SLIDER:
			_add_slider(row, cat_id, item, callback)
		KND_SettingItem.Type.TOGGLE:
			_add_toggle(row, cat_id, item, callback)
		KND_SettingItem.Type.OPTION:
			_add_option(row, cat_id, item, callback)

	return row

## 添加滑块控件
## @param row: 容器
## @param cat_id: 分类ID
## @param item: 设置项
## @param cb: 回调函数
static func _add_slider(row: HBoxContainer, cat_id: String, item: KND_SettingItem, cb: Callable) -> void:
	var slider := HSlider.new()
	slider.min_value = item.min_value
	slider.max_value = item.max_value
	slider.step = item.step
	slider.value = _current(cat_id, item)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.size_flags_vertical = Control.SIZE_EXPAND_FILL
	slider.custom_minimum_size.x = 200

	var value_label := Label.new()
	value_label.custom_minimum_size.x = 60
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.text = _format_num(slider.value, item.step)

	slider.value_changed.connect(func(v: float) -> void:
		value_label.text = _format_num(v, item.step)
		cb.call(cat_id, item.key, v)
	)

	row.add_child(slider)
	row.add_child(value_label)

## 添加开关控件
## @param row: 容器
## @param cat_id: 分类ID
## @param item: 设置项
## @param cb: 回调函数
static func _add_toggle(row: HBoxContainer, cat_id: String, item: KND_SettingItem, cb: Callable) -> void:
	var check := CheckBox.new()
	check.button_pressed = _current(cat_id, item) as bool
	check.toggled.connect(func(pressed: bool) -> void:
		cb.call(cat_id, item.key, pressed)
	)
	row.add_child(check)

## 添加选项控件
## @param row: 容器
## @param cat_id: 分类ID
## @param item: 设置项
## @param cb: 回调函数
static func _add_option(row: HBoxContainer, cat_id: String, item: KND_SettingItem, cb: Callable) -> void:
	var opt := OptionButton.new()
	var cur_val: String = str(_current(cat_id, item))
	var selected_idx := 0
	for i in item.options.size():
		opt.add_item(item.options[i])
		if item.options[i] == cur_val:
			selected_idx = i
	opt.selected = selected_idx
	opt.custom_minimum_size.x = 140
	opt.item_selected.connect(func(idx: int) -> void:
		cb.call(cat_id, item.key, item.options[idx])
	)
	row.add_child(opt)

## 获取设置项的当前值
## @param cat_id: 分类ID
## @param item: 设置项
## @return: 当前值或默认值
static func _current(cat_id: String, item: KND_SettingItem) -> Variant:
	var mgr := Engine.get_singleton("KND_Settings") if Engine.has_singleton("KND_Settings") else null
	if mgr == null:
		# 备用方案：通过场景树自动加载访问
		var tree := Engine.get_main_loop() as SceneTree
		if tree:
			mgr = tree.root.get_node_or_null("KND_Settings")
	if mgr and mgr.has_method("get_setting"):
		return mgr.get_setting(cat_id, item.key)
	return item.default_value

## 格式化数字显示
## @param v: 数值
## @param step: 步长
## @return: 格式化后的字符串
static func _format_num(v: float, step: float) -> String:
	if step >= 1.0:
		return str(int(v))
	# 根据步长确定小数位数
	var s := str(step)
	var dot := s.find(".")
	var decimals := 2
	if dot >= 0:
		decimals = s.length() - dot - 1
	return ("%." + str(decimals) + "f") % v
