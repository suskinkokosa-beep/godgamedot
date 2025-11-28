extends CharacterBody3D

@export var patrol_radius := 8.0
@export var agro_range := 12.0
@export var speed := 3.5
@export var max_health := 40
@export var damage := 8

var health := max_health
var target = null
var start_pos = Vector3.ZERO
var state := "idle"
var net_id := -1

func _ready():
    start_pos = global_transform.origin
    add_to_group("mobs")
    # register with Network if server
    var net = get_node_or_null("/root/Network")
    if net and net.is_server:
        net.register_entity_server(self)

func apply_damage(amount, source):
    # Only server should process authoritative damage
    var net = get_node_or_null("/root/Network")
    if net and not net.is_server:
        return
    health -= amount
    if health <= 0:
        die()

func die():
    queue_free()
