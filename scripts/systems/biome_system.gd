extends Node

var biomes := []
var current_player_biome := "plains"

var cold_biomes := ["snow", "snow_mountain", "tundra", "taiga", "frozen_lake", "blizzard"]
var hot_biomes := ["desert", "red_desert", "volcanic", "savanna"]
var wet_biomes := ["swamp", "marsh", "jungle", "river", "lake", "ocean", "deep_ocean"]
var dry_biomes := ["desert", "red_desert", "canyon", "savanna"]

var biome_data := {
        "ocean": {"base_temp": 12.0, "humidity": 0.9, "danger": 0.3},
        "deep_ocean": {"base_temp": 8.0, "humidity": 0.95, "danger": 0.5},
        "frozen_lake": {"base_temp": -15.0, "humidity": 0.7, "danger": 0.4},
        "beach": {"base_temp": 28.0, "humidity": 0.6, "danger": 0.1},
        "plains": {"base_temp": 22.0, "humidity": 0.4, "danger": 0.2},
        "meadow": {"base_temp": 24.0, "humidity": 0.45, "danger": 0.15},
        "forest": {"base_temp": 18.0, "humidity": 0.55, "danger": 0.3},
        "dense_forest": {"base_temp": 16.0, "humidity": 0.6, "danger": 0.4},
        "birch_forest": {"base_temp": 15.0, "humidity": 0.5, "danger": 0.25},
        "taiga": {"base_temp": 5.0, "humidity": 0.55, "danger": 0.35},
        "tundra": {"base_temp": -5.0, "humidity": 0.35, "danger": 0.4},
        "snow": {"base_temp": -15.0, "humidity": 0.3, "danger": 0.5},
        "snow_mountain": {"base_temp": -25.0, "humidity": 0.25, "danger": 0.6},
        "desert": {"base_temp": 42.0, "humidity": 0.1, "danger": 0.35},
        "red_desert": {"base_temp": 40.0, "humidity": 0.08, "danger": 0.4},
        "savanna": {"base_temp": 35.0, "humidity": 0.25, "danger": 0.3},
        "jungle": {"base_temp": 32.0, "humidity": 0.85, "danger": 0.5},
        "swamp": {"base_temp": 25.0, "humidity": 0.9, "danger": 0.45},
        "marsh": {"base_temp": 20.0, "humidity": 0.8, "danger": 0.35},
        "mountain": {"base_temp": 8.0, "humidity": 0.35, "danger": 0.4},
        "volcanic": {"base_temp": 45.0, "humidity": 0.15, "danger": 0.7},
        "canyon": {"base_temp": 30.0, "humidity": 0.2, "danger": 0.35},
        "river": {"base_temp": 18.0, "humidity": 0.75, "danger": 0.2},
        "lake": {"base_temp": 16.0, "humidity": 0.8, "danger": 0.15},
        "oasis": {"base_temp": 28.0, "humidity": 0.7, "danger": 0.1}
}

func _ready():
        pass

func add_biome(biome_name: String, center: Vector3, radius: float, base_temp: float):
        biomes.append({
                "name": biome_name, 
                "center": center, 
                "radius": radius, 
                "base_temp": base_temp
        })

func get_biome_at(pos: Vector3) -> Dictionary:
        for b in biomes:
                if pos.distance_to(b["center"]) <= b["radius"]:
                        return b
        
        var world_gen = get_node_or_null("/root/WorldGenerator")
        if world_gen and world_gen.has_method("get_biome_at"):
                var biome_name = world_gen.get_biome_at(pos.x, pos.z)
                if biome_data.has(biome_name):
                        var data = biome_data[biome_name].duplicate()
                        data["name"] = biome_name
                        return data
                return {"name": biome_name, "base_temp": 20.0}
        
        return {"name": "plains", "base_temp": 15.0}

func get_biome_name_at(pos: Vector3) -> String:
        var biome = get_biome_at(pos)
        return biome.get("name", "plains")

func get_base_temperature(biome_name: String) -> float:
        if biome_data.has(biome_name):
                return biome_data[biome_name]["base_temp"]
        return 20.0

func get_humidity(biome_name: String) -> float:
        if biome_data.has(biome_name):
                return biome_data[biome_name]["humidity"]
        return 0.5

func get_danger_level(biome_name: String) -> float:
        if biome_data.has(biome_name):
                return biome_data[biome_name]["danger"]
        return 0.2

func is_cold_biome(biome_name: String = "") -> bool:
        if biome_name == "":
                biome_name = current_player_biome
                
                var players = get_tree().get_nodes_in_group("players")
                if players.size() > 0:
                        var player = players[0]
                        if player and is_instance_valid(player):
                                var pos = player.global_position
                                biome_name = get_biome_name_at(pos)
        
        return biome_name in cold_biomes

func is_hot_biome(biome_name: String = "") -> bool:
        if biome_name == "":
                biome_name = current_player_biome
        return biome_name in hot_biomes

func is_wet_biome(biome_name: String = "") -> bool:
        if biome_name == "":
                biome_name = current_player_biome
        return biome_name in wet_biomes

func is_dry_biome(biome_name: String = "") -> bool:
        if biome_name == "":
                biome_name = current_player_biome
        return biome_name in dry_biomes

func update_player_biome(pos: Vector3):
        current_player_biome = get_biome_name_at(pos)

func get_biome_color(biome_name: String) -> Color:
        var world_gen = get_node_or_null("/root/WorldGenerator")
        if world_gen and world_gen.has_method("get_biome_color"):
                return world_gen.get_biome_color(biome_name)
        
        var colors := {
                "ocean": Color(0.1, 0.3, 0.6),
                "deep_ocean": Color(0.05, 0.15, 0.4),
                "beach": Color(0.9, 0.85, 0.6),
                "plains": Color(0.4, 0.6, 0.3),
                "forest": Color(0.2, 0.45, 0.2),
                "snow": Color(0.95, 0.97, 1.0),
                "desert": Color(0.9, 0.8, 0.5),
                "mountain": Color(0.5, 0.45, 0.4)
        }
        
        return colors.get(biome_name, Color(0.5, 0.5, 0.5))

func get_spawn_modifier(biome_name: String, creature_type: String) -> float:
        var modifier := 1.0
        
        match creature_type:
                "wolf", "bear":
                        if biome_name in ["forest", "dense_forest", "taiga"]:
                                modifier = 1.5
                        elif biome_name in ["desert", "savanna"]:
                                modifier = 0.2
                "deer", "rabbit":
                        if biome_name in ["meadow", "plains", "forest"]:
                                modifier = 1.5
                        elif biome_name in ["desert", "snow"]:
                                modifier = 0.3
                "snake", "scorpion":
                        if biome_name in ["desert", "red_desert", "canyon"]:
                                modifier = 2.0
                        elif biome_name in ["snow", "tundra"]:
                                modifier = 0.0
        
        return modifier

func get_resource_modifier(biome_name: String, resource_type: String) -> float:
        var modifier := 1.0
        
        match resource_type:
                "wood":
                        if biome_name in ["forest", "dense_forest", "jungle", "taiga"]:
                                modifier = 1.5
                        elif biome_name in ["desert", "tundra", "snow"]:
                                modifier = 0.2
                "stone":
                        if biome_name in ["mountain", "canyon", "volcanic"]:
                                modifier = 1.5
                "ore":
                        if biome_name in ["mountain", "snow_mountain", "volcanic"]:
                                modifier = 1.8
                        elif biome_name in ["plains", "meadow"]:
                                modifier = 0.5
                "herbs":
                        if biome_name in ["meadow", "forest", "jungle", "swamp"]:
                                modifier = 1.5
                        elif biome_name in ["desert", "snow"]:
                                modifier = 0.2
        
        return modifier
