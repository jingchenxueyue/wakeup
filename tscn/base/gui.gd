extends CanvasLayer

@export var ui_message_pack : PackedScene
@export var count_max : int = 4

@onready var ui_box_message: Control = $UIBoxMessage

func show_message(text : String) -> void:
	var tmp_message : UIMessage = ui_message_pack.instantiate()
	tmp_message.show_message = text
	tmp_message.target_position.y = min(count_max, ui_box_message.get_children().size()) * tmp_message.custom_minimum_size.y
	tmp_message.position = tmp_message.target_position
	tmp_message.tree_exited.connect(all_message_move_up)
	ui_box_message.add_child(tmp_message)
	var tmp_tween : Tween = tmp_message.create_tween()
	tmp_tween.tween_interval(3)
	tmp_tween.tween_callback(tmp_message.queue_free)
	
	
	if ui_box_message.get_children().size() > count_max:
		if is_instance_valid(ui_box_message.get_child(0)):
			ui_box_message.get_child(0).free()

func all_message_move_up() -> void:
	for message in ui_box_message.get_children():
		message.target_position.y -= message.custom_minimum_size.y
		if is_instance_valid(message.tween):
			message.tween.kill()
		message.tween = message.create_tween()
		message.tween.tween_property(message, "position", message.target_position, 0.1)
