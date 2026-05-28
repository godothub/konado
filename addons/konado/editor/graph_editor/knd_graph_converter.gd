@tool
class_name KndGraphConverter

const X_SPACING := 320.0
const Y_SPACING := 180.0
const BRANCH_Y_OFFSET := 250.0

static var _node_counter: int = 0


static func _next_name() -> String:
	_node_counter += 1
	return "gn_%d" % _node_counter


# --- KND_Shot -> GraphEdit ---

static func shot_to_graph(shot: KND_Shot, graph: GraphEdit) -> void:
	_clear_graph(graph)
	if not shot or shot.dialogues.size() == 0:
		return
	_node_counter = 0
	# Map from node_id to GraphNode name
	var id_to_gn_name: Dictionary = {}
	var x := 40.0
	var y := 80.0
	# Create all graph nodes
	for d in shot.dialogues:
		if d.dialog_type == KND_Dialogue.Type.BRANCH:
			continue  # Skip deprecated BRANCH type
		var gn: GraphNode = KndGraphNodeFactory.create(d.dialog_type, d)
		gn.name = _next_name()
		gn.position_offset = Vector2(x, y)
		graph.add_child(gn)
		id_to_gn_name[d.node_id] = gn.name
		x += X_SPACING
		if x > 2000:
			x = 40.0
			y += Y_SPACING
	# Create connections based on next_id
	for d in shot.dialogues:
		if d.dialog_type == KND_Dialogue.Type.BRANCH:
			continue
		if not id_to_gn_name.has(d.node_id):
			continue
		var from_name: String = id_to_gn_name[d.node_id]
		# Main flow connection (next_id -> port 0)
		if not d.next_id.is_empty() and id_to_gn_name.has(d.next_id):
			var to_name: String = id_to_gn_name[d.next_id]
			if d.dialog_type == KND_Dialogue.Type.IFELSE_BRANCH:
				# Condition node: port 3 is "After" (main flow)
				graph.connect_node(from_name, 3, to_name, 0)
			elif d.dialog_type != KND_Dialogue.Type.SHOW_CHOICE:
				# Regular nodes: port 0 output
				graph.connect_node(from_name, 0, to_name, 0)
		# Choice connections
		if d.dialog_type == KND_Dialogue.Type.SHOW_CHOICE:
			for ci in range(d.choices.size()):
				var choice: KND_DialogueChoice = d.choices[ci]
				if not choice.next_id.is_empty() and id_to_gn_name.has(choice.next_id):
					graph.connect_node(from_name, ci + 1, id_to_gn_name[choice.next_id], 0)
		# Condition connections
		if d.dialog_type == KND_Dialogue.Type.IFELSE_BRANCH:
			if not d.if_next_id.is_empty() and id_to_gn_name.has(d.if_next_id):
				graph.connect_node(from_name, 1, id_to_gn_name[d.if_next_id], 0)
			if not d.else_next_id.is_empty() and id_to_gn_name.has(d.else_next_id):
				graph.connect_node(from_name, 2, id_to_gn_name[d.else_next_id], 0)


# --- GraphEdit -> KND_Shot ---

static func graph_to_shot(graph: GraphEdit) -> KND_Shot:
	var shot := KND_Shot.new()
	var nodes: Array[GraphNode] = []
	for child in graph.get_children():
		if child is GraphNode:
			nodes.append(child)
	if nodes.size() == 0:
		return shot
	var connections: Array[Dictionary] = graph.get_connection_list()
	# Build a map from GraphNode name to generated node_id
	var gn_name_to_id: Dictionary = {}
	for n in nodes:
		var id := "node_%s" % n.name
		gn_name_to_id[n.name] = id
	# Find start node (no incoming connections on port 0)
	var incoming: Dictionary = {}
	for c in connections:
		incoming[c["to_node"]] = true
	var start_gn_name: String = ""
	for n in nodes:
		if not incoming.has(n.name):
			start_gn_name = n.name
			break
	if start_gn_name.is_empty() and nodes.size() > 0:
		start_gn_name = nodes[0].name
	shot.start_node_id = gn_name_to_id.get(start_gn_name, "")
	# Create KND_Dialogue for each node
	for n in nodes:
		var d := KndGraphNodeFactory.read_fields(n)
		var nid: String = gn_name_to_id[n.name]
		d.node_id = nid
		var type: KND_Dialogue.Type = n.get_meta("dialogue_type")
		# Set next_id from connections
		if type == KND_Dialogue.Type.SHOW_CHOICE:
			# Choice: main next_id is not used (choices have their own next_id)
			# Set each choice's next_id from branch connections
			print(d.choices.size())
			for ci in range(d.choices.size()):
				var target := _find_connection_target(n.name, ci + 1, connections)
				if not target.is_empty() and gn_name_to_id.has(target):
					d.choices[ci].next_id = gn_name_to_id[target]
					print(d.choices[ci].next_id)
					
		elif type == KND_Dialogue.Type.IFELSE_BRANCH:
			# Condition: if port 1, else port 2, after(next) port 3
			var if_target := _find_connection_target(n.name, 1, connections)
			if not if_target.is_empty() and gn_name_to_id.has(if_target):
				d.if_next_id = gn_name_to_id[if_target]
			var else_target := _find_connection_target(n.name, 2, connections)
			if not else_target.is_empty() and gn_name_to_id.has(else_target):
				d.else_next_id = gn_name_to_id[else_target]
			var after_target := _find_connection_target(n.name, 3, connections)
			if not after_target.is_empty() and gn_name_to_id.has(after_target):
				d.next_id = gn_name_to_id[after_target]
		else:
			# Regular nodes: port 0 output is next
			var next_target := _find_connection_target(n.name, 0, connections)
			if not next_target.is_empty() and gn_name_to_id.has(next_target):
				d.next_id = gn_name_to_id[next_target]
		shot.dialogues.append(d)
	return shot


static func _find_connection_target(from_name: String, from_port: int, connections: Array[Dictionary]) -> String:
	for c in connections:
		if c["from_node"] == from_name and c["from_port"] == from_port:
			return c["to_node"]
	return ""


static func _clear_graph(graph: GraphEdit) -> void:
	graph.clear_connections()
	for child in graph.get_children():
		if child is GraphNode:
			child.queue_free()
