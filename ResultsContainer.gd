extends MarginContainer


var player_index: int = 0

var boards_cleared_multiplier: int = 1000
var level_multiplier: int = 10000
var perfect_boards_multiplier: int = 20000


func _ready() -> void:
	hide()


func show_results(score, boards_cleared, perfect_boards, level) -> void:
	show()
	
	var boards_score: int = boards_cleared * boards_cleared_multiplier
	var level_score: int = level * level_multiplier
	var perfect_boards_score: int = perfect_boards * perfect_boards_multiplier
	
	var total_score: int = score + boards_score + level_score + perfect_boards_score
	
	_update_global_score(total_score)
	
	if not GameData.is_left_side_player(player_index):
		$GameOverAudioStreamPlayer.play()
	
	for child in $VBoxContainer.get_children():
		child.modulate.a = 0
	
	$Tween.interpolate_property($VBoxContainer/GameOverLabel, "modulate",
		$VBoxContainer/GameOverLabel.modulate, Color.white,
		1)
	
	$Tween.start()
	
	yield($Tween, "tween_all_completed")
	
	show_value($VBoxContainer/PointsHBox/ValueLabel, score)
	
	$Timer.start()
	
	yield($Timer, "timeout")
	
	show_value_with_multiplier($VBoxContainer/BoardsClearedHBox/ValueLabel, boards_cleared, boards_cleared_multiplier)
	
	yield($Timer, "timeout")
	
	show_value_with_multiplier($VBoxContainer/PerfectBoardsHBox/ValueLabel, perfect_boards, perfect_boards_multiplier)
	
	yield($Timer, "timeout")
	
	show_value_with_multiplier($VBoxContainer/LevelHBox/ValueLabel, level, level_multiplier)
	
	yield($Timer, "timeout")
	
	show_value($VBoxContainer/BoardsClearedHBox/ValueLabel, boards_score)
	show_value($VBoxContainer/LevelHBox/ValueLabel, level_score)
	show_value($VBoxContainer/PerfectBoardsHBox/ValueLabel, perfect_boards_score)
	show_value($VBoxContainer/TotalHBox/ValueLabel, total_score)
	
	if GameData.is_two_player_mode:
		_show_vs_results()
	else:
		_show_buttons()


func _show_vs_results() -> void:
	var winner_index: int = GameData.get_winner_player_index()
	
	var is_tie: bool = false
	var is_win: bool = false
	
	if winner_index == -1:
		$VBoxContainer/GameOverLabel.text = "TIE"
		
		is_tie = true
	elif player_index == winner_index:
		$VBoxContainer/GameOverLabel.text = "WIN"
		
		$VBoxContainer/GameOverLabel.modulate = Color("#5285bd")
		
		is_win = true
		
		$ScoreItemAudioStreamPlayer.play()
	else:
		$VBoxContainer/GameOverLabel.text = "LOSE"
	
	if is_tie:
		if GameData.is_left_side_player(player_index):
			_show_buttons()
	elif not is_win:
		_show_buttons()


func _show_buttons() -> void:
	$VBoxContainer/PlayAgainButton.disabled = false
	
	$Tween.interpolate_property($VBoxContainer/PlayAgainButton, "modulate",
		$VBoxContainer/PlayAgainButton.modulate, Color.white,
		1)
	
	$VBoxContainer/QuitButton.disabled = false
	
	$Tween.interpolate_property($VBoxContainer/QuitButton, "modulate",
		$VBoxContainer/QuitButton.modulate, Color.white,
		1)
	
	$Tween.start()
	
	yield($Tween, "tween_all_completed")
	
	$VBoxContainer/PlayAgainButton.grab_focus()


func show_value(label: Label, value: int) -> void:
	label.text = str(value)
	label.get_parent().modulate = Color.white
	
	if not GameData.is_left_side_player(player_index):
		$ScoreItemAudioStreamPlayer.play()


func show_value_with_multiplier(label: Label, value: int, multiplier: int) -> void:
	label.text = "%d x %d" % [value, multiplier]
	
	label.get_parent().modulate = Color.white
	
	if not GameData.is_left_side_player(player_index):
		$ScoreItemAudioStreamPlayer.play()


func _update_global_score(total_score: int) -> void:
	if not GameData.is_two_player_mode:
		return
	
	if GameData.is_left_side_player(player_index):
		GameData.player_one_score = total_score
	else:
		GameData.player_two_score = total_score


func _on_PlayAgainButton_pressed() -> void:
		# TODO: Don't reset music?
		
		if GameData.is_two_player_mode:
			var _error := Loader.change_scene("res://VsMode.tscn")
		else:
			var _error := Loader.change_scene("res://Main.tscn")


func _on_QuitButton_pressed() -> void:
	var _error := Loader.change_scene("res://TitleScreen.tscn")
	
	GameMusic.stop()
