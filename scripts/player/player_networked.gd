extends CharacterBody3D

@export var speed := 5.5
@export var mouse_sens := 0.12
@export var max_stamina := 100.0
@export var stamina_regen := 8.0

var stamina := max_stamina
var is_blocking := false
var net = null
var net_id := -1
var ui = null

func _ready():
    net = get_node_or_null("/root/Network")
    ui = get_node_or_null("/root/UI")
    add_to_group("players")
    # ensure stamina variable exists for server bookkeeping
    if is_network_master():
        stamina = max_stamina

func _process(delta):
    # local stamina regen prediction
    if not is_network_master():
        stamina = min(max_stamina, stamina + stamina_regen * delta)
    # update HUD if available
    var ui_ctrl = get_node_or_null("/root/World/UI/UI")
    if ui_ctrl:
        var stats_node = get_node_or_null("/root/UI")
    # placeholder for input handling (should be triggered by input events)

# Attack methods called by input handlers
func light_attack(target_node):
    if not target_node: return
    # local prediction: reduce stamina immediately
    if stamina < 8: return
    stamina = max(0, stamina - 8)
    # find target net id if exists
    var tid = target_node.get("net_id") if target_node.has_variable("net_id") else -1
    if net:
        rpc_id(1, "rpc_request_attack", get_tree().get_multiplayer().get_unique_id(), net_id, tid, "light", global_transform.origin)
    else:
        # local fallback: call server combat directly
        var cs = get_node_or_null("/root/CombatServer")
        if cs:
            cs.request_attack(get_tree().get_multiplayer().get_unique_id(), net_id, tid, "light", global_transform.origin)

func heavy_attack(target_node):
    if not target_node: return
    if stamina < 20: return
    stamina = max(0, stamina - 20)
    var tid = target_node.get("net_id") if target_node.has_variable("net_id") else -1
    if net:
        rpc_id(1, "rpc_request_attack", get_tree().get_multiplayer().get_unique_id(), net_id, tid, "heavy", global_transform.origin)
    else:
        var cs = get_node_or_null("/root/CombatServer")
        if cs:
            cs.request_attack(get_tree().get_multiplayer().get_unique_id(), net_id, tid, "heavy", global_transform.origin)

func block(state:bool):
    is_blocking = state
    # send block state to server? for now local

func apply_damage(amount, source):
    # server-authoritative apply_damage should be handled on server; clients may receive rpc_notify_health
    var gm = get_node_or_null("/root/GameManager")
    # local visual feedback can go here
    pass


# Input -> desired_velocity handling for client-side prediction
var desired_velocity := Vector3.ZERO

func _input(event):
    # Placeholder: real project should map Input actions
    pass

func update_desired_from_input():
    var dir = Vector3.ZERO
    if Input.is_action_pressed("move_forward"):
        dir.z -= 1
    if Input.is_action_pressed("move_back"):
        dir.z += 1
    if Input.is_action_pressed("move_left"):
        dir.x -= 1
    if Input.is_action_pressed("move_right"):
        dir.x += 1
    # transform to world space using camera or player basis
    dir = dir.normalized()
    desired_velocity = dir * speed

func _physics_process(delta):
    if is_network_master():
        # server authoritative movement (server will apply moves itself)
        return
    # client-side prediction: apply desired_velocity locally for smoother feel
    update_desired_from_input()
    translate(desired_velocity * delta)


func _on_registered_as(id:int):
    # ensure progression record exists for this player
    var pp = get_node_or_null("/root/PlayerProgression")
    if pp:
        pp.ensure_player(id)
    # create default inventory items if not present
    var inv = get_node_or_null("/root/Inventory")
    if inv and inv.get_items().size() == 0:
        inv.add_item("wood", 5, 1.0)
        inv.add_item("stone", 3, 1.5)


# Attack integration: spawn AttackHit and deduct stamina. Use CombatEngine server-side to validate.
func perform_attack_local(attack_type:String):
    var ac = get_node_or_null("PlayerAttackController")
    var wp = null
    if has_variable("equipped_weapon"):
        wp = equipped_weapon
    else:
        # fallback to default weapon resource
        wp = ResourceLoader.load("res://assets/weapons/sword.tres")
    if not wp:
        return
    # local prediction: reduce stamina
    var cost = wp.stamina_cost if wp.has("stamina_cost") else (attack_type == "heavy" ? 20 : 8)
    stamina = max(0, stamina - cost)
    # spawn attack hit
    if ac:
        ac.perform_attack(self, attack_type, {"damage_min":wp.damage_min, "damage_max":wp.damage_max, "critical_chance":wp.critical_chance, "critical_multiplier":wp.critical_multiplier})
    # send request to server for authoritative application
    var net = get_node_or_null("/root/Network")
    if net:
        rpc_id(1, "rpc_request_attack", get_tree().get_multiplayer().get_unique_id(), net_id, -1, attack_type, global_transform.origin)
