extends Node2D


func start(score: int) -> void:
	$Label.text = str(score)
	
	$AnimationPlayer.play("float up and fade")
