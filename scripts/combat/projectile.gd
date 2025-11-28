extends Area3D
class_name Projectile

var speed := 30.0
var direction := Vector3.ZERO
var lifetime := 6.0
var attacker = null
var weapon = {}
var distance_traveled := 0.0

func _physics_process(delta):
    var move = direction.normalized() * speed * delta
    translate(move)
    distance_traveled += move.length()
    lifetime -= delta
    if lifetime <= 0:
        queue_free()

func get_hit_info() -> Dictionary:
    return {"attacker": attacker, "weapon": weapon}

func _on_body_entered(body):
    # if collides with hitbox, CombatEngine will register damage via HitboxZone
    queue_free()
