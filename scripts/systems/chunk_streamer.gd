extends Node

@export var view_distance_chunks := 3

var generated = {}
var player_ref = null
var terrain_gen = null

func _ready():
    call_deferred("_late_init")

func _late_init():
    terrain_gen = get_node_or_null("/root/TerrainGenerator")
    _find_player()

func _find_player():
    var players = get_tree().get_nodes_in_group("players")
    if players.size() > 0:
        player_ref = players[0]

func _process(delta):
    if not player_ref:
        _find_player()
        return
    if not terrain_gen or not terrain_gen.is_setup:
        terrain_gen = get_node_or_null("/root/TerrainGenerator")
        return
    var px = int(round(player_ref.global_transform.origin.x))
    var pz = int(round(player_ref.global_transform.origin.z))
    var cx = int(floor(px / float(terrain_gen.chunk_size)))
    var cz = int(floor(pz / float(terrain_gen.chunk_size)))
    var keys = []
    for dx in range(-view_distance_chunks, view_distance_chunks + 1):
        for dz in range(-view_distance_chunks, view_distance_chunks + 1):
            var nx = cx + dx
            var nz = cz + dz
            var key = "%d_%d" % [nx, nz]
            keys.append(key)
            if not generated.has(key):
                var ch = terrain_gen.generate_chunk(nx, nz)
                if ch:
                    generated[key] = ch
    for k in generated.keys():
        if k in keys:
            continue
        var node = generated[k]
        if node and is_instance_valid(node):
            node.queue_free()
        generated.erase(k)
