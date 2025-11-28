extends CharacterBody3D

var patrol_points := []
var current_index := 0
var speed := 3.5
var alert_range := 12.0
var combat_target = null

func _ready():
    add_to_group("guards")
    set_process(true)

func _process(delta):
    if combat_target and is_instance_valid(combat_target):
        _engage_target(delta)
        return
    if patrol_points.size() == 0:
        return
    var p = patrol_points[current_index]
    var dir = (p - global_transform.origin)
    if dir.length() < 1.0:
        current_index = (current_index + 1) % patrol_points.size()
    else:
        translate(dir.normalized() * speed * delta)
    # scan for hostiles
    var players = get_tree().get_nodes_in_group("players")
    for pl in players:
        if global_transform.origin.distance_to(pl.global_transform.origin) < alert_range:
            # check faction relation
            var fs = get_node_or_null("/root/FactionSystem")
            var rel = 0
            if fs and pl.has_meta("faction"):
                rel = fs.get_relation("settlers", pl.get_meta("faction"))
            if rel <= 0:
                combat_target = pl
                break

func _engage_target(delta):
    if not combat_target or not is_instance_valid(combat_target):
        combat_target = null; return
    var dist = global_transform.origin.distance_to(combat_target.global_transform.origin)
    if dist > 2.0:
        var dir = (combat_target.global_transform.origin - global_transform.origin).normalized()
        translate(dir * speed * delta)
    else:
        if randf() < 0.02 and combat_target.has_method("apply_damage"):
            combat_target.apply_damage(12, self)
