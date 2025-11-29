extends Node

signal chunk_loaded(chunk_x: int, chunk_z: int)
signal chunk_unloaded(chunk_x: int, chunk_z: int)

@export var view_distance := 4
@export var structure_view_distance := 6
@export var unload_distance := 6
@export var chunks_per_frame := 2

var world_gen
var chunk_gen
var structure_gen

var player_ref: Node3D
var loaded_chunks := {}
var loaded_structures := {}
var pending_chunks := []
var chunk_parent: Node3D
var structure_parent: Node3D

var last_player_chunk := Vector2i(999999, 999999)

func _ready():
        call_deferred("_late_init")

func _late_init():
        world_gen = get_node_or_null("/root/WorldGenerator")
        chunk_gen = get_node_or_null("/root/ChunkGenerator")
        structure_gen = get_node_or_null("/root/StructureGenerator")
        
        if not world_gen or not chunk_gen:
                push_warning("WorldStreamer: Missing required autoloads (WorldGenerator/ChunkGenerator)")
                return
        
        chunk_parent = Node3D.new()
        chunk_parent.name = "Chunks"
        add_child(chunk_parent)
        
        structure_parent = Node3D.new()
        structure_parent.name = "Structures"
        add_child(structure_parent)
        
        _find_player()

func _find_player():
        var players = get_tree().get_nodes_in_group("players")
        if players.size() > 0:
                player_ref = players[0]

func _process(delta):
        if not player_ref:
                _find_player()
                return
        
        if not world_gen or not chunk_gen:
                return
        
        var player_pos = player_ref.global_position
        var chunk_x = int(floor(player_pos.x / WorldGenerator.CHUNK_SIZE))
        var chunk_z = int(floor(player_pos.z / WorldGenerator.CHUNK_SIZE))
        var current_chunk = Vector2i(chunk_x, chunk_z)
        
        if current_chunk != last_player_chunk:
                last_player_chunk = current_chunk
                _update_pending_chunks(chunk_x, chunk_z)
        
        _process_pending_chunks()
        _unload_distant_chunks(chunk_x, chunk_z)
        _update_structures(chunk_x, chunk_z)

func _update_pending_chunks(center_x: int, center_z: int):
        pending_chunks.clear()
        
        var chunks_to_load := []
        
        for dx in range(-view_distance, view_distance + 1):
                for dz in range(-view_distance, view_distance + 1):
                        var cx = center_x + dx
                        var cz = center_z + dz
                        var key = "%d_%d" % [cx, cz]
                        
                        if not loaded_chunks.has(key):
                                var dist = sqrt(dx * dx + dz * dz)
                                chunks_to_load.append({"x": cx, "z": cz, "dist": dist})
        
        chunks_to_load.sort_custom(func(a, b): return a["dist"] < b["dist"])
        
        for chunk_data in chunks_to_load:
                pending_chunks.append(Vector2i(chunk_data["x"], chunk_data["z"]))

func _process_pending_chunks():
        var processed = 0
        
        while pending_chunks.size() > 0 and processed < chunks_per_frame:
                var chunk_pos = pending_chunks.pop_front()
                _load_chunk(chunk_pos.x, chunk_pos.y)
                processed += 1

func _load_chunk(chunk_x: int, chunk_z: int):
        var key = "%d_%d" % [chunk_x, chunk_z]
        
        if loaded_chunks.has(key):
                return
        
        var chunk = chunk_gen.generate_chunk(chunk_x, chunk_z)
        if chunk:
                chunk_parent.add_child(chunk)
                loaded_chunks[key] = chunk
                emit_signal("chunk_loaded", chunk_x, chunk_z)

func _unload_distant_chunks(center_x: int, center_z: int):
        var to_remove := []
        
        for key in loaded_chunks.keys():
                var parts = key.split("_")
                var cx = int(parts[0])
                var cz = int(parts[1])
                
                var dx = abs(cx - center_x)
                var dz = abs(cz - center_z)
                
                if dx > unload_distance or dz > unload_distance:
                        to_remove.append(key)
        
        for key in to_remove:
                var chunk = loaded_chunks[key]
                if chunk and is_instance_valid(chunk):
                        chunk.queue_free()
                loaded_chunks.erase(key)
                
                var parts = key.split("_")
                emit_signal("chunk_unloaded", int(parts[0]), int(parts[1]))

func _update_structures(center_x: int, center_z: int):
        if not structure_gen or not world_gen:
                return
        
        for dx in range(-structure_view_distance, structure_view_distance + 1):
                for dz in range(-structure_view_distance, structure_view_distance + 1):
                        var cx = center_x + dx
                        var cz = center_z + dz
                        
                        var structures = world_gen.get_structures_in_chunk(cx, cz)
                        
                        for struct_data in structures:
                                var pos = struct_data["position"]
                                var key = "%d_%d" % [int(pos.x), int(pos.z)]
                                
                                if loaded_structures.has(key):
                                        continue
                                
                                var structure = structure_gen.generate_structure(struct_data["data"], pos)
                                if structure:
                                        structure_parent.add_child(structure)
                                        loaded_structures[key] = structure
        
        var to_remove := []
        
        for key in loaded_structures.keys():
                var parts = key.split("_")
                var sx = int(parts[0])
                var sz = int(parts[1])
                
                var chunk_x_struct = int(floor(sx / float(WorldGenerator.CHUNK_SIZE)))
                var chunk_z_struct = int(floor(sz / float(WorldGenerator.CHUNK_SIZE)))
                
                var dx = abs(chunk_x_struct - center_x)
                var dz = abs(chunk_z_struct - center_z)
                
                if dx > structure_view_distance + 2 or dz > structure_view_distance + 2:
                        to_remove.append(key)
        
        for key in to_remove:
                var structure = loaded_structures[key]
                if structure and is_instance_valid(structure):
                        structure.queue_free()
                loaded_structures.erase(key)

func get_loaded_chunk_count() -> int:
        return loaded_chunks.size()

func get_loaded_structure_count() -> int:
        return loaded_structures.size()

func force_reload():
        for key in loaded_chunks.keys():
                var chunk = loaded_chunks[key]
                if chunk and is_instance_valid(chunk):
                        chunk.queue_free()
        loaded_chunks.clear()
        
        for key in loaded_structures.keys():
                var structure = loaded_structures[key]
                if structure and is_instance_valid(structure):
                        structure.queue_free()
        loaded_structures.clear()
        
        last_player_chunk = Vector2i(999999, 999999)
