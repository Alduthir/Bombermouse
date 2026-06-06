class_name Player extends CharacterBody2D

signal spawn_bomb(player_position : Vector2)

@onready var _animationPlayer : AnimatedSprite2D = %AnimatedSprite2D
@onready var _hurtBox : CollisionShape2D = %HurtBox


var max_speed := 100.0

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("place_bomb"):
		spawn_bomb.emit(position)
		pass

func _physics_process(delta: float) -> void:
	var direction := Input.get_vector("move_left","move_right","move_up","move_down")
	velocity = direction * max_speed
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
