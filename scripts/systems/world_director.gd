extends Node
class_name WorldDirector

# simple director: spawns mobs around points, maintains settlement spawns and factions

@export var spawn_points := [Vector3(5,0,5), Vector3(-10,0,8)]
@export var spawn_interval := 12.0
var spawn_timer := 0.0

func _process(delta):
    if not get_tree().is_network_server():
        return
    spawn_timer += delta
    if spawn_timer >= spawn_interval:
        spawn_timer = 0.0
        for p in spawn_points:
            _spawn_mob(p)

func _spawn_mob(pos:Vector3):
    var scene = ResourceLoader.load("res://scenes/mobs/mob_basic.tscn")
    if not scene:
        return
    var inst = scene.instantiate()
    add_child(inst)
    inst.global_transform.origin = pos
    # set random faction
    var fs = get_node_or_null("/root/FactionSystem")
    if fs:
        fs.create_faction("wild")
        inst.set_meta("faction", "wild")

# Use SpawnTable to pick mobs by biome
func _spawn_mob(pos:Vector3):
    var st = get_node_or_null("/root/SpawnTable")
    var biome = "plains"
    var bs = get_node_or_null("/root/BiomeSystem")
    if bs:
        var b = bs.get_biome_at(pos)
        biome = b.name if b.has("name") else biome
    var scene_path = st.pick_for_biome(biome) if st else ""
    if scene_path == "":
        scene_path = "res://scenes/mobs/mob_basic.tscn"
    var scene = ResourceLoader.load(scene_path)
    if not scene: return
    var inst = scene.instantiate()
    add_child(inst)
    inst.global_transform.origin = pos
