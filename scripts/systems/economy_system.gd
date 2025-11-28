extends Node
class_name EconomySystem

var base_prices = {"wood":2, "stone":3, "food":1}
var global_supply = {} # resource -> amount

func report_supply(resource_id:String, amount:int):
    global_supply[resource_id] = global_supply.get(resource_id,0) + amount

func get_price(resource_id:String) -> float:
    var base = base_prices.get(resource_id, 1.0)
    var supply = global_supply.get(resource_id, 0)
    # price rises if supply low, falls if high (simple formula)
    return max(0.1, base * (1.0 + 0.5 / (1 + supply)))
