extends Node
class_name CombatServer

# attack types: light, heavy, ranged, roll (dodge)
var cooldowns = {} # peer_id -> cooldown remaining
var stamina_costs = {"light":8, "heavy":20, "roll":15, "ranged":12}
var attack_range = {"light":2.2, "heavy":2.8, "ranged":25.0}

func _is_server() -> bool:
    var mp = multiplayer
    if mp == null:
        return true
    if not mp.has_multiplayer_peer():
        return true
    return mp.is_server()

# validate and apply attack request from client
func request_attack(attacker_peer:int, attacker_id:int, target_id:int, attack_type:String, attacker_pos:Vector3):
    if not _is_server():
        return
    # cooldown check
    if cooldowns.get(attacker_peer, 0.0) > 0.0:
        return
    # find attacker node and target node via Network autoload
    var net = get_node_or_null("/root/Network")
    if not net:
        return
    var attacker_node = null
    var target_node = null
    if net.entities.has(attacker_id):
        attacker_node = net.entities[attacker_id]
    if net.entities.has(target_id):
        target_node = net.entities[target_id]
    # basic distance validation if target exists
    if target_node and attacker_node:
        var dist = attacker_node.global_transform.origin.distance_to(target_node.global_transform.origin)
        if dist > attack_range.get(attack_type, 3.0):
            return
    # stamina check
    var stamina = attacker_node.get("stamina") if attacker_node and "stamina" in attacker_node else 100
    var cost = stamina_costs.get(attack_type, 10)
    if stamina < cost:
        return
    # apply cooldown and reduce stamina on server-side attacker_node
    cooldowns[attacker_peer] = 1.2 if attack_type == "heavy" else 0.6
    if attacker_node and "stamina" in attacker_node:
        attacker_node.stamina = max(0, attacker_node.stamina - cost)
        # notify clients about attacker's stamina change
        rpc_id(0, "rpc_notify_stamina", attacker_id, attacker_node.stamina)
    # compute damage based on type and attacker's stats (simplified)
    var base_dmg = 25 if attack_type == "heavy" else 12
    # apply damage to target (server authoritative)
    if target_node and target_node.has_method("apply_damage"):
        target_node.apply_damage(base_dmg, attacker_node)
        var remaining = target_node.health if "health" in target_node else 0
        rpc_id(0, "rpc_notify_health", target_id, remaining)

func _physics_process(delta):
    for k in cooldowns.keys():
        cooldowns[k] = max(0, cooldowns[k] - delta)
