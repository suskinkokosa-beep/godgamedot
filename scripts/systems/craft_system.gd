extends Node
class_name CraftSystem

var recipes = {}

func register_recipe(id:String, inputs:Dictionary, output:String, amount:int=1, tier:int=0):
    recipes[id] = {
        "inputs": inputs,
        "output": output,
        "amount": amount,
        "tier": tier
    }

func can_craft(inv, id:String, workbench_tier:int) -> bool:
    if not recipes.has(id): return false
    var r = recipes[id]
    if workbench_tier < r.tier: return false
    for k in r.inputs.keys():
        if inv.get_count(k) < r.inputs[k]:
            return false
    return true

func craft(inv, id:String, workbench_tier:int) -> bool:
    if not can_craft(inv, id, workbench_tier): return false
    var r = recipes[id]
    for k in r.inputs.keys():
        inv.remove_item(k, r.inputs[k])
    inv.add_item(r.output, r.amount, 1.0)
    return true
