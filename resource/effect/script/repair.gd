extends EffectBase
class_name Repair

@export var value : int = 99
@export var radius : float = 0
@export var with_recharge : bool = false
@export var is_enemy : bool = false
@export_enum(GE.NONE,GE.TAG_PROJECT, GE.TAG_MACHINE, GE.TAG_HUMAN) var target_tag : String = GE.NONE

func execute(_world_state : WorldState, _target_position : Vector2) -> bool:
	if !super(_world_state, _target_position):
		return false
	for tmp_position in _world_state.field.get_range(_world_state.fog.local_to_map(_target_position), radius):
		var tmp_node : FieldNode = _world_state.get_field_node(tmp_position)
		for product in tmp_node.product_list:
			if !is_instance_valid(product):
				continue
			
			if target_tag == GE.NONE:
				product.healing(value)
				continue
			
			if product.tag.has(target_tag):
				product.healing(value)
				
				if product is Unit && with_recharge && product.is_enemy == is_enemy:
					product.recharge()
	
	return true

func can_execute(_world_state : WorldState, _target_position : Vector2) -> bool:
	if !super(_world_state, _target_position):
		return false
	var has_product : bool = false
	for tmp_position in _world_state.field.get_range(_world_state.fog.local_to_map(_target_position), radius):
		var tmp_node : FieldNode = world_state.get_field_node(tmp_position)
		
		if !tmp_node.product_list.is_empty():
			if target_tag == GE.NONE:
				has_product = true
				break
			for product in tmp_node.product_list:
				if product.tag.has(target_tag):
					has_product = true
					break
	if !has_product:
		ActionSp.show_message.call("指定范围内不存在可恢复的目标。")
	return has_product
