extends BuffBase
class_name BDrawCard

##抽卡张数
@export var count : int = 1

func execute() -> void:
	for i in count:
		ActionSp.draw_card.call()
		
	reduce_life()
