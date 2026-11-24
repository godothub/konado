export const ROOT_KEYWORDS = [
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
] as const;

export type RootKeyword = (typeof ROOT_KEYWORDS)[number];

export const CONTEXT_KEYWORDS = {
	actor: ["show", "exit", "change", "move", "motion"],
	play: ["bgm", "sfx"],
	stop: ["bgm"],
	cam: ["move", "reset", "shake"],
	asyncam: ["move", "reset", "shake", "stop"],
	achievement: ["unlock", "increment", "set_flag"],
} as const;

export const BACKGROUND_EFFECTS = [
	"none",
	"erase",
	"blinds",
	"wave",
	"fade",
	"vortex",
	"windmill",
	"cyberglitch",
	"blink",
] as const;

export const CAMERA_TRANSITIONS = ["none", "linear", "ease_in_out"] as const;
export const ACTOR_POSITIONS = ["1", "2", "3", "4", "5"] as const;

export interface CommandInfo {
	signature: string;
	description: string;
	descriptionZh: string;
}

export interface NamedParameterInfo {
	type: "identifier" | "number";
	defaultValue: string;
	minimum?: number;
	exclusiveMinimum?: number;
}

export const COMMON_NAMED_PARAMETERS: Readonly<
	Record<string, NamedParameterInfo>
> = {
	id: { type: "identifier", defaultValue: "step_id" },
};

export const COMMAND_NAMED_PARAMETERS: Readonly<
	Record<string, Readonly<Record<string, NamedParameterInfo>>>
> = {
	dialogue: {
		speed: { type: "number", defaultValue: "1.0", exclusiveMinimum: 0 },
		interval: { type: "number", defaultValue: "0.03", minimum: 0 },
	},
	background: {
		duration: { type: "number", defaultValue: "0.3", minimum: 0 },
	},
	"actor show": {
		duration: { type: "number", defaultValue: "0.3", minimum: 0 },
	},
	"actor exit": {
		duration: { type: "number", defaultValue: "0.3", minimum: 0 },
	},
	"actor change": {
		duration: { type: "number", defaultValue: "0.3", minimum: 0 },
	},
	"actor move": {
		duration: { type: "number", defaultValue: "0.3", minimum: 0 },
	},
	"actor motion": {
		duration: { type: "number", defaultValue: "0.3", minimum: 0 },
	},
	showtextbox: {
		duration: { type: "number", defaultValue: "0.3", minimum: 0 },
	},
	hidetextbox: {
		duration: { type: "number", defaultValue: "0.3", minimum: 0 },
	},
	"cam move": {
		duration: { type: "number", defaultValue: "0.3", minimum: 0 },
	},
	"cam reset": {
		duration: { type: "number", defaultValue: "0.3", minimum: 0 },
	},
	"cam shake": {
		duration: { type: "number", defaultValue: "1.0", minimum: 0 },
	},
	"asyncam move": {
		duration: { type: "number", defaultValue: "0.3", minimum: 0 },
	},
	"asyncam reset": {
		duration: { type: "number", defaultValue: "0.3", minimum: 0 },
	},
	"asyncam shake": {
		duration: { type: "number", defaultValue: "1.0", minimum: 0 },
	},
	"play bgm": {
		fade: { type: "number", defaultValue: "1.0", minimum: 0 },
		volume: { type: "number", defaultValue: "0" },
	},
	"play sfx": {
		volume: { type: "number", defaultValue: "0" },
		count: { type: "number", defaultValue: "1", minimum: 1 },
	},
	stop: {
		fade: { type: "number", defaultValue: "1.0", minimum: 0 },
	},
	"stop bgm": {
		fade: { type: "number", defaultValue: "1.0", minimum: 0 },
	},
};

const PARAMETERIZED_COMMANDS = new Set([
	"dialogue",
	"screentext",
	"showtextbox",
	"hidetextbox",
	"waitsignal",
	"background",
	"actor show",
	"actor exit",
	"actor change",
	"actor move",
	"actor motion",
	"play bgm",
	"play sfx",
	"stop",
	"stop bgm",
	"choice",
	"if",
	"set",
	"add",
	"sub",
	"mul",
	"div",
	"jump",
	"jump_branch",
	"call",
	"signal",
	"achievement unlock",
	"achievement increment",
	"achievement set_flag",
	"cam move",
	"cam reset",
	"cam shake",
	"asyncam move",
	"asyncam reset",
	"asyncam shake",
	"asyncam stop",
	"end",
]);

export function namedParametersForCommand(
	command: string,
): Readonly<Record<string, NamedParameterInfo>> {
	if (!PARAMETERIZED_COMMANDS.has(command)) {
		return {};
	}
	return {
		...COMMON_NAMED_PARAMETERS,
		...(COMMAND_NAMED_PARAMETERS[command] ?? {}),
	};
}

export const COMMANDS: Readonly<Record<string, CommandInfo>> = {
	screentext: {
		signature: "screentext { ... }",
		description: "Display a full-screen text block.",
		descriptionZh: "显示全屏文本块。",
	},
	showtextbox: {
		signature: "showtextbox [duration]",
		description: "Show the dialogue box.",
		descriptionZh: "显示对话框。",
	},
	hidetextbox: {
		signature: "hidetextbox [duration]",
		description: "Hide the dialogue box.",
		descriptionZh: "隐藏对话框。",
	},
	waitsignal: {
		signature: "waitsignal <signal_name>",
		description: "Pause the story until an external signal is emitted.",
		descriptionZh: "暂停剧情并等待外部信号。",
	},
	background: {
		signature: "background <background_name> [transition]",
		description: "Switch the active background.",
		descriptionZh: "切换当前背景。",
	},
	actor: {
		signature: "actor <show|exit|change|move|motion> ...",
		description: "Control an actor on the stage.",
		descriptionZh: "控制舞台上的演员。",
	},
	"actor show": {
		signature: "actor show <actor_name> <state_name> at <position>",
		description: "Show an actor in a state and position.",
		descriptionZh: "以指定状态和位置显示演员。",
	},
	"actor exit": {
		signature: "actor exit <actor_name>",
		description: "Remove an actor from the stage.",
		descriptionZh: "让演员离开舞台。",
	},
	"actor change": {
		signature: "actor change <actor_name> <state_name>",
		description: "Change an actor state.",
		descriptionZh: "切换演员状态。",
	},
	"actor move": {
		signature: "actor move <actor_name> <position>",
		description: "Move an actor to another position.",
		descriptionZh: "将演员移动到指定位置。",
	},
	"actor motion": {
		signature: "actor motion <actor_name> <motion_name>",
		description: "Play an actor motion.",
		descriptionZh: "播放演员动作。",
	},
	play: {
		signature: "play <bgm|sfx> <resource_name>",
		description: "Play background music or a sound effect.",
		descriptionZh: "播放背景音乐或音效。",
	},
	"play bgm": {
		signature: "play bgm <bgm_name> [fade] [volume]",
		description:
			"Play background music (event or legacy list entry) with an optional crossfade and dB offset.",
		descriptionZh:
			"播放背景音乐（事件或旧版列表），可指定淡入时长与 dB 偏移。",
	},
	"play sfx": {
		signature: "play sfx <sound_effect_name> [volume] [count]",
		description:
			"Play a sound effect with an optional dB offset and repeat count.",
		descriptionZh: "播放音效，可指定 dB 偏移与重复次数。",
	},
	stop: {
		signature: "stop bgm [fade]",
		description:
			"Stop the active background music with an optional fade out.",
		descriptionZh: "停止当前背景音乐，可指定淡出时长。",
	},
	choice: {
		signature: 'choice "<option>" -> <branch_name> [if <condition>] [once]',
		description:
			"Add a choice that targets a branch, with an optional visible condition and one-time flag.",
		descriptionZh:
			"添加跳转到分支的选项，可附带可见条件（if）与一次性标记（once）。",
	},
	branch: {
		signature: "branch <branch_name>",
		description: "Declare a branch in the current script.",
		descriptionZh: "声明当前剧本中的分支。",
	},
	if: {
		signature: "if <%variable|$variable> <operator> <integer>:",
		description: "Start a conditional block.",
		descriptionZh: "开始条件块。",
	},
	else: {
		signature: "else:",
		description: "Start the fallback section of a conditional block.",
		descriptionZh: "开始条件块的备用分支。",
	},
	endif: {
		signature: "endif",
		description: "End a conditional block.",
		descriptionZh: "结束条件块。",
	},
	set: {
		signature: "set <%variable|$variable> [=] <value>",
		description: "Assign a persistent or temporary variable.",
		descriptionZh: "设置持久变量或临时变量。",
	},
	add: {
		signature: "add <%variable|$variable> <value>",
		description: "Add to a variable or append text.",
		descriptionZh: "对变量执行加法或追加。",
	},
	sub: {
		signature: "sub <%variable|$variable> <value>",
		description: "Subtract from a variable.",
		descriptionZh: "对变量执行减法。",
	},
	mul: {
		signature: "mul <%variable|$variable> <value>",
		description: "Multiply a variable.",
		descriptionZh: "对变量执行乘法。",
	},
	div: {
		signature: "div <%variable|$variable> <value>",
		description: "Divide a variable.",
		descriptionZh: "对变量执行除法。",
	},
	jump: {
		signature: "jump <res://path/to/script.ks>",
		description: "Load another KonadoScript file.",
		descriptionZh: "跳转到另一个 KonadoScript 文件。",
	},
	jump_branch: {
		signature: "jump_branch <branch_name>",
		description: "Jump to a branch in the current script.",
		descriptionZh: "跳转到当前剧本中的分支。",
	},
	call: {
		signature: "call <branch_name>",
		description:
			"Run a branch as a subroutine and continue after it returns.",
		descriptionZh: "调用当前剧本内的分支作为子程序，return 后回到调用点。",
	},
	return: {
		signature: "return",
		description: "Return from a called branch to the statement after call.",
		descriptionZh: "从被调用的分支返回到 call 之后的语句。",
	},
	signal: {
		signature: "signal <signal_name>",
		description: "Emit a story signal.",
		descriptionZh: "发送剧情信号。",
	},
	achievement: {
		signature: "achievement <unlock|increment|set_flag> ...",
		description: "Update an achievement or flag.",
		descriptionZh: "更新成就或标记。",
	},
	"achievement unlock": {
		signature: 'achievement unlock "<achievement_id>"',
		description: "Unlock an achievement.",
		descriptionZh: "解锁成就。",
	},
	"achievement increment": {
		signature: 'achievement increment "<achievement_id>" <amount>',
		description: "Increment achievement progress.",
		descriptionZh: "增加成就进度。",
	},
	"achievement set_flag": {
		signature: 'achievement set_flag "<flag_id>" <true|false>',
		description: "Set an achievement flag.",
		descriptionZh: "设置成就标记。",
	},
	cam: {
		signature: "cam <move|reset|shake> ...",
		description: "Run a blocking camera operation.",
		descriptionZh: "执行阻塞式镜头操作。",
	},
	asyncam: {
		signature: "asyncam <move|reset|shake|stop> ...",
		description: "Run a non-blocking camera operation.",
		descriptionZh: "执行非阻塞式镜头操作。",
	},
	"cam move": {
		signature: "cam move <camera_name> [transition] [duration]",
		description: "Move the camera and wait for completion.",
		descriptionZh: "移动相机并等待完成。",
	},
	"cam reset": {
		signature: "cam reset [transition] [duration]",
		description: "Reset the camera and wait for completion.",
		descriptionZh: "复位相机并等待完成。",
	},
	"cam shake": {
		signature: "cam shake [duration]",
		description: "Shake the camera and wait for completion.",
		descriptionZh: "晃动相机并等待完成。",
	},
	"asyncam move": {
		signature: "asyncam move <camera_name> [transition] [duration]",
		description: "Move the camera without blocking the story.",
		descriptionZh: "移动相机但不阻塞剧情。",
	},
	"asyncam reset": {
		signature: "asyncam reset [transition] [duration]",
		description: "Reset the camera without blocking the story.",
		descriptionZh: "复位相机但不阻塞剧情。",
	},
	"asyncam shake": {
		signature: "asyncam shake [duration]",
		description: "Shake the camera without blocking the story.",
		descriptionZh: "晃动相机但不阻塞剧情。",
	},
	"asyncam stop": {
		signature: "asyncam stop",
		description: "Stop the active asynchronous camera operation.",
		descriptionZh: "停止当前异步运镜。",
	},
	end: {
		signature: "end",
		description: "End the current dialogue.",
		descriptionZh: "结束当前对话。",
	},
};

export interface SnippetInfo {
	label: string;
	labelZh: string;
	detail: string;
	detailZh: string;
	body: string;
}

export const SNIPPETS: readonly SnippetInfo[] = [
	{
		label: "Dialogue",
		labelZh: "对话",
		detail: "Insert a character dialogue line",
		detailZh: "插入角色对话",
		body: '${1:Character} "${2:Dialogue content}"${3: voice_id}',
	},
	{
		label: "Screen text",
		labelZh: "全屏文本",
		detail: "Display a full-screen text block",
		detailZh: "显示全屏文本块",
		body: 'screentext {\n\t"${1:Text}"\n}',
	},
	{
		label: "Conditional block",
		labelZh: "条件块",
		detail: "Insert an if/else conditional block",
		detailZh: "插入 if/else 条件块",
		body: "if ${1:%variable} == ${2:0}:\n\t${3}\nelse:\n\t${4}\nendif",
	},
	{
		label: "Choice",
		labelZh: "选项",
		detail: "Add a dialogue choice",
		detailZh: "添加对话选项",
		body: 'choice "${1:Option}" -> ${2:branch_name}',
	},
	{
		label: "Conditional choice",
		labelZh: "条件选项",
		detail: "Add a choice that only appears while a condition holds",
		detailZh: "添加只在条件成立时出现的选项",
		body: 'choice "${1:Option}" -> ${2:branch_name} if ${3:%love} == ${4:1}',
	},
	{
		label: "Call subroutine",
		labelZh: "调用子程序",
		detail: "Call a branch and continue after it returns",
		detailZh: "调用分支作为子程序，返回后继续执行",
		body: "call ${1:branch_name}",
	},
	{
		label: "Branch",
		labelZh: "分支",
		detail: "Define a branch",
		detailZh: "定义分支",
		body: "branch ${1:branch_name}\n\t${2}",
	},
	{
		label: "Show actor",
		labelZh: "演员入场",
		detail: "Show an actor in a state and position",
		detailZh: "以指定状态和位置显示演员",
		body: "actor show ${1:actor_name} ${2:state_name} at ${3:2}",
	},
	{
		label: "Switch background",
		labelZh: "切换背景",
		detail: "Switch the background with a transition",
		detailZh: "切换背景并指定转场",
		body: "background ${1:background_name} ${2:none}",
	},
	{
		label: "Jump to script",
		labelZh: "跳转剧本",
		detail: "Jump to another KonadoScript file",
		detailZh: "跳转到另一个 KonadoScript 文件",
		body: "jump ${1:res://story/next.ks}",
	},
];

export function commandKey(words: readonly string[]): string {
	const first = words[0]?.replace(/:$/u, "") ?? "";
	const second = words[1]?.replace(/:$/u, "") ?? "";
	if (words.length > 1 && COMMANDS[`${first} ${second}`]) {
		return `${first} ${second}`;
	}
	return first;
}
