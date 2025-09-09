extends Resource
class_name FieldNode

var pos : Vector2i
var building : BuildingBase
var road : String
var light_level : int = 0
var containment_level : int = 0
var nightmare_flowing_direction : Vector2i = Vector2i.ZERO
var product_list : Array[ProductBase] = []
var nightmare_list : Array[Nightmare] = []

func _on_product_invalid(_product : ProductBase) -> void:
	product_list.erase(_product)
	
