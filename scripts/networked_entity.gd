extends Node3D

var net_id := -1

func _ready():
    # if autoload Network exists, ask server to register or register locally
    var net = get_node_or_null("/root/Network")
    if net:
        if net.is_server:
            net.register_entity_server(self)
        else:
            # clients will be registered when rpc_notify_spawn is received
            pass

func get_net_id():
    return net_id

func set_net_id(id:int):
    net_id = id
