extends AudioStreamPlayer


var _max_volume_db: float

# Flag to handle case when stop() is called multiple times,
# to avoid starting the tween again
var _is_stopping: bool = false


func _ready() -> void:
	_max_volume_db = volume_db
	
	volume_db = -80


func start_playing() -> void:
	if playing:
		return
	
	$Tween.interpolate_property(self, "volume_db",
		-80, _max_volume_db, 0.5)
	
	$Tween.start()
	
	play()


func stop_playing() -> void:
	if _is_stopping:
		return
	
	_is_stopping = true
	
	$Tween.remove_all()
	
	$Tween.interpolate_property(self, "volume_db",
		volume_db, -80, 0.5)
	
	$Tween.start()
	
	yield($Tween, "tween_all_completed")
	
	stop()
	
	_is_stopping = false
