extends StaticBody2D

func _on_explosion_detection_body_entered(body: Node2D) -> void:
	print_debug("Explosion in area")
	queue_free()
