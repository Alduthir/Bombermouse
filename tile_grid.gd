extends Node

const TILE_SIZE := 16
var terrain: TileMapLayer
var obstacles: TileMapLayer
var destructibles: TileMapLayer
var bomb_tiles : Array[Vector2i] = []
func setup(p_terrain: TileMapLayer, p_obstacles: TileMapLayer, p_destructibles: TileMapLayer)->void:
	terrain = p_terrain
	obstacles = p_obstacles
	destructibles = p_destructibles
	
func can_move_to(cell: Vector2i) -> bool:
	if obstacles.get_cell_source_id(cell) != -1:
		return false
	if destructibles.get_cell_source_id(cell) != -1:
		return false
	if bomb_tiles.has(cell):
		return false
	
	#If there is no cell drawn on terrain, its a nonexistant piece of map.
	if terrain.get_cell_source_id(cell) == -1:
		return false
	return true

func grid_to_world(cell: Vector2i) -> Vector2:
	return Vector2(cell) * TILE_SIZE + Vector2(TILE_SIZE / 2.0, TILE_SIZE / 2.0)

func world_to_grid(pos: Vector2) -> Vector2i:
	return Vector2i(
		floor(pos.x / TILE_SIZE),
		floor(pos.y / TILE_SIZE)
	)

func add_bomb_tile(cell: Vector2i):
	bomb_tiles.append(cell)
	
	
func remove_bomb_tile(cell: Vector2i):
	bomb_tiles.erase(cell)

func has_bomb_tile(cell: Vector2i):
	return bomb_tiles.has(cell)

func clear_destructible_tile(cell: Vector2i):
	if destructibles.get_cell_source_id(cell) != -1:
		destructibles.set_cell(cell, -1)
