class_name Explosion extends Node2D

@onready var center_animation_plater : AnimatedSprite2D = %Center
var explosion_spriteframes := preload("res://Bomb/explosion_animation.tres")
var sections := []
func _ready() -> void:
	var directions := [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
	
	for direction in directions:
		propagate_in_direction(direction)
		
	center_animation_plater.play("center")
	for section : Node2D in sections:
		var animation_player : AnimatedSprite2D = section.get_child(0)
		animation_player.play()
		animation_player.animation_finished.connect(queue_free)
	
func propagate_in_direction(direction: Vector2)->void:
		var depth := 0
		var blast_collided = false
		
		var terrain_cast := RayCast2D.new()
		terrain_cast.position = Vector2.ZERO
		terrain_cast.target_position = 8*direction
		terrain_cast.set_collision_mask_value(2, true)
		add_child(terrain_cast)
		terrain_cast.force_raycast_update()

		var obstacle_cast := RayCast2D.new()
		obstacle_cast.collide_with_areas = true
		obstacle_cast.hit_from_inside = true
		obstacle_cast.position = Vector2.ZERO
		obstacle_cast.target_position = direction
		obstacle_cast.set_collision_mask_value(6, true)
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
				create_explosion_segment(direction, terrain_cast, obstacle_cast.is_colliding())
			elif depth == BombStats.blast_radius:
				create_explosion_segment(direction, terrain_cast, true)

			depth+=1
			terrain_cast.position += 16*direction
			terrain_cast.force_raycast_update()
			obstacle_cast.position += 16*direction
			obstacle_cast.force_raycast_update()

func create_explosion_segment(direction : Vector2, terrain_cast: RayCast2D, is_end: bool)->void:
	var explosion_segment := StaticBody2D.new()
	explosion_segment.add_to_group("explosion")
	explosion_segment.position = terrain_cast.position
	explosion_segment.set_collision_layer_value(4, true)
	explosion_segment.set_collision_mask_value(1, true)
	explosion_segment.set_collision_mask_value(3, true)
	explosion_segment.set_collision_mask_value(5, true)
	explosion_segment.set_collision_mask_value(6, true)

	var animatedSprite := AnimatedSprite2D.new()
	animatedSprite.sprite_frames = explosion_spriteframes
	animatedSprite.animation = "outward"
	if is_end:
		animatedSprite.animation = "end"
	explosion_segment.add_child(animatedSprite)
	
	var rectangle = RectangleShape2D.new()
	rectangle.size = Vector2(16,16)
	var collision_shape = CollisionShape2D.new()
	collision_shape.shape = rectangle
	explosion_segment.add_child(collision_shape)
	
	match direction:
		Vector2.DOWN:
			animatedSprite.flip_v = true
		Vector2.LEFT:
			animatedSprite.rotation_degrees = -90
		Vector2.RIGHT:
			animatedSprite.rotation_degrees = 90
	

	add_child(explosion_segment)
	sections.append(explosion_segment)
