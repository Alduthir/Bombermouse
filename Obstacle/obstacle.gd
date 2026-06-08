class_name Obstacle extends StaticBody2D

func explode()->void:
	print_debug("Explosion in area")
	queue_free()
