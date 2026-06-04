extends RefCounted
class_name KS_Analyzer

## KS 语义分析器
## 对 AST 进行语义验证：标签引用、演员生命周期等

var _errors: Array[String] = []
var _warnings: Array[String] = []
var _branch_ids: Array[String] = []
var _active_actors: Array[String] = []
var _dep_characters: Array[String] = []
var _path: String = ""


func _init() -> void:
	pass


## 获取错误列表
func get_errors() -> Array[String]:
	return _errors


## 获取警告列表
func get_warnings() -> Array[String]:
	return _warnings


## 获取角色依赖列表
func get_dep_characters() -> Array[String]:
	return _dep_characters


## 分析 AST，返回 true 表示通过验证
func analyze(script: KS_AST.ScriptNode, path: String = "") -> bool:
	_errors.clear()
	_warnings.clear()
	_branch_ids.clear()
	_active_actors.clear()
	_dep_characters.clear()
	_path = path

	# 第一遍：收集所有 branch 标签ID
	_collect_branch_ids(script)

	# 第二遍：验证所有语句
	_validate_statements(script.statements, "主线")

	return _errors.is_empty()


## 收集所有 branch 声明的标签ID
func _collect_branch_ids(script: KS_AST.ScriptNode) -> void:
	for stmt in script.statements:
		if stmt is KS_AST.BranchNode:
			_branch_ids.append(stmt.branch_id)


## 验证语句列表
func _validate_statements(stmts: Array, context: String) -> void:
	for stmt in stmts:
		_validate_node(stmt, context)


## 分发验证单个节点
func _validate_node(node: KS_AST.ASTNode, context: String) -> void:
	if node is KS_AST.ActorNode:
		_validate_actor(node, context)
	elif node is KS_AST.ChoiceGroupNode:
		_validate_choice(node, context)
	elif node is KS_AST.BranchNode:
		_validate_branch(node)
	elif node is KS_AST.IfElseNode:
		_validate_if_else(node, context)
	elif node is KS_AST.JumpBranchNode:
		_validate_jump_branch(node, context)
	elif node is KS_AST.DialogueNode:
		pass  # 对话节点无需额外验证
	elif node is KS_AST.BackgroundNode:
		pass
	elif node is KS_AST.AudioNode:
		pass
	elif node is KS_AST.VariableNode:
		pass
	elif node is KS_AST.JumpNode:
		pass
	elif node is KS_AST.SignalNode:
		if node.signal_content.is_empty():
			_error(node.line, "信号指令内容为空")
	elif node is KS_AST.AchievementNode:
		_validate_achievement(node)
	elif node is KS_AST.EndNode:
		pass


## 验证演员操作
func _validate_actor(node: KS_AST.ActorNode, context: String) -> void:
	match node.action:
		"show":
			if not _dep_characters.has(node.actor_name):
				_dep_characters.append(node.actor_name)
			if _active_actors.has(node.actor_name):
				_error(node.line, "角色 '%s' 已存在，请检查角色名称是否重复创建" % node.actor_name)
			else:
				_active_actors.append(node.actor_name)
		"exit":
			if _active_actors.has(node.actor_name):
				_active_actors.erase(node.actor_name)
			else:
				_warning(node.line, "无法移除不存在的角色 '%s'" % node.actor_name)
		"change":
			if not _active_actors.has(node.actor_name):
				_warning(node.line, "无法改变不存在角色 '%s' 的状态" % node.actor_name)
		"move":
			if not _active_actors.has(node.actor_name):
				_warning(node.line, "无法移动不存在的角色 '%s'" % node.actor_name)


## 验证选项跳转目标
func _validate_choice(node: KS_AST.ChoiceGroupNode, context: String) -> void:
	if node.options.is_empty():
		_error(node.line, "选项行没有有效的选项")
		return

	for option in node.options:
		if not _branch_ids.has(option.branch_target):
			_error(node.line, "跳转标签 '%s' 不存在（当前可选标签：%s）" % [
				option.branch_target, str(_branch_ids)])


## 验证分支
func _validate_branch(node: KS_AST.BranchNode) -> void:
	# 检查分支内不能嵌套分支
	for stmt in node.body:
		if stmt is KS_AST.BranchNode:
			_error(stmt.line, "branch 内不能嵌套 branch")
			return

	# 验证分支内部语句
	_validate_statements(node.body, "分支 '%s'" % node.branch_id)


## 验证条件分支
func _validate_if_else(node: KS_AST.IfElseNode, context: String) -> void:
	_validate_statements(node.if_body, "%s/if块" % context)
	if node.else_body.size() > 0:
		_validate_statements(node.else_body, "%s/else块" % context)


## 验证 jump_branch 目标
func _validate_jump_branch(node: KS_AST.JumpBranchNode, context: String) -> void:
	if not _branch_ids.has(node.target_branch):
		_warning(node.line, "jump_branch 目标分支 '%s' 未找到" % node.target_branch)


## 验证成就操作
func _validate_achievement(node: KS_AST.AchievementNode) -> void:
	if node.target_id.is_empty():
		_error(node.line, "achievement 目标ID为空")


func _error(line_num: int, msg: String) -> void:
	var err := "错误：%s [行：%d] %s" % [_path, line_num, msg]
	_errors.append(err)
	push_error(err)


func _warning(line_num: int, msg: String) -> void:
	var warn := "警告：%s [行：%d] %s" % [_path, line_num, msg]
	_warnings.append(warn)
	push_warning(warn)
