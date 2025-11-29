extends Node

var is_server := false
var next_entity_id := 1000
var entities := {} # id -> node (only on server)
var client_entities := {} # id -> node (clients)

func is_active() -> bool:
    var mp = get_tree().get_multiplayer()
    return mp and mp.has_multiplayer_peer() and mp.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED

func host(port=7777):
    var peer = ENetMultiplayerPeer.new()
    peer.create_server(port)
    get_tree().get_multiplayer().multiplayer_peer = peer
    is_server = true
    print("Hosting on port", port)

func join(ip, port=7777):
    var peer = ENetMultiplayerPeer.new()
    peer.create_client(ip, port)
    get_tree().get_multiplayer().multiplayer_peer = peer
    is_server = false
    print("Joining", ip)

# SERVER: allocate id and register entity, then notify clients
func register_entity_server(node):
    if not is_server:
        return -1
    var id = next_entity_id
    next_entity_id += 1
    entities[id] = node
    # inform clients to create a proxy (they may already have it)
    rpc_id(0, "rpc_notify_register", id, node.get_filename() if node.has_method("get_filename") else "")
    return id

# CLIENT: register local representation (non-authoritative)
func register_entity_client(id, node):
    client_entities[id] = node

@rpc("any_peer", "call_remote")
func rpc_notify_register(id, dummy):
    # clients can create mapping after they instantiate the scene; placeholder
    # actual linking should be done when spawn notification arrives
    pass

# SERVER-AUTHORIZED SPAWN (client calls request, server spawns and notifies)
@rpc("any_peer", "call_remote")
func rpc_request_spawn(scene_path: String, tf: Transform3D):
    if not is_server:
        return
    var scene = ResourceLoader.load(scene_path)
    if not scene:
        print("Spawn failed: scene not found", scene_path)
        return
    var inst = scene.instantiate()
    var world = get_tree().get_root().get_node("/root/World") if get_tree().get_root().has_node("World") else null
    if world:
        world.add_child(inst)
    else:
        get_tree().get_root().add_child(inst)
    inst.global_transform = tf
    # register and notify clients with id and path
    var id = register_entity_server(inst)
    rpc_id(0, "rpc_notify_spawn", scene_path, tf, id)

@rpc("any_peer", "call_remote")
func rpc_notify_spawn(scene_path: String, tf: Transform3D, id:int):
    if is_server:
        return
    var scene = ResourceLoader.load(scene_path)
    if not scene:
        return
    var inst = scene.instantiate()
    var world = get_tree().get_root().get_node("/root/World") if get_tree().get_root().has_node("World") else null
    if world:
        world.add_child(inst)
    else:
        get_tree().get_root().add_child(inst)
    inst.global_transform = tf
    # register local mapping
    register_entity_client(id, inst)

# DAMAGE RPC (clients request, server applies and notifies)
@rpc("any_peer", "call_remote")
func rpc_request_damage(entity_id:int, amount:float, attacker_peer_id:int):
    if not is_server:
        return
    if not entities.has(entity_id):
        return
    var node = entities[entity_id]
    if node and node.has_method("apply_damage"):
        node.apply_damage(amount, attacker_peer_id)
        # notify clients about health change if node has get_health method
        var health = node.get("health") if "health" in node else 0
        rpc_id(0, "rpc_notify_health", entity_id, health)

@rpc("any_peer", "call_remote")
func rpc_notify_health(entity_id:int, health:float):
    # clients update local representation
    if client_entities.has(entity_id):
        var node = client_entities[entity_id]
        if node and "health" in node:
            node.health = health


# SERVER: receive attack requests and validate via combat server
@rpc("any_peer", "call_remote")
func rpc_request_attack(attacker_id:int, target_entity_id:int, damage:float, attacker_pos:Vector3):
    if not is_server:
        return
    var combat = get_node_or_null("/root/CombatServer")
    if combat:
        combat.validate_and_apply_attack(attacker_id, target_entity_id, damage, attacker_pos)


# CLIENT -> SERVER: request to spawn player for this peer
@rpc("any_peer", "call_remote")
func rpc_request_player_join(scene_path: String):
    if not is_server:
        return
    var peer_id = get_tree().get_multiplayer().get_unique_id()
    var scene = ResourceLoader.load(scene_path)
    if not scene:
        print("Player scene not found", scene_path)
        return
    var inst = scene.instantiate()
    var world = get_tree().get_root().get_node("/root/World") if get_tree().get_root().has_node("World") else null
    if world:
        world.add_child(inst)
    else:
        get_tree().get_root().add_child(inst)
    # set owner meta for server
    inst.set_meta("owner_peer_id", peer_id)
    inst.set_meta("owner_scene_path", scene_path)
    inst.set_meta("owner_spawn_time", Time.get_unix_time_from_system())
    inst.global_transform.origin += Vector3(0,0,0) # leave spawn pos as is, could be refined
    var id = register_entity_server(inst)
    # notify single client about their assigned id and spawn
    rpc_id(peer_id, "rpc_notify_player_spawned", scene_path, inst.global_transform, id)

# Server -> client: notify player's own client of spawn and assigned net_id
@rpc("any_peer", "call_remote")
func rpc_notify_player_spawned(scene_path: String, tf: Transform3D, id:int):
    # client will instantiate and set local ownership mapping
    var scene = ResourceLoader.load(scene_path)
    if not scene:
        return
    var inst = scene.instantiate()
    var world = get_tree().get_root().get_node("/root/World") if get_tree().get_root().has_node("World") else null
    if world:
        world.add_child(inst)
    else:
        get_tree().get_root().add_child(inst)
    inst.global_transform = tf
    if inst.has_method("set_net_id"):
        inst.set_net_id(id)
    else:
        inst.net_id = id
    # register local client mapping
    register_entity_client(id, inst)


@rpc("any_peer", "call_remote")
func rpc_notify_stamina(entity_id:int, stamina_value:float):
    if client_entities.has(entity_id):
        var node = client_entities[entity_id]
        if node and "stamina" in node:
            node.stamina = stamina_value


@rpc("any_peer", "call_remote")
func rpc_sync_transform(entity_id:int, pos:Vector3, vel:Vector3):
    # clients receive authoritative transform updates from server
    if is_server:
        return
    if client_entities.has(entity_id):
        var node = client_entities[entity_id]
        # if node has interpolator, set server state
        if node.has_node("NetworkInterpolator"):
            node.get_node("NetworkInterpolator").set_server_state(pos, vel)
        else:
            # direct set fallback
            var t = node.global_transform
            t.origin = pos
            node.global_transform = t
