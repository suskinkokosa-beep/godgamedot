extends HBoxContainer

onready var slots = []

func _ready():
    for i in range(8):
        var node_name = "Slot" + str(i)
        if has_node(node_name):
            slots.append(get_node(node_name))
        else:
            slots.append(null)

func use_slot(index):
    var slot = slots[index]
    if not slot: return
    var item_id = slot.get_meta("item_id")
    if not item_id: return
    var net = get_node_or_null("/root/Network")
    if net:
        rpc_id(1, "rpc_request_inventory_update", "remove", item_id, 1)
        # server could add effect, e.g., equip or use
    else:
        var inv = get_node_or_null("/root/Inventory")
        if inv:
            inv.remove_item(item_id, 1)
