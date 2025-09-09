extends EffectBase
class_name HitProduct

@export var radius : int = 0
@export var damage : int = 4
@export var is_enemy : bool = true

func execute(_world_state : WorldState, _target_position : Vector2) -> bool:
	if !super(_world_state, _target_position):
		return false
	var result : bool = false
	var tmp_map_position : Vector2i = world_state.fog.local_to_map(_target_position)
	for tmp_position : Vector2i in world_state.field.get_range(tmp_map_position, radius, false):
		var tmp_node : FieldNode = world_state.get_field_node(tmp_map_position)
		for tmp_product in tmp_node.product_list:
			if tmp_product.is_enemy == is_enemy:
				tmp_product.hurted(damage)
				result = true
	
	return result
