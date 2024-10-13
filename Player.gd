extends Sprite


var _angle_degrees: float = 0


func _ready():
	_start_rotation()


func _start_rotation() -> void:
	$Tween.interpolate_method(self, "rotate_sprite", _angle_degrees, _angle_degrees + 359, 1, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	$Tween.start()


func rotate_sprite(angle_degrees: float) -> void:
	_angle_degrees = angle_degrees
	var angle_rad := deg2rad(_angle_degrees)
	
	$Sprite.position = 12 * Vector2(cos(angle_rad), sin(angle_rad))


func advance_tween() -> void:
	$Tween.remove(self, "rotate_sprite")
	
	_start_rotation()


func _on_Tween_tween_completed(object, key):
	_angle_degrees = int(_angle_degrees) % 360
	
	_start_rotation()
