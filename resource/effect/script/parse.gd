extends EffectBase
class_name Parse

## 解析噩梦一次，噩梦所上升的被解析值
@export var value : float = 25.0

func execute(_world_state : WorldState, _target_pos : Vector2) -> bool:
	if !super(_world_state, _target_pos):
		return false
	var tmp_node : FieldNode = world_state.get_field_node(world_state.fog.local_to_map(_target_pos))
	if tmp_node.nightmare_list.is_empty():
		ActionSp.show_message.call("指定位置不存在噩梦，位置：{0}".format([tmp_node.pos]))
		return false
	for nightmare in tmp_node.nightmare_list:
		nightmare.parsed_value += value
	return true
