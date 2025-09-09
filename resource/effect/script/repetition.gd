extends NestedEffect
class_name Repetition

@export var repeat_count : int = 1

func execute(_world_state : WorldState, _target_position : Vector2) -> bool:
	if !super(_world_state, _target_position): return false
	for i in repeat_count - 1:
		next_effect.execute(world_state, target_position)
	return true
