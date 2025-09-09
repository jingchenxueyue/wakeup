extends Node
#Card Database

const WAKE_DATA_PATH : String = "res://resource/json_data/wake_data.json"
const CARD_IMAGE_PATH : String = "res://asset/card/image/{0}.png"
const PRODUCT_PATH : String = "res://resource/product/{0}.gd"
const PRODUCT_TEXTURE_PATH : String = "res://asset/image/{0}.png"
const EFFECT_PATH : String = "res://resource/effect/tres/final/{0}.tres"

var cdb : Dictionary
var pdb : Dictionary
var sdb : Dictionary 
var edb : Dictionary
var vdb : Dictionary

func _ready() -> void:
	load_data(WAKE_DATA_PATH)

func load_data(path : String) -> void:
	var json_string = FileAccess.get_file_as_string(path)
	if json_string == null:
		push_warning("Json文件读取失败，该路径不存在。")
		return
	var json = JSON.new()
	var error = json.parse(json_string)
	if error == OK:
		var data_received = json.data
		if typeof(data_received) == TYPE_DICTIONARY:
			cdb = data_received.get("card")
			pdb = data_received.get("product")
			sdb = data_received.get("squad")
			edb = data_received.get("enemy")
			vdb = data_received.get("event")
		else:
			push_warning("意外数据,该json文件中的数据不是字典。")
	else:
		push_warning("JSON 解析错误：", json.get_error_message(), " 位于 ", json_string, " 行号 ", json.get_error_line())

func cut_list_string(list_string) -> Array[String]:
	if list_string == null || !list_string is String:
		return []
	var tmp_list : PackedStringArray = []
	var result : Array[String] = []
	tmp_list = list_string.split(",", false)
	for _str in tmp_list:
		result.append(_str)
	return result

func get_effect(string : String) -> EffectBase:
	if string == null || string == "":
		return null
	var tmp_effect : EffectBase
	if ":" in string:
		tmp_effect = GenerateCard.new()
		tmp_effect.card_index = string.get_slice(":", 1).to_int()
	else:
		tmp_effect = load(EFFECT_PATH.format([string])).duplicate()
	return tmp_effect
