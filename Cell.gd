extends Node2D

class_name Cell

enum DIRECTION {
	UP,
	DOWN,
	LEFT,
	RIGHT
}

signal pressed(is_dragged)

# Value of this cell
var value: float = 6 setget set_value

# ID in AStar graph, for pathfinding
var id: int = 0

export var has_cost_one: bool = false

export var highlight_color: Color

onready var value_label: Label = $CanvasLayer/MarginContainer2/VBoxContainer/ValueHintLabel

onready var _tween: Tween = $Tween


# x,y coordinates in the grid matrix, for convenience.
var coordinates: Vector2 = Vector2.ZERO

# Array of Cell. Only valid, non-null neighbors
var neighbors: Array = []


var _is_touch_pressed: bool = false


func _ready() -> void:
	disable_selection()


func _process(_delta: float) -> void:
	if Input.is_action_pressed("ui_select"):
		emit_signal("pressed", true)


func _input(event: InputEvent):
	if event is InputEventScreenDrag:
		emit_signal("pressed", true)
		
		_is_touch_pressed = true


func add_neighbor(neighbor: Cell) -> void:
	if neighbor != null:
		neighbors.push_back(neighbor)


func possess() -> void:
	$AnimationPlayer.play("possess")


func possess_again() -> void:
	$AnimationPlayer.play("jump_higher")
	
	hide_arrows()


func release() -> void:
	$AnimationPlayer.play("release")
	
	hide_arrows()


func clear() -> void:
	reset()
	
	neighbors.clear()


func reset() -> void:
	$AnimationPlayer.play("RESET")
	
	hide_arrows()
	
	value_label.hide()


func show_value(is_in_shortest_path: bool, is_correction: bool) -> void:
	if has_cost_one:
		value_label.text = "*"
	else:
		value_label.text = _value_to_string()
	
	value_label.show()
	
	if not is_in_shortest_path:
		value_label.modulate = Color("#514445")
	elif is_correction:
		value_label.modulate = Color("#5285bd")
	else:
		value_label.modulate = Color.white


func set_texture(texture_path: String) -> void:
	$Sprite.texture = ResourceLoader.load(texture_path)


func show_arrow(direction: int) -> void:
	hide_arrows()
	
	$Arrows.get_child(direction).show()


func hide_arrows() -> void:
	for child in $Arrows.get_children():
		child.hide()


func set_value(_value: float) -> void:
	value = _value
	
	$CanvasLayer/MarginContainer2/VBoxContainer/ValueHintLabel.text = _value_to_string()


func _value_to_string() -> String:
	if is_equal_approx(value, floor(value)):
		return "%.f" % value
	else:
		return "%.1f" % value


func enable_selection() -> void:
	$Area2D.show()


func disable_selection() -> void:
	$Area2D.hide()
	
	_remove_highlight()
	
	set_process(false)
	set_process_input(false)


func _remove_highlight() -> void:
	_modulate_border(Color.white)


func _modulate_border(target_color: Color) -> void:
	if _tween.is_active():
		var _error = _tween.stop($Border)
	
	var _error = _tween.interpolate_property($Border, "modulate", $Border.modulate, target_color, 0.1, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	
	_error = _tween.start()


func _on_Area2D_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if (event is InputEventMouseButton or event is InputEventScreenTouch):
		if event.pressed and not _is_touch_pressed:
			emit_signal("pressed", false)
			
			_is_touch_pressed = true
			
			set_process(false)
			set_process_input(false)
		elif not event.pressed:
			_is_touch_pressed = false


func _on_Area2D_mouse_entered() -> void:
	_modulate_border(highlight_color)
	
	set_process(true)
	set_process_input(true)


func _on_Area2D_mouse_exited() -> void:
	_remove_highlight()
	
	set_process(false)
	set_process_input(false)
	
	_is_touch_pressed = false
