class_name Player extends CharacterBody2D

@onready var _animationPlayer : AnimatedSprite2D = %AnimatedSprite2D

var current_grid_position : Vector2i
var target_grid_position: Vector2i
var is_moving = false

func _ready() -> void:
	current_grid_position = TileGrid.world_to_grid(global_position)
	target_grid_position = current_grid_position
	global_position = TileGrid.grid_to_world(current_grid_position)

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("place_bomb"):
		SignalBus.spawn_bomb.emit(position)

func _physics_process(_delta: float) -> void:
	var direction := Input.get_vector("move_left","move_right","move_up","move_down")
	
	if is_moving:
		return
	
	if direction != Vector2.ZERO:
		try_move(direction)
	
	update_animation(direction)
		
func try_move(direction: Vector2i)->void:
	var next_grid_position := current_grid_position + direction
	
	if not TileGrid.can_move_to(next_grid_position):
		return
	
	target_grid_position = next_grid_position
	is_moving = true
	var tween := create_tween()
	tween.tween_property(self, "global_position", TileGrid.grid_to_world(target_grid_position), 0.12).set_trans(Tween.TRANS_LINEAR)
	tween.tween_callback(func():
		current_grid_position = target_grid_position
		is_moving = false
	)

func update_animation(direction: Vector2)->void:
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
	if body.is_in_group("explosion") or body.is_in_group("enemy"):
		set_physics_process(false)
		_animationPlayer.play("die")
		_animationPlayer.animation_finished.connect(func()->void:
			queue_free()
			PlayerStats.decrease_life()
		)
