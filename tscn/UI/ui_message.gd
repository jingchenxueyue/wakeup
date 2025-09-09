extends Panel
class_name UIMessage

@onready var label_message: Label = $LabelMessage

var tween : Tween = null
var target_position : Vector2

var show_message : String = "显示默认信息"

func _ready() -> void:
	label_message.text = show_message
