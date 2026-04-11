# https://www.youtube.com/@ProfesorShader
# https://github.com/profesorshader
extends Node3D

@export var texture_size : int = 512
@export var splat_size : int = 200
@export var splat_count : int = 20 # 0 = infinite
@export var splat_time_initial : float = 2.0 # time for the first splat
@export var splat_time_min : float = 0.25
@export var splat_time_max : float = 0.50
@export var splat_texture : Texture2D

var wet_map_a := DrawableTexture2D.new() # blood amount (ping)
var wet_map_b := DrawableTexture2D.new() # blood amount (pong)
var color_map := DrawableTexture2D.new() # albedo

var wet_map_ref_a : DrawableTexture2D
var wet_map_ref_b : DrawableTexture2D

@onready var blood_material := load("res://materials/blood_material.tres")
@onready var splat_material := load("res://materials/splat_material.tres")

var time_to_splat : float 
var remaining_splats : int 

func next_splat_time():
	time_to_splat = randf_range(splat_time_min, splat_time_max)

func _ready() -> void:
	# set time to splat and remaining splat counter
	time_to_splat = splat_time_initial
	remaining_splats = splat_count
	
	# setup blood material
	var texel_size = 1.0 / texture_size
	blood_material.set_shader_parameter("texel_size", texel_size)
	
	# setup drawable textures
	wet_map_a.setup(
		texture_size, # width
		texture_size, # height
		DrawableTexture2D.DRAWABLE_FORMAT_RGBAF, # format
		Color.BLACK,  # initial color
		false         # use mipmaps ?
	)
	wet_map_ref_a = wet_map_a

	wet_map_b.setup(
		texture_size, # width
		texture_size, # height
		DrawableTexture2D.DRAWABLE_FORMAT_RGBAF, # format
		Color.BLACK,  # initial color
		false         # use mipmaps ?
	)
	wet_map_ref_b = wet_map_b

	color_map.setup(
		texture_size, # width
		texture_size, # height
		DrawableTexture2D.DRAWABLE_FORMAT_RGBA8, # format
		Color.WHITE,  # initial color
		false         # use mipmaps ?
	)
	
	# replace mesh albedo texture with the DrawableTexture2D color_map
	$MeshInstance3D.material_override.albedo_texture = color_map
	
func _process(delta: float) -> void:
	# every X seconds, draw a random splat
	if remaining_splats > 0 or splat_count == 0:
		time_to_splat -= delta
		if time_to_splat <= 0.0:
			# choose where
			var pos_x = randi_range(0, texture_size-splat_size)		
			var pos_y = randi_range(0, texture_size-splat_size);
			# draw splat on wet map
			wet_map_ref_a.blit_rect(
				Rect2i(pos_x,pos_y,splat_size,splat_size), # region
				splat_texture,
				Color(1, 1, 1, 1), 
				0, 
				splat_material
			)
			# do splat!
			next_splat_time()
			remaining_splats -= 1
		
	# update wet map and albedo/color map
	color_map.blit_rect_multi(
		Rect2i(0,0,texture_size,texture_size), # region
		[wet_map_ref_a],                       # source textures
		[wet_map_ref_b],                       # extra target textures
		Color.WHITE,                           # modulate
		0,                                     # mipmap level
		blood_material                         # blood material
	)
		
	# swap A and B
	if wet_map_ref_a == wet_map_a:
		wet_map_ref_a = wet_map_b
		wet_map_ref_b = wet_map_a
	else:
		wet_map_ref_a = wet_map_a
		wet_map_ref_b = wet_map_b
