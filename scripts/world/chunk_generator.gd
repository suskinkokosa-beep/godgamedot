extends Node

const CHUNK_SIZE := 32
const MESH_RESOLUTION := 16
const VERTEX_SPACING := CHUNK_SIZE / float(MESH_RESOLUTION)

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
        
        return chunk

func _create_terrain_mesh(world_x: float, world_z: float) -> StaticBody3D:
        var terrain = StaticBody3D.new()
        terrain.name = "Terrain"
        
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
        
        var material = StandardMaterial3D.new()
        material.vertex_color_use_as_albedo = true
        material.roughness = 0.9
        mesh_instance.material_override = material
        
        terrain.add_child(mesh_instance)
        
        var shape = _create_collision_shape(heights, world_x, world_z)
        var collision = CollisionShape3D.new()
        collision.shape = shape
        terrain.add_child(collision)
        
        return terrain

func _create_collision_shape(heights: Array, world_x: float, world_z: float) -> HeightMapShape3D:
        var shape = HeightMapShape3D.new()
        var size = MESH_RESOLUTION + 1
        shape.map_width = size
        shape.map_depth = size
        
        var map_data = PackedFloat32Array()
        map_data.resize(size * size)
        
        for z in range(size):
                for x in range(size):
                        map_data[z * size + x] = heights[z][x]
        
        shape.map_data = map_data
        
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
                        var tree = _create_tree(tree_type, rng)
                        
                        if tree:
                                var height = world_gen.get_height_at(wx, wz)
                                tree.position = Vector3(wx, height, wz)
                                tree.rotation.y = rng.randf_range(0, TAU)
                                var scale_factor = rng.randf_range(0.7, 1.3)
                                tree.scale = Vector3(scale_factor, scale_factor, scale_factor)
                                result.append(tree)
        
        return result

func _create_tree(tree_type: String, rng: RandomNumberGenerator) -> Node3D:
        if tree_scenes.has(tree_type):
                return tree_scenes[tree_type].instantiate()
        
        var tree = Node3D.new()
        tree.name = "Tree_" + tree_type
        
        var trunk = MeshInstance3D.new()
        trunk.name = "Trunk"
        var trunk_mesh = CylinderMesh.new()
        
        var trunk_height = rng.randf_range(2.0, 4.0)
        var trunk_radius = rng.randf_range(0.15, 0.3)
        
        match tree_type:
                "pine", "spruce":
                        trunk_height = rng.randf_range(4.0, 7.0)
                        trunk_radius = rng.randf_range(0.2, 0.35)
                "willow":
                        trunk_height = rng.randf_range(2.5, 4.0)
                        trunk_radius = rng.randf_range(0.25, 0.4)
                "acacia":
                        trunk_height = rng.randf_range(2.0, 3.5)
                        trunk_radius = rng.randf_range(0.15, 0.25)
        
        trunk_mesh.height = trunk_height
        trunk_mesh.top_radius = trunk_radius * 0.7
        trunk_mesh.bottom_radius = trunk_radius
        trunk.mesh = trunk_mesh
        trunk.position.y = trunk_height * 0.5
        
        var trunk_mat = StandardMaterial3D.new()
        trunk_mat.albedo_color = Color(0.35, 0.25, 0.15)
        trunk.material_override = trunk_mat
        
        tree.add_child(trunk)
        
        var leaves = MeshInstance3D.new()
        leaves.name = "Leaves"
        
        var leaves_color = Color(0.2, 0.5, 0.2)
        
        match tree_type:
                "pine", "spruce":
                        var cone = CylinderMesh.new()
                        cone.height = trunk_height * 1.2
                        cone.top_radius = 0.1
                        cone.bottom_radius = trunk_height * 0.4
                        leaves.mesh = cone
                        leaves.position.y = trunk_height + cone.height * 0.4
                        leaves_color = Color(0.15, 0.35, 0.2)
                "willow":
                        var sphere = SphereMesh.new()
                        sphere.radius = trunk_height * 0.6
                        sphere.height = trunk_height * 0.8
                        leaves.mesh = sphere
                        leaves.position.y = trunk_height + sphere.height * 0.3
                        leaves_color = Color(0.25, 0.45, 0.2)
                "birch":
                        var sphere = SphereMesh.new()
                        sphere.radius = trunk_height * 0.5
                        sphere.height = trunk_height * 0.7
                        leaves.mesh = sphere
                        leaves.position.y = trunk_height + sphere.height * 0.3
                        leaves_color = Color(0.35, 0.55, 0.25)
                        trunk_mat.albedo_color = Color(0.9, 0.88, 0.85)
                "acacia":
                        var box = BoxMesh.new()
                        box.size = Vector3(trunk_height * 0.8, trunk_height * 0.3, trunk_height * 0.8)
                        leaves.mesh = box
                        leaves.position.y = trunk_height + box.size.y * 0.5
                        leaves_color = Color(0.3, 0.5, 0.15)
                _:
                        var sphere = SphereMesh.new()
                        sphere.radius = trunk_height * 0.5
                        sphere.height = trunk_height * 0.6
                        leaves.mesh = sphere
                        leaves.position.y = trunk_height + sphere.height * 0.3
        
        var leaves_mat = StandardMaterial3D.new()
        leaves_mat.albedo_color = leaves_color
        leaves.material_override = leaves_mat
        
        tree.add_child(leaves)
        
        var col_shape = CollisionShape3D.new()
        var capsule = CapsuleShape3D.new()
        capsule.radius = trunk_radius * 1.5
        capsule.height = trunk_height
        col_shape.shape = capsule
        col_shape.position.y = trunk_height * 0.5
        
        var static_body = StaticBody3D.new()
        static_body.add_child(col_shape)
        tree.add_child(static_body)
        
        return tree

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
                        
                        var rock = _create_rock(rng)
                        var height = world_gen.get_height_at(wx, wz)
                        rock.position = Vector3(wx, height, wz)
                        rock.rotation.y = rng.randf_range(0, TAU)
                        result.append(rock)
        
        return result

func _create_rock(rng: RandomNumberGenerator) -> Node3D:
        var idx = rng.randi() % max(1, rock_scenes.size())
        if rock_scenes.has(idx):
                return rock_scenes[idx].instantiate()
        
        var rock = Node3D.new()
        rock.name = "Rock"
        
        var mesh_inst = MeshInstance3D.new()
        var box = BoxMesh.new()
        var size = rng.randf_range(0.5, 2.0)
        box.size = Vector3(size, size * 0.6, size * 0.8)
        mesh_inst.mesh = box
        mesh_inst.position.y = box.size.y * 0.5
        
        var mat = StandardMaterial3D.new()
        mat.albedo_color = Color(0.45, 0.42, 0.4)
        mat.roughness = 0.95
        mesh_inst.material_override = mat
        
        rock.add_child(mesh_inst)
        
        var col = CollisionShape3D.new()
        var col_box = BoxShape3D.new()
        col_box.size = box.size
        col.shape = col_box
        col.position.y = box.size.y * 0.5
        
        var body = StaticBody3D.new()
        body.add_child(col)
        rock.add_child(body)
        
        return rock
