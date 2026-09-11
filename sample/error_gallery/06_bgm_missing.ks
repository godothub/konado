# 示例 06｜播放不存在的背景音乐
# 期望（未配置音乐列表时）：AU-004 audio.list_missing → KonadoDialogueServices._play_bgm
#         （配置了音乐列表但缺少曲目时）：AU-002 audio.bgm_not_found
# 排错：给 KonadoDialogue 配置 background_music_list，并确认曲目名与列表一致。
play bgm definitely_missing
end
