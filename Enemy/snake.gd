class_name Snake extends CharacterBody2D

@onready var _raycasts := %Raycasts

var is_following := false
var player
var speed :float = 3000.0
func _process(delta: float)->void:
	
	var sees_player := false
	for ray : RayCast2D in _raycasts.get_children():
		if ray.is_colliding():
			var collision
	if is_following && player != null:
		var direction_to_player := global_position.direction_to(player.global_position)

		#move to player
		velocity = direction_to_player.sign() * (speed * delta)
		move_and_slide()
		return
	
	#Look around
