extends Node3D

@export var melee_damage := 10
@export var attack_range := 2.2
@export var attack_cooldown := 0.8

var can_attack := true

func attack():
    if not can_attack: return
    can_attack = false
    if has_node("AnimationPlayer"):
        $AnimationPlayer.play("swing") if $AnimationPlayer.has_animation("swing") else null
    _deal_melee()
    yield(get_tree().create_timer(attack_cooldown), "timeout")
    can_attack = true

func _deal_melee():
    var owner = get_parent()
    if not owner or not owner.has_node("Camera3D"): return
    var cam = owner.get_node("Camera3D")
    var from = cam.global_transform.origin
    var to = from + -cam.global_transform.basis.z * attack_range
    var space = get_world_3d().direct_space_state
    var res = space.intersect_ray(from, to, [owner], 1)
    if res:
        var target = res.collider
        if target and target.has_method("apply_damage"):
            target.apply_damage(melee_damage, owner)
