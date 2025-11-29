extends Node3D

var rain_particles: GPUParticles3D
var snow_particles: GPUParticles3D
var sand_particles: GPUParticles3D
var fog_particles: GPUParticles3D

var current_weather := "clear"
var intensity := 0.0
var target_intensity := 0.0
var transition_speed := 0.5

var player_ref: Node3D

var weather_system: Node

func _ready():
        call_deferred("_setup_particles")

func _setup_particles():
        _create_rain_particles()
        _create_snow_particles()
        _create_sand_particles()
        _find_player()
        _connect_weather_system()

func _connect_weather_system():
        await get_tree().process_frame
        weather_system = get_node_or_null("/root/WeatherSystem")
        if weather_system and weather_system.has_signal("weather_changed"):
                weather_system.weather_changed.connect(_on_weather_system_changed)

func _on_weather_system_changed(new_weather: String):
        set_weather(new_weather, 1.0)

func _find_player():
        await get_tree().process_frame
        var players = get_tree().get_nodes_in_group("players")
        if players.size() > 0:
                player_ref = players[0]

func _process(delta):
        if not player_ref:
                _find_player()
                return
        
        global_position = player_ref.global_position + Vector3(0, 10, 0)
        
        intensity = lerp(intensity, target_intensity, transition_speed * delta)
        
        _update_particle_emission()

func _update_particle_emission():
        if rain_particles:
                rain_particles.emitting = current_weather in ["rain", "storm"] and intensity > 0.1
                if rain_particles.emitting:
                        rain_particles.amount_ratio = intensity
        
        if snow_particles:
                snow_particles.emitting = current_weather in ["snow", "blizzard"] and intensity > 0.1
                if snow_particles.emitting:
                        snow_particles.amount_ratio = intensity
        
        if sand_particles:
                sand_particles.emitting = current_weather == "sandstorm" and intensity > 0.1
                if sand_particles.emitting:
                        sand_particles.amount_ratio = intensity

func _create_rain_particles():
        rain_particles = GPUParticles3D.new()
        rain_particles.name = "RainParticles"
        rain_particles.amount = 500
        rain_particles.lifetime = 2.0
        rain_particles.visibility_aabb = AABB(Vector3(-30, -15, -30), Vector3(60, 30, 60))
        rain_particles.emitting = false
        
        var material = ParticleProcessMaterial.new()
        material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
        material.emission_box_extents = Vector3(25, 1, 25)
        material.direction = Vector3(0, -1, 0)
        material.spread = 5.0
        material.gravity = Vector3(0, -15, 0)
        material.initial_velocity_min = 8.0
        material.initial_velocity_max = 12.0
        material.scale_min = 0.02
        material.scale_max = 0.04
        material.color = Color(0.7, 0.75, 0.85, 0.6)
        rain_particles.process_material = material
        
        var mesh = CylinderMesh.new()
        mesh.top_radius = 0.01
        mesh.bottom_radius = 0.01
        mesh.height = 0.3
        rain_particles.draw_pass_1 = mesh
        
        add_child(rain_particles)

func _create_snow_particles():
        snow_particles = GPUParticles3D.new()
        snow_particles.name = "SnowParticles"
        snow_particles.amount = 300
        snow_particles.lifetime = 5.0
        snow_particles.visibility_aabb = AABB(Vector3(-30, -15, -30), Vector3(60, 30, 60))
        snow_particles.emitting = false
        
        var material = ParticleProcessMaterial.new()
        material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
        material.emission_box_extents = Vector3(25, 1, 25)
        material.direction = Vector3(0, -1, 0)
        material.spread = 30.0
        material.gravity = Vector3(0, -2, 0)
        material.initial_velocity_min = 0.5
        material.initial_velocity_max = 1.5
        material.scale_min = 0.03
        material.scale_max = 0.08
        material.color = Color(0.95, 0.95, 1.0, 0.8)
        snow_particles.process_material = material
        
        var mesh = SphereMesh.new()
        mesh.radius = 0.05
        mesh.height = 0.1
        snow_particles.draw_pass_1 = mesh
        
        add_child(snow_particles)

func _create_sand_particles():
        sand_particles = GPUParticles3D.new()
        sand_particles.name = "SandParticles"
        sand_particles.amount = 400
        sand_particles.lifetime = 3.0
        sand_particles.visibility_aabb = AABB(Vector3(-30, -15, -30), Vector3(60, 30, 60))
        sand_particles.emitting = false
        
        var material = ParticleProcessMaterial.new()
        material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
        material.emission_box_extents = Vector3(25, 5, 25)
        material.direction = Vector3(1, 0, 0.3)
        material.spread = 20.0
        material.gravity = Vector3(0, -1, 0)
        material.initial_velocity_min = 5.0
        material.initial_velocity_max = 10.0
        material.scale_min = 0.02
        material.scale_max = 0.05
        material.color = Color(0.8, 0.7, 0.5, 0.5)
        sand_particles.process_material = material
        
        var mesh = BoxMesh.new()
        mesh.size = Vector3(0.03, 0.03, 0.03)
        sand_particles.draw_pass_1 = mesh
        
        add_child(sand_particles)

func set_weather(weather_type: String, weather_intensity: float = 1.0):
        current_weather = weather_type
        target_intensity = weather_intensity

func stop_all():
        target_intensity = 0.0
        if rain_particles:
                rain_particles.emitting = false
        if snow_particles:
                snow_particles.emitting = false
        if sand_particles:
                sand_particles.emitting = false
