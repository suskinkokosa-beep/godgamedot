extends StaticBody3D
class_name ResourceNode

@export var resource_id := "wood"
@export var amount := 10
@export var respawn_time := 60.0

var depleted := false

func gather(amount_requested:int) -> int:
    if depleted: return 0
    var taken = min(amount, amount_requested)
    amount -= taken
    if amount <= 0:
        _on_depleted()
    return taken

func _on_depleted():
    depleted = true
    hide()
    set_physics_process(false)
    # schedule respawn
    var t = get_tree().create_timer(respawn_time)
    t.connect("timeout", Callable(self, "_respawn"))

func _respawn():
    amount = 10
    depleted = false
    show()
    set_physics_process(true)
