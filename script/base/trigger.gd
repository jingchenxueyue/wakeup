extends Resource
class_name Trigger

##触发器

signal trigger_activate

var runtween : Tween = null

var is_aura : bool = false
var is_activate : bool = false
var is_break : bool = false

func _init() -> void:
	trigger_activate.connect(_on_trigger_activate)

func check_condition() -> bool:
	if !is_instance_valid(runtween):
		return false
	return true

func action() -> Tween:
	
	if !check_condition():
		return null
	is_activate = true
	action_rewrite()
	
	return runtween

func action_rewrite() -> Tween:
	return runtween

func _on_trigger_activate() -> void:
	pass
