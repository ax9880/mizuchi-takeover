extends Node2D

class_name Cell

enum DIRECTION {
	UP,
	DOWN,
	LEFT,
	RIGHT
}

# Value of this cell
var value: float = 6 setget set_value

# ID in AStar graph, for pathfinding
var id: int = 0

export var has_cost_one: bool = false

onready var value_label: Label = $CanvasLayer/MarginContainer/ValueLabel


# x,y coordinates in the grid matrix, for convenience.
var coordinates: Vector2 = Vector2.ZERO

# Array of Cell. Only valid, non-null neighbors
var neighbors: Array = []


func add_neighbor(neighbor: Cell, direction: int) -> void:
	if neighbor != null:
		neighbors.push_back(neighbor)


func possess() -> void:
	_play_animation("possess")
	$AnimationPlayer.play("possess")


func possess_again() -> void:
	$AnimationPlayer.play("jump_higher")
	
	hide_arrows()


func release() -> void:
	_play_animation("release")
	$AnimationPlayer.play("release")
	
	hide_arrows()


func reset() -> void:
	has_cost_one = false
	
	$AnimationPlayer.play("RESET")
	
	$Highlight.hide()
	
	hide_arrows()
	
	value_label.hide()


func show_value(is_in_shortest_path: bool) -> void:
	$AnimationPlayer.play("fade")
	
	value_label.text = _value_to_string()
	
	value_label.show()
	
	if not is_in_shortest_path:
		# TODO: Use red color from palette
		value_label.modulate = Color.red
	else:
		value_label.modulate = Color.white


func set_frame(frame: int) -> void:
	$Sprite.frame = frame


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


func _play_animation(animation_name: String) -> void:
	$AnimatedSprite.show()
	
	$AnimatedSprite.frame = 0
	$AnimatedSprite.play(animation_name)
	
	yield($AnimatedSprite, "animation_finished")
	
	$AnimatedSprite.hide()
