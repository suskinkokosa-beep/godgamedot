extends CharacterBody3D

@export var name := "Trader"
var inventory := []

func _ready():
    add_to_group("npcs")
    # sample goods
    inventory = [{"id":"apple","price":3},{"id":"rope","price":8},{"id":"arrow","price":1}]

func on_interact(player):
    # open trade UI - locate UI node
    var ui = get_tree().get_root().get_node("/root/World/UI") if get_tree().get_root().has_node("World") else null
    if ui and ui.has_node("TradeWindow"):
        ui.get_node("TradeWindow").call("open_trade", self, player)

func apply_damage(amount, source):
    # traders flee when attacked
    queue_free()
