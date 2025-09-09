extends Control
@onready var btn_start: Button = $VBoxContainer/HBoxContainer/BtnStart
@onready var btn_quit: Button = $VBoxContainer/HBoxContainer/BtnQuit

func _ready() -> void:
	btn_start.button_down.connect(func():
		get_tree().change_scene_to_file("res://tscn/base/main.tscn")
	)
	btn_quit.button_down.connect(func():
		get_tree().quit()
	)
