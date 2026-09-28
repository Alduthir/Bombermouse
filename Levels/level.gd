extends Node2D

@onready var _terrain : TileMapLayer = %Terrain
@onready var _obstacles : TileMapLayer = %Obstacles
@onready var _destructibles : TileMapLayer = %Destructibles

var game_over_scene := preload("res://UI/GameOver.tscn")
func _ready() -> void:
	TileGrid.setup(_terrain, _obstacles, _destructibles)
