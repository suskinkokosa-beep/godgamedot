extends Node

signal global_event_started(event_type, data)
signal global_event_ended(event_type)
signal faction_war_started(faction_a, faction_b)
signal faction_war_ended(faction_a, faction_b)
signal npc_spawned(npc, settlement_id)
signal caravan_spawned(from_id, to_id)
signal world_state_changed(state_type, data)

@export var spawn_points := [Vector3(5, 0, 5), Vector3(-10, 0, 8), Vector3(20, 0, -15)]
@export var spawn_interval := 12.0
@export var event_check_interval := 60.0
@export var max_mobs_per_area := 10
@export var npc_spawn_interval := 30.0
@export var economy_update_interval := 10.0
@export var world_tension := 0.0

var spawn_timer := 0.0
var event_timer := 0.0
var npc_timer := 0.0
var economy_timer := 0.0
var mob_count := 0
var active_events := {}
var faction_wars := []
var world_state := "peaceful"
var season := "spring"
var year := 1
var day := 1

enum GlobalEvent {
        NONE,
        MONSTER_INVASION,
        BANDIT_RAID,
        EPIDEMIC,
        HARSH_WINTER,
        DROUGHT,
        DIPLOMATIC_CONFLICT,
        MONSTER_MIGRATION,
        TRADE_BOOM,
        FAMINE,
        REBELLION,
        FESTIVAL,
        ECLIPSE,
        BLOOD_MOON,
        DRAGON_SIGHTING
}

var event_data := {
        GlobalEvent.MONSTER_INVASION: {
                "name": "Нашествие монстров",
                "name_ru": "Нашествие монстров",
                "duration": 300.0,
                "spawn_mult": 3.0,
                "danger_level": 3,
                "tension_add": 30
        },
        GlobalEvent.BANDIT_RAID: {
                "name": "Рейд бандитов",
                "name_ru": "Рейд бандитов",
                "duration": 180.0,
                "faction": "bandits",
                "danger_level": 2,
                "tension_add": 20
        },
        GlobalEvent.EPIDEMIC: {
                "name": "Эпидемия",
                "name_ru": "Эпидемия",
                "duration": 600.0,
                "health_drain": 0.1,
                "danger_level": 2,
                "tension_add": 15
        },
        GlobalEvent.HARSH_WINTER: {
                "name": "Суровая зима",
                "name_ru": "Суровая зима",
                "duration": 400.0,
                "temp_modifier": -20.0,
                "danger_level": 2,
                "tension_add": 10
        },
        GlobalEvent.DROUGHT: {
                "name": "Засуха",
                "name_ru": "Засуха",
                "duration": 500.0,
                "thirst_mult": 2.0,
                "danger_level": 1,
                "tension_add": 10
        },
        GlobalEvent.DIPLOMATIC_CONFLICT: {
                "name": "Дипломатический конфликт",
                "name_ru": "Дипломатический конфликт",
                "duration": 240.0,
                "danger_level": 1,
                "tension_add": 15
        },
        GlobalEvent.MONSTER_MIGRATION: {
                "name": "Миграция монстров",
                "name_ru": "Миграция монстров",
                "duration": 200.0,
                "spawn_mult": 2.0,
                "danger_level": 2,
                "tension_add": 15
        },
        GlobalEvent.TRADE_BOOM: {
                "name": "Торговый бум",
                "name_ru": "Торговый бум",
                "duration": 400.0,
                "trade_mult": 2.0,
                "danger_level": 0,
                "tension_add": -10
        },
        GlobalEvent.FAMINE: {
                "name": "Голод",
                "name_ru": "Голод",
                "duration": 500.0,
                "hunger_mult": 2.5,
                "food_production": 0.3,
                "danger_level": 2,
                "tension_add": 25
        },
        GlobalEvent.REBELLION: {
                "name": "Восстание",
                "name_ru": "Восстание",
                "duration": 300.0,
                "danger_level": 3,
                "tension_add": 40
        },
        GlobalEvent.FESTIVAL: {
                "name": "Праздник",
                "name_ru": "Праздник",
                "duration": 120.0,
                "happiness_bonus": 20,
                "danger_level": 0,
                "tension_add": -20
        },
        GlobalEvent.ECLIPSE: {
                "name": "Затмение",
                "name_ru": "Затмение",
                "duration": 60.0,
                "magic_mult": 2.0,
                "danger_level": 1,
                "tension_add": 5
        },
        GlobalEvent.BLOOD_MOON: {
                "name": "Кровавая луна",
                "name_ru": "Кровавая луна",
                "duration": 180.0,
                "spawn_mult": 4.0,
                "mob_strength": 1.5,
                "danger_level": 4,
                "tension_add": 50
        },
        GlobalEvent.DRAGON_SIGHTING: {
                "name": "Появление дракона",
                "name_ru": "Появление дракона",
                "duration": 600.0,
                "danger_level": 5,
                "tension_add": 60
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
        npc_timer += delta
        economy_timer += delta
        
        if spawn_timer >= spawn_interval:
                spawn_timer = 0.0
                _process_spawns()
        
        if event_timer >= event_check_interval:
                event_timer = 0.0
                _check_global_events()
        
        if npc_timer >= npc_spawn_interval:
                npc_timer = 0.0
                _manage_npc_population()
        
        if economy_timer >= economy_update_interval:
                economy_timer = 0.0
                _update_economy()
        
        _update_active_events(delta)
        _process_faction_relations(delta)
        _update_world_tension(delta)
        _process_seasons(delta)

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

func _manage_npc_population():
        var ss = get_node_or_null("/root/SettlementSystem")
        if not ss:
                return
        
        var settlements = ss.get_all_settlements()
        
        for settlement in settlements:
                var current_npcs = _count_npcs_in_settlement(settlement.id)
                var target_npcs = settlement.population
                
                if current_npcs < target_npcs:
                        _spawn_npc_for_settlement(settlement)
                
                _assign_npc_jobs(settlement)

func _count_npcs_in_settlement(settlement_id: int) -> int:
        var count = 0
        var npcs = get_tree().get_nodes_in_group("npcs")
        for npc in npcs:
                if npc.has_node("NPCAIBrain"):
                        var brain = npc.get_node("NPCAIBrain")
                        if brain.home_settlement_id == settlement_id:
                                count += 1
        return count

func _spawn_npc_for_settlement(settlement: Dictionary):
        var npc_scene = load("res://scenes/npcs/npc_citizen.tscn")
        if not npc_scene:
                return
        
        var npc = npc_scene.instantiate()
        var spawn_pos = settlement.position + Vector3(randf_range(-10, 10), 0, randf_range(-10, 10))
        
        add_child(npc)
        npc.global_position = spawn_pos
        
        if npc.has_node("NPCAIBrain"):
                var brain = npc.get_node("NPCAIBrain")
                brain.home_settlement_id = settlement.id
                brain.faction = settlement.faction
                brain.profession = _choose_profession_for_settlement(settlement)
        
        emit_signal("npc_spawned", npc, settlement.id)

func _choose_profession_for_settlement(settlement: Dictionary) -> int:
        var breakdown = settlement.get("population_breakdown", {})
        var guards = breakdown.get("guard", 0)
        var workers = breakdown.get("worker", 0)
        var traders = breakdown.get("trader", 0)
        
        var total = guards + workers + traders
        if total == 0:
                return 7
        
        var guard_ratio = float(guards) / total
        var trader_ratio = float(traders) / total
        
        if guard_ratio < 0.2:
                return 1
        elif trader_ratio < 0.1:
                return 2
        else:
                return 7

func _assign_npc_jobs(settlement: Dictionary):
        var npcs = get_tree().get_nodes_in_group("npcs")
        
        for npc in npcs:
                if not npc.has_node("NPCAIBrain"):
                        continue
                
                var brain = npc.get_node("NPCAIBrain")
                if brain.home_settlement_id != settlement.id:
                        continue
                
                if brain.work_position == Vector3.ZERO:
                        brain.work_position = settlement.position + Vector3(randf_range(-15, 15), 0, randf_range(-15, 15))

func _update_economy():
        var trade_sys = get_node_or_null("/root/TradeSystem")
        var ss = get_node_or_null("/root/SettlementSystem")
        
        if not trade_sys or not ss:
                return
        
        var routes = trade_sys.get_all_routes()
        for route in routes:
                if route.active:
                        var time_since_trade = Time.get_unix_time_from_system() - route.last_trade_time
                        if time_since_trade > route.trade_interval:
                                trade_sys.dispatch_caravan(route.id)
        
        var settlements = ss.get_all_settlements()
        for s in settlements:
                _update_settlement_economy(s)

func _update_settlement_economy(settlement: Dictionary):
        var law_sys = get_node_or_null("/root/LawSystem")
        if not law_sys:
                return
        
        var effects = law_sys.get_total_law_effects(settlement.id)
        
        var income = settlement.population * 2 * effects.get("income_mult", 1.0)
        if not settlement.resources.has("gold"):
                settlement.resources.gold = 0
        settlement.resources.gold += int(income)
        
        var production_mult = effects.get("production_mult", 1.0)
        settlement.production_rate = production_mult

func _update_world_tension(delta):
        world_tension = max(0, world_tension - delta * 0.1)
        
        if world_tension > 75:
                world_state = "war"
        elif world_tension > 50:
                world_state = "conflict"
        elif world_tension > 25:
                world_state = "unrest"
        else:
                world_state = "peaceful"
        
        if world_tension > 80 and randf() < 0.001:
                start_event(GlobalEvent.REBELLION)

func _process_seasons(delta):
        var dnc = get_node_or_null("/root/DayNightCycle")
        if not dnc:
                return
        
        var days_passed = 0
        if "days_passed" in dnc:
                days_passed = dnc.days_passed
        day = (days_passed % 30) + 1
        var season_num = (days_passed / 30) % 4
        
        match season_num:
                0: season = "spring"
                1: season = "summer"
                2: season = "autumn"
                3: season = "winter"
        
        year = (days_passed / 120) + 1
        
        if season == "winter" and randf() < 0.01:
                if not is_event_active(GlobalEvent.HARSH_WINTER):
                        start_event(GlobalEvent.HARSH_WINTER)

func spawn_trade_caravan(from_settlement_id: int, to_settlement_id: int):
        var ss = get_node_or_null("/root/SettlementSystem")
        if not ss:
                return
        
        var from_s = ss.get_settlement(from_settlement_id)
        var to_s = ss.get_settlement(to_settlement_id)
        
        if not from_s or not to_s:
                return
        
        emit_signal("caravan_spawned", from_settlement_id, to_settlement_id)

func trigger_war_between(faction_a: String, faction_b: String, reason: String = "territory"):
        var war_sys = get_node_or_null("/root/WarSystem")
        if war_sys:
                war_sys.declare_war(faction_a, faction_b, reason)
                world_tension += 30

func get_world_state() -> Dictionary:
        return {
                "state": world_state,
                "tension": world_tension,
                "season": season,
                "year": year,
                "day": day,
                "active_events": active_events.size(),
                "faction_wars": faction_wars.size()
        }

func get_season() -> String:
        return season

func get_year() -> int:
        return year

func get_day() -> int:
        return day

func _generate_event_quest(event_type: GlobalEvent):
        var quest_sys = get_node_or_null("/root/QuestSystem")
        if not quest_sys:
                return
        
        var event_map := {
                GlobalEvent.BLOOD_MOON: "blood_moon",
                GlobalEvent.MONSTER_INVASION: "invasion",
                GlobalEvent.DRAGON_SIGHTING: "rare_spawn",
                GlobalEvent.ECLIPSE: "meteor_shower"
        }
        
        if event_map.has(event_type):
                quest_sys.generate_event_quest(event_map[event_type])

func generate_biome_quests_for_player(player_id: int, player_position: Vector3):
        var quest_sys = get_node_or_null("/root/QuestSystem")
        var world_gen = get_node_or_null("/root/WorldGenerator")
        
        if not quest_sys or not world_gen:
                return
        
        var biome = world_gen.get_biome_at(player_position.x, player_position.z)
        var difficulty = _calculate_area_difficulty(player_position)
        
        quest_sys.generate_biome_quest(player_id, biome, difficulty)

func generate_faction_quest_for_player(player_id: int, faction: String):
        var quest_sys = get_node_or_null("/root/QuestSystem")
        var faction_sys = get_node_or_null("/root/FactionSystem")
        
        if not quest_sys or not faction_sys:
                return
        
        var reputation = faction_sys.get_player_reputation(player_id, faction)
        quest_sys.generate_faction_quest(player_id, faction, reputation)

func _calculate_area_difficulty(position: Vector3) -> int:
        var world_gen = get_node_or_null("/root/WorldGenerator")
        if not world_gen:
                return 1
        
        var distance_from_spawn = position.length()
        var base_difficulty = int(distance_from_spawn / 100) + 1
        
        if world_state == "war":
                base_difficulty += 2
        elif world_state == "conflict":
                base_difficulty += 1
        
        return clamp(base_difficulty, 1, 5)

func trigger_random_world_event():
        var possible_events := [
                GlobalEvent.TRADE_BOOM,
                GlobalEvent.MONSTER_MIGRATION,
                GlobalEvent.FESTIVAL,
                GlobalEvent.DIPLOMATIC_CONFLICT
        ]
        
        if world_tension > 30:
                possible_events.append(GlobalEvent.BANDIT_RAID)
        if world_tension > 50:
                possible_events.append(GlobalEvent.MONSTER_INVASION)
        if world_tension > 70:
                possible_events.append(GlobalEvent.REBELLION)
        
        if season == "winter":
                possible_events.append(GlobalEvent.HARSH_WINTER)
        if season == "summer":
                possible_events.append(GlobalEvent.DROUGHT)
        
        if randf() < 0.05:
                possible_events.append(GlobalEvent.BLOOD_MOON)
        if randf() < 0.02:
                possible_events.append(GlobalEvent.DRAGON_SIGHTING)
        if randf() < 0.03:
                possible_events.append(GlobalEvent.ECLIPSE)
        
        var selected_event = possible_events[randi() % possible_events.size()]
        start_event(selected_event)
        
        _generate_event_quest(selected_event)

func get_active_event_info() -> Array:
        var result := []
        for event_type in active_events.keys():
                var info = event_data.get(event_type, {})
                result.append({
                        "type": event_type,
                        "name": info.get("name_ru", "Событие"),
                        "danger_level": info.get("danger_level", 1),
                        "time_remaining": active_events[event_type].get("duration", 0)
                })
        return result

func notify_player_entered_biome(player_id: int, biome: String, position: Vector3):
        if randf() < 0.3:
                generate_biome_quests_for_player(player_id, position)
