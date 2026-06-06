extends Node

var default_bomb_amount := 1
var default_lives := 3
var default_movement_speed : float = 100.0

var movement_speed := default_movement_speed
var lives := default_lives
var bomb_amount := 1
var can_kick : bool = false

func reset_defaults():
	movement_speed = default_movement_speed
	lives = default_lives
	bomb_amount = default_bomb_amount
	can_kick = false
