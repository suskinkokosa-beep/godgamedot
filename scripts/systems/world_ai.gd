extends Node

var settlements := []

func create_settlement(pos, name="Settlement"):
    var s = {"name":name, "pos":pos, "population":3, "resources":{"wood":50, "stone":40}, "guards":[]}
    settlements.append(s)
    var house_scene = preload("res://scenes/buildings/foundation.tscn") if ResourceLoader.exists("res://scenes/buildings/foundation.tscn") else null
    for i in range(3):
        if house_scene:
            var h = house_scene.instantiate()
            add_child(h)
            h.global_transform.origin = pos + Vector3(i*3,0,0)

func _process(delta):
    for s in settlements:
        s.population += delta * 0.01
        if s.population > 5 and s.guards.size() < 2:
            var mob_scene = preload("res://scenes/mobs/mob_basic.tscn") if ResourceLoader.exists("res://scenes/mobs/mob_basic.tscn") else null
            if mob_scene:
                var mob = mob_scene.instantiate()
                add_child(mob)
                mob.global_transform.origin = s.pos + Vector3(2,0,2)
                s.guards.append(mob)
