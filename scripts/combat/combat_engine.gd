extends Node
class_name CombatEngine

# Central combat engine. Should run on server for authoritative checks.
# Emits signals for events (hit, kill, crit)

signal hit_registered(attacker_id, target_id, damage, zone)
signal actor_killed(target_id, killer_id)

# Damage calculation considering weapon, armor, criticals. All numbers illustrative.
func calculate_damage(attacker, target, weapon:Dictionary, zone:String) -> float:
    var base = (weapon.get("damage_min",10) + weapon.get("damage_max",15)) * 0.5
    # zone multipliers
    var zone_mul = 1.0
    match zone:
        "head": zone_mul = 2.0
        "legs": zone_mul = 0.7
        _: zone_mul = 1.0
    var dmg = base * zone_mul
    # critical roll
    var crit_chance = weapon.get("critical_chance", 0.05)
    if randf() < crit_chance:
        dmg *= weapon.get("critical_multiplier", 1.5)
    # armor mitigation: target expected to have "armor" dictionary with parts
    var armor = target.get("armor", {}) if target and typeof(target) == TYPE_OBJECT == false else null
    # in Godot objects we'll expect target has method get_armor_value(zone) - fallback simple
    var armor_val = 0.0
    if target and target.has_method("get_armor_value"):
        armor_val = target.get_armor_value(zone)
    else:
        armor_val = 0.0
    # armor reduces damage by percent up to 80%
    var mitigation = clamp(armor_val / 100.0, 0.0, 0.8)
    dmg = dmg * (1.0 - mitigation)
    return max(0.0, dmg)

func register_hit(attacker_node, target_node, weapon:Dictionary, zone:String):
    # server should call calculate, apply damage and emit signals
    var attacker_id = attacker_node.get("net_id") if attacker_node and attacker_node.has_variable("net_id") else -1
    var target_id = target_node.get("net_id") if target_node and target_node.has_variable("net_id") else -1
    var dmg = calculate_damage(attacker_node, target_node, weapon, zone)
    if target_node and target_node.has_method("apply_damage"):
        target_node.apply_damage(dmg, attacker_node)
        emit_signal("hit_registered", attacker_id, target_id, dmg, zone)
        # check death
        if target_node.has_variable("health") and target_node.health <= 0:
            emit_signal("actor_killed", target_id, attacker_id)
