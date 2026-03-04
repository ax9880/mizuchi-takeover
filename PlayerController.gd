extends Node2D

enum State {
	ACTIVE,
	SHOWING_PATHS,
	LOADING_NEXT_BOARD
}

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

var _can_advance_level: bool = false

var _is_game_over: bool = false

var _random := RandomNumberGenerator.new()

var _state: int = State.ACTIVE

var _last_pressed_cell: Cell

onready var next_prompt: Control = get_node(next_prompt_node_path)

signal game_finished(points, boards_cleared, perfect_boards, level)
signal score_updated(points, boards_cleared, perfect_boards)
signal level_increased(level)


func _ready() -> void:
	_random.randomize()
	
	$Timer.wait_time = GameData.time_seconds
	width = GameData.starting_size
	height = GameData.starting_size
	
	_level = GameData.starting_size - 2
	
	# Generates the grid to pool the cells before the player sees anything
	generate()
	
	$Grid.hide()
	
	set_process(false)


func _process(_delta: float) -> void:
	match(_state):
		State.ACTIVE:
			_move_player()
		State.SHOWING_PATHS:
			if Input.is_action_just_pressed("ui_down_%d" % player_index):
				_drop_cells()


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
		
		_update_cell(next_coordinates, cell)
	
	_check_win_condition()


func _update_cell(next_coordinates: Vector2, cell: Cell, is_dragged: bool = false) -> void:
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
		_play_no_movement_audio(cell, is_dragged)


func _check_win_condition() -> void:
	if coordinates.is_equal_approx(target):
		print("You win!")
		
		_state = State.SHOWING_PATHS
		
		$Grid.hide_target()
		$Grid.disable_cell_selection()
		
		_boards_cleared += 1
		
		$Grid.compare_paths(traversed_cells, target)
		
		set_process(false)


func _play_no_movement_audio(cell: Cell, is_dragged: bool) -> void:
	if is_dragged:
		if _last_pressed_cell != cell and not $NoMovementAudioStreamPlayer.playing:
			$NoMovementAudioStreamPlayer.play()
	else:
		$NoMovementAudioStreamPlayer.play()


func _drop_cells() -> void:
	if _state == State.LOADING_NEXT_BOARD:
		return
	
	_state = State.LOADING_NEXT_BOARD
	
	$Grid.drop_cells()
	
	next_prompt.stop()
	$NextArea2D.hide()
	
	set_process(false)


func generate() -> void:
	$Grid.generate(width, height)
	
	var grid_width: float = $Grid.tilesize * width
	var grid_height: float = $Grid.tilesize * height
	
	$Grid.position = Vector2(rect_size.x - grid_width, rect_size.y - grid_height) / 2.0
	
	# Place in the middle container
	$NextArea2D.position = Vector2(rect_size.x, rect_size.y) / 2.0
	var shape = $NextArea2D/CollisionShape2D.shape as RectangleShape2D
	
	# Make it as big as the board
	shape.extents = Vector2(grid_width, grid_height) / 2.0
	
	$NextArea2D.hide()


func start() -> void:
	$Timer.start()
	
	_create_new_board()


func _create_new_board() -> void:
	set_process(false)
	
	$Grid.hide()
	
	_advance_level()
	
	_choose_random_target()
	
	while true:
		if $Grid.randomize_board(coordinates, target, GameData.is_left_side_player(player_index)):
			break
		else:
			printerr("Failed to generate suitable path, trying again")
	
	print("Board randomized")
	
	$Grid.drop_down_cells()
	
	yield($Grid, "cells_dropped")
	
	if _is_game_over:
		return
	
	$Grid.show_target()
	
	traversed_cells.clear()
	traversed_cells.push_back($Grid.get_cell_from_coordinates(coordinates))
	
	update_player_position()
	traversed_cells.back().possess()
	
	set_process(true)


func _advance_level() -> void:
	if not GameData.can_grow_size:
		return
	
	if GameData.is_two_player_mode and (width == 6 or height == 6):
		return
	
	if not _can_advance_level:
		return
	
	if _perfect_boards == 0:
		return
	
	if _perfect_boards % 5 != 0:
		return
	
	if width < 8:
		width += 1
	
	if height < 6:
		height += 1
	
	_level += 1
	emit_signal("level_increased", _level)
	
	_can_advance_level = false
	
	generate()


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
	
	emit_signal("game_finished", _points, _boards_cleared, _perfect_boards, _level)


func _on_Timer_timeout() -> void:
	_finish_game()


func _on_Grid_score_shown() -> void:
	_create_new_board()


func _on_Grid_score_calculated(points: int, is_perfect_board: bool) -> void:
	_points += points
	
	if is_perfect_board:
		_perfect_boards += 1
		
		_can_advance_level = true
	
	emit_signal("score_updated", _points, _boards_cleared, _perfect_boards)
	
	next_prompt.start(player_index)
	
	$NextArea2D.show()
	
	set_process(true)


func _on_Grid_cell_pressed(cell: Cell, is_dragged: bool) -> void:
	if _state != State.ACTIVE:
		return
	
	var current_cell = $Grid.get_cell_from_coordinates(coordinates)
	
	if cell == current_cell:
		if not is_dragged:
			var last_cell: Cell = traversed_cells[traversed_cells.size() - 1]
			
			# Click on the last cell to release it
			if traversed_cells.size() > 1 and cell == last_cell:
				var second_to_last_cell: Cell = traversed_cells[traversed_cells.size() - 2]
				
				_update_cell(second_to_last_cell.coordinates, second_to_last_cell, is_dragged)
		
		return
	
	if not cell in current_cell.neighbors:
		_play_no_movement_audio(cell, is_dragged)
		
		_last_pressed_cell = cell
		
		return
	
	_update_cell(cell.coordinates, cell, is_dragged)
	
	_check_win_condition()
	
	_last_pressed_cell = cell


func _on_Grid_cells_dropped() -> void:
	if not _is_game_over:
		_state = State.ACTIVE
		
		set_process(true)



func _on_NextArea2D_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed:
		_drop_cells()
