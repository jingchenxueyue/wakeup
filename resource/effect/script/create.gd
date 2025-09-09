extends EffectBase
class_name Create

@export var product_index : int = 0
@export var create_spwaner : bool = false
@export var can_create_in_building : bool = true
@export var can_create_in_water : bool = false

var field_node : FieldNode

func execute(_world_state : WorldState, _target_position : Vector2) -> bool:
	
	if !super(_world_state, _target_position) : return false
	var tmp_product : ProductBase = create_product(str(product_index))
	tmp_product.world_state = _world_state
	tmp_product.target_position = _target_position
	tmp_product.map_position = _world_state.fog.local_to_map(_target_position)
	tmp_product.position = _world_state.fog.map_to_local(_world_state.fog.local_to_map(_target_position))
	tmp_product.is_spwaner = create_spwaner
	_world_state.product_layer.add_child(tmp_product)
	field_node.product_list.append(tmp_product)
	tmp_product.product_invalid.connect(field_node._on_product_invalid)
	return true
	
func create_product(index : String) -> ProductBase:
	var tmp_dic : Dictionary = return_db().get(index)
	var tmp_product : ProductBase = load(CDB.PRODUCT_PATH.format([tmp_dic.get("PRODUCT_PATH")])).new()
	tmp_product.product_index = product_index
	tmp_product.product_name = tmp_dic.get("NAME")
	tmp_product.texture = load(CDB.PRODUCT_TEXTURE_PATH.format([tmp_dic.get("TEXTURE_PATH")]))
	tmp_product.type = tmp_dic.get("TYPE")
	tmp_product.life_max = tmp_dic.get("LIFE_MAX")
	tmp_product.is_forever = tmp_dic.get("FOREVER")
	tmp_product.tag = CDB.cut_list_string(tmp_dic.get("TAG"))
	tmp_product.set("tip_text", tmp_dic.get("TIP_TEXT"))
	var tmp_list : Array[String] = CDB.cut_list_string(tmp_dic.get("EFFECT_PATH"))
	tmp_product.effect = load(CDB.EFFECT_PATH.format([tmp_list.pop_front()])).duplicate()
	if tmp_dic.get("DEATH_EFFECT_PATH"):
		tmp_product.death_effect = CDB.get_effect(tmp_dic.get("DEATH_EFFECT_PATH"))
	for effect : String in tmp_list:
		var tmp_eff : String = CDB.EFFECT_PATH.format([effect])
		
		tmp_product.effect_list.append(load(tmp_eff).duplicate())
	if tmp_product.has_method("add_button"):
		tmp_product.add_button()
	
	return tmp_product

func can_execute(_world_state : WorldState, _target_position : Vector2) -> bool:
	if !super(_world_state, _target_position): return false
	field_node = _world_state.field.get_point(_world_state.fog.local_to_map(_target_position))
	if field_node.road == GE.ROAD_WATER && !can_create_in_water:
		ActionSp.show_message.call("部署失败，该单位不可在无法通行处部署。")
		return false
	if !can_create_in_building && is_instance_valid(field_node.building):
		ActionSp.show_message.call("部署失败，该单位不可在建筑物所在处部署。")
		return false
	for product in field_node.product_list:
		if product.product_index == product_index:
			ActionSp.show_message.call("部署失败，指定节点位置已存在指定单位。")
			return false
	return true

func set_extra_data(_dictionary : Dictionary, _product : ProductBase) -> ProductBase:
	return _product

func return_db() -> Dictionary:
	return CDB.pdb
