extends StaticBody2D

var snakescene : PackedScene = preload("res://Enemy/snake.tscn")



func _on_timer_timeout() -> void:
	spawn_snake()

func spawn_snake() -> void:
	var new_snake : Node2D = snakescene.instantiate()
	new_snake.transform = transform
	get_tree().root.add_child(new_snake)
	
