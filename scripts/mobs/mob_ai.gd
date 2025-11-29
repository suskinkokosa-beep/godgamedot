extends CharacterBody3D

@export var patrol_radius := 10.0
@export var agro_range := 15.0
@export var attack_range := 2.5
@export var speed := 3.5
@export var run_speed := 5.5
@export var max_health := 50
@export var damage := 10
@export var attack_cooldown := 1.5
@export var xp_reward := 25.0
@export var faction := "wild"
@export var mob_type := "mob_basic"
@export var loot_table := "mob_basic"

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

signal died(mob, killer)
signal damaged(mob, amount, source)

func _ready():
        health = max_health
        start_pos = global_position
        wander_target = start_pos
        add_to_group("mobs")
        add_to_group("entities")
        
        var net = get_node_or_null("/root/Network")
        if net and net.is_server:
                net.register_entity_server(self)
        
        var faction_sys = get_node_or_null("/root/FactionSystem")
        if faction_sys:
                faction_sys.register_entity(self, faction)

func _physics_process(delta):
        var net = get_node_or_null("/root/Network")
        if net and not net.is_server:
                return
        
        attack_timer = max(0, attack_timer - delta)
        
        match state:
                "idle":
                        _process_idle(delta)
                "patrol":
                        _process_patrol(delta)
                "chase":
                        _process_chase(delta)
                "attack":
                        _process_attack(delta)
                "flee":
                        _process_flee(delta)
        
        move_and_slide()

func _process_idle(delta):
        idle_timer += delta
        
        var found_target = _find_target()
        if found_target:
                target = found_target
                state = "chase"
                return
        
        if idle_timer > randf_range(3.0, 6.0):
                idle_timer = 0.0
                state = "patrol"
                _pick_wander_target()

func _process_patrol(delta):
        var found_target = _find_target()
        if found_target:
                target = found_target
                state = "chase"
                return
        
        var dir = (wander_target - global_position).normalized()
        dir.y = 0
        velocity = dir * speed
        
        if global_position.distance_to(wander_target) < 1.5:
                state = "idle"

func _process_chase(delta):
        if not is_instance_valid(target):
                target = null
                state = "idle"
                return
        
        var dist = global_position.distance_to(target.global_position)
        
        if dist > agro_range * 1.5:
                target = null
                state = "idle"
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
        velocity = dir * run_speed
        
        look_at(target.global_position, Vector3.UP)

func _process_attack(delta):
        if not is_instance_valid(target):
                target = null
                state = "idle"
                return
        
        var dist = global_position.distance_to(target.global_position)
        
        if dist > attack_range * 1.2:
                state = "chase"
                return
        
        if attack_timer <= 0:
                _perform_attack()
                attack_timer = attack_cooldown

func _process_flee(delta):
        if not is_instance_valid(target):
                is_fleeing = false
                state = "idle"
                return
        
        var flee_dir = (global_position - target.global_position).normalized()
        flee_dir.y = 0
        velocity = flee_dir * run_speed
        
        if global_position.distance_to(target.global_position) > agro_range * 2:
                is_fleeing = false
                target = null
                state = "idle"

func _find_target() -> Node3D:
        var players = get_tree().get_nodes_in_group("players")
        var closest: Node3D = null
        var closest_dist := agro_range
        
        for player in players:
                var dist = global_position.distance_to(player.global_position)
                if dist < closest_dist:
                        var faction_sys = get_node_or_null("/root/FactionSystem")
                        if faction_sys:
                                var rel = faction_sys.get_relation(faction, "player")
                                if rel < 0:
                                        closest = player
                                        closest_dist = dist
                        else:
                                closest = player
                                closest_dist = dist
        
        return closest

func _pick_wander_target():
        var angle = randf() * TAU
        var dist = randf_range(patrol_radius * 0.3, patrol_radius)
        wander_target = start_pos + Vector3(cos(angle) * dist, 0, sin(angle) * dist)

func _perform_attack():
        if not is_instance_valid(target):
                return
        
        if target.has_method("take_damage"):
                target.take_damage(damage, self)
        elif target.has_method("apply_damage"):
                target.apply_damage(damage, self)

func take_damage(amount: float, source: Node = null):
        apply_damage(amount, source)

func apply_damage(amount: float, source: Node = null):
        var net = get_node_or_null("/root/Network")
        if net and not net.is_server:
                return
        
        health -= amount
        emit_signal("damaged", self, amount, source)
        
        if source and is_instance_valid(source):
                target = source
                state = "chase"
        
        if float(health) / float(max_health) < flee_health_threshold:
                is_fleeing = true
                state = "flee"
        
        if health <= 0:
                die(source)

func die(killer: Node = null):
        var quest_sys = get_node_or_null("/root/QuestSystem")
        if quest_sys and killer:
                var killer_id = killer.get("net_id") if killer.get("net_id") else 1
                quest_sys.update_objective(killer_id, "kill", "mob_basic", 1)
        
        var prog = get_node_or_null("/root/PlayerProgression")
        if prog and killer:
                var killer_id = killer.get("net_id") if killer.get("net_id") else 1
                prog.add_xp(killer_id, xp_reward)
                prog.add_skill_xp(killer_id, "combat", xp_reward * 0.5)
        
        _drop_loot()
        
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
                if randf() < 0.5:
                        inv.add_item("meat", randi_range(1, 3), 1.0)
                if randf() < 0.3:
                        inv.add_item("hide", randi_range(1, 2), 1.0)
                if randf() < 0.1:
                        inv.add_item("bone", randi_range(1, 2), 1.0)

func get_health_percent() -> float:
        return float(health) / float(max_health) * 100.0
