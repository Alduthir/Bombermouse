extends CharacterBody2D
var is_following := false
var player
var speed :float = 200.0
func _process(delta: float)->void:
	if is_following && player != null:
		var direction_to_player := global_position.direction_to(player.global_position)

		#move to player
		velocity = direction_to_player.sign() * (speed * delta)
		move_and_slide()
		return
	
	#Look around

func _on_follow_range_body_entered(body: Node2D) -> void:
	if body is Player:
		is_following = true
		player = body

func _on_follow_range_body_exited(body: Node2D) -> void:
	is_following = false
	player = null
