class_name Player extends CharacterBody2D

@onready var _animationPlayer : AnimatedSprite2D = %AnimatedSprite2D

var max_speed := 100.0

func _ready() -> void:
	pass

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("place_bomb"):
		SignalBus.spawn_bomb.emit(position)
		pass

func _physics_process(_delta: float) -> void:
	var direction := Input.get_vector("move_left","move_right","move_up","move_down")
	velocity = direction * PlayerStats.movement_speed
	move_and_slide()
		
	var signed_direction := direction.sign()
	match signed_direction:
		Vector2.LEFT, Vector2.RIGHT:
			_animationPlayer.play("move_right")
		Vector2.UP:
			_animationPlayer.play("move_up")
		Vector2.DOWN:
			_animationPlayer.play("move_down")
		Vector2.ZERO:
			_animationPlayer.play("idle")
	
	if signed_direction.length() > 0:
		_animationPlayer.flip_h = direction.x < 0.0


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("explosion"):
		set_physics_process(false)
		_animationPlayer.play("die")
		_animationPlayer.animation_finished.connect(func()->void:
			queue_free()
			PlayerStats.decrease_life()
			
			)
