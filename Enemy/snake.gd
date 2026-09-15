class_name Snake extends CharacterBody2D

@onready var _raycasts := %RayCasts

var movement_direction := Vector2.ZERO
var grid_position : Vector2i
var is_moving : bool = false

func _ready() -> void:
	grid_position = TileGrid.world_to_grid(global_position)

func _physics_process(delta: float) -> void:
	if is_moving == false:
		movement_direction = choose_direction()
	
		var target_grid_position := grid_position + Vector2i(movement_direction.sign())
		move(target_grid_position)
	
func choose_direction()->Vector2i:
	var sees_player := false
	var movement_direction_options : Array[Vector2i] = []
	for ray : RayCast2D in _raycasts.get_children():
		# If the ray sees the player, that is the only valid movement option. Otherwise it gets added to the list
		if ray.is_colliding():
			if ray.get_collider() is Player and TileGrid.can_move_to(grid_position + Vector2i(ray.target_position.sign())):
				movement_direction_options = [ray.target_position.sign()]
				sees_player = true
				break
		
		if TileGrid.can_move_to(grid_position + Vector2i(ray.target_position.sign())):
			movement_direction_options.append(ray.target_position.sign())
	
	if movement_direction_options.is_empty():
		movement_direction = Vector2.ZERO
	elif sees_player: 
		movement_direction = movement_direction_options[0]
	#only overwrite if blocked to avoid changing direction every tile
	else:
		movement_direction= movement_direction_options.pick_random()
		
	return movement_direction

func move(target : Vector2)->void:
	if is_moving:
		return
		
	is_moving = true
	var tween = create_tween()
	tween.tween_property(self, "global_position", TileGrid.grid_to_world(target), 0.45)
	tween.tween_callback(func(): 
		is_moving = false
		grid_position = target
		)


func _on_hurt_box_body_entered(body: Node2D) -> void:
	if body.is_in_group("explosion"):
		set_physics_process(false)
		SignalBus.enemy_death.emit()
		queue_free()
