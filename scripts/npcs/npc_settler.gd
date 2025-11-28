extends CharacterBody3D
class_name NPCSettler

@export var carry_capacity := 10
var carrying := {} # resource_id -> amount
var settlement_id := -1

func _ready():
    add_to_group("npcs")

func find_nearest_settlement() -> int:
    var ss = get_node_or_null("/root/SettlementSystem")
    if not ss: return -1
    var best = -1
    var bd = 1e9
    for id in ss.settlements.keys():
        var s = ss.settlements[id]
        var d = global_transform.origin.distance_to(s.pos)
        if d < bd:
            bd = d; best = id
    return best

func deposit_all():
    if settlement_id == -1:
        settlement_id = find_nearest_settlement()
    if settlement_id == -1: return
    var ss = get_node_or_null("/root/SettlementSystem")
    for r in carrying.keys():
        ss.add_resource(settlement_id, r, carrying[r])
    carrying.clear()

func gather_and_return(resource_node):
    # pick up from a resource node, then return to settlement
    var taken = resource_node.gather( min(carry_capacity, resource_node.amount) )
    carrying[resource_node.resource_id] = carrying.get(resource_node.resource_id,0) + taken
    deposit_all()
