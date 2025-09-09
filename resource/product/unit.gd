extends Entity
class_name Unit

signal find_path_over
signal action_over(is_enemy : bool)

var view_range : Array[Vector2i] = []
var view_radius : float = 3.5
var atk : int = 1
var atk_radius : float = 1.0
var atk_count_max : int = 1
var atk_count : int = atk_count_max
var atk_vfx_name : String = VFX.VFX_HIT
var def : int = 0
var move_distance_max : float = 3.0
var move_distance : float = move_distance_max
var move_distance_step : float = 1.0

var path_list : Array[Vector2i] = []
var map_target_position : Vector2i:
	set(value):
		if !world_state.field.has_point(value):
			
			emit_signal("find_path_over")
		elif map_target_position == value:
			
			emit_signal("find_path_over")
		else:
			map_target_position = value
			if !world_state.astar_thread.is_started():
				world_state.astar_thread.start(find_path.bind(value))

func _init() -> void:
	press_count = INF
	is_act_at_once = false

func _ready() -> void:
	super()
	view_range = world_state.field.get_range(map_position, view_radius)
	view_light_area_update(true)
	if is_enemy:
		world_state.unit_enemy_list.append(self)
	else:
		world_state.unit_friend_list.append(self)
		

func _exit_tree() -> void:
	if is_enemy:
		world_state.unit_enemy_list.erase(self)
	else:
		world_state.unit_friend_list.erase(self)

func hurted(damage : int) -> void:
	life = clamp(life - (damage - def), 0, life_max)
	if life <= 0:
		death()

func action() -> void:
	if is_instance_valid(effect) && effect.can_execute(world_state, map_position):
		effect.execute(world_state, map_position)

func find_path(_target_position : Vector2i) -> void:
	
	world_state.astar_mutex.lock()
	path_list.clear()
	path_list = world_state.field_astar.find_path(map_position, _target_position)
	world_state.astar_mutex.unlock()
	call_deferred("find_done")
	

func find_done() -> void:
	world_state.astar_thread.wait_to_finish()
	
	if !path_list.is_empty():
		path_list.pop_front()
	var tmp_path_tile : TileMapLayer = world_state.path_layer
	var tmp_path_point : Vector2i = map_position
	var tmp_move_distance : float = move_distance_max
	tmp_path_tile.clear()
	for point : Vector2i in path_list:
		var direction : Vector2i = point - tmp_path_point + Vector2i(1, 1)
		tmp_path_point = point
		if move_distance_step <= tmp_move_distance:
			tmp_move_distance -= move_distance_step
			world_state.path_layer.set_cell(point, 0, direction)
		else:
			world_state.path_layer.set_cell(point, 1, direction)
	if !path_list.is_empty():
		var tmp_id : int = world_state.path_layer.get_cell_source_id(path_list.back())
		world_state.path_layer.set_cell(path_list.back(), tmp_id, Vector2i.ONE)
	
	emit_signal("find_path_over")

func lock_target() -> bool:
	var lock_success : bool = false
	for pos in view_range:
		for product : ProductBase in world_state.get_field_node(pos).product_list:
			if product.is_enemy != is_enemy:
				if !is_instance_valid(target_product):
					target_product = product
				elif target_product == product:
					pass
				else:
					if (pos - map_position).length() < (target_product.map_position - map_position).length():
						target_product = product
				lock_success = true
				
	return lock_success

func can_atk() -> bool:
	if atk_count <= 0:
		return false
	if !lock_target():
		return false
	
	return true if (target_product.map_position - map_position).length() <= atk_radius else false

func can_move() -> bool:
	if path_list.is_empty():
		
		return false
	if move_distance_step > move_distance:
		
		return false
	for product in world_state.get_field_node(path_list.front()).product_list:
		if product is Entity:
			
			return false
	
	return true

func atk_enemy(finish_call : Callable) -> void:
	target_product.hurted(atk)
	
	atk_count -= 1
	var tmp_vfx : VFX = GV.vfx.duplicate()
	var tmp_pos : Vector2 = Vector2.RIGHT * world_state.cell_size.x
	var tmp_rotation : float = tmp_pos.angle_to(target_product.position - position)
	tmp_vfx.position = tmp_pos.rotated(tmp_rotation)
	tmp_vfx.rotation = tmp_rotation
	add_child(tmp_vfx)
	tmp_vfx.play(atk_vfx_name)
	await tmp_vfx.animation_finished
	tmp_vfx.queue_free()
	finish_call.call_deferred()
	
	return

func move_by_step(finish_call : Callable) -> Tween:
	if !can_move():
		return null
	
	var move_tween : Tween = create_tween()
	var tmp_scale : float = 1.0
	var move_ani_delay : float = 0.4
	move_distance -= move_distance_step * (path_list.front() - map_position).length()
	
	var tmp_position : Vector2 = world_state.fog.map_to_local(path_list.front())
	var tmp_map_position : Vector2i = path_list.pop_front()
	tmp_scale = (tmp_map_position - map_position).length()
	
	world_state.get_field_node(map_position).product_list.erase(self)
	
	world_state.get_field_node(tmp_map_position).product_list.append(self)
	
	map_position = tmp_map_position
	view_light_area_update(false)
	view_range.clear()
	view_range = world_state.field.get_range(tmp_map_position, view_radius)
	view_light_area_update(true)
	
	if world_state.get_field_node(map_position).light_level <= 0:
		move_ani_delay = 0.0
	move_tween.tween_interval(move_ani_delay)
	move_tween.tween_property(self, "position", tmp_position, move_ani_delay * tmp_scale)
	move_tween.tween_callback(finish_call)
	
	for product : ProductBase in world_state.get_field_node(map_position).product_list:
		if product == self: continue
		if product.tag.has(GE.TAG_MATERIAL) && product.is_enemy == is_enemy:
			product.effect.execute(world_state, product.position)
			if !product.is_forever:
				product.hurted(99)
	
	return move_tween

func alert() -> void:
	world_state.path_layer.clear()
	emit_signal("action_over", is_enemy)

func death() -> void:
	super()
	view_light_area_update(false)

func recharge() -> void:
	move_distance = move_distance_max
	atk_count = atk_count_max

func view_light_area_update(is_saw : bool) -> void:
	if is_enemy : return
	for pos in view_range:
		var tmp_value : int = 1 if is_saw else -1
		world_state.get_field_node(pos).light_level += tmp_value
	
	ActionSp.fog_update.call(view_range)
