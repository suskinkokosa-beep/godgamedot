extends Node
class_name ResourceGenerator

@export var resource_scene := "res://scenes/world/resource_node.tscn"
@export var area_center := Vector3(0,0,0)
@export var area_radius := 200.0
@export var density := 0.0008 # nodes per sq unit approximation
@export var min_distance := 4.0

var spawned := []

func generate():
    # simple random scatter based on area and density
    var area = PI * area_radius * area_radius
    var count = int(area * density)
    for i in range(count):
        var pos = _random_point_in_radius(area_center, area_radius)
        if _is_valid_position(pos):
            _spawn_node(pos)

func _random_point_in_radius(center:Vector3, r:float) -> Vector3:
    var ang = randf() * PI * 2.0
    var rad = sqrt(randf()) * r
    var x = center.x + cos(ang) * rad
    var z = center.z + sin(ang) * rad
    # approximate y by raycast to terrain if needed; for now use 0
    return Vector3(x, 0, z)

func _is_valid_position(pos:Vector3) -> bool:
    for p in spawned:
        if p.distance_to(pos) < min_distance:
            return false
    return true

func _spawn_node(pos:Vector3):
    var scene = ResourceLoader.load(resource_scene)
    if not scene: return
    var inst = scene.instantiate()
    add_child(inst)
    inst.global_transform.origin = pos
    spawned.append(pos)
