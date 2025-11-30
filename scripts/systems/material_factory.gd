extends Node

signal material_created(material_name: String, material: StandardMaterial3D)

var texture_loader: Node = null

func _ready():
	texture_loader = get_node_or_null("/root/TextureLoader")
	print("[MaterialFactory] Ready - creates PBR materials from texture sets")

func create_pbr_material(albedo: Texture2D = null, normal: Texture2D = null, roughness: Texture2D = null, metallic: Texture2D = null, ao: Texture2D = null) -> StandardMaterial3D:
	var material = StandardMaterial3D.new()
	
	if albedo:
		material.albedo_texture = albedo
	
	if normal:
		material.normal_enabled = true
		material.normal_texture = normal
	
	if roughness:
		material.roughness_texture = roughness
	
	if metallic:
		material.metallic_texture = metallic
		material.metallic = 1.0
	
	if ao:
		material.ao_enabled = true
		material.ao_texture = ao
	
	return material

func create_orm_material(albedo: Texture2D, normal: Texture2D, orm: Texture2D) -> StandardMaterial3D:
	var material = StandardMaterial3D.new()
	
	material.albedo_texture = albedo
	
	if normal:
		material.normal_enabled = true
		material.normal_texture = normal
	
	if orm:
		material.ao_enabled = true
		material.ao_texture = orm
		material.ao_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_RED
		
		material.roughness_texture = orm
		material.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_GREEN
		
		material.metallic_texture = orm
		material.metallic_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_BLUE
		material.metallic = 1.0
	
	return material

func create_foliage_material(albedo: Texture2D, normal: Texture2D = null, alpha_cutoff: float = 0.5) -> StandardMaterial3D:
	var material = StandardMaterial3D.new()
	
	material.albedo_texture = albedo
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	material.alpha_scissor_threshold = alpha_cutoff
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	
	if normal:
		material.normal_enabled = true
		material.normal_texture = normal
	
	return material

func create_bark_material(bark_id: String = "bark_normal_tree") -> StandardMaterial3D:
	if not texture_loader:
		texture_loader = get_node_or_null("/root/TextureLoader")
	
	if texture_loader:
		return texture_loader.create_material(bark_id, "nature")
	return null

func create_leaves_material(leaves_id: String = "leaves_normal_tree") -> StandardMaterial3D:
	if not texture_loader:
		texture_loader = get_node_or_null("/root/TextureLoader")
	
	if texture_loader:
		var textures = texture_loader.load_texture_set(leaves_id, "nature")
		if textures.has("cutout"):
			return create_foliage_material(textures.cutout, textures.get("normal"))
		elif textures.has("base"):
			return create_foliage_material(textures.base, textures.get("normal"))
	return null

func create_rock_material(rock_id: String = "rocks") -> StandardMaterial3D:
	if not texture_loader:
		texture_loader = get_node_or_null("/root/TextureLoader")
	
	if texture_loader:
		return texture_loader.create_material(rock_id, "nature")
	return null

func create_building_material(building_type: String = "brick") -> StandardMaterial3D:
	if not texture_loader:
		texture_loader = get_node_or_null("/root/TextureLoader")
	
	if texture_loader:
		return texture_loader.create_building_material(building_type)
	return null

func create_prop_material(prop_type: String = "furniture") -> StandardMaterial3D:
	if not texture_loader:
		texture_loader = get_node_or_null("/root/TextureLoader")
	
	if texture_loader:
		return texture_loader.create_prop_material(prop_type)
	return null

func create_character_material(skin_type: String = "superhero_male_dark") -> StandardMaterial3D:
	if not texture_loader:
		texture_loader = get_node_or_null("/root/TextureLoader")
	
	if texture_loader:
		return texture_loader.create_material(skin_type, "character")
	return null

func create_terrain_material_for_biome(biome: String) -> StandardMaterial3D:
	if not texture_loader:
		texture_loader = get_node_or_null("/root/TextureLoader")
	
	if texture_loader:
		return texture_loader.create_terrain_material(biome)
	return null

func create_simple_color_material(color: Color, metallic: float = 0.0, roughness: float = 0.8) -> StandardMaterial3D:
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = metallic
	material.roughness = roughness
	return material

func create_emissive_material(color: Color, emission_color: Color, emission_energy: float = 1.0) -> StandardMaterial3D:
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = emission_color
	material.emission_energy_multiplier = emission_energy
	return material

func create_water_material() -> StandardMaterial3D:
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.2, 0.4, 0.7, 0.7)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.metallic = 0.3
	material.roughness = 0.1
	material.refraction_enabled = true
	material.refraction_scale = 0.05
	return material

func create_glass_material(tint: Color = Color(0.9, 0.95, 1.0, 0.3)) -> StandardMaterial3D:
	var material = StandardMaterial3D.new()
	material.albedo_color = tint
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.metallic = 0.0
	material.roughness = 0.0
	material.refraction_enabled = true
	return material

func create_metal_material(color: Color = Color(0.8, 0.8, 0.85), metallic: float = 0.9, roughness: float = 0.3) -> StandardMaterial3D:
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = metallic
	material.roughness = roughness
	return material

func apply_material_to_node(node: Node3D, material: StandardMaterial3D):
	if node is MeshInstance3D:
		node.material_override = material
	else:
		for child in node.get_children():
			if child is MeshInstance3D:
				child.material_override = material
			elif child is Node3D:
				apply_material_to_node(child, material)

func get_biome_tree_materials(biome: String) -> Dictionary:
	var materials := {}
	
	match biome:
		"forest":
			materials["bark"] = create_bark_material("bark_normal_tree")
			materials["leaves"] = create_leaves_material("leaves_normal_tree")
		"swamp":
			materials["bark"] = create_bark_material("bark_twisted_tree")
			materials["leaves"] = create_leaves_material("leaves_twisted_tree")
		"desert":
			materials["bark"] = create_bark_material("bark_dead_tree")
			materials["leaves"] = null
		"mountain", "taiga":
			materials["bark"] = create_bark_material("bark_normal_tree")
			materials["leaves"] = create_leaves_material("leaves_pine")
		_:
			materials["bark"] = create_bark_material("bark_normal_tree")
			materials["leaves"] = create_leaves_material("leaves_common")
	
	return materials

func get_biome_rock_material(biome: String) -> StandardMaterial3D:
	match biome:
		"desert":
			return create_rock_material("rocks_desert")
		_:
			return create_rock_material("rocks")
