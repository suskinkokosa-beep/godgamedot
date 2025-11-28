extends Node
class_name BuildSystem

# Handles placement previews, snapping, and server-side validation

var preview_instance = null
var current_part = null
var snap_distance := 2.0

signal build_placed(item_id, position, rotation)

func request_build(item_id:String):
    current_part = item_id
    _spawn_preview(item_id)

func _spawn_preview(item_id):
    if preview_instance: preview_instance.queue_free()
    var scene = ResourceLoader.load("res://scenes/building_parts/%s.tscn" % item_id)
    if scene:
        preview_instance = scene.instantiate()
        add_child(preview_instance)
        preview_instance.modulate = Color(0,1,0,0.4)

func update_preview(player):
    if not preview_instance: return
    var space_state = get_world_3d().direct_space_state
    var from = player.get_camera().global_transform.origin
    var to = from + player.get_camera().global_transform.basis.z * -1 * 6.0
    var hit = space_state.intersect_ray(from, to)
    if hit:
        var p = hit.position
        preview_instance.global_transform.origin = _snap_position(p)

func _snap_position(pos:Vector3) -> Vector3:
    return Vector3(
        round(pos.x / 1.0) * 1.0,
        round(pos.y / 1.0) * 1.0,
        round(pos.z / 1.0) * 1.0
    )

func confirm_build(player):
    if not preview_instance or not current_part: return
    var pos = preview_instance.global_transform.origin
    var rot = preview_instance.global_transform.basis.get_euler()
    rpc_id(1, "server_place_build", current_part, pos, rot)

@rpc("any_peer", "call_remote", "reliable")
func server_place_build(item_id, pos, rot):
    var scene = ResourceLoader.load("res://scenes/building_parts/%s.tscn" % item_id)
    if not scene: return
    var inst = scene.instantiate()
    get_node("/root/World/Structures").add_child(inst)
    inst.global_transform.origin = pos
    inst.global_transform.basis = Basis().rotated(Vector3.UP, rot.y)
    emit_signal("build_placed", item_id, pos, rot)
