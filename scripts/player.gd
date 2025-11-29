extends CharacterBody3D

@export var speed := 5.0
@export var sprint_multiplier := 1.4
@export var crouch_multiplier := 0.6
@export var mouse_sens := 0.06
@export var gravity := 20.0
@export var jump_force := 8.0
@export var double_jump_force := 6.0
@export var acceleration := 12.0
@export var deceleration := 16.0
@export var friction := 8.0
@export var camera_smoothing := 0.15
@export var coyote_time := 0.15
@export var jump_buffer_time := 0.1
@export var max_jumps := 2

var inventory = null
var combat = null
var progression = null
var camera: Camera3D = null
var net_id := 1
var health := 100.0
var max_health := 100.0
var stamina := 100.0
var max_stamina := 100.0
var hunger := 100.0
var thirst := 100.0
var sanity := 100.0
var blood := 100.0
var body_temperature := 37.0

var target_velocity := Vector3.ZERO
var camera_yaw := 0.0
var camera_pitch := 0.0
var target_yaw := 0.0
var target_pitch := 0.0

var jumps_remaining := 2
var coyote_timer := 0.0
var jump_buffer_timer := 0.0
var was_on_floor := true
var is_jumping := false

func _ready():
        Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
        camera = get_node_or_null("Camera3D")
        inventory = get_node_or_null("/root/Inventory")
        combat = get_node_or_null("Combat")
        progression = get_node_or_null("/root/PlayerProgression")
        add_to_group("players")
        
        var gm = get_node_or_null("/root/GameManager")
        if gm and gm.get("mouse_sensitivity") != null:
                mouse_sens = gm.mouse_sensitivity
        
        if progression:
                progression.ensure_player(net_id)
                _sync_stats_from_progression()
        
        var ss = get_node_or_null("/root/StatsSystem")
        if ss:
                ss.create_player(net_id)

func _input(event):
        if event is InputEventMouseMotion and camera:
                target_yaw -= event.relative.x * mouse_sens
                target_pitch -= event.relative.y * mouse_sens
                target_pitch = clamp(target_pitch, -85.0, 85.0)
        
        if event.is_action_pressed("attack"):
                _attack()
        
        if event.is_action_pressed("interact"):
                interact()
        
        if event.is_action_pressed("jump"):
                jump_buffer_timer = jump_buffer_time
                _try_jump()

func _physics_process(delta):
        _process_survival(delta)
        
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
        
        var speed_mult = get_speed_modifier()
        if is_sprinting:
                speed_mult *= sprint_multiplier
                stamina -= 15.0 * delta
        elif is_crouching:
                speed_mult *= crouch_multiplier
        
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
        
        _process_jump(delta)
        
        if not is_on_floor():
                velocity.y -= gravity * delta
        
        move_and_slide()
        
        was_on_floor = is_on_floor()
        
        if not is_sprinting:
                stamina = min(max_stamina, stamina + 8.0 * delta)

func _process_jump(delta: float):
        if is_on_floor():
                jumps_remaining = max_jumps
                coyote_timer = coyote_time
                is_jumping = false
        else:
                coyote_timer -= delta
        
        jump_buffer_timer -= delta
        
        if jump_buffer_timer > 0 and jumps_remaining > 0:
                _try_jump()
                jump_buffer_timer = 0

func _try_jump():
        if jumps_remaining <= 0:
                return
        
        if stamina < 5:
                return
        
        var can_jump = is_on_floor() or coyote_timer > 0 or jumps_remaining < max_jumps
        
        if can_jump:
                var force = jump_force if jumps_remaining == max_jumps else double_jump_force
                velocity.y = force
                jumps_remaining -= 1
                is_jumping = true
                coyote_timer = 0
                stamina -= 5.0
                
                if progression:
                        progression.add_skill_xp(net_id, "athletics", 0.5)

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
                var damage = 15.0 * get_damage_modifier()
                if target and target.has_method("apply_damage"):
                        target.apply_damage(damage, self)
                        if progression:
                                progression.add_skill_xp(net_id, "melee", 2.0)

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
        if source and randf() < 0.3:
                blood -= amount * 0.5
                blood = max(0, blood)
        if health <= 0:
                _die()

func apply_bleeding(amount: float):
        blood -= amount
        blood = max(0, blood)
        if progression:
                progression.modify_stat(net_id, "blood", -amount)

func _die():
        if progression:
                progression.apply_death_penalties(net_id)
        health = max_health * 0.5
        stamina = max_stamina * 0.5
        hunger = 50.0
        thirst = 50.0
        blood = 100.0
        global_position = Vector3(0, 2, 0)

func get_health() -> float:
        return health

func get_hunger() -> float:
        return hunger

func get_thirst() -> float:
        return thirst

func get_sanity() -> float:
        return sanity

func get_blood() -> float:
        return blood

func consume_food(amount: float):
        hunger = min(100, hunger + amount)
        if progression:
                progression.modify_stat(net_id, "hunger", amount)

func consume_water(amount: float):
        thirst = min(100, thirst + amount)
        if progression:
                progression.modify_stat(net_id, "thirst", amount)

func heal(amount: float):
        health = min(max_health, health + amount)

func set_mouse_sensitivity(value: float):
        mouse_sens = clamp(value, 0.01, 0.2)

func _sync_stats_from_progression():
        if not progression:
                return
        var p = progression.get_player(net_id)
        if p.is_empty():
                return
        max_health = p.stats.max_health
        max_stamina = p.stats.max_stamina
        health = p.stats.health
        stamina = p.stats.stamina
        hunger = p.stats.hunger
        thirst = p.stats.thirst
        sanity = p.stats.sanity
        blood = p.stats.blood
        body_temperature = p.stats.temperature

func _process_survival(delta: float):
        hunger -= 0.05 * delta
        thirst -= 0.08 * delta
        
        if hunger <= 0:
                health -= 0.5 * delta
        if thirst <= 0:
                health -= 1.0 * delta
        if blood < 50:
                health -= 0.3 * delta
        
        if blood < 100:
                blood += 0.1 * delta
        
        hunger = clamp(hunger, 0, 100)
        thirst = clamp(thirst, 0, 100)
        blood = clamp(blood, 0, 100)
        health = clamp(health, 0, max_health)
        
        if health <= 0:
                _die()

func get_speed_modifier() -> float:
        var mod := 1.0
        if progression:
                mod *= progression.get_debuff_modifier(net_id, "speed_mult")
        if hunger < 20:
                mod *= 0.8
        if thirst < 20:
                mod *= 0.85
        if blood < 30:
                mod *= 0.7
        return mod

func get_damage_modifier() -> float:
        var mod := 1.0
        if progression:
                mod *= progression.get_debuff_modifier(net_id, "damage_mult")
                var strength = progression.get_attribute(net_id, "strength")
                mod *= 1.0 + (strength - 5) * 0.05
        return mod

func get_luck_bonus() -> float:
        var luck := 0.0
        if progression:
                luck = progression.get_attribute(net_id, "luck")
        return luck

func get_jumps_remaining() -> int:
        return jumps_remaining

func is_on_ground() -> bool:
        return is_on_floor()
