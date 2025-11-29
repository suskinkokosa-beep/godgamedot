extends Node
class_name TreeGenerator

static var tree_materials := {}
static var bark_material: StandardMaterial3D = null
static var leaves_material: StandardMaterial3D = null

static func create_tree(tree_type: String, lod_level: int = 0) -> Node3D:
	var root = Node3D.new()
	root.name = tree_type.capitalize() + "Tree"
	
	var config = _get_tree_config(tree_type)
	
	var trunk = _create_trunk(config, lod_level)
	root.add_child(trunk)
	
	var foliage = _create_foliage(config, tree_type, lod_level)
	root.add_child(foliage)
	
	if config.get("has_roots", false) and lod_level == 0:
		var roots = _create_roots(config)
		root.add_child(roots)
	
	return root

static func _get_tree_config(tree_type: String) -> Dictionary:
	match tree_type:
		"oak":
			return {
				"trunk_height": 4.0,
				"trunk_radius": 0.4,
				"trunk_color": Color(0.35, 0.25, 0.18),
				"crown_radius": 4.0,
				"crown_height": 5.0,
				"crown_color": Color(0.25, 0.45, 0.2),
				"crown_type": "sphere",
				"branch_count": 5,
				"has_roots": true
			}
		"birch":
			return {
				"trunk_height": 6.0,
				"trunk_radius": 0.25,
				"trunk_color": Color(0.9, 0.88, 0.85),
				"crown_radius": 2.5,
				"crown_height": 4.0,
				"crown_color": Color(0.35, 0.55, 0.25),
				"crown_type": "oval",
				"branch_count": 4,
				"has_roots": false
			}
		"pine":
			return {
				"trunk_height": 8.0,
				"trunk_radius": 0.35,
				"trunk_color": Color(0.4, 0.28, 0.2),
				"crown_radius": 2.5,
				"crown_height": 7.0,
				"crown_color": Color(0.15, 0.35, 0.15),
				"crown_type": "cone",
				"branch_count": 0,
				"has_roots": true
			}
		"spruce":
			return {
				"trunk_height": 10.0,
				"trunk_radius": 0.4,
				"trunk_color": Color(0.38, 0.26, 0.18),
				"crown_radius": 3.0,
				"crown_height": 9.0,
				"crown_color": Color(0.12, 0.3, 0.12),
				"crown_type": "cone",
				"branch_count": 0,
				"has_roots": true
			}
		"willow":
			return {
				"trunk_height": 4.5,
				"trunk_radius": 0.5,
				"trunk_color": Color(0.4, 0.32, 0.22),
				"crown_radius": 5.0,
				"crown_height": 4.0,
				"crown_color": Color(0.35, 0.5, 0.25),
				"crown_type": "drooping",
				"branch_count": 8,
				"has_roots": true
			}
		"acacia":
			return {
				"trunk_height": 3.0,
				"trunk_radius": 0.35,
				"trunk_color": Color(0.45, 0.3, 0.2),
				"crown_radius": 5.0,
				"crown_height": 2.0,
				"crown_color": Color(0.4, 0.5, 0.25),
				"crown_type": "flat",
				"branch_count": 3,
				"has_roots": false
			}
		"maple":
			return {
				"trunk_height": 5.0,
				"trunk_radius": 0.45,
				"trunk_color": Color(0.38, 0.28, 0.2),
				"crown_radius": 4.5,
				"crown_height": 5.5,
				"crown_color": Color(0.7, 0.35, 0.15),
				"crown_type": "sphere",
				"branch_count": 6,
				"has_roots": true
			}
		"palm":
			return {
				"trunk_height": 7.0,
				"trunk_radius": 0.3,
				"trunk_color": Color(0.5, 0.4, 0.3),
				"crown_radius": 3.0,
				"crown_height": 2.0,
				"crown_color": Color(0.3, 0.5, 0.2),
				"crown_type": "palm",
				"branch_count": 8,
				"has_roots": false
			}
		"dead":
			return {
				"trunk_height": 4.0,
				"trunk_radius": 0.3,
				"trunk_color": Color(0.3, 0.25, 0.2),
				"crown_radius": 0.0,
				"crown_height": 0.0,
				"crown_color": Color(0.3, 0.25, 0.2),
				"crown_type": "none",
				"branch_count": 4,
				"has_roots": false
			}
		_:
			return {
				"trunk_height": 5.0,
				"trunk_radius": 0.35,
				"trunk_color": Color(0.4, 0.3, 0.2),
				"crown_radius": 3.0,
				"crown_height": 4.0,
				"crown_color": Color(0.25, 0.45, 0.2),
				"crown_type": "sphere",
				"branch_count": 4,
				"has_roots": false
			}

static func _create_trunk(config: Dictionary, lod_level: int) -> MeshInstance3D:
	var mesh_inst = MeshInstance3D.new()
	mesh_inst.name = "Trunk"
	
	var segments = 12 if lod_level == 0 else (6 if lod_level == 1 else 4)
	
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = config.trunk_radius * 0.7
	cylinder.bottom_radius = config.trunk_radius
	cylinder.height = config.trunk_height
	cylinder.radial_segments = segments
	mesh_inst.mesh = cylinder
	
	mesh_inst.position.y = config.trunk_height * 0.5
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = config.trunk_color
	mat.roughness = 0.95
	mat.metallic = 0.0
	mat.diffuse_mode = BaseMaterial3D.DIFFUSE_BURLEY
	
	var wood_tex_path = "res://assets/art_pack/textures/albedo_wood.png"
	if ResourceLoader.exists(wood_tex_path):
		mat.albedo_texture = load(wood_tex_path)
		mat.albedo_color = Color(1, 1, 1)
		mat.uv1_scale = Vector3(2, 4, 1)
	
	mesh_inst.material_override = mat
	
	return mesh_inst

static func _create_foliage(config: Dictionary, tree_type: String, lod_level: int) -> Node3D:
	var foliage = Node3D.new()
	foliage.name = "Foliage"
	
	if config.crown_type == "none":
		return foliage
	
	var crown_y = config.trunk_height
	
	match config.crown_type:
		"sphere":
			var mesh_inst = _create_sphere_crown(config, lod_level)
			mesh_inst.position.y = crown_y + config.crown_height * 0.4
			foliage.add_child(mesh_inst)
		"oval":
			var mesh_inst = _create_oval_crown(config, lod_level)
			mesh_inst.position.y = crown_y + config.crown_height * 0.4
			foliage.add_child(mesh_inst)
		"cone":
			var layers = 4 if lod_level == 0 else 2
			for i in range(layers):
				var mesh_inst = _create_cone_layer(config, i, layers, lod_level)
				mesh_inst.position.y = crown_y + i * (config.crown_height / layers)
				foliage.add_child(mesh_inst)
		"flat":
			var mesh_inst = _create_flat_crown(config, lod_level)
			mesh_inst.position.y = crown_y + config.crown_height * 0.5
			foliage.add_child(mesh_inst)
		"drooping":
			var mesh_inst = _create_drooping_crown(config, lod_level)
			mesh_inst.position.y = crown_y + config.crown_height * 0.3
			foliage.add_child(mesh_inst)
		"palm":
			var fronds = _create_palm_fronds(config, lod_level)
			for frond in fronds:
				frond.position.y = crown_y
				foliage.add_child(frond)
	
	return foliage

static func _create_sphere_crown(config: Dictionary, lod_level: int) -> MeshInstance3D:
	var mesh_inst = MeshInstance3D.new()
	mesh_inst.name = "Crown"
	
	var segments = 16 if lod_level == 0 else (8 if lod_level == 1 else 4)
	
	var sphere = SphereMesh.new()
	sphere.radius = config.crown_radius
	sphere.height = config.crown_height
	sphere.radial_segments = segments
	sphere.rings = segments / 2
	mesh_inst.mesh = sphere
	
	mesh_inst.material_override = _create_leaves_material(config.crown_color)
	
	return mesh_inst

static func _create_oval_crown(config: Dictionary, lod_level: int) -> MeshInstance3D:
	var mesh_inst = MeshInstance3D.new()
	mesh_inst.name = "Crown"
	
	var segments = 12 if lod_level == 0 else 6
	
	var sphere = SphereMesh.new()
	sphere.radius = config.crown_radius
	sphere.height = config.crown_height * 1.5
	sphere.radial_segments = segments
	sphere.rings = segments / 2
	mesh_inst.mesh = sphere
	
	mesh_inst.material_override = _create_leaves_material(config.crown_color)
	
	return mesh_inst

static func _create_cone_layer(config: Dictionary, layer: int, total_layers: int, lod_level: int) -> MeshInstance3D:
	var mesh_inst = MeshInstance3D.new()
	mesh_inst.name = "ConeLayer%d" % layer
	
	var segments = 12 if lod_level == 0 else 6
	
	var t = float(layer) / float(total_layers)
	var radius = config.crown_radius * (1.0 - t * 0.7)
	var height = config.crown_height / total_layers * 1.2
	
	var cone = CylinderMesh.new()
	cone.top_radius = radius * 0.3
	cone.bottom_radius = radius
	cone.height = height
	cone.radial_segments = segments
	mesh_inst.mesh = cone
	
	mesh_inst.material_override = _create_leaves_material(config.crown_color)
	
	return mesh_inst

static func _create_flat_crown(config: Dictionary, lod_level: int) -> MeshInstance3D:
	var mesh_inst = MeshInstance3D.new()
	mesh_inst.name = "Crown"
	
	var segments = 16 if lod_level == 0 else 8
	
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = config.crown_radius
	cylinder.bottom_radius = config.crown_radius * 0.8
	cylinder.height = config.crown_height
	cylinder.radial_segments = segments
	mesh_inst.mesh = cylinder
	
	mesh_inst.material_override = _create_leaves_material(config.crown_color)
	
	return mesh_inst

static func _create_drooping_crown(config: Dictionary, lod_level: int) -> MeshInstance3D:
	var mesh_inst = MeshInstance3D.new()
	mesh_inst.name = "Crown"
	
	var segments = 16 if lod_level == 0 else 8
	
	var sphere = SphereMesh.new()
	sphere.radius = config.crown_radius
	sphere.height = config.crown_height * 2
	sphere.radial_segments = segments
	sphere.rings = segments / 2
	mesh_inst.mesh = sphere
	
	mesh_inst.material_override = _create_leaves_material(config.crown_color)
	
	return mesh_inst

static func _create_palm_fronds(config: Dictionary, lod_level: int) -> Array:
	var fronds := []
	var num_fronds = 8 if lod_level == 0 else 4
	
	for i in range(num_fronds):
		var frond = MeshInstance3D.new()
		frond.name = "Frond%d" % i
		
		var box = BoxMesh.new()
		box.size = Vector3(0.3, 0.1, 2.5)
		frond.mesh = box
		
		var angle = (float(i) / num_fronds) * TAU
		frond.rotation.y = angle
		frond.rotation.x = -0.5
		
		frond.material_override = _create_leaves_material(config.crown_color)
		fronds.append(frond)
	
	return fronds

static func _create_roots(config: Dictionary) -> Node3D:
	var roots = Node3D.new()
	roots.name = "Roots"
	
	for i in range(4):
		var root = MeshInstance3D.new()
		root.name = "Root%d" % i
		
		var cylinder = CylinderMesh.new()
		cylinder.top_radius = config.trunk_radius * 0.15
		cylinder.bottom_radius = config.trunk_radius * 0.4
		cylinder.height = 1.0
		cylinder.radial_segments = 6
		root.mesh = cylinder
		
		var angle = (float(i) / 4.0) * TAU + randf() * 0.3
		root.rotation.y = angle
		root.rotation.z = 0.6
		root.position = Vector3(cos(angle) * config.trunk_radius * 0.5, 0.3, sin(angle) * config.trunk_radius * 0.5)
		
		var mat = StandardMaterial3D.new()
		mat.albedo_color = config.trunk_color * 0.9
		mat.roughness = 0.95
		root.material_override = mat
		
		roots.add_child(root)
	
	return roots

static func _create_leaves_material(color: Color) -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.9
	mat.metallic = 0.0
	mat.diffuse_mode = BaseMaterial3D.DIFFUSE_BURLEY
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	return mat

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
