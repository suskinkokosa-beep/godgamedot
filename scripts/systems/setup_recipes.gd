extends Node

func _ready():
    var cs = get_node("/root/CraftSystem")
    cs.register_recipe("wood_wall", {"wood":4}, "wall", 1, 0)
    cs.register_recipe("wood_floor", {"wood":3}, "floor", 1, 0)
    cs.register_recipe("wood_foundation", {"wood":6}, "foundation", 1, 0)
    cs.register_recipe("wood_door_frame", {"wood":5}, "door_frame", 1, 0)
