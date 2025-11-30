extends CharacterBody3D
class_name MobAI

@export var patrol_radius := 10.0
@export var agro_range := 15.0
@export var attack_range := 2.5
@export var hearing_range := 25.0
@export var speed := 3.5
@export var run_speed := 5.5
@export var max_health := 50
@export var damage := 10
@export var attack_cooldown := 1.5
@export var xp_reward := 25.0
@export var faction := "wild"
@export var mob_type := "mob_basic"
@export var mob_name := ""
@export var loot_table := "mob_basic"
@export var is_pack_animal := false
@export var pack_call_range := 20.0
@export var can_migrate := false

@export_enum("passive", "neutral", "aggressive", "territorial", "predator") var behavior_type := "neutral"
@export var territorial_radius := 15.0
@export var vision_angle := 120.0

var health: float
var target: Node3D = null
var start_pos := Vector3.ZERO
var state := "idle"
var net_id := -1
var attack_timer := 0.0
var idle_timer := 0.0
var wander_target := Vector3.ZERO
var flee_health_threshold := 0.2
var is_fleeing := false

var pack_leader: Node3D = null
var pack_members: Array = []
var is_pack_leader := false
var migration_target := Vector3.ZERO
var is_migrating := false
var migration_timer := 0.0

var alert_level := 0.0
var last_heard_position := Vector3.ZERO
var investigation_timer := 0.0
var suspicion_decay_rate := 0.5
var aggression_mult := 1.0

var patrol_points: Array = []
var current_patrol_index := 0
var patrol_wait_timer := 0.0
var patrol_wait_time := 2.0

var time_of_day_modifier := 1.0
var is_nocturnal := false
var sleeping := false
var sleep_start_hour := 20.0
var sleep_end_hour := 6.0

var last_damage_time := 0.0
var damage_sources: Array = []

signal died(mob, killer)
signal damaged(mob, amount, source)
signal pack_alert(position, target)
signal sound_heard(position, loudness)

func _ready():
        health = max_health
        start_pos = global_position
        wander_target = start_pos
        add_to_group("mobs")
        add_to_group("entities")
        add_to_group("sound_listeners")
        
        _setup_behavior_modifiers()
        _generate_patrol_points()
        _generate_mob_name()
        _update_name_label()
        
        var net = get_node_or_null("/root/Network")
        if net and net.is_server:
                net.register_entity_server(self)
        
        var faction_sys = get_node_or_null("/root/FactionSystem")
        if faction_sys:
                faction_sys.register_entity(self, faction)

func _generate_mob_name():
        if mob_name != "":
                return
        
        var gm = get_node_or_null("/root/GameManager")
        var lang = "ru"
        if gm:
                lang = gm.get_language()
        
        var names_ru := {
                "wolf": ["Серый Клык", "Лютый", "Вожак", "Тень", "Хищник", "Волчара", "Бродяга", "Одинокий"],
                "bear": ["Бурый", "Косолапый", "Гризли", "Топтыгин", "Михаил", "Шатун", "Берлог", "Медведко"],
                "boar": ["Клык", "Секач", "Дикарь", "Рыжий", "Клыкастый", "Хряк", "Вепрь", "Пятак"],
                "deer": ["Рогач", "Быстроног", "Лесной", "Олень", "Благородный", "Пугливый", "Златорог", "Бегун"],
                "rabbit": ["Ушастик", "Пушок", "Зайка", "Шустрик", "Серенький", "Косой", "Попрыгун", "Трусишка"],
                "spider": ["Паучок", "Восьминог", "Ткач", "Ядовитый", "Тень", "Хищник", "Охотник", "Чёрный"],
                "snake": ["Шипящий", "Ползун", "Гадюка", "Клык", "Ядовитый", "Скользкий", "Хитрый"],
                "scorpion": ["Жало", "Клешня", "Пустынник", "Ядовитый", "Охотник", "Ночной"],
                "mob_basic": ["Тварь", "Существо", "Зверь", "Монстр", "Создание", "Порождение"]
        }
        
        var names_en := {
                "wolf": ["Gray Fang", "Fierce", "Alpha", "Shadow", "Hunter", "Lone Wolf", "Wanderer", "Stalker"],
                "bear": ["Brown", "Grizzly", "Big Paw", "Thunderclaw", "Bruiser", "Forest King", "Ursus", "Kodiak"],
                "boar": ["Tusker", "Razorback", "Wild One", "Bristle", "Charger", "Gore", "Savage", "Snout"],
                "deer": ["Antler", "Swiftfoot", "Forest", "Stag", "Noble", "Fleet", "Golden Horn", "Runner"],
                "rabbit": ["Flopsy", "Fluffy", "Cotton", "Speedy", "Lucky", "Thumper", "Hopper", "Nibbles"],
                "spider": ["Spinner", "Eight-legs", "Weaver", "Venomous", "Shadow", "Hunter", "Stalker", "Black"],
                "snake": ["Hisser", "Slither", "Viper", "Fang", "Venom", "Slinky", "Cunning"],
                "scorpion": ["Stinger", "Pincher", "Desert", "Venomous", "Hunter", "Nightcrawler"],
                "mob_basic": ["Creature", "Beast", "Monster", "Spawn", "Fiend", "Abomination"]
        }
        
        var type_key = mob_type if mob_type in names_ru else "mob_basic"
        var name_pool = names_ru[type_key] if lang == "ru" else names_en.get(type_key, names_en["mob_basic"])
        
        mob_name = name_pool[randi() % name_pool.size()]

func _update_name_label():
        var label = get_node_or_null("NameLabel")
        if label and label is Label3D:
                label.text = mob_name
                
                match behavior_type:
                        "aggressive", "predator":
                                label.modulate = Color(1.0, 0.3, 0.3)
                        "neutral":
                                label.modulate = Color(1.0, 0.8, 0.3)
                        "passive":
                                label.modulate = Color(0.5, 1.0, 0.5)
                        _:
                                label.modulate = Color(1.0, 1.0, 1.0)

func get_display_name() -> String:
        return mob_name if mob_name != "" else mob_type

func _setup_behavior_modifiers():
        match behavior_type:
                "passive":
                        flee_health_threshold = 0.8
                        aggression_mult = 0.0
                "neutral":
                        flee_health_threshold = 0.3
                        aggression_mult = 0.5
                "aggressive":
                        flee_health_threshold = 0.15
                        aggression_mult = 1.5
                        agro_range *= 1.3
                "territorial":
                        flee_health_threshold = 0.2
                        aggression_mult = 1.0
                "predator":
                        flee_health_threshold = 0.1
                        aggression_mult = 2.0
                        agro_range *= 1.5
                        hearing_range *= 1.2

func _generate_patrol_points():
        patrol_points.clear()
        var num_points = randi_range(3, 6)
        
        for i in range(num_points):
                var angle = (float(i) / float(num_points)) * TAU + randf() * 0.5
                var dist = randf_range(patrol_radius * 0.4, patrol_radius)
                var point = start_pos + Vector3(cos(angle) * dist, 0, sin(angle) * dist)
                patrol_points.append(point)

func _physics_process(delta):
        var net = get_node_or_null("/root/Network")
        if net and not net.is_server:
                return
        
        _update_time_of_day_behavior()
        
        if sleeping:
                _process_sleeping(delta)
                return
        
        attack_timer = max(0, attack_timer - delta)
        alert_level = max(0, alert_level - suspicion_decay_rate * delta)
        
        if is_migrating:
                if _process_migration(delta):
                        move_and_slide()
                        return
        
        if is_pack_animal and pack_leader == null and not is_pack_leader:
                if randf() < 0.01:
                        _try_form_pack()
        
        if pack_leader != null and state == "idle":
                _follow_pack_leader(delta)
                move_and_slide()
                return
        
        match state:
                "idle":
                        _process_idle(delta)
                "patrol":
                        _process_patrol(delta)
                "investigate":
                        _process_investigate(delta)
                "chase":
                        _process_chase(delta)
                        if is_pack_animal and target:
                                alert_pack(target)
                "attack":
                        _process_attack(delta)
                "flee":
                        _process_flee(delta)
                "return_home":
                        _process_return_home(delta)
        
        move_and_slide()

func _update_time_of_day_behavior():
        var day_night = get_node_or_null("/root/DayNightCycle")
        if not day_night:
                return
        
        var hour = 12.0
        if day_night.has_method("get_current_hour"):
                hour = day_night.get_current_hour()
        elif day_night.has_method("get_time_of_day"):
                hour = day_night.get_time_of_day() * 24.0
        
        var is_night_time = hour >= sleep_start_hour or hour < sleep_end_hour
        
        if is_nocturnal:
                if not is_night_time and state == "idle":
                        sleeping = true
                time_of_day_modifier = 1.5 if is_night_time else 0.5
        else:
                if is_night_time and state == "idle" and randf() < 0.01:
                        sleeping = true
                time_of_day_modifier = 0.7 if is_night_time else 1.0

func _process_sleeping(delta):
        velocity = Vector3.ZERO
        
        var day_night = get_node_or_null("/root/DayNightCycle")
        if day_night:
                var hour = 12.0
                if day_night.has_method("get_current_hour"):
                        hour = day_night.get_current_hour()
                elif day_night.has_method("get_time_of_day"):
                        hour = day_night.get_time_of_day() * 24.0
                
                var is_night_time = hour >= sleep_start_hour or hour < sleep_end_hour
                
                if is_nocturnal:
                        if is_night_time:
                                sleeping = false
                else:
                        if not is_night_time:
                                sleeping = false
        
        if alert_level > 50:
                sleeping = false
                state = "investigate"

func _process_idle(delta):
        idle_timer += delta
        
        var found_target = _find_target()
        if found_target:
                target = found_target
                state = "chase"
                return
        
        if alert_level > 30:
                state = "investigate"
                return
        
        if idle_timer > randf_range(3.0, 6.0) * time_of_day_modifier:
                idle_timer = 0.0
                state = "patrol"
                if patrol_points.size() > 0:
                        current_patrol_index = (current_patrol_index + 1) % patrol_points.size()
                        wander_target = patrol_points[current_patrol_index]
                else:
                        _pick_wander_target()

func _process_patrol(delta):
        var found_target = _find_target()
        if found_target:
                target = found_target
                state = "chase"
                return
        
        if alert_level > 30:
                state = "investigate"
                return
        
        var dist_to_target = global_position.distance_to(wander_target)
        
        if dist_to_target < 1.5:
                patrol_wait_timer += delta
                velocity = velocity.lerp(Vector3.ZERO, 5.0 * delta)
                
                if patrol_wait_timer >= patrol_wait_time:
                        patrol_wait_timer = 0.0
                        state = "idle"
                return
        
        var dir = (wander_target - global_position).normalized()
        dir.y = 0
        velocity = dir * speed * time_of_day_modifier
        
        _face_direction(dir, delta)

func _process_investigate(delta):
        investigation_timer += delta
        
        if investigation_timer > 10.0:
                investigation_timer = 0.0
                alert_level = 0
                state = "return_home"
                return
        
        var found_target = _find_target()
        if found_target:
                target = found_target
                state = "chase"
                investigation_timer = 0.0
                return
        
        if last_heard_position != Vector3.ZERO:
                var dist = global_position.distance_to(last_heard_position)
                
                if dist < 2.0:
                        velocity = velocity.lerp(Vector3.ZERO, 5.0 * delta)
                        
                        var look_timer = fmod(investigation_timer, 2.0)
                        if look_timer < 0.5:
                                rotation.y += delta * 2.0
                else:
                        var dir = (last_heard_position - global_position).normalized()
                        dir.y = 0
                        velocity = dir * speed * 0.7
                        _face_direction(dir, delta)

func _process_chase(delta):
        if not is_instance_valid(target):
                target = null
                state = "return_home"
                return
        
        var dist = global_position.distance_to(target.global_position)
        
        if behavior_type == "territorial":
                var dist_from_home = global_position.distance_to(start_pos)
                if dist_from_home > territorial_radius * 2:
                        target = null
                        state = "return_home"
                        return
        
        if dist > agro_range * 1.5:
                target = null
                state = "return_home"
                return
        
        if is_fleeing:
                state = "flee"
                return
        
        if dist <= attack_range:
                state = "attack"
                velocity = Vector3.ZERO
                return
        
        var dir = (target.global_position - global_position).normalized()
        dir.y = 0
        velocity = dir * run_speed * aggression_mult
        
        _face_direction(dir, delta)

func _process_attack(delta):
        if not is_instance_valid(target):
                target = null
                state = "idle"
                return
        
        var dist = global_position.distance_to(target.global_position)
        
        if dist > attack_range * 1.3:
                state = "chase"
                return
        
        _face_direction((target.global_position - global_position).normalized(), delta)
        
        if attack_timer <= 0:
                _perform_attack()
                attack_timer = attack_cooldown / aggression_mult

func _process_flee(delta):
        if not is_instance_valid(target):
                is_fleeing = false
                state = "return_home"
                return
        
        var flee_dir = (global_position - target.global_position).normalized()
        flee_dir.y = 0
        velocity = flee_dir * run_speed * 1.2
        
        _face_direction(flee_dir, delta)
        
        if global_position.distance_to(target.global_position) > agro_range * 2:
                is_fleeing = false
                target = null
                state = "return_home"

func _process_return_home(delta):
        var dist = global_position.distance_to(start_pos)
        
        if dist < 3.0:
                state = "idle"
                return
        
        var dir = (start_pos - global_position).normalized()
        dir.y = 0
        velocity = dir * speed
        
        _face_direction(dir, delta)

func _face_direction(dir: Vector3, delta: float):
        if dir.length() > 0.1:
                var target_angle = atan2(dir.x, dir.z)
                rotation.y = lerp_angle(rotation.y, target_angle, 5.0 * delta)

func _find_target() -> Node3D:
        if behavior_type == "passive":
                return null
        
        var players = get_tree().get_nodes_in_group("players")
        var closest: Node3D = null
        var closest_dist := agro_range * time_of_day_modifier
        
        for player in players:
                if not is_instance_valid(player):
                        continue
                
                var dist = global_position.distance_to(player.global_position)
                
                if dist >= closest_dist:
                        continue
                
                if not _can_see_target(player):
                        continue
                
                var faction_sys = get_node_or_null("/root/FactionSystem")
                if faction_sys:
                        var rel = faction_sys.get_relation(faction, "player")
                        
                        match behavior_type:
                                "neutral":
                                        if rel >= 0 and player not in damage_sources:
                                                continue
                                "territorial":
                                        var in_territory = global_position.distance_to(start_pos) < territorial_radius
                                        if not in_territory and rel >= 0:
                                                continue
                                "aggressive", "predator":
                                        pass
                
                closest = player
                closest_dist = dist
        
        return closest

func _can_see_target(target_node: Node3D) -> bool:
        var to_target = (target_node.global_position - global_position).normalized()
        var forward = -transform.basis.z
        forward.y = 0
        forward = forward.normalized()
        to_target.y = 0
        to_target = to_target.normalized()
        
        if forward.length() < 0.01 or to_target.length() < 0.01:
                return true
        
        var angle = rad_to_deg(forward.angle_to(to_target))
        if angle > vision_angle / 2.0:
                return false
        
        var space_state = get_world_3d().direct_space_state
        if not space_state:
                return true
        
        var query = PhysicsRayQueryParameters3D.create(
                global_position + Vector3.UP * 0.5,
                target_node.global_position + Vector3.UP * 0.5
        )
        query.exclude = [self]
        
        var result = space_state.intersect_ray(query)
        if result and result.collider != target_node:
                return false
        
        return true

func _pick_wander_target():
        var angle = randf() * TAU
        var dist = randf_range(patrol_radius * 0.3, patrol_radius)
        wander_target = start_pos + Vector3(cos(angle) * dist, 0, sin(angle) * dist)

func _perform_attack():
        if not is_instance_valid(target):
                return
        
        var actual_damage = damage * aggression_mult
        
        if target.has_method("take_damage"):
                target.take_damage(actual_damage, self)
        elif target.has_method("apply_damage"):
                target.apply_damage(actual_damage, self)
        
        var audio = get_node_or_null("/root/AudioManager")
        if audio and audio.has_method("play_mob_attack"):
                audio.play_mob_attack(mob_type, global_position)

func on_sound_heard(sound_position: Vector3, loudness: float):
        var dist = global_position.distance_to(sound_position)
        
        if dist > hearing_range:
                return
        
        if sleeping:
                var wake_chance = (loudness / 100.0) * (1.0 - dist / hearing_range)
                if randf() < wake_chance:
                        sleeping = false
        
        var alert_increase = loudness * (1.0 - dist / hearing_range) * 0.5
        alert_level = min(100, alert_level + alert_increase)
        last_heard_position = sound_position
        
        emit_signal("sound_heard", sound_position, loudness)
        
        if alert_level > 50 and state == "idle":
                state = "investigate"
                investigation_timer = 0.0

func take_damage(amount: float, source: Node = null):
        apply_damage(amount, source)

func apply_damage(amount: float, source: Node = null):
        var net = get_node_or_null("/root/Network")
        if net and not net.is_server:
                return
        
        health -= amount
        last_damage_time = Time.get_ticks_msec() / 1000.0
        
        if source and is_instance_valid(source):
                if source not in damage_sources:
                        damage_sources.append(source)
                target = source
                state = "chase"
                alert_level = 100
                sleeping = false
        
        emit_signal("damaged", self, amount, source)
        
        var vfx = get_node_or_null("/root/VFXManager")
        if vfx and vfx.has_method("spawn_damage_number"):
                vfx.spawn_damage_number(global_position + Vector3.UP, int(amount))
        
        if float(health) / float(max_health) < flee_health_threshold:
                is_fleeing = true
                state = "flee"
        
        if health <= 0:
                die(source)

func die(killer: Node = null):
        var quest_sys = get_node_or_null("/root/QuestSystem")
        if quest_sys and killer:
                var killer_id = killer.get("net_id") if killer.get("net_id") else 1
                quest_sys.update_objective(killer_id, "kill", mob_type, 1)
        
        var prog = get_node_or_null("/root/PlayerProgression")
        if prog and killer:
                var killer_id = killer.get("net_id") if killer.get("net_id") else 1
                prog.add_xp(killer_id, xp_reward)
                prog.add_skill_xp(killer_id, "combat", xp_reward * 0.5)
        
        var faction_sys = get_node_or_null("/root/FactionSystem")
        if faction_sys:
                faction_sys.unregister_entity(self, faction)
        
        leave_pack()
        _drop_loot()
        
        var vfx = get_node_or_null("/root/VFXManager")
        if vfx and vfx.has_method("spawn_death_effect"):
                vfx.spawn_death_effect(global_position)
        
        emit_signal("died", self, killer)
        queue_free()

func _drop_loot():
        var loot_sys = get_node_or_null("/root/LootSystem")
        if loot_sys:
                var luck = 0.0
                if target and target.has_method("get_luck_bonus"):
                        luck = target.get_luck_bonus()
                loot_sys.drop_loot_at(loot_table, global_position, luck)
        else:
                var inv = get_node_or_null("/root/Inventory")
                if not inv:
                        return
                
                match mob_type:
                        "wolf", "bear", "boar":
                                if randf() < 0.7:
                                        inv.add_item("meat", randi_range(2, 4), 1.0)
                                if randf() < 0.5:
                                        inv.add_item("hide", randi_range(1, 3), 1.0)
                                if randf() < 0.2:
                                        inv.add_item("bone", randi_range(1, 2), 1.0)
                        "deer", "rabbit":
                                if randf() < 0.8:
                                        inv.add_item("meat", randi_range(1, 3), 1.0)
                                if randf() < 0.6:
                                        inv.add_item("hide", randi_range(1, 2), 1.0)
                        "snake", "scorpion":
                                if randf() < 0.4:
                                        inv.add_item("meat", 1, 1.0)
                                if randf() < 0.3:
                                        inv.add_item("venom", 1, 1.0)
                        _:
                                if randf() < 0.5:
                                        inv.add_item("meat", randi_range(1, 3), 1.0)
                                if randf() < 0.3:
                                        inv.add_item("hide", randi_range(1, 2), 1.0)
                                if randf() < 0.1:
                                        inv.add_item("bone", randi_range(1, 2), 1.0)

func get_health_percent() -> float:
        return float(health) / float(max_health) * 100.0

func _try_form_pack():
        if not is_pack_animal or is_pack_leader or pack_leader != null:
                return
        
        var nearby_mobs = get_tree().get_nodes_in_group("mobs")
        var same_type_nearby = []
        
        for mob in nearby_mobs:
                if mob == self:
                        continue
                if not is_instance_valid(mob):
                        continue
                if mob.get("mob_type") != mob_type:
                        continue
                if global_position.distance_to(mob.global_position) > pack_call_range:
                        continue
                same_type_nearby.append(mob)
        
        if same_type_nearby.size() >= 2:
                is_pack_leader = true
                for mob in same_type_nearby:
                        if pack_members.size() >= 5:
                                break
                        if mob.get("pack_leader") == null and not mob.get("is_pack_leader"):
                                pack_members.append(mob)
                                mob.set("pack_leader", self)

func _follow_pack_leader(delta: float):
        if not is_instance_valid(pack_leader):
                pack_leader = null
                return
        
        var leader_state = pack_leader.get("state")
        if leader_state in ["chase", "attack", "flee"]:
                var leader_target = pack_leader.get("target")
                if is_instance_valid(leader_target):
                        target = leader_target
                        state = "chase"
                        return
        
        var dist = global_position.distance_to(pack_leader.global_position)
        
        if dist > pack_call_range * 1.5:
                pack_leader = null
                return
        
        if dist > 5.0:
                var dir = (pack_leader.global_position - global_position).normalized()
                dir.y = 0
                velocity = dir * speed * 0.9
                _face_direction(dir, delta)
        else:
                velocity = velocity.lerp(Vector3.ZERO, 3.0 * delta)

func alert_pack(alert_target: Node3D):
        if not is_pack_animal:
                return
        
        emit_signal("pack_alert", global_position, alert_target)
        
        if is_pack_leader:
                for member in pack_members:
                        if is_instance_valid(member) and member.has_method("on_pack_alert"):
                                member.on_pack_alert(alert_target)
        elif pack_leader and is_instance_valid(pack_leader) and pack_leader.has_method("alert_pack"):
                pack_leader.alert_pack(alert_target)

func on_pack_alert(alert_target: Node3D):
        if is_instance_valid(alert_target):
                target = alert_target
                state = "chase"
                alert_level = 100

func start_migration(migration_pos: Vector3):
        if not can_migrate:
                return
        
        is_migrating = true
        migration_target = migration_pos
        migration_timer = 0.0
        start_pos = migration_pos

func _process_migration(delta: float) -> bool:
        if not is_migrating:
                return false
        
        migration_timer += delta
        
        if migration_timer > 60.0:
                is_migrating = false
                return false
        
        var dist = global_position.distance_to(migration_target)
        if dist < 5.0:
                is_migrating = false
                _generate_patrol_points()
                return false
        
        var dir = (migration_target - global_position).normalized()
        dir.y = 0
        velocity = dir * speed * 0.7
        _face_direction(dir, delta)
        return true

func get_pack_size() -> int:
        if is_pack_leader:
                return pack_members.size() + 1
        elif pack_leader:
                var leader_members = pack_leader.get("pack_members")
                return leader_members.size() + 1 if leader_members else 1
        return 1

func leave_pack():
        if pack_leader and is_instance_valid(pack_leader):
                var leader_members = pack_leader.get("pack_members")
                if leader_members:
                        leader_members.erase(self)
                pack_leader = null
        
        if is_pack_leader:
                for member in pack_members:
                        if is_instance_valid(member):
                                member.set("pack_leader", null)
                pack_members.clear()
                is_pack_leader = false

func set_nocturnal(value: bool):
        is_nocturnal = value

func get_behavior_description() -> String:
        match behavior_type:
                "passive":
                        return "Мирное существо, убегает при опасности"
                "neutral":
                        return "Нейтральное существо, атакует только в ответ"
                "aggressive":
                        return "Агрессивное существо, атакует при виде"
                "territorial":
                        return "Территориальное существо, защищает свою зону"
                "predator":
                        return "Хищник, активно охотится"
        return "Неизвестно"
