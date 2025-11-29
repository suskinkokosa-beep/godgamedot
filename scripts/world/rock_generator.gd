extends Node
class_name RockGenerator

static var rock_meshes := {}

static func create_rock(variant: int = -1, size_mult: float = 1.0) -> Node3D:
	var root = Node3D.new()
	
	if variant < 0:
		variant = randi() % 30
	
	var obj_path = "res://assets/art_pack/environment/rock_var_%d.obj" % variant
	
	if ResourceLoader.exists(obj_path):
		var mesh_inst = MeshInstance3D.new()
		mesh_inst.name = "RockMesh"
		
		if rock_meshes.has(variant):
			mesh_inst.mesh = rock_meshes[variant]
		else:
			mesh_inst.mesh = load(obj_path)
			rock_meshes[variant] = mesh_inst.mesh
		
		mesh_inst.scale = Vector3.ONE * size_mult
		mesh_inst.material_override = _create_rock_material()
		
		root.add_child(mesh_inst)
		
		var collision = _create_rock_collision(size_mult)
		root.add_child(collision)
	else:
		var procedural = _create_procedural_rock(size_mult)
		root.add_child(procedural)
	
	root.name = "Rock_%d" % variant
	return root

static func create_ore_node(ore_type: String, size_mult: float = 1.0) -> Node3D:
	var root = Node3D.new()
	root.name = ore_type.capitalize() + "Node"
	
	var rock = _create_procedural_rock(size_mult * 0.8)
	root.add_child(rock)
	
	var ore_spots = _create_ore_spots(ore_type, size_mult)
	for spot in ore_spots:
		root.add_child(spot)
	
	var collision = _create_rock_collision(size_mult * 0.8)
	root.add_child(collision)
	
	return root

static func _create_rock_material() -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	mat.diffuse_mode = BaseMaterial3D.DIFFUSE_BURLEY
	mat.specular_mode = BaseMaterial3D.SPECULAR_SCHLICK_GGX
	mat.roughness = 0.9
	mat.metallic = 0.0
	
	var stone_tex_path = "res://assets/art_pack/textures/albedo_stone.png"
	if ResourceLoader.exists(stone_tex_path):
		mat.albedo_texture = load(stone_tex_path)
		mat.albedo_color = Color(1, 1, 1)
		mat.uv1_scale = Vector3(2, 2, 2)
	else:
		mat.albedo_color = Color(0.5, 0.48, 0.45)
	
	return mat

static func _create_procedural_rock(size_mult: float) -> MeshInstance3D:
	var mesh_inst = MeshInstance3D.new()
	mesh_inst.name = "ProceduralRock"
	
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
	mesh_inst.material_override = _create_rock_material()
	
	return mesh_inst

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
	var color = _get_ore_color(ore_type)
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
		mat.metallic = 0.6 if ore_type in ["iron_ore", "gold_ore", "copper_ore"] else 0.1
		mat.emission_enabled = ore_type == "sulfur"
		if mat.emission_enabled:
			mat.emission = Color(0.8, 0.7, 0.2)
			mat.emission_energy_multiplier = 0.3
		spot.material_override = mat
		
		spots.append(spot)
	
	return spots

static func _get_ore_color(ore_type: String) -> Color:
	match ore_type:
		"iron_ore":
			return Color(0.45, 0.35, 0.3)
		"copper_ore":
			return Color(0.7, 0.45, 0.3)
		"gold_ore":
			return Color(0.85, 0.75, 0.3)
		"coal":
			return Color(0.15, 0.15, 0.15)
		"sulfur":
			return Color(0.85, 0.8, 0.3)
		"stone":
			return Color(0.55, 0.53, 0.5)
		_:
			return Color(0.5, 0.5, 0.5)
