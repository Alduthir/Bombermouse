extends Node2D
## Test level for the LevelGenerator mockup (Shared/level_generator.gd).
##
## - Generates a map on load (initial_seed) and rolls a fresh random map
##   whenever R is pressed.
## - The corner label shows the seed that was actually used (so a map you
##   like can be regenerated exactly), the is_valid() result, and an ASCII
##   rendering of the map:
##     @ player start, # stump, t tree, P snakepit, S snake, . floor
## - Any is_valid() violation is also pushed to the Output panel as a warning.

@export var initial_seed := 1337
@export var map_size := Vector2i(15, 13)

@onready var _terrain: TileMapLayer = %Terrain
@onready var _obstacles: TileMapLayer = %Obstacles
@onready var _destructibles: TileMapLayer = %Destructibles
@onready var _player: Player = %Player
@onready var _enemy_root: Node = %SpawnManager.EnemyRoot
@onready var _debug_label: Label = %DebugLabel


func _ready() -> void:
	_build_level(initial_seed)


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key and key.pressed and not key.echo and key.physical_keycode == KEY_R:
		_build_level(-1)


func _build_level(seed: int) -> void:
	_clear_previous()

	var gen := LevelGenerator.new()
	gen.map_size = map_size
	gen.seed_value = seed
	var data := gen.generate()
	gen.apply_to(data, self, _terrain, _obstacles, _destructibles, _enemy_root)

	# The player's move tween (if any) targets a cell on the old map; kill it
	# before repositioning, or it will rubber-band the player back.
	for tween in _player.get_tweens():
		tween.kill()
	_player.global_position = TileGrid.grid_to_world(data.player_start)

	# Player._ready already ran (children become ready before their parent)
	# and snapped the player to its *scene* position, so refresh the grid
	# state to match the new position.
	_player.current_grid_position = data.player_start
	_player.target_grid_position = data.player_start

	# If the player died on the previous map, cancel the death animation:
	# its animation_finished callback would queue_free() the player and
	# drain a life shortly after the rebuild.
	if _player._animationPlayer.animation == "die":
		_player._animationPlayer.play("idle")

	# Must come after apply_to(): setup() scans the scene for SnakePit nodes.
	TileGrid.setup(_terrain, _obstacles, _destructibles)

	var problems := gen.is_valid(data)
	_debug_label.text = "seed=%d  valid=%s\n\n%s" % [
		gen.last_seed, str(problems.is_empty()), gen.debug_ascii(data)]
	for problem in problems:
		push_warning("LevelGenerator: " + problem)


## Frees pits and snakes from a previous build. Uses immediate free() (not
## queue_free) so TileGrid.setup's SnakePit scan in _build_level() only sees
## the new pits.
func _clear_previous() -> void:
	for snake in _enemy_root.get_children():
		_enemy_root.remove_child(snake)
		snake.free()
	for pit in get_tree().current_scene.find_children("*", "SnakePit"):
		pit.get_parent().remove_child(pit)
		pit.free()
