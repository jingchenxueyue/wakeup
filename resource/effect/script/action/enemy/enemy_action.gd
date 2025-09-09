extends ActionBase
class_name EnemyAction

func action() -> void:
	if !owner.find_path_over.is_connected(_on_find_path_over):
		owner.find_path_over.connect(_on_find_path_over)
	if owner.lock_target():
		owner.map_target_position = owner.target_product.map_position
		
	elif owner.path_list.is_empty():
		var tmp_range : Array[Vector2i] = world_state.field_astar.find_move_range(owner.map_position, 1.0, true)
		tmp_range.erase(owner.map_position)
		owner.map_target_position = tmp_range.pick_random()
	else:
		_on_find_path_over()

func _on_find_path_over() -> void:
	if owner.can_atk():
		owner.atk_enemy(action)
	elif owner.can_move():
		owner.move_by_step(action)
	else:
		owner.alert()
