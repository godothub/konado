jump_branch menu

branch menu
	choice "take once" -> take once [id=menu_choice]
	choice "leave" -> leave

branch take
	jump_branch menu

branch leave
	end
