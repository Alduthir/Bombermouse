class_name Explosion extends Node2D

@onready var center_animation_player : AnimatedSprite2D = %Center
var segment_scene : PackedScene = preload("res://Bomb/explosion_segment.tscn")

var sections := []
var obstacles_to_destroy := []
func _ready() -> void:
	var directions := [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
	
	create_explosion_segment(Vector2.ZERO, RayCast2D.new(), false)
	 
	for direction in directions:
		propagate_in_direction(direction)
	
func propagate_in_direction(direction: Vector2)->void:
		var depth := 0
		var blast_collided = false
		
		var terrain_cast := RayCast2D.new()
		terrain_cast.position = Vector2.ZERO
		terrain_cast.target_position = 8*direction
		terrain_cast.set_collision_mask_value(2, true)
		terrain_cast.set_collision_mask_value(1, true)
		add_child(terrain_cast)
		terrain_cast.force_raycast_update()

		var obstacle_cast := RayCast2D.new()
		obstacle_cast.collide_with_areas = true
		obstacle_cast.hit_from_inside = true
		obstacle_cast.position = Vector2.ZERO
		obstacle_cast.target_position = direction
		obstacle_cast.set_collision_mask_value(6, true)
		obstacle_cast.set_collision_mask_value(1, false)
		add_child(obstacle_cast)
		obstacle_cast.force_raycast_update()
		
		while depth <= BombStats.blast_radius and blast_collided == false:
			if terrain_cast.is_colliding():
				blast_collided = true
				if depth > 0:
					create_explosion_segment(direction,terrain_cast,true)
				break
			elif depth > 0 and depth < BombStats.blast_radius:
				if obstacle_cast.is_colliding():
					blast_collided = true
					obstacles_to_destroy.append(obstacle_cast.global_position)
				create_explosion_segment(direction, terrain_cast, obstacle_cast.is_colliding())
			elif depth == BombStats.blast_radius:
				create_explosion_segment(direction, terrain_cast, true)

			depth+=1
			terrain_cast.position += 16*direction
			terrain_cast.force_raycast_update()
			obstacle_cast.position += 16*direction
			obstacle_cast.force_raycast_update()

func create_explosion_segment(direction : Vector2, terrain_cast: RayCast2D, is_end: bool)->void:
	var explosion_segment : ExplosionSegment = segment_scene.instantiate()
	explosion_segment.position = terrain_cast.position
	
	add_child(explosion_segment)
	sections.append(explosion_segment)
	
	if is_end:
		explosion_segment.set_explosion_animation(ExplosionSegment.animations.END)
	elif direction == Vector2.ZERO:
		explosion_segment.set_explosion_animation(ExplosionSegment.animations.CENTER)
	else:
		explosion_segment.set_explosion_animation(ExplosionSegment.animations.OUTWARD)
	
	explosion_segment.set_explosion_direction(direction)
	explosion_segment.explosion_animation_finished.connect(finalize_explosion)
	
func finalize_explosion()->void:
	for exploded_position in obstacles_to_destroy:
		SignalBus.remove_destructible.emit(exploded_position)
	queue_free()
