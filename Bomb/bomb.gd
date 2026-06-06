class_name Bomb extends AnimatableBody2D

@export var bomb_scene : PackedScene = preload("res://Bomb/bomb.tscn")

func _ready() -> void:
	var bomb := bomb_scene.instantiate()
	add_child(bomb)

func _on_area_2d_body_exited(body: Node2D) -> void:
	print_debug("player exited")
	set_collision_layer_value(2, true)
