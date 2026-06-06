extends Node2D

@onready var _terrain : TileMapLayer = %Terrain

var _placed_bombs : Dictionary[Vector2i, Bomb]

func _on_player_spawn_bomb(player_position: Vector2) -> void:
	var cell_coordinate := _terrain.local_to_map(player_position)
	var cell_contents := _terrain.get_cell_source_id(cell_coordinate)
	print_debug(cell_coordinate)
	var has_bomb := cell_contents == -1
	if has_bomb or _placed_bombs.has(cell_coordinate):
		print_debug("Cell already has bomb")
		return
		
	var bomb := Bomb.new()
	bomb.global_position = _terrain.map_to_local(cell_coordinate)
	add_child(bomb)
	_placed_bombs[cell_coordinate] = bomb
	print_debug("bomb placed")
