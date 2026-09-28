extends Node

@onready var game_over_scene := preload("res://UI/GameOver.tscn")
var player_won := false

func reset()->void:
	player_won = false
	PlayerStats.reset_defaults()

func trigger_gameover(has_won: bool = false)->void:
	player_won = has_won
	get_tree().change_scene_to_packed(game_over_scene)
