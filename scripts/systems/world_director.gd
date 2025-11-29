extends Node
class_name WorldDirector

signal global_event_started(event_type, data)
signal global_event_ended(event_type)
signal faction_war_started(faction_a, faction_b)
signal faction_war_ended(faction_a, faction_b)

@export var spawn_points := [Vector3(5, 0, 5), Vector3(-10, 0, 8), Vector3(20, 0, -15)]
@export var spawn_interval := 12.0
@export var event_check_interval := 60.0
@export var max_mobs_per_area := 10

var spawn_timer := 0.0
var event_timer := 0.0
var mob_count := 0
var active_events := {}
var faction_wars := []

enum GlobalEvent {
        NONE,
        MONSTER_INVASION,
        BANDIT_RAID,
        EPIDEMIC,
        HARSH_WINTER,
        DROUGHT,
        DIPLOMATIC_CONFLICT,
        MONSTER_MIGRATION
}

var event_data := {
        GlobalEvent.MONSTER_INVASION: {
                "name": "Нашествие монстров",
                "duration": 300.0,
                "spawn_mult": 3.0,
                "danger_level": 3
        },
        GlobalEvent.BANDIT_RAID: {
                "name": "Рейд бандитов",
                "duration": 180.0,
                "faction": "bandits",
                "danger_level": 2
        },
        GlobalEvent.EPIDEMIC: {
                "name": "Эпидемия",
                "duration": 600.0,
                "health_drain": 0.1,
                "danger_level": 2
        },
        GlobalEvent.HARSH_WINTER: {
                "name": "Суровая зима",
                "duration": 400.0,
                "temp_modifier": -20.0,
                "danger_level": 2
        },
        GlobalEvent.DROUGHT: {
                "name": "Засуха",
                "duration": 500.0,
                "thirst_mult": 2.0,
                "danger_level": 1
        },
        GlobalEvent.DIPLOMATIC_CONFLICT: {
                "name": "Дипломатический конфликт",
                "duration": 240.0,
                "danger_level": 1
        },
        GlobalEvent.MONSTER_MIGRATION: {
                "name": "Миграция монстров",
                "duration": 200.0,
                "spawn_mult": 2.0,
                "danger_level": 2
        }
}

func _is_server() -> bool:
        var mp = multiplayer
        if mp == null:
                return true
        if not mp.has_multiplayer_peer():
                return true
        return mp.is_server()

func _process(delta):
        if not _is_server():
                return
        
        spawn_timer += delta
        event_timer += delta
        
        if spawn_timer >= spawn_interval:
                spawn_timer = 0.0
                _process_spawns()
        
        if event_timer >= event_check_interval:
                event_timer = 0.0
                _check_global_events()
        
        _update_active_events(delta)
        _process_faction_relations(delta)

func _process_spawns():
        for p in spawn_points:
                var mobs_nearby = _count_mobs_near(p, 30.0)
                if mobs_nearby < max_mobs_per_area:
                        var spawn_mult = 1.0
                        for event in active_events.values():
                                if event.has("spawn_mult"):
                                        spawn_mult *= event.spawn_mult
                        
                        var count = int(1 * spawn_mult)
                        for i in range(count):
                                _spawn_mob(p + Vector3(randf_range(-5, 5), 0, randf_range(-5, 5)))

func _count_mobs_near(pos: Vector3, radius: float) -> int:
        var count = 0
        var mobs = get_tree().get_nodes_in_group("mobs")
        for mob in mobs:
                if is_instance_valid(mob) and mob.global_position.distance_to(pos) < radius:
                        count += 1
        return count

func _spawn_mob(pos: Vector3):
        var st = get_node_or_null("/root/SpawnTable")
        var biome = "plains"
        var bs = get_node_or_null("/root/BiomeSystem")
        if bs:
                var b = bs.get_biome_at(pos)
                biome = b.name if b.has("name") else biome
        
        var scene_path = st.pick_for_biome(biome) if st else ""
        if scene_path == "":
                scene_path = "res://scenes/mobs/mob_basic.tscn"
        
        var scene = ResourceLoader.load(scene_path)
        if not scene:
                return
        
        var inst = scene.instantiate()
        add_child(inst)
        inst.global_transform.origin = pos
        mob_count += 1

func _check_global_events():
        if active_events.size() >= 2:
                return
        
        var chance = randf()
        
        if chance < 0.05:
                start_event(GlobalEvent.MONSTER_INVASION)
        elif chance < 0.10:
                start_event(GlobalEvent.BANDIT_RAID)
        elif chance < 0.12:
                start_event(GlobalEvent.EPIDEMIC)
        elif chance < 0.15:
                start_event(GlobalEvent.MONSTER_MIGRATION)
        elif chance < 0.17:
                _check_faction_conflicts()

func start_event(event_type: int, custom_data := {}):
        if active_events.has(event_type):
                return
        
        var data = event_data.get(event_type, {}).duplicate()
        data.merge(custom_data)
        data["time_remaining"] = data.get("duration", 300.0)
        data["type"] = event_type
        
        active_events[event_type] = data
        emit_signal("global_event_started", event_type, data)
        
        _apply_event_effects(event_type, data)

func end_event(event_type: int):
        if not active_events.has(event_type):
                return
        
        var data = active_events[event_type]
        _remove_event_effects(event_type, data)
        active_events.erase(event_type)
        emit_signal("global_event_ended", event_type)

func _update_active_events(delta: float):
        var events_to_end = []
        
        for event_type in active_events.keys():
                var event = active_events[event_type]
                event.time_remaining -= delta
                
                _process_event_tick(event_type, event, delta)
                
                if event.time_remaining <= 0:
                        events_to_end.append(event_type)
        
        for event_type in events_to_end:
                end_event(event_type)

func _process_event_tick(event_type: int, event: Dictionary, delta: float):
        match event_type:
                GlobalEvent.EPIDEMIC:
                        var players = get_tree().get_nodes_in_group("players")
                        for player in players:
                                if player.has_method("apply_damage"):
                                        player.apply_damage(event.get("health_drain", 0.1) * delta, null)
                
                GlobalEvent.HARSH_WINTER:
                        var temp_sys = get_node_or_null("/root/TemperatureSystem")
                        if temp_sys and temp_sys.has_method("set_global_modifier"):
                                temp_sys.set_global_modifier(event.get("temp_modifier", -20.0))
                
                GlobalEvent.MONSTER_INVASION:
                        if randf() < 0.02:
                                var ss = get_node_or_null("/root/SettlementSystem")
                                if ss:
                                        var settlements = ss.get_all_settlements()
                                        if settlements.size() > 0:
                                                var target = settlements[randi() % settlements.size()]
                                                _spawn_invasion_wave(target.position)

func _spawn_invasion_wave(target_pos: Vector3):
        for i in range(randi_range(3, 6)):
                var offset = Vector3(randf_range(-15, 15), 0, randf_range(-15, 15))
                _spawn_mob(target_pos + offset)

func _apply_event_effects(event_type: int, data: Dictionary):
        match event_type:
                GlobalEvent.BANDIT_RAID:
                        var faction_sys = get_node_or_null("/root/FactionSystem")
                        if faction_sys:
                                faction_sys.modify_relation("player", "bandits", -30)

func _remove_event_effects(event_type: int, data: Dictionary):
        match event_type:
                GlobalEvent.HARSH_WINTER:
                        var temp_sys = get_node_or_null("/root/TemperatureSystem")
                        if temp_sys and temp_sys.has_method("set_global_modifier"):
                                temp_sys.set_global_modifier(0.0)

func _check_faction_conflicts():
        var faction_sys = get_node_or_null("/root/FactionSystem")
        var ss = get_node_or_null("/root/SettlementSystem")
        if not faction_sys or not ss:
                return
        
        var settlements = ss.get_all_settlements()
        if settlements.size() < 2:
                return
        
        var factions_with_settlements = {}
        for s in settlements:
                var faction = s.get("faction", "neutral")
                if not factions_with_settlements.has(faction):
                        factions_with_settlements[faction] = []
                factions_with_settlements[faction].append(s)
        
        var faction_list = factions_with_settlements.keys()
        if faction_list.size() < 2:
                return
        
        var f1 = faction_list[randi() % faction_list.size()]
        var f2 = faction_list[randi() % faction_list.size()]
        
        if f1 == f2 or f1 == "player" or f2 == "player":
                return
        
        var relation = faction_sys.get_relation(f1, f2)
        if relation < -50:
                _start_faction_war(f1, f2)

func _start_faction_war(faction_a: String, faction_b: String):
        if [faction_a, faction_b] in faction_wars:
                return
        
        faction_wars.append([faction_a, faction_b])
        emit_signal("faction_war_started", faction_a, faction_b)

func _process_faction_relations(delta: float):
        var faction_sys = get_node_or_null("/root/FactionSystem")
        if not faction_sys:
                return
        
        for war in faction_wars:
                if randf() < 0.001:
                        faction_sys.modify_relation(war[0], war[1], 1)
                        if faction_sys.get_relation(war[0], war[1]) > -25:
                                _end_faction_war(war[0], war[1])

func _end_faction_war(faction_a: String, faction_b: String):
        faction_wars.erase([faction_a, faction_b])
        faction_wars.erase([faction_b, faction_a])
        emit_signal("faction_war_ended", faction_a, faction_b)

func get_active_events() -> Array:
        return active_events.values()

func is_event_active(event_type: int) -> bool:
        return active_events.has(event_type)

func get_danger_level() -> int:
        var max_danger = 0
        for event in active_events.values():
                max_danger = max(max_danger, event.get("danger_level", 0))
        return max_danger
