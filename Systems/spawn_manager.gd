extends Node

@export var _terrain : TileMapLayer
@export var _bomb_scene : PackedScene
@export var _explosion_scene : PackedScene

var placed_bombs : Dictionary[Vector2i, AnimatableBody2D]

func _ready() -> void:
	SignalBus.spawn_bomb.connect(_on_player_spawn_bomb)
	SignalBus.spawn_explosion.connect(_on_bomb_spawn_explosion)

func _on_player_spawn_bomb(player_position: Vector2) -> void:
	if placed_bombs.size() >= PlayerStats.bomb_amount:
		return
	var cell_coordinate := _terrain.local_to_map(player_position)
	var cell_contents := _terrain.get_cell_source_id(cell_coordinate)
	print_debug(cell_coordinate)
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
