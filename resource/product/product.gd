extends Node2D
class_name ProductBase

signal product_invalid(product : ProductBase)

var sprite: Sprite2D = Sprite2D.new()
var label: Label = Label.new()

var product_index : int
var product_name : String
var texture : Texture2D
var type : String
var life_max : int = 1
var life : int = life_max:
	set(value):
		if life != value:
			life = value
			label.text = str(life)
var is_forever : bool
var is_spwaner : bool = false
var is_enemy : bool = false
var is_act_at_once : bool = true
var is_press_at_once : bool = true
var button_self : Button = preload("uid://c6h10h1kswru2").instantiate()

var effect : EffectBase
var buff_list : Array[BuffBase]
var death_effect : EffectBase
var tag : Array[String]
var world_state : WorldState
var target_product : ProductBase
var target_position : Vector2
var map_position : Vector2i

func _ready() -> void:
	add_child(sprite)
	add_child(label)
	add_child(button_self)
	life = life_max
	label.text = str(life)
	sprite.texture = texture
	button_self.pressed.connect(_on_self_pressed)
	init_product()
	
	if is_enemy:
		return
	var tmp_tween : Tween = create_tween()
	tmp_tween.tween_interval(0.1)
	if is_act_at_once:
		tmp_tween.tween_callback(execute)
	if is_press_at_once:
		tmp_tween.tween_callback(_on_self_pressed)

func init_product() -> void:
	pass

func execute() -> void:
	if !is_instance_valid(effect):
		return
	if effect.execute(world_state, target_position) && tag.has(GE.TAG_MATERIAL):
		hurted(99)
	

func healing(value : int) -> void:
	life += value
	life = min(life_max, life)
	if life <= 0:
		death()

func turn_end() -> void:
	if !is_forever : life -= 1
	
	if life <= 0:
		death()

func hurted(damage : int) -> void:
	life = clamp(life - damage, 0, life_max)
	if life <= 0:
		death()

func death() -> void:
	if is_instance_valid(effect) && effect.has_method("invalid"):
		effect.invalid()
	for buff in buff_list:
		if is_instance_valid(buff):
			if buff.can_invalid(world_state):
				buff.invalid()
				buff.life = 0
	if is_instance_valid(death_effect):
		death_effect.execute(world_state, position)
	world_state.get_field_node(world_state.fog.local_to_map(position)).product_list.erase(self)
	emit_signal("product_invalid", self)
	ActionSp.show_message.call("{0}已被摧毁。".format([product_name]))
	queue_free()

func _on_self_pressed() -> void:
	pass
