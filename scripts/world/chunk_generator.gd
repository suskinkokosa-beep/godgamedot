extends Node

const CHUNK_SIZE := 32
const MESH_RESOLUTION := 16
const VERTEX_SPACING := CHUNK_SIZE / float(MESH_RESOLUTION)

const _TerrainMaterialGenerator = preload("res://scripts/world/terrain_material_generator.gd")
const _TreeGenerator = preload("res://scripts/world/tree_generator.gd")
const _RockGenerator = preload("res://scripts/world/rock_generator.gd")

var world_gen
var tree_scenes := {}
var rock_scenes := {}
var grass_material: Material
var water_material: Material

func _ready():
        world_gen = get_node_or_null("/root/WorldGenerator")
        _load_materials()
        _preload_scenes()

func _load_materials():
        var grass_mat_path = "res://assets/materials/grass_material.tres"
        var water_mat_path = "res://assets/materials/water_material.tres"
        
        if ResourceLoader.exists(grass_mat_path):
                grass_material = load(grass_mat_path)
        else:
                grass_material = StandardMaterial3D.new()
                grass_material.albedo_color = Color(0.3, 0.5, 0.25)
        
        if ResourceLoader.exists(water_mat_path):
                water_material = load(water_mat_path)
        else:
                water_material = StandardMaterial3D.new()
                water_material.albedo_color = Color(0.2, 0.4, 0.7, 0.8)
                water_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

func _preload_scenes():
        var tree_paths = {
                "oak": "res://scenes/props/trees/tree_oak.tscn",
                "birch": "res://scenes/props/trees/tree_birch.tscn",
                "pine": "res://scenes/props/trees/tree_pine.tscn",
                "spruce": "res://scenes/props/trees/tree_spruce.tscn",
                "willow": "res://scenes/props/trees/tree_willow.tscn",
                "acacia": "res://scenes/props/trees/tree_acacia.tscn",
                "maple": "res://scenes/props/trees/tree_maple.tscn"
        }
        
        for key in tree_paths:
                if ResourceLoader.exists(tree_paths[key]):
                        tree_scenes[key] = load(tree_paths[key])
        
        var rock_paths = [
                "res://scenes/props/rock_var_0.tscn",
                "res://scenes/props/rock_var_1.tscn",
                "res://scenes/props/rock_var_2.tscn"
        ]
        
        for i in range(rock_paths.size()):
                if ResourceLoader.exists(rock_paths[i]):
                        rock_scenes[i] = load(rock_paths[i])

func generate_chunk(chunk_x: int, chunk_z: int) -> Node3D:
        if not world_gen:
                world_gen = get_node_or_null("/root/WorldGenerator")
                if not world_gen:
                        return null
        
        var chunk = Node3D.new()
        chunk.name = "Chunk_%d_%d" % [chunk_x, chunk_z]
        
        var world_x = chunk_x * CHUNK_SIZE
        var world_z = chunk_z * CHUNK_SIZE
        
        var terrain = _create_terrain_mesh(world_x, world_z)
        chunk.add_child(terrain)
        
        var water = _create_water_plane(world_x, world_z)
        if water:
                chunk.add_child(water)
        
        var vegetation = _spawn_vegetation(world_x, world_z)
        for v in vegetation:
                chunk.add_child(v)
        
        var rocks = _spawn_rocks(world_x, world_z)
        for r in rocks:
                chunk.add_child(r)
        
        var ores = _spawn_ore_nodes(world_x, world_z)
        for o in ores:
                chunk.add_child(o)
        
        return chunk

func _create_terrain_mesh(world_x: float, world_z: float) -> StaticBody3D:
        var terrain = StaticBody3D.new()
        terrain.name = "Terrain"
        terrain.collision_layer = 1
        terrain.collision_mask = 1
        
        var st = SurfaceTool.new()
        st.begin(Mesh.PRIMITIVE_TRIANGLES)
        
        var heights := []
        var biomes := []
        
        for z in range(MESH_RESOLUTION + 1):
                var row_h := []
                var row_b := []
                for x in range(MESH_RESOLUTION + 1):
                        var wx = world_x + x * VERTEX_SPACING
                        var wz = world_z + z * VERTEX_SPACING
                        var h = world_gen.get_height_at(wx, wz)
                        var b = world_gen.get_biome_at(wx, wz)
                        row_h.append(h)
                        row_b.append(b)
                heights.append(row_h)
                biomes.append(row_b)
        
        for z in range(MESH_RESOLUTION):
                for x in range(MESH_RESOLUTION):
                        var x0 = world_x + x * VERTEX_SPACING
                        var z0 = world_z + z * VERTEX_SPACING
                        var x1 = x0 + VERTEX_SPACING
                        var z1 = z0 + VERTEX_SPACING
                        
                        var h00 = heights[z][x]
                        var h10 = heights[z][x + 1]
                        var h01 = heights[z + 1][x]
                        var h11 = heights[z + 1][x + 1]
                        
                        var b00 = biomes[z][x]
                        var c00 = world_gen.get_biome_color(b00)
                        var c10 = world_gen.get_biome_color(biomes[z][x + 1])
                        var c01 = world_gen.get_biome_color(biomes[z + 1][x])
                        var c11 = world_gen.get_biome_color(biomes[z + 1][x + 1])
                        
                        var v00 = Vector3(x0, h00, z0)
                        var v10 = Vector3(x1, h10, z0)
                        var v01 = Vector3(x0, h01, z1)
                        var v11 = Vector3(x1, h11, z1)
                        
                        var n1 = (v10 - v00).cross(v01 - v00).normalized()
                        var n2 = (v01 - v11).cross(v10 - v11).normalized()
                        
                        st.set_color(c00)
                        st.set_normal(n1)
                        st.set_uv(Vector2(0, 0))
                        st.add_vertex(v00)
                        
                        st.set_color(c10)
                        st.set_normal(n1)
                        st.set_uv(Vector2(1, 0))
                        st.add_vertex(v10)
                        
                        st.set_color(c01)
                        st.set_normal(n1)
                        st.set_uv(Vector2(0, 1))
                        st.add_vertex(v01)
                        
                        st.set_color(c10)
                        st.set_normal(n2)
                        st.set_uv(Vector2(1, 0))
                        st.add_vertex(v10)
                        
                        st.set_color(c11)
                        st.set_normal(n2)
                        st.set_uv(Vector2(1, 1))
                        st.add_vertex(v11)
                        
                        st.set_color(c01)
                        st.set_normal(n2)
                        st.set_uv(Vector2(0, 1))
                        st.add_vertex(v01)
        
        var mesh = st.commit()
        var mesh_instance = MeshInstance3D.new()
        mesh_instance.mesh = mesh
        
        var terrain_mat = _TerrainMaterialGenerator.get_terrain_material()
        if terrain_mat:
                mesh_instance.material_override = terrain_mat
        else:
                var material = StandardMaterial3D.new()
                material.vertex_color_use_as_albedo = true
                material.roughness = 0.85
                material.metallic = 0.0
                material.diffuse_mode = BaseMaterial3D.DIFFUSE_BURLEY
                material.specular_mode = BaseMaterial3D.SPECULAR_SCHLICK_GGX
                material.ao_enabled = true
                material.ao_light_affect = 0.3
                mesh_instance.material_override = material
        
        terrain.add_child(mesh_instance)
        
        var mesh_shape = _create_mesh_collision(mesh)
        var collision = CollisionShape3D.new()
        collision.shape = mesh_shape
        terrain.add_child(collision)
        
        return terrain

func _create_collision_shape(heights: Array, world_x: float, world_z: float) -> Shape3D:
        var size = MESH_RESOLUTION + 1
        
        var shape = HeightMapShape3D.new()
        shape.map_width = size
        shape.map_depth = size
        
        var map_data = PackedFloat32Array()
        map_data.resize(size * size)
        
        for z in range(size):
                for x in range(size):
                        map_data[z * size + x] = heights[z][x]
        
        shape.map_data = map_data
        
        return shape

func _create_mesh_collision(mesh: Mesh) -> ConcavePolygonShape3D:
        var shape = ConcavePolygonShape3D.new()
        var faces = mesh.get_faces()
        shape.set_faces(faces)
        return shape

func _create_water_plane(world_x: float, world_z: float) -> Node3D:
        var has_water = false
        for z in range(0, CHUNK_SIZE, 4):
                for x in range(0, CHUNK_SIZE, 4):
                        var h = world_gen.get_height_at(world_x + x, world_z + z)
                        if h < world_gen.SEA_LEVEL:
                                has_water = true
                                break
                if has_water:
                        break
        
        if not has_water:
                return null
        
        var water = MeshInstance3D.new()
        water.name = "Water"
        
        var plane = PlaneMesh.new()
        plane.size = Vector2(CHUNK_SIZE, CHUNK_SIZE)
        plane.subdivide_width = 8
        plane.subdivide_depth = 8
        water.mesh = plane
        
        water.position = Vector3(world_x + CHUNK_SIZE * 0.5, world_gen.SEA_LEVEL, world_z + CHUNK_SIZE * 0.5)
        
        if water_material:
                water.material_override = water_material
        else:
                var mat = StandardMaterial3D.new()
                mat.albedo_color = Color(0.2, 0.4, 0.7, 0.7)
                mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
                mat.metallic = 0.3
                mat.roughness = 0.1
                water.material_override = mat
        
        return water

func _spawn_vegetation(world_x: float, world_z: float) -> Array:
        var result = []
        var rng = RandomNumberGenerator.new()
        rng.seed = hash(Vector2(world_x, world_z))
        
        var spacing = 4.0
        
        for z in range(0, CHUNK_SIZE, int(spacing)):
                for x in range(0, CHUNK_SIZE, int(spacing)):
                        var offset_x = rng.randf_range(-spacing * 0.4, spacing * 0.4)
                        var offset_z = rng.randf_range(-spacing * 0.4, spacing * 0.4)
                        var wx = world_x + x + offset_x
                        var wz = world_z + z + offset_z
                        
                        if not world_gen.should_spawn_tree(wx, wz):
                                continue
                        
                        var biome = world_gen.get_biome_at(wx, wz)
                        var density = world_gen.get_vegetation_density(biome)
                        
                        if rng.randf() > density:
                                continue
                        
                        var tree_type = world_gen.get_tree_type(biome)
                        var tree = _create_harvestable_tree(tree_type, rng)
                        
                        if tree:
                                var height = world_gen.get_height_at(wx, wz)
                                tree.position = Vector3(wx, height, wz)
                                tree.rotation.y = rng.randf_range(0, TAU)
                                var scale_factor = rng.randf_range(0.7, 1.3)
                                tree.scale = Vector3(scale_factor, scale_factor, scale_factor)
                                result.append(tree)
        
        return result

func _create_harvestable_tree(tree_type: String, rng: RandomNumberGenerator) -> StaticBody3D:
        var tree = StaticBody3D.new()
        tree.name = "Tree_" + tree_type
        tree.collision_layer = 2
        tree.collision_mask = 1
        tree.add_to_group("resources")
        tree.add_to_group("trees")
        
        var resource_script = load("res://scripts/world/resource_node.gd")
        if resource_script:
                tree.set_script(resource_script)
                tree.set("resource_type", "wood")
                tree.set("resource_amount", rng.randf_range(50.0, 150.0))
                tree.set("gather_amount", 10.0)
                tree.set("required_tool", "axe")
                tree.set("respawn_time", 600.0)
                tree.set("quality", 1)
        
        var lod_level = 0
        var tree_model = _TreeGenerator.create_tree(tree_type, lod_level)
        if tree_model:
                tree.add_child(tree_model)
        
        var trunk_height = 4.0
        match tree_type:
                "pine", "spruce":
                        trunk_height = 8.0
                "birch":
                        trunk_height = 6.0
                "oak", "maple":
                        trunk_height = 5.0
                "willow":
                        trunk_height = 4.5
                "palm":
                        trunk_height = 7.0
                "acacia":
                        trunk_height = 3.5
        
        var trunk_radius = 0.35
        
        var col_shape = CollisionShape3D.new()
        var capsule = CapsuleShape3D.new()
        capsule.radius = trunk_radius * 2.0
        capsule.height = trunk_height + 1.0
        col_shape.shape = capsule
        col_shape.position.y = (trunk_height + 1.0) * 0.5
        tree.add_child(col_shape)
        
        return tree

func _create_tree(tree_type: String, rng: RandomNumberGenerator) -> Node3D:
        return _create_harvestable_tree(tree_type, rng)

func _spawn_rocks(world_x: float, world_z: float) -> Array:
        var result = []
        var rng = RandomNumberGenerator.new()
        rng.seed = hash(Vector2(world_x + 500, world_z + 500))
        
        var spacing = 8.0
        
        for z in range(0, CHUNK_SIZE, int(spacing)):
                for x in range(0, CHUNK_SIZE, int(spacing)):
                        var offset_x = rng.randf_range(-spacing * 0.3, spacing * 0.3)
                        var offset_z = rng.randf_range(-spacing * 0.3, spacing * 0.3)
                        var wx = world_x + x + offset_x
                        var wz = world_z + z + offset_z
                        
                        if not world_gen.should_spawn_rock(wx, wz):
                                continue
                        
                        var rock = _create_harvestable_rock(rng)
                        var height = world_gen.get_height_at(wx, wz)
                        rock.position = Vector3(wx, height, wz)
                        rock.rotation.y = rng.randf_range(0, TAU)
                        result.append(rock)
        
        return result

func _create_harvestable_rock(rng: RandomNumberGenerator) -> StaticBody3D:
        var rock = StaticBody3D.new()
        rock.name = "Rock"
        rock.collision_layer = 2
        rock.collision_mask = 1
        rock.add_to_group("resources")
        rock.add_to_group("rocks")
        
        var resource_script = load("res://scripts/world/resource_node.gd")
        if resource_script:
                rock.set_script(resource_script)
                rock.set("resource_type", "stone")
                rock.set("resource_amount", rng.randf_range(30.0, 80.0))
                rock.set("gather_amount", 5.0)
                rock.set("required_tool", "pickaxe")
                rock.set("respawn_time", 900.0)
                rock.set("quality", 1)
        
        var size = rng.randf_range(0.5, 2.0)
        var variant = rng.randi() % 30
        var rock_model = _RockGenerator.create_rock(variant, size)
        if rock_model:
                rock.add_child(rock_model)
        
        return rock

func _create_rock(rng: RandomNumberGenerator) -> Node3D:
        return _create_harvestable_rock(rng)

func _spawn_ore_nodes(world_x: float, world_z: float) -> Array:
        var result = []
        var rng = RandomNumberGenerator.new()
        rng.seed = hash(Vector2(world_x + 1000, world_z + 1000))
        
        var spacing = 16.0
        
        for z in range(0, CHUNK_SIZE, int(spacing)):
                for x in range(0, CHUNK_SIZE, int(spacing)):
                        if rng.randf() > 0.15:
                                continue
                        
                        var offset_x = rng.randf_range(-spacing * 0.3, spacing * 0.3)
                        var offset_z = rng.randf_range(-spacing * 0.3, spacing * 0.3)
                        var wx = world_x + x + offset_x
                        var wz = world_z + z + offset_z
                        
                        var height = world_gen.get_height_at(wx, wz)
                        var biome = world_gen.get_biome_at(wx, wz)
                        
                        if height < 5.0 or biome in ["ocean", "deep_ocean", "beach", "river", "lake"]:
                                continue
                        
                        var ore_type = _get_ore_type(biome, height, rng)
                        if ore_type == "":
                                continue
                        
                        var ore = _create_ore_node(ore_type, rng)
                        ore.position = Vector3(wx, height, wz)
                        ore.rotation.y = rng.randf_range(0, TAU)
                        result.append(ore)
        
        return result

func _get_ore_type(biome: String, height: float, rng: RandomNumberGenerator) -> String:
        var roll = rng.randf()
        
        if biome in ["mountain", "snow_mountain", "volcanic"]:
                if height > 60:
                        if roll < 0.1:
                                return "gold_ore"
                        elif roll < 0.25:
                                return "silver_ore"
                        elif roll < 0.5:
                                return "iron_ore"
                        return "stone"
                elif height > 30:
                        if roll < 0.15:
                                return "silver_ore"
                        elif roll < 0.4:
                                return "iron_ore"
                        elif roll < 0.6:
                                return "copper_ore"
                        return "stone"
        elif biome in ["canyon", "red_desert"]:
                if roll < 0.2:
                        return "copper_ore"
                elif roll < 0.35:
                        return "iron_ore"
                return "stone"
        elif biome == "volcanic":
                if roll < 0.1:
                        return "titanium_ore"
                elif roll < 0.25:
                        return "gold_ore"
                return "iron_ore"
        
        if roll < 0.3:
                return "iron_ore"
        elif roll < 0.5:
                return "copper_ore"
        
        return ""

func _create_ore_node(ore_type: String, rng: RandomNumberGenerator) -> StaticBody3D:
        var ore = StaticBody3D.new()
        ore.name = "Ore_" + ore_type
        ore.collision_layer = 2
        ore.collision_mask = 1
        ore.add_to_group("resources")
        ore.add_to_group("ores")
        
        var resource_script = load("res://scripts/world/resource_node.gd")
        if resource_script:
                ore.set_script(resource_script)
                ore.set("resource_type", ore_type)
                ore.set("required_tool", "pickaxe")
                ore.set("respawn_time", 1800.0)
        
        var ore_data = {
                "iron_ore": {"amount": 40.0, "gather": 5.0, "quality": 1},
                "copper_ore": {"amount": 35.0, "gather": 5.0, "quality": 1},
                "silver_ore": {"amount": 25.0, "gather": 4.0, "quality": 2},
                "gold_ore": {"amount": 20.0, "gather": 3.0, "quality": 3},
                "titanium_ore": {"amount": 15.0, "gather": 2.0, "quality": 4},
                "stone": {"amount": 60.0, "gather": 8.0, "quality": 1}
        }
        
        var data = ore_data.get(ore_type, ore_data["stone"])
        if resource_script:
                ore.set("resource_amount", data["amount"])
                ore.set("gather_amount", data["gather"])
                ore.set("quality", data["quality"])
        
        var size = rng.randf_range(0.5, 1.2)
        var ore_model = _RockGenerator.create_ore_node(ore_type, size)
        if ore_model:
                ore.add_child(ore_model)
        
        return ore
