extends Node3D
class_name BaseAI

enum State { IDLE, PATROL, CHASE, ATTACK, FLEE, SLEEP, WORK }

var state = State.IDLE
var target = null
var last_state_change = 0.0

func set_state(s):
    state = s
    last_state_change = Engine.get_physics_frames()

func _process(delta):
    match state:
        State.IDLE:
            _on_idle(delta)
        State.PATROL:
            _on_patrol(delta)
        State.CHASE:
            _on_chase(delta)
        State.ATTACK:
            _on_attack(delta)
        State.FLEE:
            _on_flee(delta)
        State.SLEEP:
            _on_sleep(delta)
        State.WORK:
            _on_work(delta)

func _on_idle(delta): pass
func _on_patrol(delta): pass
func _on_chase(delta): pass
func _on_attack(delta): pass
func _on_flee(delta): pass
func _on_sleep(delta): pass
func _on_work(delta): pass
