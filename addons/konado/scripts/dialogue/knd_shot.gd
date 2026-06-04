extends KND_Data
class_name KND_Shot

@export var ks_path: String = "null"

@export var shot_id: String = "新镜头"

## 起始节点ID
@export var start_node_id: String = ""

## 所有对话节点（扁平列表）
@export var dialogues: Array[KND_Dialogue] = []

## 依赖角色
@export var dep_characters: Array[String] = []

## 根据 node_id 查找对话节点
func find_node(id: String) -> KND_Dialogue:
	if id.is_empty():
		return null
	for d in dialogues:
		if d.node_id == id:
			return d
	return null

## 获取起始节点
func get_start_node() -> KND_Dialogue:
	if not start_node_id.is_empty():
		return find_node(start_node_id)
	if dialogues.size() > 0:
		return dialogues[0]
	return null
