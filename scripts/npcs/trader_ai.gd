extends CharacterBody3D

var inventory := [{"id":"apple","price":3, "count":10}, {"id":"rope","price":8, "count":5}]
var market_pos := Vector3.ZERO

func _ready():
    add_to_group("traders")
    set_process(true)

func _process(delta):
    # simple wander near market
    if randf() < 0.01:
        var rnd = Vector3(randf_range(-3,3),0,randf_range(-3,3))
        translate(rnd * delta)

func on_interact(player):
    # open trade UI (assumes TradeWindow exists under UI root)
    var ui = get_node_or_null("/root/World/TradeWindow")
    if ui:
        ui.call("open_trade", self, player)
