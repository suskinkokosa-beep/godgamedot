extends BaseAI

@export var patrol_radius := 12.0
@export var speed := 4.0
@export var agro_range := 10.0
@export var attack_damage := 15
var health := 60

var home_pos := Vector3.ZERO
var wander_target := Vector3.ZERO

func _ready():
    home_pos = global_transform.origin
    set_state(State.PATROL)

func _on_patrol(delta):
    if target and is_instance_valid(target):
        set_state(State.CHASE)
        return
    if (global_transform.origin.distance_to(home_pos) > patrol_radius):
        # return home
        var dir = (home_pos - global_transform.origin).normalized()
        translate(dir * speed * delta)
        return
    # wander randomly
    if randf() < 0.01:
        var rnd = Vector3(randf_range(-patrol_radius, patrol_radius), 0, randf_range(-patrol_radius, patrol_radius))
        wander_target = global_transform.origin + rnd
    if wander_target != Vector3.ZERO:
        var dir = (wander_target - global_transform.origin)
        if dir.length() > 0.5:
            translate(dir.normalized() * speed * delta)

func _on_chase(delta):
    if not target or not is_instance_valid(target):
        target = null
        set_state(State.PATROL)
        return
    var dist = global_transform.origin.distance_to(target.global_transform.origin)
    if dist <= 1.8:
        set_state(State.ATTACK)
        return
    var dir = (target.global_transform.origin - global_transform.origin).normalized()
    translate(dir * speed * delta)

func _on_attack(delta):
    if not target or not is_instance_valid(target):
        set_state(State.PATROL); return
    # simple hits on timer
    if randf() < 0.02:
        if target.has_method("apply_damage"):
            target.apply_damage(attack_damage, self)
    # if target dead, go idle
    if target.has_variable("health") and target.health <= 0:
        target = null
        set_state(State.PATROL)

func take_damage(amount, source):
    health -= amount
    if health <= 10:
        set_state(State.FLEE)
    elif source and source.has_method("get_owner"):
        target = source.get_owner()
