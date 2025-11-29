extends Node

var input_velocity := Vector3.ZERO
var last_sent := 0.0
var send_interval := 0.05

func _process(delta):
    var players = get_tree().get_nodes_in_group("players")
    if players.size() == 0:
        return
    var local = players[0]
    if not local:
        return
    var desired = local.get("desired_velocity") if "desired_velocity" in local else Vector3.ZERO
    input_velocity = desired
