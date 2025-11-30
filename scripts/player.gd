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
var first_person_arms = null
var first_person_legs = null
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

var is_crouching := false
var default_height := 1.8
var crouch_height := 0.9
var default_camera_height := 1.6
var crouch_camera_height := 0.7
var current_height := 1.8
var crouch_transition_speed := 8.0

var collision_shape: CollisionShape3D = null

var is_spawning := true
var spawn_grace_timer := 5.0
var spawn_check_timer := 0.0
var spawn_attempts := 0
var max_spawn_attempts := 30

func _ready():
        Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
        camera = get_node_or_null("Camera3D")
        collision_shape = get_node_or_null("CollisionShape3D")
        inventory = get_node_or_null("/root/Inventory")
        combat = get_node_or_null("Combat")
        progression = get_node_or_null("/root/PlayerProgression")
        add_to_group("players")
        
        if camera:
                first_person_arms = camera.get_node_or_null("FirstPersonArms")
                first_person_legs = camera.get_node_or_null("FirstPersonLegs")
        
        if collision_shape and collision_shape.shape is CapsuleShape3D:
                default_height = collision_shape.shape.height
                crouch_height = default_height * 0.5
        
        if camera:
                default_camera_height = camera.position.y
                crouch_camera_height = default_camera_height * 0.5
        
        var gm = get_node_or_null("/root/GameManager")
        if gm and gm.get("mouse_sensitivity") != null:
                mouse_sens = gm.mouse_sensitivity
        
        if progression:
                progression.ensure_player(net_id)
                _sync_stats_from_progression()
        
        var ss = get_node_or_null("/root/StatsSystem")
        if ss:
                ss.create_player(net_id)
        
        is_spawning = true
        spawn_grace_timer = 5.0
        spawn_attempts = 0
        call_deferred("_safe_spawn")

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
        
        if event is InputEventKey and event.pressed:
                var key = event.keycode
                if key >= KEY_1 and key <= KEY_8:
                        var slot = key - KEY_1
                        if inventory and inventory.has_method("select_hotbar_slot"):
                                inventory.select_hotbar_slot(slot)
        
        if event is InputEventMouseButton:
                if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
                        if inventory and inventory.has_method("get_selected_hotbar_slot"):
                                var current = inventory.get_selected_hotbar_slot()
                                inventory.select_hotbar_slot((current - 1 + 8) % 8)
                elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
                        if inventory and inventory.has_method("get_selected_hotbar_slot"):
                                var current = inventory.get_selected_hotbar_slot()
                                inventory.select_hotbar_slot((current + 1) % 8)

func _physics_process(delta):
        if is_spawning:
                _handle_spawn_phase(delta)
                return
        
        if spawn_grace_timer > 0:
                spawn_grace_timer -= delta
        
        _process_survival(delta)
        _update_interact_prompt()
        
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
        
        var is_sprinting = Input.is_action_pressed("sprint") and not is_crouching and stamina > 5
        var wants_crouch = Input.is_action_pressed("crouch")
        
        _process_crouch(delta, wants_crouch)
        
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
        
        var audio = get_node_or_null("/root/AudioManager")
        if audio and is_on_floor():
                var is_moving = velocity.length() > 0.5
                audio.update_footsteps(delta, is_moving, is_sprinting)
        
        if not is_sprinting:
                stamina = min(max_stamina, stamina + 8.0 * delta)

func _safe_spawn():
        var world_gen = get_node_or_null("/root/WorldGenerator")
        if not world_gen:
                await get_tree().create_timer(0.5).timeout
                if not world_gen:
                        world_gen = get_node_or_null("/root/WorldGenerator")
        
        var spawn_pos := Vector3.ZERO
        
        if world_gen and world_gen.has_method("get_height_at"):
                var best_height := -1000.0
                var found_safe := false
                
                for attempt in range(10):
                        var test_x = randf_range(-100, 100)
                        var test_z = randf_range(-100, 100)
                        var terrain_height = world_gen.get_height_at(test_x, test_z)
                        
                        var sea_level = world_gen.get("SEA_LEVEL")
                        if sea_level == null:
                                sea_level = 5.0
                        
                        if terrain_height > sea_level + 1 and terrain_height > best_height:
                                best_height = terrain_height
                                spawn_pos = Vector3(test_x, terrain_height + 3, test_z)
                                found_safe = true
                
                if not found_safe:
                        spawn_pos = Vector3(0, 50, 0)
        else:
                spawn_pos = Vector3(0, 50, 0)
        
        global_position = spawn_pos
        velocity = Vector3.ZERO

func _handle_spawn_phase(delta: float):
        spawn_check_timer += delta
        
        if spawn_check_timer < 0.1:
                return
        
        spawn_check_timer = 0
        spawn_attempts += 1
        
        velocity.y = 0
        
        var safe_y := _find_safe_ground_height()
        
        if safe_y > -900:
                global_position.y = safe_y + 2.0
                velocity = Vector3.ZERO
                is_spawning = false
                spawn_grace_timer = 5.0
                body_temperature = 37.0
                print("Player spawned safely at: ", global_position)
        elif spawn_attempts >= max_spawn_attempts:
                var world_gen = get_node_or_null("/root/WorldGenerator")
                if world_gen and world_gen.has_method("get_height_at"):
                        var terrain_h = world_gen.get_height_at(global_position.x, global_position.z)
                        var sea_level = world_gen.get("SEA_LEVEL")
                        if sea_level == null:
                                sea_level = 5.0
                        global_position.y = max(terrain_h + 3, sea_level + 5)
                else:
                        global_position.y = 20.0
                
                velocity = Vector3.ZERO
                is_spawning = false
                spawn_grace_timer = 5.0
                body_temperature = 37.0
                print("Spawn timeout, fallback position: ", global_position)
        else:
                velocity.y = 0
                global_position.y = max(global_position.y, 50)

func _find_safe_ground_height() -> float:
        var space = get_world_3d().direct_space_state
        if not space:
                return -1000.0
        
        var from = Vector3(global_position.x, global_position.y + 100, global_position.z)
        var to = Vector3(global_position.x, global_position.y - 200, global_position.z)
        
        var query = PhysicsRayQueryParameters3D.create(from, to)
        query.exclude = [self]
        query.collision_mask = 1
        
        var result = space.intersect_ray(query)
        
        if result:
                return result.position.y
        
        return -1000.0

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
        
        if is_crouching:
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

func _process_crouch(delta: float, wants_crouch: bool):
        if wants_crouch and is_on_floor():
                is_crouching = true
        elif not wants_crouch:
                if is_crouching:
                        if _can_stand_up():
                                is_crouching = false
        
        var target_height = crouch_height if is_crouching else default_height
        var target_cam_y = crouch_camera_height if is_crouching else default_camera_height
        
        current_height = lerp(current_height, target_height, crouch_transition_speed * delta)
        
        if collision_shape and collision_shape.shape is CapsuleShape3D:
                collision_shape.shape.height = current_height
                collision_shape.position.y = current_height / 2.0
        
        if camera:
                camera.position.y = lerp(camera.position.y, target_cam_y, crouch_transition_speed * delta)

func _can_stand_up() -> bool:
        if not collision_shape:
                return true
        
        var space = get_world_3d().direct_space_state
        var from = global_position + Vector3(0, current_height, 0)
        var to = global_position + Vector3(0, default_height + 0.1, 0)
        var query = PhysicsRayQueryParameters3D.create(from, to)
        query.exclude = [self]
        var result = space.intersect_ray(query)
        
        return result.is_empty()

func get_is_crouching() -> bool:
        return is_crouching

func _attack():
        if stamina < 10:
                return
        stamina -= 10
        
        var audio = get_node_or_null("/root/AudioManager")
        if audio:
                audio.play_attack_sound("melee")
        
        if first_person_arms and first_person_arms.has_method("swing"):
                first_person_arms.swing()
        
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
                var base_damage = 15.0
                if first_person_arms and first_person_arms.has_item_equipped():
                        var item_id = first_person_arms.get_held_item_id()
                        if inventory:
                                var info = inventory.get_item_info(item_id)
                                base_damage = info.get("damage", 15.0)
                var damage = base_damage * get_damage_modifier()
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
                elif obj and obj.has_method("interact"):
                        obj.interact(self)
                elif obj and obj.has_method("on_interact"):
                        obj.on_interact(self)
        else:
                _check_nearby_npcs()

func _check_nearby_npcs():
        var npcs = get_tree().get_nodes_in_group("npcs")
        var closest_npc = null
        var closest_dist = 4.0
        
        for npc in npcs:
                if npc is Node3D:
                        var dist = global_position.distance_to(npc.global_position)
                        if dist < closest_dist:
                                closest_dist = dist
                                closest_npc = npc
        
        if closest_npc and closest_npc.has_method("interact"):
                closest_npc.interact(self)

func _update_interact_prompt():
        var hud = get_node_or_null("/root/GameWorld/CanvasLayer/HUD")
        if not hud:
                return
        
        var interactable = _get_interactable_target()
        
        if interactable:
                var prompt_text = "[E] Взаимодействовать"
                
                if interactable.is_in_group("npcs"):
                        var npc_name = ""
                        if interactable.has_method("get") and interactable.get("npc_name"):
                                npc_name = interactable.npc_name
                        prompt_text = "[E] Поговорить" + (" с " + npc_name if not npc_name.is_empty() else "")
                elif interactable.has_method("gather"):
                        prompt_text = "[E] Собрать"
                
                if hud.has_method("show_interact_prompt"):
                        hud.show_interact_prompt(prompt_text)
        else:
                if hud.has_method("hide_interact_prompt"):
                        hud.hide_interact_prompt()

func _get_interactable_target() -> Node:
        if not camera:
                return null
        
        var from = camera.global_position
        var to = from - camera.global_basis.z * 4.0
        var space = get_world_3d().direct_space_state
        var query = PhysicsRayQueryParameters3D.create(from, to)
        query.exclude = [self]
        var result = space.intersect_ray(query)
        
        if result:
                var obj = result.collider
                if obj and (obj.has_method("interact") or obj.has_method("gather") or obj.has_method("on_interact")):
                        return obj
        
        var npcs = get_tree().get_nodes_in_group("npcs")
        for npc in npcs:
                if npc is Node3D:
                        var dist = global_position.distance_to(npc.global_position)
                        if dist < 3.5:
                                return npc
        
        return null

func apply_damage(amount: float, source):
        health -= amount
        if source and randf() < 0.3:
                blood -= amount * 0.5
                blood = max(0, blood)
        
        var vfx = get_node_or_null("/root/VFXManager")
        if vfx:
                vfx.spawn_damage_numbers(global_position + Vector3(0, 2, 0), amount)
                vfx.spawn_hit_effect(global_position + Vector3(0, 1, 0), "flesh")
        
        var audio = get_node_or_null("/root/AudioManager")
        if audio:
                audio.play_hit_sound("flesh")
        
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
        
        var vfx = get_node_or_null("/root/VFXManager")
        if vfx:
                vfx.spawn_healing_effect(global_position + Vector3(0, 1, 0))

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
        if spawn_grace_timer > 0:
                body_temperature = 37.0
                return
        
        var debuff_sys = get_node_or_null("/root/DebuffSystem")
        var temp_sys = get_node_or_null("/root/TemperatureSystem")
        
        hunger -= 0.05 * delta
        thirst -= 0.08 * delta
        
        if temp_sys:
                body_temperature = temp_sys.calculate_body_temp(global_position, body_temperature, delta)
        
        if debuff_sys:
                debuff_sys.check_conditions(net_id, self)
                
                var health_drain = debuff_sys.get_effect_drain(net_id, "health_drain")
                var blood_drain = debuff_sys.get_effect_drain(net_id, "blood_drain")
                var stamina_drain = debuff_sys.get_effect_drain(net_id, "stamina_drain")
                var thirst_drain = debuff_sys.get_effect_drain(net_id, "thirst_drain")
                var health_regen = debuff_sys.get_effect_drain(net_id, "health_regen")
                
                health -= health_drain * delta
                blood -= blood_drain * delta
                stamina -= stamina_drain * delta
                thirst -= thirst_drain * delta
                health += health_regen * delta
        
        if hunger <= 0:
                health -= 0.5 * delta
        if thirst <= 0:
                health -= 1.0 * delta
        if blood < 50:
                health -= 0.3 * delta
        
        if blood < 100:
                blood += 0.1 * delta
        
        if sanity < 100 and hunger > 30 and thirst > 30:
                sanity += 0.02 * delta
        
        hunger = clamp(hunger, 0, 100)
        thirst = clamp(thirst, 0, 100)
        blood = clamp(blood, 0, 100)
        sanity = clamp(sanity, 0, 100)
        health = clamp(health, 0, max_health)
        stamina = clamp(stamina, 0, max_stamina)
        
        if health <= 0:
                _die()

func get_speed_modifier() -> float:
        var mod := 1.0
        var debuff_sys = get_node_or_null("/root/DebuffSystem")
        
        if debuff_sys:
                mod *= debuff_sys.get_effect_multiplier(net_id, "speed_mult")
        
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
        var debuff_sys = get_node_or_null("/root/DebuffSystem")
        
        if debuff_sys:
                mod *= debuff_sys.get_effect_multiplier(net_id, "damage_mult")
        
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
