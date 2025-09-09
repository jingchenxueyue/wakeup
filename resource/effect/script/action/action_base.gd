extends EffectBase
class_name ActionBase

var owner : Unit

func can_execute(_world_state : WorldState, _target_position : Vector2) -> bool:
	if !is_instance_valid(owner):
		return false
	if !super(_world_state, _target_position):
		return false
	return true
	
func execute(_world_state : WorldState, _target_position : Vector2) -> bool:
	if !super(_world_state, _target_position):
		return false
	before_action()
	action()
	after_action()
	return true

func before_action() -> void:
	pass

func action() -> void:
	pass

func after_action() -> void:
	pass
