extends Control

@export var dialogue_manager: KND_DialogueManager



func _ready() -> void:
	dialogue_manager.custom_signal.connect(_on_konado_dialogue_manager_play_sfx)
	# 可以在脚本中同步外部变量
	var store = KND_VariableStore.new()
	store.set_value("love", 0)
	dialogue_manager.variable_store = store

# 这一部分非插件内容，为demo演示所需
func _on_konado_dialogue_manager_play_sfx(content: Variant) -> void:
	if content == "好感度上升":
		if dialogue_manager.variable_store:
			dialogue_manager.variable_store.apply_operation("love", KND_VariableStore.Operation.ADD, 1)
