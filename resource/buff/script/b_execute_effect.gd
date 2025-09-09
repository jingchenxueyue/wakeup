extends BuffBase
class_name BExecuteEffect

@export var effect : EffectBase

var target_position : Vector2

func execute() -> void:
	if is_instance_valid(effect) && effect.can_execute(world_state, target_position):
		effect.execute(world_state, target_position)

func invalid() -> void:
	super()
	if is_instance_valid(effect) && effect.can_execute(world_state, target_position):
		effect.invalid()
