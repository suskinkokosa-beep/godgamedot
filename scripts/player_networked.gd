extends CharacterBody3D

@export var speed := 6.0
@export var mouse_sens := 0.12
@export var melee_damage := 10

var camera = null
var inv = null
var net = null

func _ready():
    camera = $Camera3D if has_node("Camera3D") else null
    inv = get_node_or_null("/root/Inventory")
    net = get_node_or_null("/root/Network")
    add_to_group("players")

func attack():
    if not camera:
        return
    var from = camera.global_transform.origin
    var to = from + -camera.global_transform.basis.z * 2.2
    var space = get_world_3d().direct_space_state
    var query = PhysicsRayQueryParameters3D.create(from, to)
    query.exclude = [self]
    var res = space.intersect_ray(query)
    if res:
        var target = res.collider
        if target:
            # if target has net_id use networked damage
            var nid = -1
            var nid_val = target.get("net_id")
            if nid_val != null:
                nid = nid_val
            # request server to apply damage
            if net:
                rpc_id(1, "rpc_request_attack", get_tree().get_multiplayer().get_unique_id(), nid, melee_damage, global_transform.origin)
            else:
                # local fallback
                if target.has_method("apply_damage"):
                    target.apply_damage(melee_damage, self)


func request_server_spawn():
    var net = get_node_or_null("/root/Network")
    if net and not net.is_server:
        var scene_path = "res://scenes/player/player.tscn"
        rpc_id(1, "rpc_request_player_join", scene_path)

# Attempt to request join once after local creation
func _enter_tree():
    # small delay could be used; here we call immediately
    request_server_spawn()


func _on_registered_as(id:int):
    # called after server assigns net id; ensure stats and inventory exist
    var ss = get_node_or_null("/root/StatsSystem")
    if ss:
        ss.create_player(id)
    var inv = get_node_or_null("/root/Inventory")
    if inv and inv.get_items().size() == 0:
        inv.add_item("wood", 5, 1.0)
        inv.add_item("stone", 3, 1.5)
