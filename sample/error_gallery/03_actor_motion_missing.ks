# 示例 03｜播放不在舞台上角色的动作
# 期望：AC-012 stage.actor_not_present → KonadoInstructionExecutor._actor_motion
# 注意：同类错误码会按“当前指令处理器”精确定位到 _actor_motion，而不是 _actor_change。
# 排错：先 actor show，再 actor motion；并确认动作名存在于动作层（否则报 AC-007）。
actor motion Nobody shake
end
