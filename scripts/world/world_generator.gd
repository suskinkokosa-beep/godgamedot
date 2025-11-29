extends Node

signal chunk_generated(chunk_x: int, chunk_z: int)
signal structure_placed(structure_type: String, position: Vector3)

const CHUNK_SIZE := 32
const WORLD_SIZE := 4096
const SEA_LEVEL := 0.0
const BEACH_HEIGHT := 2.0
const HILL_HEIGHT := 15.0
const MOUNTAIN_HEIGHT := 60.0

var seed_value: int = 0
var height_noise: FastNoiseLite
var moisture_noise: FastNoiseLite
var temperature_noise: FastNoiseLite
var continent_noise: FastNoiseLite
var detail_noise: FastNoiseLite
var cave_noise: FastNoiseLite
var river_noise: FastNoiseLite

var biome_colors := {
        "ocean": Color(0.1, 0.3, 0.6),
        "deep_ocean": Color(0.05, 0.15, 0.4),
        "beach": Color(0.9, 0.85, 0.6),
        "plains": Color(0.4, 0.6, 0.3),
        "forest": Color(0.2, 0.45, 0.2),
        "dense_forest": Color(0.15, 0.35, 0.15),
        "taiga": Color(0.25, 0.4, 0.35),
        "tundra": Color(0.85, 0.9, 0.95),
        "snow": Color(0.95, 0.97, 1.0),
        "desert": Color(0.9, 0.8, 0.5),
        "savanna": Color(0.7, 0.65, 0.4),
        "swamp": Color(0.3, 0.35, 0.25),
        "mountain": Color(0.5, 0.45, 0.4),
        "snow_mountain": Color(0.9, 0.92, 0.95),
        "river": Color(0.2, 0.4, 0.7),
        "lake": Color(0.15, 0.35, 0.65)
}

var structure_templates := {}
var placed_structures := {}
var generated_chunks := {}

func _ready():
        var seed_mgr = get_node_or_null("/root/SeedManager")
        if seed_mgr and seed_mgr.has_method("get_seed"):
                initialize(seed_mgr.get_seed())
        else:
                initialize(randi())

func initialize(new_seed: int):
        seed_value = new_seed
        seed(seed_value)
        _create_noise_generators()
        _pregenerate_structures()

func _create_noise_generators():
        continent_noise = _make_noise(seed_value, 3, 800.0, 0.5)
        height_noise = _make_noise(seed_value + 1, 6, 200.0, 0.55)
        detail_noise = _make_noise(seed_value + 2, 4, 50.0, 0.6)
        moisture_noise = _make_noise(seed_value + 3, 4, 300.0, 0.5)
        temperature_noise = _make_noise(seed_value + 4, 3, 400.0, 0.45)
        cave_noise = _make_noise(seed_value + 5, 4, 30.0, 0.65)
        river_noise = _make_noise(seed_value + 6, 2, 150.0, 0.4)

func _make_noise(s: int, octaves: int, period: float, persistence: float) -> FastNoiseLite:
        var n = FastNoiseLite.new()
        n.seed = s
        n.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
        n.fractal_type = FastNoiseLite.FRACTAL_FBM
        n.fractal_octaves = octaves
        n.frequency = 1.0 / period
        n.fractal_gain = persistence
        n.fractal_lacunarity = 2.0
        return n

func get_height_at(x: float, z: float) -> float:
        var continent = (continent_noise.get_noise_2d(x, z) + 1.0) * 0.5
        var base_height = (height_noise.get_noise_2d(x, z) + 1.0) * 0.5
        var detail = detail_noise.get_noise_2d(x, z) * 0.15
        
        var dist_from_center = Vector2(x, z).length() / (WORLD_SIZE * 0.5)
        var edge_falloff = 1.0 - smoothstep(0.7, 1.0, dist_from_center)
        
        continent = continent * edge_falloff
        
        if continent < 0.35:
                return lerp(-20.0, SEA_LEVEL - 2.0, continent / 0.35)
        elif continent < 0.4:
                var t = (continent - 0.35) / 0.05
                return lerp(SEA_LEVEL - 2.0, BEACH_HEIGHT, t)
        else:
                var land_factor = (continent - 0.4) / 0.6
                var height = base_height * land_factor
                
                if height > 0.7:
                        height = lerp(HILL_HEIGHT, MOUNTAIN_HEIGHT, (height - 0.7) / 0.3)
                elif height > 0.4:
                        height = lerp(5.0, HILL_HEIGHT, (height - 0.4) / 0.3)
                else:
                        height = lerp(BEACH_HEIGHT, 5.0, height / 0.4)
                
                height += detail * (1.0 + land_factor * 2.0)
                
                var river = _get_river_factor(x, z)
                if river > 0.0 and height > SEA_LEVEL:
                        height = lerp(height, SEA_LEVEL - 1.0, river * 0.8)
                
                return height

func _get_river_factor(x: float, z: float) -> float:
        var r1 = river_noise.get_noise_2d(x, z)
        var r2 = river_noise.get_noise_2d(x * 0.5, z * 0.5 + 1000.0)
        var river_val = abs(r1) + abs(r2) * 0.5
        if river_val < 0.08:
                return 1.0 - (river_val / 0.08)
        return 0.0

func get_biome_at(x: float, z: float) -> String:
        var height = get_height_at(x, z)
        var moisture = (moisture_noise.get_noise_2d(x, z) + 1.0) * 0.5
        var temperature = (temperature_noise.get_noise_2d(x, z) + 1.0) * 0.5
        
        temperature -= height * 0.008
        
        var river = _get_river_factor(x, z)
        if river > 0.5 and height > SEA_LEVEL - 0.5:
                return "river"
        
        if height < SEA_LEVEL - 8.0:
                return "deep_ocean"
        elif height < SEA_LEVEL:
                return "ocean"
        elif height < BEACH_HEIGHT:
                return "beach"
        elif height > MOUNTAIN_HEIGHT - 10.0:
                if temperature < 0.4:
                        return "snow_mountain"
                return "mountain"
        elif height > HILL_HEIGHT:
                if temperature < 0.3:
                        return "snow"
                elif temperature < 0.5:
                        return "tundra"
                return "mountain"
        
        if temperature < 0.25:
                if moisture > 0.5:
                        return "taiga"
                return "tundra"
        elif temperature < 0.4:
                if moisture > 0.6:
                        return "taiga"
                elif moisture > 0.3:
                        return "forest"
                return "plains"
        elif temperature < 0.6:
                if moisture > 0.7:
                        return "swamp"
                elif moisture > 0.5:
                        return "dense_forest"
                elif moisture > 0.3:
                        return "forest"
                return "plains"
        elif temperature < 0.8:
                if moisture > 0.4:
                        return "forest"
                elif moisture > 0.2:
                        return "savanna"
                return "desert"
        else:
                if moisture > 0.3:
                        return "savanna"
                return "desert"

func get_biome_color(biome: String) -> Color:
        return biome_colors.get(biome, Color(0.5, 0.5, 0.5))

func is_water_biome(biome: String) -> bool:
        return biome in ["ocean", "deep_ocean", "river", "lake"]

func _pregenerate_structures():
        var rng = RandomNumberGenerator.new()
        rng.seed = seed_value + 1000
        
        var village_count = rng.randi_range(15, 25)
        for i in range(village_count):
                var pos = _find_valid_structure_pos(rng, "village", 200.0)
                if pos != Vector3.ZERO:
                        placed_structures[pos] = {"type": "village", "size": rng.randi_range(3, 8)}
        
        var city_count = rng.randi_range(3, 6)
        for i in range(city_count):
                var pos = _find_valid_structure_pos(rng, "city", 500.0)
                if pos != Vector3.ZERO:
                        placed_structures[pos] = {"type": "city", "size": rng.randi_range(8, 15)}
        
        var mine_count = rng.randi_range(10, 20)
        for i in range(mine_count):
                var pos = _find_valid_structure_pos(rng, "mine", 150.0)
                if pos != Vector3.ZERO:
                        placed_structures[pos] = {"type": "mine", "depth": rng.randi_range(3, 10)}
        
        var camp_count = rng.randi_range(20, 40)
        for i in range(camp_count):
                var pos = _find_valid_structure_pos(rng, "camp", 100.0)
                if pos != Vector3.ZERO:
                        placed_structures[pos] = {"type": "camp", "faction": _random_faction(rng)}

func _find_valid_structure_pos(rng: RandomNumberGenerator, type: String, min_distance: float) -> Vector3:
        for attempt in range(50):
                var x = rng.randf_range(-WORLD_SIZE * 0.4, WORLD_SIZE * 0.4)
                var z = rng.randf_range(-WORLD_SIZE * 0.4, WORLD_SIZE * 0.4)
                var height = get_height_at(x, z)
                var biome = get_biome_at(x, z)
                
                if is_water_biome(biome):
                        continue
                
                if type == "mine" and height < HILL_HEIGHT:
                        continue
                if type in ["village", "city"] and (height < BEACH_HEIGHT or height > HILL_HEIGHT):
                        continue
                if type == "camp" and height < BEACH_HEIGHT:
                        continue
                
                var valid = true
                for pos in placed_structures.keys():
                        if Vector3(x, height, z).distance_to(pos) < min_distance:
                                valid = false
                                break
                
                if valid:
                        return Vector3(x, height, z)
        
        return Vector3.ZERO

func _random_faction(rng: RandomNumberGenerator) -> String:
        var factions = ["town", "bandits", "neutral", "wild"]
        return factions[rng.randi() % factions.size()]

func get_structures_in_chunk(chunk_x: int, chunk_z: int) -> Array:
        var result = []
        var min_x = chunk_x * CHUNK_SIZE
        var max_x = min_x + CHUNK_SIZE
        var min_z = chunk_z * CHUNK_SIZE
        var max_z = min_z + CHUNK_SIZE
        
        for pos in placed_structures.keys():
                if pos.x >= min_x and pos.x < max_x and pos.z >= min_z and pos.z < max_z:
                        result.append({"position": pos, "data": placed_structures[pos]})
        
        return result

func should_spawn_tree(x: float, z: float) -> bool:
        var biome = get_biome_at(x, z)
        var height = get_height_at(x, z)
        
        if is_water_biome(biome) or height < BEACH_HEIGHT:
                return false
        
        var tree_noise = detail_noise.get_noise_2d(x * 2.0, z * 2.0)
        
        match biome:
                "dense_forest":
                        return tree_noise > -0.3
                "forest":
                        return tree_noise > 0.0
                "taiga":
                        return tree_noise > 0.1
                "swamp":
                        return tree_noise > 0.2
                "plains":
                        return tree_noise > 0.6
                "savanna":
                        return tree_noise > 0.5
                _:
                        return false

func get_tree_type(biome: String) -> String:
        match biome:
                "dense_forest", "forest":
                        return ["oak", "birch", "maple"][randi() % 3]
                "taiga":
                        return ["pine", "spruce"][randi() % 2]
                "swamp":
                        return "willow"
                "savanna":
                        return "acacia"
                "plains":
                        return ["oak", "birch"][randi() % 2]
                _:
                        return "oak"

func should_spawn_rock(x: float, z: float) -> bool:
        var biome = get_biome_at(x, z)
        var height = get_height_at(x, z)
        
        if is_water_biome(biome):
                return false
        
        var rock_noise = cave_noise.get_noise_2d(x, z)
        
        if biome in ["mountain", "snow_mountain"]:
                return rock_noise > 0.2
        elif height > HILL_HEIGHT * 0.7:
                return rock_noise > 0.4
        else:
                return rock_noise > 0.7

func get_vegetation_density(biome: String) -> float:
        match biome:
                "dense_forest": return 0.8
                "forest": return 0.5
                "taiga": return 0.4
                "swamp": return 0.3
                "plains": return 0.15
                "savanna": return 0.1
                "tundra": return 0.05
                _: return 0.0

func smoothstep(edge0: float, edge1: float, x: float) -> float:
        var t = clamp((x - edge0) / (edge1 - edge0), 0.0, 1.0)
        return t * t * (3.0 - 2.0 * t)
