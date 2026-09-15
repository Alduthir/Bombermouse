class_name SnakePit extends StaticBody2D

func _on_timer_timeout() -> void:
	SignalBus.spawn_snake.emit(self)
	
