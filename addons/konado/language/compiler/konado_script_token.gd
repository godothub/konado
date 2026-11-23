extends RefCounted
class_name KonadoScriptToken

## KonadoScript 词法单元（Token）
## 词法分析阶段的最小语法单位

enum Type {
	# 字面量
	STRING_LITERAL,  ## 双引号包裹的字符串 "..."
	NUMBER_LITERAL,  ## 数字（整数或浮点数）
	IDENTIFIER,  ## 标识符（未匹配关键字的裸词）
	VARIABLE_REF,  ## 变量引用 %name 或 $name
	# 主关键字
	KW_SCREENTEXT,
	KW_BACKGROUND,
	KW_ACTOR,
	KW_PLAY,
	KW_STOP,
	KW_CHOICE,
	KW_BRANCH,
	KW_IF,
	KW_ELSE,
	KW_ENDIF,
	KW_SET,
	KW_ADD,
	KW_SUB,
	KW_MUL,
	KW_DIV,
	KW_JUMP,
	KW_JUMP_BRANCH,
	KW_SIGNAL,
	KW_ACHIEVEMENT,
	KW_END,
	KW_CAM,
	KW_ASYNCAM,
	KW_SHOWTEXTBOX,
	KW_HIDETEXTBOX,
	KW_WAITSIGNAL,
	KW_CALL,
	KW_RETURN,
	# 子关键字
	KW_SHOW,
	KW_EXIT,
	KW_CHANGE,
	KW_MOVE,
	KW_MOTION,
	KW_AT,
	KW_BGM,
	KW_SFX,
	KW_UNLOCK,
	KW_INCREMENT,
	KW_SET_FLAG,
	KW_RESET,
	KW_SHAKE,
	# 定界符
	LBRACE,  ## {
	RBRACE,  ## }
	LBRACKET,  ## [
	RBRACKET,  ## ]
	# 运算符
	OP_ARROW,  ## ->
	OP_EQ,  ## ==
	OP_NEQ,  ## !=
	OP_GT,  ## >
	OP_LT,  ## <
	OP_GTE,  ## >=
	OP_LTE,  ## <=
	OP_ASSIGN,  ## =
	COLON,  ## :
	# 结构
	INDENT,  ## 缩进标记
	DEDENT,  ## 结束一个缩进层级
	NEWLINE,  ## 行结束
	EOF,  ## 文件结束
}

## 关键字查找表
const KEYWORDS: Dictionary = {
	"screentext": Type.KW_SCREENTEXT,
	"background": Type.KW_BACKGROUND,
	"actor": Type.KW_ACTOR,
	"play": Type.KW_PLAY,
	"stop": Type.KW_STOP,
	"choice": Type.KW_CHOICE,
	"branch": Type.KW_BRANCH,
	"if": Type.KW_IF,
	"else": Type.KW_ELSE,
	"else:": Type.KW_ELSE,
	"endif": Type.KW_ENDIF,
	"set": Type.KW_SET,
	"add": Type.KW_ADD,
	"sub": Type.KW_SUB,
	"mul": Type.KW_MUL,
	"div": Type.KW_DIV,
	"jump": Type.KW_JUMP,
	"jump_branch": Type.KW_JUMP_BRANCH,
	"call": Type.KW_CALL,
	"return": Type.KW_RETURN,
	"signal": Type.KW_SIGNAL,
	"achievement": Type.KW_ACHIEVEMENT,
	"end": Type.KW_END,
	"cam": Type.KW_CAM,
	"asyncam": Type.KW_ASYNCAM,
	"show": Type.KW_SHOW,
	"exit": Type.KW_EXIT,
	"change": Type.KW_CHANGE,
	"move": Type.KW_MOVE,
	"motion": Type.KW_MOTION,
	"at": Type.KW_AT,
	"bgm": Type.KW_BGM,
	"sfx": Type.KW_SFX,
	"unlock": Type.KW_UNLOCK,
	"increment": Type.KW_INCREMENT,
	"set_flag": Type.KW_SET_FLAG,
	"reset": Type.KW_RESET,
	"shake": Type.KW_SHAKE,
	"showtextbox": Type.KW_SHOWTEXTBOX,
	"hidetextbox": Type.KW_HIDETEXTBOX,
	"waitsignal": Type.KW_WAITSIGNAL,
}

var type: Type
var value: Variant  ## 词素值
var line: int  ## 源代码行号（1-based）
var column: int  ## 列号（1-based）
var length: int  ## 原始词素长度（Unicode 码点）
var start_offset: int = -1  ## 规范化源文本中的起始偏移
var end_offset: int = -1  ## 规范化源文本中的结束偏移（不含）


func _init(
	p_type: Type = Type.EOF,
	p_value: Variant = "",
	p_line: int = 0,
	p_column: int = 0,
	p_length: int = -1,
) -> void:
	type = p_type
	value = p_value
	line = p_line
	column = p_column
	length = p_length if p_length >= 0 else str(p_value).length()


func _to_string() -> String:
	return "Token(%s, %s, L%d:C%d)" % [Type.keys()[type], str(value), line, column]
