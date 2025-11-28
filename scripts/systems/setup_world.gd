extends Node

func _ready():
    var rg = get_node_or_null("/root/World/ResourceGenerator")
    if rg:
        rg.generate()
    var ss = get_node_or_null("/root/SettlementSystem")
    if ss:
        ss.create_settlement("Starter Village", Vector3(0,0,0), 6)
