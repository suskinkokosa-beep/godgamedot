extends BaseAI

signal mob_died(mob)
signal mob_damaged(mob, damage, attacker)

@export var speed := 3.0
@export var run_speed := 5.0
@export var agro_range := 14.0
@export var attack_range := 1.8
@export var attack_damage := 20
@export var attack_cooldown := 1.5
@export var patrol_radius := 15.0
@export var flee_health_threshold := 0.2
@export var is_passive := false
@export var is_nocturnal := false

var health := 120.0
var max_health := 120.0
var attack_timer := 0.0
var patrol_target := Vector3.ZERO
var home_position := Vector3.ZERO
var flee_direction := Vector3.ZERO
var idle_timer := 0.0
var patrol_wait_time := 0.0

var body: CharacterBody3D = null
var nav_agent: NavigationAgent3D = null

func _ready():
	home_position = global_transform.origin
	patrol_target = home_position
	
	body = get_parent() as CharacterBody3D
	nav_agent = get_node_or_null("../NavigationAgent3D")
	
	set_state(State.IDLE)
	idle_timer = randf_range(1.0, 5.0)

func _process(delta):
	attack_timer = max(0, attack_timer - delta)
	super._process(delta)

func _on_idle(delta):
	idle_timer -= delta
	
	if idle_timer <= 0:
		_pick_patrol_point()
		set_state(State.PATROL)
		return
	
	if not is_passive:
		_check_for_targets()

func _on_patrol(delta):
	if patrol_wait_time > 0:
		patrol_wait_time -= delta
		if patrol_wait_time <= 0:
			_pick_patrol_point()
		return
	
	var direction = (patrol_target - global_transform.origin)
	direction.y = 0
	var distance = direction.length()
	
	if distance < 1.0:
		patrol_wait_time = randf_range(2.0, 6.0)
		return
	
	direction = direction.normalized()
	_move_towards(direction, speed, delta)
	_look_at_direction(direction, delta)
	
	if not is_passive:
		_check_for_targets()

func _on_chase(delta):
	if not is_instance_valid(target):
		target = null
		set_state(State.IDLE)
		idle_timer = randf_range(1.0, 3.0)
		return
	
	var direction = (target.global_transform.origin - global_transform.origin)
	direction.y = 0
	var distance = direction.length()
	
	if distance > agro_range * 1.5:
		target = null
		set_state(State.PATROL)
		_pick_patrol_point()
		return
	
	if distance <= attack_range:
		set_state(State.ATTACK)
		return
	
	direction = direction.normalized()
	_move_towards(direction, run_speed, delta)
	_look_at_direction(direction, delta)

func _on_attack(delta):
	if not is_instance_valid(target):
		target = null
		set_state(State.IDLE)
		return
	
	var distance = global_transform.origin.distance_to(target.global_transform.origin)
	
	if distance > attack_range * 1.2:
		set_state(State.CHASE)
		return
	
	var direction = (target.global_transform.origin - global_transform.origin).normalized()
	_look_at_direction(direction, delta)
	
	if attack_timer <= 0:
		_perform_attack()
		attack_timer = attack_cooldown

func _on_flee(delta):
	if health / max_health > flee_health_threshold * 1.5:
		set_state(State.IDLE)
		idle_timer = randf_range(2.0, 5.0)
		return
	
	if flee_direction == Vector3.ZERO:
		if is_instance_valid(target):
			flee_direction = (global_transform.origin - target.global_transform.origin).normalized()
		else:
			flee_direction = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized()
	
	_move_towards(flee_direction, run_speed, delta)
	_look_at_direction(flee_direction, delta)
	
	if randf() < 0.01:
		flee_direction = Vector3.ZERO

func _move_towards(direction: Vector3, move_speed: float, delta: float):
	if body:
		body.velocity = direction * move_speed
		body.velocity.y = -9.8
		body.move_and_slide()
	else:
		global_transform.origin += direction * move_speed * delta

func _look_at_direction(direction: Vector3, delta: float):
	if direction.length() < 0.1:
		return
	
	var target_rot = atan2(direction.x, direction.z)
	var parent = get_parent()
	if parent:
		parent.rotation.y = lerp_angle(parent.rotation.y, target_rot, 5.0 * delta)

func _pick_patrol_point():
	var offset = Vector3(
		randf_range(-patrol_radius, patrol_radius),
		0,
		randf_range(-patrol_radius, patrol_radius)
	)
	patrol_target = home_position + offset

func _check_for_targets():
	var players = get_tree().get_nodes_in_group("players")
	for p in players:
		var dist = global_transform.origin.distance_to(p.global_transform.origin)
		if dist < agro_range:
			target = p
			set_state(State.CHASE)
			return

func _perform_attack():
	if not is_instance_valid(target):
		return
	
	if target.has_method("apply_damage"):
		target.apply_damage(attack_damage, get_parent())
	
	var vfx = get_node_or_null("/root/VFXManager")
	if vfx:
		vfx.spawn_hit_effect(target.global_transform.origin + Vector3(0, 1, 0), "flesh")
	
	var audio = get_node_or_null("/root/AudioManager")
	if audio:
		audio.play_hit_sound("flesh")

func take_damage(amount: float, attacker = null):
	health -= amount
	emit_signal("mob_damaged", get_parent(), amount, attacker)
	
	var vfx = get_node_or_null("/root/VFXManager")
	if vfx:
		vfx.spawn_damage_numbers(global_transform.origin + Vector3(0, 2, 0), amount)
		vfx.spawn_hit_effect(global_transform.origin + Vector3(0, 1, 0), "flesh")
	
	if health <= 0:
		_die()
		return
	
	if health / max_health < flee_health_threshold and not is_passive:
		flee_direction = Vector3.ZERO
		set_state(State.FLEE)
	elif attacker and state != State.ATTACK and state != State.CHASE:
		target = attacker
		set_state(State.CHASE)

func _die():
	emit_signal("mob_died", get_parent())
	
	var vfx = get_node_or_null("/root/VFXManager")
	if vfx:
		vfx.spawn_death_effect(global_transform.origin + Vector3(0, 0.5, 0), "mob")
	
	var loot = get_node_or_null("/root/LootSystem")
	if loot and loot.has_method("drop_loot"):
		loot.drop_loot(get_parent().name.to_lower(), global_transform.origin)
	
	var parent = get_parent()
	if parent:
		parent.queue_free()
