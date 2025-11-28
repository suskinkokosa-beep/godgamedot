extends Area3D
class_name AttackHit

var attacker = null
var weapon = {}
var duration = 0.25
var active = false

func _ready():
    set_physics_process(true)
    $CollisionShape3D.disabled = true
    # auto-activate shortly after created to allow positioning before collision checks
    call_deferred("activate")

func activate():
    active = true
    $CollisionShape3D.disabled = false
    # schedule removal after duration
    await get_tree().create_timer(duration).timeout
    queue_free()

func get_hit_info() -> Dictionary:
    return {"attacker": attacker, "weapon": weapon}

func _on_body_entered(body):
    # if collides with a HitboxZone, the HitboxZone will call engine; we still can forward if needed
    pass
