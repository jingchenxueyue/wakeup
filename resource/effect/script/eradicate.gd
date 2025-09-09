extends EffectBase
class_name Eradicate

@export var radius : int = 1

func execute(_world_state : WorldState, _target_position : Vector2) -> bool:
	if !super(_world_state, _target_position): return false
	var tmp_center : Vector2i = world_state.fog.local_to_map(_target_position)
	var tmp_list : Array[Vector2i] = world_state.field.get_range(tmp_center, radius)
	
	var tmp_nightmare_list : Array[Nightmare] = []
	for tmp_position in tmp_list:
		var tmp_node : FieldNode = world_state.get_field_node(tmp_position)
		for nightmare in tmp_node.nightmare_list:
			if !tmp_nightmare_list.has(nightmare):
				tmp_nightmare_list.append(nightmare)
			nightmare.erase_target_position(tmp_position)
		tmp_node.nightmare_list.clear()
	for nightmare in tmp_nightmare_list:
		nightmare.adjust_reach()
		
	return true
