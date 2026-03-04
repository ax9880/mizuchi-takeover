extends Node2D

const _SPRITE_PREFFIX: String = "Charas_"
const _SPRITE_EXTENSION: String = ".png.import"

enum PathMode {
	RANDOM,
	ASCENDING,
	DESCENDING
}

class MyAStar:
	extends AStar
	
	const ILLEGAL_MOVE_COST_PENALTY: float = 100.0
	
	var cells: Array = []
	var values: Array = []
	
	# Flag used when finding the best path after the player has completed a
	# board.
	var is_pathfinding_mode: bool = false
	
	# Flag used to penalize illegal moves so that this class always finds the
	# best legal path when comparing paths. A legal move is a move between
	# characters of the same game or adjacent games.
	var can_penalize_illegal_moves: bool = false
	
	func _compute_cost(from_id: int, to_id: int) -> float:
		var to_cell: Cell = cells[to_id]
		
		if to_cell.has_cost_one:
			return 1.0
		elif is_pathfinding_mode:
			# When pathfinding, the cost to go from one cell to another
			# is the distance between games or indexes. This way, the cost to
			# go from 12.8 to 13 (1 game difference) is the same as the cost
			# from 12.8 to 12.5 (1 game difference), because they are adjacent games
			var from_index: int = values.find(cells[from_id].value)
			var to_index: int = values.find(cells[to_id].value)
			
			assert(from_index != -1)
			assert(to_index != -1)
			
			var difference: float = abs(from_index - to_index)
			
			if can_penalize_illegal_moves and difference > 1.0:
				return difference * ILLEGAL_MOVE_COST_PENALTY
			else:
				return difference
		else:
			# When generating a random path, the cost is the 
			# difference between the cells' randomly assigned values
			return abs(cells[from_id].value - cells[to_id].value)
	
	
	func _estimate_cost(from_id: int, to_id: int) -> float:
		return _compute_cost(from_id, to_id)


# Array[Array[Cell]]
var grid: Array = []
var astar: MyAStar = MyAStar.new()

var start_id: int = 0
var target_id: int = 0

var _randomized_id_path: Array = []

# Dictionary[float, string (character texture path)]
var bags: Dictionary = {}

var textures: Array = []

# Array[float]
var values: Array = []

var _cell_pool: Array = []

var rng := RandomNumberGenerator.new()

var base_score: int = 0

export(PackedScene) var floating_label_packed_scene: PackedScene

export(PackedScene) var cell_packed_scene: PackedScene = null

export var tilesize: float = 48.0
export var tile_offset: float = 0.0

onready var half_tilesize: float = tilesize / 2.0


signal cell_pressed(cell, is_dragged)
signal cells_dropped
signal score_calculated(points, is_perfect_board)
signal score_shown


func _ready() -> void:
	rng.randomize()
	
	_read_characters("res://Split")


func generate(width: int, height: int) -> void:
	rng.randomize()
	
	grid.clear()
	astar.clear()
	
	for cell in astar.cells:
		remove_child(cell)
		
		cell.clear()
		
		assert(not cell in _cell_pool)
		
		_cell_pool.push_back(cell)
	
	astar.cells.clear()
	
	start_id = 0
	target_id = 0
	
	base_score = width * height * 1000
	
	var id := 0
	
	for x in width:
		grid.append([])
		grid[x].resize(height)
		
		for y in height:
			var cell: Cell = _build_cell(x, y)
			grid[x][y] = cell
			
			cell.id = id
			astar.add_point(cell.id, Vector3(cell.position.x, cell.position.y, 0))
			
			id += 1
	
	# Populate cell neighbors
	for x in range(width):
		for y in range(height):
			var cell: Cell = grid[x][y]
			
			_set_neighbors(cell, width, height)
	
	astar.cells.clear()
	
	for row in grid:
		astar.cells.append_array(row)
	
	for cell in astar.cells:
		for neighbor in cell.neighbors:
			astar.connect_points(cell.id, neighbor.id, false)


func randomize_board(start_coordinates: Vector2, target_coordinates: Vector2, is_left_side_player: bool) -> bool:
	astar.is_pathfinding_mode = false
	
	for cell in astar.cells:
		cell.value = rng.randi_range(0, 1)
		cell.has_cost_one = false
	
	start_id = get_cell_from_coordinates(start_coordinates).id
	target_id = get_cell_from_coordinates(target_coordinates).id
	
	var shortest_id_path: Array = astar.get_id_path(start_id, target_id)
	
	var shuffled_bags: Dictionary = bags.duplicate(true)
	
	values = shuffled_bags.keys()
	
	if rng.randf() < 0.7:
		# Remove values with decimals
		_remove_decimals(values, shuffled_bags)
		
		values = shuffled_bags.keys()
	
	values.sort()
	
	# Use the values after removing (or keeping) the decimal games so that
	# this object can calculate the correct cost
	astar.values = values.duplicate()
	
	for characters in shuffled_bags.values():
		characters.shuffle()
	
	var start_value_index: int = rng.randi_range(0, values.size() - 1)
	var current_value: float = values[start_value_index]
	
	var path_mode: int = PathMode.RANDOM
	
	var path_mode_chance: float = rng.randf()
	
	if path_mode_chance < 0.2:
		path_mode = PathMode.DESCENDING
	elif path_mode_chance < 0.4:
		path_mode = PathMode.ASCENDING
	
	for cell_id in shortest_id_path:
		var cell: Cell = astar.cells[cell_id]
		
		cell.value = current_value
		var characters: Array = shuffled_bags[current_value]
		
		cell.set_texture(characters.pop_back())
		
		if characters.empty():
			var index: int = values.find(current_value)
			
			if index == 0:
				# Get upper range
				values = values.slice(index + 1, values.size() - 1)
				
				start_value_index = 0
			elif index == values.size() - 1:
				# Get lower range
				values = values.slice(0, index - 1)
				
				start_value_index = values.size() - 1
			else:
				if path_mode == PathMode.RANDOM:
					# Randomly pick the range that you want to keep
					if rng.randf() < 0.5:
						# Get lower range
						values = values.slice(0, index - 1)
						
						start_value_index = values.size() - 1
					else:
						# Get upper range
						values = values.slice(index + 1, values.size() - 1)
						
						start_value_index = 0
				elif path_mode == PathMode.DESCENDING:
					values = values.slice(0, index - 1)
					
					start_value_index = values.size() - 1
				else:
					values = values.slice(index + 1, values.size() - 1)
					
					start_value_index = 0
			
			var _is_erased := shuffled_bags.erase(current_value)
			
			# Ran out of characters and didn't reach the goal. Return
			if values.empty() and cell_id != shortest_id_path.back():
				return false
		else:
			# No adjustment needed, pick next index according to path mode
			var next_index: int = 0
		
			if path_mode == PathMode.RANDOM:
				next_index = start_value_index + rng.randi_range(-1, 1)
			elif path_mode == PathMode.DESCENDING:
				next_index = start_value_index - 1
				
				# If you reach the limit, set the path mode to random
				if next_index < 0:
					path_mode = PathMode.RANDOM
			else:
				next_index = start_value_index + 1
				
				if next_index >= values.size():
					path_mode = PathMode.RANDOM
			
			start_value_index = int(clamp(next_index, 0, values.size() - 1))
		
		if cell_id != shortest_id_path.back():
			assert(values.size() > 0)
			assert(start_value_index >= 0)
			
			current_value = values[start_value_index]
	
	# Assign the values again to fill the grid with random characters
	# from the remaining games
	values = shuffled_bags.keys()
	values.sort()
	
	# Slice to ignore the last ID, which doesn't count because
	# it is going to have cost one after the target is set
	if not _path_has_decimals(shortest_id_path.slice(0, shortest_id_path.size() - 2)):
		# If the path doesn't have decimals remove them from the bags to avoid
		# generating a board with 'hidden decimals', meaning that a move from
		# 7 to 8 becomes illegal because the sequence is 7 -> 7.5, but the board
		# didn't add any character from 7.5.
		_remove_decimals(values, shuffled_bags)
		
		values = shuffled_bags.keys()
	
	_fill_cells_with_random_characters(shortest_id_path, shuffled_bags)
	
	set_target(is_left_side_player)
	
	_randomized_id_path = shortest_id_path
	
	assert(_is_path_legal(_randomized_id_path))
	
	return true


func _remove_decimals(_values: Array, _bags: Dictionary) -> void:
	for value in _values:
		if not is_equal_approx(value, floor(value)):
			var is_erased := _bags.erase(value)
			
			assert(is_erased)


func _path_has_decimals(shortest_id_path: Array) -> bool:
	for id in shortest_id_path:
		var cell: Cell = astar.cells[id]
		
		if cell.has_cost_one:
			continue
		
		var value: float = cell.value
		
		if not is_equal_approx(value, floor(value)):
			return true 
	
	return false


func _fill_cells_with_random_characters(shortest_id_path: Array, shuffled_bags: Dictionary) -> void:
	for cell in astar.cells:
		if not cell.id in shortest_id_path:
			var index: int = rng.randi_range(0, values.size() - 1)
			var value: float = values[index]
			
			var characters: Array = shuffled_bags[value]
			
			cell.value = value
			cell.set_texture(characters.pop_back())
			
			if characters.empty():
				values.remove(index)
				
				var _is_erased := shuffled_bags.erase(value)


func _read_characters(path: String) -> void:
	var directory = Directory.new()
	
	if directory.open(path) != OK:
		printerr("An error occurred when trying to access the path %s" % path)
		
		return
	
	directory.list_dir_begin()
	
	var file_name: String = directory.get_next()
	
	while not file_name.empty():
		if file_name.begins_with("."):
			file_name = directory.get_next()
			
			continue
		
		if directory.current_is_dir():
			var value: float = file_name.replace("Touhou", "").to_float()
			
			bags[value] = []
			values.push_back(value)
			
			var character_directory = Directory.new()
			character_directory.open(directory.get_current_dir() + "/" + file_name)
			
			character_directory.list_dir_begin()
			
			var character: String = character_directory.get_next()
			
			while not character.empty():
				if character.ends_with(_SPRITE_EXTENSION):
					var resource_path: String = directory.get_current_dir() + "/" + file_name + "/" + character.trim_suffix(".import")
					
					textures.push_back(ResourceLoader.load(resource_path))
					
					bags[value].push_back(resource_path)
					
				character = character_directory.get_next()
				
			character_directory.list_dir_end()
		
		file_name = directory.get_next()
	
	directory.list_dir_end()
	
	values.sort()


# Extracts an index from a path in the form "path/Charas_***.png
func _extract_index(path: String) -> int:
	var prefix_start: int = path.find(_SPRITE_PREFFIX)
	
	assert(prefix_start != -1)
	
	var extension_start: int = path.find(_SPRITE_EXTENSION)
	
	assert(extension_start != -1)
	
	var index_start: int = prefix_start + _SPRITE_PREFFIX.length()
	
	# -1 because indexes in the filenames start from 1
	return path.substr(index_start, extension_start - index_start).to_int() - 1


func compare_paths(path: Array, target_coordinates: Vector2) -> void:
	var start_cell: Cell = path.front()
	var target_cell: Cell = get_cell_from_coordinates(target_coordinates)
	
	astar.is_pathfinding_mode = true
	astar.can_penalize_illegal_moves = true
	
	var shortest_id_path: Array = astar.get_id_path(start_cell.id, target_cell.id)
	
	if not _is_path_legal(shortest_id_path):
		print("Shortest path is not legal, using generated path")
		
		shortest_id_path = _randomized_id_path
		
		assert(_is_path_legal(_randomized_id_path))
	
	astar.can_penalize_illegal_moves = false
	var lowest_cost: float = calculate_path_cost(shortest_id_path)
	
	var id_path: Array = []
	
	for cell in path:
		id_path.push_back(astar.get_closest_point(Vector3(cell.position.x, cell.position.y, 0)))
	
	var is_current_path_legal: bool = _is_path_legal(id_path)
	var current_cost: float = calculate_path_cost(id_path)
	
	print("Lowest: %s, current: %s" % [lowest_cost, current_cost])
	
	var points: int = 0
	
	if is_current_path_legal and current_cost <= lowest_cost:
		points = base_score
	else:
		if current_cost <= lowest_cost:
			# In case the player found an illegal path with a lower cost
			current_cost = lowest_cost + 1
		
		points = int(base_score / (current_cost + 1 - lowest_cost))
	
	print("Points: %d" % [points])
	
	if is_current_path_legal and is_equal_approx(current_cost, lowest_cost):
		# In case there are two paths with lowest cost, use the one
		# that the player used
		shortest_id_path = id_path
	
	_show_paths(shortest_id_path, id_path, points)


func _is_path_legal(id_path: Array) -> bool:
	var _values: Array = astar.values
	
	for i in id_path.size() - 1:
		var current_cell: Cell = astar.cells[id_path[i]]
		var next_cell: Cell = astar.cells[id_path[i + 1]]
		
		if current_cell.has_cost_one or next_cell.has_cost_one:
			continue
		
		var current_index: int = _values.find(current_cell.value)
		var next_cell_index: int = _values.find(next_cell.value)
		
		if current_index == -1 || next_cell_index == -1:
			return false
		
		# If characters are not in the same or in adjacent games
		if abs(current_index - next_cell_index) > 1:
			printerr("Path is not legal because it jumps from %s to %s" % [_values[current_index], _values[next_cell_index]])
			
			return false
	
	return true


func _show_paths(shortest_id_path: Array, current_id_path: Array, points: int) -> void:
	for i in current_id_path.size():
		var id: int = current_id_path[i]
		
		var is_in_shortest_path: bool = id in shortest_id_path
		
		if is_in_shortest_path:
			$PathAudioStreamPlayer.play()
		else:
			$WrongPathAudioStreamPlayer.play()
		
		var cell: Cell = astar.cells[current_id_path[i]]
		cell.show_value(is_in_shortest_path, false)
		
		$PathResultsTimer.start()
		
		yield($PathResultsTimer, "timeout")
	
	if shortest_id_path != current_id_path:
		for id in shortest_id_path:
			var cell: Cell = astar.cells[id]
			
			cell.show_value(true, true)
	
	var floating_label: Node2D = floating_label_packed_scene.instance()
	
	add_child(floating_label)
	
	var cell: Cell = astar.cells[shortest_id_path.back()]
	floating_label.position = cell.position
	
	var is_perfect_board: bool = false
	
	if points == base_score:
		$GoodScoreAudioStreamPlayer.play()
		
		is_perfect_board = true
	elif points >= int(base_score * 0.10):
		$BadScoreAudioStreamPlayer2.play()
	else:
		$BadScoreAudioStreamPlayer2.play()
		
		print("Very bad score")
	
	# TODO: If score is less than 10% of base score, play wrong score and lose one life
	# Also set score to 0
	
	floating_label.start(points)
	
	emit_signal("score_calculated", points, is_perfect_board)


func calculate_path_cost(id_path: Array) -> float:
	var cost: float = 0
	
	for i in id_path.size() - 1:
		cost += astar._compute_cost(id_path[i], id_path[i + 1])
	
	return cost


func drop_down_cells() -> void:
	$Target.hide()
	
	for cell in astar.cells:
		cell.reset()
		
		cell.position =  cell_coordinates_to_cell_origin(cell.coordinates)
		
		var y_start: float = cell.position.y - max(grid.front().size() * tilesize + tilesize, 1280)
		
		$Tween.interpolate_property(cell, "position", Vector2(cell.position.x, y_start), cell.position, 0.75, Tween.TRANS_SINE, Tween.EASE_IN)
		
		$Tween.start()
		
		yield(get_tree(), "physics_frame")
	
	show()
	
	$AudioStreamPlayer.play()
	
	yield($Tween, "tween_all_completed")
	
	for cell in astar.cells:
		cell.enable_selection()
	
	emit_signal("cells_dropped")


func drop_cells() -> void:
	$Target.hide()
	
	$DropCellsAudioStreamPlayer.play()
	
	for cell in astar.cells:
		$Tween.interpolate_property(cell, "position", cell.position, Vector2(cell.position.x, cell.position.y + 1080), 0.75, Tween.TRANS_SINE, Tween.EASE_IN)
		
		$Tween.start()
		
		yield(get_tree(), "physics_frame")
	
	yield($Tween, "tween_all_completed")
	
	emit_signal("score_shown")


func set_target(is_left_side_player: bool) -> void:
	var cell: Cell = astar.cells[target_id]
	
	if is_left_side_player:
		cell.set_texture("res://Split/Charas_8_4b.png")
	else:
		cell.set_texture("res://Split/Charas_8_4a.png")
	
	cell.has_cost_one = true


func show_target() -> void:
	var cell: Cell = astar.cells[target_id]
	
	$Target.position = cell.position
	
	$Target.position.x -= 90
	$Target.position.y -= 85
	
	$Target.show()


func hide_target() -> void:
	$Target.hide()


func disable_cell_selection() -> void:
	for cell in astar.cells:
		cell.disable_selection()


func _build_cell(x_position: float, y_position: float) -> Cell:
	if _cell_pool.empty():
		var cell: Cell = cell_packed_scene.instance()
		var _error = cell.connect("pressed", self, "_on_Cell_pressed", [cell])
		
		_cell_pool.push_back(cell)
	
	var cell: Cell = _cell_pool.pop_front()
	
	assert(not cell.is_inside_tree())
	
	add_child(cell)
	
	var cell_coordinates := Vector2(x_position, y_position)
	cell.position = cell_coordinates_to_cell_origin(cell_coordinates)
	cell.coordinates = cell_coordinates
	
	return cell


func _set_neighbors(node: Cell, width, height) -> void:
	var cell_coordinates: Vector2 = node.coordinates
	
	_set_neighbor(node, Vector2(cell_coordinates.x, cell_coordinates.y - 1), width, height)
	_set_neighbor(node, Vector2(cell_coordinates.x, cell_coordinates.y + 1), width, height)
	_set_neighbor(node, Vector2(cell_coordinates.x + 1, cell_coordinates.y), width, height)
	_set_neighbor(node, Vector2(cell_coordinates.x - 1, cell_coordinates.y), width, height)


func _set_neighbor(cell: Cell, neighbor_coordinates: Vector2, width: int, height: int) -> void:
	var neighbor: Cell = null
	
	if _is_in_range(neighbor_coordinates, width, height):
		neighbor = get_cell_from_coordinates(neighbor_coordinates)
	
	cell.add_neighbor(neighbor)


func _is_in_range(cell_coordinates: Vector2, width, height) -> bool:
	if cell_coordinates.x < 0 or cell_coordinates.x >= width:
		return false
	elif cell_coordinates.y < 0 or cell_coordinates.y >= height:
		return false
	else:
		return true


func _on_Cell_pressed(is_dragged: bool, cell: Cell) -> void:
	emit_signal("cell_pressed", cell, is_dragged)


# Returns the x, y coordinates of a cell (whole numbers)
func get_cell_coordinates(unit_position: Vector2) -> Vector2:
	return Vector2(floor(unit_position.x / tilesize), floor(unit_position.y / tilesize))


func get_cell_from_position(unit_position: Vector2) -> Cell:
	var cell_coordinates := get_cell_coordinates(unit_position)
	
	return get_cell_from_coordinates(cell_coordinates)


func get_cell_from_coordinates(cell_coordinates: Vector2) -> Cell:
	return grid[cell_coordinates.x][cell_coordinates.y]


func cell_coordinates_to_cell_origin(cell_coordinates: Vector2) -> Vector2:
	return Vector2(cell_coordinates.x * tilesize + half_tilesize, cell_coordinates.y * tilesize + + half_tilesize + tile_offset)
