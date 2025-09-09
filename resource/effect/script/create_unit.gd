extends CreateEntity
class_name CreateUnit

@export var is_enemy : bool = false ##生成的单位是否是敌方单位

func create_product(index : String) -> ProductBase:
	var _product : ProductBase = super(index)
	var _dictionary : Dictionary = return_db().get(index)
	if _product is Unit:
		_product.is_enemy = is_enemy
		_product.view_radius = _dictionary.get("VIEW_RADIUS")
		_product.move_distance_max = _dictionary.get("MOVE_DISTANCE_MAX")
		_product.move_distance_step = _dictionary.get("MOVE_DISTANCE_STEP")
		_product.atk = _dictionary.get("ATK")
		_product.atk_radius = _dictionary.get("ATK_RADIUS")
		_product.atk_count_max = _dictionary.get("ATK_COUNT_MAX")
		_product.atk_count = _product.atk_count_max
		_product.atk_vfx_name = _dictionary.get("ATK_VFX_NAME")
		_product.def = _dictionary.get("DEF")
		_product.effect.set("owner", _product)
		_product.action_over.connect(world_state._on_unit_action_over)
		for effect : EffectBase in _product.effect_list:
			effect.set("owner", _product)
	return _product

func return_db() -> Dictionary:
	if is_enemy:
		
		return CDB.edb
	else:
		return CDB.sdb
