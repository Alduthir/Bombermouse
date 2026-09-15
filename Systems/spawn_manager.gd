extends Node

@export var _bomb_scene : PackedScene
@export var _explosion_scene : PackedScene
@export var _snake_scene : PackedScene
@export_range(1,20) var _max_living_enemies : int = 10
var placed_bombs : int = 0
var living_enemies : int = 0

func _ready() -> void:
	SignalBus.spawn_bomb.connect(_on_player_spawn_bomb)
	SignalBus.spawn_explosion.connect(_on_bomb_spawn_explosion)
	SignalBus.spawn_snake.connect(_on_spawn_snake)
	SignalBus.remove_destructible.connect(_on_remove_destructible)
	SignalBus.enemy_death.connect(_on_enemy_death)
	for child in get_tree().root.get_children():
		if child is Snake:
			living_enemies+=1

func _on_player_spawn_bomb(player_position: Vector2) -> void:
	if placed_bombs >= PlayerStats.bomb_amount:
		return
	var cell_coordinate := TileGrid.world_to_grid(player_position)
	if TileGrid.has_bomb_tile(cell_coordinate):
		return
		
	var bomb := _bomb_scene.instantiate()
	bomb.global_position = TileGrid.grid_to_world(cell_coordinate)
	TileGrid.add_bomb_tile(cell_coordinate)
	get_tree().current_scene.add_child(bomb)
	placed_bombs+= 1


func _on_bomb_spawn_explosion(bomb_position: Vector2)->void:
	var cell_coordinate := TileGrid.world_to_grid(bomb_position)
	TileGrid.remove_bomb_tile(cell_coordinate)
	var explosion := _explosion_scene.instantiate()
	explosion.global_position = bomb_position
	get_tree().current_scene.add_child(explosion)
	placed_bombs-=1
	
func _on_spawn_snake(sender : SnakePit)->void:
	var new_snake : Node2D = _snake_scene.instantiate()
	
	#Calculate surrounding cells
	var pit_cell := TileGrid.world_to_grid(sender.global_position)
	
	var offsets : Array[Vector2i] = [Vector2i(0,-1), Vector2i(1,0), Vector2i(0,1), Vector2i(-1,0)]
	var neighbours: Array[Vector2i] = []
	for offset : Vector2i in offsets:
		neighbours.append(pit_cell+offset)

	#Check if surrounding cells are empty		
	for neighbour : Vector2i in neighbours:
		if TileGrid.can_move_to(neighbour) == false:
			neighbours.erase(neighbour)

	#Pick a random empty cell to spawn the snake in.
	var snake_location = neighbours.pick_random()
	print_debug(snake_location)
	new_snake.global_position = TileGrid.grid_to_world(snake_location)
	get_tree().root.add_child(new_snake)
	living_enemies+=1
	
func _on_remove_destructible(destructible_position: Vector2)->void:
	var cell_to_destroy := TileGrid.world_to_grid(destructible_position)
	TileGrid.clear_destructible_tile(cell_to_destroy)
	
func _on_enemy_death()->void:
	living_enemies -= 1
