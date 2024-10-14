extends MarginContainer


export(PackedScene) var game_characters_container_packed_scene: PackedScene


func _ready() -> void:
	var bags: Dictionary = $Grid.bags
	
	var sorted_values: Array = bags.keys()
	sorted_values.sort()
	
	for value in sorted_values:
		# List of frames
		var characters: Array = bags[value]
		characters.sort()
		
		var game_characters_container: Control = game_characters_container_packed_scene.instance()
		
		game_characters_container.initialize(value, characters)
		
		$MarginContainer/ScrollContainer/VBoxContainer.add_child(game_characters_container)
	
	#var margin_container := MarginContainer.new()
	#margin_container.rect_size.y = 64
	#$MarginContainer/ScrollContainer/VBoxContainer.add_child(margin_container)
	
	$MarginContainer/ScrollContainer/VBoxContainer/QuitButton.grab_focus()



func _on_QuitButton_pressed() -> void:
	var _error: int = Loader.change_scene("res://TitleScreen.tscn")
