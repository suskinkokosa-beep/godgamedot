extends BaseAI

@export var speed := 3.0
@export var agro_range := 14.0
@export var attack_damage := 20
var health := 120

func _ready():
    set_state(State.PATROL)

func _on_patrol(delta):
    if randf() < 0.01:
        var rnd = Vector3(randf_range(-8,8),0,randf_range(-8,8))
        translate(rnd)
    # find players in range
    var players = get_tree().get_nodes_in_group("players")
    for p in players:
        if global_transform.origin.distance_to(p.global_transform.origin) < agro_range:
            target = p
            set_state(State.CHASE)
            return

func _on_chase(delta):
    if not target or not is_instance_valid(target):
        target = null; set_state(State.PATROL); return
    var dir = (target.global_transform.origin - global_transform.origin).normalized()
    translate(dir * speed * delta)
    if global_transform.origin.distance_to(target.global_transform.origin) < 1.5:
        set_state(State.ATTACK)

func _on_attack(delta):
    if randf() < 0.03 and target and target.has_method("apply_damage"):
        target.apply_damage(attack_damage, self)
    if target and target.get("health") != null and target.health <= 0:
        target = null; set_state(State.PATROL)
