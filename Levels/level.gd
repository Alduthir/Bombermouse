extends Node2D

@onready var _terrain : TileMapLayer = %Terrain
@onready var _obstacles : TileMapLayer = %Obstacles
@onready var _destructibles : TileMapLayer = %Destructibles

func _ready() -> void:
	TileGrid.setup(_terrain, _obstacles, _destructibles)
