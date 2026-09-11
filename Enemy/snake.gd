class_name Snake extends CharacterBody2D

@onready var _raycasts := %Raycasts

var is_following := false
var player
var speed :float = 3000.0

var movement_direction := Vector2.ZERO

func _process(delta: float)->void:
	var sees_player := false
	var movement_direction_options : Array[Vector2] = []
	for ray : RayCast2D in _raycasts.get_children():
		# If the ray sees the player, that is the only valid movement option. Otherwise it gets added to the list
		if ray.is_colliding():
			if ray.get_collider() is Player:
				movement_direction_options = [ray.target_position.sign()]
				sees_player = true
				break
			else:
				var collision_point : Vector2 = ray.get_collision_point()
				if position.distance_to(collision_point) > 8.0:
					movement_direction_options.append(ray.target_position.sign())
		if ray.is_colliding() == false:
			movement_direction_options.append(ray.target_position.sign())	
	
	if sees_player: 
		movement_direction = movement_direction_options[0]
	elif movement_direction_options.has(movement_direction) == false:
		movement_direction= movement_direction_options.pick_random()
	
	velocity = movement_direction * (speed * delta)
	move_and_slide()
	
