@tool
extends RefCounted
class_name KonadoScriptDiagnosticMessages

## Localizes compiler diagnostics shown by the Godot Script Editor.
##
## Compiler messages remain stable for logs and compatibility. The editor layer
## translates their structured message body according to the editor UI language.

const EXACT_ENGLISH: Dictionary = {
	"文件不存在，无法打开脚本文件": "The script file does not exist or cannot be opened.",
	"无法打开脚本文件": "The script file could not be opened.",
	"字符串字面量未闭合": "Unterminated string literal.",
	"解析器未能消费当前语句": "The parser could not consume the current statement.",
	"意外的 else：当前没有等待结束的 if 条件块": "Unexpected else: there is no open if block.",
	"意外的 endif：当前没有等待结束的 if 条件块": "Unexpected endif: there is no open if block.",
	"screentext 缺少 {": "screentext requires an opening {.",
	"screentext 块内仅允许字符串文本或结束符 }":
	"Only string lines or the closing } are allowed inside screentext.",
	"screentext 缺少结束符 }": "screentext requires a closing }.",
	"showtextbox 缺少动画时长": "showtextbox requires an animation duration.",
	"hidetextbox 缺少动画时长": "hidetextbox requires an animation duration.",
	"waitsignal 缺少信号名称": "waitsignal requires a signal name.",
	"background 缺少背景资源名": "background requires a background resource name.",
	"actor 缺少操作指令": "actor requires an action.",
	"actor show 缺少角色名": "actor show requires an actor name.",
	"actor show 缺少状态": "actor show requires a state.",
	"actor show 缺少 at 和位置": "actor show requires at followed by a position.",
	"actor show 状态后应为 at": "actor show expects at after the state.",
	"actor show 的 at 缺少位置": "actor show requires a position after at.",
	"actor exit 缺少角色名": "actor exit requires an actor name.",
	"actor change 缺少角色名": "actor change requires an actor name.",
	"actor change 缺少新状态": "actor change requires a new state.",
	"actor move 缺少角色名": "actor move requires an actor name.",
	"actor move 缺少目标坐标": "actor move requires a target position.",
	"actor motion 缺少角色名": "actor motion requires an actor name.",
	"actor motion 缺少动作名": "actor motion requires a motion name.",
	"play 缺少音频类型": "play requires an audio type.",
	"cam 缺少操作指令": "cam requires an action.",
	"cam move 缺少目标镜头名": "cam move requires a target camera.",
	"asyncam 缺少操作指令": "asyncam requires an action.",
	"asyncam move 缺少目标镜头名": "asyncam move requires a target camera.",
	"choice 缺少选项文本": "choice requires option text.",
	"choice 缺少 -> 运算符": "choice requires the -> operator.",
	"choice 缺少目标分支名": "choice requires a target branch.",
	"choice 条件缺少变量引用（格式：choice \"文本\" -> 分支 if %变量名 == 值）":
	(
		"choice conditions require a variable reference (format: choice \"text\" -> branch if "
		+ "%variable == value)."
	),
	"choice 条件缺少比较运算符": "choice conditions require a comparison operator.",
	"choice 条件缺少目标值": "choice conditions require a comparison value.",
	"choice 条件重复": "A choice can only declare one condition.",
	"choice once 重复": "A choice can only declare once once.",
	"branch 缺少标签ID": "branch requires an identifier.",
	"if 条件缺少变量引用（格式：if %变量名 == 值:）":
	"if requires a variable reference (format: if %variable == value:).",
	"if 条件缺少比较运算符": "if requires a comparison operator.",
	"if 条件缺少目标值": "if requires a comparison value.",
	"if 条件目标值应为整数": "The if comparison value must be an integer.",
	"if 条件末尾缺少冒号": "The if condition must end with a colon.",
	"if 条件冒号后不允许其他内容": "Nothing is allowed after the if condition's colon.",
	"else 末尾缺少冒号": "else must end with a colon.",
	"else 冒号后不允许其他内容": "Nothing is allowed after the else colon.",
	"endif 后不允许其他内容": "Nothing is allowed after endif.",
	"if 条件块缺少 endif": "The if block requires endif.",
	"对话开头应为演员标识符、变量或带引号的署名":
	"A dialogue must start with an actor identifier, variable, or quoted speaker label.",
	"对话语句后存在多余内容": "Unexpected content after the dialogue statement.",
	"showtextbox 动画时长后存在多余内容": "Unexpected content after the showtextbox duration.",
	"hidetextbox 动画时长后存在多余内容": "Unexpected content after the hidetextbox duration.",
	"waitsignal 信号名称后存在多余内容": "Unexpected content after the waitsignal name.",
	"background 参数后存在多余内容": "Unexpected content after the background arguments.",
	"actor 参数后存在多余内容": "Unexpected content after the actor arguments.",
	"play 参数后存在多余内容": "Unexpected content after the play arguments.",
	"stop bgm 后存在多余内容": "Unexpected content after stop bgm.",
	"cam 参数后存在多余内容": "Unexpected content after the cam arguments.",
	"asyncam 参数后存在多余内容": "Unexpected content after the asyncam arguments.",
	"choice 目标分支后存在多余内容": "Unexpected content after the choice target.",
	"branch 标签后存在多余内容": "Unexpected content after the branch identifier.",
	"jump_branch 目标分支后存在多余内容": "Unexpected content after the jump_branch target.",
	"achievement 参数后存在多余内容": "Unexpected content after the achievement arguments.",
	"end 后存在多余内容": "Unexpected content after end.",
	"showtextbox 动画时长不能为负数": "The showtextbox duration cannot be negative.",
	"hidetextbox 动画时长不能为负数": "The hidetextbox duration cannot be negative.",
	"cam 过渡时长应为数字": "The cam transition duration must be numeric.",
	"cam 震动时长应为数字": "The cam shake duration must be numeric.",
	"asyncam 过渡时长应为数字": "The asyncam transition duration must be numeric.",
	"asyncam 震动时长应为数字": "The asyncam shake duration must be numeric.",
	"镜头过渡时长不能为负数": "The camera transition duration cannot be negative.",
	"镜头震动时长不能为负数": "The camera shake duration cannot be negative.",
	"achievement increment 增量应为整数": "achievement increment requires an integer amount.",
	"achievement set_flag 布尔值应为 true 或 false": "achievement set_flag requires true or false.",
	"jump 缺少目标路径": "jump requires a target script path.",
	"jump 目标必须是 res:// 下的 .ks 文件": "jump requires a .ks file under res://.",
	"jump_branch 缺少目标分支名": "jump_branch requires a target branch.",
	"call 缺少目标分支名": "call requires a target branch.",
	"call 目标必须是本剧本内有效的分支标识符（跨剧本调用暂不支持，请使用 jump）":
	"call requires a branch identifier in the current script; use jump for another script.",
	"call 目标分支后存在多余内容": "Unexpected content after the call target.",
	"return 后存在多余内容": "Unexpected content after return.",
	"signal 缺少信号内容": "signal requires a signal name.",
	"achievement 缺少操作类型": "achievement requires an action.",
	"achievement increment 缺少增量数值": "achievement increment requires an amount.",
	"achievement set_flag 缺少布尔值": "achievement set_flag requires a boolean value.",
	"branch 内不能嵌套 branch": "A branch cannot be nested inside another branch.",
	"选项行没有有效的选项": "The choice statement contains no valid option.",
	"信号指令内容为空": "The signal command cannot be empty.",
	"achievement 目标ID为空": "The achievement target ID cannot be empty.",
}
const DYNAMIC_TRANSLATION_SAMPLES := [
	"无法识别的语法：endif1；条件块结束关键字应为 endif",
	"无法识别的语法：unknown",
	"期望 IDENTIFIER，实际为 EOF",
	"未知的 actor 操作: dance",
	"play 后应为 bgm 或 sfx，实际为: voice",
	"play bgm 缺少资源名",
	"cam 未知操作: fly（应为 move、reset 或 shake）",
	"asyncam 未知操作: fly（应为 move、reset、shake 或 stop）",
	"if 条件的比较运算符无效: =",
	"choice 条件的比较运算符无效: =",
	"镜头过渡类型无效：instant",
	"set 变量值后存在多余内容",
	"set 缺少变量名（格式：set %变量名 值）",
	"set 缺少变量值",
	"achievement unlock 缺少目标ID",
	"未知的 achievement 操作: reset",
	"branch 标签 'intro' 重复",
	"跳转标签 'missing' 不存在（当前可选标签：[intro]）",
	"jump_branch 目标分支 'missing' 未找到",
	"call 目标分支 'missing' 未找到",
	"call 目标分支 'missing' 不存在或为空",
	"call 形成递归调用环：a → a",
	"call 调用链超过 256 层安全上限",
	"jump 目标剧本 'res://missing.ks' 不存在",
	"目标效果 'unknown' 未找到",
	"角色 'Kona' 在部分路径上不存在，无法安全移动",
	"角色 'Kona' 不存在，无法移动",
	"未找到角色 'Kona'",
	"角色 'Kona' 存在 2 个重复定义",
	"角色 'Kona' 未配置目标资源",
	"角色 'Kona' 的目标资源不存在：res://missing.tscn",
]

static var _dynamic_rules: Array[Dictionary] = []


static func describe(message: String, locale: String = "") -> Dictionary:
	_ensure_dynamic_rules()
	if EXACT_ENGLISH.has(message):
		return {
			"code": _exact_code(message),
			"arguments": [],
			"message":
			message if KonadoScriptEditorLocale.is_chinese(locale) else EXACT_ENGLISH[message],
			"raw_message": message,
		}
	for rule: Dictionary in _dynamic_rules:
		var match_result: RegExMatch = (rule["regex"] as RegEx).search(message)
		if match_result == null:
			continue
		var values: Array = []
		for group_index: int in range(1, match_result.get_group_count() + 1):
			values.append(match_result.get_string(group_index))
		return {
			"code": rule["code"],
			"arguments": values,
			"message":
			(
				message
				if KonadoScriptEditorLocale.is_chinese(locale)
				else String(rule["template"]) % values
			),
			"raw_message": message,
		}
	return {
		"code": _fallback_code(message),
		"arguments": [],
		"message":
		message if KonadoScriptEditorLocale.is_chinese(locale) else "KonadoScript: " + message,
		"raw_message": message,
	}


static func localize(message: String, locale: String = "") -> String:
	return String(describe(message, locale)["message"])


static func validate_catalog() -> PackedStringArray:
	var problems := PackedStringArray()
	for message: String in EXACT_ENGLISH:
		if localize(message, "en").begins_with("KonadoScript: "):
			problems.append("Missing exact English translation: %s" % message)
	for message: String in DYNAMIC_TRANSLATION_SAMPLES:
		if localize(message, "en").begins_with("KonadoScript: "):
			problems.append("Missing dynamic English translation: %s" % message)
		if localize(message, "zh_CN") != message:
			problems.append("Chinese diagnostic changed unexpectedly: %s" % message)
	return problems


static func _ensure_dynamic_rules() -> void:
	if not _dynamic_rules.is_empty():
		return
	_add_rule(
		"^无法识别的语法：(.+)；条件块结束关键字应为 endif$",
		"Unrecognized syntax: %s; a conditional block must end with endif.",
		"syntax.unrecognized_endif",
	)
	_add_rule("^无法识别的语法：(.+)$", "Unrecognized syntax: %s.", "syntax.unrecognized")
	_add_rule("^期望 (.+)，实际为 (.+)$", "Expected %s; got %s.", "syntax.unexpected_token")
	_add_rule("^未知的 actor 操作: (.+)$", "Unknown actor action: %s.", "syntax.actor_action")
	_add_rule(
		"^play 后应为 bgm 或 sfx，实际为: (.+)$",
		"Expected bgm or sfx after play; got %s.",
		"syntax.audio_type",
	)
	_add_rule(
		"^play (.+) 缺少资源名$",
		"play %s requires a resource name.",
		"syntax.missing_argument",
	)
	_add_rule(
		"^cam 未知操作: (.+)（应为 move、reset 或 shake）$",
		"Unknown cam action: %s (expected move, reset, or shake).",
		"syntax.camera_action",
	)
	_add_rule(
		"^asyncam 未知操作: (.+)（应为 move、reset、shake 或 stop）$",
		"Unknown asyncam action: %s (expected move, reset, shake, or stop).",
		"syntax.camera_action",
	)
	_add_rule(
		"^if 条件的比较运算符无效: (.+)$",
		"Invalid if comparison operator: %s.",
		"syntax.comparison_operator",
	)
	_add_rule(
		"^choice 条件的比较运算符无效: (.+)$",
		"Invalid choice comparison operator: %s.",
		"syntax.comparison_operator",
	)
	_add_rule(
		"^镜头过渡类型无效：(.+)$",
		"Invalid camera transition: %s.",
		"syntax.camera_transition",
	)
	_add_rule(
		"^(set|add|sub|mul|div) 变量值后存在多余内容$",
		"Unexpected content after the %s value.",
		"syntax.trailing_content",
	)
	_add_rule(
		"^(.+) 缺少变量名（格式：(.+) %变量名 值）$",
		"%s requires a variable name (format: %s %%variable value).",
		"syntax.missing_argument",
	)
	_add_rule(
		"^(set|add|sub|mul|div) 缺少变量值$",
		"%s requires a value.",
		"syntax.missing_argument",
	)
	_add_rule(
		"^achievement (.+) 缺少目标ID$",
		"achievement %s requires a target ID.",
		"syntax.missing_argument",
	)
	_add_rule(
		"^未知的 achievement 操作: (.+)$",
		"Unknown achievement action: %s.",
		"syntax.achievement_action",
	)
	_add_rule(
		"^branch 标签 '(.+)' 重复$",
		"Duplicate branch label '%s'.",
		"semantic.duplicate_branch",
	)
	_add_rule(
		"^跳转标签 '(.+)' 不存在（当前可选标签：(.+)）$",
		"Target branch '%s' does not exist (available branches: %s).",
		"semantic.missing_branch",
	)
	_add_rule(
		"^jump_branch 目标分支 '(.+)' 未找到$",
		"Target branch '%s' was not found.",
		"semantic.missing_branch",
	)
	_add_rule(
		"^call 目标分支 '(.+)' 未找到$",
		"Call target branch '%s' was not found.",
		"semantic.missing_branch",
	)
	_add_rule(
		"^call 目标分支 '(.+)' 不存在或为空$",
		"Call target branch '%s' does not exist or is empty.",
		"semantic.missing_branch",
	)
	_add_rule(
		"^call 形成递归调用环：(.+)$",
		"call would recurse (%s); recursive calls are not supported.",
		"semantic.recursive_call",
	)
	_add_rule(
		"^call 调用链超过 (.+) 层安全上限$",
		"The call chain exceeds the %s-level safety limit.",
		"semantic.call_chain_too_deep",
	)
	_add_rule(
		"^jump 目标剧本 '(.+)' 不存在$",
		"Target KonadoScript '%s' does not exist.",
		"semantic.missing_script",
	)
	_add_rule(
		"^目标效果 '(.+)' 未找到$",
		"Background effect '%s' was not found.",
		"semantic.missing_effect",
	)
	_add_rule(
		"^角色 '(.+)' 在部分路径上不存在，无法安全(.+)$",
		"Actor '%s' is unavailable on some paths, so it cannot safely perform: %s.",
		"semantic.actor_maybe_missing",
	)
	_add_rule(
		"^角色 '(.+)' 不存在，无法(.+)$",
		"Actor '%s' does not exist; cannot perform: %s.",
		"semantic.actor_missing",
	)
	var resource_kinds := {
		"角色": "actor",
		"背景": "background",
		"背景音乐": "BGM",
		"音效": "sound effect",
		"语音": "voice",
		"角色状态": "actor state",
		"演员动作": "actor motion",
		"镜头配置": "camera setup",
	}
	for chinese_kind: String in resource_kinds:
		var english_kind := String(resource_kinds[chinese_kind])
		_add_rule(
			"^未找到%s '(.+)'$" % chinese_kind,
			"Unknown %s: '%%s'." % english_kind,
			"resource.unknown",
		)
		_add_rule(
			"^%s '(.+)' 存在 (\\d+) 个重复定义$" % chinese_kind,
			"%s '%%s' has %%s duplicate definitions." % english_kind.capitalize(),
			"resource.duplicate",
		)
		_add_rule(
			"^%s '(.+)' 未配置目标资源$" % chinese_kind,
			"%s '%%s' has no target resource." % english_kind.capitalize(),
			"resource.unassigned",
		)
		_add_rule(
			"^%s '(.+)' 的目标资源不存在：(.+)$" % chinese_kind,
			"%s '%%s' targets a missing resource: %%s." % english_kind.capitalize(),
			"resource.missing_target",
		)


static func _add_rule(pattern: String, template: String, code: String) -> void:
	var regex := RegEx.new()
	if regex.compile(pattern) == OK:
		_dynamic_rules.append({"regex": regex, "template": template, "code": code})


static func _exact_code(message: String) -> String:
	return (
		{
			"文件不存在，无法打开脚本文件": "io.script_missing",
			"无法打开脚本文件": "io.script_unreadable",
			"字符串字面量未闭合": "lexer.unterminated_string",
			"意外的 else：当前没有等待结束的 if 条件块": "syntax.unexpected_else",
			"意外的 endif：当前没有等待结束的 if 条件块": "syntax.unexpected_endif",
			"screentext 缺少 {": "syntax.screentext_missing_open",
			"screentext 缺少结束符 }": "syntax.screentext_missing_close",
			"choice 缺少 -> 运算符": "syntax.choice_missing_arrow",
			"call 目标必须是本剧本内有效的分支标识符（跨剧本调用暂不支持，请使用 jump）":
			"syntax.invalid_value",
			"actor show 缺少 at 和位置": "syntax.actor_position",
			"actor show 状态后应为 at": "syntax.actor_position",
			"actor show 的 at 缺少位置": "syntax.actor_position",
			"if 条件末尾缺少冒号": "syntax.if_missing_colon",
			"if 条件的比较运算符无效": "syntax.comparison_operator",
			"else 末尾缺少冒号": "syntax.else_missing_colon",
			"if 条件块缺少 endif": "syntax.if_missing_endif",
			"achievement set_flag 布尔值应为 true 或 false": "syntax.boolean_value",
		}
		. get(message, _fallback_code(message))
	)


static func _fallback_code(message: String) -> String:
	if "后存在多余内容" in message or "后不允许其他内容" in message:
		return "syntax.trailing_content"
	if "缺少" in message:
		return "syntax.missing_argument"
	if "应为" in message or "无效" in message or "不能" in message:
		return "syntax.invalid_value"
	if message in ["branch 内不能嵌套 branch", "选项行没有有效的选项"]:
		return "semantic.invalid_structure"
	if message in ["信号指令内容为空", "achievement 目标ID为空"]:
		return "semantic.empty_value"
	return "compiler.diagnostic"
