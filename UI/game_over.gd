class_name GameOver extends Control

const lost_text = "Game Over"
const won_text = "You Win!"

var game_scene := preload("res://Levels/Level1.tscn")
var menu_scene := preload("res://UI/MainMenu.tscn")
@onready var game_over_label : Label = %GameOverText

func _ready() -> void:
	if GameState.player_won:
		game_over_label.text = won_text
	else:
		game_over_label.text = lost_text
		
	
func _on_quit_button_pressed() -> void:
	get_tree().quit()


func _on_play_again_pressed() -> void:
	GameState.reset()
	get_tree().change_scene_to_packed(game_scene)


func _on_menu_button_pressed() -> void:
	get_tree().change_scene_to_packed(menu_scene)
