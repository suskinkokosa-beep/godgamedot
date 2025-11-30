extends Node

signal texture_loaded(texture_id: String, texture: Texture2D)
signal texture_load_failed(texture_id: String, error: String)
signal material_created(material_id: String, material: StandardMaterial3D)

const ART_PACK2_PATH := "res://assets/art_pack2/"
const NATURE_TEX_PATH := ART_PACK2_PATH + "Stylized Nature MEGAKIT/Textures/"
const NATURE_GLTF_PATH := ART_PACK2_PATH + "Stylized Nature MEGAKIT/glTF/"
const PROPS_TEX_PATH := ART_PACK2_PATH + "Fantasy Props MegaKit/Textures/"
const PROPS_GLTF_PATH := ART_PACK2_PATH + "Fantasy Props MegaKit/Exports/glTF/"
const VILLAGE_TEX_PATH := ART_PACK2_PATH + "Medieval Village MegaKit[Standard]/Textures/"
const VILLAGE_GODOT_PATH := ART_PACK2_PATH + "Medieval Village MegaKit[Standard]/Textures/Normals Godot-Unity/"
const CHAR_TEX_PATH := ART_PACK2_PATH + "Characters/Base Characters/Godot/"
const HAIR_TEX_PATH := ART_PACK2_PATH + "Characters/Hairstyles/Textures/"

var texture_cache := {}
var material_cache := {}

var nature_textures := {
	"bark_dead_tree": {"base": NATURE_TEX_PATH + "Bark_DeadTree.png", "normal": NATURE_TEX_PATH + "Bark_DeadTree_Normal.png", "category": "bark"},
	"bark_normal_tree": {"base": NATURE_TEX_PATH + "Bark_NormalTree.png", "normal": NATURE_TEX_PATH + "Bark_NormalTree_Normal.png", "category": "bark"},
	"bark_twisted_tree": {"base": NATURE_TEX_PATH + "Bark_TwistedTree.png", "normal": NATURE_TEX_PATH + "Bark_TwistedTree_Normal.png", "category": "bark"},
	"leaves_normal_tree": {"base": NATURE_TEX_PATH + "Leaves_NormalTree.png", "cutout": NATURE_TEX_PATH + "Leaves_NormalTree_C.png", "category": "leaves"},
	"leaves_twisted_tree": {"base": NATURE_TEX_PATH + "Leaves_TwistedTree.png", "cutout": NATURE_TEX_PATH + "Leaves_TwistedTree_C.png", "category": "leaves"},
	"leaves_pine": {"base": NATURE_TEX_PATH + "Leaf_Pine.png", "cutout": NATURE_TEX_PATH + "Leaf_Pine_C.png", "category": "leaves"},
	"leaves_giant_pine": {"cutout": NATURE_TEX_PATH + "Leaves_GiantPine_C.png", "category": "leaves"},
	"flowers": {"base": NATURE_TEX_PATH + "Flowers.png", "category": "flower"},
	"grass": {"base": NATURE_TEX_PATH + "Grass.png", "category": "grass"},
	"mushrooms": {"base": NATURE_TEX_PATH + "Mushrooms.png", "category": "mushroom"},
	"rocks": {"base": NATURE_TEX_PATH + "Rocks_Diffuse.png", "category": "rock"},
	"rocks_desert": {"base": NATURE_TEX_PATH + "Rocks_Desert_Diffuse.png", "category": "rock"},
	"path_rocks": {"base": NATURE_TEX_PATH + "PathRocks_Diffuse.png", "category": "path"},
	"leaves_common": {"base": NATURE_TEX_PATH + "Leaves.png", "category": "leaves"}
}

var building_textures := {
	"brick": {"base": VILLAGE_TEX_PATH + "T_Brick_BaseColor.png", "normal": VILLAGE_GODOT_PATH + "T_Brick_Normal.png", "roughness": VILLAGE_TEX_PATH + "T_Brick_Roughness.png", "category": "wall"},
	"brick_red": {"base": VILLAGE_TEX_PATH + "T_RedBrick_BaseColor.png", "category": "wall"},
	"brick_uneven": {"base": VILLAGE_TEX_PATH + "T_UnevenBrick_BaseColor.png", "normal": VILLAGE_GODOT_PATH + "T_UnevenBrick_Normal.png", "category": "wall"},
	"plaster": {"base": VILLAGE_TEX_PATH + "T_Plaster_BaseColor.png", "normal": VILLAGE_GODOT_PATH + "T_Plaster_Normal.png", "orm": VILLAGE_TEX_PATH + "T_Plaster_ORM.png", "category": "wall"},
	"rock_trim": {"base": VILLAGE_TEX_PATH + "T_RockTrim_BaseColor.png", "normal": VILLAGE_GODOT_PATH + "T_RockTrim_Normal.png", "orm": VILLAGE_TEX_PATH + "T_RockTrim_ORM.png", "category": "trim"},
	"round_tiles": {"base": VILLAGE_TEX_PATH + "T_RoundTiles_BaseColor.png", "normal": VILLAGE_GODOT_PATH + "T_RoundTiles_Normal.png", "roughness": VILLAGE_TEX_PATH + "T_RoundTiles_Roughness.png", "category": "floor"},
	"wood_trim": {"normal": VILLAGE_GODOT_PATH + "T_WoodTrim_Normal.png", "category": "wood"},
	"terrain_noise": {"base": VILLAGE_TEX_PATH + "T_Noise_Terrain.png", "category": "terrain"},
	"brushed_noise": {"base": VILLAGE_TEX_PATH + "T_BrushedNoise.png", "category": "noise"},
	"bottom_wear": {"base": VILLAGE_TEX_PATH + "T_BottomWear.png", "category": "wear"},
	"top_wear": {"base": VILLAGE_TEX_PATH + "T_TopWear.png", "category": "wear"}
}

var props_textures := {
	"cloth": {"base": PROPS_TEX_PATH + "T_Trim_Cloth_BaseColor.png", "normal": PROPS_TEX_PATH + "T_Trim_Cloth_Normal.png", "orm": PROPS_TEX_PATH + "T_Trim_Cloth_ORM.png", "category": "fabric"},
	"furniture": {"base": PROPS_TEX_PATH + "T_Trim_Furniture_BaseColor.png", "normal": PROPS_TEX_PATH + "T_Trim_Furniture_Normal.png", "orm": PROPS_TEX_PATH + "T_Trim_Furniture_ORM.png", "category": "wood"},
	"metal": {"base": PROPS_TEX_PATH + "T_Trim_Metal_BaseColor.png", "normal": PROPS_TEX_PATH + "T_Trim_Metal_Normal.png", "orm": PROPS_TEX_PATH + "T_Trim_Metal_ORM.png", "category": "metal"},
	"props": {"base": PROPS_TEX_PATH + "T_Trim_Props_BaseColor.png", "normal": PROPS_TEX_PATH + "T_Trim_Props_Normal.png", "orm": PROPS_TEX_PATH + "T_Trim_Props_ORM.png", "category": "misc"},
	"page_noise": {"base": PROPS_TEX_PATH + "T_Page_Noise.png", "category": "paper"}
}

var character_textures := {
	"superhero_male_dark": {"base": CHAR_TEX_PATH + "T_Superhero_Male_Dark.png", "normal": CHAR_TEX_PATH + "T_Superhero_Male_Normal.png", "roughness": CHAR_TEX_PATH + "T_Superhero_Male_Roughness.png", "category": "skin"},
	"superhero_female_dark": {"base": CHAR_TEX_PATH + "T_Superhero_Female_Dark_BaseColor.png", "normal": CHAR_TEX_PATH + "T_Superhero_Female_Normal.png", "roughness": CHAR_TEX_PATH + "T_Superhero_Female_Roughness.png", "category": "skin"},
	"eye_brown": {"base": CHAR_TEX_PATH + "T_Eye_Brown.png", "normal": CHAR_TEX_PATH + "T_Eye_Normal.png", "category": "eye"},
	"hair_1": {"base": HAIR_TEX_PATH + "T_Hair_1_BaseColor.png", "normal": HAIR_TEX_PATH + "T_Hair_1_Normal.png", "category": "hair"},
	"hair_2": {"base": HAIR_TEX_PATH + "T_Hair_2_BaseColor.png", "normal": HAIR_TEX_PATH + "T_Hair_2_Normal.png", "category": "hair"}
}

var plant_textures := {
	"celandine": {
		"base": ART_PACK2_PATH + "celandine/textures/celandine_01_diff_4k.jpg",
		"alpha": ART_PACK2_PATH + "celandine/textures/celandine_01_alpha_4k.png",
		"normal": ART_PACK2_PATH + "celandine/textures/celandine_01_nor_gl_4k.exr",
		"roughness": ART_PACK2_PATH + "celandine/textures/celandine_01_rough_4k.exr",
		"category": "plant"
	},
	"fern": {
		"base": ART_PACK2_PATH + "fern/textures/fern_02_diff_4k.jpg",
		"alpha": ART_PACK2_PATH + "fern/textures/fern_02_alpha_4k.png",
		"normal": ART_PACK2_PATH + "fern/textures/fern_02_nor_gl_4k.exr",
		"roughness": ART_PACK2_PATH + "fern/textures/fern_02_rough_4k.exr",
		"category": "plant"
	}
}

var weapon_textures := {
	"wooden_axe": {
		"base": ART_PACK2_PATH + "wooden_axe/textures/wooden_axe_03_diff_4k.jpg",
		"metallic": ART_PACK2_PATH + "wooden_axe/textures/wooden_axe_03_metal_4k.exr",
		"roughness": ART_PACK2_PATH + "wooden_axe/textures/wooden_axe_03_rough_4k.exr",
		"category": "weapon"
	}
}

func _ready():
	var total = nature_textures.size() + building_textures.size() + props_textures.size() + character_textures.size() + plant_textures.size() + weapon_textures.size()
	print("[TextureLoader] Initialized with ", total, " texture sets")

func get_total_texture_count() -> int:
	return nature_textures.size() + building_textures.size() + props_textures.size() + character_textures.size() + plant_textures.size() + weapon_textures.size()

func load_texture(texture_id: String, texture_type: String = "nature") -> Texture2D:
	var tex_dict := _get_texture_dict(texture_type)
	
	if not tex_dict.has(texture_id):
		emit_signal("texture_load_failed", texture_id, "Texture not found: " + texture_id)
		return null
	
	var tex_data = tex_dict[texture_id]
	var path = tex_data.get("base", "")
	
	if path.is_empty():
		path = tex_data.get("cutout", tex_data.get("alpha", ""))
	
	if path.is_empty():
		emit_signal("texture_load_failed", texture_id, "No base texture path for: " + texture_id)
		return null
	
	if texture_cache.has(path):
		return texture_cache[path]
	
	var texture = load(path) as Texture2D
	if texture:
		texture_cache[path] = texture
		emit_signal("texture_loaded", texture_id, texture)
	else:
		emit_signal("texture_load_failed", texture_id, "Failed to load: " + path)
	
	return texture

func load_texture_set(texture_id: String, texture_type: String = "nature") -> Dictionary:
	var tex_dict := _get_texture_dict(texture_type)
	
	if not tex_dict.has(texture_id):
		return {}
	
	var tex_data = tex_dict[texture_id]
	var result := {}
	
	for key in tex_data:
		if key == "category":
			continue
		var path = tex_data[key]
		if texture_cache.has(path):
			result[key] = texture_cache[path]
		else:
			var texture = load(path) as Texture2D
			if texture:
				texture_cache[path] = texture
				result[key] = texture
	
	return result

func create_material(texture_id: String, texture_type: String = "nature") -> StandardMaterial3D:
	var cache_key = texture_type + "_" + texture_id
	if material_cache.has(cache_key):
		return material_cache[cache_key].duplicate()
	
	var textures = load_texture_set(texture_id, texture_type)
	if textures.is_empty():
		return null
	
	var material = StandardMaterial3D.new()
	
	if textures.has("base"):
		material.albedo_texture = textures.base
	
	if textures.has("normal"):
		material.normal_enabled = true
		material.normal_texture = textures.normal
	
	if textures.has("roughness"):
		material.roughness_texture = textures.roughness
	
	if textures.has("metallic"):
		material.metallic_texture = textures.metallic
	
	if textures.has("orm"):
		material.ao_enabled = true
		material.ao_texture = textures.orm
		material.roughness_texture = textures.orm
		material.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_GREEN
		material.metallic_texture = textures.orm
		material.metallic_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_BLUE
	
	if textures.has("cutout") or textures.has("alpha"):
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
		material.alpha_scissor_threshold = 0.5
		if textures.has("alpha"):
			material.albedo_texture = textures.alpha
	
	material_cache[cache_key] = material
	emit_signal("material_created", cache_key, material)
	
	return material.duplicate()

func _get_texture_dict(texture_type: String) -> Dictionary:
	match texture_type:
		"nature": return nature_textures
		"building": return building_textures
		"props": return props_textures
		"character": return character_textures
		"plant": return plant_textures
		"weapon": return weapon_textures
		_: return nature_textures

func get_available_nature_textures() -> Array:
	return nature_textures.keys()

func get_available_building_textures() -> Array:
	return building_textures.keys()

func get_available_props_textures() -> Array:
	return props_textures.keys()

func get_available_character_textures() -> Array:
	return character_textures.keys()

func get_available_plant_textures() -> Array:
	return plant_textures.keys()

func get_available_weapon_textures() -> Array:
	return weapon_textures.keys()

func get_textures_by_category(texture_type: String, category: String) -> Array:
	var tex_dict := _get_texture_dict(texture_type)
	var result := []
	for key in tex_dict:
		if tex_dict[key].get("category", "") == category:
			result.append(key)
	return result

func get_bark_textures() -> Array:
	return get_textures_by_category("nature", "bark")

func get_leaves_textures() -> Array:
	return get_textures_by_category("nature", "leaves")

func get_rock_textures() -> Array:
	return get_textures_by_category("nature", "rock")

func get_wall_textures() -> Array:
	return get_textures_by_category("building", "wall")

func get_floor_textures() -> Array:
	return get_textures_by_category("building", "floor")

func get_metal_textures() -> Array:
	return get_textures_by_category("props", "metal")

func get_fabric_textures() -> Array:
	return get_textures_by_category("props", "fabric")

func create_terrain_material(biome: String) -> StandardMaterial3D:
	var material = StandardMaterial3D.new()
	
	match biome:
		"forest":
			material = create_material("bark_normal_tree", "nature")
		"desert":
			material = create_material("rocks_desert", "nature")
		"mountain":
			material = create_material("rocks", "nature")
		"swamp":
			material = create_material("grass", "nature")
		"plains":
			var grass_tex = load_texture("grass", "nature")
			if grass_tex:
				material.albedo_texture = grass_tex
		_:
			material = create_material("terrain_noise", "building")
	
	if material:
		material.uv1_scale = Vector3(4.0, 4.0, 4.0)
	
	return material

func create_building_material(building_type: String) -> StandardMaterial3D:
	match building_type:
		"house", "cottage":
			return create_material("plaster", "building")
		"tower", "fortress":
			return create_material("brick", "building")
		"barn", "shed":
			return create_material("furniture", "props")
		"inn", "tavern":
			return create_material("brick_red", "building")
		"workshop", "forge":
			return create_material("metal", "props")
		_:
			return create_material("brick", "building")

func create_prop_material(prop_type: String) -> StandardMaterial3D:
	match prop_type:
		"barrel", "crate", "chest":
			return create_material("furniture", "props")
		"cloth", "banner", "curtain":
			return create_material("cloth", "props")
		"sword", "axe", "armor":
			return create_material("metal", "props")
		"book", "scroll", "paper":
			var mat = create_material("page_noise", "props")
			return mat
		_:
			return create_material("props", "props")

func apply_texture_to_mesh(mesh_instance: MeshInstance3D, texture_id: String, texture_type: String = "nature"):
	var material = create_material(texture_id, texture_type)
	if material:
		mesh_instance.material_override = material

func preload_essential_textures():
	var essential := [
		["bark_normal_tree", "nature"],
		["leaves_normal_tree", "nature"],
		["grass", "nature"],
		["rocks", "nature"],
		["brick", "building"],
		["plaster", "building"],
		["furniture", "props"],
		["metal", "props"]
	]
	
	for tex in essential:
		load_texture_set(tex[0], tex[1])
	
	print("[TextureLoader] Preloaded ", essential.size(), " essential texture sets")

func clear_cache():
	texture_cache.clear()
	material_cache.clear()
