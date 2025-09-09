extends Area2D

signal unfocus_with_out_of_area(card : CardBase, target_position : Vector2, is_execute : bool)

@export var card_count_max : int = 5
@export var draw_count : int = 1

@onready var collision: CollisionShape2D = $CollisionShape2D

@onready var button_draw: Button = $ButtonDraw
@onready var library: Library = $Library
@onready var mark: Sprite2D = $Mark
@onready var discard_pile: DiscardPile = $DiscardPile
@onready var label_library: Label = $LabelLibrary
@onready var label_discard_pile: Label = $LabelDiscardPile

var world_state : WorldState

var focus_card : CardBase
var on_focus : bool = false ##手牌区是否处于焦点位

var is_hold : bool = false ##是否正在按住某张牌

var list : Array[CardBase] = []

var hide_tween : Tween
var default_position : Vector2
var hide_position : Vector2

func _ready() -> void:
	
	button_draw.pressed.connect(_on_button_pressed)
	if is_instance_valid(ActionSp):
		ActionSp.draw_card = draw_card
		ActionSp.discard = discard
		ActionSp.generate_card = generate_card
	default_position = position
	hide_position = default_position
	hide_position.y += collision.shape.get_rect().size.y

func _physics_process(_delta: float) -> void:
	
	if !on_focus || world_state.turn_state != world_state.TurnState.PLAYER : return
	
	if Input.is_action_pressed("mouse_left") || Input.is_action_pressed("mouse_right"):
		if is_instance_valid(focus_card):
			mark.global_position = get_global_mouse_position()
			
			if !is_hold:
				mark.visible = true
				
				is_hold = true
				focus_card.is_hold = true
				for card in list:
					card.in_hand = false
				focus_card.in_hand = true
	
	if Input.is_action_just_released("mouse_left") || Input.is_action_just_released("mouse_right"):
		if !is_instance_valid(focus_card):
			return
		mark.visible = false
		is_hold = false
		focus_card.is_hold = false
		for card in list:
			card.in_hand = true
		if Input.is_action_just_released("mouse_right"):
			var tmp_position : Vector2 = get_global_mouse_position() - focus_card.global_position
			if tmp_position.x >= focus_card.outline.get_rect().size.x / 2:
				back_to_library(focus_card)
			if tmp_position.x <= -focus_card.outline.get_rect().size.x / 2:
				var tmp_is_free : bool = true if focus_card.tag.has(GE.TAG_NO_RETURN) else false
				discard(focus_card, tmp_is_free)

		if !collision.shape.get_rect().has_point(get_local_mouse_position()):
			on_focus = false
			if Input.is_action_just_released("mouse_right"):
				emit_signal("unfocus_with_out_of_area",focus_card, Vector2.ZERO, false)
			elif Input.is_action_just_released("mouse_left"):
				var tmp_position : Vector2 = world_state.get_global_mouse_position()
				
				if can_pay_cost(focus_card.cost) && focus_card.judge_type(world_state, tmp_position):
					if focus_card.effect.can_execute(world_state, tmp_position):
						pay_cost(focus_card.cost)
						if focus_card.tag.has(GE.TAG_FORWARD_CHARGE):
							discard(focus_card, true)
						elif focus_card.tag.has(GE.TAG_QUICK):
							pass
						else:
							discard(focus_card)
						emit_signal("unfocus_with_out_of_area",focus_card, tmp_position, true)
						focus_card._on_mouse_exited()
						return
				
				emit_signal("unfocus_with_out_of_area",focus_card, tmp_position, false)
			focus_card._on_mouse_exited()
			return
		
		if !focus_card.collision_shape.shape.get_rect().has_point(focus_card.get_local_mouse_position()):
			focus_card._on_mouse_exited()
			detect_is_mouse_in_any_card_area()
			return
		
#region 卡牌机制相关

func draw_card() -> void:
	if list.size() >= card_count_max:
		return
	if library.stack.is_empty():
		shuffle()
	if library.stack.is_empty():
		return
	var tmp_card : CardBase = library.stack.pop_back()
	tmp_card.reparent(self)
	
	tmp_card.visible = true
	tmp_card.in_hand = true
	if !tmp_card.focus_card.is_connected(_on_focus_card):
		tmp_card.focus_card.connect(_on_focus_card)
	if !tmp_card.unfocus_card.is_connected(_on_unfocus_card):
		tmp_card.unfocus_card.connect(_on_unfocus_card)
	list.append(tmp_card)
	library_text_update()
	adjust_position()

func can_pay_cost(_cost : int) -> bool:
	if _cost > world_state.cost:
		ActionSp.show_message.call("费用不足，无法使用该卡牌")
		return false
	return true

func pay_cost(_cost : int) -> bool:
	
	world_state.cost -= _cost
	if world_state.cost > world_state.cost_max:
		world_state.cost = world_state.cost_max
	return true

func back_to_library(card : CardBase) -> void:
	card.visible = false
	card.in_hand = false
	card.reparent(library)
	card.position = Vector2.ZERO
	list.erase(card)
	library.stack.append(card)
	library_text_update()
	adjust_position()

func discard(card : CardBase, is_free : bool = false) -> void:
	card.visible = false
	card.in_hand = false
	card.reparent(discard_pile)
	card.position = Vector2.ZERO
	list.erase(card)
	if is_free:
		card.queue_free()
	else:
		discard_pile.discard_list.append(card)
	discard_text_update()
	adjust_position()

func shuffle() -> void:
	library.stack.append_array(discard_pile.discard_list)
	discard_pile.discard_list.clear()
	library.stack.shuffle()
	for card in library.stack:
		card.reparent(library, false)
	discard_text_update()

func generate_card(index : int, is_in_hand : bool = true) -> void:
	var tmp_card : CardBase = library.card_pack.instantiate()
	if !CDB.cdb.has(str(index)):
		printerr("卡牌生成失败，索引{0}无效".format([index]))
		return
	tmp_card.index = str(index)
	tmp_card.visible = false
	if is_in_hand && list.size() < card_count_max:
		list.append(tmp_card)
		add_child(tmp_card)
		tmp_card.in_hand = true
		tmp_card.visible = true
		if !tmp_card.focus_card.is_connected(_on_focus_card):
			tmp_card.focus_card.connect(_on_focus_card)
		if !tmp_card.unfocus_card.is_connected(_on_unfocus_card):
			tmp_card.unfocus_card.connect(_on_unfocus_card)
		adjust_position()
	else:
		library.stack.append(tmp_card)
		library.add_child(tmp_card)
		tmp_card.in_hand = false
		
#endregion

#region UI表现相关

func adjust_position() -> void:
	if list.is_empty():
		return
	for card in list:
		card.in_hand = false
	var middle : int = list.size() - 1
	for _index in list.size():
		var tmp_card : CardBase = list[_index]
		var tmp_off : Vector2 = Vector2((_index * 2 - middle) * tmp_card.outline.get_rect().size.x / 2 * tmp_card.scale.x, 0)
		if is_instance_valid(tmp_card.tween):
			tmp_card.tween.kill()
		tmp_card.tween = tmp_card.create_tween()
		tmp_card.tween.tween_property(tmp_card, "position", tmp_off, 0.08)
		tmp_card.tween.tween_property(tmp_card, "default_pos", tmp_off, 0)
		tmp_card.tween.tween_property(tmp_card, "in_hand", true, 0)
		tmp_card.tween.tween_callback(detect_is_mouse_in_any_card_area)

func library_text_update() -> void:
	label_library.text = "抽牌堆: {0}".format([library.stack.size()])

func discard_text_update() -> void:
	label_discard_pile.text = "弃牌堆: {0}".format([discard_pile.discard_list.size()])

#endregion

func detect_is_mouse_in_any_card_area() -> void:
	for card in list:
		var tmp_rect : Rect2 = card.collision_shape.shape.get_rect()
		if tmp_rect.has_point(card.get_local_mouse_position()):
			
			card._on_mouse_entered()
			break

func turn_start() -> void:
	for i in draw_count:
		draw_card()

func turn_end() -> void:
	if library.stack.is_empty():
		shuffle()

func _on_button_pressed() -> void:
	draw_card()

func _on_focus_card(card : CardBase) -> void:
	focus_card = card

func _on_unfocus_card(card : CardBase) -> void:
	if focus_card == card:
		focus_card = null
