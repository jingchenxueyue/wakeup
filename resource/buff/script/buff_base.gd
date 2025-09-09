extends Resource
class_name BuffBase

##游戏状态与顺序LOST, START, PLAYER, FRIEND, NIGHTMARE, ENEMY, END
@export var execute_state : int = 0
##游戏状态与顺序LOST, START, PLAYER, FRIEND, NIGHTMARE, ENEMY, END
@export var invalid_state : int = 0
@export var is_forever : bool = false
@export var life : int = 1

var world_state : WorldState
var owner

func execute() -> void:
	pass
	
func can_execute(_world_state : WorldState) -> bool:
	if is_instance_valid(_world_state):
		world_state = _world_state
		if world_state.turn_state == execute_state && life > 0:
			return true
	return false

func can_invalid(_world_state : WorldState) -> bool:
	if is_instance_valid(_world_state):
		world_state = _world_state
		if world_state.turn_state == invalid_state:
			return true
	return false

func reduce_life() -> void:
	if is_forever: return
	life -= 1
	if life <= 0:
		invalid()

func invalid() -> void:
	life = 0
