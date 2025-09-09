extends Control
class_name UIEvent

@warning_ignore("unused_signal")
signal event_hide_over

@onready var ui_bg: Panel = $UIBG
@onready var panel: Panel = $Panel
@onready var label_title: Label = $Panel/VBoxContainer/LabelTitle
@onready var label_context: Label = $Panel/VBoxContainer/LabelContext
@onready var container_button: VBoxContainer = $Panel/VBoxContainer/ContainerButton


var ui_bg_alpha : Color = Color(Color.BLACK, 0.7)
var panel_size : Vector2 = Vector2(340, 500)
var panel_position_close : Vector2 = Vector2(310, 270)
var panel_position_open : Vector2 = Vector2(310, 20)

var button_list : Array[Button]
var effect_list : Array[EffectBase]
var button_effect_list : Array[EffectBase]

var tween : Tween

var world_state : WorldState
var target_position : Vector2 = Vector2.ZERO

func _ready() -> void:
	
	var tmp_idx : int = 0
	for button : ButtonSP in container_button.get_children():
		button.index = tmp_idx
		button.sp_pressed.connect(_on_button_sp_pressed)
		tmp_idx += 1
	ActionSp.trigger_event = init_event

func init_event(index : String) -> bool:
	clear()
	var tmp_idx : String = index
	var tmp_dic : Dictionary = CDB.vdb.get(tmp_idx)
	if tmp_dic == null || tmp_dic.is_empty() :
		return false
	label_title.text = tmp_dic.get("TITLE")
	label_context.text = tmp_dic.get("DESCRIPTION")
	var tmp_button_text_list : Array[String] = CDB.cut_list_string(tmp_dic.get("BUTTON_TEXT"))
	var tmp_button_idx : int = 1
	
	for button : ButtonSP in container_button.get_children():
		if tmp_button_idx > tmp_button_text_list.size():
			button.visible = false
			continue
		button.visible = true
		button.text = tmp_button_text_list[tmp_button_idx - 1]
		tmp_button_idx += 1
	
	var tmp_effect_text : String = tmp_dic.get("EFFECT_LIST")
	if tmp_effect_text != null && tmp_effect_text != "":
		for effect_text in CDB.cut_list_string(tmp_effect_text):
			effect_list.append(CDB.get_effect(effect_text))
			effect_list.filter(func(element): return is_instance_valid(element))
		
	var tmp_button_effect_text : String = tmp_dic.get("BUTTON_EFFECT_LIST")
	if tmp_button_effect_text != null && tmp_button_effect_text != "":
		for button_effect_text in CDB.cut_list_string(tmp_button_effect_text):
			button_effect_list.append(CDB.get_effect(button_effect_text))
			button_effect_list.filter(func(element): return is_instance_valid(element))
	
	show_self_animation()
	return true

func clear() -> void:
	label_title.text = ""
	label_context.text = ""
	for button :ButtonSP in container_button.get_children():
		button.text = ""
	effect_list.clear()
	button_effect_list.clear()

func show_self_animation() -> void:
	visible = true
	if is_instance_valid(tween):
		tween.kill()
	tween = create_tween()
	tween.tween_property(panel, "size", panel_size, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
	tween.set_parallel(true)
	tween.tween_property(panel, "position", panel_position_open, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
	tween.tween_property(ui_bg, "self_modulate", ui_bg_alpha, 0.3)
	tween.tween_property(label_title, "visible", true, 0.3)
	tween.tween_property(label_context, "visible", true, 0.3)

func hide_self_animation() -> void:
	if is_instance_valid(tween):
		tween.kill()
	tween = create_tween()
	tween.tween_property(panel, "size", Vector2(panel_size.x, 0), 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
	tween.set_parallel(true)
	tween.tween_property(panel, "position", panel_position_close, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
	tween.tween_property(ui_bg, "self_modulate", Color(Color.BLACK, 0.0), 0.3)
	tween.tween_property(label_title, "visible", false, 0.0)
	tween.tween_property(label_context, "visible", false, 0.0)
	tween.set_parallel(false)
	tween.tween_property(self, "visible", false, 0.0)
	tween.tween_callback(emit_signal.bind("event_hide_over"))

func _on_button_sp_pressed(button : ButtonSP) -> void:
	if !effect_list.is_empty():
		for effect in effect_list:
			effect.execute(world_state, target_position)
	if is_instance_valid(button_effect_list[button.index]):
		button_effect_list[button.index].execute(world_state, target_position)
	hide_self_animation()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_released("ui_accept"):
		if visible:
			hide_self_animation()
		else:
			show_self_animation()
