extends Node3D
class_name CharacterModel

signal animation_started(anim_name: String)
signal animation_finished(anim_name: String)

@export var skin_color := Color(0.85, 0.72, 0.63)
@export var hair_color := Color(0.2, 0.15, 0.1)
@export var clothing_color := Color(0.35, 0.32, 0.28)
@export var body_height := 1.8
@export var is_male := true

var skeleton: Node3D
var body_parts := {}
var equipment_slots := {}
var current_animation := ""
var animation_time := 0.0
var animation_speed := 1.0
var is_moving := false
var is_crouching := false
var velocity := Vector3.ZERO

var bone_transforms := {}
var idle_time := 0.0

func _ready():
	_create_skeleton()
	_create_body()
	_create_clothing()

func _create_skeleton():
	skeleton = Node3D.new()
	skeleton.name = "Skeleton"
	add_child(skeleton)
	
	var bone_positions := {
		"pelvis": Vector3(0, body_height * 0.52, 0),
		"spine": Vector3(0, body_height * 0.58, 0),
		"spine1": Vector3(0, body_height * 0.65, 0),
		"spine2": Vector3(0, body_height * 0.72, 0),
		"neck": Vector3(0, body_height * 0.82, 0),
		"head": Vector3(0, body_height * 0.92, 0),
		"shoulder_l": Vector3(-0.18, body_height * 0.78, 0),
		"shoulder_r": Vector3(0.18, body_height * 0.78, 0),
		"upper_arm_l": Vector3(-0.25, body_height * 0.74, 0),
		"upper_arm_r": Vector3(0.25, body_height * 0.74, 0),
		"forearm_l": Vector3(-0.28, body_height * 0.58, 0),
		"forearm_r": Vector3(0.28, body_height * 0.58, 0),
		"hand_l": Vector3(-0.30, body_height * 0.45, 0),
		"hand_r": Vector3(0.30, body_height * 0.45, 0),
		"thigh_l": Vector3(-0.1, body_height * 0.48, 0),
		"thigh_r": Vector3(0.1, body_height * 0.48, 0),
		"calf_l": Vector3(-0.1, body_height * 0.26, 0),
		"calf_r": Vector3(0.1, body_height * 0.26, 0),
		"foot_l": Vector3(-0.1, body_height * 0.04, 0.05),
		"foot_r": Vector3(0.1, body_height * 0.04, 0.05)
	}
	
	for bone_name in bone_positions:
		var bone = Node3D.new()
		bone.name = bone_name
		bone.position = bone_positions[bone_name]
		skeleton.add_child(bone)
		bone_transforms[bone_name] = {
			"position": bone_positions[bone_name],
			"rotation": Vector3.ZERO
		}

func _create_body():
	_create_torso()
	_create_head()
	_create_arms()
	_create_legs()

func _create_torso():
	var torso = Node3D.new()
	torso.name = "Torso"
	add_child(torso)
	body_parts["torso"] = torso
	
	var chest = MeshInstance3D.new()
	chest.name = "Chest"
	var chest_mesh = BoxMesh.new()
	var chest_width = 0.38 if is_male else 0.34
	var chest_depth = 0.22 if is_male else 0.20
	chest_mesh.size = Vector3(chest_width, 0.35, chest_depth)
	chest.mesh = chest_mesh
	chest.position = Vector3(0, body_height * 0.72, 0)
	
	var chest_mat = _create_skin_material()
	chest.material_override = chest_mat
	torso.add_child(chest)
	
	var waist = MeshInstance3D.new()
	waist.name = "Waist"
	var waist_mesh = BoxMesh.new()
	var waist_width = 0.32 if is_male else 0.28
	waist_mesh.size = Vector3(waist_width, 0.2, 0.18)
	waist.mesh = waist_mesh
	waist.position = Vector3(0, body_height * 0.58, 0)
	waist.material_override = _create_skin_material()
	torso.add_child(waist)
	
	var pelvis_mesh_inst = MeshInstance3D.new()
	pelvis_mesh_inst.name = "Pelvis"
	var pelvis_mesh = BoxMesh.new()
	var pelvis_width = 0.34 if is_male else 0.38
	pelvis_mesh.size = Vector3(pelvis_width, 0.15, 0.2)
	pelvis_mesh_inst.mesh = pelvis_mesh
	pelvis_mesh_inst.position = Vector3(0, body_height * 0.50, 0)
	pelvis_mesh_inst.material_override = _create_skin_material()
	torso.add_child(pelvis_mesh_inst)

func _create_head():
	var head = Node3D.new()
	head.name = "Head"
	add_child(head)
	body_parts["head"] = head
	
	var skull = MeshInstance3D.new()
	skull.name = "Skull"
	var skull_mesh = SphereMesh.new()
	skull_mesh.radius = 0.11
	skull_mesh.height = 0.24
	skull.mesh = skull_mesh
	skull.position = Vector3(0, body_height * 0.90, 0)
	skull.material_override = _create_skin_material()
	head.add_child(skull)
	
	var face = MeshInstance3D.new()
	face.name = "Face"
	var face_mesh = BoxMesh.new()
	face_mesh.size = Vector3(0.14, 0.18, 0.12)
	face.mesh = face_mesh
	face.position = Vector3(0, body_height * 0.88, 0.05)
	face.material_override = _create_skin_material()
	head.add_child(face)
	
	var jaw = MeshInstance3D.new()
	jaw.name = "Jaw"
	var jaw_mesh = BoxMesh.new()
	jaw_mesh.size = Vector3(0.1, 0.06, 0.08)
	jaw.mesh = jaw_mesh
	jaw.position = Vector3(0, body_height * 0.82, 0.04)
	jaw.material_override = _create_skin_material()
	head.add_child(jaw)
	
	var neck = MeshInstance3D.new()
	neck.name = "Neck"
	var neck_mesh = CylinderMesh.new()
	neck_mesh.height = 0.08
	neck_mesh.top_radius = 0.055
	neck_mesh.bottom_radius = 0.06
	neck.mesh = neck_mesh
	neck.position = Vector3(0, body_height * 0.80, 0)
	neck.material_override = _create_skin_material()
	head.add_child(neck)
	
	_create_facial_features(head)
	_create_hair(head)

func _create_facial_features(head: Node3D):
	var eye_l = MeshInstance3D.new()
	eye_l.name = "EyeL"
	var eye_mesh = SphereMesh.new()
	eye_mesh.radius = 0.015
	eye_mesh.height = 0.025
	eye_l.mesh = eye_mesh
	eye_l.position = Vector3(-0.035, body_height * 0.90, 0.1)
	var eye_mat = StandardMaterial3D.new()
	eye_mat.albedo_color = Color(0.9, 0.9, 0.95)
	eye_l.material_override = eye_mat
	head.add_child(eye_l)
	
	var eye_r = eye_l.duplicate()
	eye_r.name = "EyeR"
	eye_r.position.x = 0.035
	head.add_child(eye_r)
	
	var pupil_l = MeshInstance3D.new()
	pupil_l.name = "PupilL"
	var pupil_mesh = SphereMesh.new()
	pupil_mesh.radius = 0.008
	pupil_l.mesh = pupil_mesh
	pupil_l.position = Vector3(-0.035, body_height * 0.90, 0.11)
	var pupil_mat = StandardMaterial3D.new()
	pupil_mat.albedo_color = Color(0.2, 0.15, 0.1)
	pupil_l.material_override = pupil_mat
	head.add_child(pupil_l)
	
	var pupil_r = pupil_l.duplicate()
	pupil_r.name = "PupilR"
	pupil_r.position.x = 0.035
	head.add_child(pupil_r)
	
	var nose = MeshInstance3D.new()
	nose.name = "Nose"
	var nose_mesh = BoxMesh.new()
	nose_mesh.size = Vector3(0.025, 0.04, 0.03)
	nose.mesh = nose_mesh
	nose.position = Vector3(0, body_height * 0.87, 0.11)
	nose.material_override = _create_skin_material()
	head.add_child(nose)
	
	var mouth = MeshInstance3D.new()
	mouth.name = "Mouth"
	var mouth_mesh = BoxMesh.new()
	mouth_mesh.size = Vector3(0.04, 0.008, 0.01)
	mouth.mesh = mouth_mesh
	mouth.position = Vector3(0, body_height * 0.83, 0.1)
	var mouth_mat = StandardMaterial3D.new()
	mouth_mat.albedo_color = Color(0.6, 0.35, 0.35)
	mouth.material_override = mouth_mat
	head.add_child(mouth)
	
	var ear_l = MeshInstance3D.new()
	ear_l.name = "EarL"
	var ear_mesh = BoxMesh.new()
	ear_mesh.size = Vector3(0.02, 0.04, 0.015)
	ear_l.mesh = ear_mesh
	ear_l.position = Vector3(-0.12, body_height * 0.88, 0)
	ear_l.material_override = _create_skin_material()
	head.add_child(ear_l)
	
	var ear_r = ear_l.duplicate()
	ear_r.name = "EarR"
	ear_r.position.x = 0.12
	head.add_child(ear_r)

func _create_hair(head: Node3D):
	var hair = Node3D.new()
	hair.name = "Hair"
	head.add_child(hair)
	
	var hair_top = MeshInstance3D.new()
	hair_top.name = "HairTop"
	var hair_mesh = SphereMesh.new()
	hair_mesh.radius = 0.12
	hair_mesh.height = 0.15
	hair_top.mesh = hair_mesh
	hair_top.position = Vector3(0, body_height * 0.95, -0.02)
	var hair_mat = StandardMaterial3D.new()
	hair_mat.albedo_color = hair_color
	hair_mat.roughness = 0.8
	hair_top.material_override = hair_mat
	hair.add_child(hair_top)

func _create_arms():
	var arms = Node3D.new()
	arms.name = "Arms"
	add_child(arms)
	body_parts["arms"] = arms
	
	for side in ["L", "R"]:
		var x_mult = -1 if side == "L" else 1
		
		var shoulder = MeshInstance3D.new()
		shoulder.name = "Shoulder" + side
		var shoulder_mesh = SphereMesh.new()
		shoulder_mesh.radius = 0.06 if is_male else 0.05
		shoulder.mesh = shoulder_mesh
		shoulder.position = Vector3(x_mult * 0.2, body_height * 0.78, 0)
		shoulder.material_override = _create_skin_material()
		arms.add_child(shoulder)
		
		var upper_arm = MeshInstance3D.new()
		upper_arm.name = "UpperArm" + side
		var upper_arm_mesh = CapsuleMesh.new()
		upper_arm_mesh.radius = 0.045 if is_male else 0.038
		upper_arm_mesh.height = 0.28
		upper_arm.mesh = upper_arm_mesh
		upper_arm.position = Vector3(x_mult * 0.24, body_height * 0.66, 0)
		upper_arm.material_override = _create_skin_material()
		arms.add_child(upper_arm)
		
		var elbow = MeshInstance3D.new()
		elbow.name = "Elbow" + side
		var elbow_mesh = SphereMesh.new()
		elbow_mesh.radius = 0.035
		elbow.mesh = elbow_mesh
		elbow.position = Vector3(x_mult * 0.26, body_height * 0.54, 0)
		elbow.material_override = _create_skin_material()
		arms.add_child(elbow)
		
		var forearm = MeshInstance3D.new()
		forearm.name = "Forearm" + side
		var forearm_mesh = CapsuleMesh.new()
		forearm_mesh.radius = 0.038 if is_male else 0.032
		forearm_mesh.height = 0.26
		forearm.mesh = forearm_mesh
		forearm.position = Vector3(x_mult * 0.28, body_height * 0.42, 0)
		forearm.material_override = _create_skin_material()
		arms.add_child(forearm)
		
		var wrist = MeshInstance3D.new()
		wrist.name = "Wrist" + side
		var wrist_mesh = SphereMesh.new()
		wrist_mesh.radius = 0.028
		wrist.mesh = wrist_mesh
		wrist.position = Vector3(x_mult * 0.29, body_height * 0.32, 0)
		wrist.material_override = _create_skin_material()
		arms.add_child(wrist)
		
		_create_hand(arms, side, x_mult)

func _create_hand(parent: Node3D, side: String, x_mult: int):
	var hand = Node3D.new()
	hand.name = "Hand" + side
	parent.add_child(hand)
	
	var palm = MeshInstance3D.new()
	palm.name = "Palm"
	var palm_mesh = BoxMesh.new()
	palm_mesh.size = Vector3(0.08, 0.1, 0.025)
	palm.mesh = palm_mesh
	palm.position = Vector3(x_mult * 0.29, body_height * 0.26, 0)
	palm.material_override = _create_skin_material()
	hand.add_child(palm)
	
	var finger_offsets = [
		Vector3(-0.025, -0.05, 0),
		Vector3(-0.01, -0.055, 0),
		Vector3(0.01, -0.055, 0),
		Vector3(0.025, -0.05, 0)
	]
	
	for i in range(4):
		var finger = MeshInstance3D.new()
		finger.name = "Finger%d" % i
		var finger_mesh = CapsuleMesh.new()
		finger_mesh.radius = 0.008
		finger_mesh.height = 0.06
		finger.mesh = finger_mesh
		finger.position = Vector3(x_mult * 0.29, body_height * 0.26, 0) + finger_offsets[i] * Vector3(x_mult, 1, 1)
		finger.material_override = _create_skin_material()
		hand.add_child(finger)
	
	var thumb = MeshInstance3D.new()
	thumb.name = "Thumb"
	var thumb_mesh = CapsuleMesh.new()
	thumb_mesh.radius = 0.01
	thumb_mesh.height = 0.04
	thumb.mesh = thumb_mesh
	thumb.position = Vector3(x_mult * (0.29 + 0.04), body_height * 0.28, 0.01)
	thumb.rotation_degrees.z = x_mult * -45
	thumb.material_override = _create_skin_material()
	hand.add_child(thumb)

func _create_legs():
	var legs = Node3D.new()
	legs.name = "Legs"
	add_child(legs)
	body_parts["legs"] = legs
	
	for side in ["L", "R"]:
		var x_mult = -1 if side == "L" else 1
		var hip_offset = 0.1
		
		var hip = MeshInstance3D.new()
		hip.name = "Hip" + side
		var hip_mesh = SphereMesh.new()
		hip_mesh.radius = 0.08
		hip.mesh = hip_mesh
		hip.position = Vector3(x_mult * hip_offset, body_height * 0.46, 0)
		hip.material_override = _create_skin_material()
		legs.add_child(hip)
		
		var thigh = MeshInstance3D.new()
		thigh.name = "Thigh" + side
		var thigh_mesh = CapsuleMesh.new()
		thigh_mesh.radius = 0.065 if is_male else 0.07
		thigh_mesh.height = 0.42
		thigh.mesh = thigh_mesh
		thigh.position = Vector3(x_mult * hip_offset, body_height * 0.32, 0)
		thigh.material_override = _create_skin_material()
		legs.add_child(thigh)
		
		var knee = MeshInstance3D.new()
		knee.name = "Knee" + side
		var knee_mesh = SphereMesh.new()
		knee_mesh.radius = 0.05
		knee.mesh = knee_mesh
		knee.position = Vector3(x_mult * hip_offset, body_height * 0.27, 0.02)
		knee.material_override = _create_skin_material()
		legs.add_child(knee)
		
		var calf = MeshInstance3D.new()
		calf.name = "Calf" + side
		var calf_mesh = CapsuleMesh.new()
		calf_mesh.radius = 0.05 if is_male else 0.048
		calf_mesh.height = 0.38
		calf.mesh = calf_mesh
		calf.position = Vector3(x_mult * hip_offset, body_height * 0.15, 0)
		calf.material_override = _create_skin_material()
		legs.add_child(calf)
		
		var ankle = MeshInstance3D.new()
		ankle.name = "Ankle" + side
		var ankle_mesh = SphereMesh.new()
		ankle_mesh.radius = 0.035
		ankle.mesh = ankle_mesh
		ankle.position = Vector3(x_mult * hip_offset, body_height * 0.05, 0)
		ankle.material_override = _create_skin_material()
		legs.add_child(ankle)
		
		var foot = MeshInstance3D.new()
		foot.name = "Foot" + side
		var foot_mesh = BoxMesh.new()
		foot_mesh.size = Vector3(0.09, 0.05, 0.22)
		foot.mesh = foot_mesh
		foot.position = Vector3(x_mult * hip_offset, body_height * 0.025, 0.06)
		foot.material_override = _create_skin_material()
		legs.add_child(foot)

func _create_clothing():
	var clothing = Node3D.new()
	clothing.name = "Clothing"
	add_child(clothing)
	body_parts["clothing"] = clothing
	
	var shirt = MeshInstance3D.new()
	shirt.name = "Shirt"
	var shirt_mesh = BoxMesh.new()
	shirt_mesh.size = Vector3(0.42 if is_male else 0.38, 0.4, 0.24 if is_male else 0.22)
	shirt.mesh = shirt_mesh
	shirt.position = Vector3(0, body_height * 0.68, 0)
	shirt.material_override = _create_clothing_material()
	clothing.add_child(shirt)
	
	var pants = MeshInstance3D.new()
	pants.name = "Pants"
	var pants_mesh = BoxMesh.new()
	pants_mesh.size = Vector3(0.36 if is_male else 0.40, 0.35, 0.22)
	pants.mesh = pants_mesh
	pants.position = Vector3(0, body_height * 0.40, 0)
	var pants_mat = StandardMaterial3D.new()
	pants_mat.albedo_color = Color(0.25, 0.22, 0.2)
	pants_mat.roughness = 0.85
	pants.material_override = pants_mat
	clothing.add_child(pants)

func _create_skin_material() -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	mat.albedo_color = skin_color
	mat.roughness = 0.75
	mat.metallic = 0.0
	mat.subsurf_scatter_enabled = true
	mat.subsurf_scatter_strength = 0.3
	return mat

func _create_clothing_material() -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	mat.albedo_color = clothing_color
	mat.roughness = 0.85
	mat.metallic = 0.0
	return mat

func _process(delta):
	_update_idle_animation(delta)
	_update_movement_animation(delta)

func _update_idle_animation(delta):
	if is_moving:
		return
	
	idle_time += delta
	
	var breath_offset = sin(idle_time * 2.0) * 0.002
	if body_parts.has("torso"):
		body_parts["torso"].position.y = breath_offset

func _update_movement_animation(delta):
	if not is_moving:
		return
	
	animation_time += delta * animation_speed
	
	var walk_speed = 8.0
	var leg_swing = sin(animation_time * walk_speed) * 0.3
	var arm_swing = sin(animation_time * walk_speed) * 0.2
	
	if body_parts.has("legs"):
		var legs = body_parts["legs"]
		var thigh_l = legs.get_node_or_null("ThighL")
		var thigh_r = legs.get_node_or_null("ThighR")
		var calf_l = legs.get_node_or_null("CalfL")
		var calf_r = legs.get_node_or_null("CalfR")
		
		if thigh_l:
			thigh_l.rotation.x = leg_swing
		if thigh_r:
			thigh_r.rotation.x = -leg_swing
		if calf_l:
			calf_l.rotation.x = max(0, leg_swing * 0.5)
		if calf_r:
			calf_r.rotation.x = max(0, -leg_swing * 0.5)
	
	if body_parts.has("arms"):
		var arms = body_parts["arms"]
		var upper_l = arms.get_node_or_null("UpperArmL")
		var upper_r = arms.get_node_or_null("UpperArmR")
		
		if upper_l:
			upper_l.rotation.x = -arm_swing
		if upper_r:
			upper_r.rotation.x = arm_swing

func set_moving(moving: bool, vel: Vector3 = Vector3.ZERO):
	is_moving = moving
	velocity = vel
	if moving:
		animation_speed = vel.length() / 5.0

func set_crouching(crouch: bool):
	is_crouching = crouch

func set_skin_color(color: Color):
	skin_color = color
	_update_materials()

func set_hair_color(color: Color):
	hair_color = color
	_update_materials()

func set_clothing_color(color: Color):
	clothing_color = color
	_update_materials()

func _update_materials():
	pass

func equip_item(slot: String, item_mesh: Mesh):
	if equipment_slots.has(slot):
		equipment_slots[slot].queue_free()
	
	var item = MeshInstance3D.new()
	item.mesh = item_mesh
	
	match slot:
		"helmet":
			item.position = Vector3(0, body_height * 0.95, 0)
			if body_parts.has("head"):
				body_parts["head"].add_child(item)
		"chestplate":
			item.position = Vector3(0, body_height * 0.70, 0)
			if body_parts.has("clothing"):
				body_parts["clothing"].add_child(item)
	
	equipment_slots[slot] = item

func unequip_item(slot: String):
	if equipment_slots.has(slot):
		equipment_slots[slot].queue_free()
		equipment_slots.erase(slot)
