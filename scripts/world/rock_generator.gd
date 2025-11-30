extends Node
class_name RockGenerator

const NATURE_PATH := "res://assets/art_pack2/Stylized Nature MEGAKIT/glTF/"

static var loaded_models := {}
static var gltf_document: GLTFDocument = null

static var rock_mappings := {
	"rock": ["Rock_Medium_1.gltf", "Rock_Medium_2.gltf", "Rock_Medium_3.gltf"],
	"pebble_round": ["Pebble_Round_1.gltf", "Pebble_Round_2.gltf", "Pebble_Round_3.gltf", "Pebble_Round_4.gltf", "Pebble_Round_5.gltf"],
	"pebble_square": ["Pebble_Square_1.gltf", "Pebble_Square_2.gltf", "Pebble_Square_3.gltf", "Pebble_Square_4.gltf", "Pebble_Square_5.gltf", "Pebble_Square_6.gltf"]
}

static var ore_colors := {
	"iron_ore": Color(0.45, 0.35, 0.3),
	"copper_ore": Color(0.7, 0.45, 0.3),
	"gold_ore": Color(0.85, 0.75, 0.3),
	"silver_ore": Color(0.75, 0.75, 0.8),
	"coal": Color(0.15, 0.15, 0.15),
	"sulfur": Color(0.85, 0.8, 0.3),
	"titanium_ore": Color(0.6, 0.65, 0.7),
	"stone": Color(0.55, 0.53, 0.5)
}

static func create_rock(variant: int = -1, size_mult: float = 1.0) -> Node3D:
	if variant < 0:
		variant = randi() % 10
	
	var model_type: String
	var model_files: Array
	
	if variant < 3:
		model_type = "rock"
		model_files = rock_mappings["rock"]
	elif variant < 7:
		model_type = "pebble_round"
		model_files = rock_mappings["pebble_round"]
	else:
		model_type = "pebble_square"
		model_files = rock_mappings["pebble_square"]
	
	var selected_file = model_files[randi() % model_files.size()]
	var full_path = NATURE_PATH + selected_file
	
	var model = _load_gltf_model(full_path)
	if model:
		model.name = "Rock_%d" % variant
		model.scale = Vector3.ONE * size_mult
		
		var collision = _create_rock_collision(size_mult)
		model.add_child(collision)
		
		return model
	
	return _create_fallback_rock(variant, size_mult)

static func create_ore_node(ore_type: String, size_mult: float = 1.0) -> Node3D:
	var root = Node3D.new()
	root.name = ore_type.capitalize() + "Node"
	
	var rock_files = rock_mappings["rock"]
	var selected_file = rock_files[randi() % rock_files.size()]
	var full_path = NATURE_PATH + selected_file
	
	var rock_model = _load_gltf_model(full_path)
	if rock_model:
		rock_model.scale = Vector3.ONE * size_mult * 0.8
		_apply_ore_tint(rock_model, ore_type)
		root.add_child(rock_model)
	else:
		var fallback = _create_fallback_rock(-1, size_mult * 0.8)
		_apply_ore_tint(fallback, ore_type)
		root.add_child(fallback)
	
	var ore_spots = _create_ore_spots(ore_type, size_mult)
	for spot in ore_spots:
		root.add_child(spot)
	
	var collision = _create_rock_collision(size_mult * 0.8)
	root.add_child(collision)
	
	return root

static func _load_gltf_model(path: String) -> Node3D:
	if loaded_models.has(path):
		var cached = loaded_models[path]
		if cached and is_instance_valid(cached):
			return cached.duplicate()
	
	if not FileAccess.file_exists(path):
		push_warning("[RockGenerator] glTF file not found: " + path)
		return null
	
	if gltf_document == null:
		gltf_document = GLTFDocument.new()
	
	var state = GLTFState.new()
	var error = gltf_document.append_from_file(path, state)
	if error != OK:
		push_warning("[RockGenerator] Failed to parse glTF: " + path + " (error: " + str(error) + ")")
		return null
	
	var scene = gltf_document.generate_scene(state)
	if scene:
		loaded_models[path] = scene
		return scene.duplicate()
	
	return null

static func _create_fallback_rock(variant: int, size_mult: float) -> Node3D:
	var root = Node3D.new()
	root.name = "Rock_Fallback_%d" % variant
	
	var mesh_inst = MeshInstance3D.new()
	mesh_inst.name = "RockMesh"
	
	var base_size = Vector3(1.0, 0.7, 0.9) * size_mult
	
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var ico = _generate_icosphere(2)
	var noise = FastNoiseLite.new()
	noise.seed = randi()
	noise.frequency = 0.8
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	
	for i in range(ico.size()):
		var v = ico[i]
		var displacement = 1.0 + noise.get_noise_3d(v.x * 10, v.y * 10, v.z * 10) * 0.3
		v *= displacement
		v *= base_size
		ico[i] = v
	
	for i in range(0, ico.size(), 3):
		var v0 = ico[i]
		var v1 = ico[i + 1]
		var v2 = ico[i + 2]
		var normal = (v1 - v0).cross(v2 - v0).normalized()
		var gray = randf_range(0.4, 0.6)
		
		st.set_color(Color(gray, gray * 0.95, gray * 0.9))
		st.set_normal(normal)
		st.set_uv(Vector2(0, 0))
		st.add_vertex(v0)
		
		st.set_color(Color(gray, gray * 0.95, gray * 0.9))
		st.set_normal(normal)
		st.set_uv(Vector2(1, 0))
		st.add_vertex(v1)
		
		st.set_color(Color(gray, gray * 0.95, gray * 0.9))
		st.set_normal(normal)
		st.set_uv(Vector2(0.5, 1))
		st.add_vertex(v2)
	
	mesh_inst.mesh = st.commit()
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.5, 0.48, 0.45)
	mat.roughness = 0.9
	mesh_inst.material_override = mat
	
	root.add_child(mesh_inst)
	
	var collision = _create_rock_collision(size_mult)
	root.add_child(collision)
	
	return root

static func _generate_icosphere(subdivisions: int) -> PackedVector3Array:
	var t = (1.0 + sqrt(5.0)) / 2.0
	
	var vertices := PackedVector3Array([
		Vector3(-1, t, 0).normalized(),
		Vector3(1, t, 0).normalized(),
		Vector3(-1, -t, 0).normalized(),
		Vector3(1, -t, 0).normalized(),
		Vector3(0, -1, t).normalized(),
		Vector3(0, 1, t).normalized(),
		Vector3(0, -1, -t).normalized(),
		Vector3(0, 1, -t).normalized(),
		Vector3(t, 0, -1).normalized(),
		Vector3(t, 0, 1).normalized(),
		Vector3(-t, 0, -1).normalized(),
		Vector3(-t, 0, 1).normalized()
	])
	
	var faces := [
		[0, 11, 5], [0, 5, 1], [0, 1, 7], [0, 7, 10], [0, 10, 11],
		[1, 5, 9], [5, 11, 4], [11, 10, 2], [10, 7, 6], [7, 1, 8],
		[3, 9, 4], [3, 4, 2], [3, 2, 6], [3, 6, 8], [3, 8, 9],
		[4, 9, 5], [2, 4, 11], [6, 2, 10], [8, 6, 7], [9, 8, 1]
	]
	
	for _sub in range(subdivisions):
		var new_faces := []
		for face in faces:
			var a = vertices[face[0]]
			var b = vertices[face[1]]
			var c = vertices[face[2]]
			
			var ab = ((a + b) / 2.0).normalized()
			var bc = ((b + c) / 2.0).normalized()
			var ca = ((c + a) / 2.0).normalized()
			
			var i_a = face[0]
			var i_b = face[1]
			var i_c = face[2]
			var i_ab = vertices.size()
			vertices.append(ab)
			var i_bc = vertices.size()
			vertices.append(bc)
			var i_ca = vertices.size()
			vertices.append(ca)
			
			new_faces.append([i_a, i_ab, i_ca])
			new_faces.append([i_b, i_bc, i_ab])
			new_faces.append([i_c, i_ca, i_bc])
			new_faces.append([i_ab, i_bc, i_ca])
		
		faces = new_faces
	
	var result := PackedVector3Array()
	for face in faces:
		result.append(vertices[face[0]])
		result.append(vertices[face[1]])
		result.append(vertices[face[2]])
	
	return result

static func _apply_ore_tint(node: Node3D, ore_type: String):
	var color = ore_colors.get(ore_type, Color(0.5, 0.5, 0.5))
	
	for child in node.get_children():
		if child is MeshInstance3D:
			var mat = StandardMaterial3D.new()
			mat.albedo_color = color.lerp(Color(0.5, 0.5, 0.5), 0.5)
			mat.roughness = 0.85
			mat.metallic = 0.1 if ore_type in ["iron_ore", "gold_ore", "copper_ore", "silver_ore"] else 0.0
			child.material_override = mat
		if child is Node3D:
			_apply_ore_tint(child, ore_type)

static func _create_rock_collision(size_mult: float) -> CollisionShape3D:
	var col = CollisionShape3D.new()
	col.name = "Collision"
	
	var shape = ConvexPolygonShape3D.new()
	var points := PackedVector3Array()
	
	for i in range(8):
		var angle = float(i) / 8.0 * TAU
		points.append(Vector3(cos(angle) * 0.5 * size_mult, 0.2 * size_mult, sin(angle) * 0.4 * size_mult))
		points.append(Vector3(cos(angle) * 0.3 * size_mult, 0.5 * size_mult, sin(angle) * 0.25 * size_mult))
	
	points.append(Vector3(0, 0, 0))
	points.append(Vector3(0, 0.7 * size_mult, 0))
	
	shape.points = points
	col.shape = shape
	
	return col

static func _create_ore_spots(ore_type: String, size_mult: float) -> Array:
	var spots := []
	var color = ore_colors.get(ore_type, Color(0.5, 0.5, 0.5))
	var num_spots = randi_range(3, 6)
	
	for i in range(num_spots):
		var spot = MeshInstance3D.new()
		spot.name = "OreSpot%d" % i
		
		var sphere = SphereMesh.new()
		sphere.radius = randf_range(0.08, 0.15) * size_mult
		sphere.height = sphere.radius * 2
		sphere.radial_segments = 8
		sphere.rings = 4
		spot.mesh = sphere
		
		var angle = randf() * TAU
		var height = randf_range(0.1, 0.5) * size_mult
		var radius = randf_range(0.3, 0.6) * size_mult
		spot.position = Vector3(cos(angle) * radius, height, sin(angle) * radius)
		
		var mat = StandardMaterial3D.new()
		mat.albedo_color = color
		mat.roughness = 0.4
		mat.metallic = 0.6 if ore_type in ["iron_ore", "gold_ore", "copper_ore", "silver_ore", "titanium_ore"] else 0.1
		mat.emission_enabled = ore_type == "sulfur"
		if mat.emission_enabled:
			mat.emission = Color(0.8, 0.7, 0.2)
			mat.emission_energy_multiplier = 0.3
		spot.material_override = mat
		
		spots.append(spot)
	
	return spots
