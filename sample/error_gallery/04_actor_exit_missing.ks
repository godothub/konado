# 示例 04｜让不存在的角色退场
# 期望：AC-012 stage.actor_not_present → KonadoInstructionExecutor._actor_exit
# 排错：演员必须先在舞台上（actor show）才能退场。
actor exit Nobody
end
