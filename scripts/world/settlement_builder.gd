extends Node

signal settlement_spawned(settlement_id: int, position: Vector3)
signal building_placed(building_type: String, position: Vector3)

const VILLAGE_KIT_PATH = "res://assets/art_pack2/Medieval Village MegaKit[Standard]/glTF/"
const PROPS_KIT_PATH = "res://assets/art_pack2/Fantasy Props MegaKit/Exports/glTF/"
const NATURE_KIT_PATH = "res://assets/art_pack2/Stylized Nature MEGAKIT/glTF/"

var loaded_models := {}
var world_gen = null
var settlement_system = null

var building_templates := {
	"small_house": {
		"walls": ["Wall_Plaster_Door_Flat", "Wall_Plaster_Straight", "Wall_Plaster_Window_Wide_Flat"],
		"roof": "Roof_RoundTiles_4x4",
		"floor": "Floor_WoodDark",
		"size": Vector3(4, 3, 4),
		"npc_capacity": 2
	},
	"medium_house": {
		"walls": ["Wall_Plaster_Door_Round", "Wall_Plaster_Straight", "Wall_Plaster_Window_Wide_Round", "Wall_Plaster_WoodGrid"],
		"roof": "Roof_RoundTiles_6x6",
		"floor": "Floor_WoodLight",
		"size": Vector3(6, 4, 6),
		"npc_capacity": 4
	},
	"large_house": {
		"walls": ["Wall_UnevenBrick_Door_Round", "Wall_UnevenBrick_Straight", "Wall_UnevenBrick_Window_Wide_Round"],
		"roof": "Roof_RoundTiles_8x8",
		"floor": "Floor_Brick",
		"size": Vector3(8, 5, 8),
		"npc_capacity": 6
	},
	"tavern": {
		"walls": ["Wall_Plaster_Door_Round", "Wall_Plaster_WoodGrid", "Wall_Plaster_Window_Wide_Round"],
		"roof": "Roof_RoundTiles_8x10",
		"floor": "Floor_WoodDark",
		"size": Vector3(10, 5, 8),
		"npc_capacity": 8,
		"props": ["Table_Large", "Chair_1", "Barrel", "Mug"]
	},
	"blacksmith": {
		"walls": ["Wall_UnevenBrick_Door_Flat", "Wall_UnevenBrick_Straight"],
		"roof": "Roof_RoundTiles_6x8",
		"floor": "Floor_UnevenBrick",
		"size": Vector3(8, 4, 6),
		"npc_capacity": 2,
		"props": ["Anvil", "Workbench", "Barrel", "Crate_Metal"]
	},
	"shop": {
		"walls": ["Wall_Plaster_Door_Flat", "Wall_Plaster_Straight", "Wall_Plaster_Window_Wide_Flat"],
		"roof": "Roof_RoundTiles_6x6",
		"floor": "Floor_WoodLight",
		"size": Vector3(6, 4, 6),
		"npc_capacity": 3,
		"props": ["Shelf_Simple", "Crate_Wooden", "Barrel"]
	},
	"guard_tower": {
		"walls": ["Wall_UnevenBrick_Straight"],
		"roof": "Roof_Tower_RoundTiles",
		"floor": "Floor_Brick",
		"size": Vector3(4, 8, 4),
		"npc_capacity": 2
	},
	"well": {
		"base": "Prop_ExteriorBorder_Corner",
		"size": Vector3(2, 2, 2),
		"is_center": true
	},
	"market_stall": {
		"model": "Stall_Empty",
		"size": Vector3(3, 3, 2),
		"props": ["Barrel_Apples", "FarmCrate_Carrot"]
	}
}

var prop_models := [
	"Barrel", "Crate_Wooden", "Chest_Wood", "Bench", "Chair_1",
	"Table_Large", "Anvil", "Workbench", "Torch_Metal", "Lantern_Wall",
	"Bucket_Wooden_1", "Pot_1", "Stool", "FarmCrate_Empty"
]

func _ready():
	world_gen = get_node_or_null("/root/WorldGenerator")
	settlement_system = get_node_or_null("/root/SettlementSystem")
	_preload_models()

func _preload_models():
	var model_list := [
		"Wall_Plaster_Straight", "Wall_Plaster_Door_Flat", "Wall_Plaster_Door_Round",
		"Wall_Plaster_Window_Wide_Flat", "Wall_Plaster_Window_Wide_Round", "Wall_Plaster_WoodGrid",
		"Wall_UnevenBrick_Straight", "Wall_UnevenBrick_Door_Flat", "Wall_UnevenBrick_Door_Round",
		"Wall_UnevenBrick_Window_Wide_Flat", "Wall_UnevenBrick_Window_Wide_Round",
		"Floor_Brick", "Floor_WoodDark", "Floor_WoodLight", "Floor_UnevenBrick",
		"Roof_RoundTiles_4x4", "Roof_RoundTiles_6x6", "Roof_RoundTiles_6x8",
		"Roof_RoundTiles_8x8", "Roof_RoundTiles_8x10", "Roof_Tower_RoundTiles",
		"Door_1_Flat", "Door_1_Round", "Door_2_Flat",
		"Prop_WoodenFence_Single", "Prop_WoodenFence_Extension1",
		"Prop_Chimney", "Prop_Crate", "Prop_Wagon"
	]
	
	for model_name in model_list:
		var path = VILLAGE_KIT_PATH + model_name + ".gltf"
		if ResourceLoader.exists(path):
			loaded_models[model_name] = path
	
	var prop_list := [
		"Anvil", "Barrel", "Barrel_Apples", "Bench", "Chair_1", "Chest_Wood",
		"Crate_Wooden", "Crate_Metal", "FarmCrate_Carrot", "FarmCrate_Empty",
		"Lantern_Wall", "Shelf_Simple", "Stall_Empty", "Stool", "Table_Large",
		"Torch_Metal", "Workbench", "Bucket_Wooden_1", "Pot_1", "Cauldron"
	]
	
	for prop_name in prop_list:
		var path = PROPS_KIT_PATH + prop_name + ".gltf"
		if ResourceLoader.exists(path):
			loaded_models[prop_name] = path

func build_village(position: Vector3, size: int, faction: String = "town") -> Node3D:
	var village = Node3D.new()
	village.name = "Village_%d_%d" % [int(position.x), int(position.z)]
	village.position = position
	
	var rng = RandomNumberGenerator.new()
	rng.seed = hash(position)
	
	var center = _create_village_center(rng)
	village.add_child(center)
	
	var building_count = size * 2 + rng.randi_range(3, 6)
	var placed_buildings := []
	var building_data := []
	
	for i in range(building_count):
		var building_pos = _find_building_spot(placed_buildings, rng, 12.0, 8.0 + size * 6.0)
		if building_pos == Vector3.ZERO:
			continue
		
		var building_type = _choose_building_type(rng, "village")
		var building = _create_modular_building(building_type, rng)
		
		if building:
			var ground_y = _get_ground_height(position + building_pos)
			building.position = Vector3(building_pos.x, ground_y - position.y, building_pos.z)
			building.rotation.y = rng.randf_range(0, TAU)
			village.add_child(building)
			
			var template = building_templates.get(building_type, {})
			placed_buildings.append(building_pos)
			building_data.append({
				"position": building_pos,
				"type": building_type,
				"npc_capacity": template.get("npc_capacity", 2)
			})
	
	_add_village_decorations(village, rng, placed_buildings)
	_add_paths_between_buildings(village, rng, placed_buildings)
	
	var settlement_id = _register_settlement(position, "village", size, faction, building_data)
	emit_signal("settlement_spawned", settlement_id, position)
	
	return village

func build_city(position: Vector3, size: int, faction: String = "town") -> Node3D:
	var city = Node3D.new()
	city.name = "City_%d_%d" % [int(position.x), int(position.z)]
	city.position = position
	
	var rng = RandomNumberGenerator.new()
	rng.seed = hash(position)
	
	var wall_radius = size * 8.0
	_create_city_walls(city, wall_radius, rng)
	
	var center = _create_city_center(rng)
	city.add_child(center)
	
	var building_count = size * 4 + rng.randi_range(8, 15)
	var placed_buildings := []
	var building_data := []
	
	for i in range(building_count):
		var building_pos = _find_building_spot(placed_buildings, rng, 14.0, wall_radius * 0.75)
		if building_pos == Vector3.ZERO:
			continue
		
		var building_type = _choose_building_type(rng, "city")
		var building = _create_modular_building(building_type, rng)
		
		if building:
			var ground_y = _get_ground_height(position + building_pos)
			building.position = Vector3(building_pos.x, ground_y - position.y, building_pos.z)
			building.rotation.y = _face_towards_center(building_pos) + rng.randf_range(-0.3, 0.3)
			city.add_child(building)
			
			var template = building_templates.get(building_type, {})
			placed_buildings.append(building_pos)
			building_data.append({
				"position": building_pos,
				"type": building_type,
				"npc_capacity": template.get("npc_capacity", 2)
			})
	
	_add_market_area(city, rng)
	_add_city_decorations(city, rng, placed_buildings)
	
	var settlement_id = _register_settlement(position, "city", size, faction, building_data)
	emit_signal("settlement_spawned", settlement_id, position)
	
	return city

func _create_village_center(rng: RandomNumberGenerator) -> Node3D:
	var center = Node3D.new()
	center.name = "VillageCenter"
	
	var well = _create_well()
	center.add_child(well)
	
	for i in range(rng.randi_range(2, 4)):
		var bench = _load_prop_model("Bench")
		if bench:
			var angle = i * TAU / 4.0 + rng.randf_range(-0.3, 0.3)
			bench.position = Vector3(cos(angle) * 4.0, 0, sin(angle) * 4.0)
			bench.rotation.y = angle + PI
			center.add_child(bench)
	
	return center

func _create_city_center(rng: RandomNumberGenerator) -> Node3D:
	var center = Node3D.new()
	center.name = "CityCenter"
	
	var fountain = _create_fountain()
	center.add_child(fountain)
	
	for i in range(8):
		var angle = i * TAU / 8.0
		var torch = _load_prop_model("Torch_Metal")
		if torch:
			torch.position = Vector3(cos(angle) * 6.0, 0, sin(angle) * 6.0)
			torch.rotation.y = angle
			
			var light = OmniLight3D.new()
			light.light_color = Color(1.0, 0.7, 0.3)
			light.light_energy = 1.5
			light.omni_range = 8.0
			light.position.y = 2.0
			torch.add_child(light)
			
			center.add_child(torch)
	
	return center

func _create_well() -> Node3D:
	var well = Node3D.new()
	well.name = "Well"
	
	var base = CylinderMesh.new()
	base.height = 1.0
	base.top_radius = 1.0
	base.bottom_radius = 1.2
	
	var base_mesh = MeshInstance3D.new()
	base_mesh.mesh = base
	base_mesh.position.y = 0.5
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.45, 0.4, 0.35)
	mat.roughness = 0.85
	base_mesh.material_override = mat
	well.add_child(base_mesh)
	
	var water = CylinderMesh.new()
	water.height = 0.3
	water.top_radius = 0.85
	water.bottom_radius = 0.85
	
	var water_mesh = MeshInstance3D.new()
	water_mesh.mesh = water
	water_mesh.position.y = 0.65
	
	var water_mat = StandardMaterial3D.new()
	water_mat.albedo_color = Color(0.2, 0.4, 0.6, 0.9)
	water_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	water_mat.metallic = 0.3
	water_mat.roughness = 0.1
	water_mesh.material_override = water_mat
	well.add_child(water_mesh)
	
	var col = CollisionShape3D.new()
	var col_shape = CylinderShape3D.new()
	col_shape.height = 1.0
	col_shape.radius = 1.2
	col.shape = col_shape
	col.position.y = 0.5
	
	var body = StaticBody3D.new()
	body.add_child(col)
	well.add_child(body)
	
	return well

func _create_fountain() -> Node3D:
	var fountain = Node3D.new()
	fountain.name = "Fountain"
	
	var base = CylinderMesh.new()
	base.height = 0.6
	base.top_radius = 3.0
	base.bottom_radius = 3.5
	
	var base_mesh = MeshInstance3D.new()
	base_mesh.mesh = base
	base_mesh.position.y = 0.3
	
	var stone_mat = StandardMaterial3D.new()
	stone_mat.albedo_color = Color(0.6, 0.58, 0.55)
	stone_mat.roughness = 0.9
	base_mesh.material_override = stone_mat
	fountain.add_child(base_mesh)
	
	var water = CylinderMesh.new()
	water.height = 0.4
	water.top_radius = 2.7
	water.bottom_radius = 2.7
	
	var water_mesh = MeshInstance3D.new()
	water_mesh.mesh = water
	water_mesh.position.y = 0.5
	
	var water_mat = StandardMaterial3D.new()
	water_mat.albedo_color = Color(0.25, 0.45, 0.65, 0.85)
	water_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	water_mat.metallic = 0.4
	water_mat.roughness = 0.05
	water_mesh.material_override = water_mat
	fountain.add_child(water_mesh)
	
	var pillar = CylinderMesh.new()
	pillar.height = 2.5
	pillar.top_radius = 0.3
	pillar.bottom_radius = 0.4
	
	var pillar_mesh = MeshInstance3D.new()
	pillar_mesh.mesh = pillar
	pillar_mesh.position.y = 1.25
	pillar_mesh.material_override = stone_mat
	fountain.add_child(pillar_mesh)
	
	return fountain

func _create_modular_building(building_type: String, rng: RandomNumberGenerator) -> Node3D:
	var template = building_templates.get(building_type, building_templates["small_house"])
	var building = Node3D.new()
	building.name = building_type.capitalize().replace("_", "")
	
	var size = template.get("size", Vector3(4, 3, 4))
	
	var floor_model = _load_village_model(template.get("floor", "Floor_WoodDark"))
	if floor_model:
		floor_model.scale = Vector3(size.x / 4.0, 1.0, size.z / 4.0)
		building.add_child(floor_model)
	else:
		var floor_mesh = _create_floor_mesh(size.x, size.z)
		building.add_child(floor_mesh)
	
	_create_walls(building, template, size, rng)
	
	var roof_model = _load_village_model(template.get("roof", "Roof_RoundTiles_4x4"))
	if roof_model:
		roof_model.position.y = size.y
		roof_model.scale = Vector3(size.x / 4.0 * 1.1, 1.0, size.z / 4.0 * 1.1)
		building.add_child(roof_model)
	else:
		var roof_mesh = _create_roof_mesh(size.x, size.z, size.y)
		building.add_child(roof_mesh)
	
	if template.has("props"):
		_add_interior_props(building, template.props, size, rng)
	
	_add_building_collision(building, size)
	
	return building

func _create_walls(building: Node3D, template: Dictionary, size: Vector3, rng: RandomNumberGenerator):
	var walls_list = template.get("walls", ["Wall_Plaster_Straight"])
	var wall_height = size.y
	
	var directions = [
		{"pos": Vector3(0, 0, -size.z / 2), "rot": 0, "has_door": true},
		{"pos": Vector3(size.x / 2, 0, 0), "rot": PI / 2, "has_door": false},
		{"pos": Vector3(0, 0, size.z / 2), "rot": PI, "has_door": false},
		{"pos": Vector3(-size.x / 2, 0, 0), "rot": -PI / 2, "has_door": false}
	]
	
	for i in range(4):
		var dir = directions[i]
		var wall_type: String
		
		if dir.has_door:
			for w in walls_list:
				if "Door" in w:
					wall_type = w
					break
			if wall_type.is_empty():
				wall_type = walls_list[0]
		elif rng.randf() < 0.4:
			for w in walls_list:
				if "Window" in w:
					wall_type = w
					break
			if wall_type.is_empty():
				wall_type = walls_list[0]
		else:
			wall_type = walls_list[rng.randi() % walls_list.size()]
		
		var wall = _load_village_model(wall_type)
		if wall:
			wall.position = dir.pos
			wall.position.y = wall_height / 2.0
			wall.rotation.y = dir.rot
			
			var wall_scale_x = size.x / 4.0 if i % 2 == 0 else size.z / 4.0
			wall.scale = Vector3(wall_scale_x, wall_height / 3.0, 1.0)
			building.add_child(wall)
		else:
			var wall_mesh = _create_wall_mesh(size.x if i % 2 == 0 else size.z, wall_height, dir.has_door)
			wall_mesh.position = dir.pos
			wall_mesh.position.y = wall_height / 2.0
			wall_mesh.rotation.y = dir.rot
			building.add_child(wall_mesh)

func _create_floor_mesh(width: float, depth: float) -> MeshInstance3D:
	var mesh = MeshInstance3D.new()
	mesh.name = "Floor"
	
	var box = BoxMesh.new()
	box.size = Vector3(width, 0.2, depth)
	mesh.mesh = box
	mesh.position.y = 0.1
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.4, 0.32, 0.22)
	mat.roughness = 0.85
	mesh.material_override = mat
	
	return mesh

func _create_wall_mesh(width: float, height: float, has_door: bool) -> MeshInstance3D:
	var mesh = MeshInstance3D.new()
	mesh.name = "Wall"
	
	var box = BoxMesh.new()
	box.size = Vector3(width, height, 0.3)
	mesh.mesh = box
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.75, 0.7, 0.62)
	mat.roughness = 0.9
	mesh.material_override = mat
	
	return mesh

func _create_roof_mesh(width: float, depth: float, base_height: float) -> MeshInstance3D:
	var mesh = MeshInstance3D.new()
	mesh.name = "Roof"
	
	var prism = PrismMesh.new()
	prism.size = Vector3(width + 1.0, depth * 0.4, depth + 1.0)
	mesh.mesh = prism
	mesh.position.y = base_height + depth * 0.2
	mesh.rotation.x = PI
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.55, 0.38, 0.28)
	mat.roughness = 0.85
	mesh.material_override = mat
	
	return mesh

func _add_interior_props(building: Node3D, props: Array, size: Vector3, rng: RandomNumberGenerator):
	for prop_name in props:
		var prop = _load_prop_model(prop_name)
		if prop:
			var pos = Vector3(
				rng.randf_range(-size.x * 0.3, size.x * 0.3),
				0.1,
				rng.randf_range(-size.z * 0.3, size.z * 0.3)
			)
			prop.position = pos
			prop.rotation.y = rng.randf_range(0, TAU)
			prop.scale = Vector3(0.8, 0.8, 0.8)
			building.add_child(prop)

func _add_building_collision(building: Node3D, size: Vector3):
	var col = CollisionShape3D.new()
	var col_box = BoxShape3D.new()
	col_box.size = size
	col.shape = col_box
	col.position.y = size.y / 2.0
	
	var body = StaticBody3D.new()
	body.add_child(col)
	building.add_child(body)

func _create_city_walls(city: Node3D, radius: float, rng: RandomNumberGenerator):
	var wall_count = 24
	
	for i in range(wall_count):
		var angle = i * TAU / wall_count
		var pos = Vector3(cos(angle) * radius, 0, sin(angle) * radius)
		
		var wall = _create_wall_segment(rng)
		wall.position = pos
		wall.rotation.y = angle + PI / 2
		city.add_child(wall)
	
	var gate_angles = [0, PI / 2, PI, -PI / 2]
	for gate_angle in gate_angles:
		var gate = _create_gate(rng)
		gate.position = Vector3(cos(gate_angle) * radius, 0, sin(gate_angle) * radius)
		gate.rotation.y = gate_angle + PI / 2
		city.add_child(gate)

func _create_wall_segment(rng: RandomNumberGenerator) -> Node3D:
	var wall = Node3D.new()
	wall.name = "WallSegment"
	
	var mesh = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(10.0, 5.0, 1.5)
	mesh.mesh = box
	mesh.position.y = 2.5
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.5, 0.48, 0.45)
	mat.roughness = 0.9
	mesh.material_override = mat
	wall.add_child(mesh)
	
	var battlement = MeshInstance3D.new()
	var batt_box = BoxMesh.new()
	batt_box.size = Vector3(10.0, 1.0, 0.8)
	battlement.mesh = batt_box
	battlement.position.y = 5.5
	battlement.material_override = mat
	wall.add_child(battlement)
	
	var col = CollisionShape3D.new()
	var col_box = BoxShape3D.new()
	col_box.size = Vector3(10.0, 5.0, 1.5)
	col.shape = col_box
	col.position.y = 2.5
	
	var body = StaticBody3D.new()
	body.add_child(col)
	wall.add_child(body)
	
	return wall

func _create_gate(rng: RandomNumberGenerator) -> Node3D:
	var gate = Node3D.new()
	gate.name = "Gate"
	
	var left_pillar = MeshInstance3D.new()
	var pillar_box = BoxMesh.new()
	pillar_box.size = Vector3(2.0, 7.0, 2.0)
	left_pillar.mesh = pillar_box
	left_pillar.position = Vector3(-3.0, 3.5, 0)
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.52, 0.5, 0.47)
	mat.roughness = 0.9
	left_pillar.material_override = mat
	gate.add_child(left_pillar)
	
	var right_pillar = left_pillar.duplicate()
	right_pillar.position.x = 3.0
	gate.add_child(right_pillar)
	
	var arch = MeshInstance3D.new()
	var arch_box = BoxMesh.new()
	arch_box.size = Vector3(8.0, 1.5, 2.0)
	arch.mesh = arch_box
	arch.position.y = 6.25
	arch.material_override = mat
	gate.add_child(arch)
	
	return gate

func _add_market_area(city: Node3D, rng: RandomNumberGenerator):
	var market = Node3D.new()
	market.name = "MarketArea"
	market.position = Vector3(rng.randf_range(-15, 15), 0, rng.randf_range(-15, 15))
	
	for i in range(rng.randi_range(4, 8)):
		var stall = _load_prop_model("Stall_Empty")
		if stall:
			var angle = i * TAU / 8.0 + rng.randf_range(-0.2, 0.2)
			stall.position = Vector3(cos(angle) * 8.0, 0, sin(angle) * 8.0)
			stall.rotation.y = angle + PI
			market.add_child(stall)
			
			if rng.randf() > 0.5:
				var goods = _load_prop_model("Barrel_Apples" if rng.randf() > 0.5 else "FarmCrate_Carrot")
				if goods:
					goods.position = stall.position + Vector3(rng.randf_range(-1, 1), 0, rng.randf_range(-1, 1))
					market.add_child(goods)
	
	city.add_child(market)

func _add_village_decorations(village: Node3D, rng: RandomNumberGenerator, placed_buildings: Array):
	for i in range(rng.randi_range(5, 12)):
		var pos = _find_empty_spot(placed_buildings, rng, 25.0)
		if pos == Vector3.ZERO:
			continue
		
		var decoration_type = rng.randi() % 5
		var decoration: Node3D
		
		match decoration_type:
			0:
				decoration = _load_prop_model("Barrel")
			1:
				decoration = _load_prop_model("Crate_Wooden")
			2:
				decoration = _load_prop_model("Bucket_Wooden_1")
			3:
				decoration = _create_campfire()
			4:
				decoration = _load_prop_model("FarmCrate_Empty")
		
		if decoration:
			decoration.position = pos
			decoration.rotation.y = rng.randf_range(0, TAU)
			village.add_child(decoration)

func _add_city_decorations(city: Node3D, rng: RandomNumberGenerator, placed_buildings: Array):
	for i in range(rng.randi_range(8, 20)):
		var pos = _find_empty_spot(placed_buildings, rng, 40.0)
		if pos == Vector3.ZERO:
			continue
		
		var decoration_type = rng.randi() % 6
		var decoration: Node3D
		
		match decoration_type:
			0:
				decoration = _load_prop_model("Barrel")
			1:
				decoration = _load_prop_model("Crate_Wooden")
			2:
				decoration = _load_prop_model("Bench")
			3:
				decoration = _load_prop_model("Pot_1")
			4:
				decoration = _load_prop_model("Torch_Metal")
				if decoration:
					var light = OmniLight3D.new()
					light.light_color = Color(1.0, 0.7, 0.3)
					light.light_energy = 1.2
					light.omni_range = 6.0
					light.position.y = 1.8
					decoration.add_child(light)
			5:
				decoration = _load_prop_model("Wagon")
		
		if decoration:
			decoration.position = pos
			decoration.rotation.y = rng.randf_range(0, TAU)
			city.add_child(decoration)

func _add_paths_between_buildings(settlement: Node3D, rng: RandomNumberGenerator, buildings: Array):
	if buildings.size() < 2:
		return
	
	var path_container = Node3D.new()
	path_container.name = "Paths"
	
	for i in range(buildings.size() - 1):
		var from_pos = buildings[i]
		var to_pos = buildings[(i + 1) % buildings.size()]
		
		var direction = (to_pos - from_pos).normalized()
		var distance = from_pos.distance_to(to_pos)
		var step_count = int(distance / 2.0)
		
		for j in range(step_count):
			var t = float(j) / step_count
			var path_pos = from_pos.lerp(to_pos, t)
			path_pos.x += rng.randf_range(-0.3, 0.3)
			path_pos.z += rng.randf_range(-0.3, 0.3)
			
			var path_stone = MeshInstance3D.new()
			var stone_mesh = CylinderMesh.new()
			stone_mesh.height = 0.08
			stone_mesh.top_radius = rng.randf_range(0.3, 0.5)
			stone_mesh.bottom_radius = stone_mesh.top_radius + 0.05
			path_stone.mesh = stone_mesh
			path_stone.position = path_pos
			path_stone.position.y = 0.04
			
			var mat = StandardMaterial3D.new()
			mat.albedo_color = Color(0.55, 0.52, 0.48)
			mat.roughness = 0.95
			path_stone.material_override = mat
			
			path_container.add_child(path_stone)
	
	settlement.add_child(path_container)

func _create_campfire() -> Node3D:
	var campfire = Node3D.new()
	campfire.name = "Campfire"
	
	for i in range(6):
		var log = MeshInstance3D.new()
		var log_mesh = CylinderMesh.new()
		log_mesh.height = rng.randf_range(0.8, 1.2) if randf() > 0 else 1.0
		log_mesh.top_radius = 0.08
		log_mesh.bottom_radius = 0.1
		log.mesh = log_mesh
		log.rotation.z = PI / 2 + randf_range(-0.3, 0.3)
		log.rotation.y = i * TAU / 6.0
		log.position = Vector3(cos(i * TAU / 6.0) * 0.2, 0.1, sin(i * TAU / 6.0) * 0.2)
		
		var wood_mat = StandardMaterial3D.new()
		wood_mat.albedo_color = Color(0.35, 0.25, 0.15)
		log.material_override = wood_mat
		campfire.add_child(log)
	
	var fire_light = OmniLight3D.new()
	fire_light.light_color = Color(1.0, 0.6, 0.2)
	fire_light.light_energy = 2.5
	fire_light.omni_range = 10.0
	fire_light.position.y = 0.5
	campfire.add_child(fire_light)
	
	return campfire

func _load_village_model(model_name: String) -> Node3D:
	if not loaded_models.has(model_name):
		return null
	
	var path = loaded_models[model_name]
	
	var gltf_doc = GLTFDocument.new()
	var gltf_state = GLTFState.new()
	
	var err = gltf_doc.append_from_file(path, gltf_state)
	if err != OK:
		return null
	
	var scene = gltf_doc.generate_scene(gltf_state)
	return scene

func _load_prop_model(prop_name: String) -> Node3D:
	if not loaded_models.has(prop_name):
		return null
	
	return _load_village_model(prop_name)

func _find_building_spot(placed: Array, rng: RandomNumberGenerator, min_dist: float, max_dist: float) -> Vector3:
	for attempt in range(30):
		var angle = rng.randf_range(0, TAU)
		var dist = rng.randf_range(min_dist, max_dist)
		var pos = Vector3(cos(angle) * dist, 0, sin(angle) * dist)
		
		var valid = true
		for p in placed:
			if pos.distance_to(p) < min_dist * 0.9:
				valid = false
				break
		
		if valid:
			return pos
	
	return Vector3.ZERO

func _find_empty_spot(placed: Array, rng: RandomNumberGenerator, max_dist: float) -> Vector3:
	for attempt in range(15):
		var pos = Vector3(rng.randf_range(-max_dist, max_dist), 0, rng.randf_range(-max_dist, max_dist))
		
		var valid = true
		for p in placed:
			if pos.distance_to(p) < 5.0:
				valid = false
				break
		
		if valid:
			return pos
	
	return Vector3.ZERO

func _choose_building_type(rng: RandomNumberGenerator, settlement_type: String) -> String:
	var weights: Dictionary
	
	if settlement_type == "village":
		weights = {
			"small_house": 40,
			"medium_house": 25,
			"shop": 15,
			"blacksmith": 10,
			"tavern": 10
		}
	else:
		weights = {
			"small_house": 20,
			"medium_house": 30,
			"large_house": 15,
			"shop": 15,
			"blacksmith": 8,
			"tavern": 8,
			"guard_tower": 4
		}
	
	var total = 0
	for w in weights.values():
		total += w
	
	var roll = rng.randi() % total
	var current = 0
	
	for building_type in weights:
		current += weights[building_type]
		if roll < current:
			return building_type
	
	return "small_house"

func _face_towards_center(pos: Vector3) -> float:
	return atan2(-pos.x, -pos.z)

func _get_ground_height(pos: Vector3) -> float:
	if world_gen and world_gen.has_method("get_height_at"):
		return world_gen.get_height_at(pos.x, pos.z)
	return 0.0

func _register_settlement(pos: Vector3, settlement_type: String, size: int, faction: String, building_data: Array) -> int:
	if not settlement_system:
		return -1
	
	var name_gen = get_node_or_null("/root/NameGenerator")
	var settlement_name = "Settlement"
	if name_gen and name_gen.has_method("generate_settlement_name"):
		settlement_name = name_gen.generate_settlement_name()
	
	var pop = 0
	for b in building_data:
		pop += b.get("npc_capacity", 2)
	
	return settlement_system.create_settlement(settlement_name, pos, pop, faction)

var rng := RandomNumberGenerator.new()
