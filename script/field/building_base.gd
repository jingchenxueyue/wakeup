extends Node2D
class_name BuildingBase

signal building_collapsed(building : BuildingBase)

@onready var label_life : Label = Label.new()

var type : String = GE.BUILDING_BASE

var world_state : WorldState

var core_position : Vector2i
var life_max : int = 3
var life : int = life_max
var is_stationed : bool = false
var is_eroded : bool = false
var build_range : Array[Vector2i] = []
var build_tilemap : TileMapLayer
var build_decotation : TileMapLayer
var light_radius : float = 2.5
var light_area : Array[Vector2i]  = []

func _ready() -> void:
	add_child(label_life)
	life_update()

func get_light_area(field : PlaneArray) -> Array[Vector2i]:
	var tmp_range : Array[Vector2i] = build_range.duplicate()
	var tmp_pos : Vector2i = tmp_range.pop_back()
	var tmp_list : Array[Vector2i] = field.get_range(tmp_pos, light_radius)
	var result : Array[Vector2i] = tmp_list.duplicate()
	
	for pos in tmp_range:
		var tmp_off : Vector2i = pos - tmp_pos
		for element in tmp_list:
			if !result.has(element + tmp_off) && field.has_point(element + tmp_off):
				result.append(element + tmp_off)
	light_area = result
	return result

func collapse() -> void:
	if is_eroded:
		return
	is_eroded = true
	if type == GE.BUILDING_POWER_PLANT:
		ActionSp.show_message.call("发电站已被侵蚀，噩梦强度恢复。")
	else:
		ActionSp.show_message.call("建筑已被侵蚀。")
	for pos in build_range:
		world_state.get_field_node(pos).containment_level -= 1
	
	for pos in light_area:
		if is_stationed:
			var tmp_node : FieldNode = world_state.get_field_node(pos)
			tmp_node.light_level -= 1
	
	if is_stationed:
		ActionSp.fog_update.call(light_area)
	
	emit_signal("building_collapsed", self)

func hurted(damage : int) -> void:
	life = clamp(life - damage, 0, life_max)
	life_update()
	if life <= 0:
		collapse()

func turn_end() -> void:
	if is_stationed:
		life = clamp(life + 1, 0, life_max)

func life_update() -> void:
	label_life.text = str(life)
