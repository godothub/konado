# 示例 07｜播放不存在的音效
# 期望（未配置音效列表时）：AU-004 audio.list_missing → KonadoDialogueServices._play_bgm
#         （配置了音效列表但缺少音效时）：AU-007 audio.sfx_not_found
# 排错：给 KonadoDialogue 配置 sound_effect_list，并确认音效名与列表一致。
play sfx definitely_missing
end
