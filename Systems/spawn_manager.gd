extends Node

@export var _terrain : TileMapLayer
@export var _obstacles : TileMapLayer
@export var _destructibles : TileMapLayer
@export var _bomb_scene : PackedScene
@export var _explosion_scene : PackedScene
@export var _snake_scene : PackedScene

var placed_bombs : Dictionary[Vector2i, AnimatableBody2D]

func _ready() -> void:
	SignalBus.spawn_bomb.connect(_on_player_spawn_bomb)
	SignalBus.spawn_explosion.connect(_on_bomb_spawn_explosion)
	SignalBus.spawn_snake.connect(_on_spawn_snake)
	SignalBus.remove_destructible.connect(_on_remove_destructible)

func _on_player_spawn_bomb(player_position: Vector2) -> void:
	if placed_bombs.size() >= PlayerStats.bomb_amount:
		return
	var cell_coordinate := _terrain.local_to_map(player_position)
	var cell_contents := _terrain.get_cell_source_id(cell_coordinate)
	var has_bomb := cell_contents == -1
	if has_bomb or placed_bombs.has(cell_coordinate):
		return
		
	var bomb := _bomb_scene.instantiate()
	bomb.global_position = _terrain.map_to_local(cell_coordinate)
	get_tree().current_scene.add_child(bomb)
	placed_bombs[cell_coordinate] = bomb

func _on_bomb_spawn_explosion(bomb_position: Vector2)->void:
	var cell_coordinate := _terrain.local_to_map(bomb_position)
	placed_bombs.erase(cell_coordinate)
	var explosion := _explosion_scene.instantiate()
	explosion.global_position = bomb_position
	get_tree().current_scene.add_child(explosion)
	
func _on_spawn_snake(snake_pit_position : Vector2)->void:
	var new_snake : Node2D = _snake_scene.instantiate()
	
	#Calculate surrounding cells
	var pit_cell := _terrain.local_to_map(snake_pit_position)
	
	var offsets : Array[Vector2i] = [Vector2i(0,-1), Vector2i(1,0), Vector2i(0,1), Vector2i(-1,0)]
	var neighbours: Array[Vector2i] = []
	for offset : Vector2i in offsets:
		neighbours.append(pit_cell+offset)

	#Check if surrounding cells are empty		
	for neighbour : Vector2i in neighbours:
		if _obstacles.get_cell_source_id(neighbour) != -1 or _destructibles.get_cell_source_id(neighbour) != -1:
			neighbours.erase(neighbour)
		#TODO check for player and bombs

	#Pick a random empty cell to spawn the snake in.
	
	get_tree().root.add_child(new_snake)
	pass
	
func _on_remove_destructible(destructible_position: Vector2)->void:
	var cell_to_destroy := _destructibles.local_to_map(destructible_position)
	if _destructibles.get_cell_source_id(cell_to_destroy) != -1:
		_destructibles.set_cell(cell_to_destroy, -1)
