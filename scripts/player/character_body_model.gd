extends Node3D

signal animation_started(anim_name: String)
signal animation_finished(anim_name: String)

enum BodyPart { HEAD, TORSO, LEFT_ARM, RIGHT_ARM, LEFT_LEG, RIGHT_LEG }
enum AnimState { IDLE, WALK, RUN, JUMP, CROUCH, ATTACK, GATHER, SWIM }

@export_category("Внешность персонажа")
@export var skin_color := Color(0.87, 0.72, 0.62)
@export var hair_color := Color(0.25, 0.18, 0.12)
@export var pants_color := Color(0.22, 0.28, 0.35)
@export var shirt_color := Color(0.35, 0.32, 0.28)
@export var boots_color := Color(0.18, 0.14, 0.10)

@export_category("Анатомия")
@export var body_height := 1.8
@export var shoulder_width := 0.45
@export var hip_width := 0.35
@export var arm_length := 0.65
@export var leg_length := 0.85
@export var head_size := 0.22

@export_category("Анимация")
@export var walk_speed := 6.0
@export var run_speed := 10.0
@export var arm_swing := 25.0
@export var leg_swing := 35.0

var current_state := AnimState.IDLE
var anim_time := 0.0
var blend_time := 0.0
var is_first_person := true

var skeleton: Dictionary = {}
var meshes: Dictionary = {}

var materials := {
	"skin": null,
	"hair": null,
	"pants": null,
	"shirt": null,
	"boots": null
}

func _ready():
	_create_materials()
	_build_skeleton()
	_build_body()
	
	if is_first_person:
		_set_first_person_visibility()

func _create_materials():
	materials["skin"] = StandardMaterial3D.new()
	materials["skin"].albedo_color = skin_color
	materials["skin"].roughness = 0.75
	materials["skin"].metallic = 0.0
	materials["skin"].diffuse_mode = BaseMaterial3D.DIFFUSE_BURLEY
	materials["skin"].specular_mode = BaseMaterial3D.SPECULAR_SCHLICK_GGX
	
	materials["hair"] = StandardMaterial3D.new()
	materials["hair"].albedo_color = hair_color
	materials["hair"].roughness = 0.85
	
	materials["pants"] = StandardMaterial3D.new()
	materials["pants"].albedo_color = pants_color
	materials["pants"].roughness = 0.9
	
	materials["shirt"] = StandardMaterial3D.new()
	materials["shirt"].albedo_color = shirt_color
	materials["shirt"].roughness = 0.85
	
	materials["boots"] = StandardMaterial3D.new()
	materials["boots"].albedo_color = boots_color
	materials["boots"].roughness = 0.95

func _build_skeleton():
	skeleton["root"] = self
	
	skeleton["pelvis"] = Node3D.new()
	skeleton["pelvis"].name = "Pelvis"
	skeleton["pelvis"].position = Vector3(0, leg_length, 0)
	add_child(skeleton["pelvis"])
	
	skeleton["spine"] = Node3D.new()
	skeleton["spine"].name = "Spine"
	skeleton["spine"].position = Vector3(0, 0.25, 0)
	skeleton["pelvis"].add_child(skeleton["spine"])
	
	skeleton["chest"] = Node3D.new()
	skeleton["chest"].name = "Chest"
	skeleton["chest"].position = Vector3(0, 0.25, 0)
	skeleton["spine"].add_child(skeleton["chest"])
	
	skeleton["neck"] = Node3D.new()
	skeleton["neck"].name = "Neck"
	skeleton["neck"].position = Vector3(0, 0.18, 0)
	skeleton["chest"].add_child(skeleton["neck"])
	
	skeleton["head"] = Node3D.new()
	skeleton["head"].name = "Head"
	skeleton["head"].position = Vector3(0, 0.1, 0)
	skeleton["neck"].add_child(skeleton["head"])
	
	skeleton["left_shoulder"] = Node3D.new()
	skeleton["left_shoulder"].name = "LeftShoulder"
	skeleton["left_shoulder"].position = Vector3(-shoulder_width / 2, 0.12, 0)
	skeleton["chest"].add_child(skeleton["left_shoulder"])
	
	skeleton["right_shoulder"] = Node3D.new()
	skeleton["right_shoulder"].name = "RightShoulder"
	skeleton["right_shoulder"].position = Vector3(shoulder_width / 2, 0.12, 0)
	skeleton["chest"].add_child(skeleton["right_shoulder"])
	
	skeleton["left_upper_arm"] = Node3D.new()
	skeleton["left_upper_arm"].name = "LeftUpperArm"
	skeleton["left_upper_arm"].position = Vector3(-0.08, -0.02, 0)
	skeleton["left_shoulder"].add_child(skeleton["left_upper_arm"])
	
	skeleton["right_upper_arm"] = Node3D.new()
	skeleton["right_upper_arm"].name = "RightUpperArm"
	skeleton["right_upper_arm"].position = Vector3(0.08, -0.02, 0)
	skeleton["right_shoulder"].add_child(skeleton["right_upper_arm"])
	
	skeleton["left_forearm"] = Node3D.new()
	skeleton["left_forearm"].name = "LeftForearm"
	skeleton["left_forearm"].position = Vector3(0, -arm_length * 0.45, 0)
	skeleton["left_upper_arm"].add_child(skeleton["left_forearm"])
	
	skeleton["right_forearm"] = Node3D.new()
	skeleton["right_forearm"].name = "RightForearm"
	skeleton["right_forearm"].position = Vector3(0, -arm_length * 0.45, 0)
	skeleton["right_upper_arm"].add_child(skeleton["right_forearm"])
	
	skeleton["left_hand"] = Node3D.new()
	skeleton["left_hand"].name = "LeftHand"
	skeleton["left_hand"].position = Vector3(0, -arm_length * 0.45, 0)
	skeleton["left_forearm"].add_child(skeleton["left_hand"])
	
	skeleton["right_hand"] = Node3D.new()
	skeleton["right_hand"].name = "RightHand"
	skeleton["right_hand"].position = Vector3(0, -arm_length * 0.45, 0)
	skeleton["right_forearm"].add_child(skeleton["right_hand"])
	
	skeleton["left_hip"] = Node3D.new()
	skeleton["left_hip"].name = "LeftHip"
	skeleton["left_hip"].position = Vector3(-hip_width / 2, 0, 0)
	skeleton["pelvis"].add_child(skeleton["left_hip"])
	
	skeleton["right_hip"] = Node3D.new()
	skeleton["right_hip"].name = "RightHip"
	skeleton["right_hip"].position = Vector3(hip_width / 2, 0, 0)
	skeleton["pelvis"].add_child(skeleton["right_hip"])
	
	skeleton["left_thigh"] = Node3D.new()
	skeleton["left_thigh"].name = "LeftThigh"
	skeleton["left_thigh"].position = Vector3(0, -0.05, 0)
	skeleton["left_hip"].add_child(skeleton["left_thigh"])
	
	skeleton["right_thigh"] = Node3D.new()
	skeleton["right_thigh"].name = "RightThigh"
	skeleton["right_thigh"].position = Vector3(0, -0.05, 0)
	skeleton["right_hip"].add_child(skeleton["right_thigh"])
	
	skeleton["left_shin"] = Node3D.new()
	skeleton["left_shin"].name = "LeftShin"
	skeleton["left_shin"].position = Vector3(0, -leg_length * 0.48, 0)
	skeleton["left_thigh"].add_child(skeleton["left_shin"])
	
	skeleton["right_shin"] = Node3D.new()
	skeleton["right_shin"].name = "RightShin"
	skeleton["right_shin"].position = Vector3(0, -leg_length * 0.48, 0)
	skeleton["right_thigh"].add_child(skeleton["right_shin"])
	
	skeleton["left_foot"] = Node3D.new()
	skeleton["left_foot"].name = "LeftFoot"
	skeleton["left_foot"].position = Vector3(0, -leg_length * 0.48, 0)
	skeleton["left_shin"].add_child(skeleton["left_foot"])
	
	skeleton["right_foot"] = Node3D.new()
	skeleton["right_foot"].name = "RightFoot"
	skeleton["right_foot"].position = Vector3(0, -leg_length * 0.48, 0)
	skeleton["right_shin"].add_child(skeleton["right_foot"])

func _build_body():
	_create_head()
	_create_torso()
	_create_arms()
	_create_legs()

func _create_head():
	var head_mesh = MeshInstance3D.new()
	head_mesh.name = "HeadMesh"
	var sphere = SphereMesh.new()
	sphere.radius = head_size * 0.5
	sphere.height = head_size
	head_mesh.mesh = sphere
	head_mesh.material_override = materials["skin"]
	skeleton["head"].add_child(head_mesh)
	meshes["head"] = head_mesh
	
	var hair_mesh = MeshInstance3D.new()
	hair_mesh.name = "HairMesh"
	var hair = SphereMesh.new()
	hair.radius = head_size * 0.52
	hair.height = head_size * 0.6
	hair_mesh.mesh = hair
	hair_mesh.position = Vector3(0, 0.03, -0.02)
	hair_mesh.material_override = materials["hair"]
	skeleton["head"].add_child(hair_mesh)
	meshes["hair"] = hair_mesh

func _create_torso():
	var pelvis_mesh = MeshInstance3D.new()
	pelvis_mesh.name = "PelvisMesh"
	var pelvis_box = BoxMesh.new()
	pelvis_box.size = Vector3(hip_width, 0.18, 0.18)
	pelvis_mesh.mesh = pelvis_box
	pelvis_mesh.position = Vector3(0, 0.05, 0)
	pelvis_mesh.material_override = materials["pants"]
	skeleton["pelvis"].add_child(pelvis_mesh)
	meshes["pelvis"] = pelvis_mesh
	
	var spine_mesh = MeshInstance3D.new()
	spine_mesh.name = "SpineMesh"
	var spine_box = BoxMesh.new()
	spine_box.size = Vector3(0.28, 0.22, 0.16)
	spine_mesh.mesh = spine_box
	spine_mesh.material_override = materials["shirt"]
	skeleton["spine"].add_child(spine_mesh)
	meshes["spine"] = spine_mesh
	
	var chest_mesh = MeshInstance3D.new()
	chest_mesh.name = "ChestMesh"
	var chest_box = BoxMesh.new()
	chest_box.size = Vector3(shoulder_width - 0.05, 0.28, 0.2)
	chest_mesh.mesh = chest_box
	chest_mesh.material_override = materials["shirt"]
	skeleton["chest"].add_child(chest_mesh)
	meshes["chest"] = chest_mesh
	
	var neck_mesh = MeshInstance3D.new()
	neck_mesh.name = "NeckMesh"
	var neck_cyl = CylinderMesh.new()
	neck_cyl.top_radius = 0.05
	neck_cyl.bottom_radius = 0.06
	neck_cyl.height = 0.1
	neck_mesh.mesh = neck_cyl
	neck_mesh.material_override = materials["skin"]
	skeleton["neck"].add_child(neck_mesh)
	meshes["neck"] = neck_mesh

func _create_arms():
	_create_arm("left")
	_create_arm("right")

func _create_arm(side: String):
	var upper_arm_mesh = MeshInstance3D.new()
	upper_arm_mesh.name = side.capitalize() + "UpperArmMesh"
	var upper = CapsuleMesh.new()
	upper.radius = 0.045
	upper.height = arm_length * 0.45
	upper_arm_mesh.mesh = upper
	upper_arm_mesh.position = Vector3(0, -arm_length * 0.22, 0)
	upper_arm_mesh.material_override = materials["shirt"]
	skeleton[side + "_upper_arm"].add_child(upper_arm_mesh)
	meshes[side + "_upper_arm"] = upper_arm_mesh
	
	var forearm_mesh = MeshInstance3D.new()
	forearm_mesh.name = side.capitalize() + "ForearmMesh"
	var forearm = CapsuleMesh.new()
	forearm.radius = 0.04
	forearm.height = arm_length * 0.42
	forearm_mesh.mesh = forearm
	forearm_mesh.position = Vector3(0, -arm_length * 0.2, 0)
	forearm_mesh.material_override = materials["skin"]
	skeleton[side + "_forearm"].add_child(forearm_mesh)
	meshes[side + "_forearm"] = forearm_mesh
	
	_create_hand(side)

func _create_hand(side: String):
	var hand_bone = skeleton[side + "_hand"]
	
	var palm = MeshInstance3D.new()
	palm.name = "Palm"
	var palm_mesh = BoxMesh.new()
	palm_mesh.size = Vector3(0.08, 0.1, 0.035)
	palm.mesh = palm_mesh
	palm.material_override = materials["skin"]
	hand_bone.add_child(palm)
	meshes[side + "_palm"] = palm
	
	var fingers_data = [
		{"name": "Index", "offset": Vector3(-0.025, -0.08, 0), "length": 0.065},
		{"name": "Middle", "offset": Vector3(-0.008, -0.085, 0), "length": 0.07},
		{"name": "Ring", "offset": Vector3(0.012, -0.08, 0), "length": 0.065},
		{"name": "Pinky", "offset": Vector3(0.03, -0.07, 0), "length": 0.05}
	]
	
	for finger_data in fingers_data:
		var finger = _create_finger_chain(finger_data["length"], 3)
		finger.name = finger_data["name"]
		finger.position = finger_data["offset"]
		hand_bone.add_child(finger)
	
	var thumb = _create_finger_chain(0.05, 2)
	thumb.name = "Thumb"
	thumb.position = Vector3(-0.045 if side == "left" else 0.045, -0.02, 0.015)
	thumb.rotation_degrees = Vector3(0, 0, -45 if side == "left" else 45)
	hand_bone.add_child(thumb)

func _create_finger_chain(total_length: float, segments: int) -> Node3D:
	var root = Node3D.new()
	var seg_length = total_length / segments
	var current_node = root
	
	for i in range(segments):
		var seg = MeshInstance3D.new()
		seg.name = "Segment" + str(i)
		var capsule = CapsuleMesh.new()
		capsule.radius = 0.008 - i * 0.001
		capsule.height = seg_length
		seg.mesh = capsule
		seg.position = Vector3(0, -seg_length * 0.5, 0)
		seg.material_override = materials["skin"]
		current_node.add_child(seg)
		
		if i < segments - 1:
			var joint = Node3D.new()
			joint.name = "Joint" + str(i)
			joint.position = Vector3(0, -seg_length * 0.5, 0)
			seg.add_child(joint)
			current_node = joint
	
	return root

func _create_legs():
	_create_leg("left")
	_create_leg("right")

func _create_leg(side: String):
	var thigh_mesh = MeshInstance3D.new()
	thigh_mesh.name = side.capitalize() + "ThighMesh"
	var thigh = CapsuleMesh.new()
	thigh.radius = 0.075
	thigh.height = leg_length * 0.48
	thigh_mesh.mesh = thigh
	thigh_mesh.position = Vector3(0, -leg_length * 0.24, 0)
	thigh_mesh.material_override = materials["pants"]
	skeleton[side + "_thigh"].add_child(thigh_mesh)
	meshes[side + "_thigh"] = thigh_mesh
	
	var shin_mesh = MeshInstance3D.new()
	shin_mesh.name = side.capitalize() + "ShinMesh"
	var shin = CapsuleMesh.new()
	shin.radius = 0.055
	shin.height = leg_length * 0.46
	shin_mesh.mesh = shin
	shin_mesh.position = Vector3(0, -leg_length * 0.23, 0)
	shin_mesh.material_override = materials["pants"]
	skeleton[side + "_shin"].add_child(shin_mesh)
	meshes[side + "_shin"] = shin_mesh
	
	var foot_mesh = MeshInstance3D.new()
	foot_mesh.name = side.capitalize() + "FootMesh"
	var foot = BoxMesh.new()
	foot.size = Vector3(0.1, 0.08, 0.22)
	foot_mesh.mesh = foot
	foot_mesh.position = Vector3(0, -0.02, 0.05)
	foot_mesh.material_override = materials["boots"]
	skeleton[side + "_foot"].add_child(foot_mesh)
	meshes[side + "_foot"] = foot_mesh

func _set_first_person_visibility():
	if meshes.has("head"):
		meshes["head"].visible = false
	if meshes.has("hair"):
		meshes["hair"].visible = false
	if meshes.has("neck"):
		meshes["neck"].visible = false
	if meshes.has("chest"):
		meshes["chest"].visible = false
	if meshes.has("spine"):
		meshes["spine"].visible = false
	if meshes.has("pelvis"):
		meshes["pelvis"].visible = false
	if meshes.has("left_upper_arm"):
		meshes["left_upper_arm"].visible = false
	if meshes.has("right_upper_arm"):
		meshes["right_upper_arm"].visible = false

func set_first_person_mode(enabled: bool):
	is_first_person = enabled
	if enabled:
		_set_first_person_visibility()
	else:
		for mesh in meshes.values():
			if mesh:
				mesh.visible = true

func _process(delta: float):
	anim_time += delta
	_update_animation(delta)

func _update_animation(delta: float):
	var player = get_parent()
	if not player or not player is CharacterBody3D:
		return
	
	var velocity = player.velocity
	var is_grounded = player.is_on_floor()
	var speed = Vector2(velocity.x, velocity.z).length()
	
	var new_state = AnimState.IDLE
	if not is_grounded:
		new_state = AnimState.JUMP
	elif speed > 5.0:
		new_state = AnimState.RUN
	elif speed > 0.5:
		new_state = AnimState.WALK
	
	if player.get("is_crouching"):
		new_state = AnimState.CROUCH
	
	if current_state != new_state:
		current_state = new_state
		emit_signal("animation_started", AnimState.keys()[current_state])
	
	match current_state:
		AnimState.IDLE:
			_animate_idle(delta)
		AnimState.WALK:
			_animate_walk(delta, false)
		AnimState.RUN:
			_animate_walk(delta, true)
		AnimState.JUMP:
			_animate_jump(delta)
		AnimState.CROUCH:
			_animate_crouch(delta)

func _animate_idle(delta: float):
	var breath = sin(anim_time * 1.5) * 0.005
	if skeleton.has("chest"):
		skeleton["chest"].position.y = 0.25 + breath
	
	_reset_limbs(delta)

func _animate_walk(delta: float, is_running: bool):
	var speed = run_speed if is_running else walk_speed
	var swing_mult = 1.4 if is_running else 1.0
	
	var phase = anim_time * speed
	
	if skeleton.has("left_thigh"):
		skeleton["left_thigh"].rotation_degrees.x = sin(phase) * leg_swing * swing_mult
	if skeleton.has("right_thigh"):
		skeleton["right_thigh"].rotation_degrees.x = sin(phase + PI) * leg_swing * swing_mult
	
	if skeleton.has("left_shin"):
		var knee_bend = max(0, -sin(phase)) * 45.0 * swing_mult
		skeleton["left_shin"].rotation_degrees.x = knee_bend
	if skeleton.has("right_shin"):
		var knee_bend = max(0, -sin(phase + PI)) * 45.0 * swing_mult
		skeleton["right_shin"].rotation_degrees.x = knee_bend
	
	if not is_first_person:
		if skeleton.has("left_upper_arm"):
			skeleton["left_upper_arm"].rotation_degrees.x = sin(phase + PI) * arm_swing * swing_mult
		if skeleton.has("right_upper_arm"):
			skeleton["right_upper_arm"].rotation_degrees.x = sin(phase) * arm_swing * swing_mult

func _animate_jump(delta: float):
	if skeleton.has("left_thigh"):
		skeleton["left_thigh"].rotation_degrees.x = lerp(skeleton["left_thigh"].rotation_degrees.x, -25.0, 8.0 * delta)
	if skeleton.has("right_thigh"):
		skeleton["right_thigh"].rotation_degrees.x = lerp(skeleton["right_thigh"].rotation_degrees.x, -25.0, 8.0 * delta)
	
	if skeleton.has("left_shin"):
		skeleton["left_shin"].rotation_degrees.x = lerp(skeleton["left_shin"].rotation_degrees.x, 35.0, 8.0 * delta)
	if skeleton.has("right_shin"):
		skeleton["right_shin"].rotation_degrees.x = lerp(skeleton["right_shin"].rotation_degrees.x, 35.0, 8.0 * delta)

func _animate_crouch(delta: float):
	if skeleton.has("pelvis"):
		skeleton["pelvis"].position.y = lerp(skeleton["pelvis"].position.y, leg_length * 0.6, 5.0 * delta)
	
	if skeleton.has("left_thigh"):
		skeleton["left_thigh"].rotation_degrees.x = lerp(skeleton["left_thigh"].rotation_degrees.x, -80.0, 5.0 * delta)
	if skeleton.has("right_thigh"):
		skeleton["right_thigh"].rotation_degrees.x = lerp(skeleton["right_thigh"].rotation_degrees.x, -80.0, 5.0 * delta)
	
	if skeleton.has("left_shin"):
		skeleton["left_shin"].rotation_degrees.x = lerp(skeleton["left_shin"].rotation_degrees.x, 90.0, 5.0 * delta)
	if skeleton.has("right_shin"):
		skeleton["right_shin"].rotation_degrees.x = lerp(skeleton["right_shin"].rotation_degrees.x, 90.0, 5.0 * delta)

func _reset_limbs(delta: float):
	var lerp_speed = 5.0
	
	if skeleton.has("pelvis"):
		skeleton["pelvis"].position.y = lerp(skeleton["pelvis"].position.y, leg_length, lerp_speed * delta)
	
	for bone_name in ["left_thigh", "right_thigh", "left_shin", "right_shin", "left_upper_arm", "right_upper_arm"]:
		if skeleton.has(bone_name):
			skeleton[bone_name].rotation_degrees.x = lerp(skeleton[bone_name].rotation_degrees.x, 0.0, lerp_speed * delta)

func play_attack_animation():
	current_state = AnimState.ATTACK
	emit_signal("animation_started", "attack")

func play_gather_animation():
	current_state = AnimState.GATHER
	emit_signal("animation_started", "gather")

func get_right_hand() -> Node3D:
	return skeleton.get("right_hand")

func get_left_hand() -> Node3D:
	return skeleton.get("left_hand")

func set_skin_color(color: Color):
	skin_color = color
	if materials["skin"]:
		materials["skin"].albedo_color = color

func set_hair_color(color: Color):
	hair_color = color
	if materials["hair"]:
		materials["hair"].albedo_color = color

func set_clothing_colors(shirt: Color, pants: Color, boots: Color):
	shirt_color = shirt
	pants_color = pants
	boots_color = boots
	if materials["shirt"]:
		materials["shirt"].albedo_color = shirt
	if materials["pants"]:
		materials["pants"].albedo_color = pants
	if materials["boots"]:
		materials["boots"].albedo_color = boots
