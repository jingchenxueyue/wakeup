extends Node2D
class_name LevelBase

@export var nightmare_core_position : Vector2i

@onready var map: TileMapLayer = $Map
@onready var building: TileMapLayer = $Building
@onready var building_decotation: TileMapLayer = $BuildingDecotation
@onready var light_area: TileMapLayer = $LightArea
@onready var nightmare: TileMapLayer = $Nightmare
@onready var unit: TileMapLayer = $Unit


var map_rect : Rect2i
var map_cell_size : Vector2

func _ready() -> void:
	map_rect = map.get_used_rect()
	map_cell_size = map.tile_set.tile_size
