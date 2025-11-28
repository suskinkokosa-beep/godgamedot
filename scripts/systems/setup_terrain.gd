extends Node

func _ready():
    var sm = get_node_or_null("/root/SeedManager")
    var tg = get_node_or_null("/root/TerrainGenerator")
    var cs = get_node_or_null("/root/ChunkStreamer")
    if sm and tg:
        var s = sm.get_seed()
        if s == 0:
            s = randi()
            sm.set_seed(s)
        tg.setup(s)
    if cs:
        # ensure it will find players later
        pass
