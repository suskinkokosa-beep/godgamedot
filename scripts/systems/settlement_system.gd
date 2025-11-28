extends Node
class_name SettlementSystem

signal settlement_created(id, name, position)

var settlements = {} # id -> {name, pos, population, resources: {}}
var next_id := 1

func create_settlement(name:String, pos:Vector3, initial_pop:int=4):
    var id = next_id
    next_id += 1
    settlements[id] = {"name":name, "pos":pos, "population":initial_pop, "resources":{}}
    emit_signal("settlement_created", id, name, pos)
    return id

func add_resource(settlement_id:int, resource_id:String, amount:int):
    if not settlements.has(settlement_id): return
    var s = settlements[settlement_id]
    s.resources[resource_id] = s.resources.get(resource_id, 0) + amount

func consume_resource(settlement_id:int, resource_id:String, amount:int) -> bool:
    if not settlements.has(settlement_id): return false
    var s = settlements[settlement_id]
    var have = s.resources.get(resource_id, 0)
    if have < amount: return false
    s.resources[resource_id] = have - amount
    return true

func get_settlement_info(id:int) -> Dictionary:
    return settlements.get(id, null)

func maintain_growth(delta):
    # simple growth: population increases if resources available
    for id in settlements.keys():
        var s = settlements[id]
        if s.resources.get("food",0) > s.population:
            s.population += int(clamp(s.population * 0.01 * delta, 0, 1))
