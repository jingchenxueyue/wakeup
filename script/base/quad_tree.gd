extends RefCounted
class_name QuadTree

##四叉树

@export var area : Rect2 = Rect2(0,0,0,0)
@export var volume : int = 0
@export var depth_max : int = 0
@export var error_value : float = 5.

var depth : int = 0
var points : Array[Rect2] = []
var divided : bool = false
var parent : QuadTree = null
var ne : QuadTree = null
var nw : QuadTree = null
var se : QuadTree = null
var sw : QuadTree = null

func _init(tree_area : Rect2, tree_volume : int, tree_depth_max : int, tree_parent : QuadTree = null) -> void:
	area = tree_area
	volume = tree_volume
	depth_max = tree_depth_max
	parent = tree_parent

#判断两个Rect2对象是否近似相等
func is_rect_equal(rect_f : Rect2, rect_s : Rect2) -> bool:
	var result : bool = (rect_f.position - rect_s.position).length_squared() <= error_value * error_value
	result = result && (rect_f.size - rect_s.size).length_squared() <= error_value * error_value
	return result

##四叉树分裂
func subdivide() -> void:
	var x : float = area.position.x
	var y : float = area.position.y
	var w : float = area.size.x / 2.
	var h : float = area.size.y / 2.
	var crt_tree : Callable = func(origin_x : float, origin_y : float) -> QuadTree:
		var tmp_rect : Rect2 = Rect2(origin_x, origin_y, w, h)
		var tmp_tree : QuadTree = QuadTree.new(tmp_rect, volume, depth_max, self)
		tmp_tree.depth = depth + 1    
		return tmp_tree
	ne = crt_tree.call(x + w, y)
	
	nw = crt_tree.call(x, y)
	
	se = crt_tree.call(x + w, y + h)
	
	sw = crt_tree.call(x, y + h)
	divided = true
	
	var tmp_points : Array[Rect2] = []
	var div_point : Callable = func(child_tree : QuadTree) -> bool:
		if child_tree.area.encloses(points.back()):
			child_tree.points.append(points.pop_back())
			
			return true
		return false
	
	while !points.is_empty():
		if div_point.call(ne): continue
		if div_point.call(nw): continue
		if div_point.call(se): continue
		if div_point.call(sw): continue
		tmp_points.append(points.pop_back())
		
	points.append_array(tmp_points)
	
	var check_valid : Callable = func (qdtree : QuadTree) -> bool:
		if qdtree.points.size() > qdtree.volume && qdtree.depth < qdtree.depth_max:
			qdtree.subdivide()
			return true
		return false
	check_valid.call(ne)
	check_valid.call(nw)
	check_valid.call(se)
	check_valid.call(sw)

##四叉树插入新点
func insert(point : Rect2) -> bool:
	print("尝试插入新点，深度", depth)
	if !area.encloses(point):
		return false
	
	if !divided:
		points.append(point)
		print("叶子插入新点成功, 深度", depth)
		if points.size() > volume && depth < depth_max:
			print("分裂")
			subdivide()
		return true
	else:
		if ne.insert(point): return true
		if nw.insert(point): return true
		if se.insert(point): return true
		if sw.insert(point): return true
		points.append(point)
		print("枝干插入新点成功， 深度", depth)
		return true


func query_area(rect : Rect2) -> Array:
	var result : Array = []
	var tmp_rect : Rect2 = area
	if !tmp_rect.intersects(rect):
		return []

	for point in points:
		if rect.intersects(point, true):
			result.append(point)
	
	if divided:
		result.append_array(ne.query_area(rect))
		result.append_array(nw.query_area(rect))
		result.append_array(se.query_area(rect))
		result.append_array(sw.query_area(rect))
	return result

func query_point_return_tree(point : Rect2) -> QuadTree:
	if !area.encloses(point):
		return null

	var tmp_tree : QuadTree = null
	var find_point : Callable = func(_point: Rect2) -> bool:
		return is_rect_equal(point, _point)
	if points.filter(find_point).size() > 0:
		return self
	if !divided: return null
	var choice : Callable = func(tree_f : QuadTree, tree_s : QuadTree) ->QuadTree:
		if is_instance_valid(tree_f):
			return tree_f
		return tree_s
	tmp_tree = choice.call(tmp_tree, nw.query_point_return_tree(point))
	tmp_tree = choice.call(tmp_tree, ne.query_point_return_tree(point))
	tmp_tree = choice.call(tmp_tree, sw.query_point_return_tree(point))
	tmp_tree = choice.call(tmp_tree, se.query_point_return_tree(point))
	return tmp_tree


#根据输入的矩形找到在误差范围内的目标矩形，并将其删除。
#这个方法只能在顶层父节点使用，同时伴有较大的清理开销。
#这个方法在子节点中使用的情况下，不保证其能正确清理节点树的冗余部分。
func delete_point(point : Rect2) -> bool:
	var tmp_tree : QuadTree = null
	tmp_tree = query_point_return_tree(point)
	if !is_instance_valid(tmp_tree):
		return false
	var tmp_idx : int = 0
	while tmp_idx < tmp_tree.points.size():
		var _point : Rect2 = tmp_tree.points[tmp_idx]
		if is_rect_equal(point, _point):
			tmp_tree.points.pop_at(tmp_idx)
			clear_up()
			return true
		tmp_idx += 1
	print_debug("错误，四叉树删除节点失败，当前深度为",tmp_tree.depth)
	return false

func change_point(from : Rect2, to : Rect2) -> bool:
	if delete_point(from) && insert(to):
		return true
	return false

#遍历四叉树，接受一个绑定Quadtree类型参数的Callable，
#返回一个处理后的数组，
#这个方法会将每个四叉树节点本身作为参数来调用指定的Callable，
#并将该Callable返回的结果按顺序合并至最终的输出的数组中。
func traversal(lamda : Callable) -> Array:
	var result : Array = []
	if divided:
		result.append_array(ne.traversal(lamda))
		result.append_array(nw.traversal(lamda))
		result.append_array(se.traversal(lamda))
		result.append_array(sw.traversal(lamda))
	
	result.append_array(lamda.call(self))
	return result

func clear_up() -> bool:
	if !divided:
		return false
	
	ne.clear_up()
	se.clear_up()
	nw.clear_up()
	sw.clear_up()
	
	var tree_combine : Callable = func(child_tree : QuadTree) -> void:
		points.append_array(child_tree.points)
	if ne.points.size() + nw.points.size() + se.points.size() + sw.points.size() + points.size() <= volume:
		if ne.divided || se.divided || nw.divided || sw.divided:
			return false
		tree_combine.call(ne)
		tree_combine.call(se)
		tree_combine.call(nw)
		tree_combine.call(sw)
		ne = null
		se = null
		nw = null
		sw = null
		divided = false
		return true
	return false
