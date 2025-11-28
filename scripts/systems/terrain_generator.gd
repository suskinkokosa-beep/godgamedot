extends Node
class_name TerrainGenerator

@export var world_size := 2048  # in world units (square world_size x world_size)
@export var chunk_size := 64    # chunk dimensions (square chunk_size x chunk_size)
@export var spawn_art_preview := false

var seed := 0
var temp_noise:OpenSimplexNoise
var moist_noise:OpenSimplexNoise
var height_noise:OpenSimplexNoise
var biome_map = null

func setup(seed_value:int):
    seed = seed_value
    var nu = get_node_or_null("/root/NoiseUtil")
    if nu == null:
        push_error("NoiseUtil autoload missing")
        return
    temp_noise = nu.create_noise(seed + 100, octaves=4, period=300.0, persistence=0.55)
    moist_noise = nu.create_noise(seed + 200, octaves=4, period=200.0, persistence=0.6)
    height_noise = nu.create_noise(seed + 300, octaves=6, period=120.0, persistence=0.5)
    biome_map = get_node_or_null("/root/BiomeMap")
    if biome_map:
        biome_map.setup(temp_noise, moist_noise)

# returns height for world x,z
func height_at(x:float, z:float) -> float:
    var s = height_noise.get_noise_2d(x * 0.01, z * 0.01)
    # amplify by distance from center to create islands or mountains
    var cx = x - world_size*0.5
    var cz = z - world_size*0.5
    var dist = sqrt(cx*cx + cz*cz) / (world_size*0.5)
    dist = clamp(dist, 0.0, 1.0)
    var elevation = s * 20.0 * (1.0 - dist)
    return elevation

# simple chunk generation: spawns environment prefabs based on biome thresholds
func generate_chunk(chunk_x:int, chunk_z:int):
    var world_x = chunk_x * chunk_size
    var world_z = chunk_z * chunk_size
    var parent = Node3D.new()
    parent.name = "chunk_%d_%d" % [chunk_x, chunk_z]
    add_child(parent)
    for ix in range(chunk_size):
        for iz in range(chunk_size):
            var wx = world_x + ix
            var wz = world_z + iz
            var h = height_at(wx, wz)
            if h < -2:
                continue
            # determine biome
            var biome = biome_map.get_biome_at(Vector3(wx,0,wz)) if biome_map else "plains"
            # decide to spawn some art props based on simple noise and biome
            var n = height_noise.get_noise_2d(wx * 0.1, wz * 0.1)
            if n > 0.65:
                var path = _pick_prop_for_biome(biome)
                if path != "":
                    var sc = ResourceLoader.load(path)
                    if sc:
                        var inst = sc.instantiate()
                        parent.add_child(inst)
                        inst.global_transform.origin = Vector3(wx, h, wz)
    return parent

func _pick_prop_for_biome(biome:String) -> String:
    # map biome to some art preview props (use art_pack prefabs we created earlier)
    match biome:
        "forest": return "res://scenes/props/rock_var_0.tscn"
        "plains": return "res://scenes/props/log_0.tscn"
        "desert": return "res://scenes/props/rock_var_0.tscn"
        "tundra": return "res://scenes/props/rock_var_0.tscn"
        "taiga": return "res://scenes/props/rock_var_0.tscn"
        _:
            return "res://scenes/props/rock_var_0.tscn"
