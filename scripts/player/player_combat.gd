
extends Node
class_name PlayerCombatController

var is_blocking = false
var target_id = null

func do_light():
    if target_id != null:
        get_node("/root/CombatServer").do_light_attack(get_parent().net_id, target_id, is_blocking)

func do_heavy():
    if target_id != null:
        get_node("/root/CombatServer").do_heavy_attack(get_parent().net_id, target_id, is_blocking)

func block(on:bool):
    is_blocking = on
