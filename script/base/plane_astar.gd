extends RefCounted
class_name PlaneAstar

#平面二维数组的A*寻路算法的实现，
#注意，该类是基于PlaneArray类实现，
#脱离PlaneArray类将无法工作与运行，并引发不可预计的后果。

class Anode extends  RefCounted:
	var solid : bool = false:
		set(value):
			solid = value
			if solid:
				road_ability = Vector4i.ONE
				def_level = Vector4i.ONE * 2
				sgh_level = Vector4i.ONE * 2
	var road_ability : Vector4i = Vector4i(0, 0, 0, 0)##可通行性
	##x,y,z,w值分别代表上，右，下，左方位上的通行性
	##对应位置上0为可通行，1为不可通行，
	##注意，该属性表示的是！！“从其他节点移动到该节点时的通行性”！！
	##而不是“从这个节点移动到其他节点的通行性”，
	##该属性主要用于制造单向通行的地形。
	var weight_scale : float = 1.0
	var def_level : Vector4i = Vector4i.ZERO##节点的防御等级
	##x,y,z,w值分别代表上，右，下，左方位上的防御等级
	##对应位置上0为无防御，1为半防御，2为全防御
	##注意，该属性表示的是！！“从其他节点指向该节点时的防御等级”！！
	##而不是“从这个节点指向其他节点的防御等级”，
	##该属性主要用于制造掩体地形。
	var sgh_level : Vector4i = Vector4i.ZERO##节点的可见等级
	##x,y,z,w值分别代表上，右，下，左方位上的可见度等级
	##对应位置上0为完全可见，1为隐约可见，2为不可见
	##注意，该属性表示的是！！“从其他节点看向该节点时的可见度等级”！！
	##而不是“从这个节点看向其他节点的可见度等级”，
	##该属性主要用于视野机制。
	
	var g : float = 0.0: ##已经行走的距离
		set(value):
			g = value
			f = g + h
	var h : float = 0.0: ##估计还剩的距离
		set(value):
			h = value
			f = g + h
	var f : float = 0.0 ##g + h
	var parent_vector : Vector2i = Vector2i.ZERO
	var in_gone : bool = false:
		set(value):
			in_gone = value
			if in_gone: in_next = false
	var in_next : bool = false

enum diagonal_mode{
	MANHATTAN,
	UNLIMITED,
	BREAK_WATER,
	NO_CROSS
}

enum heuristic_mode{
	EUCLIDEAN,
	MANHATTAN,
	OCTILE,
	CHEBYSHEV
}

var region : Rect2i = Rect2i(0, 0, 0, 0)
var grid : PlaneArray = PlaneArray.new()
var diagonal := diagonal_mode.BREAK_WATER
var heuristic := heuristic_mode.EUCLIDEAN
static var step_len : int = 10
static var diag_len : int = 14
var test_mode : bool = false


func _init(_region : Rect2i = Rect2i(0, 0 ,0, 0)) -> void:
	region = _region
	grid.origin = region.position
	grid.resize(region.size)
	for x in region.size.x:
		for y in region.size.y:
			grid.set_value(Vector2i(x, y), Anode.new())

func node_all_reset(vector : Vector2i) -> void:
	var tmp_node = _node(vector)
	tmp_node.solid = false
	tmp_node.road_ability = Vector4i.ZERO
	tmp_node.weight_scale = 1.0
	tmp_node.def_level = Vector4i.ZERO
	node_ghf_reset(vector)

func node_ghf_reset(vector : Vector2i) -> void:
	var tmp_node = _node(vector)
	tmp_node.g = 0.0
	tmp_node.h = 0.0
	tmp_node.parent_vector = Vector2i.ZERO
	tmp_node.in_gone = false
	tmp_node.in_next = false
	return

func set_point_solid(vector : Vector2i, is_solid : bool) -> void:
	_node(vector).solid = is_solid

func _node(_pos : Vector2i) -> Anode:
	return grid.get_point(_pos)

func find_nearest_valid_point(start : Vector2i, target : Vector2i) -> Vector2i:
	var tmp_vec : Vector2i = target
	if region.size == Vector2i.ZERO:
		print_debug("错误，A*寻路的范围为空")
		return start
	
	tmp_vec.x = clampi(target.x, region.position.x, region.position.x + region.size.x - 1)
	tmp_vec.y = clampi(target.y, region.position.y, region.position.y + region.size.y - 1)
	
	var tmp_node : Anode = grid.get_point(tmp_vec)
	if !tmp_node.solid: return tmp_vec
	
	var offset : Vector2i = tmp_vec - start
	var _x : int = offset.x
	var _y : int = offset.y
	
	while tmp_vec != start:
		if abs(offset.x) == abs(offset.y):
			if offset.x % 2 == 0:
				tmp_vec.x = move_toward(tmp_vec.x, start.x, 1) as int
			else:
				tmp_vec.y = move_toward(tmp_vec.y, start.y, 1) as int
			
		if abs(offset.x) > abs(offset.y):
			tmp_vec.x = move_toward(tmp_vec.x, start.x, 1) as int
		else:
			tmp_vec.y = move_toward(tmp_vec.y, start.y, 1) as int
		offset = tmp_vec - start
		if !grid.get_point(tmp_vec).solid: break
		
	if tmp_vec == start: return start
	
	return tmp_vec

func is_walkable(move_direction : Vector2i, road_ab: Vector4i) -> bool:
	if move_direction.y > 0 && road_ab.x > 0: return false
	if move_direction.y < 0 && road_ab.z > 0: return false 
	if move_direction.x > 0 && road_ab.w > 0: return false
	if move_direction.x < 0 && road_ab.y > 0: return false
	return true

func is_enterable(move_drt : Vector2i, grid_vector : Vector2i) -> bool:
	if !grid.has_point(grid_vector): return false
	var tmp_node : Anode = _node(grid_vector)
	var road_ab : Vector4i = tmp_node.road_ability
	var can_move : bool = is_walkable(move_drt, road_ab)
	if move_drt.length_squared() > 1:
		var cpt_x : Vector2i = Vector2i(move_drt.x, 0)
		var cpt_y : Vector2i = Vector2i(0, move_drt.y)
		var cpt_x_b : bool = is_walkable(cpt_x, _node(grid_vector - cpt_x).road_ability)
		var cpt_y_b : bool = is_walkable(cpt_y, _node(grid_vector - cpt_y).road_ability)
		can_move = cpt_x_b && cpt_y_b && can_move
	return can_move

func cal_h(_pos : Vector2i, end : Vector2i) -> int:
	var tmp : Vector2i = end - _pos
	tmp.x = abs(tmp.x)
	tmp.y = abs(tmp.y)
	if heuristic == heuristic_mode.EUCLIDEAN:
		return floori(tmp.length() * step_len)
	if heuristic == heuristic_mode.MANHATTAN:
		return (tmp.x + tmp.y) * step_len
	if heuristic == heuristic_mode.OCTILE:
		var off_len : int = diag_len - step_len
		return tmp.x * step_len + off_len * tmp.y if tmp.x > tmp.y else tmp.x * off_len + tmp.y  * step_len
	if heuristic == heuristic_mode.CHEBYSHEV:
		return (tmp.x if tmp.x > tmp.y else tmp.y) *step_len
	return 0

func find_path(start : Vector2i, end : Vector2i) -> Array[Vector2i]:
	var gone_list : Array[Vector2i] = []
	var next_list : Array[Vector2i] = []
	var path : Array[Vector2i] = []
	var f_min_vector : Vector2i = start
	
	#如果目标节点无效或目标节点是实体，则寻找最近的有效节点
	if !grid.has_point(end) || _node(end).solid:
		end = find_nearest_valid_point(start, end)
	#如果找不到有效的目标节点，返回空数组
	if end == start: return []
	next_list.append(start)
	_node(start).in_next = true
	_node(start).h = cal_h(start, end)
	
	while !next_list.is_empty():
		
		var tmp_list : Array[Vector2i] = []
		var tmp_index : int = 0
		
		#寻找next_list中f值最小的节点
		f_min_vector = next_list.front()
		for _index in next_list.size():
			
			if _node(next_list[_index]).f < _node(f_min_vector).f:
				f_min_vector = next_list[_index]
				tmp_index = _index
			elif _node(next_list[_index]).f == _node(f_min_vector).f:
				if _node(next_list[_index]).g > _node(f_min_vector).g:
					f_min_vector = next_list[_index]
					tmp_index = _index
		
		#f_min_vector是next_list中f值最小的节点，
		#将其添加至gone_list,从next_list中删除.
		gone_list.append(f_min_vector)
		_node(f_min_vector).in_gone = true
		next_list.pop_at(tmp_index)
		if f_min_vector == end : break
		var is_bw : bool = true if diagonal == diagonal_mode.BREAK_WATER else false
		for pos in grid.around(f_min_vector, is_bw):
			if pos is Vector2i:
				tmp_list.append(pos)
		#对f_min_vector周围的位置进行遍历判断，
		#可以行走的位置添加进next_list，并计算，刷新g值，计算h值
		for pos in tmp_list:
			var tmp_node : Anode = _node(pos)
			if tmp_node.solid: continue
			
			var dirt_2d : Vector2i = pos - f_min_vector
			var tmp_f_min_node : Anode = _node(f_min_vector)
			var new_g : float = tmp_f_min_node.g + step_len * tmp_f_min_node.weight_scale
			var can_move : bool = is_enterable(dirt_2d, pos)
			if !can_move: continue
			if dirt_2d.length_squared() > 1:
				new_g += (diag_len - step_len) * tmp_f_min_node.weight_scale
			
			if !(tmp_node.in_gone || tmp_node.in_next):
				next_list.append(pos)
				tmp_node.in_next = true
				tmp_node.g = new_g
				tmp_node.h = cal_h(pos, end)
				tmp_node.parent_vector = -dirt_2d
				continue
			if tmp_node.in_next && tmp_node.g > new_g:
				tmp_node.g = new_g
				tmp_node.parent_vector = f_min_vector - pos
		
	if _node(end).in_gone:
		var tmp_vec : Vector2i = end
		while true:
			path.push_front(tmp_vec)
			if tmp_vec == start:
				break
			if path.size() > 1 && tmp_vec == path[1]: break
			tmp_vec = tmp_vec + _node(tmp_vec).parent_vector
	
	for element in gone_list:
		node_ghf_reset(element)
	for element in next_list:
		node_ghf_reset(element)
	
	return path

func is_attackable(start : Vector2i, end : Vector2i, see_or_attack : bool = false) -> bool:
	
	var line : Array[Vector2i] = PlaneArray.get_line_bresenham(start, end)
	var last_vec : Vector2i = line.pop_front()
	for tmp_vec in line:
		var dirt : Vector2i = tmp_vec - last_vec
		if _node(tmp_vec).solid:
			return false
		var tmp_level : Vector4i = Vector4i.ZERO
		if see_or_attack: tmp_level = _node(tmp_vec).sgh_level
		else: tmp_level = _node(tmp_vec).def_level
		if !is_walkable(dirt, tmp_level):
			return false
		
	return true

func astar_to_normal(_path : Array[Vector2i], _step : float) -> Array[Vector2]:
	var result_path : Array[Vector2] = []
	for point in _path:
		result_path.append(point * _step + Vector2(_step, _step) / 2)
	return result_path

#该方法会返回在指定移动能力内可以到达的所有位置。
#注意，此方法不会对输入的move_rng,即指定的移动能力做额外修正
#输入move_rng参数时请参考step_len和diag_len两个属性进行调整
#is_cleaning参数为真，则会清除寻路时写入各个节点中的数据，比如g值
#is_cleaning参数为假，则不会清除，在下次寻路开始前请手动清除数据
func find_move_range(start : Vector2i, move_rng : float, is_cleaning : bool) -> Array[Vector2i]:
	var next_list : Array[Vector2i] = []
	var gone_list : Array[Vector2i] = []
	var f_min_vector : Vector2i = start
	
	next_list.append(f_min_vector)
	while !next_list.is_empty():
		
		var tmp_index : int = 0
		for _index in next_list.size():
			if _node(next_list[_index]).g <= _node(next_list[tmp_index]).g:
				f_min_vector = next_list[_index]
				tmp_index = _index
		f_min_vector = next_list[tmp_index]
		gone_list.append(f_min_vector)
		next_list.pop_at(tmp_index)
		
		
		var around_list : Array[Vector2i] = []
		var is_bw : bool = true if diagonal == diagonal_mode.BREAK_WATER else false
		
		around_list.append_array(grid.around(f_min_vector, is_bw).filter(func(element):if element is Vector2i: return element))
		for pos in around_list:
			if pos == start: continue
			var tmp_node : Anode = _node(pos)
			if tmp_node.solid: continue
			
			var dirt_2d : Vector2i = pos - f_min_vector
			var can_move : bool = is_enterable(dirt_2d, pos)
			var tmp_f_min_node : Anode = _node(f_min_vector)
			var new_g : float = tmp_f_min_node.g + step_len * tmp_f_min_node.weight_scale
			
			if !can_move: continue
			if dirt_2d.length_squared() > 1:
				new_g += (diag_len - step_len) * tmp_f_min_node.weight_scale
			if new_g > move_rng * step_len:
				continue
			
			if tmp_node.g == 0:
				tmp_node.g = new_g
				next_list.append(pos)
			elif tmp_node.g > new_g:
				tmp_node.g = new_g
	if is_cleaning:
		for element in gone_list: node_ghf_reset(element)
	return gone_list
