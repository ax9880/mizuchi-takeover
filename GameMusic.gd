extends Node


export(Array, Resource) var audio_streams: Array

var _random := RandomNumberGenerator.new()

# Flag to handle case when stop() is called multiple times,
# to avoid starting the tween again
var _is_stopping: bool = false


func _ready() -> void:
	_random.randomize()
	
	$AudioStreamPlayer.volume_db = -80


func play() -> void:
	if audio_streams.empty():
		return
	
	if $AudioStreamPlayer.playing:
		return
	
	if GameData.is_two_player_mode:
		$AudioStreamPlayer.stream = audio_streams[_random.randi_range(0, audio_streams.size() - 1)]
	else:
		$AudioStreamPlayer.stream = audio_streams.front()
		
	$AudioStreamPlayer.start_playing()


func stop() -> void:
	$AudioStreamPlayer.stop_playing()
