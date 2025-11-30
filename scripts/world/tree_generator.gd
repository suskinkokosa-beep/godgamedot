extends Node
class_name TreeGenerator

const NATURE_PATH := "res://assets/art_pack2/Stylized Nature MEGAKIT/glTF/"

static var loaded_models := {}
static var gltf_document: GLTFDocument = null
static var gltf_state: GLTFState = null

static var tree_mappings := {
	"oak": ["CommonTree_1.gltf", "CommonTree_2.gltf", "CommonTree_3.gltf"],
	"birch": ["CommonTree_4.gltf", "CommonTree_5.gltf"],
	"pine": ["Pine_1.gltf", "Pine_2.gltf", "Pine_3.gltf", "Pine_4.gltf", "Pine_5.gltf"],
	"spruce": ["Pine_1.gltf", "Pine_3.gltf", "Pine_5.gltf"],
	"willow": ["TwistedTree_1.gltf", "TwistedTree_2.gltf", "TwistedTree_3.gltf"],
	"maple": ["CommonTree_1.gltf", "CommonTree_3.gltf", "CommonTree_5.gltf"],
	"acacia": ["TwistedTree_4.gltf", "TwistedTree_5.gltf"],
	"palm": ["TwistedTree_1.gltf", "TwistedTree_3.gltf"],
	"dead": ["DeadTree_1.gltf", "DeadTree_2.gltf", "DeadTree_3.gltf", "DeadTree_4.gltf", "DeadTree_5.gltf"]
}

static var tree_scales := {
	"oak": Vector3(1.5, 1.5, 1.5),
	"birch": Vector3(1.2, 1.4, 1.2),
	"pine": Vector3(1.0, 1.3, 1.0),
	"spruce": Vector3(1.0, 1.5, 1.0),
	"willow": Vector3(1.3, 1.2, 1.3),
	"maple": Vector3(1.4, 1.4, 1.4),
	"acacia": Vector3(1.5, 1.0, 1.5),
	"palm": Vector3(1.0, 1.2, 1.0),
	"dead": Vector3(1.0, 1.0, 1.0)
}

static func create_tree(tree_type: String, _lod_level: int = 0) -> Node3D:
	var model_files = tree_mappings.get(tree_type, tree_mappings["oak"])
	var selected_file = model_files[randi() % model_files.size()]
	var full_path = NATURE_PATH + selected_file
	
	var model = _load_gltf_model(full_path)
	if model:
		model.name = tree_type.capitalize() + "Tree"
		var base_scale = tree_scales.get(tree_type, Vector3.ONE)
		model.scale = base_scale
		return model
	
	return _create_fallback_tree(tree_type)

static func _load_gltf_model(path: String) -> Node3D:
	if loaded_models.has(path):
		var cached = loaded_models[path]
		if cached and is_instance_valid(cached):
			return cached.duplicate()
	
	if not FileAccess.file_exists(path):
		push_warning("[TreeGenerator] glTF file not found: " + path)
		return null
	
	if gltf_document == null:
		gltf_document = GLTFDocument.new()
	
	var state = GLTFState.new()
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		push_warning("[TreeGenerator] Cannot open file: " + path)
		return null
	
	var error = gltf_document.append_from_file(path, state)
	if error != OK:
		push_warning("[TreeGenerator] Failed to parse glTF: " + path + " (error: " + str(error) + ")")
		return null
	
	var scene = gltf_document.generate_scene(state)
	if scene:
		loaded_models[path] = scene
		return scene.duplicate()
	
	return null

static func _create_fallback_tree(tree_type: String) -> Node3D:
	var root = Node3D.new()
	root.name = tree_type.capitalize() + "Tree_Fallback"
	
	var config = _get_tree_config(tree_type)
	
	var trunk = MeshInstance3D.new()
	trunk.name = "Trunk"
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = config.trunk_radius * 0.7
	cylinder.bottom_radius = config.trunk_radius
	cylinder.height = config.trunk_height
	cylinder.radial_segments = 8
	trunk.mesh = cylinder
	trunk.position.y = config.trunk_height * 0.5
	
	var trunk_mat = StandardMaterial3D.new()
	trunk_mat.albedo_color = config.trunk_color
	trunk_mat.roughness = 0.95
	trunk.material_override = trunk_mat
	root.add_child(trunk)
	
	if config.crown_type != "none":
		var crown = MeshInstance3D.new()
		crown.name = "Crown"
		var sphere = SphereMesh.new()
		sphere.radius = config.crown_radius
		sphere.height = config.crown_height
		sphere.radial_segments = 12
		sphere.rings = 6
		crown.mesh = sphere
		crown.position.y = config.trunk_height + config.crown_height * 0.4
		
		var crown_mat = StandardMaterial3D.new()
		crown_mat.albedo_color = config.crown_color
		crown_mat.roughness = 0.9
		crown_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		crown.material_override = crown_mat
		root.add_child(crown)
	
	return root

static func _get_tree_config(tree_type: String) -> Dictionary:
	match tree_type:
		"oak":
			return {"trunk_height": 4.0, "trunk_radius": 0.4, "trunk_color": Color(0.35, 0.25, 0.18), "crown_radius": 4.0, "crown_height": 5.0, "crown_color": Color(0.25, 0.45, 0.2), "crown_type": "sphere"}
		"birch":
			return {"trunk_height": 6.0, "trunk_radius": 0.25, "trunk_color": Color(0.9, 0.88, 0.85), "crown_radius": 2.5, "crown_height": 4.0, "crown_color": Color(0.35, 0.55, 0.25), "crown_type": "oval"}
		"pine", "spruce":
			return {"trunk_height": 8.0, "trunk_radius": 0.35, "trunk_color": Color(0.4, 0.28, 0.2), "crown_radius": 2.5, "crown_height": 7.0, "crown_color": Color(0.15, 0.35, 0.15), "crown_type": "cone"}
		"willow":
			return {"trunk_height": 4.5, "trunk_radius": 0.5, "trunk_color": Color(0.4, 0.32, 0.22), "crown_radius": 5.0, "crown_height": 4.0, "crown_color": Color(0.35, 0.5, 0.25), "crown_type": "drooping"}
		"dead":
			return {"trunk_height": 4.0, "trunk_radius": 0.3, "trunk_color": Color(0.3, 0.25, 0.2), "crown_radius": 0.0, "crown_height": 0.0, "crown_color": Color(0.3, 0.25, 0.2), "crown_type": "none"}
		_:
			return {"trunk_height": 5.0, "trunk_radius": 0.35, "trunk_color": Color(0.4, 0.3, 0.2), "crown_radius": 3.0, "crown_height": 4.0, "crown_color": Color(0.25, 0.45, 0.2), "crown_type": "sphere"}

static func get_biome_tree_types(biome: String) -> Array:
	match biome:
		"forest", "dense_forest":
			return ["oak", "birch", "maple"]
		"birch_forest":
			return ["birch", "birch", "oak"]
		"maple_forest":
			return ["maple", "maple", "oak"]
		"taiga", "snowy_taiga":
			return ["pine", "spruce", "spruce"]
		"jungle", "rainforest":
			return ["oak", "palm", "willow"]
		"savanna":
			return ["acacia", "acacia", "dead"]
		"swamp", "marsh":
			return ["willow", "dead", "oak"]
		"desert", "dunes":
			return ["palm", "dead"]
		"tundra", "snow_plains":
			return ["spruce", "dead"]
		"plains", "meadow":
			return ["oak", "birch"]
		_:
			return ["oak", "pine"]
