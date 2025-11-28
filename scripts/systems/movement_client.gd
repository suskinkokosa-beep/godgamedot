extends Node
class_name MovementClient

var input_velocity := Vector3.ZERO
var last_sent := 0.0
var send_interval := 0.05

func _process(delta):
    # pack input from local player (assuming single local player instance exists)
    var local = get_tree().get_nodes_in_group("players")[0] if get_tree().get_nodes_in_group("players").size() > 0 else null
    if not local: return
    # compute desired vel from input (placeholder: read from local node's desired_velocity)
    var desired = local.get("desired_velocity") if local.has_variable("desired_velocity") else Vector3.ZERO
    input_velocity = desired
    var now = OS.get_unix_time_millis() / 1000.0
    if now - last_sent >= send_interval:
        last_sent = now
        # send to server via Network autoload
        var net = get_node_or_null("/root/Network")
        if net:
            var peer_id = get_tree().get_multiplayer().get_unique_id()
            var nid = local.get("net_id") if local.has_variable("net_id") else -1
            rpc_id(1, "rpc_request_move", peer_id, nid, desired, now)
