extends Node3D
class_name NetworkInterpolator

var server_pos = Vector3.ZERO
var server_vel = Vector3.ZERO
var smooth_speed := 10.0

func set_server_state(pos:Vector3, vel:Vector3):
    server_pos = pos
    server_vel = vel

func _physics_process(delta):
    # smooth interpolate towards server_pos
    global_transform.origin = global_transform.origin.lerp(server_pos, clamp(smooth_speed * delta, 0, 1))
