class_name ExplosionSegment extends Area2D

signal explosion_animation_finished

enum animations {OUTWARD, END, CENTER}

@onready var sprite : AnimatedSprite2D = %AnimatedSprite2D

func _ready() -> void:
	sprite.animation_finished.connect(
		func()->void:
			explosion_animation_finished.emit()
	)
	
	#var collider := %CollisionShape2D
	##collider.get_
	#
	#var space_state = get_world_2d().direct_space_state
	#var query = PhysicsShapeQueryParameters2D.new()
	##query.collide_with_areas = true
	#query.shape_rid = %CollisionShape2D.shape.get_rid()
	#
	#var query_transform : Transform2D = %CollisionShape2D.global_transform
	#query_transform.origin += Vector2(-8,-8)
	#query.transform = query_transform
	#
	#var collisions = space_state.intersect_shape(query)
	#for collision in collisions:
		#if collision.collider is Player or collision.collider is Snake:
			#queue_redraw()
			#collision.collider.die()

#func _draw() -> void:
			#draw_rect(Rect2(Vector2.ZERO, %CollisionShape2D.shape.size), Color.RED, true)
	#
func set_explosion_animation(animation : animations)->void:
	match animation:
		animations.OUTWARD:
			sprite.play("outward")
		animations.END:
			sprite.play("end")
		animations.CENTER:
			sprite.play("center")

func set_explosion_direction(direction: Vector2)->void:
	match direction:
		Vector2.DOWN:
			sprite.flip_v = true
		Vector2.LEFT:
			sprite.rotation_degrees = -90
		Vector2.RIGHT:
			sprite.rotation_degrees = 90
