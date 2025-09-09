extends TaskBase
class_name FriendArriveAt

func task_adjust(_world_state : WorldState) -> bool:
	
	for tmp_index in target_map_position_list.size():
		for tmp_position : Vector2i in target_map_position_list[tmp_index]:
			for product : ProductBase in _world_state.get_field_node(tmp_position).product_list:
				if product is Unit && !product.is_enemy:
					if event == "" && event_list.size() > 0:
						event = event_list[tmp_index]
					return true
	return false
