extends Node2D
class_name BuffManager

var buff_list : Array[BuffBase]

func execute_buff(_world_state : WorldState) -> void:
	
	for buff in buff_list:
		if is_instance_valid(buff):
			if buff.can_execute(_world_state):
				buff.execute()
			
	
	clear_invalid_buff()

func clear_invalid_buff() -> void:
	buff_list = buff_list.filter(
		func(element):
		if is_instance_valid(element) && element.life > 0:
			return true
		else:
			return false
	)
