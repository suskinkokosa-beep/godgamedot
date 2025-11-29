extends Node

const PLANK_WIDTH := 0.15
const PLANK_DEPTH := 0.05
const BEAM_SIZE := 0.12
const STONE_BLOCK_SIZE := 0.4
const METAL_PLATE_THICKNESS := 0.02

var wood_material: StandardMaterial3D
var stone_material: StandardMaterial3D
var metal_material: StandardMaterial3D
var steel_material: StandardMaterial3D
var cloth_material: StandardMaterial3D

var materials_cache := {}

func _ready():
	_create_materials()

func _create_materials():
	wood_material = _create_wood_material()
	stone_material = _create_stone_material()
	metal_material = _create_metal_material()
	steel_material = _create_steel_material()
	cloth_material = _create_cloth_material()
	
	materials_cache["wood"] = wood_material
	materials_cache["stone"] = stone_material
	materials_cache["metal"] = metal_material
	materials_cache["iron"] = metal_material
	materials_cache["steel"] = steel_material
	materials_cache["cloth"] = cloth_material

func _create_wood_material() -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.55, 0.35, 0.18)
	mat.roughness = 0.75
	mat.metallic = 0.0
	mat.normal_enabled = true
	
	var normal_tex = _generate_wood_normal()
	if normal_tex:
		mat.normal_texture = normal_tex
		mat.normal_scale = 0.8
	
	mat.ao_enabled = true
	mat.ao_light_affect = 0.4
	
	return mat

func _create_stone_material() -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.5, 0.48, 0.45)
	mat.roughness = 0.85
	mat.metallic = 0.0
	mat.normal_enabled = true
	
	var normal_tex = _generate_stone_normal()
	if normal_tex:
		mat.normal_texture = normal_tex
		mat.normal_scale = 1.0
	
	mat.ao_enabled = true
	mat.ao_light_affect = 0.5
	
	return mat

func _create_metal_material() -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.55, 0.55, 0.6)
	mat.roughness = 0.35
	mat.metallic = 0.85
	mat.metallic_specular = 0.6
	
	var normal_tex = _generate_metal_normal()
	if normal_tex:
		mat.normal_texture = normal_tex
		mat.normal_scale = 0.3
	
	return mat

func _create_steel_material() -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.7, 0.7, 0.75)
	mat.roughness = 0.2
	mat.metallic = 0.95
	mat.metallic_specular = 0.8
	mat.clearcoat_enabled = true
	mat.clearcoat = 0.3
	mat.clearcoat_roughness = 0.1
	
	return mat

func _create_cloth_material() -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.6, 0.5, 0.4)
	mat.roughness = 0.95
	mat.metallic = 0.0
	
	return mat

func _generate_wood_normal() -> ImageTexture:
	var img = Image.create(64, 64, false, Image.FORMAT_RGB8)
	var rng = RandomNumberGenerator.new()
	rng.seed = 12345
	
	for y in range(64):
		for x in range(64):
			var grain = sin(float(y) * 0.5 + rng.randf() * 0.3) * 0.5 + 0.5
			var noise_val = rng.randf_range(-0.1, 0.1)
			var nx = 0.5 + noise_val
			var ny = 0.5 + grain * 0.1
			var nz = 1.0
			img.set_pixel(x, y, Color(nx, ny, nz))
	
	var tex = ImageTexture.create_from_image(img)
	return tex

func _generate_stone_normal() -> ImageTexture:
	var img = Image.create(64, 64, false, Image.FORMAT_RGB8)
	var rng = RandomNumberGenerator.new()
	rng.seed = 54321
	
	for y in range(64):
		for x in range(64):
			var nx = 0.5 + rng.randf_range(-0.15, 0.15)
			var ny = 0.5 + rng.randf_range(-0.15, 0.15)
			var nz = 1.0
			img.set_pixel(x, y, Color(nx, ny, nz))
	
	var tex = ImageTexture.create_from_image(img)
	return tex

func _generate_metal_normal() -> ImageTexture:
	var img = Image.create(32, 32, false, Image.FORMAT_RGB8)
	var rng = RandomNumberGenerator.new()
	rng.seed = 99999
	
	for y in range(32):
		for x in range(32):
			var scratch = 0.0
			if rng.randf() < 0.05:
				scratch = rng.randf_range(-0.2, 0.2)
			var nx = 0.5 + scratch
			var ny = 0.5 + rng.randf_range(-0.02, 0.02)
			var nz = 1.0
			img.set_pixel(x, y, Color(nx, ny, nz))
	
	var tex = ImageTexture.create_from_image(img)
	return tex

func get_material(material_type: String) -> StandardMaterial3D:
	if materials_cache.has(material_type):
		return materials_cache[material_type].duplicate()
	return wood_material.duplicate()

func create_building_part(part_type: String, material_type: String, size: Vector3 = Vector3.ZERO) -> Node3D:
	match part_type:
		"foundation":
			return _create_foundation(material_type, size)
		"wall":
			return _create_wall(material_type, size)
		"floor":
			return _create_floor(material_type, size)
		"roof":
			return _create_roof(material_type, size)
		"door_frame", "doorframe":
			return _create_doorframe(material_type, size)
		"window":
			return _create_window_wall(material_type, size)
		"stairs":
			return _create_stairs(material_type, size)
		"workbench":
			return _create_workbench(material_type, size)
		"furnace":
			return _create_furnace(size)
		"campfire":
			return _create_campfire(size)
		"box", "large_box":
			return _create_storage_box(material_type, size)
		"cupboard":
			return _create_tool_cupboard(size)
		"bed":
			return _create_bed(material_type, size)
		_:
			return _create_placeholder(material_type, size)
	
	return null

func _create_foundation(material_type: String, size: Vector3) -> Node3D:
	var root = Node3D.new()
	root.name = "Foundation"
	
	if size == Vector3.ZERO:
		size = Vector3(4, 0.5, 4)
	
	var mat = get_material(material_type)
	
	if material_type == "wood":
		var base = _create_wooden_platform(size, mat)
		root.add_child(base)
		
		var support_positions = [
			Vector3(-size.x/2 + 0.2, -size.y/2, -size.z/2 + 0.2),
			Vector3(size.x/2 - 0.2, -size.y/2, -size.z/2 + 0.2),
			Vector3(-size.x/2 + 0.2, -size.y/2, size.z/2 - 0.2),
			Vector3(size.x/2 - 0.2, -size.y/2, size.z/2 - 0.2)
		]
		
		for pos in support_positions:
			var beam = _create_support_beam(Vector3(BEAM_SIZE * 2, 1.0, BEAM_SIZE * 2), mat)
			beam.position = pos - Vector3(0, 0.5, 0)
			root.add_child(beam)
	else:
		var slab = _create_stone_slab(size, mat)
		root.add_child(slab)
	
	return root

func _create_wooden_platform(size: Vector3, mat: StandardMaterial3D) -> MeshInstance3D:
	var mesh_inst = MeshInstance3D.new()
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_material(mat)
	
	var plank_count = int(size.x / PLANK_WIDTH)
	var half_x = size.x / 2
	var half_z = size.z / 2
	
	for i in range(plank_count):
		var x_offset = -half_x + i * PLANK_WIDTH + PLANK_WIDTH / 2
		var plank_height = size.y * 0.9 + randf_range(-0.02, 0.02)
		
		_add_box_to_surface_tool(st, 
			Vector3(x_offset, 0, 0),
			Vector3(PLANK_WIDTH * 0.95, plank_height, size.z * 0.98))
	
	var cross_beam_mat = mat.duplicate()
	cross_beam_mat.albedo_color = mat.albedo_color * 0.85
	
	for z_pos in [-half_z + 0.3, 0, half_z - 0.3]:
		_add_box_to_surface_tool(st,
			Vector3(0, -size.y/2 + BEAM_SIZE/2, z_pos),
			Vector3(size.x, BEAM_SIZE, BEAM_SIZE * 1.5))
	
	mesh_inst.mesh = st.commit()
	return mesh_inst

func _create_stone_slab(size: Vector3, mat: StandardMaterial3D) -> MeshInstance3D:
	var mesh_inst = MeshInstance3D.new()
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_material(mat)
	
	_add_box_to_surface_tool(st, Vector3.ZERO, size)
	
	var edge_mat = mat.duplicate()
	edge_mat.albedo_color = mat.albedo_color * 0.9
	
	var edge_height = 0.08
	_add_box_to_surface_tool(st, Vector3(0, size.y/2 + edge_height/2, 0), 
		Vector3(size.x + 0.05, edge_height, size.z + 0.05))
	
	mesh_inst.mesh = st.commit()
	return mesh_inst

func _create_support_beam(size: Vector3, mat: StandardMaterial3D) -> MeshInstance3D:
	var mesh_inst = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = size
	mesh_inst.mesh = box
	mesh_inst.material_override = mat
	return mesh_inst

func _create_wall(material_type: String, size: Vector3) -> Node3D:
	var root = Node3D.new()
	root.name = "Wall"
	
	if size == Vector3.ZERO:
		size = Vector3(4, 3, 0.2)
	
	var mat = get_material(material_type)
	
	if material_type == "wood":
		var wall_mesh = _create_wooden_wall_mesh(size, mat)
		root.add_child(wall_mesh)
		
		var frame = _create_wall_frame(size, mat)
		root.add_child(frame)
	elif material_type in ["stone", "metal", "steel"]:
		var wall_mesh = _create_solid_wall_mesh(size, mat, material_type)
		root.add_child(wall_mesh)
	else:
		var wall_mesh = _create_solid_wall_mesh(size, mat, "wood")
		root.add_child(wall_mesh)
	
	return root

func _create_wooden_wall_mesh(size: Vector3, mat: StandardMaterial3D) -> MeshInstance3D:
	var mesh_inst = MeshInstance3D.new()
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_material(mat)
	
	var plank_count = int(size.y / (PLANK_WIDTH * 1.5))
	var half_y = size.y / 2
	
	for i in range(plank_count):
		var y_offset = -half_y + i * PLANK_WIDTH * 1.5 + PLANK_WIDTH * 0.75
		var plank_width = PLANK_WIDTH * 1.4 + randf_range(-0.01, 0.01)
		
		_add_box_to_surface_tool(st,
			Vector3(0, y_offset, 0),
			Vector3(size.x * 0.96, plank_width, size.z * 0.8))
	
	mesh_inst.mesh = st.commit()
	return mesh_inst

func _create_wall_frame(size: Vector3, mat: StandardMaterial3D) -> MeshInstance3D:
	var mesh_inst = MeshInstance3D.new()
	var frame_mat = mat.duplicate()
	frame_mat.albedo_color = mat.albedo_color * 0.8
	
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_material(frame_mat)
	
	_add_box_to_surface_tool(st, Vector3(-size.x/2 + BEAM_SIZE/2, 0, 0), 
		Vector3(BEAM_SIZE, size.y, size.z))
	_add_box_to_surface_tool(st, Vector3(size.x/2 - BEAM_SIZE/2, 0, 0), 
		Vector3(BEAM_SIZE, size.y, size.z))
	
	_add_box_to_surface_tool(st, Vector3(0, size.y/2 - BEAM_SIZE/2, 0), 
		Vector3(size.x, BEAM_SIZE, size.z))
	_add_box_to_surface_tool(st, Vector3(0, -size.y/2 + BEAM_SIZE/2, 0), 
		Vector3(size.x, BEAM_SIZE, size.z))
	
	mesh_inst.mesh = st.commit()
	return mesh_inst

func _create_solid_wall_mesh(size: Vector3, mat: StandardMaterial3D, material_type: String) -> MeshInstance3D:
	var mesh_inst = MeshInstance3D.new()
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_material(mat)
	
	if material_type == "stone":
		var block_rows = int(size.y / STONE_BLOCK_SIZE)
		var block_cols = int(size.x / (STONE_BLOCK_SIZE * 1.5))
		
		for row in range(block_rows):
			var offset = (row % 2) * STONE_BLOCK_SIZE * 0.5
			for col in range(block_cols + 1):
				var x_pos = -size.x/2 + col * STONE_BLOCK_SIZE * 1.5 + offset
				var y_pos = -size.y/2 + row * STONE_BLOCK_SIZE + STONE_BLOCK_SIZE/2
				
				if abs(x_pos) < size.x/2:
					var block_width = STONE_BLOCK_SIZE * 1.4 + randf_range(-0.05, 0.05)
					var block_height = STONE_BLOCK_SIZE * 0.95 + randf_range(-0.02, 0.02)
					
					_add_box_to_surface_tool(st, Vector3(x_pos, y_pos, 0),
						Vector3(block_width, block_height, size.z * 0.9))
	else:
		_add_box_to_surface_tool(st, Vector3.ZERO, size)
		
		if material_type in ["metal", "steel"]:
			var rivet_mat = mat.duplicate()
			rivet_mat.albedo_color = mat.albedo_color * 0.7
			
			for x in range(-int(size.x/2) + 1, int(size.x/2), 1):
				for y in range(-int(size.y/2) + 1, int(size.y/2), 1):
					_add_box_to_surface_tool(st, 
						Vector3(x * 0.8, y * 0.8, size.z/2 + 0.01),
						Vector3(0.03, 0.03, 0.02))
	
	mesh_inst.mesh = st.commit()
	return mesh_inst

func _create_floor(material_type: String, size: Vector3) -> Node3D:
	var root = Node3D.new()
	root.name = "Floor"
	
	if size == Vector3.ZERO:
		size = Vector3(4, 0.1, 4)
	
	var mat = get_material(material_type)
	
	if material_type == "wood":
		var floor_mesh = _create_wooden_floor_mesh(size, mat)
		root.add_child(floor_mesh)
	else:
		var floor_mesh = MeshInstance3D.new()
		var box = BoxMesh.new()
		box.size = size
		floor_mesh.mesh = box
		floor_mesh.material_override = mat
		root.add_child(floor_mesh)
	
	return root

func _create_wooden_floor_mesh(size: Vector3, mat: StandardMaterial3D) -> MeshInstance3D:
	var mesh_inst = MeshInstance3D.new()
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_material(mat)
	
	var plank_count = int(size.x / PLANK_WIDTH)
	var half_x = size.x / 2
	
	for i in range(plank_count):
		var x_offset = -half_x + i * PLANK_WIDTH + PLANK_WIDTH / 2
		var plank_length = size.z * (0.9 + randf_range(0, 0.08))
		
		_add_box_to_surface_tool(st,
			Vector3(x_offset, 0, 0),
			Vector3(PLANK_WIDTH * 0.92, size.y, plank_length))
	
	mesh_inst.mesh = st.commit()
	return mesh_inst

func _create_roof(material_type: String, size: Vector3) -> Node3D:
	var root = Node3D.new()
	root.name = "Roof"
	
	if size == Vector3.ZERO:
		size = Vector3(4, 0.5, 4)
	
	var mat = get_material(material_type)
	
	var roof_mesh = MeshInstance3D.new()
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_material(mat)
	
	var apex_height = size.y * 2
	var half_x = size.x / 2
	var half_z = size.z / 2
	
	var verts = [
		Vector3(-half_x, 0, -half_z),
		Vector3(half_x, 0, -half_z),
		Vector3(half_x, 0, half_z),
		Vector3(-half_x, 0, half_z),
		Vector3(0, apex_height, -half_z),
		Vector3(0, apex_height, half_z)
	]
	
	_add_triangle(st, verts[0], verts[4], verts[1])
	_add_triangle(st, verts[2], verts[5], verts[3])
	_add_triangle(st, verts[0], verts[3], verts[4])
	_add_triangle(st, verts[3], verts[5], verts[4])
	_add_triangle(st, verts[1], verts[4], verts[5])
	_add_triangle(st, verts[1], verts[5], verts[2])
	
	roof_mesh.mesh = st.commit()
	root.add_child(roof_mesh)
	
	return root

func _create_doorframe(material_type: String, size: Vector3) -> Node3D:
	var root = Node3D.new()
	root.name = "Doorframe"
	
	if size == Vector3.ZERO:
		size = Vector3(4, 3, 0.2)
	
	var mat = get_material(material_type)
	var door_width = 1.0
	var door_height = 2.2
	
	var mesh_inst = MeshInstance3D.new()
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_material(mat)
	
	var left_width = (size.x - door_width) / 2
	_add_box_to_surface_tool(st, 
		Vector3(-size.x/2 + left_width/2, 0, 0),
		Vector3(left_width, size.y, size.z))
	
	_add_box_to_surface_tool(st, 
		Vector3(size.x/2 - left_width/2, 0, 0),
		Vector3(left_width, size.y, size.z))
	
	var top_height = size.y - door_height
	_add_box_to_surface_tool(st, 
		Vector3(0, size.y/2 - top_height/2, 0),
		Vector3(door_width + 0.1, top_height, size.z))
	
	mesh_inst.mesh = st.commit()
	root.add_child(mesh_inst)
	
	var door = _create_door(material_type, Vector3(door_width, door_height, size.z * 0.8))
	door.position = Vector3(0, -size.y/2 + door_height/2, 0)
	root.add_child(door)
	
	return root

func _create_door(material_type: String, size: Vector3) -> Node3D:
	var root = Node3D.new()
	root.name = "Door"
	
	var mat = get_material(material_type)
	var door_mat = mat.duplicate()
	door_mat.albedo_color = mat.albedo_color * 0.9
	
	var mesh_inst = MeshInstance3D.new()
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_material(door_mat)
	
	_add_box_to_surface_tool(st, Vector3.ZERO, size)
	
	if material_type == "wood":
		var panel_mat = mat.duplicate()
		panel_mat.albedo_color = mat.albedo_color * 0.85
		
		_add_box_to_surface_tool(st, Vector3(0, size.y * 0.25, size.z/2 + 0.01),
			Vector3(size.x * 0.7, size.y * 0.35, 0.02))
		_add_box_to_surface_tool(st, Vector3(0, -size.y * 0.2, size.z/2 + 0.01),
			Vector3(size.x * 0.7, size.y * 0.3, 0.02))
	
	var handle = MeshInstance3D.new()
	var handle_mesh = CylinderMesh.new()
	handle_mesh.top_radius = 0.02
	handle_mesh.bottom_radius = 0.02
	handle_mesh.height = 0.1
	handle.mesh = handle_mesh
	handle.position = Vector3(size.x * 0.35, 0, size.z/2 + 0.05)
	handle.rotation.x = PI/2
	
	var handle_mat = metal_material.duplicate()
	handle_mat.albedo_color = Color(0.3, 0.3, 0.35)
	handle.material_override = handle_mat
	root.add_child(handle)
	
	mesh_inst.mesh = st.commit()
	root.add_child(mesh_inst)
	
	return root

func _create_window_wall(material_type: String, size: Vector3) -> Node3D:
	var root = Node3D.new()
	root.name = "WindowWall"
	
	if size == Vector3.ZERO:
		size = Vector3(4, 3, 0.2)
	
	var mat = get_material(material_type)
	var window_width = 1.2
	var window_height = 1.0
	var window_y_offset = 0.3
	
	var mesh_inst = MeshInstance3D.new()
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_material(mat)
	
	var left_width = (size.x - window_width) / 2
	_add_box_to_surface_tool(st, 
		Vector3(-size.x/2 + left_width/2, 0, 0),
		Vector3(left_width, size.y, size.z))
	
	_add_box_to_surface_tool(st, 
		Vector3(size.x/2 - left_width/2, 0, 0),
		Vector3(left_width, size.y, size.z))
	
	var bottom_height = (size.y - window_height) / 2 + window_y_offset
	_add_box_to_surface_tool(st, 
		Vector3(0, -size.y/2 + bottom_height/2, 0),
		Vector3(window_width, bottom_height, size.z))
	
	var top_height = size.y - bottom_height - window_height
	_add_box_to_surface_tool(st, 
		Vector3(0, size.y/2 - top_height/2, 0),
		Vector3(window_width, top_height, size.z))
	
	mesh_inst.mesh = st.commit()
	root.add_child(mesh_inst)
	
	var glass = MeshInstance3D.new()
	var glass_mesh = BoxMesh.new()
	glass_mesh.size = Vector3(window_width - 0.1, window_height - 0.1, 0.02)
	glass.mesh = glass_mesh
	glass.position = Vector3(0, window_y_offset, 0)
	
	var glass_mat = StandardMaterial3D.new()
	glass_mat.albedo_color = Color(0.7, 0.8, 0.9, 0.3)
	glass_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass_mat.metallic = 0.1
	glass_mat.roughness = 0.1
	glass.material_override = glass_mat
	root.add_child(glass)
	
	return root

func _create_stairs(material_type: String, size: Vector3) -> Node3D:
	var root = Node3D.new()
	root.name = "Stairs"
	
	if size == Vector3.ZERO:
		size = Vector3(2, 3, 4)
	
	var mat = get_material(material_type)
	var step_count = 8
	var step_height = size.y / step_count
	var step_depth = size.z / step_count
	
	var mesh_inst = MeshInstance3D.new()
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_material(mat)
	
	for i in range(step_count):
		var step_y = -size.y/2 + i * step_height + step_height/2
		var step_z = -size.z/2 + i * step_depth + step_depth/2
		
		_add_box_to_surface_tool(st,
			Vector3(0, step_y, step_z),
			Vector3(size.x, step_height * 0.95, step_depth * 0.95))
	
	var stringer_mat = mat.duplicate()
	stringer_mat.albedo_color = mat.albedo_color * 0.85
	
	_add_box_to_surface_tool(st,
		Vector3(-size.x/2 + BEAM_SIZE/2, 0, 0),
		Vector3(BEAM_SIZE, size.y * 1.1, size.z))
	_add_box_to_surface_tool(st,
		Vector3(size.x/2 - BEAM_SIZE/2, 0, 0),
		Vector3(BEAM_SIZE, size.y * 1.1, size.z))
	
	mesh_inst.mesh = st.commit()
	root.add_child(mesh_inst)
	
	return root

func _create_workbench(material_type: String, size: Vector3) -> Node3D:
	var root = Node3D.new()
	root.name = "Workbench"
	
	if size == Vector3.ZERO:
		size = Vector3(2, 1, 1)
	
	var mat = get_material(material_type)
	
	var mesh_inst = MeshInstance3D.new()
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_material(mat)
	
	var top_height = 0.1
	_add_box_to_surface_tool(st,
		Vector3(0, size.y/2 - top_height/2, 0),
		Vector3(size.x, top_height, size.z))
	
	var leg_size = 0.08
	var leg_height = size.y - top_height
	var positions = [
		Vector3(-size.x/2 + leg_size, -top_height/2, -size.z/2 + leg_size),
		Vector3(size.x/2 - leg_size, -top_height/2, -size.z/2 + leg_size),
		Vector3(-size.x/2 + leg_size, -top_height/2, size.z/2 - leg_size),
		Vector3(size.x/2 - leg_size, -top_height/2, size.z/2 - leg_size)
	]
	
	for pos in positions:
		_add_box_to_surface_tool(st, pos, Vector3(leg_size * 2, leg_height, leg_size * 2))
	
	if material_type in ["iron", "steel"]:
		var tool_mat = metal_material.duplicate()
		tool_mat.albedo_color = Color(0.4, 0.4, 0.45)
		
		_add_box_to_surface_tool(st,
			Vector3(-size.x * 0.3, size.y/2 + 0.02, 0),
			Vector3(0.15, 0.04, 0.4))
		_add_box_to_surface_tool(st,
			Vector3(size.x * 0.2, size.y/2 + 0.03, -size.z * 0.2),
			Vector3(0.1, 0.06, 0.1))
	
	mesh_inst.mesh = st.commit()
	root.add_child(mesh_inst)
	
	return root

func _create_furnace(size: Vector3) -> Node3D:
	var root = Node3D.new()
	root.name = "Furnace"
	
	if size == Vector3.ZERO:
		size = Vector3(1.5, 1.5, 1.5)
	
	var mat = stone_material.duplicate()
	mat.albedo_color = Color(0.35, 0.32, 0.3)
	
	var mesh_inst = MeshInstance3D.new()
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_material(mat)
	
	_add_box_to_surface_tool(st, Vector3.ZERO, size)
	
	var opening_mat = StandardMaterial3D.new()
	opening_mat.albedo_color = Color(0.1, 0.08, 0.05)
	opening_mat.emission_enabled = true
	opening_mat.emission = Color(1.0, 0.3, 0.1)
	opening_mat.emission_energy_multiplier = 0.3
	
	_add_box_to_surface_tool(st,
		Vector3(0, -size.y * 0.1, size.z/2 + 0.01),
		Vector3(size.x * 0.5, size.y * 0.4, 0.02))
	
	var chimney_mat = mat.duplicate()
	chimney_mat.albedo_color = mat.albedo_color * 0.9
	_add_box_to_surface_tool(st,
		Vector3(0, size.y/2 + size.y * 0.25, -size.z * 0.2),
		Vector3(size.x * 0.3, size.y * 0.5, size.z * 0.3))
	
	mesh_inst.mesh = st.commit()
	root.add_child(mesh_inst)
	
	return root

func _create_campfire(size: Vector3) -> Node3D:
	var root = Node3D.new()
	root.name = "Campfire"
	
	if size == Vector3.ZERO:
		size = Vector3(1, 0.3, 1)
	
	var stones_mat = stone_material.duplicate()
	stones_mat.albedo_color = Color(0.4, 0.38, 0.35)
	
	var mesh_inst = MeshInstance3D.new()
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_material(stones_mat)
	
	var stone_count = 8
	for i in range(stone_count):
		var angle = (float(i) / stone_count) * TAU
		var radius = size.x * 0.4
		var stone_pos = Vector3(cos(angle) * radius, 0, sin(angle) * radius)
		var stone_size = Vector3(0.15, 0.12, 0.15) * (0.8 + randf() * 0.4)
		_add_box_to_surface_tool(st, stone_pos, stone_size)
	
	mesh_inst.mesh = st.commit()
	root.add_child(mesh_inst)
	
	var wood_mat = wood_material.duplicate()
	wood_mat.albedo_color = Color(0.3, 0.2, 0.1)
	
	var logs = MeshInstance3D.new()
	var log_st = SurfaceTool.new()
	log_st.begin(Mesh.PRIMITIVE_TRIANGLES)
	log_st.set_material(wood_mat)
	
	for i in range(3):
		var angle = (float(i) / 3) * TAU + PI/6
		_add_box_to_surface_tool(log_st,
			Vector3(cos(angle) * 0.1, 0.08, sin(angle) * 0.1),
			Vector3(0.08, 0.08, size.z * 0.6))
	
	logs.mesh = log_st.commit()
	root.add_child(logs)
	
	return root

func _create_storage_box(material_type: String, size: Vector3) -> Node3D:
	var root = Node3D.new()
	root.name = "StorageBox"
	
	if size == Vector3.ZERO:
		size = Vector3(1, 0.8, 0.5)
	
	var mat = get_material(material_type)
	
	var mesh_inst = MeshInstance3D.new()
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_material(mat)
	
	_add_box_to_surface_tool(st, Vector3.ZERO, size)
	
	var trim_mat = mat.duplicate()
	trim_mat.albedo_color = mat.albedo_color * 0.75
	
	_add_box_to_surface_tool(st, Vector3(0, size.y/2, 0), 
		Vector3(size.x + 0.02, 0.04, size.z + 0.02))
	
	_add_box_to_surface_tool(st, Vector3(-size.x/2, 0, 0),
		Vector3(0.04, size.y, size.z + 0.02))
	_add_box_to_surface_tool(st, Vector3(size.x/2, 0, 0),
		Vector3(0.04, size.y, size.z + 0.02))
	
	var handle_mat = metal_material.duplicate()
	handle_mat.albedo_color = Color(0.35, 0.32, 0.3)
	
	_add_box_to_surface_tool(st, Vector3(0, size.y/2 + 0.03, size.z/2 + 0.02),
		Vector3(0.15, 0.02, 0.03))
	
	mesh_inst.mesh = st.commit()
	root.add_child(mesh_inst)
	
	return root

func _create_tool_cupboard(size: Vector3) -> Node3D:
	var root = Node3D.new()
	root.name = "ToolCupboard"
	
	if size == Vector3.ZERO:
		size = Vector3(1, 1.5, 0.5)
	
	var mat = wood_material.duplicate()
	mat.albedo_color = Color(0.45, 0.3, 0.18)
	
	var mesh_inst = MeshInstance3D.new()
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_material(mat)
	
	var thickness = 0.05
	
	_add_box_to_surface_tool(st, Vector3(-size.x/2 + thickness/2, 0, 0),
		Vector3(thickness, size.y, size.z))
	_add_box_to_surface_tool(st, Vector3(size.x/2 - thickness/2, 0, 0),
		Vector3(thickness, size.y, size.z))
	_add_box_to_surface_tool(st, Vector3(0, 0, -size.z/2 + thickness/2),
		Vector3(size.x - thickness*2, size.y, thickness))
	_add_box_to_surface_tool(st, Vector3(0, size.y/2 - thickness/2, 0),
		Vector3(size.x, thickness, size.z))
	_add_box_to_surface_tool(st, Vector3(0, -size.y/2 + thickness/2, 0),
		Vector3(size.x, thickness, size.z))
	
	for i in range(3):
		var shelf_y = -size.y/2 + (i + 1) * size.y / 4
		_add_box_to_surface_tool(st, Vector3(0, shelf_y, 0),
			Vector3(size.x - thickness*2, thickness * 0.8, size.z - thickness))
	
	mesh_inst.mesh = st.commit()
	root.add_child(mesh_inst)
	
	return root

func _create_bed(material_type: String, size: Vector3) -> Node3D:
	var root = Node3D.new()
	root.name = "Bed"
	
	if size == Vector3.ZERO:
		size = Vector3(1, 0.5, 2)
	
	var frame_mat = get_material("wood")
	var cloth_mat = self.cloth_material.duplicate()
	
	var mesh_inst = MeshInstance3D.new()
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_material(frame_mat)
	
	var frame_height = size.y * 0.4
	_add_box_to_surface_tool(st, Vector3(0, -size.y/2 + frame_height/2, 0),
		Vector3(size.x, frame_height, size.z))
	
	var leg_size = 0.06
	var leg_height = size.y * 0.3
	var leg_positions = [
		Vector3(-size.x/2 + leg_size, -size.y/2 - leg_height/2, -size.z/2 + leg_size),
		Vector3(size.x/2 - leg_size, -size.y/2 - leg_height/2, -size.z/2 + leg_size),
		Vector3(-size.x/2 + leg_size, -size.y/2 - leg_height/2, size.z/2 - leg_size),
		Vector3(size.x/2 - leg_size, -size.y/2 - leg_height/2, size.z/2 - leg_size)
	]
	
	for pos in leg_positions:
		_add_box_to_surface_tool(st, pos, Vector3(leg_size * 2, leg_height, leg_size * 2))
	
	_add_box_to_surface_tool(st, Vector3(0, size.y * 0.2, -size.z/2 + 0.05),
		Vector3(size.x, size.y * 0.8, 0.08))
	
	mesh_inst.mesh = st.commit()
	root.add_child(mesh_inst)
	
	var mattress = MeshInstance3D.new()
	var mattress_mesh = BoxMesh.new()
	mattress_mesh.size = Vector3(size.x * 0.9, size.y * 0.3, size.z * 0.85)
	mattress.mesh = mattress_mesh
	mattress.position = Vector3(0, 0, size.z * 0.05)
	mattress.material_override = cloth_mat
	root.add_child(mattress)
	
	var pillow_mat = cloth_mat.duplicate()
	pillow_mat.albedo_color = Color(0.85, 0.82, 0.78)
	
	var pillow = MeshInstance3D.new()
	var pillow_mesh = BoxMesh.new()
	pillow_mesh.size = Vector3(size.x * 0.7, 0.1, 0.3)
	pillow.mesh = pillow_mesh
	pillow.position = Vector3(0, size.y * 0.2, -size.z/2 + 0.25)
	pillow.material_override = pillow_mat
	root.add_child(pillow)
	
	return root

func _create_placeholder(material_type: String, size: Vector3) -> Node3D:
	var root = Node3D.new()
	root.name = "Placeholder"
	
	if size == Vector3.ZERO:
		size = Vector3(1, 1, 1)
	
	var mesh_inst = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = size
	mesh_inst.mesh = box
	mesh_inst.material_override = get_material(material_type)
	root.add_child(mesh_inst)
	
	return root

func _add_box_to_surface_tool(st: SurfaceTool, center: Vector3, size: Vector3):
	var half = size / 2
	
	var vertices = [
		center + Vector3(-half.x, -half.y, -half.z),
		center + Vector3(half.x, -half.y, -half.z),
		center + Vector3(half.x, half.y, -half.z),
		center + Vector3(-half.x, half.y, -half.z),
		center + Vector3(-half.x, -half.y, half.z),
		center + Vector3(half.x, -half.y, half.z),
		center + Vector3(half.x, half.y, half.z),
		center + Vector3(-half.x, half.y, half.z)
	]
	
	var faces = [
		[0, 1, 2, 3],
		[5, 4, 7, 6],
		[4, 0, 3, 7],
		[1, 5, 6, 2],
		[3, 2, 6, 7],
		[4, 5, 1, 0]
	]
	
	var normals = [
		Vector3(0, 0, -1),
		Vector3(0, 0, 1),
		Vector3(-1, 0, 0),
		Vector3(1, 0, 0),
		Vector3(0, 1, 0),
		Vector3(0, -1, 0)
	]
	
	for i in range(6):
		var face = faces[i]
		var normal = normals[i]
		
		st.set_normal(normal)
		st.add_vertex(vertices[face[0]])
		st.set_normal(normal)
		st.add_vertex(vertices[face[1]])
		st.set_normal(normal)
		st.add_vertex(vertices[face[2]])
		
		st.set_normal(normal)
		st.add_vertex(vertices[face[0]])
		st.set_normal(normal)
		st.add_vertex(vertices[face[2]])
		st.set_normal(normal)
		st.add_vertex(vertices[face[3]])

func _add_triangle(st: SurfaceTool, v1: Vector3, v2: Vector3, v3: Vector3):
	var normal = (v2 - v1).cross(v3 - v1).normalized()
	
	st.set_normal(normal)
	st.add_vertex(v1)
	st.set_normal(normal)
	st.add_vertex(v2)
	st.set_normal(normal)
	st.add_vertex(v3)
