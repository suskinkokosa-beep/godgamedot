extends Node3D

signal item_equipped(item_id: String)
signal item_unequipped()
signal swing_started()
signal swing_finished()
signal hit_target(target)

@export var skin_color := Color(0.85, 0.72, 0.63)
@export var clothing_color := Color(0.35, 0.32, 0.28)
@export var swing_speed := 10.0
@export var sway_amount := 0.015
@export var sway_speed := 6.0
@export var bob_amount := 0.008
@export var bob_speed := 10.0
@export var attack_reach := 3.0

var current_item_id: String = ""
var current_item_mesh: Node3D = null
var is_swinging := false
var swing_progress := 0.0
var swing_type := "attack"
var sway_offset := Vector3.ZERO
var bob_offset := Vector3.ZERO
var target_sway := Vector3.ZERO
var move_time := 0.0
var is_moving := false
var original_position := Vector3.ZERO

var right_arm: Node3D
var left_arm: Node3D
var item_holder: Node3D

var inventory = null
var item_models := {}
var tool_effectiveness := {}

func _ready():
	original_position = position
	inventory = get_node_or_null("/root/Inventory")
	if inventory and inventory.has_signal("hotbar_changed"):
		inventory.connect("hotbar_changed", Callable(self, "_on_hotbar_changed"))
	
	_preload_item_models()
	_create_realistic_arms()
	
	call_deferred("_update_held_item")

func _preload_item_models():
	var model_paths := {
		"stone_axe": "res://assets/art_pack/weapons/axe.obj",
		"iron_axe": "res://assets/art_pack/weapons/axe.obj",
		"steel_axe": "res://assets/art_pack/weapons/axe.obj",
		"stone_pickaxe": "res://assets/art_pack/weapons/pickaxe.obj",
		"iron_pickaxe": "res://assets/art_pack/weapons/pickaxe.obj",
		"steel_pickaxe": "res://assets/art_pack/weapons/pickaxe.obj",
		"iron_sword": "res://assets/art_pack/weapons/sword.obj",
		"steel_sword": "res://assets/art_pack/weapons/sword.obj",
		"wooden_spear": "res://assets/art_pack/weapons/sword.obj",
		"stone_knife": "res://assets/art_pack/weapons/knife.obj",
		"bow": "res://assets/art_pack/weapons/bow.obj",
		"crossbow": "res://assets/art_pack/weapons/bow.obj",
		"torch": null
	}
	
	tool_effectiveness = {
		"stone_axe": {"type": "axe", "efficiency": 1.0},
		"iron_axe": {"type": "axe", "efficiency": 1.5},
		"steel_axe": {"type": "axe", "efficiency": 2.0},
		"stone_pickaxe": {"type": "pickaxe", "efficiency": 1.0},
		"iron_pickaxe": {"type": "pickaxe", "efficiency": 1.5},
		"steel_pickaxe": {"type": "pickaxe", "efficiency": 2.0}
	}
	
	for item_id in model_paths:
		var path = model_paths[item_id]
		if path and ResourceLoader.exists(path):
			item_models[item_id] = load(path)

func _create_realistic_arms():
	for child in get_children():
		child.queue_free()
	
	right_arm = Node3D.new()
	right_arm.name = "RightArm"
	add_child(right_arm)
	
	left_arm = Node3D.new()
	left_arm.name = "LeftArm"
	add_child(left_arm)
	
	_create_detailed_arm(right_arm, Vector3(0.28, -0.25, -0.45), false)
	_create_detailed_arm(left_arm, Vector3(-0.28, -0.25, -0.45), true)
	
	item_holder = Node3D.new()
	item_holder.name = "ItemHolder"
	right_arm.add_child(item_holder)
	item_holder.position = Vector3(0.02, 0.18, -0.08)

func _create_detailed_arm(arm_node: Node3D, base_pos: Vector3, is_left: bool):
	arm_node.position = base_pos
	
	var shoulder = MeshInstance3D.new()
	shoulder.name = "Shoulder"
	var shoulder_mesh = SphereMesh.new()
	shoulder_mesh.radius = 0.055
	shoulder.mesh = shoulder_mesh
	shoulder.position = Vector3(0, 0.1, 0.1)
	shoulder.material_override = _create_arm_skin_material()
	arm_node.add_child(shoulder)
	
	var upper_arm = MeshInstance3D.new()
	upper_arm.name = "UpperArm"
	var upper_mesh = CapsuleMesh.new()
	upper_mesh.radius = 0.042
	upper_mesh.height = 0.22
	upper_arm.mesh = upper_mesh
	upper_arm.rotation_degrees.x = 75
	upper_arm.position = Vector3(0, 0, 0)
	upper_arm.material_override = _create_arm_skin_material()
	arm_node.add_child(upper_arm)
	
	var elbow = MeshInstance3D.new()
	elbow.name = "Elbow"
	var elbow_mesh = SphereMesh.new()
	elbow_mesh.radius = 0.035
	elbow.mesh = elbow_mesh
	elbow.position = Vector3(0, -0.02, -0.18)
	elbow.material_override = _create_arm_skin_material()
	arm_node.add_child(elbow)
	
	var forearm = MeshInstance3D.new()
	forearm.name = "Forearm"
	var forearm_mesh = CapsuleMesh.new()
	forearm_mesh.radius = 0.036
	forearm_mesh.height = 0.22
	forearm.mesh = forearm_mesh
	forearm.rotation_degrees.x = 90
	forearm.position = Vector3(0, 0.05, -0.32)
	forearm.material_override = _create_arm_skin_material()
	arm_node.add_child(forearm)
	
	var wrist = MeshInstance3D.new()
	wrist.name = "Wrist"
	var wrist_mesh = SphereMesh.new()
	wrist_mesh.radius = 0.028
	wrist.mesh = wrist_mesh
	wrist.position = Vector3(0, 0.08, -0.42)
	wrist.material_override = _create_arm_skin_material()
	arm_node.add_child(wrist)
	
	var sleeve = MeshInstance3D.new()
	sleeve.name = "Sleeve"
	var sleeve_mesh = CylinderMesh.new()
	sleeve_mesh.top_radius = 0.052
	sleeve_mesh.bottom_radius = 0.048
	sleeve_mesh.height = 0.12
	sleeve.mesh = sleeve_mesh
	sleeve.rotation_degrees.x = 75
	sleeve.position = Vector3(0, 0.05, 0.05)
	var sleeve_mat = StandardMaterial3D.new()
	sleeve_mat.albedo_color = clothing_color
	sleeve_mat.roughness = 0.85
	sleeve.material_override = sleeve_mat
	arm_node.add_child(sleeve)
	
	_create_detailed_hand(arm_node, is_left)

func _create_detailed_hand(arm_node: Node3D, is_left: bool):
	var hand = Node3D.new()
	hand.name = "Hand"
	arm_node.add_child(hand)
	hand.position = Vector3(0, 0.1, -0.48)
	
	var palm = MeshInstance3D.new()
	palm.name = "Palm"
	var palm_mesh = BoxMesh.new()
	palm_mesh.size = Vector3(0.075, 0.095, 0.025)
	palm.mesh = palm_mesh
	palm.material_override = _create_arm_skin_material()
	hand.add_child(palm)
	
	var finger_positions := [
		Vector3(-0.025, -0.045, 0),
		Vector3(-0.008, -0.055, 0),
		Vector3(0.008, -0.055, 0),
		Vector3(0.025, -0.045, 0)
	]
	
	var finger_lengths := [0.055, 0.065, 0.06, 0.05]
	
	for i in range(4):
		var finger = _create_finger(finger_positions[i], finger_lengths[i], 0.007)
		finger.name = "Finger%d" % i
		hand.add_child(finger)
	
	var thumb = _create_thumb(is_left)
	thumb.name = "Thumb"
	hand.add_child(thumb)
	
	var knuckles = MeshInstance3D.new()
	knuckles.name = "Knuckles"
	var knuckle_mesh = BoxMesh.new()
	knuckle_mesh.size = Vector3(0.07, 0.02, 0.025)
	knuckles.mesh = knuckle_mesh
	knuckles.position = Vector3(0, -0.03, 0.01)
	knuckles.material_override = _create_arm_skin_material()
	hand.add_child(knuckles)

func _create_finger(offset: Vector3, length: float, radius: float) -> Node3D:
	var finger = Node3D.new()
	finger.position = offset
	
	var segment1 = MeshInstance3D.new()
	var seg1_mesh = CapsuleMesh.new()
	seg1_mesh.radius = radius
	seg1_mesh.height = length * 0.45
	segment1.mesh = seg1_mesh
	segment1.position = Vector3(0, -length * 0.2, 0)
	segment1.rotation_degrees.x = 15
	segment1.material_override = _create_arm_skin_material()
	finger.add_child(segment1)
	
	var segment2 = MeshInstance3D.new()
	var seg2_mesh = CapsuleMesh.new()
	seg2_mesh.radius = radius * 0.9
	seg2_mesh.height = length * 0.35
	segment2.mesh = seg2_mesh
	segment2.position = Vector3(0, -length * 0.5, -0.008)
	segment2.rotation_degrees.x = 25
	segment2.material_override = _create_arm_skin_material()
	finger.add_child(segment2)
	
	var segment3 = MeshInstance3D.new()
	var seg3_mesh = CapsuleMesh.new()
	seg3_mesh.radius = radius * 0.8
	seg3_mesh.height = length * 0.25
	segment3.mesh = seg3_mesh
	segment3.position = Vector3(0, -length * 0.75, -0.015)
	segment3.rotation_degrees.x = 30
	segment3.material_override = _create_arm_skin_material()
	finger.add_child(segment3)
	
	return finger

func _create_thumb(is_left: bool) -> Node3D:
	var thumb = Node3D.new()
	var x_mult = -1 if is_left else 1
	thumb.position = Vector3(x_mult * 0.045, 0, 0.01)
	thumb.rotation_degrees.z = x_mult * -35
	
	var base = MeshInstance3D.new()
	var base_mesh = CapsuleMesh.new()
	base_mesh.radius = 0.012
	base_mesh.height = 0.03
	base.mesh = base_mesh
	base.position = Vector3(0, 0.01, 0)
	base.material_override = _create_arm_skin_material()
	thumb.add_child(base)
	
	var tip = MeshInstance3D.new()
	var tip_mesh = CapsuleMesh.new()
	tip_mesh.radius = 0.01
	tip_mesh.height = 0.025
	tip.mesh = tip_mesh
	tip.position = Vector3(0, -0.02, -0.005)
	tip.rotation_degrees.x = 20
	tip.material_override = _create_arm_skin_material()
	thumb.add_child(tip)
	
	return thumb

func _create_arm_skin_material() -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	mat.albedo_color = skin_color
	mat.roughness = 0.7
	mat.metallic = 0.0
	return mat

func _on_hotbar_changed():
	_update_held_item()

func _update_held_item():
	if not inventory:
		return
	
	var selected = inventory.get_selected_hotbar_slot()
	var item = inventory.get_hotbar_slot(selected)
	
	if item == null or not item.has("id"):
		_unequip_current_item()
		return
	
	var item_id = item["id"]
	if item_id != current_item_id:
		_equip_item(item_id)

func _equip_item(item_id: String):
	_unequip_current_item()
	
	current_item_id = item_id
	
	if item_models.has(item_id) and item_models[item_id] != null:
		var mesh = MeshInstance3D.new()
		mesh.mesh = item_models[item_id]
		mesh.name = "ItemMesh"
		mesh.scale = Vector3(0.5, 0.5, 0.5)
		mesh.rotation_degrees = Vector3(-90, 0, 0)
		
		var info = null
		if inventory:
			info = inventory.get_item_info(item_id)
		
		if info:
			var item_type = info.get("type", "misc")
			match item_type:
				"weapon":
					mesh.scale = Vector3(0.4, 0.4, 0.4)
					mesh.position = Vector3(0, 0, -0.1)
				"tool":
					mesh.scale = Vector3(0.45, 0.45, 0.45)
					mesh.position = Vector3(0, 0, -0.08)
		
		var mat = StandardMaterial3D.new()
		if item_id.contains("stone"):
			mat.albedo_color = Color(0.55, 0.52, 0.5)
		elif item_id.contains("iron"):
			mat.albedo_color = Color(0.65, 0.65, 0.68)
		elif item_id.contains("steel"):
			mat.albedo_color = Color(0.75, 0.75, 0.78)
		elif item_id.contains("wood"):
			mat.albedo_color = Color(0.55, 0.4, 0.25)
		else:
			mat.albedo_color = Color(0.5, 0.35, 0.2)
		mat.metallic = 0.4
		mat.roughness = 0.55
		mesh.material_override = mat
		
		item_holder.add_child(mesh)
		current_item_mesh = mesh
	else:
		var mesh = _create_default_item_mesh(item_id)
		item_holder.add_child(mesh)
		current_item_mesh = mesh
	
	_play_equip_animation()
	emit_signal("item_equipped", item_id)

func _create_default_item_mesh(item_id: String) -> MeshInstance3D:
	var mesh = MeshInstance3D.new()
	mesh.name = "ItemMesh"
	
	var info = null
	if inventory:
		info = inventory.get_item_info(item_id)
	
	var item_type = "misc"
	if info:
		item_type = info.get("type", "misc")
	
	match item_type:
		"tool":
			var handle = CylinderMesh.new()
			handle.height = 0.35
			handle.top_radius = 0.015
			handle.bottom_radius = 0.018
			mesh.mesh = handle
			mesh.rotation_degrees = Vector3(0, 0, 45)
			mesh.position = Vector3(0, 0, -0.1)
			
			var head = MeshInstance3D.new()
			var head_mesh = BoxMesh.new()
			head_mesh.size = Vector3(0.12, 0.06, 0.02)
			head.mesh = head_mesh
			head.position = Vector3(0.06, 0.15, 0)
			var head_mat = StandardMaterial3D.new()
			head_mat.albedo_color = Color(0.5, 0.5, 0.55)
			head_mat.metallic = 0.5
			head.material_override = head_mat
			mesh.add_child(head)
			
			var mat = StandardMaterial3D.new()
			mat.albedo_color = Color(0.45, 0.32, 0.2)
			mesh.material_override = mat
		"weapon":
			var blade = BoxMesh.new()
			blade.size = Vector3(0.04, 0.04, 0.35)
			mesh.mesh = blade
			mesh.position = Vector3(0, 0, -0.15)
			
			var mat = StandardMaterial3D.new()
			mat.albedo_color = Color(0.6, 0.6, 0.65)
			mat.metallic = 0.6
			mesh.material_override = mat
		"food", "consumable":
			var sphere = SphereMesh.new()
			sphere.radius = 0.04
			sphere.height = 0.06
			mesh.mesh = sphere
			mesh.position = Vector3(0, 0, -0.05)
			
			var mat = StandardMaterial3D.new()
			mat.albedo_color = Color(0.7, 0.5, 0.3)
			mesh.material_override = mat
		"medical":
			var box = BoxMesh.new()
			box.size = Vector3(0.06, 0.04, 0.08)
			mesh.mesh = box
			mesh.position = Vector3(0, 0, -0.05)
			
			var mat = StandardMaterial3D.new()
			mat.albedo_color = Color(0.95, 0.95, 0.95)
			mesh.material_override = mat
		"light":
			var cylinder = CylinderMesh.new()
			cylinder.top_radius = 0.018
			cylinder.bottom_radius = 0.022
			cylinder.height = 0.3
			mesh.mesh = cylinder
			mesh.rotation_degrees.x = 90
			mesh.position = Vector3(0, 0.05, -0.1)
			
			var mat = StandardMaterial3D.new()
			mat.albedo_color = Color(0.4, 0.3, 0.15)
			mesh.material_override = mat
			
			if item_id == "torch":
				var flame = _create_torch_flame()
				flame.position = Vector3(0, 0.18, 0)
				mesh.add_child(flame)
		_:
			var box = BoxMesh.new()
			box.size = Vector3(0.05, 0.05, 0.05)
			mesh.mesh = box
			mesh.position = Vector3(0, 0, -0.05)
			
			var mat = StandardMaterial3D.new()
			mat.albedo_color = Color(0.6, 0.5, 0.4)
			mesh.material_override = mat
	
	return mesh

func _create_torch_flame() -> OmniLight3D:
	var light = OmniLight3D.new()
	light.name = "TorchFlame"
	light.light_color = Color(1.0, 0.7, 0.3)
	light.light_energy = 2.5
	light.omni_range = 10.0
	light.omni_attenuation = 1.5
	
	var flame_mesh = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 0.03
	flame_mesh.mesh = sphere
	var flame_mat = StandardMaterial3D.new()
	flame_mat.albedo_color = Color(1.0, 0.6, 0.2)
	flame_mat.emission_enabled = true
	flame_mat.emission = Color(1.0, 0.5, 0.1)
	flame_mat.emission_energy_multiplier = 3.0
	flame_mesh.material_override = flame_mat
	light.add_child(flame_mesh)
	
	return light

func _play_equip_animation():
	var tween = create_tween()
	var orig_pos = item_holder.position
	item_holder.position.y -= 0.15
	tween.tween_property(item_holder, "position:y", orig_pos.y, 0.2).set_ease(Tween.EASE_OUT)

func _unequip_current_item():
	if current_item_mesh:
		current_item_mesh.queue_free()
		current_item_mesh = null
	current_item_id = ""
	emit_signal("item_unequipped")

func swing(type: String = "attack"):
	if is_swinging:
		return
	
	is_swinging = true
	swing_progress = 0.0
	swing_type = type
	emit_signal("swing_started")
	
	_perform_hit_check()

func _perform_hit_check():
	var camera = get_parent()
	if not camera or not camera is Camera3D:
		return
	
	var from = camera.global_position
	var to = from - camera.global_basis.z * attack_reach
	
	var space = camera.get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, to)
	
	var player = camera.get_parent()
	if player:
		query.exclude = [player]
	
	var result = space.intersect_ray(query)
	
	if result:
		var target = result.collider
		if target:
			emit_signal("hit_target", target)
			
			if target.has_method("gather"):
				target.gather(player)
			elif target.has_method("apply_damage"):
				var damage = _calculate_damage()
				target.apply_damage(damage, player)

func _calculate_damage() -> float:
	var base_damage := 10.0
	
	if inventory:
		var info = inventory.get_item_info(current_item_id)
		if info:
			base_damage = info.get("damage", 10.0)
	
	return base_damage

func _process(delta):
	_process_swing(delta)
	_process_sway(delta)
	_process_bob(delta)

func _process_swing(delta):
	if not is_swinging:
		return
	
	swing_progress += delta * swing_speed
	
	if swing_progress < 0.3:
		var t = swing_progress / 0.3
		right_arm.rotation_degrees.x = lerp(0.0, -45.0, ease(t, 0.3))
		right_arm.rotation_degrees.z = lerp(0.0, 15.0, ease(t, 0.3))
		right_arm.position.z = lerp(-0.45, -0.35, ease(t, 0.3))
	elif swing_progress < 0.6:
		var t = (swing_progress - 0.3) / 0.3
		right_arm.rotation_degrees.x = lerp(-45.0, 25.0, ease(t, 2.5))
		right_arm.rotation_degrees.z = lerp(15.0, -10.0, ease(t, 2.0))
		right_arm.position.z = lerp(-0.35, -0.55, ease(t, 2.0))
	else:
		var t = (swing_progress - 0.6) / 0.4
		right_arm.rotation_degrees.x = lerp(25.0, 0.0, ease(t, 1.5))
		right_arm.rotation_degrees.z = lerp(-10.0, 0.0, ease(t, 1.5))
		right_arm.position.z = lerp(-0.55, -0.45, ease(t, 1.5))
	
	if swing_progress >= 1.0:
		is_swinging = false
		right_arm.rotation_degrees = Vector3.ZERO
		right_arm.position = Vector3(0.28, -0.25, -0.45)
		emit_signal("swing_finished")

func _process_sway(delta):
	if is_swinging:
		return
	
	var mouse_delta = Input.get_last_mouse_velocity() * 0.0001
	target_sway = Vector3(-mouse_delta.y, -mouse_delta.x, 0) * sway_amount
	target_sway = target_sway.clamp(Vector3(-0.04, -0.04, 0), Vector3(0.04, 0.04, 0))
	
	sway_offset = sway_offset.lerp(target_sway, sway_speed * delta)
	
	position = original_position + sway_offset

func _process_bob(delta):
	var player = get_parent().get_parent() if get_parent() else null
	if player and player is CharacterBody3D:
		is_moving = player.velocity.length() > 0.5 and player.is_on_floor()
	
	if is_moving:
		move_time += delta * bob_speed
		bob_offset.x = sin(move_time) * bob_amount
		bob_offset.y = abs(cos(move_time * 2)) * bob_amount * 0.7
	else:
		move_time = 0.0
		bob_offset = bob_offset.lerp(Vector3.ZERO, 6.0 * delta)
	
	if not is_swinging:
		position += bob_offset

func get_held_item_id() -> String:
	return current_item_id

func has_item_equipped() -> bool:
	return current_item_id != ""

func get_tool_type() -> String:
	if tool_effectiveness.has(current_item_id):
		return tool_effectiveness[current_item_id].type
	return ""

func get_tool_efficiency() -> float:
	if tool_effectiveness.has(current_item_id):
		return tool_effectiveness[current_item_id].efficiency
	return 1.0

func set_skin_color(color: Color):
	skin_color = color
	_update_arm_materials()

func set_clothing_color(color: Color):
	clothing_color = color
	_update_arm_materials()

func _update_arm_materials():
	pass
