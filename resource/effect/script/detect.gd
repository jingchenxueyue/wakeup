extends SetAroundPropertyUp
class_name Detect

func all_set_over() -> void:
	ActionSp.fog_update.call(effect_area)
