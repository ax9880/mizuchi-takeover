extends Node


var is_two_player_mode: bool = false
var can_grow_size: bool = true

var starting_size: int = 3
var time_seconds: int = 2

var player_one_score: int = 0
var player_two_score: int = 0


func get_winner_player_index() -> int:
	if player_one_score == player_two_score:
		return -1
	elif player_one_score > player_two_score:
		return 1
	else:
		return 0


func is_player_one(player_index: int) -> bool:
	# Index 0 is for arrow controls, which are on the right (player 2)
	return player_index == 1
