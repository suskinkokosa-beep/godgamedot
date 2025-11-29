extends Node

var day_night_cycle
var weather_system
var weather_particles

var world_environment: WorldEnvironment
var environment: Environment

var current_weather := "clear"
var weather_intensity := 0.0
var target_weather := "clear"
var weather_transition_speed := 0.1

var fog_color_day := Color(0.7, 0.75, 0.85)
var fog_color_sunset := Color(0.8, 0.5, 0.4)
var fog_color_night := Color(0.1, 0.12, 0.18)

signal weather_changed(weather_type: String)

func _ready():
        call_deferred("_late_init")

func _late_init():
        day_night_cycle = get_node_or_null("/root/DayNightCycle")
        weather_system = get_node_or_null("/root/WeatherSystem")
        weather_particles = get_node_or_null("/root/WeatherParticles")
        
        await get_tree().process_frame
        _find_or_create_environment()
        
        if weather_system and weather_system.has_signal("weather_changed"):
                weather_system.weather_changed.connect(_on_weather_changed)

func _find_or_create_environment():
        var envs = get_tree().get_nodes_in_group("world_environment")
        if envs.size() > 0:
                world_environment = envs[0]
                environment = world_environment.environment
                return
        
        var all_envs := []
        _find_nodes_of_type(get_tree().root, "WorldEnvironment", all_envs)
        if all_envs.size() > 0:
                world_environment = all_envs[0]
                environment = world_environment.environment
                _enhance_environment()
                return
        
        _create_environment()

func _find_nodes_of_type(node: Node, type_name: String, result: Array):
        if node.get_class() == type_name:
                result.append(node)
        for child in node.get_children():
                _find_nodes_of_type(child, type_name, result)

func _create_environment():
        world_environment = WorldEnvironment.new()
        world_environment.name = "AtmosphereEnvironment"
        
        environment = Environment.new()
        
        var sky_material = ProceduralSkyMaterial.new()
        sky_material.sky_top_color = Color(0.35, 0.55, 0.9)
        sky_material.sky_horizon_color = Color(0.65, 0.75, 0.9)
        sky_material.ground_bottom_color = Color(0.2, 0.18, 0.15)
        sky_material.ground_horizon_color = Color(0.55, 0.5, 0.45)
        
        var sky = Sky.new()
        sky.sky_material = sky_material
        
        environment.background_mode = Environment.BG_SKY
        environment.sky = sky
        environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
        environment.ambient_light_color = Color(0.4, 0.45, 0.5)
        environment.ambient_light_energy = 0.5
        
        _enhance_environment()
        
        world_environment.environment = environment
        get_tree().root.call_deferred("add_child", world_environment)

func _enhance_environment():
        if not environment:
                return
        
        environment.tonemap_mode = Environment.TONE_MAPPER_ACES
        environment.tonemap_exposure = 1.0
        environment.tonemap_white = 6.0
        
        var is_forward_plus = RenderingServer.get_rendering_device() != null
        if is_forward_plus:
                environment.ssao_enabled = true
                environment.ssao_radius = 1.0
                environment.ssao_intensity = 1.5
        else:
                environment.ssao_enabled = false
        
        environment.fog_enabled = true
        environment.fog_light_color = fog_color_day
        environment.fog_light_energy = 0.5
        environment.fog_density = 0.001
        environment.fog_sky_affect = 0.3
        
        environment.glow_enabled = true
        environment.glow_intensity = 0.3
        environment.glow_strength = 0.8
        environment.glow_bloom = 0.1
        environment.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT

func _process(delta):
        _update_weather_transition(delta)
        _apply_time_based_effects()
        _apply_weather_effects()

func _update_weather_transition(delta: float):
        if current_weather != target_weather:
                weather_intensity += weather_transition_speed * delta
                if weather_intensity >= 1.0:
                        weather_intensity = 1.0
                        current_weather = target_weather
                        emit_signal("weather_changed", current_weather)
        elif current_weather == "clear" and weather_intensity > 0.0:
                weather_intensity = max(0.0, weather_intensity - weather_transition_speed * delta)

func _apply_time_based_effects():
        if not environment or not day_night_cycle:
                return
        
        var hour = day_night_cycle.current_hour
        var t_day = 0.0
        var t_sunset = 0.0
        
        if hour >= 6 and hour < 20:
                t_day = 1.0
                if hour >= 18 and hour < 20:
                        t_sunset = (hour - 18) / 2.0
                elif hour >= 6 and hour < 8:
                        t_sunset = 1.0 - (hour - 6) / 2.0
        else:
                t_day = 0.0
        
        var fog_color: Color
        if t_sunset > 0.3:
                fog_color = fog_color_day.lerp(fog_color_sunset, t_sunset)
        else:
                fog_color = fog_color_day.lerp(fog_color_night, 1.0 - t_day)
        
        environment.fog_light_color = fog_color

func _apply_weather_effects():
        if not environment:
                return
        
        var base_fog_density = 0.001
        var base_fog_energy = 0.5
        
        match current_weather:
                "rain", "storm":
                        environment.fog_density = lerp(base_fog_density, 0.005, weather_intensity)
                        environment.fog_light_energy = lerp(base_fog_energy, 0.3, weather_intensity)
                "fog", "mist":
                        environment.fog_density = lerp(base_fog_density, 0.02, weather_intensity)
                        environment.fog_light_energy = lerp(base_fog_energy, 0.8, weather_intensity)
                "snow", "blizzard":
                        environment.fog_density = lerp(base_fog_density, 0.008, weather_intensity)
                        environment.fog_light_color = environment.fog_light_color.lerp(Color(0.9, 0.92, 0.95), weather_intensity * 0.5)
                "sandstorm":
                        environment.fog_density = lerp(base_fog_density, 0.015, weather_intensity)
                        environment.fog_light_color = environment.fog_light_color.lerp(Color(0.8, 0.65, 0.4), weather_intensity * 0.5)
                "clear":
                        environment.fog_density = base_fog_density

func _on_weather_changed(new_weather: String):
        set_weather(new_weather)

func set_weather(weather_type: String):
        target_weather = weather_type
        if current_weather == "clear":
                current_weather = weather_type
        
        if weather_particles and weather_particles.has_method("set_weather"):
                weather_particles.set_weather(weather_type, 1.0)

func get_current_hour() -> float:
        if day_night_cycle:
                return float(day_night_cycle.current_hour)
        return 12.0

func is_daytime() -> bool:
        var hour = get_current_hour()
        return hour >= 6.0 and hour < 20.0

func is_night() -> bool:
        return not is_daytime()

func get_ambient_color() -> Color:
        if environment:
                return environment.ambient_light_color
        return Color.WHITE

func get_fog_density() -> float:
        if environment:
                return environment.fog_density
        return 0.001
