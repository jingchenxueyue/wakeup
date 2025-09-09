extends Area2D
class_name CardBase

signal focus_card(card : CardBase)
signal unfocus_card(card : CardBase)

@onready var image: Sprite2D = $Image
@onready var outline: Sprite2D = $Outline
@onready var label_text: Label = $text
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var label_cost: Label = $Panel/LabelCost
@onready var label_title: Label = $LabelTitle
@onready var label_type: Label = $LabelType

@export var in_hand : bool = false

var index : String = "0"
var in_hande_index : int = -1
var title : String = "标题"
var cost : int = 0:
	set(value):
		cost = value
		label_cost.text = str(cost)
var type : String = "NONE"
var tag : Array[String] = []

var effect : EffectBase

var default_pos : Vector2
var is_enter : bool = false
var is_hold : bool = false

var tween : Tween

func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	default_pos = position
	
	init_card()

func init_card() -> bool:
	if !CDB.cdb.has(index):
		printerr("卡牌创建失败，该索引不存在")
		return false
	var tmp_dic : Dictionary = CDB.cdb.get(index)
	var tmp_path : String = ""
	title = tmp_dic.get("TITLE")
	cost = tmp_dic.get("COST")
	type = tmp_dic.get("TYPE")
	tag = CDB.cut_list_string(tmp_dic.get("TAG"))
	tmp_path = CDB.CARD_IMAGE_PATH.format([tmp_dic.get("IMAGE_PATH")])
	var tmp_file = load(tmp_path)
	if is_instance_valid(tmp_file):
		image.texture = tmp_file.duplicate()
		match type:
			GE.TYPE_CONTAINMENT:
				image.modulate = Color.AQUA
			GE.TYPE_DETECT:
				image.modulate = Color.YELLOW
			GE.TYPE_ERADICATION:
				image.modulate = Color.RED
			GE.TYPE_SUPPORT:
				image.modulate = Color.GREEN
	label_title.text = title
	label_type.text = type
	label_text.text = tmp_dic.get("DESCRIPTION")
	tmp_path = CDB.EFFECT_PATH.format([tmp_dic.get("EFFECT_PATH")])
	tmp_file = load(tmp_path)
	if is_instance_valid(tmp_file):
		effect = tmp_file.duplicate(true)
	return true
	
func _physics_process(_delta: float) -> void:
	pass

func judge_type(world_state : WorldState, target_position : Vector2) -> bool:
	var tmp_position : Vector2i = world_state.fog.local_to_map(target_position)
	var tmp_node : FieldNode = world_state.get_field_node(tmp_position)
	if !is_instance_valid(tmp_node):
		ActionSp.show_message.call("超出地图范围。")
		return false
	if tag.has(GE.TAG_SINK) && tmp_node.nightmare_list.is_empty():
		ActionSp.show_message.call("该卡牌只能在噩梦区域内使用。")
		return false
	match type:
		GE.TYPE_NONE:
			return false
		GE.TYPE_DETECT:
			if tmp_node.light_level > 0:
				return true
			ActionSp.show_message.call("该卡牌需要在可见区域内使用。")
			return false
		GE.TYPE_CONTAINMENT:
			if tmp_node.light_level > 0 && tmp_node.nightmare_list.is_empty():
				return true
			ActionSp.show_message.call("该卡牌需要在无噩梦的可见区域内使用。")
			return false
		GE.TYPE_ERADICATION:
			if tmp_node.light_level > 0:
				return true
			ActionSp.show_message.call("该卡牌需要在可见区域内使用。")
			return false
		GE.TYPE_SUPPORT:
			if tmp_node.light_level > 0 && tmp_node.nightmare_list.is_empty():
				return true
			ActionSp.show_message.call("该卡牌需要在无噩梦的可见区域内使用。")
			return false
	ActionSp.show_message.call("类型错误，该卡牌不是一个有效类型")
	return false

func _on_mouse_entered() -> void:
	if !in_hand || is_hold: return
	is_enter = true
	emit_signal("focus_card", self)
	var tmp_pos : Vector2 = default_pos
	tmp_pos.y -= 10
	if is_instance_valid(tween) : tween.kill()
	tween = create_tween()
	tween.tween_property(self, "position", tmp_pos, 0.05)

func _on_mouse_exited() -> void:
	if !in_hand  || is_hold: return
	is_enter = false
	
	emit_signal("unfocus_card", self)
	if is_instance_valid(tween) : tween.kill()
	tween = create_tween()
	tween.tween_property(self, "position", default_pos, 0.05)
