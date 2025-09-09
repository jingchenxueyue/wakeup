extends Nightmare
class_name SilentEcho

@export_range(0, 100) var random_number : int = 50 ## 符合生成条件的网格在一步内生成新回想区域的概率，0为不可能，100为必定生成

var echo_reach : Array[Vector2i] ## 回想区域

func execute() -> void:
	var copy_list : Array[Vector2i] = echo_reach.duplicate()
	
	for pos in echo_reach:
		var tmp_node = world_state.get_field_node(pos)
		if tmp_node is FieldNode:
			tmp_node.nightmare_list.append(self)
			flowing_reach.append(pos)
			copy_list.erase(pos)
			tile_map.set_cell(pos, 0, Vector2i(0, 0))
	
	echo_reach = copy_list
	adjust_flowing()
	
	for pos in flowing_reach:
		if  world_state.get_field_node(pos).containment_level > 0:
			continue
		var tmp_list : Array[Vector2i] = []
		for neighbor in world_state.get_field_neighbors(pos, is_4_direction):
			
			if neighbor.nightmare_list.has(self):
				continue
			tmp_list.append(neighbor.pos)
		if !tmp_list.is_empty():
			if randi_range(1, 100) > random_number:
				continue
			var tmp_direction : Vector2i = world_state.get_field_node(pos).nightmare_flowing_direction
			var tmp_pos : Vector2i = Vector2i.ZERO
			if tmp_direction != Vector2i.ZERO && tmp_list.has(tmp_direction + pos):
				tmp_pos = tmp_direction + pos
			else:
				tmp_pos = tmp_list.pick_random()
			world_state.get_field_node(tmp_pos).nightmare_list.append(self)
			world_state.get_field_node(pos).nightmare_flowing_direction = tmp_direction
			echo_reach.append(tmp_pos)
			tile_map.set_cell(tmp_pos, 0, Vector2i(1, 0))
	hit_with_reach(congealed_reach + flowing_reach)
		
func erase_target_position(target_position) -> void:
	super(target_position)
	echo_reach.erase(target_position)
