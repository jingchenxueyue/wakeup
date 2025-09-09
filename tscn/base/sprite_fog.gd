extends Sprite2D
class_name SpriteFog

@export var light_texture : GradientTexture2D

var fog_size : Vector2

var fog_image : Image
var fog_texture : ImageTexture
var light_image : Image
var black_image : Image

func _ready() -> void:
	pass

func init_sprite_fog() -> void:
	fog_image = Image.create(floori(fog_size.x), floori(fog_size.y), false, Image.FORMAT_RGBA8)
	fog_image.fill(Color.BLACK)
	fog_texture = ImageTexture.create_from_image(fog_image)
	texture = fog_texture
	light_image = light_texture.get_image()
	black_image = light_texture.get_image()
	black_image.fill(Color.WHITE)

func update_fog(position_list : Array[Vector2i], is_light : bool) -> void:
	
	for _veci in position_list:
		var tmp_position : Vector2 = _veci * 32.0
		if is_light:
			fog_image.blend_rect(light_image, Rect2(Vector2.ZERO, light_image.get_size()), tmp_position)
		else:
			fog_image.blend_rect(black_image, Rect2(Vector2.ZERO, light_image.get_size()), tmp_position)
	
	fog_texture.update(fog_image)
	if material is ShaderMaterial:
		material.set_shader_parameter("mask_texture", fog_texture)
	
