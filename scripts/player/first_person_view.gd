extends Node3D

signal item_equipped(item_id: String)
signal item_unequipped()
signal attack_started()
signal attack_finished()
signal action_started(action_name: String)
signal action_finished(action_name: String)

enum HandState { IDLE, WALK, RUN, ATTACK, GATHER, USE_ITEM, BLOCK, RELOAD }

@export_category("Внешность рук")
@export var skin_color := Color(0.87, 0.72, 0.62)
@export var sleeve_color := Color(0.35, 0.32, 0.28)

@export_category("Позиционирование")
@export var base_position := Vector3(0, -0.25, -0.35)
@export var right_arm_offset := Vector3(0.22, 0, 0)
@export var left_arm_offset := Vector3(-0.22, 0, 0)

@export_category("Анимация движения")
@export var sway_amount := 0.025
@export var sway_speed := 6.0
@export var bob_amount := Vector2(0.018, 0.015)
@export var bob_speed := 8.0
@export var run_bob_multiplier := 1.5

@export_category("Анимация атаки")
@export var swing_speed := 7.0
@export var swing_arc := 75.0
@export var swing_forward := 0.15

var current_state := HandState.IDLE
var current_item_id: String = ""
var current_item_mesh: Node3D = null

var right_arm: Node3D = null
var left_arm: Node3D = null
var item_holder: Node3D = null

var anim_time := 0.0
var swing_progress := 0.0
var is_attacking := false

var sway_offset := Vector3.ZERO
var bob_offset := Vector3.ZERO
var target_sway := Vector3.ZERO
var move_time := 0.0

var velocity := Vector3.ZERO
var is_grounded := true
var is_running := false

var skin_material: StandardMaterial3D = null
var sleeve_material: StandardMaterial3D = null

var inventory = null
var item_database := {}

func _ready():
	_create_materials()
	_build_arms()
	
	inventory = get_node_or_null("/root/Inventory")
	if inventory:
		if inventory.has_signal("hotbar_changed"):
			inventory.connect("hotbar_changed", Callable(self, "_on_hotbar_changed"))
	
	call_deferred("_update_held_item")

func _create_materials():
	skin_material = StandardMaterial3D.new()
	skin_material.albedo_color = skin_color
	skin_material.roughness = 0.72
	skin_material.metallic = 0.0
	skin_material.diffuse_mode = BaseMaterial3D.DIFFUSE_BURLEY
	skin_material.specular_mode = BaseMaterial3D.SPECULAR_SCHLICK_GGX
	
	sleeve_material = StandardMaterial3D.new()
	sleeve_material.albedo_color = sleeve_color
	sleeve_material.roughness = 0.85

func _build_arms():
	position = base_position
	
	right_arm = Node3D.new()
	right_arm.name = "RightArm"
	add_child(right_arm)
	_create_detailed_arm(right_arm, right_arm_offset, false)
	
	left_arm = Node3D.new()
	left_arm.name = "LeftArm"
	add_child(left_arm)
	_create_detailed_arm(left_arm, left_arm_offset, true)
	
	item_holder = Node3D.new()
	item_holder.name = "ItemHolder"
	item_holder.position = Vector3(0.02, 0.12, -0.08)
	right_arm.add_child(item_holder)

func _create_detailed_arm(arm_node: Node3D, offset: Vector3, is_left: bool):
	arm_node.position = offset
	
	var upper_arm = Node3D.new()
	upper_arm.name = "UpperArm"
	upper_arm.position = Vector3(0, 0.08, -0.05)
	arm_node.add_child(upper_arm)
	
	var upper_mesh = MeshInstance3D.new()
	upper_mesh.name = "UpperArmMesh"
	var upper_capsule = CapsuleMesh.new()
	upper_capsule.radius = 0.045
	upper_capsule.height = 0.22
	upper_mesh.mesh = upper_capsule
	upper_mesh.rotation_degrees = Vector3(75, 0, 0)
	upper_mesh.material_override = sleeve_material
	upper_arm.add_child(upper_mesh)
	
	var elbow = Node3D.new()
	elbow.name = "Elbow"
	elbow.position = Vector3(0, -0.08, -0.12)
	upper_arm.add_child(elbow)
	
	var forearm = Node3D.new()
	forearm.name = "Forearm"
	forearm.position = Vector3(0, 0, 0)
	elbow.add_child(forearm)
	
	var forearm_mesh = MeshInstance3D.new()
	forearm_mesh.name = "ForearmMesh"
	var forearm_capsule = CapsuleMesh.new()
	forearm_capsule.radius = 0.038
	forearm_capsule.height = 0.25
	forearm_mesh.mesh = forearm_capsule
	forearm_mesh.rotation_degrees = Vector3(90, 0, 0)
	forearm_mesh.position = Vector3(0, 0, -0.12)
	forearm_mesh.material_override = skin_material
	forearm.add_child(forearm_mesh)
	
	var wrist = Node3D.new()
	wrist.name = "Wrist"
	wrist.position = Vector3(0, 0, -0.25)
	forearm.add_child(wrist)
	
	_create_detailed_hand(wrist, is_left)

func _create_detailed_hand(wrist: Node3D, is_left: bool):
	var hand = Node3D.new()
	hand.name = "Hand"
	wrist.add_child(hand)
	
	var palm = MeshInstance3D.new()
	palm.name = "Palm"
	var palm_mesh = BoxMesh.new()
	palm_mesh.size = Vector3(0.075, 0.095, 0.03)
	palm.mesh = palm_mesh
	palm.position = Vector3(0, 0, -0.05)
	palm.material_override = skin_material
	hand.add_child(palm)
	
	var knuckles = MeshInstance3D.new()
	knuckles.name = "Knuckles"
	var knuckle_mesh = BoxMesh.new()
	knuckle_mesh.size = Vector3(0.07, 0.025, 0.025)
	knuckles.mesh = knuckle_mesh
	knuckles.position = Vector3(0, -0.055, -0.05)
	knuckles.material_override = skin_material
	hand.add_child(knuckles)
	
	var fingers_config = [
		{"name": "Index", "x": -0.022, "length": 0.065, "radius": 0.009},
		{"name": "Middle", "x": -0.007, "length": 0.072, "radius": 0.0095},
		{"name": "Ring", "x": 0.008, "length": 0.065, "radius": 0.009},
		{"name": "Pinky", "x": 0.023, "length": 0.052, "radius": 0.0075}
	]
	
	for config in fingers_config:
		var finger = _create_realistic_finger(config["length"], config["radius"], 3)
		finger.name = config["name"]
		finger.position = Vector3(config["x"], -0.068, -0.05)
		finger.rotation_degrees = Vector3(15, 0, 0)
		hand.add_child(finger)
	
	var thumb = _create_realistic_finger(0.048, 0.011, 2)
	thumb.name = "Thumb"
	var thumb_x = -0.04 if is_left else 0.04
	thumb.position = Vector3(thumb_x, -0.015, -0.035)
	thumb.rotation_degrees = Vector3(10, 0, -55 if is_left else 55)
	hand.add_child(thumb)

func _create_realistic_finger(length: float, base_radius: float, segments: int) -> Node3D:
	var root = Node3D.new()
	var seg_length = length / segments
	var current_parent = root
	
	for i in range(segments):
		var joint = Node3D.new()
		joint.name = "Joint" + str(i)
		current_parent.add_child(joint)
		
		var seg = MeshInstance3D.new()
		seg.name = "Segment" + str(i)
		var capsule = CapsuleMesh.new()
		capsule.radius = base_radius * (1.0 - i * 0.12)
		capsule.height = seg_length * 0.95
		seg.mesh = capsule
		seg.position = Vector3(0, -seg_length * 0.5, 0)
		seg.material_override = skin_material
		joint.add_child(seg)
		
		if i < segments - 1:
			var next_joint = Node3D.new()
			next_joint.name = "NextJoint"
			next_joint.position = Vector3(0, -seg_length, 0)
			joint.add_child(next_joint)
			current_parent = next_joint
	
	return root

func _on_hotbar_changed():
	_update_held_item()

func _update_held_item():
	if not inventory:
		return
	
	var selected = 0
	if inventory.has_method("get_selected_hotbar_slot"):
		selected = inventory.get_selected_hotbar_slot()
	elif inventory.get("selected_hotbar_slot") != null:
		selected = inventory.selected_hotbar_slot
	
	var item = null
	if inventory.has_method("get_hotbar_slot"):
		item = inventory.get_hotbar_slot(selected)
	
	if item == null or not item is Dictionary or not item.has("id"):
		_unequip_current_item()
		return
	
	var item_id = item["id"]
	if item_id != current_item_id:
		_equip_item(item_id)

func _equip_item(item_id: String):
	_unequip_current_item()
	current_item_id = item_id
	
	var mesh = _create_item_model(item_id)
	if mesh:
		item_holder.add_child(mesh)
		current_item_mesh = mesh
	
	emit_signal("item_equipped", item_id)

func _create_item_model(item_id: String) -> Node3D:
	var root = Node3D.new()
	root.name = "ItemModel"
	
	var info = null
	if inventory and inventory.has_method("get_item_info"):
		info = inventory.get_item_info(item_id)
	
	var item_type = "misc"
	if info:
		item_type = info.get("type", "misc")
	
	var mesh = MeshInstance3D.new()
	mesh.name = "ItemMesh"
	
	var material = StandardMaterial3D.new()
	material.roughness = 0.7
	
	match item_type:
		"weapon":
			if item_id.contains("sword"):
				mesh.mesh = _create_sword_mesh()
				material.albedo_color = Color(0.7, 0.7, 0.75)
				material.metallic = 0.6
			elif item_id.contains("axe"):
				mesh.mesh = _create_axe_mesh()
				material.albedo_color = Color(0.5, 0.5, 0.55)
				material.metallic = 0.4
			elif item_id.contains("bow"):
				mesh.mesh = _create_bow_mesh()
				material.albedo_color = Color(0.45, 0.32, 0.18)
			else:
				var box = BoxMesh.new()
				box.size = Vector3(0.04, 0.04, 0.3)
				mesh.mesh = box
				material.albedo_color = Color(0.5, 0.4, 0.3)
		"tool":
			if item_id.contains("pickaxe"):
				mesh.mesh = _create_pickaxe_mesh()
				material.albedo_color = Color(0.5, 0.5, 0.55)
				material.metallic = 0.4
			elif item_id.contains("axe"):
				mesh.mesh = _create_axe_mesh()
				material.albedo_color = Color(0.5, 0.5, 0.55)
				material.metallic = 0.4
			else:
				var box = BoxMesh.new()
				box.size = Vector3(0.03, 0.03, 0.25)
				mesh.mesh = box
				material.albedo_color = Color(0.4, 0.3, 0.2)
		"food", "drink":
			var sphere = SphereMesh.new()
			sphere.radius = 0.04
			sphere.height = 0.07
			mesh.mesh = sphere
			material.albedo_color = Color(0.75, 0.55, 0.35)
		"light":
			mesh.mesh = _create_torch_mesh()
			material.albedo_color = Color(0.4, 0.28, 0.14)
			
			if item_id == "torch":
				var flame_light = OmniLight3D.new()
				flame_light.name = "FlameLight"
				flame_light.light_color = Color(1.0, 0.7, 0.35)
				flame_light.light_energy = 1.8
				flame_light.omni_range = 6.0
				flame_light.position = Vector3(0, 0.18, 0)
				root.add_child(flame_light)
		_:
			var box = BoxMesh.new()
			box.size = Vector3(0.05, 0.05, 0.05)
			mesh.mesh = box
			material.albedo_color = Color(0.55, 0.45, 0.35)
	
	mesh.material_override = material
	root.add_child(mesh)
	return root

func _create_sword_mesh() -> Mesh:
	var mesh = ImmediateMesh.new()
	return mesh

func _create_axe_mesh() -> Mesh:
	var mesh = BoxMesh.new()
	mesh.size = Vector3(0.03, 0.03, 0.4)
	return mesh

func _create_pickaxe_mesh() -> Mesh:
	var mesh = BoxMesh.new()
	mesh.size = Vector3(0.03, 0.03, 0.35)
	return mesh

func _create_bow_mesh() -> Mesh:
	var mesh = CylinderMesh.new()
	mesh.top_radius = 0.01
	mesh.bottom_radius = 0.01
	mesh.height = 0.6
	return mesh

func _create_torch_mesh() -> Mesh:
	var mesh = CylinderMesh.new()
	mesh.top_radius = 0.018
	mesh.bottom_radius = 0.022
	mesh.height = 0.32
	return mesh

func _unequip_current_item():
	if current_item_mesh:
		current_item_mesh.queue_free()
		current_item_mesh = null
	current_item_id = ""
	emit_signal("item_unequipped")

func attack():
	if is_attacking:
		return
	
	is_attacking = true
	swing_progress = 0.0
	current_state = HandState.ATTACK
	emit_signal("attack_started")

func gather():
	if is_attacking:
		return
	
	is_attacking = true
	swing_progress = 0.0
	current_state = HandState.GATHER
	emit_signal("action_started", "gather")

func _process(delta: float):
	anim_time += delta
	
	_update_player_state()
	_process_sway(delta)
	_process_bob(delta)
	
	if is_attacking:
		_process_attack(delta)
	else:
		_apply_idle_pose(delta)
	
	position = base_position + sway_offset + bob_offset

func _update_player_state():
	var player = get_parent()
	if player and player is CharacterBody3D:
		velocity = player.velocity
		is_grounded = player.is_on_floor()
		is_running = Input.is_action_pressed("sprint") and velocity.length() > 0.5

func _process_sway(delta: float):
	var mouse_vel = Input.get_last_mouse_velocity() * 0.00008
	target_sway = Vector3(-mouse_vel.y, -mouse_vel.x, 0) * sway_amount
	target_sway = target_sway.clamp(Vector3(-0.04, -0.04, 0), Vector3(0.04, 0.04, 0))
	
	sway_offset = sway_offset.lerp(target_sway, sway_speed * delta)

func _process_bob(delta: float):
	var speed = Vector2(velocity.x, velocity.z).length()
	var is_moving = speed > 0.5 and is_grounded
	
	if is_moving:
		var mult = run_bob_multiplier if is_running else 1.0
		move_time += delta * bob_speed * mult
		
		bob_offset.x = sin(move_time) * bob_amount.x * mult
		bob_offset.y = abs(cos(move_time * 2.0)) * bob_amount.y * mult
	else:
		move_time = 0.0
		bob_offset = bob_offset.lerp(Vector3.ZERO, 6.0 * delta)

func _process_attack(delta: float):
	swing_progress += delta * swing_speed
	
	var phase = swing_progress
	
	if phase < 0.3:
		var t = phase / 0.3
		if right_arm:
			right_arm.rotation_degrees.x = lerp(0.0, 25.0, ease(t, 0.5))
			right_arm.rotation_degrees.z = lerp(0.0, -15.0, ease(t, 0.5))
			right_arm.position.z = lerp(right_arm_offset.z, right_arm_offset.z - 0.05, ease(t, 0.5))
	elif phase < 0.6:
		var t = (phase - 0.3) / 0.3
		if right_arm:
			right_arm.rotation_degrees.x = lerp(25.0, -swing_arc, ease(t, 0.3))
			right_arm.rotation_degrees.z = lerp(-15.0, 25.0, ease(t, 0.3))
			right_arm.position.z = lerp(right_arm_offset.z - 0.05, right_arm_offset.z + swing_forward, ease(t, 0.3))
	else:
		var t = (phase - 0.6) / 0.4
		if right_arm:
			right_arm.rotation_degrees.x = lerp(-swing_arc, 0.0, ease(t, 2.5))
			right_arm.rotation_degrees.z = lerp(25.0, 0.0, ease(t, 2.5))
			right_arm.position.z = lerp(right_arm_offset.z + swing_forward, right_arm_offset.z, ease(t, 2.5))
	
	if swing_progress >= 1.0:
		is_attacking = false
		swing_progress = 0.0
		current_state = HandState.IDLE
		if right_arm:
			right_arm.rotation_degrees = Vector3.ZERO
			right_arm.position = right_arm_offset
		emit_signal("attack_finished")
		emit_signal("action_finished", "attack")

func _apply_idle_pose(delta: float):
	var breath = sin(anim_time * 1.2) * 0.003
	
	if right_arm:
		right_arm.rotation_degrees = right_arm.rotation_degrees.lerp(Vector3.ZERO, 5.0 * delta)
		right_arm.position.y = lerp(right_arm.position.y, right_arm_offset.y + breath, 5.0 * delta)
	
	if left_arm:
		left_arm.rotation_degrees = left_arm.rotation_degrees.lerp(Vector3.ZERO, 5.0 * delta)
		left_arm.position.y = lerp(left_arm.position.y, left_arm_offset.y + breath, 5.0 * delta)

func set_skin_color(color: Color):
	skin_color = color
	if skin_material:
		skin_material.albedo_color = color

func set_sleeve_color(color: Color):
	sleeve_color = color
	if sleeve_material:
		sleeve_material.albedo_color = color

func get_held_item_id() -> String:
	return current_item_id

func has_item_equipped() -> bool:
	return current_item_id != ""

func swing():
	attack()
