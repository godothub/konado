extends RefCounted
class_name KonadoScriptLanguageCatalog

## KonadoScript 语言功能使用的统一语言目录。
##
## 解析器仍以 KonadoScriptToken.KEYWORDS 作为合法关键字的唯一来源。本目录只描述
## 编辑器展示所需的分组、补全关系和可插入模板，并通过测试确保目录中的
## 关键字始终是解析器已注册的关键字。

const ROOT_KEYWORDS: PackedStringArray = [
	"screentext",
	"showtextbox",
	"hidetextbox",
	"waitsignal",
	"background",
	"actor",
	"play",
	"stop",
	"choice",
	"branch",
	"if",
	"else",
	"endif",
	"set",
	"add",
	"sub",
	"mul",
	"div",
	"jump",
	"jump_branch",
	"call",
	"return",
	"signal",
	"achievement",
	"cam",
	"asyncam",
	"end",
]

const CONTEXT_COMPLETIONS: Dictionary = {
	"actor": ["show", "exit", "change", "move", "motion"],
	"play": ["bgm", "sfx"],
	"stop": ["bgm"],
	"cam": ["move", "reset", "shake"],
	"asyncam": ["move", "reset", "shake", "stop"],
	"achievement": ["unlock", "increment", "set_flag"],
}

const STRUCTURAL_KEYWORDS: PackedStringArray = ["at"]
const CAMERA_TRANSITIONS: PackedStringArray = ["none", "linear", "ease_in_out"]
const POSITION_VALUES: PackedStringArray = ["1", "2", "3", "4", "5"]
const LIKELY_POSITION_VALUES: PackedStringArray = ["3", "2", "1"]

const SIGNATURES: Dictionary = {
	"screentext": "screentext { ... }",
	"showtextbox": "showtextbox [duration]",
	"hidetextbox": "hidetextbox [duration]",
	"waitsignal": "waitsignal <signal_name>",
	"background": "background <background_name> [transition]",
	"actor": "actor <show|exit|change|move|motion> ...",
	"actor show": "actor show <actor_name> <state_name> at <position>",
	"actor exit": "actor exit <actor_name>",
	"actor change": "actor change <actor_name> <state_name>",
	"actor move": "actor move <actor_name> <position>",
	"actor motion": "actor motion <actor_name> <motion_name>",
	"play": "play <bgm|sfx> <resource_name>",
	"play bgm": "play bgm <background_music_name>",
	"play sfx": "play sfx <sound_effect_name>",
	"stop": "stop bgm",
	"choice": 'choice "<option>" -> <branch_name> [if <condition>] [once]',
	"branch": "branch <branch_name>",
	"if": "if <%variable|$variable> <operator> <value>:",
	"else": "else:",
	"endif": "endif",
	"set": "set <%variable|$variable> [=] <value>",
	"add": "add <%variable|$variable> <value>",
	"sub": "sub <%variable|$variable> <value>",
	"mul": "mul <%variable|$variable> <value>",
	"div": "div <%variable|$variable> <value>",
	"jump": "jump <res://path/to/script.ks>",
	"jump_branch": "jump_branch <branch_name>",
	"call": "call <branch_name>",
	"return": "return",
	"signal": "signal <signal_name>",
	"achievement": "achievement <unlock|increment|set_flag> ...",
	"achievement unlock": 'achievement unlock "<achievement_id>"',
	"achievement increment": 'achievement increment "<achievement_id>" <amount>',
	"achievement set_flag": 'achievement set_flag "<flag_id>" <true|false>',
	"cam": "cam <move|reset|shake> ...",
	"cam move": "cam move <camera_name> [transition] [duration]",
	"cam reset": "cam reset [transition] [duration]",
	"cam shake": "cam shake [duration]",
	"asyncam": "asyncam <move|reset|shake|stop> ...",
	"asyncam move": "asyncam move <camera_name> [transition] [duration]",
	"asyncam reset": "asyncam reset [transition] [duration]",
	"asyncam shake": "asyncam shake [duration]",
	"asyncam stop": "asyncam stop",
	"end": "end",
}

const COMMAND_DESCRIPTIONS: Dictionary = {
	"screentext":
	{
		"en": "Display a full-screen text block.",
		"zh": "显示全屏文本块。",
	},
	"showtextbox":
	{
		"en": "Show the dialogue box.",
		"zh": "显示对话框。",
	},
	"hidetextbox":
	{
		"en": "Hide the dialogue box.",
		"zh": "隐藏对话框。",
	},
	"waitsignal":
	{
		"en": "Pause dialogue until an external signal is emitted.",
		"zh": "暂停剧情并等待外部信号。",
	},
	"background":
	{
		"en": "Switch the active background.",
		"zh": "切换当前背景。",
	},
	"actor":
	{
		"en": "Control an actor on the stage.",
		"zh": "控制舞台上的演员。",
	},
	"play":
	{
		"en": "Play background music or a sound effect.",
		"zh": "播放背景音乐或音效。",
	},
	"stop":
	{
		"en": "Stop the active background music.",
		"zh": "停止当前背景音乐。",
	},
	"choice":
	{
		"en": "Add a choice that targets a branch, optionally gated by a condition or shown only once.",
		"zh": "添加跳转到分支的选项，可按条件显示或只显示一次。",
	},
	"branch":
	{
		"en": "Declare a branch in the current script.",
		"zh": "声明当前剧本中的分支。",
	},
	"if":
	{
		"en": "Start a conditional block.",
		"zh": "开始条件块。",
	},
	"else":
	{
		"en": "Start the fallback section of a conditional block.",
		"zh": "开始条件块的备用分支。",
	},
	"endif":
	{
		"en": "End a conditional block.",
		"zh": "结束条件块。",
	},
	"set":
	{
		"en": "Assign a persistent or temporary variable.",
		"zh": "设置持久变量或临时变量。",
	},
	"add": {"en": "Add to a variable.", "zh": "对变量执行加法或追加。"},
	"sub": {"en": "Subtract from a variable.", "zh": "对变量执行减法。"},
	"mul": {"en": "Multiply a variable.", "zh": "对变量执行乘法。"},
	"div": {"en": "Divide a variable.", "zh": "对变量执行除法。"},
	"jump": {"en": "Load another KonadoScript.", "zh": "跳转到另一个 KonadoScript。"},
	"jump_branch":
	{
		"en": "Jump to a branch in the current script.",
		"zh": "跳转到当前剧本中的分支。",
	},
	"call":
	{
		"en": "Call a branch and return to the next line when it reaches return.",
		"zh": "调用一个分支，遇到 return 时回到下一行继续执行。",
	},
	"return":
	{
		"en": "Return from a called branch; ends the shot when the call stack is empty.",
		"zh": "从被调用的分支返回；调用栈为空时结束当前镜头。",
	},
	"signal": {"en": "Emit a dialogue signal.", "zh": "发送剧情信号。"},
	"achievement":
	{
		"en": "Update an achievement or flag.",
		"zh": "更新成就或标记。",
	},
	"cam": {"en": "Run a blocking camera operation.", "zh": "执行阻塞式镜头操作。"},
	"asyncam":
	{
		"en": "Run a non-blocking camera operation.",
		"zh": "执行非阻塞式镜头操作。",
	},
	"end": {"en": "End the current dialogue.", "zh": "结束当前对话。"},
}

const SNIPPETS: Array[Dictionary] = [
	{
		"group": "dialogue",
		"label": "Dialogue",
		"label_zh": "对话",
		"snippet": 'Character "Dialogue content" voice_id',
		"description": "Insert a character dialogue line",
		"description_zh": "插入角色对话",
	},
	{
		"group": "text",
		"label": "Screen text",
		"label_zh": "全屏文本",
		"snippet": 'screentext {\n    "Text"\n}',
		"description": "Display NVL-style full-screen text",
		"description_zh": "显示 NVL 风格全屏文本",
	},
	{
		"group": "text",
		"label": "Show dialogue box",
		"label_zh": "显示对话框",
		"snippet": "showtextbox 1.0",
		"description": "Show the dialogue box, optionally using a fade duration",
		"description_zh": "显示对话框，可选淡入时长",
	},
	{
		"group": "text",
		"label": "Hide dialogue box",
		"label_zh": "隐藏对话框",
		"snippet": "hidetextbox 1.0",
		"description": "Hide the dialogue box, optionally using a fade duration",
		"description_zh": "隐藏对话框，可选淡出时长",
	},
	{
		"group": "text",
		"label": "Wait for signal",
		"label_zh": "等待信号",
		"snippet": "waitsignal signal_name",
		"description": "Pause until an external signal is emitted",
		"description_zh": "暂停并等待外部信号",
	},
	{
		"group": "stage",
		"label": "Background",
		"label_zh": "切换背景",
		"snippet": "background background_name none",
		"description": "Switch the background with an optional transition",
		"description_zh": "切换背景并指定可选转场",
	},
	{
		"group": "actor",
		"label": "Show actor",
		"label_zh": "演员入场",
		"snippet": "actor show actor_name state_name at 2",
		"description": "Show an actor in a state and position",
		"description_zh": "以指定状态和位置显示演员",
	},
	{
		"group": "actor",
		"label": "Exit actor",
		"label_zh": "演员退场",
		"snippet": "actor exit actor_name",
		"description": "Remove an actor from the stage",
		"description_zh": "让演员离开舞台",
	},
	{
		"group": "actor",
		"label": "Change actor state",
		"label_zh": "切换演员状态",
		"snippet": "actor change actor_name state_name",
		"description": "Change an actor state",
		"description_zh": "切换演员状态",
	},
	{
		"group": "actor",
		"label": "Move actor",
		"label_zh": "移动演员",
		"snippet": "actor move actor_name 2",
		"description": "Move an actor to another position",
		"description_zh": "将演员移动到指定位置",
	},
	{
		"group": "actor",
		"label": "Play actor motion",
		"label_zh": "播放演员动作",
		"snippet": "actor motion actor_name motion_name",
		"description": "Play an actor stage-layer motion",
		"description_zh": "播放演员舞台层动作",
	},
	{
		"group": "audio",
		"label": "Play BGM",
		"label_zh": "播放 BGM",
		"snippet": "play bgm background_music_name",
		"description": "Play background music",
		"description_zh": "播放背景音乐",
	},
	{
		"group": "audio",
		"label": "Play SFX",
		"label_zh": "播放音效",
		"snippet": "play sfx sfx_name",
		"description": "Play a sound effect",
		"description_zh": "播放音效",
	},
	{
		"group": "audio",
		"label": "Stop BGM",
		"label_zh": "停止 BGM",
		"snippet": "stop bgm",
		"description": "Stop background music",
		"description_zh": "停止背景音乐",
	},
	{
		"group": "camera",
		"label": "Move camera",
		"label_zh": "移动相机",
		"snippet": "cam move target linear 1.0",
		"description": "Move the camera and wait for completion",
		"description_zh": "移动相机并等待完成",
	},
	{
		"group": "camera",
		"label": "Reset camera",
		"label_zh": "复位相机",
		"snippet": "cam reset linear 1.0",
		"description": "Reset the camera and wait for completion",
		"description_zh": "复位相机并等待完成",
	},
	{
		"group": "camera",
		"label": "Shake camera",
		"label_zh": "晃动相机",
		"snippet": "cam shake 1.0",
		"description": "Shake the camera and wait for completion",
		"description_zh": "晃动相机并等待完成",
	},
	{
		"group": "camera",
		"label": "Move camera asynchronously",
		"label_zh": "异步移动相机",
		"snippet": "asyncam move target linear 1.0",
		"description": "Move the camera without blocking dialogue",
		"description_zh": "移动相机但不阻塞对话",
	},
	{
		"group": "camera",
		"label": "Reset camera asynchronously",
		"label_zh": "异步复位相机",
		"snippet": "asyncam reset linear 1.0",
		"description": "Reset the camera without blocking dialogue",
		"description_zh": "复位相机但不阻塞对话",
	},
	{
		"group": "camera",
		"label": "Shake camera asynchronously",
		"label_zh": "异步晃动相机",
		"snippet": "asyncam shake 1.0",
		"description": "Shake the camera without blocking dialogue",
		"description_zh": "晃动相机但不阻塞对话",
	},
	{
		"group": "camera",
		"label": "Stop asynchronous camera",
		"label_zh": "停止异步运镜",
		"snippet": "asyncam stop",
		"description": "Stop the active asynchronous camera operation",
		"description_zh": "停止当前异步运镜",
	},
	{
		"group": "variable",
		"label": "Set variable",
		"label_zh": "设置变量",
		"snippet": "set %variable_name = value",
		"description": "Set a persistent or temporary variable",
		"description_zh": "设置持久或临时变量",
	},
	{
		"group": "variable",
		"label": "Add variable",
		"label_zh": "变量加法",
		"snippet": "add %variable_name value",
		"description": "Add or append to a variable",
		"description_zh": "增加数值或追加字符串",
	},
	{
		"group": "variable",
		"label": "Subtract variable",
		"label_zh": "变量减法",
		"snippet": "sub %variable_name value",
		"description": "Subtract from a variable",
		"description_zh": "对变量执行减法",
	},
	{
		"group": "variable",
		"label": "Multiply variable",
		"label_zh": "变量乘法",
		"snippet": "mul %variable_name value",
		"description": "Multiply a variable",
		"description_zh": "对变量执行乘法",
	},
	{
		"group": "variable",
		"label": "Divide variable",
		"label_zh": "变量除法",
		"snippet": "div %variable_name value",
		"description": "Divide a variable",
		"description_zh": "对变量执行除法",
	},
	{
		"group": "condition",
		"label": "Conditional block",
		"label_zh": "条件块",
		"snippet":
		(
			'if %variable_name == 0:\n    "Narrator" "Condition met."\n'
			+ 'else:\n    "Narrator" "Condition not met."\nendif'
		),
		"description": "Insert an if/else conditional block",
		"description_zh": "插入 if/else 条件块",
	},
	{
		"group": "branch",
		"label": "Choice",
		"label_zh": "选项",
		"snippet": 'choice "Option" -> branch_name',
		"description": "Add a dialogue choice",
		"description_zh": "添加对话选项",
	},
	{
		"group": "branch",
		"label": "Conditional choice",
		"label_zh": "条件选项",
		"snippet": 'choice "Option" -> branch_name if %variable_name == 0',
		"description": "Add a choice that is only visible when a condition holds",
		"description_zh": "添加仅在条件成立时显示的选项",
	},
	{
		"group": "branch",
		"label": "One-time choice",
		"label_zh": "一次性选项",
		"snippet": 'choice "Option" -> branch_name once',
		"description": "Add a choice that disappears after it is picked",
		"description_zh": "添加选中一次后不再出现的选项",
	},
	{
		"group": "branch",
		"label": "Branch",
		"label_zh": "分支",
		"snippet": 'branch branch_name\n    "Narrator" "Branch content."',
		"description": "Define a branch",
		"description_zh": "定义分支",
	},
	{
		"group": "branch",
		"label": "Jump to branch",
		"label_zh": "跳转分支",
		"snippet": "jump_branch branch_name",
		"description": "Jump to a branch in the current script",
		"description_zh": "跳转到当前脚本中的分支",
	},
	{
		"group": "branch",
		"label": "Call branch",
		"label_zh": "调用分支",
		"snippet": "call branch_name",
		"description": "Call a branch and return to the next line",
		"description_zh": "调用分支，并在 return 后回到下一行",
	},
	{
		"group": "branch",
		"label": "Return",
		"label_zh": "返回",
		"snippet": "return",
		"description": "Return from the called branch",
		"description_zh": "从被调用的分支返回",
	},
	{
		"group": "flow",
		"label": "Jump to script",
		"label_zh": "跳转剧本",
		"snippet": "jump res://story/next.ks",
		"description": "Jump to another KonadoScript file",
		"description_zh": "跳转到另一个 KonadoScript 文件",
	},
	{
		"group": "flow",
		"label": "Emit signal",
		"label_zh": "发送信号",
		"snippet": "signal signal_name",
		"description": "Emit a dialogue signal",
		"description_zh": "发送对话信号",
	},
	{
		"group": "achievement",
		"label": "Unlock achievement",
		"label_zh": "解锁成就",
		"snippet": 'achievement unlock "achievement_id"',
		"description": "Unlock an achievement",
		"description_zh": "解锁成就",
	},
	{
		"group": "achievement",
		"label": "Increment achievement",
		"label_zh": "增加成就进度",
		"snippet": 'achievement increment "achievement_id" 1',
		"description": "Increment achievement progress",
		"description_zh": "增加成就进度",
	},
	{
		"group": "achievement",
		"label": "Set achievement flag",
		"label_zh": "设置成就标记",
		"snippet": 'achievement set_flag "flag_id" true',
		"description": "Set an achievement flag",
		"description_zh": "设置成就标记",
	},
	{
		"group": "flow",
		"label": "End dialogue",
		"label_zh": "结束对话",
		"snippet": "end",
		"description": "End the current dialogue",
		"description_zh": "结束当前对话",
	},
]

const GROUP_LABELS: Dictionary = {
	"dialogue": {"en": "Dialogue", "zh": "对话"},
	"text": {"en": "Text and UI", "zh": "文本与界面"},
	"stage": {"en": "Stage", "zh": "舞台"},
	"actor": {"en": "Actor", "zh": "演员"},
	"audio": {"en": "Audio", "zh": "音频"},
	"camera": {"en": "Camera", "zh": "相机"},
	"variable": {"en": "Variables", "zh": "变量"},
	"condition": {"en": "Conditions", "zh": "条件"},
	"branch": {"en": "Branches", "zh": "分支"},
	"achievement": {"en": "Achievements", "zh": "成就"},
	"flow": {"en": "Flow", "zh": "流程"},
}


static func is_chinese_locale(locale: String = "") -> bool:
	return KonadoScriptEditorLocale.is_chinese(locale)


static func get_group_label(group: String, chinese: bool) -> String:
	var labels: Dictionary = GROUP_LABELS.get(group, {"en": group, "zh": group})
	return labels["zh"] if chinese else labels["en"]


static func get_snippet_label(snippet: Dictionary, chinese: bool) -> String:
	return snippet.get("label_zh", snippet["label"]) if chinese else snippet["label"]


static func get_snippet_description(snippet: Dictionary, chinese: bool) -> String:
	return (
		snippet.get("description_zh", snippet["description"]) if chinese else snippet["description"]
	)


static func get_context_completions(root_keyword: String) -> PackedStringArray:
	return PackedStringArray(CONTEXT_COMPLETIONS.get(root_keyword, []))


static func get_signature(command: String) -> String:
	return String(SIGNATURES.get(command, ""))


static func get_command_description(command: String, locale: String = "") -> String:
	var description: Dictionary = COMMAND_DESCRIPTIONS.get(command, {})
	if description.is_empty():
		return ""
	return String(
		description["zh"] if KonadoScriptEditorLocale.is_chinese(locale) else description["en"]
	)


static func get_snippet_completions(partial: String, locale: String = "") -> Array[Dictionary]:
	var completions: Array[Dictionary] = []
	var chinese := KonadoScriptEditorLocale.is_chinese(locale)
	for snippet: Dictionary in SNIPPETS:
		var source := String(snippet["snippet"])
		var first_word := source.get_slice(" ", 0)
		if not partial.is_empty() and not first_word.to_lower().begins_with(partial.to_lower()):
			continue
		(
			completions
			. append(
				{
					"text": get_snippet_label(snippet, chinese),
					"insert_text": source,
					"description": get_snippet_description(snippet, chinese),
					"kind": CodeEdit.CodeCompletionKind.KIND_PLAIN_TEXT,
				}
			)
		)
	return completions


static func get_background_effects() -> PackedStringArray:
	return PackedStringArray(KonadoScriptProgramEmitter.BACKGROUND_EFFECTS_MAP.keys())


static func get_parser_keywords() -> PackedStringArray:
	var keywords := PackedStringArray()
	for keyword: String in KonadoScriptToken.KEYWORDS:
		keywords.append(keyword.trim_suffix(":"))
	keywords.sort()
	return keywords


static func get_editor_keywords() -> PackedStringArray:
	var keywords := ROOT_KEYWORDS.duplicate()
	for root_keyword: String in CONTEXT_COMPLETIONS:
		for keyword: String in CONTEXT_COMPLETIONS[root_keyword]:
			if not keywords.has(keyword):
				keywords.append(keyword)
	for keyword: String in STRUCTURAL_KEYWORDS:
		if not keywords.has(keyword):
			keywords.append(keyword)
	keywords.sort()
	return keywords


static func validate_catalog() -> Array[String]:
	var errors: Array[String] = []
	var parser_keywords := get_parser_keywords()
	for keyword: String in get_editor_keywords():
		if not parser_keywords.has(keyword):
			errors.append("编辑器目录包含解析器不支持的关键字：%s" % keyword)
	for keyword: String in ROOT_KEYWORDS:
		if not parser_keywords.has(keyword):
			errors.append("根命令未在解析器中注册：%s" % keyword)
	for keyword: String in parser_keywords:
		if not get_editor_keywords().has(keyword):
			errors.append("解析器关键字未纳入编辑器目录：%s" % keyword)
	return errors
