extends Node

# Very simple biome mapping by position: define circular biomes
var biomes := [] # [{name, center:Vector3, radius, base_temp}]

func add_biome(name:String, center:Vector3, radius:float, base_temp:float):
    biomes.append({"name":name, "center":center, "radius":radius, "base_temp":base_temp})

func get_biome_at(pos:Vector3) -> Dictionary:
    for b in biomes:
        if pos.distance_to(b.center) <= b.radius:
            return b
    return {"name":"plains","base_temp":15.0}
