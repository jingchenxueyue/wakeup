extends ActionBase
class_name FriendAction

func action() -> void:
	if owner.can_atk():
		owner.atk_enemy(action)
	elif owner.can_move():
		owner.move_by_step(action)
	else:
		owner.alert()
