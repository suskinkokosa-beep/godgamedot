extends Node
class_name ChunkStreamer

@export var view_distance_chunks := 3

var generated = {} # key 'x_z' -> Node
var player_ref = null
var terrain_gen = null

func _ready():
    terrain_gen = get_node_or_null("/root/TerrainGenerator")
    player_ref = get_tree().get_nodes_in_group("players")[0] if get_tree().get_nodes_in_group("players").size() > 0 else null

func _process(delta):
    if not player_ref or not terrain_gen:
        return
    var px = int(round(player_ref.global_transform.origin.x))
    var pz = int(round(player_ref.global_transform.origin.z))
    var cx = int(floor(px / float(terrain_gen.chunk_size)))
    var cz = int(floor(pz / float(terrain_gen.chunk_size)))
    # ensure chunks within view_distance are generated
    var keys = []
    for dx in range(-view_distance_chunks, view_distance_chunks+1):
        for dz in range(-view_distance_chunks, view_distance_chunks+1):
            var nx = cx + dx
            var nz = cz + dz
            var key = "%d_%d" % [nx, nz]
            keys.append(key)
            if not generated.has(key):
                var ch = terrain_gen.generate_chunk(nx, nz)
                generated[key] = ch
    # cleanup distant chunks
    for k in generated.keys():
        if k in keys:
            continue
        var node = generated[k]
        if node and is_instance_valid(node):
            node.queue_free()
        generated.erase(k)
