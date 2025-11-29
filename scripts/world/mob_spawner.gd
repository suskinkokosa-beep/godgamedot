extends Node

signal mob_spawned(mob: Node3D, biome: String)
signal mob_despawned(mob: Node3D)

@export var max_mobs := 50
@export var spawn_radius := 80.0
@export var despawn_radius := 120.0
@export var spawn_interval := 2.0
@export var min_spawn_distance := 20.0

var world_gen
var player_ref: Node3D
var spawned_mobs := []
var spawn_timer := 0.0

var mob_scenes := {}
var animal_scenes := {}

var biome_spawn_tables := {
        "forest": [
                {"type": "wolf", "weight": 20, "pack_size": [2, 4]},
                {"type": "boar", "weight": 35, "pack_size": [1, 3]},
                {"type": "bear", "weight": 10, "pack_size": [1, 1]},
                {"type": "deer", "weight": 25, "pack_size": [2, 5]},
                {"type": "rabbit", "weight": 10, "pack_size": [1, 2]}
        ],
        "dense_forest": [
                {"type": "wolf", "weight": 25, "pack_size": [3, 5]},
                {"type": "bear", "weight": 20, "pack_size": [1, 2]},
                {"type": "boar", "weight": 30, "pack_size": [2, 4]},
                {"type": "spider", "weight": 15, "pack_size": [2, 4]},
                {"type": "deer", "weight": 10, "pack_size": [1, 3]}
        ],
        "plains": [
                {"type": "boar", "weight": 30, "pack_size": [2, 4]},
                {"type": "deer", "weight": 25, "pack_size": [3, 6]},
                {"type": "rabbit", "weight": 25, "pack_size": [2, 4]},
                {"type": "wolf", "weight": 10, "pack_size": [2, 3]},
                {"type": "bandit", "weight": 10, "pack_size": [2, 4]}
        ],
        "taiga": [
                {"type": "wolf", "weight": 35, "pack_size": [3, 6]},
                {"type": "bear", "weight": 25, "pack_size": [1, 2]},
                {"type": "deer", "weight": 20, "pack_size": [2, 4]},
                {"type": "rabbit", "weight": 20, "pack_size": [1, 2]}
        ],
        "tundra": [
                {"type": "wolf", "weight": 40, "pack_size": [4, 7]},
                {"type": "bear", "weight": 30, "pack_size": [1, 1]},
                {"type": "rabbit", "weight": 30, "pack_size": [1, 2]}
        ],
        "desert": [
                {"type": "scorpion", "weight": 35, "pack_size": [1, 3]},
                {"type": "snake", "weight": 30, "pack_size": [1, 2]},
                {"type": "bandit", "weight": 25, "pack_size": [3, 6]},
                {"type": "vulture", "weight": 10, "pack_size": [2, 4]}
        ],
        "savanna": [
                {"type": "lion", "weight": 20, "pack_size": [2, 4]},
                {"type": "hyena", "weight": 25, "pack_size": [3, 5]},
                {"type": "elephant", "weight": 10, "pack_size": [2, 4]},
                {"type": "zebra", "weight": 25, "pack_size": [4, 8]},
                {"type": "bandit", "weight": 20, "pack_size": [2, 4]}
        ],
        "swamp": [
                {"type": "snake", "weight": 30, "pack_size": [1, 2]},
                {"type": "spider", "weight": 25, "pack_size": [2, 4]},
                {"type": "croc", "weight": 20, "pack_size": [1, 2]},
                {"type": "frog", "weight": 15, "pack_size": [3, 6]},
                {"type": "zombie", "weight": 10, "pack_size": [2, 4]}
        ],
        "mountain": [
                {"type": "goat", "weight": 35, "pack_size": [2, 5]},
                {"type": "eagle", "weight": 20, "pack_size": [1, 2]},
                {"type": "bear", "weight": 15, "pack_size": [1, 1]},
                {"type": "bandit", "weight": 20, "pack_size": [2, 4]},
                {"type": "wolf", "weight": 10, "pack_size": [2, 3]}
        ],
        "snow_mountain": [
                {"type": "wolf", "weight": 40, "pack_size": [3, 5]},
                {"type": "bear", "weight": 30, "pack_size": [1, 1]},
                {"type": "goat", "weight": 30, "pack_size": [2, 4]}
        ]
}

var mob_stats := {
        "wolf": {"hp": 40, "damage": 8, "speed": 6.0, "aggressive": true, "faction": "wild"},
        "bear": {"hp": 120, "damage": 20, "speed": 4.0, "aggressive": true, "faction": "wild"},
        "boar": {"hp": 50, "damage": 10, "speed": 5.0, "aggressive": false, "faction": "wild"},
        "deer": {"hp": 30, "damage": 5, "speed": 7.0, "aggressive": false, "faction": "wild"},
        "rabbit": {"hp": 10, "damage": 0, "speed": 8.0, "aggressive": false, "faction": "wild"},
        "spider": {"hp": 25, "damage": 12, "speed": 5.5, "aggressive": true, "faction": "monsters"},
        "snake": {"hp": 15, "damage": 15, "speed": 4.0, "aggressive": true, "faction": "wild"},
        "scorpion": {"hp": 20, "damage": 18, "speed": 3.5, "aggressive": true, "faction": "wild"},
        "lion": {"hp": 80, "damage": 15, "speed": 7.0, "aggressive": true, "faction": "wild"},
        "hyena": {"hp": 35, "damage": 8, "speed": 6.5, "aggressive": true, "faction": "wild"},
        "elephant": {"hp": 200, "damage": 25, "speed": 3.0, "aggressive": false, "faction": "wild"},
        "zebra": {"hp": 40, "damage": 5, "speed": 8.0, "aggressive": false, "faction": "wild"},
        "croc": {"hp": 70, "damage": 18, "speed": 3.0, "aggressive": true, "faction": "wild"},
        "frog": {"hp": 5, "damage": 0, "speed": 4.0, "aggressive": false, "faction": "wild"},
        "goat": {"hp": 35, "damage": 6, "speed": 5.0, "aggressive": false, "faction": "wild"},
        "eagle": {"hp": 20, "damage": 8, "speed": 10.0, "aggressive": false, "faction": "wild"},
        "vulture": {"hp": 15, "damage": 5, "speed": 8.0, "aggressive": false, "faction": "wild"},
        "bandit": {"hp": 60, "damage": 12, "speed": 4.5, "aggressive": true, "faction": "bandits"},
        "zombie": {"hp": 45, "damage": 10, "speed": 2.5, "aggressive": true, "faction": "monsters"}
}

func _ready():
        call_deferred("_late_init")

func _late_init():
        world_gen = get_node_or_null("/root/WorldGenerator")
        _preload_scenes()
        _find_player()

func _preload_scenes():
        var paths = {
                "wolf": "res://scenes/mobs/wolf.tscn",
                "bear": "res://scenes/mobs/bear.tscn",
                "boar": "res://scenes/mobs/boar.tscn",
                "deer": "res://scenes/mobs/deer.tscn",
                "rabbit": "res://scenes/mobs/rabbit.tscn",
                "spider": "res://scenes/mobs/spider.tscn",
                "snake": "res://scenes/mobs/snake.tscn",
                "scorpion": "res://scenes/mobs/scorpion.tscn",
                "lion": "res://scenes/mobs/lion.tscn",
                "hyena": "res://scenes/mobs/hyena.tscn",
                "elephant": "res://scenes/mobs/elephant.tscn",
                "zebra": "res://scenes/mobs/zebra.tscn",
                "croc": "res://scenes/mobs/croc.tscn",
                "frog": "res://scenes/mobs/frog.tscn",
                "goat": "res://scenes/mobs/goat.tscn",
                "eagle": "res://scenes/mobs/eagle.tscn",
                "vulture": "res://scenes/mobs/vulture.tscn",
                "bandit": "res://scenes/mobs/bandit.tscn",
                "zombie": "res://scenes/mobs/zombie.tscn"
        }
        
        for key in paths:
                if ResourceLoader.exists(paths[key]):
                        mob_scenes[key] = load(paths[key])

func _find_player():
        var players = get_tree().get_nodes_in_group("players")
        if players.size() > 0:
                player_ref = players[0]

func _process(delta):
        if not player_ref:
                _find_player()
                return
        
        spawn_timer += delta
        if spawn_timer >= spawn_interval:
                spawn_timer = 0.0
                _try_spawn_mobs()
        
        _despawn_distant_mobs()
        _cleanup_dead_mobs()

func _try_spawn_mobs():
        if not world_gen:
                world_gen = get_node_or_null("/root/WorldGenerator")
                return
        
        if spawned_mobs.size() >= max_mobs:
                return
        
        var player_pos = player_ref.global_position
        var rng = RandomNumberGenerator.new()
        rng.randomize()
        
        var angle = rng.randf_range(0, TAU)
        var dist = rng.randf_range(min_spawn_distance, spawn_radius)
        var spawn_x = player_pos.x + cos(angle) * dist
        var spawn_z = player_pos.z + sin(angle) * dist
        
        var biome = world_gen.get_biome_at(spawn_x, spawn_z)
        
        if world_gen.is_water_biome(biome):
                return
        
        if not biome_spawn_tables.has(biome):
                biome = "plains"
        
        var spawn_table = biome_spawn_tables[biome]
        var mob_data = _weighted_random(spawn_table, rng)
        
        if not mob_data:
                return
        
        var pack_min = mob_data["pack_size"][0]
        var pack_max = mob_data["pack_size"][1]
        var pack_size = rng.randi_range(pack_min, pack_max)
        
        var height = world_gen.get_height_at(spawn_x, spawn_z)
        var base_pos = Vector3(spawn_x, height + 1.0, spawn_z)
        
        for i in range(pack_size):
                if spawned_mobs.size() >= max_mobs:
                        break
                
                var offset = Vector3(
                        rng.randf_range(-3.0, 3.0),
                        0,
                        rng.randf_range(-3.0, 3.0)
                )
                var mob_pos = base_pos + offset
                mob_pos.y = world_gen.get_height_at(mob_pos.x, mob_pos.z) + 1.0
                
                var mob = _create_mob(mob_data["type"], mob_pos, rng)
                if mob:
                        add_child(mob)
                        spawned_mobs.append(mob)
                        emit_signal("mob_spawned", mob, biome)

func _weighted_random(table: Array, rng: RandomNumberGenerator) -> Dictionary:
        var total_weight = 0
        for entry in table:
                total_weight += entry["weight"]
        
        var roll = rng.randi_range(0, total_weight - 1)
        var current = 0
        
        for entry in table:
                current += entry["weight"]
                if roll < current:
                        return entry
        
        return table[0] if table.size() > 0 else {}

func _create_mob(mob_type: String, pos: Vector3, rng: RandomNumberGenerator) -> Node3D:
        var mob: Node3D
        
        if mob_scenes.has(mob_type):
                mob = mob_scenes[mob_type].instantiate()
        else:
                mob = _create_procedural_mob(mob_type, rng)
        
        if mob:
                mob.position = pos
                mob.rotation.y = rng.randf_range(0, TAU)
                
                if mob_stats.has(mob_type):
                        var stats = mob_stats[mob_type]
                        if mob.has_method("set_stats"):
                                mob.set_stats(stats)
                        if mob.has_method("set_faction"):
                                mob.set_faction(stats.get("faction", "wild"))
                
                mob.add_to_group("mobs")
        
        return mob

func _create_procedural_mob(mob_type: String, rng: RandomNumberGenerator) -> Node3D:
        var mob = CharacterBody3D.new()
        mob.name = mob_type.capitalize()
        
        var stats = mob_stats.get(mob_type, {"hp": 30, "damage": 5, "speed": 4.0})
        
        var size = Vector3(0.8, 0.8, 1.2)
        var color = Color(0.5, 0.4, 0.35)
        
        match mob_type:
                "wolf":
                        size = Vector3(0.6, 0.7, 1.0)
                        color = Color(0.4, 0.4, 0.45)
                "bear":
                        size = Vector3(1.2, 1.4, 1.8)
                        color = Color(0.35, 0.25, 0.2)
                "boar":
                        size = Vector3(0.7, 0.6, 1.0)
                        color = Color(0.4, 0.35, 0.3)
                "deer":
                        size = Vector3(0.5, 1.0, 1.2)
                        color = Color(0.6, 0.45, 0.35)
                "rabbit":
                        size = Vector3(0.2, 0.25, 0.3)
                        color = Color(0.7, 0.65, 0.6)
                "spider":
                        size = Vector3(0.6, 0.4, 0.6)
                        color = Color(0.2, 0.2, 0.2)
                "snake":
                        size = Vector3(0.15, 0.15, 1.0)
                        color = Color(0.3, 0.4, 0.3)
                "scorpion":
                        size = Vector3(0.4, 0.2, 0.5)
                        color = Color(0.5, 0.4, 0.3)
                "lion":
                        size = Vector3(0.8, 0.9, 1.4)
                        color = Color(0.7, 0.55, 0.35)
                "hyena":
                        size = Vector3(0.6, 0.7, 1.0)
                        color = Color(0.5, 0.45, 0.4)
                "elephant":
                        size = Vector3(2.0, 2.5, 3.0)
                        color = Color(0.5, 0.5, 0.5)
                "zebra":
                        size = Vector3(0.6, 1.2, 1.4)
                        color = Color(0.9, 0.9, 0.9)
                "croc":
                        size = Vector3(0.5, 0.4, 2.0)
                        color = Color(0.3, 0.35, 0.25)
                "frog":
                        size = Vector3(0.2, 0.15, 0.2)
                        color = Color(0.3, 0.5, 0.3)
                "goat":
                        size = Vector3(0.5, 0.7, 0.9)
                        color = Color(0.6, 0.55, 0.5)
                "eagle", "vulture":
                        size = Vector3(0.4, 0.3, 0.5)
                        color = Color(0.35, 0.3, 0.25)
                "bandit":
                        size = Vector3(0.5, 1.7, 0.4)
                        color = Color(0.5, 0.35, 0.3)
                "zombie":
                        size = Vector3(0.5, 1.6, 0.4)
                        color = Color(0.4, 0.5, 0.35)
        
        var mesh_inst = MeshInstance3D.new()
        var box = BoxMesh.new()
        box.size = size
        mesh_inst.mesh = box
        mesh_inst.position.y = size.y * 0.5
        
        var mat = StandardMaterial3D.new()
        mat.albedo_color = color
        mesh_inst.material_override = mat
        
        mob.add_child(mesh_inst)
        
        var col = CollisionShape3D.new()
        var col_box = BoxShape3D.new()
        col_box.size = size
        col.shape = col_box
        col.position.y = size.y * 0.5
        mob.add_child(col)
        
        var ai_script_path = "res://scripts/ai/mob_ai.gd"
        if ResourceLoader.exists(ai_script_path):
                var ai_script = load(ai_script_path)
                mob.set_script(ai_script)
        
        return mob

func _despawn_distant_mobs():
        if not player_ref:
                return
        
        var player_pos = player_ref.global_position
        var to_despawn := []
        
        for mob in spawned_mobs:
                if not is_instance_valid(mob):
                        to_despawn.append(mob)
                        continue
                
                var dist = mob.global_position.distance_to(player_pos)
                if dist > despawn_radius:
                        to_despawn.append(mob)
        
        for mob in to_despawn:
                spawned_mobs.erase(mob)
                if is_instance_valid(mob):
                        emit_signal("mob_despawned", mob)
                        mob.queue_free()

func _cleanup_dead_mobs():
        var to_remove := []
        
        for mob in spawned_mobs:
                if not is_instance_valid(mob):
                        to_remove.append(mob)
                        continue
                
                if mob.has_method("is_dead") and mob.is_dead():
                        to_remove.append(mob)
        
        for mob in to_remove:
                spawned_mobs.erase(mob)

func get_mob_count() -> int:
        return spawned_mobs.size()

func get_mobs_in_radius(pos: Vector3, radius: float) -> Array:
        var result := []
        for mob in spawned_mobs:
                if is_instance_valid(mob):
                        if mob.global_position.distance_to(pos) <= radius:
                                result.append(mob)
        return result
