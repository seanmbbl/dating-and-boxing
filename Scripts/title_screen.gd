extends TextEdit

func _process(delta):
	if Input.is_key_pressed(KEY_ENTER):
		text = text.replace('\n', '')
		if text.length() == 0:
			return
		$"/root/Interpreter".player_name = text
		get_tree().change_scene("res://_Scenes/Talk.tscn")
