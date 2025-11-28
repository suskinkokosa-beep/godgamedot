extends Node
class_name FactionSystem

# Simple faction manager: track friendly/enemy relations
var factions = {} # name -> {relations: {other: relation_value}}

func create_faction(name:String):
    if factions.has(name): return
    factions[name] = {"relations":{}}

func set_relation(a:String, b:String, val:int):
    if not factions.has(a) or not factions.has(b): return
    factions[a].relations[b] = val

func get_relation(a:String, b:String) -> int:
    if not factions.has(a) or not factions.has(b): return 0
    return factions[a].relations.get(b, 0)

# relation values: -1 hostile, 0 neutral, 1 friendly
