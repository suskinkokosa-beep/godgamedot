extends CharacterBody3D

@export var speed := 5.0
@export var sprint_multiplier := 1.4
@export var crouch_multiplier := 0.6
@export var mouse_sens := 0.06
@export var gravity := 20.0
@export var jump_force := 8.0
@export var acceleration := 12.0
@export var deceleration := 16.0
@export var friction := 8.0
@export var camera_smoothing := 0.15

var inventory = null
var combat = null
var camera: Camera3D = null
var health := 100.0
var max_health := 100.0
var stamina := 100.0
var max_stamina := 100.0

var target_velocity := Vector3.ZERO
var camera_yaw := 0.0
var camera_pitch := 0.0
var target_yaw := 0.0
var target_pitch := 0.0

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	camera = get_node_or_null("Camera3D")
	inventory = get_node_or_null("/root/Inventory")
	combat = get_node_or_null("Combat")
	add_to_group("players")
	
	var gm = get_node_or_null("/root/GameManager")
	if gm and gm.get("mouse_sensitivity") != null:
		mouse_sens = gm.mouse_sensitivity
	
	var ss = get_node_or_null("/root/StatsSystem")
	if ss:
		ss.create_player(1)

func _input(event):
	if event is InputEventMouseMotion and camera:
		target_yaw -= event.relative.x * mouse_sens
		target_pitch -= event.relative.y * mouse_sens
		target_pitch = clamp(target_pitch, -85.0, 85.0)
	
	if event.is_action_pressed("attack"):
		_attack()
	
	if event.is_action_pressed("interact"):
		interact()

func _physics_process(delta):
	var input_dir = Vector3.ZERO
	
	if Input.is_action_pressed("move_forward"):
		input_dir.z -= 1
	if Input.is_action_pressed("move_back"):
		input_dir.z += 1
	if Input.is_action_pressed("move_left"):
		input_dir.x -= 1
	if Input.is_action_pressed("move_right"):
		input_dir.x += 1
	
	camera_yaw = lerp_angle(deg_to_rad(camera_yaw), deg_to_rad(target_yaw), camera_smoothing)
	camera_pitch = lerp(camera_pitch, target_pitch, camera_smoothing)
	camera_yaw = rad_to_deg(camera_yaw)
	
	rotation.y = deg_to_rad(target_yaw)
	if camera:
		camera.rotation.x = deg_to_rad(camera_pitch)
	
	var is_sprinting = Input.is_action_pressed("sprint") and not Input.is_action_pressed("crouch") and stamina > 5
	var is_crouching = Input.is_action_pressed("crouch")
	
	var speed_mult = 1.0
	if is_sprinting:
		speed_mult = sprint_multiplier
		stamina -= 15.0 * delta
	elif is_crouching:
		speed_mult = crouch_multiplier
	
	var cur_speed = speed * speed_mult
	
	var direction = (transform.basis * input_dir).normalized()
	
	if direction != Vector3.ZERO:
		target_velocity.x = direction.x * cur_speed
		target_velocity.z = direction.z * cur_speed
	else:
		target_velocity.x = 0
		target_velocity.z = 0
	
	if is_on_floor():
		if direction != Vector3.ZERO:
			velocity.x = move_toward(velocity.x, target_velocity.x, acceleration * delta * cur_speed)
			velocity.z = move_toward(velocity.z, target_velocity.z, acceleration * delta * cur_speed)
		else:
			velocity.x = move_toward(velocity.x, 0, friction * delta * speed)
			velocity.z = move_toward(velocity.z, 0, friction * delta * speed)
	else:
		velocity.x = move_toward(velocity.x, target_velocity.x, acceleration * 0.3 * delta * cur_speed)
		velocity.z = move_toward(velocity.z, target_velocity.z, acceleration * 0.3 * delta * cur_speed)
	
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	move_and_slide()
	
	if not is_sprinting:
		stamina = min(max_stamina, stamina + 8.0 * delta)

func _attack():
	if stamina < 10:
		return
	stamina -= 10
	
	if not camera:
		return
	
	var from = camera.global_position
	var to = from - camera.global_basis.z * 3.0
	var space = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [self]
	var result = space.intersect_ray(query)
	
	if result:
		var target = result.collider
		if target and target.has_method("apply_damage"):
			target.apply_damage(15, self)

func interact():
	if not camera:
		return
	
	var from = camera.global_position
	var to = from - camera.global_basis.z * 3.5
	var space = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [self]
	var result = space.intersect_ray(query)
	
	if result:
		var obj = result.collider
		if obj and obj.has_method("gather"):
			obj.gather(self)
		elif obj and obj.has_method("on_interact"):
			obj.on_interact(self)

func apply_damage(amount: float, source):
	health -= amount
	if health <= 0:
		_die()

func _die():
	health = max_health
	global_position = Vector3(0, 2, 0)

func get_health() -> float:
	return health

func set_mouse_sensitivity(value: float):
	mouse_sens = clamp(value, 0.01, 0.2)
