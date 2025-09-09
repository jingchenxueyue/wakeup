extends Button
class_name ButtonSP

signal sp_pressed(button : Button)

var index : int = -1

func _ready() -> void:
	pressed.connect(_on_pressed)

func _on_pressed() -> void:
	emit_signal("sp_pressed", self)
