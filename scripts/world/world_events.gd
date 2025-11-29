extends Node

signal event_started(event_type: String, position: Vector3)
signal event_ended(event_type: String)

var world_gen
var player_ref: Node3D

var active_events := []
var event_cooldowns := {}

const EVENT_TYPES := {
        "bandit_raid": {
                "cooldown": 300.0,
                "duration": 120.0,
                "min_distance": 50.0,
                "max_distance": 150.0,
                "mob_count": [3, 8],
                "mob_type": "bandit"
        },
        "wolf_pack": {
                "cooldown": 180.0,
                "duration": 90.0,
                "min_distance": 40.0,
                "max_distance": 100.0,
                "mob_count": [4, 7],
                "mob_type": "wolf"
        },
        "animal_migration": {
                "cooldown": 240.0,
                "duration": 180.0,
                "min_distance": 60.0,
                "max_distance": 200.0,
                "mob_count": [8, 15],
                "mob_type": "deer"
        },
        "monster_spawn": {
                "cooldown": 400.0,
                "duration": 150.0,
                "min_distance": 70.0,
                "max_distance": 180.0,
                "mob_count": [2, 5],
                "mob_type": "zombie"
        },
        "trader_caravan": {
                "cooldown": 350.0,
                "duration": 200.0,
                "min_distance": 30.0,
                "max_distance": 80.0,
                "npc_count": [2, 4],
                "npc_type": "trader"
        }
}

var check_interval := 30.0
var check_timer := 0.0
var event_chance := 0.15

func _ready():
        call_deferred("_late_init")

func _late_init():
        world_gen = get_node_or_null("/root/WorldGenerator")
        _find_player()

func _find_player():
        var players = get_tree().get_nodes_in_group("players")
        if players.size() > 0:
                player_ref = players[0]

func _process(delta):
        if not player_ref:
                _find_player()
                return
        
        for event_type in event_cooldowns.keys():
                if event_cooldowns[event_type] > 0:
                        event_cooldowns[event_type] -= delta
        
        check_timer += delta
        if check_timer >= check_interval:
                check_timer = 0.0
                _try_trigger_random_event()
        
        _update_active_events(delta)

func _try_trigger_random_event():
        if randf() > event_chance:
                return
        
        var available_events := []
        for event_type in EVENT_TYPES.keys():
                if not event_cooldowns.has(event_type) or event_cooldowns[event_type] <= 0:
                        available_events.append(event_type)
        
        if available_events.size() == 0:
                return
        
        var chosen_event = available_events[randi() % available_events.size()]
        trigger_event(chosen_event)

func trigger_event(event_type: String):
        if not EVENT_TYPES.has(event_type):
                return
        
        var config = EVENT_TYPES[event_type]
        
        if not player_ref:
                return
        
        var player_pos = player_ref.global_position
        var angle = randf_range(0, TAU)
        var distance = randf_range(config["min_distance"], config["max_distance"])
        var event_pos = player_pos + Vector3(cos(angle) * distance, 0, sin(angle) * distance)
        
        if world_gen:
                var biome = world_gen.get_biome_at(event_pos.x, event_pos.z)
                if world_gen.is_water_biome(biome):
                        return
                event_pos.y = world_gen.get_height_at(event_pos.x, event_pos.z)
        
        var event_data = {
                "type": event_type,
                "config": config,
                "position": event_pos,
                "duration": config["duration"],
                "spawned_entities": []
        }
        
        _spawn_event_entities(event_data)
        
        active_events.append(event_data)
        event_cooldowns[event_type] = config["cooldown"]
        
        emit_signal("event_started", event_type, event_pos)
        _notify_player(event_type, event_pos)

func _spawn_event_entities(event_data: Dictionary):
        var config = event_data["config"]
        var pos = event_data["position"]
        var rng = RandomNumberGenerator.new()
        rng.randomize()
        
        var mob_spawner = get_node_or_null("/root/MobSpawner")
        
        if config.has("mob_count"):
                var count = rng.randi_range(config["mob_count"][0], config["mob_count"][1])
                var mob_type = config.get("mob_type", "wolf")
                
                for i in range(count):
                        var offset = Vector3(
                                rng.randf_range(-10.0, 10.0),
                                0,
                                rng.randf_range(-10.0, 10.0)
                        )
                        var spawn_pos = pos + offset
                        
                        if world_gen:
                                spawn_pos.y = world_gen.get_height_at(spawn_pos.x, spawn_pos.z) + 1.0
                        
                        var mob = _create_event_mob(mob_type, spawn_pos, rng)
                        if mob:
                                add_child(mob)
                                event_data["spawned_entities"].append(mob)
        
        if config.has("npc_count"):
                var count = rng.randi_range(config["npc_count"][0], config["npc_count"][1])
                var npc_type = config.get("npc_type", "trader")
                
                for i in range(count):
                        var offset = Vector3(
                                rng.randf_range(-5.0, 5.0),
                                0,
                                rng.randf_range(-5.0, 5.0)
                        )
                        var spawn_pos = pos + offset
                        
                        if world_gen:
                                spawn_pos.y = world_gen.get_height_at(spawn_pos.x, spawn_pos.z) + 1.0
                        
                        var npc = _create_event_npc(npc_type, spawn_pos, rng)
                        if npc:
                                add_child(npc)
                                event_data["spawned_entities"].append(npc)

func _create_event_mob(mob_type: String, pos: Vector3, rng: RandomNumberGenerator) -> Node3D:
        var scene_path = "res://scenes/mobs/%s.tscn" % mob_type
        if ResourceLoader.exists(scene_path):
                var scene = load(scene_path)
                var mob = scene.instantiate()
                mob.position = pos
                mob.rotation.y = rng.randf_range(0, TAU)
                mob.add_to_group("event_mobs")
                return mob
        
        var mob = CharacterBody3D.new()
        mob.name = mob_type.capitalize()
        mob.position = pos
        
        var mesh = MeshInstance3D.new()
        var box = BoxMesh.new()
        box.size = Vector3(0.8, 1.0, 1.2)
        mesh.mesh = box
        mesh.position.y = 0.5
        
        var mat = StandardMaterial3D.new()
        match mob_type:
                "bandit":
                        mat.albedo_color = Color(0.5, 0.3, 0.3)
                "wolf":
                        mat.albedo_color = Color(0.4, 0.4, 0.45)
                "zombie":
                        mat.albedo_color = Color(0.4, 0.5, 0.35)
                _:
                        mat.albedo_color = Color(0.5, 0.4, 0.35)
        
        mesh.material_override = mat
        mob.add_child(mesh)
        
        var col = CollisionShape3D.new()
        var col_box = BoxShape3D.new()
        col_box.size = box.size
        col.shape = col_box
        col.position.y = 0.5
        mob.add_child(col)
        
        mob.add_to_group("event_mobs")
        mob.add_to_group("mobs")
        
        return mob

func _create_event_npc(npc_type: String, pos: Vector3, rng: RandomNumberGenerator) -> Node3D:
        var scene_path = "res://scenes/npcs/npc_citizen.tscn"
        if ResourceLoader.exists(scene_path):
                var scene = load(scene_path)
                var npc = scene.instantiate()
                npc.position = pos
                if npc.has_method("set_role"):
                        npc.set_role(npc_type)
                npc.add_to_group("event_npcs")
                return npc
        
        var npc = CharacterBody3D.new()
        npc.name = npc_type.capitalize()
        npc.position = pos
        
        var mesh = MeshInstance3D.new()
        var capsule = CapsuleMesh.new()
        capsule.radius = 0.3
        capsule.height = 1.7
        mesh.mesh = capsule
        mesh.position.y = 0.85
        
        var mat = StandardMaterial3D.new()
        mat.albedo_color = Color(0.4, 0.5, 0.6)
        mesh.material_override = mat
        
        npc.add_child(mesh)
        
        var col = CollisionShape3D.new()
        var col_cap = CapsuleShape3D.new()
        col_cap.radius = 0.3
        col_cap.height = 1.7
        col.shape = col_cap
        col.position.y = 0.85
        npc.add_child(col)
        
        npc.add_to_group("event_npcs")
        npc.add_to_group("npcs")
        
        return npc

func _update_active_events(delta: float):
        var to_remove := []
        
        for event in active_events:
                event["duration"] -= delta
                
                var valid_entities := []
                for entity in event["spawned_entities"]:
                        if is_instance_valid(entity):
                                valid_entities.append(entity)
                event["spawned_entities"] = valid_entities
                
                if event["duration"] <= 0 or valid_entities.size() == 0:
                        to_remove.append(event)
        
        for event in to_remove:
                _end_event(event)

func _end_event(event: Dictionary):
        for entity in event["spawned_entities"]:
                if is_instance_valid(entity):
                        entity.queue_free()
        
        active_events.erase(event)
        emit_signal("event_ended", event["type"])

func _notify_player(event_type: String, pos: Vector3):
        var message := ""
        match event_type:
                "bandit_raid":
                        message = "Внимание! Бандиты замечены поблизости!"
                "wolf_pack":
                        message = "Волчья стая рыщет неподалёку..."
                "animal_migration":
                        message = "Стадо животных мигрирует через эту область."
                "monster_spawn":
                        message = "Странные существа появились в округе!"
                "trader_caravan":
                        message = "Торговый караван проходит мимо!"
        
        var hud = get_tree().get_first_node_in_group("hud")
        if hud and hud.has_method("show_notification"):
                hud.show_notification(message)

func get_active_events() -> Array:
        return active_events

func get_event_count() -> int:
        return active_events.size()

func force_trigger_event(event_type: String):
        event_cooldowns[event_type] = 0
        trigger_event(event_type)
