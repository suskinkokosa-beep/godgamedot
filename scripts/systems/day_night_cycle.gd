extends Node

signal time_changed(hour: int, minute: int)
signal day_changed(day: int)
signal period_changed(period: String)

@export var day_length_minutes := 20.0
@export var start_hour := 8

var current_time := 0.0
var current_day := 1
var current_hour := 8
var current_minute := 0
var current_period := "day"

var sun_light: DirectionalLight3D
var environment: Environment
var sky_material: ProceduralSkyMaterial

var sunrise_hour := 6
var sunset_hour := 20
var midnight_hour := 0

var base_sun_energy := 1.3
var base_ambient_energy := 0.6

func _ready():
	current_time = float(start_hour) * 60.0
	_find_environment()

func _find_environment():
	await get_tree().process_frame
	
	var lights = get_tree().get_nodes_in_group("sun")
	if lights.size() > 0:
		sun_light = lights[0]
	else:
		var all_lights = []
		_find_nodes_of_type(get_tree().root, "DirectionalLight3D", all_lights)
		if all_lights.size() > 0:
			sun_light = all_lights[0]
	
	var envs = []
	_find_nodes_of_type(get_tree().root, "WorldEnvironment", envs)
	if envs.size() > 0:
		var world_env = envs[0]
		environment = world_env.environment
		if environment and environment.sky:
			sky_material = environment.sky.sky_material as ProceduralSkyMaterial

func _find_nodes_of_type(node: Node, type_name: String, result: Array):
	if node.get_class() == type_name:
		result.append(node)
	for child in node.get_children():
		_find_nodes_of_type(child, type_name, result)

func _process(delta):
	var time_scale = 1440.0 / (day_length_minutes * 60.0)
	current_time += delta * time_scale
	
	if current_time >= 1440.0:
		current_time -= 1440.0
		current_day += 1
		emit_signal("day_changed", current_day)
	
	var new_hour = int(current_time / 60.0) % 24
	var new_minute = int(current_time) % 60
	
	if new_hour != current_hour or new_minute != current_minute:
		current_hour = new_hour
		current_minute = new_minute
		emit_signal("time_changed", current_hour, current_minute)
	
	_update_period()
	_update_lighting()

func _update_period():
	var new_period := ""
	
	if current_hour >= 5 and current_hour < 7:
		new_period = "dawn"
	elif current_hour >= 7 and current_hour < 18:
		new_period = "day"
	elif current_hour >= 18 and current_hour < 20:
		new_period = "dusk"
	else:
		new_period = "night"
	
	if new_period != current_period:
		current_period = new_period
		emit_signal("period_changed", current_period)

func _update_lighting():
	if not sun_light:
		return
	
	var sun_angle = (current_time / 1440.0) * 360.0 - 90.0
	var sun_height = sin(deg_to_rad(sun_angle + 90.0))
	
	sun_light.rotation_degrees.x = -30.0 + sun_angle * 0.8
	
	var day_factor = clamp(sun_height, 0.0, 1.0)
	var night_factor = 1.0 - day_factor
	
	sun_light.light_energy = lerp(0.1, base_sun_energy, day_factor)
	
	var day_color = Color(1.0, 0.97, 0.92)
	var sunset_color = Color(1.0, 0.6, 0.3)
	var night_color = Color(0.4, 0.5, 0.7)
	
	var sun_color: Color
	if current_period == "dawn" or current_period == "dusk":
		sun_color = sunset_color.lerp(day_color, abs(sun_height))
	elif current_period == "night":
		sun_color = night_color
	else:
		sun_color = day_color
	
	sun_light.light_color = sun_color
	
	if environment:
		environment.ambient_light_energy = lerp(0.15, base_ambient_energy, day_factor)
		
		var ambient_day = Color(0.45, 0.45, 0.55)
		var ambient_night = Color(0.15, 0.2, 0.35)
		environment.ambient_light_color = ambient_night.lerp(ambient_day, day_factor)
	
	if sky_material:
		var sky_day = Color(0.35, 0.55, 0.85)
		var sky_sunset = Color(0.8, 0.4, 0.2)
		var sky_night = Color(0.05, 0.08, 0.15)
		
		var horizon_day = Color(0.65, 0.75, 0.9)
		var horizon_sunset = Color(0.95, 0.6, 0.3)
		var horizon_night = Color(0.1, 0.12, 0.2)
		
		if current_period == "dawn" or current_period == "dusk":
			sky_material.sky_top_color = sky_sunset.lerp(sky_day, day_factor)
			sky_material.sky_horizon_color = horizon_sunset.lerp(horizon_day, day_factor)
		elif current_period == "night":
			sky_material.sky_top_color = sky_night
			sky_material.sky_horizon_color = horizon_night
		else:
			sky_material.sky_top_color = sky_day
			sky_material.sky_horizon_color = horizon_day

func get_time_string() -> String:
	return "%02d:%02d" % [current_hour, current_minute]

func get_day() -> int:
	return current_day

func get_hour() -> int:
	return current_hour

func get_period() -> String:
	return current_period

func is_day() -> bool:
	return current_period == "day" or current_period == "dawn"

func is_night() -> bool:
	return current_period == "night" or current_period == "dusk"

func get_darkness_factor() -> float:
	var sun_angle = (current_time / 1440.0) * 360.0 - 90.0
	var sun_height = sin(deg_to_rad(sun_angle + 90.0))
	return 1.0 - clamp(sun_height, 0.0, 1.0)

func set_time(hour: int, minute: int = 0):
	current_time = float(hour * 60 + minute)
	current_hour = hour
	current_minute = minute
	_update_period()
	_update_lighting()
