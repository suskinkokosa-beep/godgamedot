extends CharacterBody3D

@export var speed := 6.0
@export var sprint_multiplier := 1.6
@export var mouse_sens := 0.12

var inventory = null
var combat = null
var camera = null

func _ready():
    Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
    camera = $Camera3D if has_node("Camera3D") else null
    inventory = get_node_or_null("/root/Inventory")
    combat = $Combat if has_node("Combat") else null
    add_to_group("players")

func _input(event):
    if event is InputEventMouseMotion and camera:
        rotate_y(deg_to_rad(-event.relative.x * mouse_sens))
        camera.rotate_x(deg_to_rad(-event.relative.y * mouse_sens))
        camera.rotation_degrees.x = clamp(camera.rotation_degrees.x, -85, 85)

func _physics_process(delta):
    var dir = Vector3.ZERO
    if Input.is_action_pressed("move_forward"): dir.z -= 1
    if Input.is_action_pressed("move_back"): dir.z += 1
    if Input.is_action_pressed("move_left"): dir.x -= 1
    if Input.is_action_pressed("move_right"): dir.x += 1

    var is_sprinting = Input.is_action_pressed("sprint") and not Input.is_action_pressed("crouch")
    var cur_speed = speed * (is_sprinting ? sprint_multiplier : 1)

    dir = (transform.basis * dir).normalized()
    velocity.x = dir.x * cur_speed
    velocity.z = dir.z * cur_speed

    if not is_on_floor():
        velocity.y -= 9.8 * delta

    move_and_slide()

func interact():
    if not camera: return
    var from = camera.global_transform.origin
    var to = from + -camera.global_transform.basis.z * 3.5
    var space = get_world_3d().direct_space_state
    var res = space.intersect_ray(from, to, [self], 1)
    if res:
        var obj = res.collider
        if obj and obj.has_method("gather"):
            obj.gather(self)
        elif obj and obj.has_method("on_interact"):
            obj.on_interact(self)
