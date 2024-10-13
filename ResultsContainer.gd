extends MarginContainer


func _ready():
	hide()
	
	#show_results(100, 10, 1, 2, 3)


func show_results(score, boards_cleared, perfect_boards, level, lives) -> void:
	show()
	
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
	
	show_value_with_multiplier($VBoxContainer/BoardsClearedHBox/ValueLabel, boards_cleared, 1000)
	
	yield($Timer, "timeout")
	
	show_value_with_multiplier($VBoxContainer/LevelHBox/ValueLabel, level, 10000)
	
	yield($Timer, "timeout")
	
	show_value_with_multiplier($VBoxContainer/LivesHBox/ValueLabel, lives, 20000)
	
	yield($Timer, "timeout")
	
	var boards_score: int = boards_cleared * 1000
	var level_score: int = level * 10000
	var lives_score: int = lives * 20000
	
	var total_score: int = score + boards_score + level_score + lives_score
	
	show_value($VBoxContainer/BoardsClearedHBox/ValueLabel, boards_score)
	show_value($VBoxContainer/LevelHBox/ValueLabel, level_score)
	show_value($VBoxContainer/LivesHBox/ValueLabel, lives_score)
	show_value($VBoxContainer/TotalHBox/ValueLabel, total_score)
	
	# TODO: Only in 1P mode OR only enable for the winner (or the loser)
	$Tween.interpolate_property($VBoxContainer/PlayAgainButton, "modulate",
		$VBoxContainer/PlayAgainButton.modulate, Color.white,
		1)
	
	$Tween.interpolate_property($VBoxContainer/QuitButton, "modulate",
		$VBoxContainer/QuitButton.modulate, Color.white,
		1)
	
	$Tween.start()
	
	yield($Tween, "tween_all_completed")
	
	$VBoxContainer/PlayAgainButton.grab_focus()


func show_value(label: Label, value: int) -> void:
	label.text = str(value)
	label.get_parent().modulate = Color.white
	
	$AudioStreamPlayer.play()


func show_value_with_multiplier(label: Label, value: int, multiplier: int) -> void:
	label.text = "%d x %d" % [value, multiplier]
	
	label.get_parent().modulate = Color.white
	
	$AudioStreamPlayer.play()
