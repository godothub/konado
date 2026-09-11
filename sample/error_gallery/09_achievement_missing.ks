# 示例 09｜解锁不存在的成就
# 期望：AH-002 achievement.not_found → KonadoAchievementManager._operation_failure
# 该失败属于“外部副作用屏障”，失败面板只会给出 stop，不提供 retry/skip。
# 排错：在成就配置里声明该成就，或修改成就 ID。
achievement unlock "gallery_missing"
end
