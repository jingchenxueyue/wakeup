extends Node2D
class_name WorldState

signal field_on_focus(entity : Entity)
signal field_lost_focus(entity : Entity)
signal cost_max_update
signal cost_update
signal side_unit_action_over(is_enemy : bool)

@onready var product_layer: Node2D = $ProductLayer
@onready var buff_manager: BuffManager = $BuffManager
@onready var building_layer: Node2D = $BuildingLayer
@onready var path_layer: TileMapLayer = $PathLayer

var map_rect : Rect2i
var cell_size : Vector2 = Vector2(32, 32)
var field : PlaneArray
var field_astar : PlaneAstar
var fog : TileMapLayer
var astar_thread : Thread = Thread.new()
var astar_mutex : Mutex = Mutex.new()

var turn_count : int = 0
var turn_count_max : int = 20
var power_plant_list : Array[BuildingBase] = []

var action_index : int = 0
var unit_friend_list : Array[Unit] = []
var unit_enemy_list : Array[Unit] = []

var turn_state : TurnState = TurnState.LOST:
	set(value):
		if turn_state != value:
			turn_state = value
			execute_buff()

var cost_max : int = 7:
	set(value):
		if cost_max != value:
			cost_max = value
			emit_signal("cost_max_update")
var cost : int = 2:
	set(value):
		if cost != value:
			cost = value
			emit_signal("cost_update")

enum TurnState{
	LOST,##玩家失去控制时的状态
	START,
	PLAYER,
	FRIEND,
	NIGHTMARE,
	ENEMY,
	END
}

func get_field_node(field_position : Vector2i) -> Variant:
	if !field.has_point(field_position): return null
	return field.get_point(field_position)

func get_field_neighbors(field_position : Vector2i, is_4_direction : bool = true) -> Array:
	var result : Array = []
	var tmp_list : Array = [-1, 0, 1]
	for x in tmp_list:
		for y in tmp_list:
			if x == 0 && y == 0 : continue
			if is_4_direction && (abs(x) + abs(y) == 2): continue
			var tmp_node = get_field_node(field_position + Vector2i(x, y))
			if is_instance_valid(tmp_node): result.append(tmp_node)
	return result

func set_entities(can_pressed : bool) -> void:
	for child in product_layer.get_children():
		if child is Entity:
			child.button_self.disabled = !can_pressed

func execute_buff() -> void:
	buff_manager.execute_buff(self)

func unit_recharge() -> void:
	var tmp_list : Array[Unit] = []
	tmp_list.append_array(unit_friend_list)
	tmp_list.append_array(unit_enemy_list)
	for unit in tmp_list:
		unit.recharge()

func unit_action() -> void:
	match turn_state:
		TurnState.FRIEND:
			if !unit_friend_list.is_empty():
				unit_friend_list.front().action()
			else:
				emit_signal("side_unit_action_over", false)
		TurnState.ENEMY:
			if !unit_enemy_list.is_empty():
				unit_enemy_list.front().action()
			else:
				emit_signal("side_unit_action_over", true)
		_:
			printerr("错误，在未知游戏状态调用了该方法。")

func _exit_tree() -> void:
	if is_instance_valid(astar_thread) && astar_thread.is_started():
		astar_thread.wait_to_finish()

func _on_enter_choose(entity : Entity) -> void: ## 地图上的某单位进入指令选择状态。
	emit_signal("field_on_focus", entity)
	set_entities(false)
	entity.button_self.disabled = true

func _on_exit_choose(_entity : Entity) -> void: ## 地图上的某单位退出指令选择状态。
	emit_signal("field_lost_focus", _entity)
	set_entities(true)

func _on_unit_action_over(is_enemy : bool) -> void:
	action_index += 1
	var tmp_list : Array[Unit]
	if !is_enemy:
		tmp_list = unit_friend_list
	else:
		tmp_list = unit_enemy_list
	if action_index + 1 >= tmp_list.size():
		action_index = 0
		emit_signal("side_unit_action_over", is_enemy)
		return
	else:
		tmp_list[action_index].action()
