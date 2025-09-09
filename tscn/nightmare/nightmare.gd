extends Node2D
class_name Nightmare

signal prased_value_change(value : float)

@onready var tile_map: TileMapLayer = $TileMapLayer

@export var nightmare_index : int
@export var nightmare_name : String
@export var is_4_direction : bool = true
@export var damage : int = 1
@export var strength_level_max : int = 3
@export var wake_degree_list : Array[int]

var wake_position_list : Array[Vector2i] = []
var wake_type_list : Array[String] =[]

var world_state : WorldState
var core_position : Vector2i
var strength_level : int = strength_level_max
var parsed_value : float = 0.0:
	set(value):
		parsed_value = value
		emit_signal("prased_value_change", parsed_value)
## 四周已经是污染网格的网格的集合，即实质污染区域
var congealed_reach : Array[Vector2i] = []
## 四周仍有至少一个未污染网格的网格的集合，即污染边缘区域
var flowing_reach : Array[Vector2i]  = []


func _ready() -> void:
	pass

func init_nightmare(_world_state : WorldState, _core_position : Vector2i) -> void:
	world_state = _world_state
	core_position = _core_position
	adjust_reach()
	set_wake_mission()

func execute() -> void:
	
	var tmp_reach : Array[Vector2i] = congealed_reach + flowing_reach
	ActionSp.show_message.call("噩梦正在蔓延。")
	hit_with_reach(tmp_reach)

func hit_with_reach(reach : Array[Vector2i]) -> void:
	var tmp_building_list : Array[BuildingBase] = []
	var tmp_product_list : Array[ProductBase] = []
	for pos in reach:
		var tmp_node : FieldNode = world_state.get_field_node(pos)
		if is_instance_valid(tmp_node.building) && !tmp_building_list.has(tmp_node.building):
			tmp_building_list.append(tmp_node.building)
		if !tmp_node.product_list.is_empty():
			for element in tmp_node.product_list:
				if !tmp_product_list.has(element):
					tmp_product_list.append(element)
	
	for building in tmp_building_list:
		building.hurted(damage)
	for product in tmp_product_list:
		product.hurted(damage)

func set_wake_mission() -> void:
	var tmp_reach : Array[Vector2i] = congealed_reach
	tmp_reach.append_array(flowing_reach)
	for i in wake_degree_list.size() - 1:
		wake_position_list.append(tmp_reach.pick_random())
		wake_type_list.append([GE.TYPE_CONTAINMENT, GE.TYPE_DETECT, GE.TYPE_ERADICATION, GE.TYPE_SUPPORT].pick_random())
	wake_position_list.append(core_position)
	wake_type_list.append(GE.TYPE_ERADICATION)

func adjust_reach() -> void:
	for pos in congealed_reach:
		if !is_congealed(pos):
			flowing_reach.append(pos)
	congealed_reach = congealed_reach.filter(
		func(pos):
			return !flowing_reach.has(pos)
	)

func is_congealed(pos : Vector2i) -> bool:
	
	for tmp_node in world_state.get_field_neighbors(pos, is_4_direction):
		if tmp_node is FieldNode && !tmp_node.nightmare_list.has(self):
			return false
	return true

func adjust_flowing() -> Array[Vector2i]:
	var tmp_list : Array[Vector2i] = []
	for pos in flowing_reach:
		if is_congealed(pos):
			tmp_list.append(pos)
	congealed_reach.append_array(tmp_list)
	for pos in tmp_list:
		flowing_reach.erase(pos)
	return tmp_list

func erase_target_position(target_position : Vector2i) -> void:
	congealed_reach.erase(target_position)
	flowing_reach.erase(target_position)
	tile_map.set_cell(target_position)
