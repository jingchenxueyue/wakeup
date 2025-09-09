extends Resource
class_name EffectBase

@export var effect_text : String = "默认效果"

var world_state : WorldState
var target_position : Vector2

func execute(_world_state : WorldState, _target_position : Vector2) -> bool:
	if can_execute(_world_state, _target_position):
		return true
	return false

func can_execute(_world_state : WorldState, _target_position : Vector2) -> bool:
	var tmp_map_vector : Vector2i = _world_state.fog.local_to_map(_target_position)
	if !_world_state.field.has_point(tmp_map_vector):
		ActionSp.show_message.call("超出地图范围。")
		return false
	
	world_state = _world_state
	target_position = _target_position
	return true

func invalid() -> void:
	pass
