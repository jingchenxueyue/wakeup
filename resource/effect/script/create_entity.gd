extends Create
class_name CreateEntity

func create_product(index : String) -> ProductBase:
	var tmp_product : Entity = super(index)
	
	tmp_product.enter_choose.connect(world_state._on_enter_choose)
	tmp_product.exit_choose.connect(world_state._on_exit_choose)
	
	
	return tmp_product
