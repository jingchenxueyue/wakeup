extends EffectBase
class_name CreateBuff

@export var buff_list : Array[BuffBase]
@export var is_execute_now : bool = false
@export var product_name : String = ""

func execute(_world_state : WorldState, _target_position : Vector2) -> bool:
	if !super(_world_state, _target_position): return false
	
	var tmp_list : Array[BuffBase] = []
	for buff in buff_list:
		tmp_list.append(buff.duplicate())
	for tmp_buff in tmp_list:
		tmp_buff.set("target_position", _target_position)
		tmp_buff.world_state = _world_state
		_world_state.buff_manager.buff_list.append(tmp_buff)
		if product_name == "":
			tmp_buff.owner = _world_state.buff_manager
		else:
			var tmp_node : FieldNode = _world_state.get_field_node(world_state.fog.local_to_map(_target_position))
			for product in tmp_node.product_list:
				if product.product_name == product_name:
					tmp_buff.owner = product
					product.buff_list.append(tmp_buff)
					break
	if is_execute_now:
		for buff in tmp_list:
			if buff.can_execute(_world_state):
				buff.execute()
		_world_state.buff_manager.clear_invalid_buff()
	return true
