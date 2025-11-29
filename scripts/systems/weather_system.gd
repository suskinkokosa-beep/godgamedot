extends Node

signal weather_changed(new_weather)
signal temperature_changed(temp_delta)

enum WeatherType { CLEAR, CLOUDY, RAIN, HEAVY_RAIN, SNOW, BLIZZARD, STORM, FOG }

var current_weather: int = WeatherType.CLEAR
var target_weather: int = WeatherType.CLEAR
var intensity := 0.0
var wind_speed := 0.0
var wind_direction := 0.0
var temp_delta := 0.0
var humidity := 0.5

var weather_transition := 0.0
var transition_duration := 30.0

var change_interval := 180.0
var timer := 0.0

var weather_names := {
	WeatherType.CLEAR: "Ясно",
	WeatherType.CLOUDY: "Облачно",
	WeatherType.RAIN: "Дождь",
	WeatherType.HEAVY_RAIN: "Ливень",
	WeatherType.SNOW: "Снег",
	WeatherType.BLIZZARD: "Метель",
	WeatherType.STORM: "Гроза",
	WeatherType.FOG: "Туман"
}

var weather_effects := {
	WeatherType.CLEAR: {"temp_delta": 0.0, "visibility": 1.0, "wet": 0.0},
	WeatherType.CLOUDY: {"temp_delta": -1.0, "visibility": 0.9, "wet": 0.0},
	WeatherType.RAIN: {"temp_delta": -3.0, "visibility": 0.7, "wet": 0.5},
	WeatherType.HEAVY_RAIN: {"temp_delta": -5.0, "visibility": 0.4, "wet": 1.0},
	WeatherType.SNOW: {"temp_delta": -8.0, "visibility": 0.6, "wet": 0.3},
	WeatherType.BLIZZARD: {"temp_delta": -15.0, "visibility": 0.2, "wet": 0.7},
	WeatherType.STORM: {"temp_delta": -4.0, "visibility": 0.3, "wet": 1.0},
	WeatherType.FOG: {"temp_delta": -2.0, "visibility": 0.15, "wet": 0.2}
}

var environment: Environment
var sun_light: DirectionalLight3D

func _ready():
	await get_tree().process_frame
	_find_environment()

func _find_environment():
	var envs = []
	_find_nodes_of_type(get_tree().root, "WorldEnvironment", envs)
	if envs.size() > 0:
		environment = envs[0].environment
	
	var lights = []
	_find_nodes_of_type(get_tree().root, "DirectionalLight3D", lights)
	if lights.size() > 0:
		sun_light = lights[0]

func _find_nodes_of_type(node: Node, type_name: String, result: Array):
	if node.get_class() == type_name:
		result.append(node)
	for child in node.get_children():
		_find_nodes_of_type(child, type_name, result)

func _is_server() -> bool:
	var mp = multiplayer
	if mp == null:
		return true
	if not mp.has_multiplayer_peer():
		return true
	return mp.is_server()

func _process(delta):
	if _is_server():
		timer += delta
		if timer >= change_interval:
			timer = 0.0
			_randomize_weather()
	
	if target_weather != current_weather:
		weather_transition += delta / transition_duration
		if weather_transition >= 1.0:
			weather_transition = 0.0
			current_weather = target_weather
			emit_signal("weather_changed", current_weather)
	
	_update_environment(delta)

func _randomize_weather():
	var biome_sys = get_node_or_null("/root/BiomeSystem")
	var is_cold_region = false
	
	if biome_sys:
		is_cold_region = biome_sys.is_cold_biome()
	
	var r = randi() % 100
	
	if is_cold_region:
		if r < 40:
			target_weather = WeatherType.CLEAR
		elif r < 55:
			target_weather = WeatherType.CLOUDY
		elif r < 75:
			target_weather = WeatherType.SNOW
		elif r < 90:
			target_weather = WeatherType.BLIZZARD
		else:
			target_weather = WeatherType.FOG
	else:
		if r < 50:
			target_weather = WeatherType.CLEAR
		elif r < 65:
			target_weather = WeatherType.CLOUDY
		elif r < 80:
			target_weather = WeatherType.RAIN
		elif r < 90:
			target_weather = WeatherType.HEAVY_RAIN
		elif r < 95:
			target_weather = WeatherType.STORM
		else:
			target_weather = WeatherType.FOG
	
	intensity = randf_range(0.3, 1.0)
	wind_speed = randf_range(0.0, 12.0)
	wind_direction = randf_range(0.0, TAU)
	
	var effects = weather_effects.get(target_weather, {})
	temp_delta = effects.get("temp_delta", 0.0) * intensity
	
	emit_signal("temperature_changed", temp_delta)
	
	if multiplayer and multiplayer.has_multiplayer_peer() and multiplayer.is_server():
		rpc_id(0, "rpc_sync_weather", target_weather, intensity, wind_speed, wind_direction, temp_delta)

@rpc("any_peer", "call_remote")
func rpc_sync_weather(w: int, inten: float, wind: float, wind_dir: float, tdelta: float):
	target_weather = w
	intensity = inten
	wind_speed = wind
	wind_direction = wind_dir
	temp_delta = tdelta

func _update_environment(_delta: float):
	if not environment:
		return
	
	var effects = weather_effects.get(current_weather, {})
	var target_effects = weather_effects.get(target_weather, {})
	var t = weather_transition if target_weather != current_weather else 1.0
	
	var visibility = lerp(effects.get("visibility", 1.0), target_effects.get("visibility", 1.0), t)
	
	if environment.fog_enabled:
		var base_density = 0.002
		var max_density = 0.02
		environment.fog_density = lerp(base_density, max_density, 1.0 - visibility)
	
	if sun_light:
		var base_energy = 1.3
		sun_light.light_energy = base_energy * visibility

func get_weather() -> int:
	return current_weather

func get_weather_name() -> String:
	return weather_names.get(current_weather, "Неизвестно")

func get_weather_name_for(weather: int) -> String:
	return weather_names.get(weather, "Неизвестно")

func get_temp_delta() -> float:
	return temp_delta

func get_visibility() -> float:
	var effects = weather_effects.get(current_weather, {})
	return effects.get("visibility", 1.0)

func get_wet_factor() -> float:
	var effects = weather_effects.get(current_weather, {})
	return effects.get("wet", 0.0) * intensity

func is_raining() -> bool:
	return current_weather in [WeatherType.RAIN, WeatherType.HEAVY_RAIN, WeatherType.STORM]

func is_snowing() -> bool:
	return current_weather in [WeatherType.SNOW, WeatherType.BLIZZARD]

func set_weather(weather: int):
	target_weather = weather
	weather_transition = 0.0
