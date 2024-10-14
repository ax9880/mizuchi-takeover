extends Node2D

enum State {
	ACTIVE,
	SHOWING_PATHS
}

export var lives: int = 2

export var width: int = 3
export var height: int = 3

export(NodePath) var next_prompt_node_path: NodePath

var player_index: int = 0

var coordinates: Vector2 = Vector2.ZERO
var target: Vector2 = Vector2(4, 4)

var traversed_cells: Array = []

var rect_size: Vector2

var _points: int = 0
var _boards_cleared: int = 0
var _perfect_boards: int = 0
var _level: int = 1

var _is_game_over: bool = false

var _random := RandomNumberGenerator.new()

var _state: int = State.ACTIVE

onready var next_prompt: Control = get_node(next_prompt_node_path)

signal game_finished(points, boards_cleared, perfect_boards, level, lives)
signal score_updated(points, boards_cleared)


func _ready() -> void:
	_random.randomize()
	
	$Timer.wait_time = GameData.time_seconds
	width = GameData.starting_size
	height = GameData.starting_size
	
	set_process(false)


func _process(_delta: float) -> void:
	match(_state):
		State.ACTIVE:
			_move_player()
		State.SHOWING_PATHS:
			if Input.is_action_just_pressed("ui_down_%d" % player_index):
				$Grid.drop_cells()
				
				next_prompt.stop()
				
				set_process(false)


func _move_player() -> void:
	var next_coordinates: Vector2 = coordinates
	
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
		print("You win!")
		
		$Grid.hide_target()
		
		$PosessionTimer.stop()
		
		_boards_cleared += 1
		
		$Grid.compare_paths(traversed_cells, target)
		
		set_process(false)


func generate() -> void:
	$Grid.generate(width, height)
	
	var grid_width: float = $Grid.tilesize * width
	var grid_height: float = $Grid.tilesize * height
	
	$Grid.position = Vector2(rect_size.x - grid_width, rect_size.y - grid_height) / 2.0


func start() -> void:
	$Timer.start()
	
	_create_new_board()


func _create_new_board() -> void:
	set_process(false)
	
	$PosessionTimer.stop()
	
	$Grid.hide()
	
	if GameData.can_grow_size and _boards_cleared > 0 and _boards_cleared % 1 == 0:
		if width < 8:
			width += 1
		
		if height < 6:
			height += 1
		
		_level += 1
		
		generate()
	
	_choose_random_target()
	
	$Grid.randomize_board(coordinates, target)
	$Grid.drop_down_cells()
	
	yield($Grid, "cells_dropped")
	
	if _is_game_over:
		return
	
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
	
	_is_game_over = true
	
	$PosessionTimer.stop()
	
	print("Game over!")
	
	emit_signal("game_finished", _points, _boards_cleared, _perfect_boards, _level, lives)


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


func _on_Grid_score_calculated(points: int, is_perfect_board: bool) -> void:
	_points += points
	
	if is_perfect_board:
		_perfect_boards += 1
	
	emit_signal("score_updated", _points, _boards_cleared)
	
	_state = State.SHOWING_PATHS
	next_prompt.start(player_index)
	
	set_process(true)


func _on_Grid_cells_dropped() -> void:
	if not _is_game_over:
		_state = State.ACTIVE
		
		set_process(true)
