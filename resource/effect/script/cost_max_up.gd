extends EffectBase
class_name CostMaxUp

@export var up_value : int = 1

func execute(_world_state : WorldState, _target_position : Vector2) -> bool:
	_world_state.cost_max += up_value
	return true
