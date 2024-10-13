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
	
	var total_score: int = score + boards_cleared * 1000 + level * 10000 + lives * 20000
	
	show_value($VBoxContainer/BoardsClearedHBox/ValueLabel,  boards_cleared * 1000)
	show_value($VBoxContainer/LevelHBox/ValueLabel, level * 10000)
	show_value($VBoxContainer/LivesHBox/ValueLabel, lives * 20000)
	show_value($VBoxContainer/TotalHBox/ValueLabel, total_score)
	
	
	$Tween.interpolate_property($VBoxContainer/Button, "modulate",
		$VBoxContainer/Button.modulate, Color.white,
		1)
	
	$Tween.interpolate_property($VBoxContainer/Button2, "modulate",
		$VBoxContainer/Button2.modulate, Color.white,
		1)
	
	$Tween.start()
	
	yield($Tween, "tween_all_completed")
	
	$VBoxContainer/Button.grab_focus()


func show_value(label: Label, value: int) -> void:
	label.text = str(value)
	label.get_parent().modulate = Color.white
	
	$AudioStreamPlayer.play()


func show_value_with_multiplier(label: Label, value: int, multiplier: int) -> void:
	label.text = "%d x %d" % [value, multiplier]
	
	label.get_parent().modulate = Color.white
	
	$AudioStreamPlayer.play()
