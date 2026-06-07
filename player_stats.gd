extends Node

var default_bomb_amount := 1
var default_lives := 3
var default_movement_speed : float = 100.0

var movement_speed := default_movement_speed
var lives := default_lives
var bomb_amount := 1
var can_kick : bool = false

func decrease_life()-> void:
	lives -= 1
	reset_defaults()
	
	if lives <= 0:
		print_debug("Game Over")
	else:
		get_tree().reload_current_scene()

func reset_defaults() -> void:
	movement_speed = default_movement_speed
	bomb_amount = default_bomb_amount
	can_kick = false
