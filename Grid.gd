extends Node2D


const _SPRITE_PREFFIX: String = "Charas_"
const _SPRITE_EXTENSION: String = ".png"

enum PathMode {
	RANDOM,
	ASCENDING,
	DESCENDING
}


class MyAStar:
	extends AStar
	
	var cells: Array = []
	
	func _compute_cost(from_id: int, to_id: int) -> float:
		var to_cell: Cell = cells[to_id]
		
		if to_cell.has_cost_one:
			return 1.0
		else:
			return abs(cells[from_id].value - to_cell.value)
	
	
	func _estimate_cost(from_id: int, to_id: int) -> float:
		return _compute_cost(from_id, to_id)


# Array[Array[Cell]]
var grid: Array = []
var astar: MyAStar = MyAStar.new()

var start_id: int = 0
var target_id: int = 0

# Dictionary[float, int (index of character)]
var bags: Dictionary = {}

# Array[float]
var values: Array = []

var rng := RandomNumberGenerator.new()

var base_score: int = 0

export(PackedScene) var floating_label_packed_scene: PackedScene

export(PackedScene) var cell_packed_scene: PackedScene = null

export var tilesize: float = 48.0
export var tile_offset: float = 0.0

onready var half_tilesize: float = tilesize / 2.0


signal cells_dropped
signal score_calculated
signal score_shown


func _ready() -> void:
	rng.randomize()


func generate(width: int, height: int) -> void:
	for cell in astar.cells:
		astar.remove_point(cell.id)
		
		cell.queue_free()
	
	grid.clear()
	astar.cells.clear()
	bags.clear()
	values.clear()
	
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
	
	_read_characters("res://Split")


func randomize_board(start_coordinates: Vector2, target_coordinates: Vector2) -> void:
	for cell in astar.cells:
		cell.value = rng.randi_range(0, 1)
	
	start_id = get_cell_from_coordinates(start_coordinates).id
	target_id = get_cell_from_coordinates(target_coordinates).id
	
	var shortest_id_path: Array = astar.get_id_path(start_id, target_id)
	
	var shuffled_bags: Dictionary = bags.duplicate(true)
	
	values = shuffled_bags.keys()
	
	if rng.randf() < 0.7:
		# Remove values with decimals
		for value in values:
			if not is_equal_approx(value, floor(value)):
				shuffled_bags.erase(value)
		
		values = shuffled_bags.keys()
	
	values.sort()
	
	for characters in shuffled_bags.values():
		characters.shuffle()
	
	var start_value_index: int = rng.randi_range(0, values.size() - 1)
	var current_value: float = values[start_value_index]
	var previous_value: float = current_value
	
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
		
		cell.set_frame(characters.pop_back())
		
		if characters.empty():
			if is_equal_approx(current_value, floor(current_value)):
				var index: int = values.find(current_value)
				
				if previous_value < current_value:
					# Lower range
					values = values.slice(0, index - 1)
					
					start_value_index = values.size() - 1
					
				elif previous_value > current_value:
					# Upper range
					values = values.slice(index + 1, values.size() - 1)
					
					start_value_index = 0
				else:
					var distance_to_end: int = values.size() - index
					
					if distance_to_end > index:
						# Upper range
						values = values.slice(index + 1, values.size() - 1)
						
						start_value_index = 0
					else:
						# Lower range
						values = values.slice(0, index - 1)
						
						start_value_index = values.size() - 1
				
				shuffled_bags.erase(current_value)
				
				assert(values.size() > 0)
			else:
				# Is .5 or .8
				var index: int = values.find(current_value)
				
				if rng.randf() < 0.5:
					start_value_index -= 1
				else:
					start_value_index += 1
				
				var next_value: float = values[start_value_index]
				
				values.remove(index)
				shuffled_bags.erase(current_value)
				
				start_value_index = values.find(next_value)
				
				assert(values.size() > 0)
			
			current_value = previous_value
		else:
			# No adjustment needed, pick next index according to path mode
			var next_index: int = 0
		
			if path_mode == PathMode.RANDOM:
				next_index = start_value_index + rng.randi_range(-1, 1)
			elif path_mode == PathMode.DESCENDING:
				next_index = start_value_index - 1
				
				if next_index < 0:
					path_mode = PathMode.RANDOM
			else:
				next_index = start_value_index + 1
				
				if next_index >= values.size():
					path_mode = PathMode.RANDOM
			
			start_value_index = int(clamp(next_index, 0, values.size() - 1))
		
		assert(values.size() > 0)
		
		assert(start_value_index >= 0)
		
		previous_value = current_value
		current_value = values[start_value_index]
	
	values = shuffled_bags.keys()
	values.sort()
	
	for cell in astar.cells:
		if not cell.id in shortest_id_path:
			var index: int = rng.randi_range(0, values.size() - 1)
			var value: float = values[index]
			
			var characters: Array = shuffled_bags[value]
			
			cell.value = value
			cell.set_frame(characters.pop_back())
			
			if characters.empty():
				values.remove(index)
				shuffled_bags.erase(value)
	
	set_target()


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
					bags[value].push_back(_extract_index(character))
					
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
	
	var shortest_id_path: Array = astar.get_id_path(start_cell.id, target_cell.id)
	var lowest_cost: float = calculate_path_cost(shortest_id_path)
	
	var id_path: Array = []
	
	for cell in path:
		id_path.push_back(astar.get_closest_point(Vector3(cell.position.x, cell.position.y, 0)))
	
	var current_cost: float = calculate_path_cost(id_path)
	
	print("Lowest: %s, current: %s" % [lowest_cost, current_cost])
	
	var score: int = 0
	
	if current_cost <= lowest_cost:
		score = base_score
	else:
		score = int(base_score / (current_cost + 1 - lowest_cost))
	
	print("Score: %d" % [score])
	
	if is_equal_approx(current_cost, lowest_cost):
		# In case there are two paths with lowest cost, use the one
		# that the player used
		shortest_id_path = id_path
	
	show_paths(shortest_id_path, id_path, lowest_cost, score)


func show_paths(shortest_id_path: Array, current_id_path: Array, lowest_cost: float, score: int) -> void:
	var current_cost: float = 0
	
	for i in current_id_path.size() - 1:
		var id: int = current_id_path[i]
		
		current_cost += astar._compute_cost(id, current_id_path[i + 1])
		
		var is_in_shortest_path: bool = id in shortest_id_path
		
		if is_in_shortest_path:
			$PathAudioStreamPlayer.play()
		else:
			$WrongPathAudioStreamPlayer.play()
		
		var cell: Cell = astar.cells[current_id_path[i]]
		cell.show_value(is_in_shortest_path)
		
		$PathResultsTimer.start()
		
		yield($PathResultsTimer, "timeout")
	
	for id in shortest_id_path:
		if not id in current_id_path:
			var cell: Cell = astar.cells[id]
			
			cell.show_value(true)
			
			# TODO: Highlight shortest path with a different color
			# if shortest path is better than current path
	
	var floating_label: Node2D = floating_label_packed_scene.instance()
	
	add_child(floating_label)
	
	var cell: Cell = astar.cells[shortest_id_path.back()]
	floating_label.position = cell.position
	
	if score == base_score:
		$GoodScoreAudioStreamPlayer.play()
	elif score >= int(base_score * 0.10):
		$BadScoreAudioStreamPlayer2.play()
	else:
		$BadScoreAudioStreamPlayer2.play()
		
		print("Very bad score")
	
	# TODO: If score is less than 10% of base score, play wrong score and lose one life
	# Also set score to 0
	
	floating_label.start(score)
	
	emit_signal("score_calculated", score)
	
	$DropCellsTimer.start()
	
	yield($DropCellsTimer, "timeout")
	
	drop_cells()


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
		
		$Tween.interpolate_property(cell, "position", Vector2(cell.position.x, cell.position.y - 360), cell.position, 0.75, Tween.TRANS_SINE, Tween.EASE_IN)
		
		$Tween.start()
		
		yield(get_tree(), "physics_frame")
	
	show()
	
	$AudioStreamPlayer.play()
	
	yield($Tween, "tween_all_completed")
	
	emit_signal("cells_dropped")


func drop_cells() -> void:
	$Target.hide()
	
	$DropCellsAudioStreamPlayer.play()
	
	for cell in astar.cells:
		$Tween.interpolate_property(cell, "position", cell.position, Vector2(cell.position.x, cell.position.y + 480), 0.75, Tween.TRANS_SINE, Tween.EASE_IN)
		
		$Tween.start()
		
		yield(get_tree(), "physics_frame")
	
	yield($Tween, "tween_all_completed")
	
	emit_signal("score_shown")


func set_target() -> void:
	var cell: Cell = astar.cells[target_id]
	
	cell.set_frame(0)
	cell.has_cost_one = true


func show_target() -> void:
	var cell: Cell = astar.cells[target_id]
	
	$Target.position = cell.position
	
	$Target.position.x -= 26
	$Target.position.y -= 19
	
	$Target.show()


func _build_cell(x_position: float, y_position: float) -> Cell:
	var cell: Cell = cell_packed_scene.instance()
	
	add_child(cell)
	
	var cell_coordinates := Vector2(x_position, y_position)
	cell.position = cell_coordinates_to_cell_origin(cell_coordinates)
	cell.coordinates = cell_coordinates
	
	return cell


func _set_neighbors(node: Cell, width, height) -> void:
	var cell_coordinates: Vector2 = node.coordinates
	
	_set_neighbor(node, Vector2(cell_coordinates.x, cell_coordinates.y - 1), Cell.DIRECTION.UP, width, height)
	_set_neighbor(node, Vector2(cell_coordinates.x, cell_coordinates.y + 1), Cell.DIRECTION.DOWN, width, height)
	_set_neighbor(node, Vector2(cell_coordinates.x + 1, cell_coordinates.y), Cell.DIRECTION.RIGHT, width, height)
	_set_neighbor(node, Vector2(cell_coordinates.x - 1, cell_coordinates.y), Cell.DIRECTION.LEFT, width, height)


func _set_neighbor(cell: Cell, neighbor_coordinates: Vector2, direction: int, width, height) -> void:
	var neighbor: Cell = null
	
	if _is_in_range(neighbor_coordinates, width, height):
		neighbor = get_cell_from_coordinates(neighbor_coordinates)
	
	cell.add_neighbor(neighbor, direction)


func _is_in_range(cell_coordinates: Vector2, width, height) -> bool:
	if cell_coordinates.x < 0 or cell_coordinates.x >= width:
		return false
	elif cell_coordinates.y < 0 or cell_coordinates.y >= height:
		return false
	else:
		return true


# Returns the x, y coordinates of a cell (whole numbers)
func get_cell_coordinates(unit_position: Vector2) -> Vector2:
	return Vector2(floor(unit_position.x / tilesize), floor(unit_position.y / tilesize))


func get_cell_from_position(unit_position: Vector2) -> Cell:
	var cell_coordinates := get_cell_coordinates(unit_position)
	
	return get_cell_from_coordinates(cell_coordinates)


func get_cell_from_coordinates(cell_coordinates: Vector2) -> Cell:
	return grid[cell_coordinates.x][cell_coordinates.y]


func cell_coordinates_to_cell_origin(cell_coordinates: Vector2) -> Vector2:
	return Vector2(cell_coordinates.x * tilesize + half_tilesize + tile_offset, cell_coordinates.y * tilesize + + half_tilesize + tile_offset)
