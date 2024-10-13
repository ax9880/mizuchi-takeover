extends MarginContainer

onready var player_controler = $MarginContainer/PlayerController

export(int, 0, 1) var player_index: int = 0

func _ready():
	$AnimationPlayer.play("ready")
	
	player_controler.player_index = player_index
	
	yield($AnimationPlayer, "animation_finished")
	
	player_controler.generate()
	
	player_controler.start()
