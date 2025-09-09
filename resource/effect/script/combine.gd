extends NestedEffect
class_name Combine

@export var list : Array[EffectBase] = []

func execute(_world_state : WorldState, _target_position : Vector2) -> bool:
	if !can_execute(_world_state, _target_position): return false
	for effect in list:
		if is_instance_valid(effect):
			effect.execute(world_state, target_position)
	return true

func invalid() -> void:
	for effect in list:
		if is_instance_valid(effect):
			effect.invalid()
