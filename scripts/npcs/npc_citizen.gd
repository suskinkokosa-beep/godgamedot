extends CharacterBody3D

@export var role := "citizen" # farmer, guard, trader, builder
var home_pos := Vector3.ZERO
var work_pos := Vector3.ZERO
var sleep_pos := Vector3.ZERO
var current_task := "idle"

func _ready():
    home_pos = global_transform.origin
    # roles can set work_pos externally
    add_to_group("npcs")
    set_process(true)

func _process(delta):
    # simple schedule based on GameManager time (day/night)
    var gm = get_node_or_null("/root/GameManager")
    var is_night = false
    if gm and gm.has_method("is_night"):
        is_night = gm.is_night()
    if is_night:
        _go_to_sleep(delta)
    else:
        if role == "farmer":
            _do_farming(delta)
        elif role == "guard":
            _do_patrol(delta)
        elif role == "trader":
            _do_trade(delta)
        else:
            _wander(delta)

func _go_to_sleep(delta):
    # simple sleep behavior: hide
    pass

func _do_farming(delta):
    # placeholder farming: occasionally add food to settlement
    if randf() < 0.005:
        var ss = get_node_or_null("/root/SettlementSystem")
        if ss:
            var sid = ss.create_settlement("FarmCamp", global_transform.origin, 2)
            ss.add_resource(sid, "food", 1)

func _do_patrol(delta):
    # guard patrol around home_pos
    if randf() < 0.02:
        var rnd = Vector3(randf_range(-6,6),0,randf_range(-6,6))
        translate(rnd * delta)

func _do_trade(delta):
    # traders wander near market
    if randf() < 0.01:
        var rnd = Vector3(randf_range(-4,4),0,randf_range(-4,4))
        translate(rnd * delta)

func _wander(delta):
    if randf() < 0.01:
        var rnd = Vector3(randf_range(-8,8),0,randf_range(-8,8))
        translate(rnd * delta)
