extends Node

var world_gen
var building_scenes := {}
var npc_scene: PackedScene
var mob_scene: PackedScene

var spawned_structures := {}

func _ready():
        world_gen = get_node_or_null("/root/WorldGenerator")
        _preload_scenes()

func _preload_scenes():
        var paths = {
                "house_small": "res://scenes/buildings/house_small.tscn",
                "house_medium": "res://scenes/buildings/house_medium.tscn",
                "house_large": "res://scenes/buildings/house_large.tscn",
                "shop": "res://scenes/buildings/shop.tscn",
                "tavern": "res://scenes/buildings/tavern.tscn",
                "blacksmith": "res://scenes/buildings/blacksmith.tscn",
                "tower": "res://scenes/buildings/tower.tscn",
                "wall": "res://scenes/buildings/wall_segment.tscn",
                "gate": "res://scenes/buildings/gate.tscn",
                "mine_entrance": "res://scenes/buildings/mine_entrance.tscn",
                "tent": "res://scenes/buildings/tent.tscn",
                "campfire": "res://scenes/props/campfire.tscn"
        }
        
        for key in paths:
                if ResourceLoader.exists(paths[key]):
                        building_scenes[key] = load(paths[key])
        
        if ResourceLoader.exists("res://scenes/npcs/npc_citizen.tscn"):
                npc_scene = load("res://scenes/npcs/npc_citizen.tscn")
        
        if ResourceLoader.exists("res://scenes/mobs/mob_basic.tscn"):
                mob_scene = load("res://scenes/mobs/mob_basic.tscn")

func generate_structure(structure_data: Dictionary, position: Vector3) -> Node3D:
        var key = "%d_%d" % [int(position.x), int(position.z)]
        if spawned_structures.has(key):
                return null
        
        var structure_type = structure_data.get("type", "camp")
        var result: Node3D
        
        match structure_type:
                "village":
                        result = _generate_village(structure_data, position)
                "city":
                        result = _generate_city(structure_data, position)
                "mine":
                        result = _generate_mine(structure_data, position)
                "camp":
                        result = _generate_camp(structure_data, position)
                _:
                        result = _generate_camp(structure_data, position)
        
        if result:
                spawned_structures[key] = result
        
        return result

func _generate_village(data: Dictionary, pos: Vector3) -> Node3D:
        var village = Node3D.new()
        village.name = "Village"
        village.position = pos
        
        var size = data.get("size", 5)
        var rng = RandomNumberGenerator.new()
        rng.seed = hash(pos)
        
        var building_count = size * 2 + rng.randi_range(2, 5)
        var placed_positions := []
        
        var center = _create_village_center(rng)
        village.add_child(center)
        placed_positions.append(Vector3.ZERO)
        
        for i in range(building_count):
                var building_pos = _find_building_position(placed_positions, rng, 8.0, 25.0)
                if building_pos == Vector3.ZERO:
                        continue
                
                var building_type = _random_village_building(rng)
                var building = _create_building(building_type, rng)
                if building:
                        var ground_height = 0.0
                        if world_gen:
                                ground_height = world_gen.get_height_at(pos.x + building_pos.x, pos.z + building_pos.z)
                        building.position = Vector3(building_pos.x, ground_height - pos.y, building_pos.z)
                        building.rotation.y = rng.randf_range(0, TAU)
                        village.add_child(building)
                        placed_positions.append(building_pos)
        
        var npc_count = size + rng.randi_range(2, 5)
        for i in range(npc_count):
                var npc = _spawn_npc("town", rng)
                if npc:
                        var npc_pos = _random_point_in_area(rng, 20.0)
                        var ground_height = 0.0
                        if world_gen:
                                ground_height = world_gen.get_height_at(pos.x + npc_pos.x, pos.z + npc_pos.z)
                        npc.position = Vector3(npc_pos.x, ground_height - pos.y + 1.0, npc_pos.z)
                        village.add_child(npc)
        
        return village

func _generate_city(data: Dictionary, pos: Vector3) -> Node3D:
        var city = Node3D.new()
        city.name = "City"
        city.position = pos
        
        var size = data.get("size", 10)
        var rng = RandomNumberGenerator.new()
        rng.seed = hash(pos)
        
        var wall_radius = size * 5.0
        var walls = _create_city_walls(wall_radius, rng)
        for wall in walls:
                city.add_child(wall)
        
        var center = _create_city_center(rng)
        city.add_child(center)
        
        var building_count = size * 4 + rng.randi_range(5, 15)
        var placed_positions := [Vector3.ZERO]
        
        for i in range(building_count):
                var building_pos = _find_building_position(placed_positions, rng, 10.0, wall_radius * 0.8)
                if building_pos == Vector3.ZERO:
                        continue
                
                var building_type = _random_city_building(rng)
                var building = _create_building(building_type, rng)
                if building:
                        var ground_height = 0.0
                        if world_gen:
                                ground_height = world_gen.get_height_at(pos.x + building_pos.x, pos.z + building_pos.z)
                        building.position = Vector3(building_pos.x, ground_height - pos.y, building_pos.z)
                        building.rotation.y = rng.randf_range(0, TAU)
                        city.add_child(building)
                        placed_positions.append(building_pos)
        
        var npc_count = size * 2 + rng.randi_range(5, 15)
        for i in range(npc_count):
                var npc = _spawn_npc("town", rng)
                if npc:
                        var npc_pos = _random_point_in_area(rng, wall_radius * 0.7)
                        var ground_height = 0.0
                        if world_gen:
                                ground_height = world_gen.get_height_at(pos.x + npc_pos.x, pos.z + npc_pos.z)
                        npc.position = Vector3(npc_pos.x, ground_height - pos.y + 1.0, npc_pos.z)
                        city.add_child(npc)
        
        var guard_count = size + rng.randi_range(2, 5)
        for i in range(guard_count):
                var guard = _spawn_npc("town", rng)
                if guard:
                        if guard.has_method("set_role"):
                                guard.set_role("guard")
                        var angle = rng.randf_range(0, TAU)
                        var guard_pos = Vector3(cos(angle), 0, sin(angle)) * wall_radius * 0.9
                        var ground_height = 0.0
                        if world_gen:
                                ground_height = world_gen.get_height_at(pos.x + guard_pos.x, pos.z + guard_pos.z)
                        guard.position = Vector3(guard_pos.x, ground_height - pos.y + 1.0, guard_pos.z)
                        city.add_child(guard)
        
        return city

func _generate_mine(data: Dictionary, pos: Vector3) -> Node3D:
        var mine = Node3D.new()
        mine.name = "Mine"
        mine.position = pos
        
        var depth = data.get("depth", 5)
        var rng = RandomNumberGenerator.new()
        rng.seed = hash(pos)
        
        var entrance = _create_mine_entrance(rng)
        mine.add_child(entrance)
        
        var support_count = rng.randi_range(2, 4)
        for i in range(support_count):
                var support = _create_mine_support(rng)
                var angle = rng.randf_range(0, TAU)
                var dist = rng.randf_range(3.0, 8.0)
                support.position = Vector3(cos(angle) * dist, 0, sin(angle) * dist)
                mine.add_child(support)
        
        var miner_count = rng.randi_range(1, 3)
        for i in range(miner_count):
                var miner = _spawn_npc("neutral", rng)
                if miner:
                        var miner_pos = _random_point_in_area(rng, 5.0)
                        miner.position = Vector3(miner_pos.x, 1.0, miner_pos.z)
                        mine.add_child(miner)
        
        return mine

func _generate_camp(data: Dictionary, pos: Vector3) -> Node3D:
        var camp = Node3D.new()
        camp.name = "Camp"
        camp.position = pos
        
        var faction = data.get("faction", "neutral")
        var rng = RandomNumberGenerator.new()
        rng.seed = hash(pos)
        
        var campfire = _create_campfire()
        camp.add_child(campfire)
        
        var tent_count = rng.randi_range(2, 5)
        for i in range(tent_count):
                var tent = _create_tent(rng)
                var angle = rng.randf_range(0, TAU)
                var dist = rng.randf_range(4.0, 8.0)
                tent.position = Vector3(cos(angle) * dist, 0, sin(angle) * dist)
                tent.rotation.y = atan2(-cos(angle), -sin(angle))
                camp.add_child(tent)
        
        var npc_count = rng.randi_range(2, 4)
        for i in range(npc_count):
                var npc: Node3D
                if faction == "bandits" or faction == "wild":
                        npc = _spawn_mob(faction, rng)
                else:
                        npc = _spawn_npc(faction, rng)
                
                if npc:
                        var npc_pos = _random_point_in_area(rng, 6.0)
                        npc.position = Vector3(npc_pos.x, 1.0, npc_pos.z)
                        camp.add_child(npc)
        
        return camp

func _create_village_center(rng: RandomNumberGenerator) -> Node3D:
        var center = Node3D.new()
        center.name = "VillageCenter"
        
        var well = MeshInstance3D.new()
        well.name = "Well"
        var cylinder = CylinderMesh.new()
        cylinder.height = 1.0
        cylinder.top_radius = 0.8
        cylinder.bottom_radius = 1.0
        well.mesh = cylinder
        well.position.y = 0.5
        
        var mat = StandardMaterial3D.new()
        mat.albedo_color = Color(0.4, 0.35, 0.3)
        well.material_override = mat
        
        center.add_child(well)
        
        return center

func _create_city_center(rng: RandomNumberGenerator) -> Node3D:
        var center = Node3D.new()
        center.name = "CityCenter"
        
        var fountain = MeshInstance3D.new()
        var cylinder = CylinderMesh.new()
        cylinder.height = 0.8
        cylinder.top_radius = 2.5
        cylinder.bottom_radius = 3.0
        fountain.mesh = cylinder
        fountain.position.y = 0.4
        
        var mat = StandardMaterial3D.new()
        mat.albedo_color = Color(0.6, 0.55, 0.5)
        fountain.material_override = mat
        
        center.add_child(fountain)
        
        var water = MeshInstance3D.new()
        var water_cyl = CylinderMesh.new()
        water_cyl.height = 0.3
        water_cyl.top_radius = 2.3
        water_cyl.bottom_radius = 2.3
        water.mesh = water_cyl
        water.position.y = 0.7
        
        var water_mat = StandardMaterial3D.new()
        water_mat.albedo_color = Color(0.3, 0.5, 0.7, 0.8)
        water_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
        water.material_override = water_mat
        
        center.add_child(water)
        
        return center

func _create_city_walls(radius: float, rng: RandomNumberGenerator) -> Array:
        var walls = []
        var segment_count = 16
        
        for i in range(segment_count):
                var angle = i * TAU / segment_count
                var next_angle = (i + 1) * TAU / segment_count
                
                var pos = Vector3(cos(angle) * radius, 0, sin(angle) * radius)
                var wall = _create_wall_segment(rng)
                wall.position = pos
                wall.rotation.y = angle + PI * 0.5
                walls.append(wall)
        
        return walls

func _create_wall_segment(rng: RandomNumberGenerator) -> Node3D:
        if building_scenes.has("wall"):
                return building_scenes["wall"].instantiate()
        
        var wall = Node3D.new()
        wall.name = "WallSegment"
        
        var mesh = MeshInstance3D.new()
        var box = BoxMesh.new()
        box.size = Vector3(8.0, 4.0, 1.0)
        mesh.mesh = box
        mesh.position.y = 2.0
        
        var mat = StandardMaterial3D.new()
        mat.albedo_color = Color(0.5, 0.45, 0.4)
        mesh.material_override = mat
        
        wall.add_child(mesh)
        
        var col = CollisionShape3D.new()
        var col_box = BoxShape3D.new()
        col_box.size = box.size
        col.shape = col_box
        col.position.y = 2.0
        
        var body = StaticBody3D.new()
        body.add_child(col)
        wall.add_child(body)
        
        return wall

func _create_mine_entrance(rng: RandomNumberGenerator) -> Node3D:
        if building_scenes.has("mine_entrance"):
                return building_scenes["mine_entrance"].instantiate()
        
        var entrance = Node3D.new()
        entrance.name = "MineEntrance"
        
        var frame_left = MeshInstance3D.new()
        var box = BoxMesh.new()
        box.size = Vector3(0.5, 3.0, 0.5)
        frame_left.mesh = box
        frame_left.position = Vector3(-1.5, 1.5, 0)
        
        var wood_mat = StandardMaterial3D.new()
        wood_mat.albedo_color = Color(0.4, 0.3, 0.2)
        frame_left.material_override = wood_mat
        
        entrance.add_child(frame_left)
        
        var frame_right = frame_left.duplicate()
        frame_right.position.x = 1.5
        entrance.add_child(frame_right)
        
        var frame_top = MeshInstance3D.new()
        var top_box = BoxMesh.new()
        top_box.size = Vector3(4.0, 0.5, 0.5)
        frame_top.mesh = top_box
        frame_top.position = Vector3(0, 3.25, 0)
        frame_top.material_override = wood_mat
        entrance.add_child(frame_top)
        
        var hole = MeshInstance3D.new()
        var hole_box = BoxMesh.new()
        hole_box.size = Vector3(2.5, 2.5, 3.0)
        hole.mesh = hole_box
        hole.position = Vector3(0, 1.25, 1.0)
        
        var dark_mat = StandardMaterial3D.new()
        dark_mat.albedo_color = Color(0.1, 0.08, 0.05)
        hole.material_override = dark_mat
        entrance.add_child(hole)
        
        return entrance

func _create_mine_support(rng: RandomNumberGenerator) -> Node3D:
        var support = Node3D.new()
        support.name = "MineSupport"
        
        var post = MeshInstance3D.new()
        var cylinder = CylinderMesh.new()
        cylinder.height = 2.5
        cylinder.top_radius = 0.15
        cylinder.bottom_radius = 0.2
        post.mesh = cylinder
        post.position.y = 1.25
        
        var mat = StandardMaterial3D.new()
        mat.albedo_color = Color(0.35, 0.25, 0.15)
        post.material_override = mat
        
        support.add_child(post)
        
        return support

func _create_campfire() -> Node3D:
        if building_scenes.has("campfire"):
                return building_scenes["campfire"].instantiate()
        
        var campfire = Node3D.new()
        campfire.name = "Campfire"
        
        var logs = MeshInstance3D.new()
        var box = BoxMesh.new()
        box.size = Vector3(1.0, 0.3, 1.0)
        logs.mesh = box
        logs.position.y = 0.15
        
        var wood_mat = StandardMaterial3D.new()
        wood_mat.albedo_color = Color(0.3, 0.2, 0.1)
        logs.material_override = wood_mat
        
        campfire.add_child(logs)
        
        var fire_light = OmniLight3D.new()
        fire_light.light_color = Color(1.0, 0.6, 0.2)
        fire_light.light_energy = 2.0
        fire_light.omni_range = 8.0
        fire_light.position.y = 0.5
        campfire.add_child(fire_light)
        
        return campfire

func _create_tent(rng: RandomNumberGenerator) -> Node3D:
        if building_scenes.has("tent"):
                return building_scenes["tent"].instantiate()
        
        var tent = Node3D.new()
        tent.name = "Tent"
        
        var mesh = MeshInstance3D.new()
        var prism = PrismMesh.new()
        prism.size = Vector3(3.0, 2.0, 3.0)
        mesh.mesh = prism
        mesh.position.y = 1.0
        mesh.rotation.x = PI
        
        var colors = [
                Color(0.6, 0.5, 0.4),
                Color(0.5, 0.4, 0.35),
                Color(0.55, 0.45, 0.3),
                Color(0.7, 0.6, 0.5)
        ]
        
        var mat = StandardMaterial3D.new()
        mat.albedo_color = colors[rng.randi() % colors.size()]
        mesh.material_override = mat
        
        tent.add_child(mesh)
        
        return tent

func _create_building(building_type: String, rng: RandomNumberGenerator) -> Node3D:
        if building_scenes.has(building_type):
                return building_scenes[building_type].instantiate()
        
        var building = Node3D.new()
        building.name = building_type.capitalize()
        
        var width = rng.randf_range(4.0, 8.0)
        var depth = rng.randf_range(4.0, 8.0)
        var height = rng.randf_range(3.0, 6.0)
        
        match building_type:
                "house_small":
                        width = rng.randf_range(3.0, 5.0)
                        depth = rng.randf_range(3.0, 5.0)
                        height = rng.randf_range(2.5, 3.5)
                "house_medium":
                        width = rng.randf_range(5.0, 7.0)
                        depth = rng.randf_range(5.0, 7.0)
                        height = rng.randf_range(3.0, 4.5)
                "house_large":
                        width = rng.randf_range(7.0, 10.0)
                        depth = rng.randf_range(6.0, 9.0)
                        height = rng.randf_range(4.0, 6.0)
                "shop":
                        width = rng.randf_range(5.0, 8.0)
                        depth = rng.randf_range(4.0, 6.0)
                        height = rng.randf_range(3.0, 4.0)
                "tavern":
                        width = rng.randf_range(8.0, 12.0)
                        depth = rng.randf_range(6.0, 10.0)
                        height = rng.randf_range(4.0, 6.0)
                "blacksmith":
                        width = rng.randf_range(6.0, 9.0)
                        depth = rng.randf_range(5.0, 8.0)
                        height = rng.randf_range(3.5, 5.0)
                "tower":
                        width = rng.randf_range(4.0, 6.0)
                        depth = width
                        height = rng.randf_range(8.0, 15.0)
        
        var walls = MeshInstance3D.new()
        var box = BoxMesh.new()
        box.size = Vector3(width, height, depth)
        walls.mesh = box
        walls.position.y = height * 0.5
        
        var wall_colors = [
                Color(0.7, 0.65, 0.55),
                Color(0.6, 0.55, 0.5),
                Color(0.75, 0.7, 0.6),
                Color(0.65, 0.6, 0.55)
        ]
        
        var wall_mat = StandardMaterial3D.new()
        wall_mat.albedo_color = wall_colors[rng.randi() % wall_colors.size()]
        walls.material_override = wall_mat
        
        building.add_child(walls)
        
        if building_type != "tower":
                var roof = MeshInstance3D.new()
                var roof_mesh = PrismMesh.new()
                roof_mesh.size = Vector3(width + 0.5, height * 0.4, depth + 0.5)
                roof.mesh = roof_mesh
                roof.position.y = height + height * 0.2
                roof.rotation.x = PI
                
                var roof_mat = StandardMaterial3D.new()
                roof_mat.albedo_color = Color(0.5, 0.35, 0.25)
                roof.material_override = roof_mat
                
                building.add_child(roof)
        
        var col = CollisionShape3D.new()
        var col_box = BoxShape3D.new()
        col_box.size = Vector3(width, height, depth)
        col.shape = col_box
        col.position.y = height * 0.5
        
        var body = StaticBody3D.new()
        body.add_child(col)
        building.add_child(body)
        
        return building

func _find_building_position(placed: Array, rng: RandomNumberGenerator, min_dist: float, max_dist: float) -> Vector3:
        for attempt in range(20):
                var angle = rng.randf_range(0, TAU)
                var dist = rng.randf_range(min_dist, max_dist)
                var pos = Vector3(cos(angle) * dist, 0, sin(angle) * dist)
                
                var valid = true
                for p in placed:
                        if pos.distance_to(p) < min_dist * 0.8:
                                valid = false
                                break
                
                if valid:
                        return pos
        
        return Vector3.ZERO

func _random_village_building(rng: RandomNumberGenerator) -> String:
        var buildings = ["house_small", "house_small", "house_small", "house_medium", "house_medium", "shop", "blacksmith"]
        return buildings[rng.randi() % buildings.size()]

func _random_city_building(rng: RandomNumberGenerator) -> String:
        var buildings = ["house_small", "house_medium", "house_medium", "house_large", "shop", "shop", "tavern", "blacksmith", "tower"]
        return buildings[rng.randi() % buildings.size()]

func _random_point_in_area(rng: RandomNumberGenerator, radius: float) -> Vector3:
        var angle = rng.randf_range(0, TAU)
        var dist = rng.randf_range(0, radius)
        return Vector3(cos(angle) * dist, 0, sin(angle) * dist)

func _spawn_npc(faction: String, rng: RandomNumberGenerator) -> Node3D:
        if npc_scene:
                var npc = npc_scene.instantiate()
                if npc.has_method("set_faction"):
                        npc.set_faction(faction)
                return npc
        
        var npc = Node3D.new()
        npc.name = "NPC"
        
        var body_mesh = MeshInstance3D.new()
        var capsule = CapsuleMesh.new()
        capsule.radius = 0.3
        capsule.height = 1.6
        body_mesh.mesh = capsule
        body_mesh.position.y = 0.8
        
        var mat = StandardMaterial3D.new()
        match faction:
                "town":
                        mat.albedo_color = Color(0.3, 0.5, 0.7)
                "bandits":
                        mat.albedo_color = Color(0.6, 0.3, 0.3)
                "neutral":
                        mat.albedo_color = Color(0.5, 0.5, 0.4)
                _:
                        mat.albedo_color = Color(0.5, 0.5, 0.5)
        
        body_mesh.material_override = mat
        npc.add_child(body_mesh)
        
        return npc

func _spawn_mob(faction: String, rng: RandomNumberGenerator) -> Node3D:
        if mob_scene:
                var mob = mob_scene.instantiate()
                return mob
        
        var mob = Node3D.new()
        mob.name = "Mob"
        
        var body_mesh = MeshInstance3D.new()
        var box = BoxMesh.new()
        box.size = Vector3(0.8, 1.0, 1.2)
        body_mesh.mesh = box
        body_mesh.position.y = 0.5
        
        var mat = StandardMaterial3D.new()
        mat.albedo_color = Color(0.5, 0.35, 0.3)
        body_mesh.material_override = mat
        
        mob.add_child(body_mesh)
        
        return mob
