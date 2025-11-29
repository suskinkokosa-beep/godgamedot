extends Control

@onready var map_texture: TextureRect = $MapPanel/MapTexture
@onready var player_marker: Control = $MapPanel/PlayerMarker
@onready var compass: Label = $MapPanel/Compass

var world_gen = null
var player_ref: Node3D = null
var map_image: Image
var map_size := 128
var world_scale := 8.0

func _ready():
	world_gen = get_node_or_null("/root/WorldGenerator")
	_find_player()
	_generate_map_texture()

func _find_player():
	var players = get_tree().get_nodes_in_group("players")
	if players.size() > 0:
		player_ref = players[0]

func _process(_delta):
	if not player_ref:
		_find_player()
		return
	
	_update_compass()
	_update_player_marker()

func _update_compass():
	if not player_ref or not compass:
		return
	
	var rot_y = player_ref.rotation.y
	var degrees = rad_to_deg(-rot_y)
	while degrees < 0:
		degrees += 360
	while degrees >= 360:
		degrees -= 360
	
	var direction = ""
	if degrees >= 337.5 or degrees < 22.5:
		direction = "С"
	elif degrees >= 22.5 and degrees < 67.5:
		direction = "СВ"
	elif degrees >= 67.5 and degrees < 112.5:
		direction = "В"
	elif degrees >= 112.5 and degrees < 157.5:
		direction = "ЮВ"
	elif degrees >= 157.5 and degrees < 202.5:
		direction = "Ю"
	elif degrees >= 202.5 and degrees < 247.5:
		direction = "ЮЗ"
	elif degrees >= 247.5 and degrees < 292.5:
		direction = "З"
	else:
		direction = "СЗ"
	
	compass.text = direction

func _update_player_marker():
	if not player_ref or not player_marker:
		return
	
	var px = player_ref.global_position.x
	var pz = player_ref.global_position.z
	
	var map_x = (px / world_scale + map_size / 2.0) / map_size * map_texture.size.x
	var map_y = (pz / world_scale + map_size / 2.0) / map_size * map_texture.size.y
	
	map_x = clamp(map_x, 5, map_texture.size.x - 5)
	map_y = clamp(map_y, 5, map_texture.size.y - 5)
	
	player_marker.position = Vector2(map_x - 5, map_y - 5)
	player_marker.rotation = -player_ref.rotation.y

func _generate_map_texture():
	if not world_gen:
		_create_fallback_texture()
		return
	
	map_image = Image.create(map_size, map_size, false, Image.FORMAT_RGBA8)
	
	for y in range(map_size):
		for x in range(map_size):
			var world_x = (x - map_size / 2.0) * world_scale
			var world_z = (y - map_size / 2.0) * world_scale
			
			var height = world_gen.get_height_at(world_x, world_z)
			var biome = world_gen.get_biome_at(world_x, world_z)
			var color = _get_map_color(biome, height)
			
			map_image.set_pixel(x, y, color)
	
	var tex = ImageTexture.create_from_image(map_image)
	map_texture.texture = tex

func _get_map_color(biome: String, height: float) -> Color:
	if height < 0:
		var depth = clamp(-height / 20.0, 0, 1)
		return Color(0.1, 0.2 + 0.2 * (1 - depth), 0.5 + 0.3 * (1 - depth))
	
	match biome:
		"ocean":
			return Color(0.1, 0.3, 0.6)
		"beach":
			return Color(0.9, 0.85, 0.6)
		"plains":
			return Color(0.4, 0.7, 0.3)
		"forest":
			return Color(0.2, 0.5, 0.2)
		"taiga":
			return Color(0.2, 0.4, 0.3)
		"tundra":
			return Color(0.7, 0.75, 0.8)
		"desert":
			return Color(0.9, 0.8, 0.5)
		"savanna":
			return Color(0.7, 0.6, 0.3)
		"swamp":
			return Color(0.3, 0.4, 0.2)
		"mountains":
			var h_factor = clamp(height / 50.0, 0, 1)
			return Color(0.5 + 0.2 * h_factor, 0.5 + 0.2 * h_factor, 0.5 + 0.2 * h_factor)
		"snowy_mountains":
			return Color(0.9, 0.92, 0.95)
		"hills":
			return Color(0.5, 0.6, 0.4)
		_:
			return Color(0.4, 0.5, 0.3)

func _create_fallback_texture():
	map_image = Image.create(map_size, map_size, false, Image.FORMAT_RGBA8)
	map_image.fill(Color(0.3, 0.5, 0.3))
	var tex = ImageTexture.create_from_image(map_image)
	map_texture.texture = tex

func regenerate_map():
	_generate_map_texture()
