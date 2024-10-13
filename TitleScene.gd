extends MarginContainer


func _ready() -> void:
	$MarginContainer/VBoxContainer/ArcadeModeButton.grab_focus()


func _on_ArcadeModeButton_pressed() -> void:
	Loader.change_scene("res://Main.tscn")
