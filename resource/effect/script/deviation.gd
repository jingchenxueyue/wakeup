extends NestedEffect
class_name Deviation ## 位置偏移

@export var deviation : Vector2i = Vector2i.ZERO

func execute_current(_world_state : WorldState, _target_position : Vector2) -> bool:
	var tmp_position : Vector2i = world_state.fog.local_to_map(_target_position) + deviation
	if world_state.map_rect.has_point(tmp_position):
		target_position = world_state.fog.map_to_local(tmp_position)
		return true
	return false
