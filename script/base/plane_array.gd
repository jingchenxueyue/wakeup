extends RefCounted
class_name PlaneArray

#二维数组

var default_value = 0: ##该类填充给数组的默认填充值
	set = set_default_value
var origin : Vector2i = Vector2i.ZERO ##该类的原点
var size : Vector2i = Vector2i.ZERO: ##该类的大小，注意，直接更改这个属性将导致不可预期的后果，你只能通过resize方法来更改这个属性
	set = size_update
var graph : Array[Array] = [] ##该类实际用于存储数据的数组变量
var diag_len : float = sqrt(2.0) ##该类斜45度角方向上相邻的两个位置之间的距离

func _init(_size : Vector2i = Vector2i.ZERO, _default_value = 0, origin_x : int = 0, origin_y : int = 0) -> void:
	origin = Vector2i(origin_x, origin_y)
	default_value = _default_value
	if _size.x == 0 || _size.y == 0: return
	for row in abs(_size.y):
		var new_row : Array = []
		for col in abs(_size.x):
			new_row.append(default_value)
		graph.append(new_row)
	size_update()


func set_default_value(value) -> void:
	if value is Array or value == null:
		print_debug("错误，默认填充值不能为数组或null值，本次更改无效")
		return
	default_value = value
	return

#该方法会在"不改变区域信息”的情况下，重新“框选区域”
#该方法是方法move_camera与方法resize的组合
func rewindow(new_size : Vector2i, new_origin : Vector2i) -> void:
	new_size = Vector2i(abs(new_size.x),abs(new_size.y))
	
	var move_vector : Vector2i = new_origin - origin
	if new_size.x == 0 || new_size.y == 0:
		origin = new_origin
		clear()
		return
	if new_size == size:
		move_camera(move_vector)
		return
	if new_size.x < size.x && move_vector.x > 0:
		move_camera(Vector2i(move_vector.x, 0))
		resize(Vector2i(new_size.x, size.y))
	else:
		resize(Vector2i(new_size.x, size.y))
		move_camera(Vector2i(move_vector.x, 0))
	if new_size.y < size.y && move_vector.y > 0:
		move_camera(Vector2i(0, move_vector.y))
		resize(Vector2i(size.x, new_size.y))
	else:
		resize(Vector2i(size.x, new_size.y))
		move_camera(Vector2i(0, move_vector.y))

#该方法会在不改变二维数组大小的情况下“移动”二维数组，并更改原点坐标,
#移动方式形如移动摄像头，但摄像头“看到”的新的区域的值皆为默认值,
#并且将会丢失所有“看不到”的区域的信息，
#即使移动回来，第一次移动前看到但移动后看不到的区域也会重置为默认值。
func move_camera(vector : Vector2i) -> void:
	var vector_x : int = vector.x
	var vector_y : int = vector.y
	if vector_x == 0 && vector_y == 0: return
	origin.x += vector_x
	origin.y += vector_y
	if size == Vector2i.ZERO: return
	if vector_x < 0:
		for count in abs(vector_x):
			pop_back_col()
			push_front_col()
	if vector_x > 0:
		for count in vector_x:
			pop_front_col()
			append_col()
	if vector_y < 0:
		for count in abs(vector_y):
			pop_back_row()
			push_front_row()
	if vector_y > 0:
		for count in vector_y:
			pop_front_row()
			append_row()

func resize(new_size : Vector2i = Vector2i.ZERO) -> void:
	new_size.x = abs(new_size.x)
	new_size.y = abs(new_size.y)
	if new_size.x == 0 || new_size.y == 0:
		clear()
		return
	while new_size.x > size.x:
		append_col(default_value)
	while new_size.y > size.y:
		append_row(default_value)
	while new_size.x < size.x:
		pop_back_col()
	while new_size.y < size.y:
		pop_back_row()

func size_update(_value : Vector2i = Vector2i.ZERO) -> void:
	if _value != Vector2i.ZERO:
		print_debug("操作无效！你无法直接更改该二维数组的大小")
	if graph.size() == 0:
		size = Vector2i.ZERO
		return
	size = Vector2i(graph[0].size(), graph.size())

func graph_add_first(value = default_value) -> bool:
	if graph.size() == 0:
		if value is Array || value == null:
			graph.append([default_value])
		else:
			graph.append([value])
		size_update()
		return true
	return false

#该方法将会根据给定的参数value生成存储在数组中的一组数据，
#参数is_row为真，则以该PlaneArray的size.x设置数组的大小，
#否则则以size.y设置数组的大小，
#若给定的数据为数组，
#则会将其拆开依序添加其中的元素，而不会作为一个整体元素多次添加，
#不足会补充填充值，多余去掉多余值。
func prepare_array(value, is_row : bool = true) -> Array:
	var tmp_array = []
	var tmp_count : int = size.x if is_row else size.y
	if value is Array == false:
		for col in tmp_count:
			tmp_array.append(value)
	else:
		if value.size() == 0: return []
		tmp_array.append_array(value)
		while value.size() < tmp_count:
			tmp_array.append(default_value)
		while tmp_array.size() > tmp_count:
			tmp_array.pop_back()
	return tmp_array

func is_overflow(index : int, is_row : bool = true) -> bool:
	var tmp_count : int = size.x if is_row else size.y
	if index < 0 || index > tmp_count:
		print_debug("错误，本次操作索引" + str(index) + "越界，操作无效")
		print_stack()
		return true
	else: return false

#该方法会在二维数组的上侧根据输入值value添加一行，
#如果二维数组为空且vale为数组，则只会添加一个元素，值为默认填充值。
func push_front_row(value = default_value) -> void:
	if graph_add_first(value): return
	var tmp_array : Array = prepare_array(value)
	if tmp_array.size() > 0: graph.push_front(tmp_array)
	size_update()
	return

#该方法会在二维数组的左侧根据输入值value添加一列，
#如果二维数组为空且vale为数组，则只会添加一个元素，值为默认填充值。
func push_front_col(value = default_value) -> void:
	if graph_add_first(value): return
	var tmp_array : Array = prepare_array(value, false)
	for y in tmp_array.size():
		graph[y].push_front(tmp_array[y])
	size_update()
	return

#该方法会在二维数组的指定位置index前根据输入值value添加一行，
#如果index等于size.x，则会添加至最后一行，
#如果二维数组为空且vale为数组，则只会添加一个元素，值为默认填充值。
func insert_row_at(index : int, value) -> void:
	if graph_add_first(value): return
	if is_overflow(index, false): return
	var tmp_array : Array = prepare_array(value)
	graph.insert(index, tmp_array)
	size_update()
	return

#该方法会在二维数组的指定位置index前根据输入值value添加一列，
#如果index等于size.x，则会添加至最后一列，
#如果二维数组为空且vale为数组，则只会添加一个元素，值为默认填充值。
func insert_col_at(index : int, value) -> void:
	if graph_add_first(value): return
	if is_overflow(index): return
	var tmp_array : Array = prepare_array(value, false)
	for y in size.y:
		graph[y].insert(index, tmp_array[y])
	size_update()
	return

#该方法会在二维数组的下侧根据输入值value添加一行，
#如果二维数组为空且vale为数组，则只会添加一个元素，值为默认填充值。
func append_row(value = default_value) -> void:
	if graph_add_first(value): return
	var tmp_array : Array = prepare_array(value)
	if tmp_array.size() > 0: graph.append(tmp_array)
	size_update()
	return

#该方法会在二维数组的右侧根据输入值value添加一列，
#如果二维数组为空且vale为数组，则只会添加一个元素，值为默认填充值。
func append_col(value = default_value) -> void:
	if graph_add_first(value): return
	var tmp_array : Array = prepare_array(value, false)
	for y in tmp_array.size():
		graph[y].append(tmp_array[y])
	size_update()
	return

func clear() -> void:
	graph.clear()
	size = Vector2i.ZERO

func pop_back_row() -> Array:
	if graph.is_empty(): return []
	var tmp_array : Array = graph.pop_back()
	size_update()
	return tmp_array

func pop_back_col() -> Array:
	if graph.is_empty(): return []
	var tmp_array : Array = []
	for index in size.y:
		tmp_array.append(graph[index].pop_back())
	if graph.pick_random().is_empty(): clear()
	size_update()
	return tmp_array

func pop_front_row() -> Array:
	if graph.is_empty(): return []
	var tmp_array : Array = graph.pop_front()
	size_update()
	return tmp_array
	
func pop_front_col() -> Array:
	if graph.is_empty(): return []
	var tmp_array : Array = []
	for index in size.y:
		tmp_array.append(graph[index].pop_front())
	if graph.pick_random().is_empty(): clear()
	size_update()
	return tmp_array

func pop_at_row(index : int) -> Array:
	if graph.is_empty(): return []
	if is_overflow(index): return []
	var tmp_array : Array = graph.pop_at(index)
	size_update()
	return tmp_array

func pop_at_col(index : int) -> Array:
	if graph.is_empty(): return []
	if is_overflow(index, false): return []
	var tmp_array : Array = []
	for y in size.y:
		tmp_array.append(graph[y].pop_at(index))
	if graph.pick_random().is_empty(): clear()
	size_update()
	return tmp_array
	
func has_point(point : Vector2i) -> bool:
	var tmp_rect : Rect2i = Rect2i(origin, size)
	if !tmp_rect.has_point(point):
		return false
	return true

func set_point(position : Vector2i, value = default_value) -> void:
	var pos_x : int = position.x
	var pos_y : int = position.y
	graph[pos_y - origin.y][pos_x - origin.x] = value

func get_point(position : Vector2i) -> Variant:
	var pos_x : int = position.x
	var pos_y : int = position.y
	return graph[pos_y - origin.y][pos_x - origin.x]

func set_value(position : Vector2i, value = default_value) -> void:
	var pos_x : int = position.x
	var pos_y : int = position.y
	graph[pos_y][pos_x] = value

func get_value(position : Vector2i) -> Variant:
	var pos_x : int = position.x
	var pos_y : int = position.y
	return graph[pos_y][pos_x]

func is_offset_valid(position : Vector2i, x_offset : int, y_offset : int) -> Variant:
	var new_x : int = position.x + x_offset
	var new_y : int = position.y + y_offset
	var new_vec : Vector2i = Vector2i(new_x, new_y)
	if has_point(new_vec): return new_vec
	else: return default_value

#该方法会从位置tmp_vec的正上方开始，按照顺时针顺序,
#依次将和tmp_vec相邻的四个位置vector2i填入数组tmp_list中，
#参数is_8_direction默认为假， 如果为真，则依序再添加四个斜向位置，
#如果某个填入数组的位置无效（越界），则改为填入该二维数组的默认值，
#即这个方法有可能返回一个包含两种数据类型的泛型数组。
func around(position : Vector2i, is_8_direction : bool = false) -> Array:
	var tmp_list : Array = []
	
	if !has_point(position): return tmp_list
	
	tmp_list.append(is_offset_valid(position, 0, -1))
	if is_8_direction: tmp_list.append(is_offset_valid(position, 1, -1))
	tmp_list.append(is_offset_valid(position, 1, 0))
	if is_8_direction: tmp_list.append(is_offset_valid(position, 1, 1))
	tmp_list.append(is_offset_valid(position, 0, 1))
	if is_8_direction: tmp_list.append(is_offset_valid(position, -1, 1))
	tmp_list.append(is_offset_valid(position, -1, 0))
	if is_8_direction: tmp_list.append(is_offset_valid(position, -1, -1))
	
	return tmp_list

#该方法会返回在指定位置的指定step距离内的所有有效位置
func get_range(position : Vector2i, _range : float, is_4_direction : bool = false) -> Array:
	var result_list : Array[Vector2i] = []
	
	var step : int = floori(_range)
	if !has_point(position): return result_list
	
	if is_4_direction:
		for y_offset in step + 1:
			for x_offset in range(-(step - y_offset), step - y_offset + 1):
				var tmp_value = is_offset_valid(position, x_offset, y_offset)
				if tmp_value is Vector2i:
					result_list.append(tmp_value)
				if y_offset != 0:
					tmp_value = is_offset_valid(position, x_offset, -y_offset)
					if tmp_value is Vector2i:	
						result_list.append(tmp_value)
	else:
		for x_offset in range(-step, step + 1):
			for y_offset in step + 1:
				var tmp_value
				if y_offset <= abs(x_offset):
					if abs(x_offset) + y_offset * (diag_len - 1) <= _range:
						tmp_value = is_offset_valid(position, x_offset, y_offset)
						if tmp_value is Vector2i:
							result_list.append(tmp_value)
						if y_offset != 0:
							tmp_value = is_offset_valid(position, x_offset, -y_offset)
							if tmp_value is Vector2i:
								result_list.append(tmp_value)
					else:
						break
				else:
					if y_offset + abs(x_offset) * (diag_len - 1) <= _range:
						tmp_value = is_offset_valid(position, x_offset, y_offset)
						if tmp_value is Vector2i:
							result_list.append(tmp_value)
						if y_offset != 0:
							tmp_value = is_offset_valid(position, x_offset, -y_offset)
							if tmp_value is Vector2i:
								result_list.append(tmp_value)
					else:
						break
	
	return result_list

#该方法会返回以传入参数start为起点，传入参数end为终点的一条线段上的所有点。
#该线段上的点的位置通过布森汉姆算法计算得出。
static func get_line_bresenham(start : Vector2i, end : Vector2i) -> Array[Vector2i]:
	var line : Array[Vector2i] = []
	
	var dx : int = end.x - start.x
	var dy : int = end.y - start.y
	var dirt_x : int = sign(dx)
	var dirt_y : int = sign(dy)
	var sy : int = 0
	var flip : bool = false
	
	if abs(dy) >= abs(dx):
		var tmp_d : int = 0
		flip = true
		tmp_d = dx
		if dirt_x == dirt_y:
			dx = dy
			dy = tmp_d
		else:
			dx = -dy
			dy = -tmp_d
			
	
	for sx in abs(dx):
		dy = abs(dy)
		if 2 * sx * dy - (2 * sy + 1) * abs(dx) >= 0:
			sy += 1
		var step_vec : Vector2i = Vector2i(sx, sy)
		if dirt_y < 0:
			step_vec.y = -step_vec.y
		if dirt_x < 0 || (dirt_x == 0 && dirt_y > 0):
			step_vec.x = -step_vec.x
		
		if flip:
			var tmp_vec : Vector2i = Vector2i(step_vec.y, step_vec.x)
			if dirt_x == dirt_y:
				step_vec = tmp_vec
			else:
				step_vec = -tmp_vec
		line.append(start + step_vec)
	
	line.append(end)
	
	return line

func reset_value() -> void:
	for row in graph:
		for element in row:
			element = default_value

func print_graph() -> void:
	for row in size.y:
		var tmp_string : String = ""
		for col in size.x:
			tmp_string += str(graph[row][col])
			tmp_string += " "
		print_rich(tmp_string)
