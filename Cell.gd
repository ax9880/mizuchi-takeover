extends Node2D

class_name Cell

enum DIRECTION {
	UP,
	DOWN,
	LEFT,
	RIGHT
}

export var value = 6
var id = 0

export var texture: Texture setget set_texture


# x,y coordinates in the grid matrix, for convenience.
var coordinates: Vector2 = Vector2.ZERO

# Array of Cell. Only valid, non-null neighbors
var neighbors: Array = []

# All neighbors, including invalid ones (those neighbors are set to null)
# {String, nullable Cell}
# TODO: Remove, unused
var all_neighbors: Dictionary = {}


func add_neighbor(neighbor: Cell, direction: int) -> void:
	all_neighbors[direction] = neighbor
	
	if neighbor != null:
		neighbors.push_back(neighbor)


func set_text(_id) -> void:
	#$Label.text = str(_id)
	pass


func possess() -> void:
	_play_animation("possess")
	$AnimationPlayer.play("possess")
	
	#$Highlight.show()
	#modulate = Color.purple


func possess_again() -> void:
	$AnimationPlayer.play("jump_higher")
	
	#$PossessionSound.play()
	hide_arrows()


func release() -> void:
	_play_animation("release")
	$AnimationPlayer.play("release")
	
	hide_arrows()


func reset() -> void:
	$AnimationPlayer.play("RESET")
	
	$Highlight.hide()
	
	hide_arrows()
	
	$MarginContainer/ValueLabel.hide()


func show_value(is_in_shortest_path: bool) -> void:
	$AnimationPlayer.play("fade")
	
	if is_equal_approx(value, floor(value)):
		$MarginContainer/ValueLabel.text = "%.f" % value
	else:
		$MarginContainer/ValueLabel.text = "%.1f" % value
	
	$MarginContainer/ValueLabel.show()
	
	if not is_in_shortest_path:
		$MarginContainer/ValueLabel.modulate = Color.red
	else:
		$MarginContainer/ValueLabel.modulate = Color.white


func set_texture(_texture: Texture) -> void:
	texture = _texture
	
	$Sprite.texture = _texture


func show_arrow(direction: int) -> void:
	hide_arrows()
	
	$Arrows.get_child(direction).show()


func hide_arrows() -> void:
	for child in $Arrows.get_children():
		child.hide()


func _play_animation(animation_name: String) -> void:
	$AnimatedSprite.show()
	
	$AnimatedSprite.frame = 0
	$AnimatedSprite.play(animation_name)
	
	yield($AnimatedSprite, "animation_finished")
	
	$AnimatedSprite.hide()
