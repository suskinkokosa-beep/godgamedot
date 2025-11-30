extends CharacterBody3D

signal health_changed(current, maximum)
signal died(killer)

@export var animal_id: String = "boar"
var animal_type: int = 0
var max_health: float = 50.0
var current_health: float = 50.0
var move_speed: float = 5.0
var damage: float = 10.0
var flee_distance: float = 15.0
var is_aggressive: bool = false
var model_node: Node3D = null

const ANIMAL_STATS := {
        "bear": {"health": 150.0, "speed": 4.0, "damage": 25.0, "aggressive": true, "flee_distance": 0.0, "model": "bear"},
        "boar": {"health": 80.0, "speed": 6.0, "damage": 15.0, "aggressive": true, "flee_distance": 8.0, "model": "boar"},
        "wolf": {"health": 60.0, "speed": 8.0, "damage": 20.0, "aggressive": true, "flee_distance": 0.0, "model": "wolf"},
        "deer": {"health": 40.0, "speed": 10.0, "damage": 5.0, "aggressive": false, "flee_distance": 20.0, "model": "deer"},
        "rabbit": {"health": 15.0, "speed": 12.0, "damage": 0.0, "aggressive": false, "flee_distance": 25.0, "model": "rabbit"},
        "fox": {"health": 35.0, "speed": 9.0, "damage": 8.0, "aggressive": false, "flee_distance": 15.0, "model": "fox"},
        "eagle": {"health": 25.0, "speed": 15.0, "damage": 10.0, "aggressive": false, "flee_distance": 30.0, "model": "eagle"},
        "moose": {"health": 120.0, "speed": 7.0, "damage": 20.0, "aggressive": false, "flee_distance": 12.0, "model": "moose"}
}

enum State {
        IDLE,
        WANDER,
        FLEE,
        CHASE,
        ATTACK,
        DEAD
}

var current_state: int = State.IDLE
var state_timer: float = 0.0
var target: Node3D = null
var home_position: Vector3 = Vector3.ZERO
var wander_radius: float = 20.0

var nav_agent: NavigationAgent3D = null
var detection_area: Area3D = null

var gravity: float = 9.8

func _ready():
        add_to_group("damageable")
        add_to_group("animals")
        
        _apply_animal_stats()
        _load_animal_model()
        _setup_navigation()
        _setup_detection()
        
        call_deferred("_deferred_init")

func _deferred_init():
        if is_inside_tree():
                home_position = global_position
        _change_state(State.IDLE)

func _apply_animal_stats():
        if ANIMAL_STATS.has(animal_id):
                var stats = ANIMAL_STATS[animal_id]
                max_health = stats.health
                current_health = max_health
                move_speed = stats.speed
                damage = stats.damage
                is_aggressive = stats.aggressive
                flee_distance = stats.flee_distance

func _load_animal_model():
        var model_loader = get_node_or_null("/root/ModelLoader")
        if model_loader:
                var model_id = animal_id
                if ANIMAL_STATS.has(animal_id) and ANIMAL_STATS[animal_id].has("model"):
                        model_id = ANIMAL_STATS[animal_id].model
                
                model_node = model_loader.load_model(model_id, "creature")
        
        if model_node:
                add_child(model_node)
        else:
                _create_placeholder_model()

func _create_placeholder_model():
        model_node = Node3D.new()
        model_node.name = "PlaceholderModel"
        
        var mesh_instance = MeshInstance3D.new()
        var capsule = CapsuleMesh.new()
        
        var scale_factor := 1.0
        var color := Color.BROWN
        match animal_id:
                "bear":
                        scale_factor = 1.5
                        color = Color(0.4, 0.3, 0.2)
                "boar":
                        scale_factor = 0.8
                        color = Color(0.5, 0.35, 0.25)
                "wolf":
                        scale_factor = 0.7
                        color = Color(0.5, 0.5, 0.55)
                "deer":
                        scale_factor = 1.0
                        color = Color(0.6, 0.45, 0.3)
                "rabbit":
                        scale_factor = 0.3
                        color = Color(0.7, 0.65, 0.6)
                "fox":
                        scale_factor = 0.5
                        color = Color(0.8, 0.4, 0.2)
                "eagle":
                        scale_factor = 0.4
                        color = Color(0.3, 0.25, 0.2)
                "moose":
                        scale_factor = 1.8
                        color = Color(0.35, 0.3, 0.25)
        
        capsule.radius = 0.5 * scale_factor
        capsule.height = 1.5 * scale_factor
        mesh_instance.mesh = capsule
        
        var material = StandardMaterial3D.new()
        material.albedo_color = color
        mesh_instance.material_override = material
        
        mesh_instance.rotation_degrees.x = 90
        mesh_instance.position.y = capsule.height * 0.25
        
        model_node.add_child(mesh_instance)
        add_child(model_node)

func setup_animal(new_animal_id: String):
        animal_id = new_animal_id
        _apply_animal_stats()
        
        if model_node:
                model_node.queue_free()
        _load_animal_model()

func _setup_navigation():
        nav_agent = NavigationAgent3D.new()
        nav_agent.path_desired_distance = 0.5
        nav_agent.target_desired_distance = 1.0
        add_child(nav_agent)

func _setup_detection():
        detection_area = Area3D.new()
        var coll = CollisionShape3D.new()
        var sphere = SphereShape3D.new()
        sphere.radius = max(flee_distance, 10.0)
        coll.shape = sphere
        detection_area.add_child(coll)
        add_child(detection_area)
        
        detection_area.body_entered.connect(_on_body_entered)
        detection_area.body_exited.connect(_on_body_exited)

func _physics_process(delta):
        if current_state == State.DEAD:
                return
        
        if not is_on_floor():
                velocity.y -= gravity * delta
        
        state_timer += delta
        
        match current_state:
                State.IDLE:
                        _process_idle(delta)
                State.WANDER:
                        _process_wander(delta)
                State.FLEE:
                        _process_flee(delta)
                State.CHASE:
                        _process_chase(delta)
                State.ATTACK:
                        _process_attack(delta)
        
        move_and_slide()

func _process_idle(delta):
        velocity.x = 0
        velocity.z = 0
        
        if state_timer > randf_range(2.0, 5.0):
                _change_state(State.WANDER)

func _process_wander(delta):
        if nav_agent.is_navigation_finished():
                _change_state(State.IDLE)
                return
        
        var next_pos = nav_agent.get_next_path_position()
        var direction = (next_pos - global_position).normalized()
        direction.y = 0
        
        velocity.x = direction.x * move_speed * 0.5
        velocity.z = direction.z * move_speed * 0.5
        
        _face_direction(direction)

func _process_flee(delta):
        if not target or not is_instance_valid(target):
                _change_state(State.IDLE)
                return
        
        var dist_to_target = global_position.distance_to(target.global_position)
        if dist_to_target > flee_distance * 1.5:
                target = null
                _change_state(State.IDLE)
                return
        
        var flee_dir = (global_position - target.global_position).normalized()
        flee_dir.y = 0
        
        var flee_pos = global_position + flee_dir * 10.0
        nav_agent.target_position = flee_pos
        
        if not nav_agent.is_navigation_finished():
                var next_pos = nav_agent.get_next_path_position()
                var direction = (next_pos - global_position).normalized()
                direction.y = 0
                
                velocity.x = direction.x * move_speed
                velocity.z = direction.z * move_speed
                
                _face_direction(direction)

func _process_chase(delta):
        if not target or not is_instance_valid(target):
                _change_state(State.IDLE)
                return
        
        var dist_to_target = global_position.distance_to(target.global_position)
        
        if dist_to_target > wander_radius * 2:
                target = null
                _change_state(State.WANDER)
                nav_agent.target_position = home_position
                return
        
        if dist_to_target < 1.5:
                _change_state(State.ATTACK)
                return
        
        nav_agent.target_position = target.global_position
        
        if not nav_agent.is_navigation_finished():
                var next_pos = nav_agent.get_next_path_position()
                var direction = (next_pos - global_position).normalized()
                direction.y = 0
                
                velocity.x = direction.x * move_speed
                velocity.z = direction.z * move_speed
                
                _face_direction(direction)

func _process_attack(delta):
        if not target or not is_instance_valid(target):
                _change_state(State.IDLE)
                return
        
        var dist_to_target = global_position.distance_to(target.global_position)
        
        if dist_to_target > 2.0:
                _change_state(State.CHASE)
                return
        
        velocity.x = 0
        velocity.z = 0
        
        var dir_to_target = (target.global_position - global_position).normalized()
        _face_direction(dir_to_target)
        
        if state_timer > 1.0:
                _do_attack()
                state_timer = 0.0

func _do_attack():
        if not target or not is_instance_valid(target):
                return
        
        if target.has_method("take_damage"):
                target.take_damage(damage, self)

func _change_state(new_state: int):
        current_state = new_state
        state_timer = 0.0
        
        match new_state:
                State.WANDER:
                        var wander_pos = home_position + Vector3(
                                randf_range(-wander_radius, wander_radius),
                                0,
                                randf_range(-wander_radius, wander_radius)
                        )
                        nav_agent.target_position = wander_pos

func _face_direction(direction: Vector3):
        if direction.length() > 0.1:
                var target_rotation = atan2(direction.x, direction.z)
                rotation.y = lerp_angle(rotation.y, target_rotation, 0.1)

func _on_body_entered(body: Node3D):
        if body.is_in_group("players"):
                if is_aggressive:
                        target = body
                        _change_state(State.CHASE)
                elif flee_distance > 0:
                        target = body
                        _change_state(State.FLEE)

func _on_body_exited(body: Node3D):
        if body == target:
                if current_state == State.FLEE:
                        pass

func take_damage(amount: float, attacker: Node = null):
        if current_state == State.DEAD:
                return
        
        current_health -= amount
        emit_signal("health_changed", current_health, max_health)
        
        if current_health <= 0:
                die(attacker)
        else:
                if is_aggressive:
                        target = attacker
                        _change_state(State.CHASE)
                else:
                        target = attacker
                        _change_state(State.FLEE)

func die(killer: Node = null):
        current_state = State.DEAD
        emit_signal("died", killer)
        
        var hunting_system = get_node_or_null("/root/HuntingSystem")
        if hunting_system:
                hunting_system.on_animal_killed(self, killer)
        
        var tween = create_tween()
        tween.tween_property(self, "scale", Vector3(1, 0.1, 1), 0.5)
        tween.tween_callback(queue_free)

func heal(amount: float):
        current_health = min(current_health + amount, max_health)
        emit_signal("health_changed", current_health, max_health)
