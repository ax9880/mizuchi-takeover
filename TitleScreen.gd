extends MarginContainer


func _ready() -> void:
	$MarginContainer/VBoxContainer/ArcadeModeButton.grab_focus()
	
	if OS.get_name() == "HTML5":
		$MarginContainer/VBoxContainer/QuitButton.hide()


func _on_ArcadeModeButton_pressed() -> void:
	Loader.change_scene("res://Main.tscn")


func _on_QuitButton_pressed() -> void:
	get_tree().quit()
