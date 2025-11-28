
extends Control
class_name InventoryUI

var slots = []
var selected_slot = -1

func _ready():
    slots = $GridContainer.get_children()

func set_items(items:Array):
    for i in range(len(slots)):
        if i < len(items):
            slots[i].set_item(items[i])
        else:
            slots[i].clear()

func _on_slot_dragged(from_idx, to_idx):
    get_tree().call_group("player", "swap_inventory_items", from_idx, to_idx)
