class_name SnakePit extends StaticBody2D


func _ready() -> void:
	TileGrid.add_snake_pit(TileGrid.world_to_grid(position))
	
func _on_timer_timeout() -> void:
	SignalBus.spawn_snake.emit(self)

func _on_area_2d_area_entered(area: Area2D) -> void:
		TileGrid.remove_snake_pit(TileGrid.world_to_grid(global_position))
		queue_free()
