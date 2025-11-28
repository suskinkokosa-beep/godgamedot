extends Node

func _ready():
    var bs = get_node_or_null("/root/BiomeSystem")
    if bs:
        bs.add_biome("tundra", Vector3(-50,0,20), 40, -10.0)
        bs.add_biome("desert", Vector3(80,0,-30), 60, 30.0)
        bs.add_biome("mountain", Vector3(20,0,80), 50, 5.0)
        bs.add_biome("forest", Vector3(0,0,0), 120, 12.0)
