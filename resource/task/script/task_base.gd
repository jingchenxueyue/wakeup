extends Resource
class_name TaskBase

@export var target_map_position_list : Array[Array]
@export var task_context : String
@export var event_list : Array[String]
@export var event : String = ""

func task_adjust(_world_state : WorldState) -> bool:
	
	return true

func trigger_event() -> bool:
	if event == "":
		return false
	return ActionSp.trigger_event.call(event)
	
