extends MarginContainer

onready var player_controller := $PlayerController

onready var timer_label: Label = $CanvasLayer/MarginContainer2/HBoxContainer/VBoxContainer/TimerLabel
onready var level_label: Label = $CanvasLayer/MarginContainer2/HBoxContainer/VBoxContainer2/Level
onready var boards_cleared_label: Label = $CanvasLayer/MarginContainer2/HBoxContainer/VBoxContainer3/BoardsCleared
onready var points_label: Label = $CanvasLayer/MarginContainer2/HBoxContainer/VBoxContainer4/Points

onready var timer := $PlayerController/Timer

export(int, 0, 1) var player_index: int = 0


func _ready() -> void:
	player_controller.player_index = player_index
	player_controller.rect_size = rect_size
	
	if not GameData.is_two_player_mode or GameData.is_left_side_player(player_index):
		$CanvasLayer/MarginContainer2/HBoxContainer/PlayerLabel.text = "P1"
	else:
		$CanvasLayer/MarginContainer2/HBoxContainer/PlayerLabel.text = "P2"
	
	if GameData.is_left_side_player(player_index):
		$CanvasLayer/MarginContainer2/VBoxContainer/HBoxContainer/GameControlsWasd.show()
	else:
		$CanvasLayer/MarginContainer2/VBoxContainer/HBoxContainer/GameControls.show()
	
	_on_PlayerController_score_updated(0, 0, 0)
	_on_PlayerController_level_increased(player_controller._level)
	
	_update_timer_label(timer.wait_time)
	
	$CanvasLayer/MarginContainer/ResultsMarginContainer.player_index = player_index
	
	$CanvasLayer/MarginContainer2/VBoxContainer/HBoxContainer/NextPrompt.hide()
	
	# Set size and global position because the nodes in the canvas layer do
	# not inherit that from the root container
	_set_container_rect_size($CanvasLayer/MarginContainer)
	_set_container_rect_size($CanvasLayer/MarginContainer2)
	
	set_process(false)
	
	$AnimationPlayer.play("ready")
	
	yield($AnimationPlayer, "animation_finished")
	
	player_controller.generate()
	
	player_controller.start()
	
	set_process(true)


func _process(_delta: float) -> void:
	_update_timer_label(timer.time_left)
	
	if Input.is_action_just_pressed("ui_select"):
		var _error = Loader.change_scene("res://TitleScreen.tscn")
		
		GameMusic.stop()
		
		set_process(false)


func _update_timer_label(time_left: float) -> void:
	var minutes = int(time_left / 60)
	var seconds = int(time_left) % 60
	
	# Time left: 59:59
	timer_label.text = "%02d:%02d" % [minutes, seconds]


func _set_container_rect_size(container: Control) -> void:
	container.rect_size = rect_size
	container.rect_global_position = rect_global_position


func _on_PlayerController_game_finished(points, boards_cleared, perfect_boards, level, lives) -> void:
	$AnimationPlayer.play("game over")
	
	$CanvasLayer/MarginContainer/ResultsMarginContainer.show_results(points, boards_cleared, perfect_boards, level, lives)


func _on_PlayerController_score_updated(points: int, boards_cleared: int, perfect_boards: int) -> void:
	points_label.text = str(points)
	
	boards_cleared_label.text = "%d | %d" % [boards_cleared, perfect_boards]


func _on_PlayerController_level_increased(level: int) -> void:
	level_label.text = "%d" % [level]
