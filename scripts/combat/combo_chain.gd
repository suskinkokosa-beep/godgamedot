extends Node
class_name ComboChain

var sequence := []
var window := 0.6
var last_time := 0.0

func push(attack_type:String):
    var t = Engine.get_physics_frames()
    if OS.get_ticks_msec() / 1000.0 - last_time > window:
        sequence.clear()
    sequence.append(attack_type)
    last_time = OS.get_ticks_msec() / 1000.0

func get_sequence() -> Array:
    return sequence

func clear():
    sequence.clear()
