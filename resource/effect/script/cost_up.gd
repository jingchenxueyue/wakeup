extends EffectBase
class_name CostUp

@export var up_value : int = 1

func execute(_world_state : WorldState, _target_position : Vector2) -> bool:
	_world_state.cost += up_value
	if _world_state.cost > _world_state.cost_max:
		_world_state.cost = _world_state.cost_max
	return true
