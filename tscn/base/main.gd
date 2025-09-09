extends Node2D

signal game_continue

@export var level_pack : PackedScene
@export var nightmare_pack : PackedScene
@export var task_list : Array[TaskBase]

@onready var first_node: Node2D = $FirstNode
@onready var world_state: WorldState = $WorldState
@onready var camera: Camera2D = $Camera
@onready var fog: TileMapLayer = $Fog
@onready var sprite_fog: SpriteFog = $SpriteFog
@onready var mark_layer: MarkLayer = $MarkLayer
@onready var gui: CanvasLayer = $GUI
@onready var hand_card: Area2D = $GUI/HandCard
@onready var mark_2: Sprite2D = $Mark2
@onready var button_turn_over: Button = $GUI/ButtonTurnOver
@onready var label_cost: Label = $GUI/LabelCost
@onready var label: Label = $GUI/Label
@onready var label_mouse_position: Label = $GUI/LabelMousePosition
@onready var label_task: Label = $GUI/LabelMission
@onready var label_nightmare_strengh: Label = $GUI/LabelNightmareStrengh
@onready var label_prase_degree: Label = $GUI/LabelPraseDegree
@onready var label_wake_degree: Label = $GUI/LabelWakeDegree
@onready var ui_operation_tip: TextureRect = $GUI/UIOperationTip
@onready var ui_animation_turn_change: Control = $GUI/UIAnimationTurnChange
@onready var ui_event: UIEvent = $GUI/UIEvent
@onready var ui_final_panel: UIFinalPanel = $GUI/FinalPanel

var level : LevelBase
var nightmare : Nightmare
var field : PlaneArray
var field_astar : PlaneAstar

var node_information : String = ""
var gui_cost_text : String = ""
var wake_information : String = "在坐标{0}处使用类型为{1}的卡牌。"

var wake_complete_stack : Array[bool]

var focus_entity : Entity = null
var mouse_map_position : Vector2i = Vector2i.ZERO:
	set(value):
		if mouse_map_position != value:
			mouse_map_position = value
			if is_instance_valid(focus_entity) && focus_entity is Unit && oprate_state == OprateState.FIELD:
				focus_entity.map_target_position = value

enum OprateState{
	LOST,
	UI,
	NOMAL,
	HAND_CARD,
	USE_CARD,
	FIELD,
}

var oprate_state : OprateState = OprateState.LOST:
	set(value):
		oprate_state = value
		#if oprate_state == OprateState.NOMAL:
			#camera.can_observe = true
		#else:
			#camera.can_observe = false
var is_paused : bool = false

func _ready() -> void:
	
	init_map()
	init_camera()
	init_field()
	init_sprite_fog()
	init_worldstate()
	init_nightmare()
	init_enemies()
	init_handcard()
	init_turn()
	init_gui()
	init_event()
	ActionSp.show_message.call("初始化完成")
	oprate_state = OprateState.NOMAL
	world_state.turn_state = world_state.TurnState.START
	turn_state_change(turn_start)

func _physics_process(_delta: float) -> void:
	
	if mark_2.visible:
		var tmp_pos : Vector2 = fog.map_to_local(fog.local_to_map(get_global_mouse_position()))
		mark_2.global_position = tmp_pos
	
	mouse_map_position = fog.local_to_map(get_global_mouse_position())
	
	label_mouse_position.text = "当前坐标：{0}".format([mouse_map_position])
	
#region 初始化

func init_map() -> void:
	var tmp_level = level_pack.instantiate()
	if !tmp_level is LevelBase:
		printerr("关卡场景level_pack载入失败,场景不存在或无效。")
		return
	
	level = tmp_level
	level.show_behind_parent = true
	first_node.add_sibling(level)

func init_camera() -> void:
	camera.init_camera(level.map_rect, level.map_cell_size.x)

func init_field() -> void:
	if !is_instance_valid(level):
		printerr("场地field创建失败，关卡level不存在或无效。")
	
	field = PlaneArray.new(level.map_rect.size)
	field_astar = PlaneAstar.new(level.map_rect)
	for pos : Vector2i in level.map.get_used_cells():
		var tmp_field_node : FieldNode = FieldNode.new()
		var tmp_road : String = level.map.get_cell_tile_data(pos).get_custom_data("road")
		tmp_field_node.pos = pos
		tmp_field_node.road = tmp_road
		if tmp_road == GE.ROAD_WATER:
			field_astar._node(pos).solid = true
		if level.map.get_cell_tile_data(pos):
			tmp_field_node.road = level.map.get_cell_tile_data(pos).get_custom_data("road")
			add_fog(pos)
		
		field.set_point(pos, tmp_field_node)
	#初始化建筑相关，因为建筑不相邻，所以将所有的pos分成数个相邻的pos堆来区分不同的building
	var tmp_stack_list : Array[Array] = [[]]
	var tmp_building : BuildingBase = null
	var tmp_core_list : Array[Vector2i] = []
	for pos : Vector2i in level.building.get_used_cells():
		field.get_point(pos).containment_level += 1
		field_astar._node(pos).solid = true
		var is_new_pos : bool = true
		for stack in tmp_stack_list:
			for tmp_pos in stack:
				if (tmp_pos - pos).length() <= 1:
					stack.append(pos)
					is_new_pos = false
					break
		#如果该pos不与已分堆的所有pos相邻，证明这是一个新的building的一个pos，所以创建一个新堆和新building，将该pos加入其中
		if is_new_pos:
			tmp_stack_list.append([pos])
			tmp_building = BuildingBase.new()
			tmp_building.world_state = world_state
			tmp_building.build_tilemap = level.building
			tmp_building.build_decotation = level.building_decotation
			tmp_building.building_collapsed.connect(_on_building_collapsed)
			world_state.building_layer.add_child(tmp_building)
			
		#如果该pos是一个building的核心位置core_position,将该pos添加到tmp_core_list
		if level.building_decotation.get_cell_tile_data(pos):
			tmp_core_list.append(pos)
			
	#所有位置分堆完毕，获取新初始化好的所有building，分配所有core_position与pos堆
	for building : BuildingBase in world_state.building_layer.get_children():
		if !is_instance_valid(building) || !building is BuildingBase:
			return
		if !tmp_core_list.is_empty():
			var tmp_core : Vector2i = tmp_core_list.pop_back()
			building.core_position = tmp_core
			building.position = level.building.map_to_local(tmp_core)
			building.type = level.building.get_cell_tile_data(tmp_core).get_custom_data("building")
			if building.type == GE.BUILDING_POWER_PLANT:
				world_state.power_plant_list.append(building)
				building.life_max = 2
				building.life = 2
				building.life_update()
				
			elif building.type == GE.BUILDING_HQ:
				building.is_stationed = true
				
			elif building.type == GE.BUILDING_LIBRARY:
				pass
			elif building.type == GE.BUILDING_DATA_STATION:
				pass

		for stack in tmp_stack_list:
			if stack.has(building.core_position):
				var tmp_stack : Array[Vector2i] = []
				for pos in stack:
					tmp_stack.append(Vector2i(pos))
				building.build_range = tmp_stack
				for element in stack:
					field.get_point(element).building = building
				if !building.type == GE.BUILDING_HQ:
					continue
				for tmp_pos in building.get_light_area(field):
					
					field.get_point(tmp_pos).light_level += 1

func add_mark(_position_i : Vector2i, _color : Color) -> void:
	var tmp_sprite : Sprite2D = mark_layer.mark_pack.instantiate()
	var tmp_shader : ShaderMaterial
	tmp_sprite.position = fog.map_to_local(_position_i)
	if tmp_sprite.material is ShaderMaterial:
		tmp_shader = tmp_sprite.material
		tmp_shader.set_shader_parameter("_color", _color)
	mark_layer.add_child(tmp_sprite)

func init_sprite_fog() -> void:
	sprite_fog.fog_size = fog.get_used_rect().size * fog.tile_set.tile_size.x
	sprite_fog.init_sprite_fog()
	ActionSp.fog_update = fog_update
	

func add_fog(pos : Vector2i) -> void:
	fog.set_cell(pos, 0, Vector2i.ZERO)

func init_worldstate() -> void:
	world_state.map_rect = level.map_rect
	world_state.cell_size = level.map_cell_size
	world_state.field = field
	world_state.field_astar = field_astar
	world_state.fog = fog
	world_state.field_on_focus.connect(_on_field_on_focus)
	world_state.field_lost_focus.connect(_on_field_lost_focus)
	world_state.side_unit_action_over.connect(_on_turn_unit_action_over)
	task_update()
	
	fog_update(level.map.get_used_cells())

func init_nightmare() -> void:
	var tmp_nightmare_core : Vector2i = Vector2i.MAX
	nightmare = nightmare_pack.instantiate()
	level.add_sibling(nightmare)
	nightmare.prased_value_change.connect(_on_prased_value_change)
	label_nightmare_strengh.text = "当前噩梦强度：{0}".format([nightmare.strength_level])
	for pos : Vector2i in level.nightmare.get_used_cells():
		if level.nightmare.get_cell_tile_data(pos):
			if level.nightmare.get_cell_tile_data(pos).get_custom_data("is_core"):
				tmp_nightmare_core = pos
			level.nightmare.set_cell(pos)
			nightmare.tile_map.set_cell(pos, 0, Vector2i(0, 0))
			world_state.field.get_point(pos).nightmare_list.append(nightmare)
			nightmare.congealed_reach.append(pos)
	
	nightmare.strength_level = nightmare.strength_level_max - world_state.power_plant_list.size()
	nightmare.strength_level = max(1, nightmare.strength_level)
	
	nightmare.init_nightmare(world_state, tmp_nightmare_core)

func init_enemies() -> void:
	var tmp_create : CreateUnit = load("res://resource/effect/tres/final/create_enemy.tres")
	for pos in level.unit.get_used_cells():
		if level.unit.get_cell_tile_data(pos).get_custom_data("is_enemy"):
			tmp_create.is_enemy = true
		else:
			tmp_create.is_enemy = false
		tmp_create.product_index = level.unit.get_cell_tile_data(pos).get_custom_data("unit_index")
		tmp_create.execute(world_state, fog.map_to_local(pos))

func init_handcard() -> void:
	hand_card.world_state = world_state
	hand_card.mouse_entered.connect(_on_hand_card_mouse_entered)
	hand_card.mouse_exited.connect(_on_hand_card_mouse_exited)
	hand_card.unfocus_with_out_of_area.connect(_on_unfocus_with_out_of_area)

func init_turn() -> void:
	world_state.turn_count = 0
	button_turn_over.pressed.connect(_on_button_turn_over_pressed)
	

func init_gui() -> void:
	ActionSp.show_message = gui.show_message
	world_state.cost_max_update.connect(gui_cost_update)
	world_state.cost_update.connect(gui_cost_update)
	gui_cost_update()
	for tmp_list in task_list.front().target_map_position_list:
		for map_position in tmp_list:
			add_mark(map_position, Color.YELLOW)
	
	ui_final_panel.btn_retry.pressed.connect(_on_final_panel_retry_pressed)
	ui_final_panel.btn_quit.pressed.connect(_on_final_panel_quit_pressed)

func init_event() -> void:
	ui_event.world_state = world_state
	ui_event.target_position = Vector2(16,16)
	ui_event.event_hide_over.connect(_on_ui_event_hide_over)

#endregion

#region 回合转换

func turn_lost() -> void:
	world_state.turn_state = world_state.TurnState.LOST
	oprate_state = OprateState.LOST

func turn_start() -> void:
	world_state.turn_state = world_state.TurnState.START
	world_state.cost = clampi(world_state.cost + 1, 0, world_state.cost_max)
	world_state.turn_count += 1
	world_state.unit_recharge()
	label.text = "当前回合为第{0}回合".format([world_state.turn_count])
	hand_card.turn_start()
	await turn_change_ani()
	turn_state_change(turn_player)

func turn_player() -> void:
	world_state.turn_state = world_state.TurnState.PLAYER
	await turn_change_ani()
	world_state.set_entities(true)

func turn_friend() -> void:
	world_state.turn_state = world_state.TurnState.FRIEND
	await turn_change_ani()
	world_state.unit_action()

func turn_nightmare() -> void:
	world_state.turn_state = world_state.TurnState.NIGHTMARE
	await turn_change_ani()
	for tmp_count in nightmare.strength_level:
		nightmare.execute()
	turn_state_change(turn_enemy)

func turn_enemy() -> void:
	world_state.turn_state = world_state.TurnState.ENEMY
	await turn_change_ani()
	world_state.unit_action()

func _on_turn_unit_action_over(is_enemy : bool) -> void:
	if !is_enemy:
		turn_state_change(turn_nightmare)
	else:
		turn_state_change(turn_end)

func turn_end() -> void:
	world_state.turn_state = world_state.TurnState.END
	await turn_change_ani()
	
	while task_list.size() >= 1:
		if task_list.front().task_adjust(world_state):
			print("任务完成")
			if task_list.front().trigger_event():
				is_paused = true
			for mark in mark_layer.get_children():
				mark.queue_free()
			task_list.pop_front()
			if !task_list.is_empty():
				for tmp_list in task_list.front().target_map_position_list:
					for map_position in tmp_list:
						add_mark(map_position, Color.YELLOW)
			
		else:
			break
	if task_list.is_empty():
		ui_final_panel.is_win = true
		ui_final_panel.label.text = "任务完成"
		game_over()
		return
	
	task_update()
	
	if world_state.turn_count >= world_state.turn_count_max:
		ui_final_panel.is_win = false
		ui_final_panel.label.text = "任务失败，已超过前线通讯维持最大时限"
		game_over()
		return
	
	for product : ProductBase in world_state.product_layer.get_children():
		product.turn_end()
	for building : BuildingBase in world_state.building_layer.get_children():
		building.turn_end()
	hand_card.turn_end()
	turn_state_change(turn_start)

func turn_state_change(to_call : Callable) -> void:
	if is_paused:
		
		await game_continue
	
	var tmp_tween : Tween = create_tween()
	tmp_tween.tween_interval(0.05)
	tmp_tween.tween_callback(to_call)

func player_turn_over() -> void:
	world_state.set_entities(false)
	turn_state_change(turn_friend)

#endregion

#region 游戏视觉与动画相关

func fog_update(change_cell_list : Array[Vector2i]) -> void:
	var light_area : Array[Vector2i] = []
	var dark_area : Array[Vector2i] = []
	for pos in change_cell_list:
		if world_state.get_field_node(pos).light_level > 0:
			fog.set_cell(pos)
			light_area.append(pos)
		else:
			fog.set_cell(pos, 0, Vector2i.ZERO)
			dark_area.append(pos)
			
	sprite_fog.update_fog(light_area, true)
	sprite_fog.update_fog(dark_area, false)

#endregion

#region GUI相关

func gui_cost_update() -> void:
	var tmp_text : String = "费用：{0}/{1}".format([str(world_state.cost), str(world_state.cost_max)])
	label_cost.text = gui_cost_text + tmp_text

func wake_information_update() -> void:
	label_wake_degree.text = ""
	var degree_text_list : Array[String] = []
	degree_text_list.resize(nightmare.wake_degree_list.size())
	degree_text_list.fill(wake_information)
	
	for index in nightmare.wake_degree_list.size():
		var completed_text : String
		if index > wake_complete_stack.size() - 1:
			completed_text = "进行中。\n"
		else:
			completed_text = "已完成。\n"
		var tmp_format : Array = [nightmare.wake_position_list[index], nightmare.wake_type_list[index]]
		degree_text_list[index] = degree_text_list[index].format(tmp_format) + completed_text
	for index in nightmare.wake_degree_list.size():
		if nightmare.parsed_value >= nightmare.wake_degree_list[index]:
			label_wake_degree.text = label_wake_degree.text + degree_text_list[index]

func task_update() -> void:
	if !task_list.is_empty():
		label_task.text = "当前任务：{0}".format([task_list.front().task_context])

func turn_change_ani() -> void:
	ui_animation_turn_change.show_self(world_state.turn_count, world_state.turn_state)
	await ui_animation_turn_change.show_over

#endregion

func _draw() -> void:
	pass

func _input(event: InputEvent) -> void:
	if oprate_state == OprateState.FIELD:
		if event.is_action_released("mouse_left"):
			focus_entity._on_self_pressed()
		elif event.is_action_released("mouse_right"):
			if focus_entity is Unit:
				focus_entity.path_list.clear()
			focus_entity._on_self_pressed()

#region 游戏大状态转换

func adjust_wake(card : CardBase, target_position : Vector2i) -> void:
	var step : int = wake_complete_stack.size()
	if nightmare.wake_type_list[step] == card.type && nightmare.wake_position_list[step] == target_position:
		wake_complete_stack.append(true)
	else:
		wake_complete_stack.clear()
	wake_information_update()
	step = wake_complete_stack.size()
	if step >= nightmare.wake_degree_list.size():
		ui_final_panel.is_win = true
		game_over()

func game_over() -> void:
	turn_state_change(turn_lost)
	ui_final_panel.show()

#endregion

#region 信号连接函数

func is_state_valid(need_oprete_nomal : bool = true, need_player_turn : bool = true) -> bool:
	if need_oprete_nomal && oprate_state != OprateState.NOMAL:
		return false
	if need_player_turn && world_state.turn_state != world_state.TurnState.PLAYER:
		return false
	return true

func _on_hand_card_mouse_entered() -> void:
	if !is_state_valid(): return
	mark_2.visible = false
	oprate_state = OprateState.HAND_CARD
	hand_card.on_focus = true

func _on_hand_card_mouse_exited() -> void:
	if oprate_state != OprateState.HAND_CARD: return
	if hand_card.is_hold:
		mark_2.visible = true
		return
	oprate_state = OprateState.NOMAL
	hand_card.on_focus = false

func _on_unfocus_with_out_of_area(card : CardBase, target_position : Vector2, is_execute : bool) -> void:
	mark_2.visible = false
	oprate_state = OprateState.NOMAL
	if !is_state_valid(false): return
	if is_execute:
		card.effect.execute(world_state, target_position)
		adjust_wake(card, fog.local_to_map(target_position))

func _on_button_turn_over_pressed() -> void:
	
	if !is_state_valid(): return
	turn_state_change(turn_friend)

func _on_field_on_focus(_entity : Entity) -> void:
	if !is_state_valid(): return
	if _entity.is_enemy: return
	oprate_state = OprateState.FIELD
	if is_instance_valid(hand_card.hide_tween):
		hand_card.hide_tween.kill()
	
	hand_card.hide_tween = hand_card.create_tween()
	var tmp_tween : Tween = hand_card.hide_tween
	tmp_tween.tween_property(hand_card, "position", hand_card.hide_position, 0.2)
	tmp_tween.tween_property(hand_card, "on_focus", false, 0)
	
	focus_entity = _entity

func _on_field_lost_focus(_entity : Entity) -> void:
	if oprate_state != OprateState.FIELD: return
	oprate_state = OprateState.NOMAL
	if is_instance_valid(hand_card.hide_tween):
		hand_card.hide_tween.kill()
	hand_card.hide_tween = hand_card.create_tween()
	var tmp_tween : Tween = hand_card.hide_tween
	tmp_tween.tween_property(hand_card, "position", hand_card.default_position, 0.2)
	
	
	focus_entity = null

func _on_building_collapsed(building : BuildingBase) -> void:
	label_nightmare_strengh.text = "当前噩梦强度：{0}".format([nightmare.strength_level])
	if building.type == GE.BUILDING_POWER_PLANT:
		nightmare.strength_level += 1
		nightmare.strength_level = clampi(nightmare.strength_level, 1, nightmare.strength_level)
		
	if building.type == GE.BUILDING_HQ:
		ui_final_panel.label.text = "任务失败，前线指挥部已被侵蚀"
		ui_final_panel.is_win = false
		game_over()

func _on_prased_value_change(value : float) -> void:
	wake_information_update()
	label_prase_degree.text = "噩梦已解析：{0}%".format([value])

func _on_ui_event_hide_over() -> void:
	is_paused = false
	emit_signal("game_continue")

func _on_final_panel_retry_pressed() -> void:
	get_tree().reload_current_scene()

func _on_final_panel_quit_pressed() -> void:
	get_tree().quit()

#endregion
