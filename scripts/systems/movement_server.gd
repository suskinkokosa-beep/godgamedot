extends Node

# Map of player_id -> last_valid_transform
var players := {} # net_id -> {pos:Vector3, vel:Vector3, last_update_time:float}

# anti-cheat thresholds
const MAX_SPEED := 12.0 # units per second
const MAX_TELEPORT_DIST := 10.0 # max distance allowed between updates

# process client movement inputs (client sends desired velocity + timestamp)
func _is_server() -> bool:
    var mp = multiplayer
    if mp == null:
        return true
    if not mp.has_multiplayer_peer():
        return true
    return mp.is_server()

@rpc("any_peer", "call_remote")
func rpc_request_move(peer_id:int, net_id:int, desired_vel:Vector3, client_time:float):
    if not _is_server():
        return
    var now = Time.get_ticks_msec() / 1000.0
    # find server-side node
    var net = get_node_or_null("/root/Network")
    if not net: return
    if not net.entities.has(net_id): return
    var node = net.entities[net_id]
    # basic anti-cheat: speed check
    var last = players.get(net_id, null)
    if last and last.pos:
        var dt = now - last.last_update_time
        if dt <= 0: dt = 0.05
        var expected_move = desired_vel.length() * dt
        # clamp expected max by allowed speed
        if desired_vel.length() > MAX_SPEED:
            # suspect speedhack: clamp velocity
            desired_vel = desired_vel.normalized() * MAX_SPEED
    # apply movement server-side via simple integration
    var server_dt = 0.05
    var new_pos = node.global_transform.origin + desired_vel * server_dt
    # teleport check
    if last and last.pos and new_pos.distance_to(last.pos) > MAX_TELEPORT_DIST:
        # suspicious - ignore movement and reset to last known safe pos
        new_pos = last.pos
    # set node transform on server authoritative
    var t = node.global_transform
    t.origin = new_pos
    node.global_transform = t
    # store last
    players[net_id] = {"pos":new_pos, "vel":desired_vel, "last_update_time":now}
    # broadcast to clients
    rpc_id(0, "rpc_sync_transform", net_id, new_pos, desired_vel)

