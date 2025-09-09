extends TaskBase
class_name HoldPosition

@export var hold_turn_count_max : int = 2
@export var can_pause : bool = false
@export var is_enemy : bool = false
@export_enum(GE.TAG_HUMAN, GE.TAG_MACHINE, GE.TAG_MATERIAL, GE.NONE) var target_tag : String = "HUMAN"

var hold_turn_count : int = 0

func task_adjust(_world_state : WorldState) -> bool:
	var tmp_result : bool = false
	var tmp_area_index : int = 0
	for tmp_index in target_map_position_list.size():
		for map_position : Vector2i in target_map_position_list[tmp_index]:
			for tmp_product : ProductBase in _world_state.get_field_node(map_position).product_list:
				if tmp_product.tag.has(target_tag) && tmp_product.is_enemy == is_enemy:
					if tmp_area_index != tmp_index:
						hold_turn_count = 0
						tmp_area_index = tmp_index
					hold_turn_count += 1
					tmp_result = true
					break
			if tmp_result:
				break
		if tmp_result:
			break
	
	if hold_turn_count > hold_turn_count_max:
		hold_turn_count = 0
		if event == "":
			event = event_list[tmp_area_index]
		return true
	
	return false
