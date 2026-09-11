# 示例 10｜条件引用未定义的变量
# 期望：VA-003 variable.not_found → KonadoInstructionExecutor._condition_variable
# 该失败可恢复：失败面板给出 retry / continue_true / continue_false / stop。
# 排错：先用 set 定义变量，或在检查器里预设持久变量。
if %gallery_undefined == 0:
	"Kona" "这一行永远到不了"
endif
end
