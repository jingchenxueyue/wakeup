extends ProductBase
class_name Entity

signal enter_choose(unit : Entity)
signal exit_choose(unit : Entity)

var button_sp_pack : PackedScene = preload("uid://dellqtgf627qm")

var is_focus : bool = false
var press_count : float = 2.0

var tip_text : String = ""
var button_sp_list : Array[ButtonSP] = []
var effect_list : Array[EffectBase] = []
var button_default_pos : Vector2 = Vector2(0, -32)

func _ready() -> void:
	super()
	if is_spwaner:
		press_count = 0.0

func add_button() -> void:
	
	var tmp_arc : float = TAU / effect_list.size() if !effect_list.is_empty() else TAU
	var tmp_index : int = 0
	for i in effect_list.size():
		var button : ButtonSP = button_sp_pack.instantiate()
		add_child(button)
		button_sp_list.append(button)
		button.index = tmp_index
		button.position += button_default_pos.rotated(tmp_arc * tmp_index)
		button.visible = false
		button.sp_pressed.connect(_on_button_pressed)
		button.text = effect_list[tmp_index].effect_text
		button.z_index = 1
		tmp_index += 1

func execute() -> void:
	effect.execute(world_state, target_position)

func _on_self_pressed() -> void:
	if press_count <= 0.0:
		return
	if press_count != INF && int(press_count) % 2 == 1 :
		return
	if is_enemy:
		return
	
	press_count -= 1.0
	for button in button_sp_list:
		button.visible = !button.visible
	
	if !is_focus:
		emit_signal("enter_choose", self)
		ActionSp.show_operation_tip.call(tip_text)
		is_focus = true
	else:
		emit_signal("exit_choose", self)
		ActionSp.hide_operation_tip.call()
		world_state.path_layer.clear()
		is_focus = false

func _on_button_pressed(_button : ButtonSP) -> void:
	press_count -= 1.0
	for button in button_sp_list:
		button.visible = false
	effect_list[_button.index].execute(world_state, target_position)
	emit_signal("exit_choose", self)
	ActionSp.hide_operation_tip.call()
	
