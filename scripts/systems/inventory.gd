extends Node
class_name Inventory
signal inventory_changed()
signal equip_changed()

var slots := [] # list of {id, count, weight}
var max_slots := 40
var max_weight := 80.0

# equipment: head, torso, legs, hands, feet, weapon, offhand, backpack
var equipment := {"head":null, "torso":null, "legs":null, "hands":null, "feet":null, "weapon":null, "offhand":null, "backpack":null}

func _ready():
    slots = []

func total_weight():
    var w = 0.0
    for s in slots:
        w += float(s.get("weight", 1.0)) * int(s.get("count",1))
    # equipment weight (if items add weight)
    for k in equipment.keys():
        var it = equipment[k]
        if it:
            w += float(it.get("weight",0.0))
    return w

func can_add(item_id, count=1, item_weight=1.0):
    if total_weight() + item_weight*count > max_weight:
        return false
    # try stacking
    for s in slots:
        if s.id == item_id:
            return true
    return slots.size() < max_slots

func add_item(item_id, count=1, weight=1.0):
    for s in slots:
        if s.id == item_id:
            s.count += count
            emit_signal("inventory_changed")
            return true
    if slots.size() < max_slots and total_weight() + weight*count <= max_weight:
        slots.append({"id":item_id, "count":count, "weight":weight})
        emit_signal("inventory_changed")
        return true
    return false

func remove_item(item_id, count=1):
    for s in slots:
        if s.id == item_id:
            s.count -= count
            if s.count <= 0:
                slots.erase(s)
            emit_signal("inventory_changed")
            return true
    return false

func has_item(item_id, count=1):
    for s in slots:
        if s.id == item_id and s.count >= count:
            return true
    return false

func get_items():
    return slots

# Equipment functions
func equip(slot_name:String, item:Dictionary) -> bool:
    if not equipment.has(slot_name):
        return false
    # if equipment slot occupied, unequip first (put back to inventory if space)
    if equipment[slot_name] != null:
        var prev = equipment[slot_name]
        if not add_item(prev.id, 1, prev.weight):
            return false # no space to unequip
    # remove item from inventory
    if not remove_item(item.id, 1):
        return false
    equipment[slot_name] = item
    emit_signal("equip_changed")
    return true

func unequip(slot_name:String) -> bool:
    if not equipment.has(slot_name): return false
    var it = equipment[slot_name]
    if it == null: return false
    if not add_item(it.id, 1, it.weight):
        return false
    equipment[slot_name] = null
    emit_signal("equip_changed")
    return true

func get_equipment():
    return equipment
