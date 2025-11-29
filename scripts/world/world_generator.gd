extends Node

signal chunk_generated(chunk_x: int, chunk_z: int)
signal structure_placed(structure_type: String, position: Vector3)

const CHUNK_SIZE := 32
const WORLD_SIZE := 16384
const SEA_LEVEL := 0.0
const BEACH_HEIGHT := 2.0
const HILL_HEIGHT := 15.0
const MOUNTAIN_HEIGHT := 80.0
const DEEP_VALLEY := -15.0
const CANYON_DEPTH := 25.0

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
        "meadow": Color(0.5, 0.7, 0.35),
        "forest": Color(0.2, 0.45, 0.2),
        "dense_forest": Color(0.15, 0.35, 0.15),
        "birch_forest": Color(0.35, 0.55, 0.3),
        "taiga": Color(0.25, 0.4, 0.35),
        "tundra": Color(0.85, 0.9, 0.95),
        "snow": Color(0.95, 0.97, 1.0),
        "frozen_lake": Color(0.7, 0.85, 0.95),
        "desert": Color(0.9, 0.8, 0.5),
        "red_desert": Color(0.8, 0.5, 0.35),
        "savanna": Color(0.7, 0.65, 0.4),
        "jungle": Color(0.1, 0.4, 0.15),
        "swamp": Color(0.3, 0.35, 0.25),
        "marsh": Color(0.35, 0.4, 0.3),
        "mountain": Color(0.5, 0.45, 0.4),
        "snow_mountain": Color(0.9, 0.92, 0.95),
        "volcanic": Color(0.3, 0.2, 0.2),
        "canyon": Color(0.6, 0.4, 0.3),
        "river": Color(0.2, 0.4, 0.7),
        "lake": Color(0.15, 0.35, 0.65),
        "oasis": Color(0.3, 0.6, 0.4)
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

var erosion_noise: FastNoiseLite
var peaks_noise: FastNoiseLite
var volcanic_noise: FastNoiseLite

func _create_noise_generators():
        continent_noise = _make_noise(seed_value, 4, 1200.0, 0.5)
        height_noise = _make_noise(seed_value + 1, 7, 300.0, 0.55)
        detail_noise = _make_noise(seed_value + 2, 5, 40.0, 0.6)
        moisture_noise = _make_noise(seed_value + 3, 5, 400.0, 0.5)
        temperature_noise = _make_noise(seed_value + 4, 4, 600.0, 0.45)
        cave_noise = _make_noise(seed_value + 5, 4, 30.0, 0.65)
        river_noise = _make_noise(seed_value + 6, 3, 200.0, 0.4)
        erosion_noise = _make_noise(seed_value + 7, 3, 150.0, 0.5)
        peaks_noise = _make_noise(seed_value + 8, 2, 80.0, 0.7)
        volcanic_noise = _make_noise(seed_value + 9, 2, 500.0, 0.3)

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
        var erosion = (erosion_noise.get_noise_2d(x, z) + 1.0) * 0.5
        var peaks = peaks_noise.get_noise_2d(x, z)
        
        var dist_from_center = Vector2(x, z).length() / (WORLD_SIZE * 0.5)
        var edge_falloff = 1.0 - smoothstep(0.8, 1.0, dist_from_center)
        
        continent = continent * edge_falloff
        
        if continent < 0.3:
                var depth = lerp(-35.0, SEA_LEVEL - 5.0, continent / 0.3)
                depth += detail * 2.0
                return depth
        elif continent < 0.38:
                var t = (continent - 0.3) / 0.08
                return lerp(SEA_LEVEL - 5.0, BEACH_HEIGHT, t)
        else:
                var land_factor = (continent - 0.38) / 0.62
                var height = base_height * land_factor
                
                height = height * (0.6 + erosion * 0.8)
                
                if height > 0.75:
                        var mountain_factor = (height - 0.75) / 0.25
                        height = lerp(HILL_HEIGHT, MOUNTAIN_HEIGHT, mountain_factor)
                        if peaks > 0.3:
                                height += peaks * 25.0
                elif height > 0.5:
                        height = lerp(8.0, HILL_HEIGHT, (height - 0.5) / 0.25)
                elif height > 0.25:
                        height = lerp(3.0, 8.0, (height - 0.25) / 0.25)
                else:
                        height = lerp(BEACH_HEIGHT, 3.0, height / 0.25)
                
                height += detail * (1.5 + land_factor * 3.0)
                
                var canyon = _get_canyon_factor(x, z)
                if canyon > 0.0 and height > BEACH_HEIGHT + 2.0:
                        height = lerp(height, height - CANYON_DEPTH * canyon, canyon)
                
                var river = _get_river_factor(x, z)
                if river > 0.0 and height > SEA_LEVEL:
                        var river_depth = lerp(0.0, 3.0, river)
                        height = lerp(height, SEA_LEVEL - river_depth, river * 0.85)
                
                return height

func _get_canyon_factor(x: float, z: float) -> float:
        var c1 = erosion_noise.get_noise_2d(x * 0.3, z * 0.3)
        var c2 = erosion_noise.get_noise_2d(x * 0.15 + 500.0, z * 0.15)
        var canyon_val = abs(c1 * c2)
        if canyon_val < 0.02:
                return 1.0 - (canyon_val / 0.02)
        return 0.0

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
        var volcanic = volcanic_noise.get_noise_2d(x, z)
        
        temperature -= height * 0.006
        
        var river = _get_river_factor(x, z)
        if river > 0.5 and height > SEA_LEVEL - 0.5:
                return "river"
        
        var canyon = _get_canyon_factor(x, z)
        if canyon > 0.6 and height > BEACH_HEIGHT:
                return "canyon"
        
        if height < SEA_LEVEL - 15.0:
                return "deep_ocean"
        elif height < SEA_LEVEL:
                if temperature < 0.2:
                        return "frozen_lake"
                return "ocean"
        elif height < BEACH_HEIGHT:
                return "beach"
        elif height > MOUNTAIN_HEIGHT - 5.0:
                if volcanic > 0.6:
                        return "volcanic"
                if temperature < 0.35:
                        return "snow_mountain"
                return "mountain"
        elif height > HILL_HEIGHT:
                if temperature < 0.25:
                        return "snow"
                elif temperature < 0.45:
                        return "tundra"
                return "mountain"
        
        if temperature < 0.2:
                if moisture > 0.6:
                        return "taiga"
                elif moisture > 0.3:
                        return "tundra"
                return "snow"
        elif temperature < 0.35:
                if moisture > 0.65:
                        return "taiga"
                elif moisture > 0.4:
                        return "birch_forest"
                elif moisture > 0.2:
                        return "plains"
                return "tundra"
        elif temperature < 0.5:
                if moisture > 0.7:
                        return "marsh"
                elif moisture > 0.5:
                        return "dense_forest"
                elif moisture > 0.35:
                        return "forest"
                elif moisture > 0.2:
                        return "meadow"
                return "plains"
        elif temperature < 0.7:
                if moisture > 0.75:
                        return "swamp"
                elif moisture > 0.55:
                        return "jungle"
                elif moisture > 0.35:
                        return "forest"
                elif moisture > 0.2:
                        return "savanna"
                return "desert"
        else:
                if moisture > 0.5:
                        return "oasis"
                elif moisture > 0.25:
                        return "savanna"
                elif moisture > 0.1:
                        return "red_desert"
                return "desert"

func get_biome_color(biome: String) -> Color:
        return biome_colors.get(biome, Color(0.5, 0.5, 0.5))

func is_water_biome(biome: String) -> bool:
        return biome in ["ocean", "deep_ocean", "river", "lake", "frozen_lake"]

func _pregenerate_structures():
        var rng = RandomNumberGenerator.new()
        rng.seed = seed_value + 1000
        
        var village_count = rng.randi_range(40, 60)
        for i in range(village_count):
                var pos = _find_valid_structure_pos(rng, "village", 300.0)
                if pos != Vector3.ZERO:
                        placed_structures[pos] = {"type": "village", "size": rng.randi_range(3, 10)}
        
        var city_count = rng.randi_range(8, 15)
        for i in range(city_count):
                var pos = _find_valid_structure_pos(rng, "city", 800.0)
                if pos != Vector3.ZERO:
                        placed_structures[pos] = {"type": "city", "size": rng.randi_range(10, 25)}
        
        var capital_count = rng.randi_range(2, 4)
        for i in range(capital_count):
                var pos = _find_valid_structure_pos(rng, "capital", 1500.0)
                if pos != Vector3.ZERO:
                        placed_structures[pos] = {"type": "capital", "size": rng.randi_range(20, 40)}
        
        var mine_count = rng.randi_range(25, 45)
        for i in range(mine_count):
                var pos = _find_valid_structure_pos(rng, "mine", 200.0)
                if pos != Vector3.ZERO:
                        placed_structures[pos] = {"type": "mine", "depth": rng.randi_range(3, 15)}
        
        var camp_count = rng.randi_range(50, 80)
        for i in range(camp_count):
                var pos = _find_valid_structure_pos(rng, "camp", 150.0)
                if pos != Vector3.ZERO:
                        placed_structures[pos] = {"type": "camp", "faction": _random_faction(rng)}
        
        var ruins_count = rng.randi_range(15, 30)
        for i in range(ruins_count):
                var pos = _find_valid_structure_pos(rng, "ruins", 250.0)
                if pos != Vector3.ZERO:
                        placed_structures[pos] = {"type": "ruins", "age": rng.randi_range(1, 5)}
        
        var tower_count = rng.randi_range(10, 20)
        for i in range(tower_count):
                var pos = _find_valid_structure_pos(rng, "tower", 400.0)
                if pos != Vector3.ZERO:
                        placed_structures[pos] = {"type": "tower", "faction": _random_faction(rng)}

func _find_valid_structure_pos(rng: RandomNumberGenerator, type: String, min_distance: float) -> Vector3:
        for attempt in range(80):
                var x = rng.randf_range(-WORLD_SIZE * 0.45, WORLD_SIZE * 0.45)
                var z = rng.randf_range(-WORLD_SIZE * 0.45, WORLD_SIZE * 0.45)
                var height = get_height_at(x, z)
                var biome = get_biome_at(x, z)
                
                if is_water_biome(biome):
                        continue
                
                if type == "mine" and height < HILL_HEIGHT * 0.7:
                        continue
                if type in ["village", "city", "capital"] and (height < BEACH_HEIGHT or height > HILL_HEIGHT):
                        continue
                if type == "capital" and biome in ["swamp", "marsh", "desert", "red_desert", "tundra"]:
                        continue
                if type == "camp" and height < BEACH_HEIGHT:
                        continue
                if type == "ruins" and height < BEACH_HEIGHT:
                        continue
                if type == "tower" and height < 5.0:
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
                "jungle":
                        return tree_noise > -0.4
                "dense_forest":
                        return tree_noise > -0.25
                "forest":
                        return tree_noise > 0.05
                "birch_forest":
                        return tree_noise > 0.0
                "taiga":
                        return tree_noise > 0.1
                "swamp", "marsh":
                        return tree_noise > 0.2
                "meadow":
                        return tree_noise > 0.55
                "plains":
                        return tree_noise > 0.65
                "savanna":
                        return tree_noise > 0.5
                "oasis":
                        return tree_noise > 0.3
                _:
                        return false

func get_tree_type(biome: String) -> String:
        match biome:
                "jungle":
                        return ["palm", "tropical", "bamboo"][randi() % 3]
                "dense_forest":
                        return ["oak", "oak_large", "maple"][randi() % 3]
                "forest":
                        return ["oak", "birch", "maple"][randi() % 3]
                "birch_forest":
                        return ["birch", "birch_tall"][randi() % 2]
                "taiga":
                        return ["pine", "spruce", "fir"][randi() % 3]
                "swamp", "marsh":
                        return ["willow", "dead_tree"][randi() % 2]
                "savanna":
                        return ["acacia", "baobab"][randi() % 2]
                "oasis":
                        return ["palm", "date_palm"][randi() % 2]
                "meadow", "plains":
                        return ["oak", "birch", "apple"][randi() % 3]
                _:
                        return "oak"

func should_spawn_rock(x: float, z: float) -> bool:
        var biome = get_biome_at(x, z)
        var height = get_height_at(x, z)
        
        if is_water_biome(biome):
                return false
        
        var rock_noise = cave_noise.get_noise_2d(x, z)
        
        match biome:
                "mountain", "snow_mountain", "volcanic":
                        return rock_noise > 0.15
                "canyon":
                        return rock_noise > 0.25
                "tundra":
                        return rock_noise > 0.45
                "red_desert", "desert":
                        return rock_noise > 0.55
                _:
                        if height > HILL_HEIGHT * 0.7:
                                return rock_noise > 0.4
                        return rock_noise > 0.7

func get_vegetation_density(biome: String) -> float:
        match biome:
                "jungle": return 0.95
                "dense_forest": return 0.8
                "forest": return 0.55
                "birch_forest": return 0.6
                "taiga": return 0.45
                "swamp": return 0.35
                "marsh": return 0.4
                "meadow": return 0.25
                "plains": return 0.15
                "savanna": return 0.12
                "oasis": return 0.5
                "tundra": return 0.05
                "desert", "red_desert": return 0.02
                _: return 0.0

func get_ore_type(x: float, z: float) -> String:
        var height = get_height_at(x, z)
        var biome = get_biome_at(x, z)
        var ore_noise = cave_noise.get_noise_2d(x * 0.5, z * 0.5)
        
        if biome == "volcanic":
                if ore_noise > 0.6:
                        return "obsidian"
                elif ore_noise > 0.4:
                        return "sulfur"
                return "iron"
        
        if height > MOUNTAIN_HEIGHT - 10.0:
                if ore_noise > 0.7:
                        return "gold"
                elif ore_noise > 0.5:
                        return "silver"
                elif ore_noise > 0.3:
                        return "tin"
                return "copper"
        elif height > HILL_HEIGHT:
                if ore_noise > 0.6:
                        return "iron"
                elif ore_noise > 0.4:
                        return "copper"
                return "coal"
        else:
                if ore_noise > 0.7:
                        return "copper"
                elif ore_noise > 0.5:
                        return "coal"
                return "stone"

func smoothstep(edge0: float, edge1: float, x: float) -> float:
        var t = clamp((x - edge0) / (edge1 - edge0), 0.0, 1.0)
        return t * t * (3.0 - 2.0 * t)
