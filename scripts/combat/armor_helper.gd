extends Node
class_name ArmorHelper

# Expected to be attached to character nodes as child or autoloaded to provide calculations
# armor_data expected: {"head":value, "body":value, "legs":value}
func get_armor_value_for(actor, zone:String) -> float:
    if not actor: return 0.0
    if actor.has_method("get_armor_value"):
        return actor.get_armor_value(zone)
    # try actor.armor dictionary
    if actor.has_variable("armor"):
        var a = actor.armor
        return a.get(zone, 0.0)
    return 0.0
