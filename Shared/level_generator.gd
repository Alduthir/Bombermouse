class_name LevelGenerator
extends RefCounted
## Mockup of a procedural level generator for Bombermouse.
##
## Generates a full level layout as plain data (see GeneratedLevel), then
## writes it into the three TileMapLayers and instantiates snakepits and
## snakes. Deterministic per seed, which makes it trivially testable:
## generate twice with the same seed and the maps must be identical.
##
## Guarantees (all of them re-checked by is_valid(), which returns a list of
## human-readable violations -- an empty list means the map is playable):
##   1. Floor covers the whole map and total blocked cells stay under
##      max_blocked_ratio, so the player always has open room to maneuver.
##   2. Clear zone around the player start: no blocker within
##      start_clear_radius (Chebyshev) of it.
##   3. All free space is a single connected component, so neither the player
##      nor any snake can ever be sealed into a pocket by terrain.
##      Destructibles are deliberately treated as solid for this check: a
##      tree-sealed pocket would still cost the player bombs, so it gets dug
##      open anyway.
##   4. Exactly pit_count pits and snake_count snakes, spread across the map
##      with a minimum pairwise spacing (relaxed automatically, 4 -> 3 -> 2
##      -> 1, if the map is too crowded to honour it).
##   5. No pit or snake within spawn_exclusion_radius (Chebyshev) of the
##      player start.
##   6. Every pit keeps at least one free neighbour and never disconnects the
##      map, so a snake can still spawn next to it when it gets blasted.
##
## Usage (level scene _ready; MUST run BEFORE TileGrid.setup(), which scans
## the scene tree for SnakePit nodes):
##
##   var gen := LevelGenerator.new()
##   gen.seed_value = 1337                    # -1 => random map every load
##   var data := gen.generate()
##   gen.apply_to(data, self, %Terrain, %Obstacles, %Destructibles,
##                %SpawnManager.EnemyRoot)
##   var p := %Player
##   p.global_position = TileGrid.grid_to_world(data.player_start)
##   p.current_grid_position = data.player_start  # Player._ready already ran
##   p.target_grid_position = data.player_start   # (children ready before the
##                                                # level), so refresh it
##   TileGrid.setup(%Terrain, %Obstacles, %Destructibles)
##
## Note: when switching a hand-made level (like Level1.tscn) over to this,
## remove its manually placed pits/snakes from the scene first, otherwise
## they end up on top of the generated ones.

# ---------------------------------------------------------------------------
# Tileset data (from Shared/Tileset.tres):
#   source 0 = grassy atlas; atlas (1,0) is plain floor (no collision object).
#             Other collision-free variants, if you want visual variety:
#             (2,0), (11,0), (20,0).
#   source 2 = Stump.png, tile (0,0), physics layer 0 => collision layer 2
#             (Terrain -- indestructible).
#   source 3 = tree.png, tile (0,0), physics layer 1 => collision layer 32
#             (Destructible).
# The generator only writes tiles; the collision layers come from the tileset.
# ---------------------------------------------------------------------------
const FLOOR_SOURCE_ID := 0
const FLOOR_ATLAS_COORDS := Vector2i(1, 0)
const STUMP_SOURCE_ID := 2
const STUMP_ATLAS_COORDS := Vector2i(0, 0)
const TREE_SOURCE_ID := 3
const TREE_ATLAS_COORDS := Vector2i(0, 0)

const PIT_SCENE: PackedScene = preload("res://Enemy/snakepit.tscn")
const SNAKE_SCENE: PackedScene = preload("res://Enemy/snake.tscn")

const _CARDINALS: Array[Vector2i] = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]

# --- Tunables ---------------------------------------------------------------
var map_size := Vector2i(15, 13)
var player_start_override := Vector2i(-1, -1)  # (-1,-1) => centre of the map
var seed_value := -1                           # -1 => randomise the seed
var last_seed := -1                            # seed actually used by the last generate()
var pit_count := 4
var snake_count := 4
var start_clear_radius := 1                    # 1 => 3x3 clear zone at the start
var spawn_exclusion_radius := 4                # pits/snakes must be further than this
var min_pit_spacing := 4                       # relaxed downwards if impossible
var min_snake_spacing := 2
var obstacle_target_ratio := 0.14              # stumps (indestructible)
var destructible_target_ratio := 0.10          # trees (destructible)
var max_blocked_ratio := 0.35                  # hard cap on stumps + trees combined

var rng := RandomNumberGenerator.new()


## Plain data describing one generated level. No nodes, no scene knowledge --
## this is the object unit tests operate on.
class GeneratedLevel:
	var size := Vector2i.ZERO
	var player_start := Vector2i.ZERO
	var obstacle_cells: Array[Vector2i] = []
	var destructible_cells: Array[Vector2i] = []
	var pit_cells: Array[Vector2i] = []
	var snake_cells: Array[Vector2i] = []


func generate() -> GeneratedLevel:
	if seed_value >= 0:
		rng.seed = seed_value
	else:
		rng.randomize()
	last_seed = rng.seed

	var level := GeneratedLevel.new()
	level.size = map_size
	level.player_start = player_start_override \
			if player_start_override != Vector2i(-1, -1) \
			else Vector2i(map_size.x / 2, map_size.y / 2)

	_scatter(level, level.obstacle_cells, int(map_size.x * map_size.y * obstacle_target_ratio))
	_scatter(level, level.destructible_cells, int(map_size.x * map_size.y * destructible_target_ratio))
	_dig_until_open(level)
	level.pit_cells = _place_entities(level, pit_count, min_pit_spacing, true, [])
	level.snake_cells = _place_entities(level, snake_count, min_snake_spacing, false, level.pit_cells)
	return level


## Writes the generated level into the scene: layers first, then pits (as
## children of level_root, so TileGrid.setup's SnakePit scan finds them) and
## snakes (into enemy_root, i.e. SpawnManager's EnemyRoot).
func apply_to(level: GeneratedLevel, level_root: Node, terrain: TileMapLayer,
		obstacles: TileMapLayer, destructibles: TileMapLayer, enemy_root: Node) -> void:
	terrain.clear()
	obstacles.clear()
	destructibles.clear()

	for x in level.size.x:
		for y in level.size.y:
			terrain.set_cell(Vector2i(x, y), FLOOR_SOURCE_ID, FLOOR_ATLAS_COORDS)
	for cell in level.obstacle_cells:
		obstacles.set_cell(cell, STUMP_SOURCE_ID, STUMP_ATLAS_COORDS)
	for cell in level.destructible_cells:
		destructibles.set_cell(cell, TREE_SOURCE_ID, TREE_ATLAS_COORDS)

	for cell in level.pit_cells:
		var pit: Node2D = PIT_SCENE.instantiate()
		# The SnakePit scene ships with a Camera2D; with 4 pits that means 4
		# competing cameras. Disable them here until that is cleaned up in the
		# scene itself (the level's player camera should be the only one on).
		var pit_camera := pit.get_node_or_null("Camera2D") as Camera2D
		if pit_camera != null:
			pit_camera.enabled = false
		pit.global_position = TileGrid.grid_to_world(cell)
		level_root.add_child(pit)

	for cell in level.snake_cells:
		var snake: Node2D = SNAKE_SCENE.instantiate()
		snake.global_position = TileGrid.grid_to_world(cell)
		enemy_root.add_child(snake)


## Re-checks every guarantee. Returns [] when the level is playable,
## otherwise one string per violation. This is also the hook unit tests use.
func is_valid(level: GeneratedLevel) -> Array[String]:
	var problems: Array[String] = []

	if level.pit_cells.size() != pit_count:
		problems.append("expected %d pits, got %d" % [pit_count, level.pit_cells.size()])
	if level.snake_cells.size() != snake_count:
		problems.append("expected %d snakes, got %d" % [snake_count, level.snake_cells.size()])

	for cell in level.pit_cells:
		if _chebyshev(cell, level.player_start) <= spawn_exclusion_radius:
			problems.append("pit at %s is inside the spawn exclusion zone" % str(cell))
	for cell in level.snake_cells:
		if _chebyshev(cell, level.player_start) <= spawn_exclusion_radius:
			problems.append("snake at %s is inside the spawn exclusion zone" % str(cell))
		if level.pit_cells.has(cell):
			problems.append("snake at %s shares a cell with a pit" % str(cell))

	for cell in level.obstacle_cells + level.destructible_cells:
		if _chebyshev(cell, level.player_start) <= start_clear_radius:
			problems.append("blocker at %s is inside the start clear zone" % str(cell))

	var blocked := level.obstacle_cells.size() + level.destructible_cells.size()
	if float(blocked) / float(level.size.x * level.size.y) > max_blocked_ratio:
		problems.append("blocked ratio too high: %d cells" % blocked)

	var seen := {}
	for cell in level.pit_cells + level.snake_cells:
		if not _in_bounds(level, cell):
			problems.append("spawn at %s is out of bounds" % str(cell))
		elif level.obstacle_cells.has(cell) or level.destructible_cells.has(cell):
			problems.append("spawn at %s sits on a blocker" % str(cell))
		elif seen.has(cell):
			problems.append("duplicate spawn cell %s" % str(cell))
		else:
			seen[cell] = true

	if _flood_fill(level, level.player_start).size() < _all_free_cells(level).size():
		problems.append("free space is not fully connected")

	return problems


## Small ASCII rendering for eyeballing maps in the debugger or test output:
## @ start, # stump, t tree, P pit, S snake, . floor.
func debug_ascii(level: GeneratedLevel) -> String:
	var lines: PackedStringArray = []
	for y in level.size.y:
		var line := ""
		for x in level.size.x:
			var cell := Vector2i(x, y)
			if cell == level.player_start:
				line += "@"
			elif level.obstacle_cells.has(cell):
				line += "#"
			elif level.destructible_cells.has(cell):
				line += "t"
			elif level.pit_cells.has(cell):
				line += "P"
			elif level.snake_cells.has(cell):
				line += "S"
			else:
				line += "."
		lines.append(line)
	return "\n".join(lines)


# --- Generation steps -------------------------------------------------------

## Random-walk clusters of `cells` (stumps or trees) until target_count is
## reached. Clusters look more organic than single random tiles.
func _scatter(level: GeneratedLevel, cells: Array, target_count: int) -> void:
	var guard := 0
	while cells.size() < target_count and guard < 200:
		guard += 1
		var seed_cell := _random_cell_outside_zones(level)
		if seed_cell == Vector2i(-1, -1):
			break
		_grow_cluster(level, cells, seed_cell, 2, 4, target_count)


func _grow_cluster(level: GeneratedLevel, cells: Array, seed_cell: Vector2i,
		min_len: int, max_len: int, target_count: int) -> void:
	var length := rng.randi_range(min_len, max_len)
	var current := seed_cell
	var direction := _CARDINALS.pick_random()
	for i in length:
		if cells.size() >= target_count:
			break
		if _can_place_blocker(level, cells, current):
			cells.append(current)
		if rng.randf() >= 0.7:
			direction = _CARDINALS.pick_random()
		current += direction


func _can_place_blocker(level: GeneratedLevel, cells: Array, cell: Vector2i) -> bool:
	if not _in_bounds(level, cell):
		return false
	if _chebyshev(cell, level.player_start) <= start_clear_radius:
		return false
	if cells.has(cell) or level.obstacle_cells.has(cell) or level.destructible_cells.has(cell):
		return false
	return true


func _random_cell_outside_zones(level: GeneratedLevel) -> Vector2i:
	for i in 20:
		var cell := Vector2i(rng.randi_range(0, level.size.x - 1), rng.randi_range(0, level.size.y - 1))
		if _chebyshev(cell, level.player_start) <= start_clear_radius:
			continue
		if level.obstacle_cells.has(cell) or level.destructible_cells.has(cell):
			continue
		return cell
	return Vector2i(-1, -1)


## Flood-fills from the start and, while some free cell is unreachable,
## removes one blocker ("bridge") that touches both the reachable and the
## unreachable side. Destructibles are dug first -- they are meant to be
## broken anyway, and it only ever makes the map easier.
func _dig_until_open(level: GeneratedLevel) -> void:
	var guard := 0
	while guard < 64:
		guard += 1
		var free_cells := _all_free_cells(level)
		var reached := _flood_fill(level, level.player_start)
		if reached.size() >= free_cells.size():
			return
		var bridge := _find_bridge_cell(level, free_cells, reached)
		if bridge == Vector2i(-1, -1):
			push_warning("LevelGenerator: could not fully connect the map")
			return
		if level.destructible_cells.has(bridge):
			level.destructible_cells.erase(bridge)
		else:
			level.obstacle_cells.erase(bridge)


func _find_bridge_cell(level: GeneratedLevel, free_cells: Array, reached: Dictionary) -> Vector2i:
	var tree_options: Array[Vector2i] = []
	var stump_options: Array[Vector2i] = []
	for cell in level.obstacle_cells + level.destructible_cells:
		var touches_reached := false
		var touches_unreached := false
		for dir in _CARDINALS:
			var neighbour := cell + dir
			if not free_cells.has(neighbour):
				continue
			if reached.has(neighbour):
				touches_reached = true
			else:
				touches_unreached = true
		if touches_reached and touches_unreached:
			if level.destructible_cells.has(cell):
				tree_options.append(cell)
			else:
				stump_options.append(cell)
	var options := tree_options if not tree_options.is_empty() else stump_options
	if options.is_empty():
		return Vector2i(-1, -1)
	return options.pick_random()


## Greedy placement with minimum pairwise spacing, relaxed 4 -> 3 -> 2 -> 1 -> 0
## until all `count` entities fit. With connectivity_sensitive = true a
## candidate is rejected if blocking its cell would disconnect the free space
## -- which for pits also guarantees they keep a free neighbour.
func _place_entities(level: GeneratedLevel, count: int, min_spacing: int,
		connectivity_sensitive: bool, avoid: Array) -> Array[Vector2i]:
	var candidates: Array[Vector2i] = []
	for cell in _all_free_cells(level):
		if _chebyshev(cell, level.player_start) <= spawn_exclusion_radius:
			continue
		if avoid.has(cell):
			continue
		candidates.append(cell)

	var placed: Array[Vector2i] = []
	for spacing in range(min_spacing, -1, -1):
		candidates.shuffle_with_rng(rng)
		placed = []
		for cell in candidates:
			if placed.size() >= count:
				break
			if placed.has(cell):
				continue
			if not _respects_spacing(cell, placed, spacing):
				continue
			if connectivity_sensitive and _would_disconnect(level, cell):
				continue
			placed.append(cell)
		if placed.size() >= count:
			return placed
	push_warning("LevelGenerator: could only place %d of %d (map too crowded?)" % [placed.size(), count])
	return placed


func _respects_spacing(cell: Vector2i, placed: Array, spacing: int) -> bool:
	for other in placed:
		if _chebyshev(cell, other) < spacing:
			return false
	return true


func _would_disconnect(level: GeneratedLevel, cell: Vector2i) -> bool:
	var free_count := _all_free_cells(level).size()
	var reached := _flood_fill(level, level.player_start, [cell])
	return reached.size() < free_count


# --- Grid helpers -----------------------------------------------------------

func _in_bounds(level: GeneratedLevel, cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < level.size.x and cell.y < level.size.y


func _chebyshev(a: Vector2i, b: Vector2i) -> int:
	return maxi(absi(a.x - b.x), absi(a.y - b.y))


func _is_free(level: GeneratedLevel, cell: Vector2i, extra_blocked: Array = []) -> bool:
	if not _in_bounds(level, cell):
		return false
	if level.obstacle_cells.has(cell) or level.destructible_cells.has(cell) or level.pit_cells.has(cell):
		return false
	for blocked in extra_blocked:
		if cell == blocked:
			return false
	return true


func _all_free_cells(level: GeneratedLevel) -> Array[Vector2i]:
	var free_cells: Array[Vector2i] = []
	for x in level.size.x:
		for y in level.size.y:
			var cell := Vector2i(x, y)
			if _is_free(level, cell):
				free_cells.append(cell)
	return free_cells


## 4-connected flood fill. Pits count as solid walls (they block movement).
func _flood_fill(level: GeneratedLevel, start: Vector2i, extra_blocked: Array = []) -> Dictionary:
	var reached := {}
	if not _is_free(level, start, extra_blocked):
		return reached
	reached[start] = true
	var frontier: Array[Vector2i] = [start]
	while not frontier.is_empty():
		var cell: Vector2i = frontier.pop_back()
		for dir in _CARDINALS:
			var next := cell + dir
			if reached.has(next) or not _is_free(level, next, extra_blocked):
				continue
			reached[next] = true
			frontier.append(next)
	return reached
