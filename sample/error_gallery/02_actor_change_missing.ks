# 示例 02｜切换不在舞台上的角色状态
# 期望：AC-012 stage.actor_not_present → KonadoInstructionExecutor._actor_change
# 排错：先用 actor show 让角色上台，再执行 actor change。
actor change Nobody 正常
end
