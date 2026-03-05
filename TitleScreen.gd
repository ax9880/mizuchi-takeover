extends MarginContainer


func _ready() -> void:
	$MarginContainer/VBoxContainer/ArcadeModeButton.grab_focus()
	
	if OS.get_name() == "HTML5":
		$MarginContainer/VBoxContainer/QuitButton.hide()
	
	$Music.start_playing()
	
	_on_screen_resized()
	
	get_tree().connect("screen_resized", self, "_on_screen_resized")


func _on_ArcadeModeButton_pressed() -> void:
	var _error: int = Loader.change_scene("res://ModeOptionsScreen.tscn")
	
	GameData.is_two_player_mode = false
	
	$Music.stop_playing()


func _on_QuitButton_pressed() -> void:
	get_tree().quit()


func _on_VsModeButton2_pressed() -> void:
	var _error: int = Loader.change_scene("res://ModeOptionsScreen.tscn")
	
	GameData.is_two_player_mode = true
	
	$Music.stop_playing()


func _on_FullscreenCheckBox_toggled(button_pressed: bool) -> void:
	OS.window_fullscreen = button_pressed


func _on_HelpButton_pressed() -> void:
	var _error: int = Loader.change_scene("res://CharacterList.tscn")


func _on_screen_resized() -> void:
	$MarginContainer/VBoxContainer/FullscreenCheckBox.set_pressed_no_signal(OS.window_fullscreen)
