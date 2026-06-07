class_name Bomb extends AnimatableBody2D

@onready var _sprite : AnimatedSprite2D = %AnimatedSprite2D

func _ready() -> void:
	_sprite.animation_finished.connect(func()->void:
		SignalBus.spawn_explosion.emit(position)
		queue_free()
	)
	_sprite.play()
	var tween: Tween = create_tween()
	tween.set_loops()
	# Flash to bright white over 0.05 seconds
	tween.tween_property(self, "modulate", Color.WHITE * 5, 0.75)
	# Fade back to normal color over 0.2 seconds
	tween.tween_property(self, "modulate", Color.WHITE, 1)


	
func _on_area_2d_body_exited(_body: Node2D) -> void:
	set_collision_layer_value(2, true)
