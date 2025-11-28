extends Area3D
class_name HitboxZone

@export var zone_name := "body" # head/body/arms/legs
# owner is character node that this hitbox belongs to
var owner = null

func _ready():
    connect("body_entered", Callable(self, "_on_body_entered"))

func _on_body_entered(body):
    # Expect body to be a Projectile or WeaponHit with metadata about attacker and weapon
    if not body: return
    if body.has_method("get_hit_info"):
        var info = body.get_hit_info()
        var attacker = info.get("attacker")
        var weapon = info.get("weapon")
        var engine = get_node_or_null("/root/CombatEngine")
        if engine:
            engine.register_hit(attacker, owner, weapon, zone_name)
