extends MarginContainer

onready var player_controller = $MarginContainer/PlayerController

export(int, 0, 1) var player_index: int = 0

func _ready():
	player_controller.player_index = player_index
	player_controller.rect_size = rect_size
	
	$MarginContainer/HBoxContainer/Points.text = "0"
	$MarginContainer/HBoxContainer/BoardsCleared.text = "0"
	
	$AnimationPlayer.play("ready")
	
	yield($AnimationPlayer, "animation_finished")
	
	player_controller.generate()
	
	player_controller.start()


func _on_PlayerController_game_finished(points, boards_cleared, perfect_boards, level, lives) -> void:
	$CanvasLayer/ResultsMarginContainer.show_results(points, boards_cleared, perfect_boards, level, lives)


func _on_PlayerController_score_updated(points: int, boards_cleared: int) -> void:
	$MarginContainer/HBoxContainer/Points.text = str(points)
	
	$MarginContainer/HBoxContainer/BoardsCleared.text = str(boards_cleared)
