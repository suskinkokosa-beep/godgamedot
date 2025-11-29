extends Node3D

@export var leg_color := Color(0.3, 0.25, 0.2)
@export var boot_color := Color(0.2, 0.15, 0.1)
@export var walk_speed := 8.0
@export var run_speed := 12.0
@export var step_height := 0.15
@export var step_length := 0.3

var left_leg: Node3D = null
var right_leg: Node3D = null
var walk_time := 0.0
var is_moving := false
var is_running := false
var is_crouching := false

var left_foot_pos := Vector3.ZERO
var right_foot_pos := Vector3.ZERO
var base_left_pos := Vector3.ZERO
var base_right_pos := Vector3.ZERO

func _ready():
	_create_legs()
	
	base_left_pos = left_leg.position if left_leg else Vector3(-0.12, -0.8, 0.1)
	base_right_pos = right_leg.position if right_leg else Vector3(0.12, -0.8, 0.1)

func _create_legs():
	left_leg = Node3D.new()
	left_leg.name = "LeftLeg"
	add_child(left_leg)
	
	right_leg = Node3D.new()
	right_leg.name = "RightLeg"
	add_child(right_leg)
	
	_create_leg_mesh(left_leg, Vector3(-0.12, -0.8, 0.1))
	_create_leg_mesh(right_leg, Vector3(0.12, -0.8, 0.1))

func _create_leg_mesh(leg_node: Node3D, pos: Vector3):
	var thigh = MeshInstance3D.new()
	thigh.name = "Thigh"
	var thigh_mesh = CapsuleMesh.new()
	thigh_mesh.radius = 0.07
	thigh_mesh.height = 0.4
	thigh.mesh = thigh_mesh
	thigh.position = Vector3(0, 0.2, 0)
	
	var thigh_mat = StandardMaterial3D.new()
	thigh_mat.albedo_color = leg_color
	thigh_mat.roughness = 0.9
	thigh.material_override = thigh_mat
	
	var shin = MeshInstance3D.new()
	shin.name = "Shin"
	var shin_mesh = CapsuleMesh.new()
	shin_mesh.radius = 0.05
	shin_mesh.height = 0.35
	shin.mesh = shin_mesh
	shin.position = Vector3(0, -0.2, 0)
	
	var shin_mat = StandardMaterial3D.new()
	shin_mat.albedo_color = leg_color
	shin_mat.roughness = 0.9
	shin.material_override = shin_mat
	
	var foot = MeshInstance3D.new()
	foot.name = "Foot"
	var foot_mesh = BoxMesh.new()
	foot_mesh.size = Vector3(0.08, 0.06, 0.18)
	foot.mesh = foot_mesh
	foot.position = Vector3(0, -0.4, 0.04)
	
	var foot_mat = StandardMaterial3D.new()
	foot_mat.albedo_color = boot_color
	foot_mat.roughness = 0.95
	foot.material_override = foot_mat
	
	leg_node.add_child(thigh)
	leg_node.add_child(shin)
	leg_node.add_child(foot)
	leg_node.position = pos

func _process(delta):
	var player = get_parent()
	if player and player is CharacterBody3D:
		is_moving = player.velocity.length() > 0.5 and player.is_on_floor()
		is_running = is_moving and Input.is_action_pressed("sprint")
		
		if player.has_method("get_is_crouching"):
			is_crouching = player.get_is_crouching()
		elif player.get("is_crouching") != null:
			is_crouching = player.is_crouching
	
	if is_crouching:
		_process_crouch_pose(delta)
	elif is_moving:
		_process_walk_animation(delta)
	else:
		_process_idle(delta)

func _process_walk_animation(delta):
	var speed = run_speed if is_running else walk_speed
	walk_time += delta * speed
	
	var left_phase = sin(walk_time)
	var right_phase = sin(walk_time + PI)
	
	if left_leg:
		left_leg.position.z = base_left_pos.z + left_phase * step_length
		left_leg.position.y = base_left_pos.y + max(0, left_phase) * step_height
		left_leg.rotation_degrees.x = left_phase * 20.0
	
	if right_leg:
		right_leg.position.z = base_right_pos.z + right_phase * step_length
		right_leg.position.y = base_right_pos.y + max(0, right_phase) * step_height
		right_leg.rotation_degrees.x = right_phase * 20.0

func _process_idle(delta):
	walk_time = 0.0
	
	if left_leg:
		left_leg.position = left_leg.position.lerp(base_left_pos, 5.0 * delta)
		left_leg.rotation_degrees.x = lerp(left_leg.rotation_degrees.x, 0.0, 5.0 * delta)
	
	if right_leg:
		right_leg.position = right_leg.position.lerp(base_right_pos, 5.0 * delta)
		right_leg.rotation_degrees.x = lerp(right_leg.rotation_degrees.x, 0.0, 5.0 * delta)

func _process_crouch_pose(delta):
	var crouch_left_pos = base_left_pos + Vector3(0.05, 0.2, 0.15)
	var crouch_right_pos = base_right_pos + Vector3(-0.05, 0.2, 0.15)
	
	if left_leg:
		left_leg.position = left_leg.position.lerp(crouch_left_pos, 5.0 * delta)
		left_leg.rotation_degrees.x = lerp(left_leg.rotation_degrees.x, -45.0, 5.0 * delta)
	
	if right_leg:
		right_leg.position = right_leg.position.lerp(crouch_right_pos, 5.0 * delta)
		right_leg.rotation_degrees.x = lerp(right_leg.rotation_degrees.x, -45.0, 5.0 * delta)

func set_leg_visibility(visible_: bool):
	if left_leg:
		left_leg.visible = visible_
	if right_leg:
		right_leg.visible = visible_
