extends Node

@export var world_size := 2048
@export var chunk_size := 64
@export var spawn_art_preview := false

var seed_value := 0
var temp_noise: FastNoiseLite
var moist_noise: FastNoiseLite
var height_noise: FastNoiseLite
var biome_map = null
var is_setup := false

func _ready():
    var seed_mgr = get_node_or_null("/root/SeedManager")
    if seed_mgr and seed_mgr.has_method("get_seed"):
        setup(seed_mgr.get_seed())
    else:
        setup(12345)

func setup(seed_val: int):
    seed_value = seed_val
    var nu = get_node_or_null("/root/NoiseUtil")
    if nu == null:
        nu = self
    temp_noise = _create_noise(seed_value + 100, 4, 300.0, 0.55)
    moist_noise = _create_noise(seed_value + 200, 4, 200.0, 0.6)
    height_noise = _create_noise(seed_value + 300, 6, 120.0, 0.5)
    biome_map = get_node_or_null("/root/BiomeMap")
    if biome_map and biome_map.has_method("setup"):
        biome_map.setup(temp_noise, moist_noise)
    is_setup = true

func _create_noise(seed_val: int, octaves: int, period: float, persistence: float) -> FastNoiseLite:
    var n = FastNoiseLite.new()
    n.seed = seed_val
    n.fractal_octaves = octaves
    n.frequency = 1.0 / period
    n.fractal_gain = persistence
    n.noise_type = FastNoiseLite.TYPE_SIMPLEX
    return n

func height_at(x: float, z: float) -> float:
    if not height_noise:
        return 0.0
    var s = height_noise.get_noise_2d(x * 0.01, z * 0.01)
    var cx = x - world_size * 0.5
    var cz = z - world_size * 0.5
    var dist = sqrt(cx * cx + cz * cz) / (world_size * 0.5)
    dist = clamp(dist, 0.0, 1.0)
    var elevation = s * 20.0 * (1.0 - dist)
    return elevation

func generate_chunk(chunk_x: int, chunk_z: int):
    if not is_setup:
        return null
    var world_x = chunk_x * chunk_size
    var world_z = chunk_z * chunk_size
    var parent = Node3D.new()
    parent.name = "chunk_%d_%d" % [chunk_x, chunk_z]
    add_child(parent)
    
    # Create ground mesh for this chunk
    var ground = StaticBody3D.new()
    ground.name = "Ground"
    ground.position = Vector3(world_x + chunk_size * 0.5, 0, world_z + chunk_size * 0.5)
    parent.add_child(ground)
    
    # Collision shape
    var col = CollisionShape3D.new()
    var box = BoxShape3D.new()
    box.size = Vector3(chunk_size, 1, chunk_size)
    col.shape = box
    col.position = Vector3(0, -0.5, 0)
    ground.add_child(col)
    
    # Visual mesh
    var mesh_inst = MeshInstance3D.new()
    var plane_mesh = BoxMesh.new()
    plane_mesh.size = Vector3(chunk_size, 1, chunk_size)
    mesh_inst.mesh = plane_mesh
    mesh_inst.position = Vector3(0, -0.5, 0)
    
    # Color based on biome
    var material = StandardMaterial3D.new()
    var biome_name = "plains"
    if biome_map and biome_map.has_method("get_biome_at"):
        var pos = Vector3(world_x + chunk_size * 0.5, 0, world_z + chunk_size * 0.5)
        biome_name = biome_map.get_biome_at(pos)
    
    match biome_name:
        "forest":
            material.albedo_color = Color(0.2, 0.5, 0.2)
        "desert":
            material.albedo_color = Color(0.8, 0.7, 0.4)
        "tundra":
            material.albedo_color = Color(0.9, 0.95, 1.0)
        "taiga":
            material.albedo_color = Color(0.3, 0.4, 0.3)
        _:
            material.albedo_color = Color(0.3, 0.5, 0.25)
    
    mesh_inst.material_override = material
    ground.add_child(mesh_inst)
    
    return parent

func _pick_prop_for_biome(biome: String) -> String:
    match biome:
        "forest": return "res://scenes/props/rock_var_0.tscn"
        "plains": return "res://scenes/props/log_0.tscn"
        "desert": return "res://scenes/props/rock_var_0.tscn"
        "tundra": return "res://scenes/props/rock_var_0.tscn"
        "taiga": return "res://scenes/props/rock_var_0.tscn"
        _:
            return "res://scenes/props/rock_var_0.tscn"
