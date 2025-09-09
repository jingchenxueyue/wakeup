extends EffectBase
class_name NestedEffect

@export var next_effect : EffectBase

func execute(_world_state : WorldState, _target_position : Vector2) -> bool:
	if !super(_world_state, _target_position): return false
	if execute_current(world_state, target_position):
		if is_instance_valid(next_effect):
			if next_effect.execute(world_state, target_position):
				return true
	return false

func execute_current(_world_state : WorldState, _target_position : Vector2) -> bool:
	return true
