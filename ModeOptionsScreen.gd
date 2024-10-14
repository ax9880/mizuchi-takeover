extends MarginContainer


func _ready() -> void:
	# Resets game data
	GameData.starting_size = 3
	GameData.can_grow_size = true
	GameData.time_seconds = 120
	
	if GameData.is_two_player_mode:
		GameData.can_grow_size = false
		GameData.starting_size = 4
		
		$MarginContainer/VBoxContainer/CanGrowSizeCheckBox.set_pressed_no_signal(false)
		$MarginContainer/VBoxContainer/HBoxContainer/SizeOptionButton.select(1)
	
	$MarginContainer/VBoxContainer/StartButton.grab_focus()


func _on_StartButton_pressed() -> void:
	if GameData.is_two_player_mode:
		var _error: int = Loader.change_scene("res://VsMode.tscn")
	else:
		var _error: int = Loader.change_scene("res://Main.tscn")


func _on_SizeOptionButton_item_selected(index: int) -> void:
	$PressedAudio.play()
	
	match(index):
		0:
			GameData.starting_size = 3
		1:
			GameData.starting_size = 4
		2:
			GameData.starting_size = 5
		3:
			GameData.starting_size = 6


func _on_CanGrowSizeCheckBox_toggled(button_pressed: bool) -> void:
	$PressedAudio.play()
	
	GameData.can_grow_size = button_pressed


func _on_TimeOptionButton_item_selected(index: int) -> void:
	$PressedAudio.play()
	
	match(index):
		0:
			GameData.time_seconds = 60
		1:
			GameData.time_seconds = 120
		2:
			GameData.time_seconds = 60 * 5


func _on_CancelButton_pressed() -> void:
	var _error: int = Loader.change_scene("res://TitleScreen.tscn")
