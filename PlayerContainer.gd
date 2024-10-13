extends MarginContainer

onready var player_controller = $MarginContainer/PlayerController

export(int, 0, 1) var player_index: int = 0

func _ready():
	player_controller.player_index = player_index
	player_controller.rect_size = rect_size
	
	$MarginContainer/HBoxContainer/Points.text = "0"
	$MarginContainer/HBoxContainer/BoardsCleared.text = "0"
	
	# Set size and global position because the nodes in the canvas layer do
	# not inherit that from the root container
	$CanvasLayer/MarginContainer.rect_size = rect_size
	$CanvasLayer/MarginContainer.rect_global_position = rect_global_position
	
	$AnimationPlayer.play("ready")
	
	yield($AnimationPlayer, "animation_finished")
	
	player_controller.generate()
	
	player_controller.start()


func _on_PlayerController_game_finished(points, boards_cleared, perfect_boards, level, lives) -> void:
	$AnimationPlayer.play("game over")
	
	$CanvasLayer/MarginContainer/ResultsMarginContainer.show_results(points, boards_cleared, perfect_boards, level, lives)


func _on_PlayerController_score_updated(points: int, boards_cleared: int) -> void:
	$MarginContainer/HBoxContainer/Points.text = str(points)
	
	$MarginContainer/HBoxContainer/BoardsCleared.text = str(boards_cleared)
