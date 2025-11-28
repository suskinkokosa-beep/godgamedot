extends Node3D

func place_building(scene_path:String, tf:Transform3D):
    # local call to request server spawn
    var net = get_node_or_null("/root/Network")
    if net:
        rpc_id(1, "rpc_request_spawn", scene_path, tf)
    else:
        var s = ResourceLoader.load(scene_path)
        if s:
            var inst = s.instantiate()
            get_tree().get_root().get_node("/root/World").add_child(inst)
            inst.global_transform = tf
