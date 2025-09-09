extends EffectBase
class_name GenerateCard

@export var card_index : int = 0

func execute(_world_state : WorldState, _target_position : Vector2) -> bool:
	if !super(_world_state, _target_position):
		return false
	ActionSp.generate_card.call(card_index)
	return true
