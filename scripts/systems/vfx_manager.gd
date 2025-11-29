extends Node

signal effect_spawned(effect_name: String, position: Vector3)

var particle_pool := []
const POOL_SIZE := 20

func _ready():
        _create_particle_pool()

func _create_particle_pool():
        for i in range(POOL_SIZE):
                var particles = GPUParticles3D.new()
                particles.emitting = false
                particles.one_shot = true
                add_child(particles)
                particle_pool.append(particles)

func _get_available_particles() -> GPUParticles3D:
        for p in particle_pool:
                if not p.emitting:
                        return p
        return particle_pool[0]

func spawn_damage_numbers(position: Vector3, damage: float, is_critical: bool = false):
        var label = Label3D.new()
        label.text = str(int(damage))
        label.position = position + Vector3(randf_range(-0.3, 0.3), 0.5, randf_range(-0.3, 0.3))
        label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
        label.no_depth_test = true
        label.font_size = 32 if is_critical else 24
        
        if is_critical:
                label.modulate = Color(1.0, 0.3, 0.1)
                label.text = str(int(damage)) + "!"
        else:
                label.modulate = Color(1.0, 0.9, 0.2)
        
        get_tree().current_scene.add_child(label)
        
        var tween = create_tween()
        tween.set_parallel(true)
        tween.tween_property(label, "position:y", label.position.y + 1.5, 1.0)
        tween.tween_property(label, "modulate:a", 0.0, 1.0)
        tween.set_parallel(false)
        tween.tween_callback(label.queue_free)

func spawn_pickup_effect(position: Vector3, item_type: String = "misc"):
        var effect = _get_available_particles()
        effect.position = position
        
        var material = ParticleProcessMaterial.new()
        material.direction = Vector3(0, 1, 0)
        material.spread = 30.0
        material.initial_velocity_min = 2.0
        material.initial_velocity_max = 4.0
        material.gravity = Vector3(0, -5, 0)
        material.scale_min = 0.05
        material.scale_max = 0.1
        
        match item_type:
                "resource":
                        material.color = Color(0.6, 0.5, 0.3)
                "food":
                        material.color = Color(0.8, 0.6, 0.2)
                "medical":
                        material.color = Color(0.9, 0.3, 0.3)
                "weapon", "tool":
                        material.color = Color(0.5, 0.5, 0.6)
                _:
                        material.color = Color(0.7, 0.7, 0.7)
        
        effect.process_material = material
        effect.amount = 8
        effect.lifetime = 0.5
        effect.emitting = true
        
        emit_signal("effect_spawned", "pickup", position)

func spawn_hit_effect(position: Vector3, hit_type: String = "flesh"):
        var effect = _get_available_particles()
        effect.position = position
        
        var material = ParticleProcessMaterial.new()
        material.direction = Vector3(0, 0.5, 0)
        material.spread = 60.0
        material.initial_velocity_min = 1.0
        material.initial_velocity_max = 3.0
        material.gravity = Vector3(0, -8, 0)
        material.scale_min = 0.03
        material.scale_max = 0.08
        
        match hit_type:
                "flesh":
                        material.color = Color(0.7, 0.1, 0.1)
                "wood":
                        material.color = Color(0.5, 0.35, 0.2)
                "stone":
                        material.color = Color(0.5, 0.5, 0.5)
                "metal":
                        material.color = Color(0.7, 0.7, 0.75)
                _:
                        material.color = Color(0.6, 0.6, 0.6)
        
        effect.process_material = material
        effect.amount = 12
        effect.lifetime = 0.4
        effect.emitting = true
        
        emit_signal("effect_spawned", "hit_" + hit_type, position)

func spawn_craft_effect(position: Vector3):
        var effect = _get_available_particles()
        effect.position = position
        
        var material = ParticleProcessMaterial.new()
        material.direction = Vector3(0, 1, 0)
        material.spread = 180.0
        material.initial_velocity_min = 0.5
        material.initial_velocity_max = 2.0
        material.gravity = Vector3(0, 0, 0)
        material.scale_min = 0.02
        material.scale_max = 0.05
        material.color = Color(1.0, 0.9, 0.4)
        
        effect.process_material = material
        effect.amount = 20
        effect.lifetime = 0.8
        effect.emitting = true
        
        emit_signal("effect_spawned", "craft", position)

func spawn_level_up_effect(position: Vector3):
        var effect = _get_available_particles()
        effect.position = position
        
        var material = ParticleProcessMaterial.new()
        material.direction = Vector3(0, 1, 0)
        material.spread = 360.0
        material.initial_velocity_min = 2.0
        material.initial_velocity_max = 5.0
        material.gravity = Vector3(0, 1, 0)
        material.scale_min = 0.05
        material.scale_max = 0.15
        material.color = Color(1.0, 0.85, 0.2)
        
        effect.process_material = material
        effect.amount = 50
        effect.lifetime = 1.5
        effect.emitting = true
        
        emit_signal("effect_spawned", "level_up", position)

func spawn_death_effect(position: Vector3, entity_type: String = "player"):
        var effect = _get_available_particles()
        effect.position = position
        
        var material = ParticleProcessMaterial.new()
        material.direction = Vector3(0, 0.2, 0)
        material.spread = 180.0
        material.initial_velocity_min = 0.5
        material.initial_velocity_max = 2.0
        material.gravity = Vector3(0, -2, 0)
        material.scale_min = 0.1
        material.scale_max = 0.3
        
        if entity_type == "player":
                material.color = Color(0.3, 0.3, 0.3)
        else:
                material.color = Color(0.5, 0.2, 0.2)
        
        effect.process_material = material
        effect.amount = 30
        effect.lifetime = 2.0
        effect.emitting = true
        
        emit_signal("effect_spawned", "death", position)

func spawn_footstep_dust(position: Vector3, surface: String = "dirt"):
        var effect = _get_available_particles()
        effect.position = position
        
        var material = ParticleProcessMaterial.new()
        material.direction = Vector3(0, 0.3, 0)
        material.spread = 90.0
        material.initial_velocity_min = 0.2
        material.initial_velocity_max = 0.8
        material.gravity = Vector3(0, -1, 0)
        material.scale_min = 0.05
        material.scale_max = 0.15
        
        match surface:
                "grass":
                        material.color = Color(0.4, 0.5, 0.3, 0.6)
                "sand":
                        material.color = Color(0.8, 0.7, 0.5, 0.6)
                "snow":
                        material.color = Color(0.95, 0.95, 1.0, 0.8)
                _:
                        material.color = Color(0.5, 0.45, 0.4, 0.5)
        
        effect.process_material = material
        effect.amount = 5
        effect.lifetime = 0.3
        effect.emitting = true

func spawn_healing_effect(position: Vector3):
        var effect = _get_available_particles()
        effect.position = position
        
        var material = ParticleProcessMaterial.new()
        material.direction = Vector3(0, 1, 0)
        material.spread = 30.0
        material.initial_velocity_min = 1.0
        material.initial_velocity_max = 2.0
        material.gravity = Vector3(0, 0.5, 0)
        material.scale_min = 0.03
        material.scale_max = 0.08
        material.color = Color(0.2, 0.9, 0.3)
        
        effect.process_material = material
        effect.amount = 15
        effect.lifetime = 1.0
        effect.emitting = true
        
        emit_signal("effect_spawned", "healing", position)

func spawn_item_pickup_effect(position: Vector3):
        spawn_pickup_effect(position, "resource")

func spawn_gather_effect(position: Vector3, resource_type: String = "wood"):
        var effect = _get_available_particles()
        if not effect or not is_instance_valid(effect):
                return
        
        effect.position = position
        
        var material = ParticleProcessMaterial.new()
        material.direction = Vector3(0, 0.5, 0)
        material.spread = 45.0
        material.initial_velocity_min = 1.0
        material.initial_velocity_max = 2.5
        material.gravity = Vector3(0, -4, 0)
        material.scale_min = 0.02
        material.scale_max = 0.06
        
        match resource_type:
                "wood", "log", "stick":
                        material.color = Color(0.5, 0.35, 0.2)
                "stone", "iron_ore", "copper_ore":
                        material.color = Color(0.5, 0.5, 0.55)
                "gold_ore", "silver_ore":
                        material.color = Color(0.9, 0.8, 0.3)
                "plant_fiber", "herbs", "berries":
                        material.color = Color(0.3, 0.6, 0.2)
                _:
                        material.color = Color(0.6, 0.5, 0.4)
        
        effect.process_material = material
        effect.amount = 10
        effect.lifetime = 0.6
        effect.emitting = true
        
        emit_signal("effect_spawned", "gather_" + resource_type, position)

func spawn_build_effect(position: Vector3):
        var effect = _get_available_particles()
        if not effect or not is_instance_valid(effect):
                return
        
        effect.position = position
        
        var material = ParticleProcessMaterial.new()
        material.direction = Vector3(0, 1, 0)
        material.spread = 60.0
        material.initial_velocity_min = 0.5
        material.initial_velocity_max = 1.5
        material.gravity = Vector3(0, -2, 0)
        material.scale_min = 0.03
        material.scale_max = 0.08
        material.color = Color(0.7, 0.6, 0.4)
        
        effect.process_material = material
        effect.amount = 25
        effect.lifetime = 0.8
        effect.emitting = true
        
        emit_signal("effect_spawned", "build", position)

func spawn_fire_effect(position: Vector3, size: float = 1.0):
        var effect = _get_available_particles()
        if not effect or not is_instance_valid(effect):
                return
        
        effect.position = position
        
        var material = ParticleProcessMaterial.new()
        material.direction = Vector3(0, 1, 0)
        material.spread = 15.0
        material.initial_velocity_min = 1.0 * size
        material.initial_velocity_max = 3.0 * size
        material.gravity = Vector3(0, 2, 0)
        material.scale_min = 0.05 * size
        material.scale_max = 0.15 * size
        material.color = Color(1.0, 0.5, 0.1)
        
        effect.process_material = material
        effect.amount = int(30 * size)
        effect.lifetime = 0.5
        effect.emitting = true
        
        emit_signal("effect_spawned", "fire", position)

func spawn_smoke_effect(position: Vector3, size: float = 1.0):
        var effect = _get_available_particles()
        if not effect or not is_instance_valid(effect):
                return
        
        effect.position = position
        
        var material = ParticleProcessMaterial.new()
        material.direction = Vector3(0, 1, 0)
        material.spread = 25.0
        material.initial_velocity_min = 0.5 * size
        material.initial_velocity_max = 1.5 * size
        material.gravity = Vector3(0, 1, 0)
        material.scale_min = 0.1 * size
        material.scale_max = 0.3 * size
        material.color = Color(0.3, 0.3, 0.3, 0.5)
        
        effect.process_material = material
        effect.amount = int(20 * size)
        effect.lifetime = 1.5
        effect.emitting = true
        
        emit_signal("effect_spawned", "smoke", position)

func spawn_explosion_effect(position: Vector3, radius: float = 3.0):
        var effect = _get_available_particles()
        if not effect or not is_instance_valid(effect):
                return
        
        effect.position = position
        
        var material = ParticleProcessMaterial.new()
        material.direction = Vector3(0, 0.3, 0)
        material.spread = 180.0
        material.initial_velocity_min = 5.0 * radius
        material.initial_velocity_max = 10.0 * radius
        material.gravity = Vector3(0, -5, 0)
        material.scale_min = 0.1
        material.scale_max = 0.3
        material.color = Color(1.0, 0.6, 0.2)
        
        effect.process_material = material
        effect.amount = 50
        effect.lifetime = 0.8
        effect.emitting = true
        
        emit_signal("effect_spawned", "explosion", position)

func spawn_water_splash(position: Vector3, size: float = 1.0):
        var effect = _get_available_particles()
        if not effect or not is_instance_valid(effect):
                return
        
        effect.position = position
        
        var material = ParticleProcessMaterial.new()
        material.direction = Vector3(0, 1, 0)
        material.spread = 60.0
        material.initial_velocity_min = 2.0 * size
        material.initial_velocity_max = 5.0 * size
        material.gravity = Vector3(0, -10, 0)
        material.scale_min = 0.03 * size
        material.scale_max = 0.08 * size
        material.color = Color(0.6, 0.8, 1.0, 0.7)
        
        effect.process_material = material
        effect.amount = int(20 * size)
        effect.lifetime = 0.6
        effect.emitting = true
        
        emit_signal("effect_spawned", "water_splash", position)
