extends HBoxContainer


export(PackedScene) var character_texture_rect_packed_scene: PackedScene


func initialize(value: float, characters: Array) -> void:
	$Label.text = _value_to_string(value)
	
	for frame in characters:
		var texture_rect: TextureRect = character_texture_rect_packed_scene.instance()
		texture_rect.texture = ResourceLoader.load(frame)
		
		add_child(texture_rect)


func focus() -> void:
	$Label.grab_focus()


func _value_to_string(value: float) -> String:
	if is_equal_approx(value, floor(value)):
		return "%.f" % value
	else:
		return "%.1f" % value
