extends Camera2D

@export var move_margin : float = 64
@export var move_speed : float = 10
@export var limit_off : int = 256
@export var can_observe : bool = true



var zoom_level : int = 1
var zoom_list : Array[Vector2] = [
	Vector2(1.5, 1.5),
	Vector2(1.0, 1.0),
	Vector2(0.5, 0.5)]
var mouse_pos : Vector2 = Vector2.ZERO
var move_velocity : Vector2 = Vector2.ZERO
var corrected_size : Vector2i = Vector2i.ZERO
var corrected_rect : Rect2i = Rect2i(0, 0, 0, 0)
var view_rect : Rect2

func _ready() -> void:
	view_rect = get_viewport_rect()

func init_camera(camera_rect : Rect2i, step_len : float) -> void:
	
	limit_left = floor(camera_rect.position.x * step_len)
	limit_right = floor((camera_rect.position.x + camera_rect.size.x) * step_len)
	if view_rect.size.x > camera_rect.size.x * step_len:
		var tmp_off : int = floor((view_rect.size.x - camera_rect.size.x * step_len) * 0.5)
		
		limit_left -= tmp_off
		limit_right += tmp_off
	limit_top = floor(camera_rect.position.y * step_len)
	limit_bottom = floor((camera_rect.position.y + camera_rect.size.y) * step_len)
	if view_rect.size.y > camera_rect.size.y * step_len:
		var tmp_off : int = floor((view_rect.size.y - camera_rect.size.y * step_len) * 0.5)
		
		limit_top -= tmp_off
		limit_bottom += tmp_off
	limit_bottom += limit_off
	limit_update()
	

func limit_update() -> void:
	corrected_rect = Rect2i(limit_left, limit_top, limit_right - limit_left, limit_bottom - limit_top)
	corrected_size = get_viewport_rect().size * 0.5
	corrected_rect.position += Vector2i(corrected_size / zoom.x)
	corrected_rect.size -= Vector2i(corrected_size * 2 / zoom.x)
	corrected_rect.size.x = maxi(1, corrected_rect.size.x)
	corrected_rect.size.y = maxi(1, corrected_rect.size.y)
	

func _physics_process(_delta: float) -> void:
	if !can_observe:
		return
	
	mouse_pos = get_global_mouse_position() - position + view_rect.size / 2
	move_velocity = Vector2.ZERO
	if mouse_pos.x <= move_margin: move_velocity.x = -1
	if mouse_pos.x >= corrected_size.x * 2 - move_margin: move_velocity.x = 1
	if mouse_pos.y <= move_margin: move_velocity.y = -1
	if mouse_pos.y >= corrected_size.y * 2 - move_margin: move_velocity.y = 1
	
	
	position += move_velocity * move_speed
	
func camera_zoom() -> void:
	if Input.is_action_just_pressed("zoom_out"):
		if zoom_level < zoom_list.size() - 1:
			zoom_level += 1
			var tmp_tween : Tween = create_tween()
			tmp_tween.tween_property(self, "zoom", zoom_list[zoom_level], 0.3).set_ease(Tween.EASE_OUT)
			tmp_tween.tween_callback(limit_update)
	
	if Input.is_action_just_pressed("zoom_in"):
		if zoom_level > 0:
			zoom_level -= 1
			var tmp_tween : Tween = create_tween()
			tmp_tween.tween_property(self, "zoom", zoom_list[zoom_level], 0.3).set_ease(Tween.EASE_OUT)
			tmp_tween.tween_callback(limit_update)
	
	#label.text = "鼠标位置为" + str(mouse_pos) + "\n" + \
	#"视角移动方向为" + str(move_velocity) + "\n" + \
	#"全局位置" + str(global_position) + "\n" + \
	#"目标位置" + str(get_target_position()) + "\n" + \
	#"修正矩形大小" + str(corrected_size)
	
	
	
