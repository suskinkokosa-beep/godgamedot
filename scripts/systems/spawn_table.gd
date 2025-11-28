extends Node

# spawn definitions per biome: biome_name -> [{scene:"res://scenes/mobs/wolf.tscn", weight:10}, ...]
var tables = {}

func register_table(biome:String, table:Array):
    tables[biome] = table

func pick_for_biome(biome:String) -> String:
    if not tables.has(biome): return ""
    var t = tables[biome]
    var total = 0
    for e in t: total += e.weight
    var r = randi() % total
    var cur = 0
    for e in t:
        cur += e.weight
        if r < cur:
            return e.scene
    return ""
