extends CharacterBody3D

@export var role := "citizen"
@export var npc_name := "Житель"
@export var speed := 2.5
@export var max_health := 100
@export var faction := "town"

var health: float
var home_pos := Vector3.ZERO
var work_pos := Vector3.ZERO
var current_task := "idle"
var task_timer := 0.0
var wander_target := Vector3.ZERO
var net_id := -1
var dialogue_options := []
var inventory := {}
var mood := 75.0

signal interacted(npc, player)
signal task_completed(npc, task)

func _ready():
        health = max_health
        home_pos = global_position
        work_pos = home_pos + Vector3(randf_range(-10, 10), 0, randf_range(-10, 10))
        add_to_group("npcs")
        add_to_group("entities")
        add_to_group("interactable")
        
        _setup_role()
        
        var faction_sys = get_node_or_null("/root/FactionSystem")
        if faction_sys:
                faction_sys.register_entity(self, faction)

func _setup_role():
        match role:
                "farmer":
                        npc_name = "Фермер"
                        dialogue_options = ["Урожай в этом году хороший.", "Нужен дождь..."]
                        inventory = {"wheat": 10, "carrot": 5}
                "guard":
                        npc_name = "Стражник"
                        dialogue_options = ["Стою на страже.", "В лесу видели волков."]
                        inventory = {"iron_sword": 1}
                "trader":
                        npc_name = "Торговец"
                        dialogue_options = ["Лучшие товары в округе!", "Что желаете купить?"]
                        inventory = {"bread": 5, "bandage": 3, "torch": 10}
                "builder":
                        npc_name = "Строитель"
                        dialogue_options = ["Строим новый дом.", "Нужно больше дерева."]
                        inventory = {"wood": 20, "stone": 10}
                _:
                        dialogue_options = ["Добрый день!", "Хорошая погода."]

func _physics_process(delta):
        var net = get_node_or_null("/root/Network")
        if net and not net.is_server:
                return
        
        task_timer += delta
        
        var gm = get_node_or_null("/root/GameManager")
        var is_night = false
        if gm and gm.has_method("is_night"):
                is_night = gm.is_night()
        
        if is_night:
                _go_home(delta)
        else:
                match role:
                        "farmer":
                                _do_farming(delta)
                        "guard":
                                _do_patrol(delta)
                        "trader":
                                _do_trade(delta)
                        "builder":
                                _do_building(delta)
                        _:
                                _wander(delta)
        
        move_and_slide()
        _update_mood(delta)

func _go_home(delta):
        if global_position.distance_to(home_pos) > 2.0:
                var dir = (home_pos - global_position).normalized()
                dir.y = 0
                velocity = dir * speed
        else:
                velocity = Vector3.ZERO
                current_task = "sleeping"

func _do_farming(delta):
        current_task = "farming"
        
        if task_timer > 5.0:
                task_timer = 0.0
                var ss = get_node_or_null("/root/SettlementSystem")
                if ss:
                        var nearest = ss.get_nearest_settlement(global_position)
                        if not nearest.is_empty():
                                ss.add_resource(nearest.id, "food", 1)
                emit_signal("task_completed", self, "farming")
        
        if global_position.distance_to(work_pos) > 3.0:
                var dir = (work_pos - global_position).normalized()
                dir.y = 0
                velocity = dir * speed
        else:
                velocity = Vector3.ZERO
                if randf() < 0.02:
                        _pick_work_position()

func _do_patrol(delta):
        current_task = "patrolling"
        
        var threat = _check_for_threats()
        if threat:
                _engage_threat(threat, delta)
                return
        
        if global_position.distance_to(wander_target) < 2.0 or task_timer > 10.0:
                task_timer = 0.0
                _pick_patrol_target()
        
        var dir = (wander_target - global_position).normalized()
        dir.y = 0
        velocity = dir * speed

func _do_trade(delta):
        current_task = "trading"
        
        if global_position.distance_to(work_pos) > 2.0:
                var dir = (work_pos - global_position).normalized()
                dir.y = 0
                velocity = dir * speed
        else:
                velocity = Vector3.ZERO
                
                if task_timer > 8.0:
                        task_timer = 0.0
                        work_pos = home_pos + Vector3(randf_range(-5, 5), 0, randf_range(-5, 5))

func _do_building(delta):
        current_task = "building"
        
        var build_sys = get_node_or_null("/root/BuildSystem")
        if build_sys:
                var structures = build_sys.get_placed_structures()
                for s in structures:
                        if is_instance_valid(s):
                                var dist = global_position.distance_to(s.global_position)
                                if dist < 10.0 and dist > 2.0:
                                        var dir = (s.global_position - global_position).normalized()
                                        dir.y = 0
                                        velocity = dir * speed
                                        return
        
        _wander(delta)

func _wander(delta):
        current_task = "wandering"
        
        if task_timer > 5.0 or global_position.distance_to(wander_target) < 2.0:
                task_timer = 0.0
                var angle = randf() * TAU
                var dist = randf_range(3.0, 8.0)
                wander_target = home_pos + Vector3(cos(angle) * dist, 0, sin(angle) * dist)
        
        var dir = (wander_target - global_position).normalized()
        dir.y = 0
        velocity = dir * speed * 0.5

func _pick_patrol_target():
        var angle = randf() * TAU
        var dist = randf_range(5.0, 15.0)
        wander_target = home_pos + Vector3(cos(angle) * dist, 0, sin(angle) * dist)

func _pick_work_position():
        var angle = randf() * TAU
        var dist = randf_range(2.0, 5.0)
        work_pos = home_pos + Vector3(cos(angle) * dist, 0, sin(angle) * dist)

func _check_for_threats() -> Node3D:
        var mobs = get_tree().get_nodes_in_group("mobs")
        for mob in mobs:
                var dist = global_position.distance_to(mob.global_position)
                if dist < 15.0:
                        return mob
        return null

func _engage_threat(threat: Node3D, delta):
        current_task = "fighting"
        var dist = global_position.distance_to(threat.global_position)
        
        if dist > 2.5:
                var dir = (threat.global_position - global_position).normalized()
                dir.y = 0
                velocity = dir * speed * 1.5
        else:
                velocity = Vector3.ZERO
                if task_timer > 1.5:
                        task_timer = 0.0
                        if threat.has_method("apply_damage"):
                                threat.apply_damage(15, self)

func _update_mood(delta):
        var ss = get_node_or_null("/root/SettlementSystem")
        if ss:
                var nearest = ss.get_nearest_settlement(global_position)
                if not nearest.is_empty():
                        mood = nearest.get("happiness", 50.0)

func interact(player):
        emit_signal("interacted", self, player)
        
        var dialogue = dialogue_options[randi() % dialogue_options.size()]
        return {
                "name": npc_name,
                "role": role,
                "dialogue": dialogue,
                "can_trade": role == "trader",
                "inventory": inventory if role == "trader" else {}
        }

func apply_damage(amount: float, source: Node = null):
        health -= amount
        if health <= 0:
                die(source)

func die(killer: Node = null):
        var faction_sys = get_node_or_null("/root/FactionSystem")
        if faction_sys:
                faction_sys.unregister_entity(self, faction)
                if killer:
                        faction_sys.modify_relation("player", faction, -20)
        queue_free()

func get_health_percent() -> float:
        return float(health) / float(max_health) * 100.0
