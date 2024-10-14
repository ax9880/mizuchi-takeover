extends HBoxContainer


export(PackedScene) var character_texture_rect_packed_scene: PackedScene


func initialize(value: float, characters: Array) -> void:
	$Label.text = _value_to_string(value)
	
	for frame in characters:
		var texture_rect: TextureRect = character_texture_rect_packed_scene.instance()
		texture_rect.texture = texture_rect.texture.duplicate()
		
		add_child(texture_rect)
		
		var x: int = (frame % 12) * 48
		var y: int = int(frame / 12) * 48
		
		var region := Rect2(x, y, 48, 48)
		
		texture_rect.texture.region = region


func focus() -> void:
	$Label.grab_focus()


func _value_to_string(value: float) -> String:
	if is_equal_approx(value, floor(value)):
		return "%.f" % value
	else:
		return "%.1f" % value
