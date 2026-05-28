@tool
class_name KndGraphEdit
extends VBoxContainer

signal graph_modified

var graph_edit: GraphEdit
var add_menu_btn: MenuButton
var file_label: Label
var status_label: Label
var save_btn: Button
var current_shot: KND_Shot
var current_file_path: String = ""
var _popup_pos: Vector2

const ADD_ITEMS := [
	["Dialogue", KND_Dialogue.Type.ORDINARY_DIALOG],
	["Actor Show", KND_Dialogue.Type.DISPLAY_ACTOR],
	["Actor Change", KND_Dialogue.Type.ACTOR_CHANGE_STATE],
	["Actor Move", KND_Dialogue.Type.MOVE_ACTOR],
	["Actor Exit", KND_Dialogue.Type.EXIT_ACTOR],
	["Background", KND_Dialogue.Type.SWITCH_BACKGROUND],
	["Play BGM", KND_Dialogue.Type.PLAY_BGM],
	["Stop BGM", KND_Dialogue.Type.STOP_BGM],
	["Play SFX", KND_Dialogue.Type.PLAY_SOUND_EFFECT],
	["Choice", KND_Dialogue.Type.SHOW_CHOICE],
	["Condition (if/else)", KND_Dialogue.Type.IFELSE_BRANCH],
	["Jump", KND_Dialogue.Type.JUMP],
	["Signal", KND_Dialogue.Type.SIGNAL],
	["End", KND_Dialogue.Type.THE_END],
]


func _ready() -> void:
	if not Engine.is_editor_hint():
		return
	_build_toolbar()
	_build_graph()


func _build_toolbar() -> void:
	var hbox := HBoxContainer.new()
	hbox.custom_minimum_size.y = 36
	add_child(hbox)

	var new_btn := Button.new()
	new_btn.text = "新建"
	new_btn.pressed.connect(_on_new)
	hbox.add_child(new_btn)

	var open_btn := Button.new()
	open_btn.text = "打开"
	open_btn.pressed.connect(_on_open)
	hbox.add_child(open_btn)

	save_btn = Button.new()
	save_btn.text = "保存"
	save_btn.pressed.connect(_on_save)
	hbox.add_child(save_btn)

	var sep := VSeparator.new()
	hbox.add_child(sep)

	add_menu_btn = MenuButton.new()
	add_menu_btn.text = "Add Node"
	add_menu_btn.flat = false
	var popup := add_menu_btn.get_popup()
	for i in range(ADD_ITEMS.size()):
		popup.add_item(ADD_ITEMS[i][0], i)
	popup.id_pressed.connect(_on_add_menu_id)
	hbox.add_child(add_menu_btn)

	var arrange_btn := Button.new()
	arrange_btn.text = "Auto Layout"
	arrange_btn.pressed.connect(_auto_layout)
	hbox.add_child(arrange_btn)

	var clear_btn := Button.new()
	clear_btn.text = "Clear"
	clear_btn.pressed.connect(_on_clear)
	hbox.add_child(clear_btn)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(spacer)

	file_label = Label.new()
	file_label.text = "未打开文件"
	file_label.add_theme_color_override("font_color", Color(0.6, 0.7, 0.8))
	hbox.add_child(file_label)

	var sep2 := VSeparator.new()
	hbox.add_child(sep2)

	status_label = Label.new()
	status_label.text = "Graph Editor"
	status_label.add_theme_color_override("font_color", Color(0.5, 0.6, 0.7))
	hbox.add_child(status_label)


func _build_graph() -> void:
	graph_edit = GraphEdit.new()
	graph_edit.size_flags_vertical = Control.SIZE_EXPAND_FILL
	graph_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	graph_edit.right_disconnects = true
	graph_edit.snapping_enabled = true
	graph_edit.snapping_distance = 20
	graph_edit.minimap_enabled = true
	graph_edit.connection_request.connect(_on_connection_request)
	graph_edit.disconnection_request.connect(_on_disconnection_request)
	graph_edit.delete_nodes_request.connect(_on_delete_nodes_request)
	graph_edit.popup_request.connect(_on_popup_request)
	add_child(graph_edit)


func load_shot(shot: KND_Shot) -> void:
	current_shot = shot
	if graph_edit:
		KndGraphConverter.shot_to_graph(shot, graph_edit)
	_update_status()


func export_shot() -> KND_Shot:
	if not graph_edit:
		return KND_Shot.new()
	return KndGraphConverter.graph_to_shot(graph_edit)


func edit(path: String) -> void:
	if path.is_empty():
		return
	# 使用普通加载，不设置 CACHE_MODE_IGNORE
	# 保存时 export_shot() 会创建全新的 KND_Shot 对象，不会与缓存冲突
	var res = ResourceLoader.load(path)
	if res is KND_Shot:
		current_file_path = path
		load_shot(res)
		_update_file_label()
		print("Graph Editor: 已打开 %s" % path)
	else:
		push_error("Graph Editor: 无法加载KND_Shot资源: %s" % path)


# --- 新建 ---

func _on_new() -> void:
	var file_dialog := EditorFileDialog.new()
	file_dialog.file_mode = EditorFileDialog.FILE_MODE_SAVE_FILE
	file_dialog.title = "新建 KND_Shot 资源"
	file_dialog.add_filter("*.tres", "Godot Resource")
	file_dialog.current_dir = "res://"

	var base_ctrl := EditorInterface.get_base_control()
	base_ctrl.add_child(file_dialog)

	file_dialog.file_selected.connect(func(path: String):
		# 清空当前图
		_clear_graph_contents()
		# 创建并保存空Shot
		var shot := KND_Shot.new()
		shot.ks_path = path
		var err := ResourceSaver.save(shot, path)
		if err == OK:
			current_file_path = path
			current_shot = shot
			_update_file_label()
			_update_status()
			print("Graph Editor: 已新建 %s" % path)
			# 刷新文件系统
			EditorInterface.get_resource_filesystem().scan()
		else:
			push_error("Graph Editor: 无法创建文件 %s (错误码: %d)" % [path, err])
		file_dialog.queue_free()
	)

	file_dialog.canceled.connect(func():
		file_dialog.queue_free()
	)

	file_dialog.popup_centered_ratio(0.6)


# --- 打开 ---

func _on_open() -> void:
	var file_dialog := EditorFileDialog.new()
	file_dialog.file_mode = EditorFileDialog.FILE_MODE_OPEN_FILE
	file_dialog.title = "打开 KND_Shot 资源"
	file_dialog.add_filter("*.tres", "Godot Resource")
	file_dialog.current_dir = "res://"

	var base_ctrl := EditorInterface.get_base_control()
	base_ctrl.add_child(file_dialog)

	file_dialog.file_selected.connect(func(path: String):
		edit(path)
		file_dialog.queue_free()
	)

	file_dialog.canceled.connect(func():
		file_dialog.queue_free()
	)

	file_dialog.popup_centered_ratio(0.6)


# --- 保存 ---

func _on_save() -> void:
	if current_file_path.is_empty():
		# 没有文件路径，弹出另存为对话框
		_show_save_as_dialog()
		return
	_save_to_path(current_file_path)


func _show_save_as_dialog() -> void:
	var file_dialog := EditorFileDialog.new()
	file_dialog.file_mode = EditorFileDialog.FILE_MODE_SAVE_FILE
	file_dialog.title = "保存 KND_Shot 资源"
	file_dialog.add_filter("*.tres", "Godot Resource")
	file_dialog.current_dir = "res://"

	var base_ctrl := EditorInterface.get_base_control()
	base_ctrl.add_child(file_dialog)

	file_dialog.file_selected.connect(func(path: String):
		current_file_path = path
		_save_to_path(path)
		_update_file_label()
		file_dialog.queue_free()
	)

	file_dialog.canceled.connect(func():
		file_dialog.queue_free()
	)

	file_dialog.popup_centered_ratio(0.6)


func _save_to_path(path: String) -> void:
	var shot := export_shot()
	shot.ks_path = path
	var tmp: KND_Shot = load(path)
	if tmp:
		tmp.dialogues = shot.dialogues
	current_shot = shot
	print("Graph Editor: 已保存 %s" % path)
	EditorInterface.get_resource_filesystem().scan()
	# 注意：不要设置 shot.resource_path，否则会和已缓存的资源冲突
	# ResourceSaver.save() 的第二个参数 path 会自动处理路径
	#var err := ResourceSaver.save(shot, path)
	#if err == OK:
		#current_shot = shot
		#status_label.text = "已保存: %s" % path.get_file()
		#print("Graph Editor: 已保存 %s" % path)
		## 刷新文件系统使编辑器识别新/更新的文件
		#EditorInterface.get_resource_filesystem().scan()
	#else:
		#status_label.text = "保存失败 (错误码: %d)" % err
		#push_error("Graph Editor: 保存失败 %s (错误码: %d)" % [path, err])


func _update_file_label() -> void:
	if current_file_path.is_empty():
		file_label.text = "未打开文件"
	else:
		file_label.text = "正在编辑: %s" % current_file_path.get_file()


# --- 添加节点 ---

func _on_add_menu_id(id: int) -> void:
	if id < 0 or id >= ADD_ITEMS.size():
		return
	var type: KND_Dialogue.Type = ADD_ITEMS[id][1]
	_add_node_at(type, _get_center_pos())


func _add_node_at(type: KND_Dialogue.Type, pos: Vector2) -> GraphNode:
	var gn := KndGraphNodeFactory.create(type)
	gn.name = "gn_%d" % (randi() % 999999)
	gn.position_offset = pos
	graph_edit.add_child(gn)
	_update_status()
	graph_modified.emit()
	return gn


# --- 连接管理 ---

func _on_connection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	# 先断开该输出端口已有的连接（一个输出端口只能连一个目标）
	for c in graph_edit.get_connection_list():
		if c["from_node"] == from_node and c["from_port"] == from_port:
			graph_edit.disconnect_node(c["from_node"], c["from_port"], c["to_node"], c["to_port"])
	graph_edit.connect_node(from_node, from_port, to_node, to_port)
	graph_modified.emit()


func _on_disconnection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	graph_edit.disconnect_node(from_node, from_port, to_node, to_port)
	graph_modified.emit()


func _on_delete_nodes_request(nodes: Array[StringName]) -> void:
	for node_name in nodes:
		var node := graph_edit.get_node_or_null(NodePath(node_name))
		if node and node is GraphNode:
			for c in graph_edit.get_connection_list():
				if c["from_node"] == node_name or c["to_node"] == node_name:
					graph_edit.disconnect_node(c["from_node"], c["from_port"], c["to_node"], c["to_port"])
			node.queue_free()
	_update_status()
	graph_modified.emit()


func _on_popup_request(at_position: Vector2) -> void:
	_popup_pos = at_position
	var menu := PopupMenu.new()
	for i in range(ADD_ITEMS.size()):
		menu.add_item(ADD_ITEMS[i][0], i)
	menu.id_pressed.connect(func(id: int):
		if id >= 0 and id < ADD_ITEMS.size():
			var type: KND_Dialogue.Type = ADD_ITEMS[id][1]
			var local_pos := (at_position + graph_edit.scroll_offset) / graph_edit.zoom
			_add_node_at(type, local_pos)
		menu.queue_free()
	)
	add_child(menu)
	print(at_position)
	menu.position = Vector2i(at_position)
	menu.popup()


# --- 清空 ---

func _on_clear() -> void:
	_clear_graph_contents()
	graph_modified.emit()


func _clear_graph_contents() -> void:
	if not graph_edit:
		return
	graph_edit.clear_connections()
	for child in graph_edit.get_children():
		if child is GraphNode:
			child.queue_free()
	_update_status()


# --- 自动布局 ---

func _auto_layout() -> void:
	var nodes: Array[GraphNode] = []
	for child in graph_edit.get_children():
		if child is GraphNode:
			nodes.append(child)
	if nodes.size() == 0:
		return
	var connections := graph_edit.get_connection_list()
	var incoming: Dictionary = {}
	for c in connections:
		incoming[c["to_node"]] = true
	var sorted: Array[GraphNode] = []
	var remaining := nodes.duplicate()
	while remaining.size() > 0:
		var found := false
		for n in remaining:
			if not incoming.has(n.name) or _all_sources_in(n.name, connections, sorted):
				sorted.append(n)
				remaining.erase(n)
				found = true
				break
		if not found:
			sorted.append_array(remaining)
			break
	var x := 40.0
	var y := 80.0
	for n in sorted:
		n.position_offset = Vector2(x, y)
		x += 320.0
		if x > 2000:
			x = 40.0
			y += 250.0


func _all_sources_in(node_name: String, connections: Array[Dictionary], placed: Array[GraphNode]) -> bool:
	var placed_names: Dictionary = {}
	for p in placed:
		placed_names[p.name] = true
	for c in connections:
		if c["to_node"] == node_name and not placed_names.has(c["from_node"]):
			return false
	return true


func _get_center_pos() -> Vector2:
	return (graph_edit.scroll_offset + graph_edit.size / 2.0) / graph_edit.zoom


func _update_status() -> void:
	if not graph_edit or not status_label:
		return
	var count := 0
	for child in graph_edit.get_children():
		if child is GraphNode:
			count += 1
	status_label.text = "Nodes: %d | Connections: %d" % [count, graph_edit.get_connection_list().size()]
