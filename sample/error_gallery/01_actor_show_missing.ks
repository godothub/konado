# 示例 01｜显示一个没有配置的角色
# 期望：AC-011 stage.actor_not_found → KonadoDialogueServices._show_actor
# 排错：在角色列表里添加 character_id = "Nobody"，或把角色名改成已配置的角色。
actor show Nobody 正常 at 3
end
