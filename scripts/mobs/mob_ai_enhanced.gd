extends CharacterBody3D

@export var patrol_radius := 10.0
@export var agro_range := 14.0
@export var speed := 3.0
@export var max_health := 60
@export var damage := 10
@export var flee_health_threshold := 10

var health := max_health
var state := "idle"
var start_pos := Vector3.ZERO
var target = null
var faction := "wild"

func _ready():
    start_pos = global_transform.origin
    add_to_group("mobs")
    # register faction if system exists
    var fs = get_node_or_null("/root/FactionSystem")
    if fs:
        fs.create_faction(faction)

func _physics_process(delta):
    # simple day/night check (GameManager could supply)
    var gm = get_node_or_null("/root/GameManager")
    var is_night = false
    if gm and gm.has_method("is_night"):
        is_night = gm.is_night()
    # flee if low health
    if health <= flee_health_threshold:
        state = "flee"
    # if has target and in range chase/attack
    if target and is_instance_valid(target):
        var dist = global_transform.origin.distance_to(target.global_transform.origin)
        if dist <= 1.8:
            state = "attack"
        else:
            state = "chase"
    else:
        # try to find target (players) if hostile
        var players = get_tree().get_nodes_in_group("players")
        for p in players:
            if not is_instance_valid(p): continue
            if global_transform.origin.distance_to(p.global_transform.origin) <= agro_range:
                # check faction relation
                var fs = get_node_or_null("/root/FactionSystem")
                var rel = 0
                if fs and p.has_meta("faction"):
                    rel = fs.get_relation(faction, p.get_meta("faction"))
                if rel <= 0:
                    target = p
                    break
        if not target:
            state = "patrol"

    match state:
        "patrol": _patrol(delta)
        "chase": _chase(delta)
        "attack": _attack(delta)
        "flee": _flee(delta)
        _:
            pass

func _patrol(delta):
    var dir = (start_pos - global_transform.origin)
    if dir.length() < 1.0:
        var rnd = Vector3(randf_range(-patrol_radius, patrol_radius), 0, randf_range(-patrol_radius, patrol_radius))
        look_at(global_transform.origin + rnd, Vector3.UP)
    velocity = transform.basis.z * -1 * speed
    move_and_slide()

func _chase(delta):
    if not target: return
    look_at(target.global_transform.origin, Vector3.UP)
    var dir = (target.global_transform.origin - global_transform.origin).normalized()
    velocity = dir * speed
    move_and_slide()

func _attack(delta):
    if not target: return
    if target.has_method("apply_damage"):
        target.apply_damage(damage, self)
    # small cooldown via sleep
    yield(get_tree().create_timer(1.0), "timeout")

func _flee(delta):
    # run back to start
    var dir = (start_pos - global_transform.origin)
    if dir.length() > 0.1:
        velocity = dir.normalized() * speed * 1.2
        move_and_slide()
    else:
        # healed or safe
        state = "idle"

func apply_damage(amount, source):
    health -= amount
    if health <= 0:
        die()

func die():
    # drop loot and queue_free
    queue_free()
