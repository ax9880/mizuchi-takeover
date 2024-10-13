extends MarginContainer

onready var player_controller = $MarginContainer/PlayerController

export(int, 0, 1) var player_index: int = 0

func _ready():
	player_controller.player_index = player_index
	
	$AnimationPlayer.play("ready")
	
	yield($AnimationPlayer, "animation_finished")
	
	player_controller.generate()
	
	player_controller.start()
