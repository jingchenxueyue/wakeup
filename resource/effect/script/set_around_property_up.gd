extends EffectBase
##将半径radius圆形范围内所有节点指定属性（int类型）的值增加size
class_name SetAroundPropertyUp
@export var target_property : String
@export var size : int = 1
@export var radius : int = 3

var tilemap : TileMapLayer
var effect_area : Array[Vector2i] = []

func execute(_world_state : WorldState, _target_position : Vector2) -> bool:
	if !super(_world_state, _target_position) : return false
	tilemap = _world_state.fog
	var tmp_pos : Vector2i = tilemap.local_to_map(_target_position)
	if _world_state.field.has_point(tmp_pos):
		effect_area = _world_state.field.get_range(tmp_pos, radius)
		
		for pos in effect_area:
			var tmp_field_node : FieldNode = _world_state.field.get_point(pos)
			var tmp_property = tmp_field_node.get(target_property)
			if tmp_property is int:
				tmp_field_node.set(target_property, tmp_property + size)
				after_set_property(tmp_field_node)
				
	all_set_over()
	return true

func invalid() -> void:
	if !is_instance_valid(tilemap) : return
	for pos in effect_area:
		var tmp_field_node : FieldNode = world_state.field.get_point(pos)
		var tmp_property = tmp_field_node.get(target_property)
		if tmp_property is int:
			tmp_field_node.set(target_property, tmp_property - size)
			after_set_property(tmp_field_node)
	
	all_set_over()

func after_set_property(_field_node : FieldNode) -> void:
	pass

func all_set_over() -> void:
	pass
