extends Node2D


export var lives: int = 2

export var width: int = 3
export var height: int = 3

var player_index: int = 0

var coordinates: Vector2 = Vector2.ZERO
var target: Vector2 = Vector2(4, 4)

var traversed_cells: Array = []

var _score: int = 0
var _boards_cleared: int = 0
var _perfect_boards: int = 0

var _random := RandomNumberGenerator.new()

func _ready() -> void:
	var rect_width: float = get_parent().rect_size.x
	#width = 318
	
	var grid_width: float = 48 * 5
	
	position = Vector2((rect_width - grid_width) / 2, position.y)
	# TODO: Adjust y position


func _process(_delta: float) -> void:
	#$TimerLabel.text = str($Timer.time_left)
	#$PosessionTimerLabel.text = str($PosessionTimer.time_left)
	
	var next_coordinates = coordinates
	
	if Input.is_action_just_pressed("ui_up_%d" % player_index):
		next_coordinates.y -= 1
	elif Input.is_action_just_pressed("ui_down_%d" % player_index):
		next_coordinates.y += 1
	elif Input.is_action_just_pressed("ui_left_%d" % player_index):
		next_coordinates.x -= 1
	elif Input.is_action_just_pressed("ui_right_%d" % player_index):
		next_coordinates.x += 1
	
	if !coordinates.is_equal_approx(next_coordinates) and $Grid._is_in_range(next_coordinates, width, height):
		var cell = $Grid.get_cell_from_coordinates(next_coordinates)
		
		if not cell in traversed_cells:
			var direction_vector: Vector2 = next_coordinates - coordinates
			
			var direction: int = Cell.DIRECTION.RIGHT
			
			if direction_vector.is_equal_approx(Vector2.UP):
				direction = Cell.DIRECTION.UP
			elif direction_vector.is_equal_approx(Vector2.DOWN):
				direction = Cell.DIRECTION.DOWN
			elif direction_vector.is_equal_approx(Vector2.LEFT):
				direction = Cell.DIRECTION.LEFT
			
			traversed_cells.back().show_arrow(direction)
			
			coordinates = next_coordinates
			traversed_cells.push_back(cell)
			
			update_player_position()
			
			cell.possess()
		elif traversed_cells.size() > 1 and cell == traversed_cells[traversed_cells.size() - 2]:
			traversed_cells.back().release()
			traversed_cells.pop_back()
			
			coordinates = next_coordinates
			
			update_player_position()
			
			traversed_cells.back().possess_again()
		else:
			$NoMovementAudioStreamPlayer.play()
	
	if coordinates.is_equal_approx(target):
		print("you win!")
		
		$PosessionTimer.stop()
		
		# TODO: Emit signal
		_boards_cleared += 1
		
		$Grid.compare_paths(traversed_cells, target)
		
		set_process(false)


func generate() -> void:
	$Grid.generate(width, height)


func start() -> void:
	$Timer.start()
	
	_create_new_board()


func _create_new_board() -> void:
	set_process(false)
	
	$PosessionTimer.stop()
	
	$Grid.hide()
	
	if _boards_cleared > 0 and _boards_cleared % 1 == 0:
		if width < 8:
			width += 1
		
		if height < 6:
			height += 1
		
		generate()
		
		# TODO: Reposition grid
	
	_choose_random_target()
	
	$Grid.randomize_board(coordinates, target)
	$Grid.drop_down_cells()
	
	yield($Grid, "cells_dropped")
	
	$Grid.show_target()
	
	traversed_cells.clear()
	traversed_cells.push_back($Grid.get_cell_from_coordinates(coordinates))
	
	update_player_position()
	traversed_cells.back().possess()
	
	$PosessionTimer.start()
	
	set_process(true)


func _choose_random_target() -> void:
	var corners_1 := [Vector2(0, 0), Vector2(width - 1, height - 1)]
	var corners_2 := [Vector2(0, height - 1), Vector2(width - 1, 0)]
	
	var chosen_corners: Array
	
	if _random.randf() < 0.5:
		chosen_corners = corners_1
	else:
		chosen_corners = corners_2
	
	chosen_corners.shuffle()
	
	coordinates = chosen_corners.front()
	target = chosen_corners.back()


func update_player_position() -> void:
	$Tween.remove($Player, "global_position")
	
	$Tween.interpolate_property($Player, "global_position",
		$Player.global_position, traversed_cells.back().global_position,
		0.125)
	
	$Tween.start()


func _finish_game() -> void:
	set_process(false)
	
	$PosessionTimer.stop()
	
	print("Game over!")


func _on_Timer_timeout() -> void:
	_finish_game()


func _on_PosessionTimer_timeout() -> void:
	print("Possession timeout!")
	
	lives -= 1
	
	if lives > 0:
		_create_new_board()
	else:
		print("You lose!")
		
		_finish_game()


func _on_Grid_score_shown() -> void:
	_create_new_board()
