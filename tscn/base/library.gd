extends Node2D
class_name Library

@export var card_pack : PackedScene

var stack : Array[CardBase] = []

func _ready() -> void:
	init_library()

func init_library() -> void:
	for i in [8]:
		var tmp_card : CardBase = card_pack.instantiate()
		tmp_card.index = str(i)
		tmp_card.visible = false
		add_child(tmp_card)
		stack.append(tmp_card)
	stack.shuffle()
