extends Node3D

signal item_equipped(item_id: String)
signal item_unequipped()
signal swing_started()
signal swing_finished()

@export var arm_color := Color(0.85, 0.7, 0.6)
@export var swing_speed := 8.0
@export var sway_amount := 0.02
@export var sway_speed := 5.0
@export var bob_amount := 0.01
@export var bob_speed := 8.0

var current_item_id: String = ""
var current_item_mesh: Node3D = null
var is_swinging := false
var swing_progress := 0.0
var sway_offset := Vector3.ZERO
var bob_offset := Vector3.ZERO
var target_sway := Vector3.ZERO
var move_time := 0.0
var is_moving := false

@onready var right_arm: Node3D = $RightArm
@onready var left_arm: Node3D = $LeftArm
@onready var item_holder: Node3D = $RightArm/ItemHolder

var inventory = null
var item_models := {}

func _ready():
	inventory = get_node_or_null("/root/Inventory")
	if inventory:
		inventory.connect("hotbar_changed", Callable(self, "_on_hotbar_changed"))
	
	_preload_item_models()
	_create_arms()
	
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
	
	for item_id in model_paths:
		var path = model_paths[item_id]
		if path and ResourceLoader.exists(path):
			item_models[item_id] = load(path)

func _create_arms():
	if not right_arm:
		right_arm = Node3D.new()
		right_arm.name = "RightArm"
		add_child(right_arm)
	
	if not left_arm:
		left_arm = Node3D.new()
		left_arm.name = "LeftArm"
		add_child(left_arm)
	
	if not item_holder:
		item_holder = Node3D.new()
		item_holder.name = "ItemHolder"
		right_arm.add_child(item_holder)
	
	_create_arm_mesh(right_arm, Vector3(0.25, -0.3, -0.4))
	_create_arm_mesh(left_arm, Vector3(-0.25, -0.3, -0.4))
	
	item_holder.position = Vector3(0.05, 0.15, -0.1)

func _create_arm_mesh(arm_node: Node3D, pos: Vector3):
	for child in arm_node.get_children():
		if child is MeshInstance3D and child.name != "ItemHolder":
			child.queue_free()
	
	var forearm = MeshInstance3D.new()
	forearm.name = "Forearm"
	var forearm_mesh = CapsuleMesh.new()
	forearm_mesh.radius = 0.04
	forearm_mesh.height = 0.3
	forearm.mesh = forearm_mesh
	forearm.rotation_degrees.x = 90
	forearm.position = Vector3(0, 0, -0.15)
	
	var forearm_mat = StandardMaterial3D.new()
	forearm_mat.albedo_color = arm_color
	forearm_mat.roughness = 0.8
	forearm.material_override = forearm_mat
	
	var hand = MeshInstance3D.new()
	hand.name = "Hand"
	var hand_mesh = BoxMesh.new()
	hand_mesh.size = Vector3(0.06, 0.08, 0.1)
	hand.mesh = hand_mesh
	hand.position = Vector3(0, 0, -0.35)
	
	var hand_mat = StandardMaterial3D.new()
	hand_mat.albedo_color = arm_color
	hand_mat.roughness = 0.8
	hand.material_override = hand_mat
	
	var finger1 = _create_finger(Vector3(-0.02, 0, -0.06))
	var finger2 = _create_finger(Vector3(0, 0, -0.07))
	var finger3 = _create_finger(Vector3(0.02, 0, -0.06))
	var thumb = _create_finger(Vector3(-0.04, 0, -0.02), true)
	
	hand.add_child(finger1)
	hand.add_child(finger2)
	hand.add_child(finger3)
	hand.add_child(thumb)
	
	arm_node.add_child(forearm)
	arm_node.add_child(hand)
	arm_node.position = pos

func _create_finger(offset: Vector3, is_thumb: bool = false) -> MeshInstance3D:
	var finger = MeshInstance3D.new()
	var finger_mesh = CapsuleMesh.new()
	finger_mesh.radius = 0.012 if is_thumb else 0.01
	finger_mesh.height = 0.04 if is_thumb else 0.05
	finger.mesh = finger_mesh
	finger.position = offset
	finger.rotation_degrees.x = 30
	if is_thumb:
		finger.rotation_degrees.z = 45
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = arm_color
	mat.roughness = 0.8
	finger.material_override = mat
	
	return finger

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
			mat.albedo_color = Color(0.5, 0.5, 0.5)
		elif item_id.contains("iron"):
			mat.albedo_color = Color(0.6, 0.6, 0.65)
		elif item_id.contains("steel"):
			mat.albedo_color = Color(0.7, 0.7, 0.75)
		else:
			mat.albedo_color = Color(0.5, 0.35, 0.2)
		mat.metallic = 0.3
		mat.roughness = 0.6
		mesh.material_override = mat
		
		item_holder.add_child(mesh)
		current_item_mesh = mesh
	else:
		var mesh = _create_default_item_mesh(item_id)
		item_holder.add_child(mesh)
		current_item_mesh = mesh
	
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
		"tool", "weapon":
			var box = BoxMesh.new()
			box.size = Vector3(0.04, 0.04, 0.25)
			mesh.mesh = box
			mesh.position = Vector3(0, 0, -0.12)
			
			var mat = StandardMaterial3D.new()
			mat.albedo_color = Color(0.4, 0.3, 0.2)
			mesh.material_override = mat
		"food", "drink":
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
			mat.albedo_color = Color(0.9, 0.9, 0.9)
			mesh.material_override = mat
		"light":
			var cylinder = CylinderMesh.new()
			cylinder.top_radius = 0.02
			cylinder.bottom_radius = 0.025
			cylinder.height = 0.25
			mesh.mesh = cylinder
			mesh.rotation_degrees.x = 90
			mesh.position = Vector3(0, 0.05, -0.1)
			
			var mat = StandardMaterial3D.new()
			mat.albedo_color = Color(0.4, 0.3, 0.15)
			mesh.material_override = mat
			
			if item_id == "torch":
				var flame = _create_torch_flame()
				flame.position = Vector3(0, 0.15, 0)
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
	light.light_energy = 2.0
	light.omni_range = 8.0
	light.omni_attenuation = 1.5
	return light

func _unequip_current_item():
	if current_item_mesh:
		current_item_mesh.queue_free()
		current_item_mesh = null
	current_item_id = ""
	emit_signal("item_unequipped")

func swing():
	if is_swinging:
		return
	
	is_swinging = true
	swing_progress = 0.0
	emit_signal("swing_started")

func _process(delta):
	_process_swing(delta)
	_process_sway(delta)
	_process_bob(delta)

func _process_swing(delta):
	if not is_swinging:
		return
	
	swing_progress += delta * swing_speed
	
	if swing_progress < 0.5:
		var t = swing_progress * 2.0
		right_arm.rotation_degrees.x = lerp(0.0, -60.0, ease(t, 0.3))
		right_arm.rotation_degrees.z = lerp(0.0, 20.0, ease(t, 0.3))
	else:
		var t = (swing_progress - 0.5) * 2.0
		right_arm.rotation_degrees.x = lerp(-60.0, 0.0, ease(t, 2.0))
		right_arm.rotation_degrees.z = lerp(20.0, 0.0, ease(t, 2.0))
	
	if swing_progress >= 1.0:
		is_swinging = false
		right_arm.rotation_degrees = Vector3.ZERO
		emit_signal("swing_finished")

func _process_sway(delta):
	var mouse_delta = Input.get_last_mouse_velocity() * 0.0001
	target_sway = Vector3(-mouse_delta.y, -mouse_delta.x, 0) * sway_amount
	target_sway = target_sway.clamp(Vector3(-0.05, -0.05, 0), Vector3(0.05, 0.05, 0))
	
	sway_offset = sway_offset.lerp(target_sway, sway_speed * delta)
	
	if not is_swinging:
		position = sway_offset

func _process_bob(delta):
	var player = get_parent()
	if player and player is CharacterBody3D:
		is_moving = player.velocity.length() > 0.5 and player.is_on_floor()
	
	if is_moving:
		move_time += delta * bob_speed
		bob_offset.x = sin(move_time) * bob_amount
		bob_offset.y = abs(cos(move_time)) * bob_amount * 0.5
	else:
		move_time = 0.0
		bob_offset = bob_offset.lerp(Vector3.ZERO, 5.0 * delta)
	
	if not is_swinging:
		position += bob_offset

func get_held_item_id() -> String:
	return current_item_id

func has_item_equipped() -> bool:
	return current_item_id != ""
