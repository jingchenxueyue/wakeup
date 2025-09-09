extends Control
class_name UIFinalPanel

@onready var label : Label = $VBoxContainer/Label
@onready var btn_retry : Button = $VBoxContainer/HBoxContainer/BtnRetry
@onready var btn_quit : Button = $VBoxContainer/HBoxContainer/BtnExit

var is_win : bool = false
