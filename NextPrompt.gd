extends MarginContainer


export var player_two_texture: Texture


func start(player_index: int) -> void:
	show()
	
	if GameData.is_left_side_player(player_index):
		$HBoxContainer/TextureRect.texture = player_two_texture
	
	$AnimationPlayer.play("move")


func stop() -> void:
	hide()
	
	$AnimationPlayer.stop()
