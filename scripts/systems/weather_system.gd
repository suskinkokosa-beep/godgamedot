extends Node

signal weather_changed(new_weather)

# weather types: clear, rain, snow, storm
var current_weather := "clear"
var intensity := 0.0 # 0..1
var wind_speed := 0.0

# override temperature delta applied globally
var temp_delta := 0.0

# simple timers to change weather
var change_interval := 120.0
var timer := 0.0

func _is_server() -> bool:
    var mp = multiplayer
    if mp == null:
        return true
    if not mp.has_multiplayer_peer():
        return true
    return mp.is_server()

func _process(delta):
    if not _is_server():
        return
    timer += delta
    if timer >= change_interval:
        timer = 0.0
        _randomize_weather()

func _randomize_weather():
    var r = randi() % 100
    if r < 60:
        current_weather = "clear"
        intensity = 0.0
        wind_speed = randf_range(0, 2)
        temp_delta = 0.0
    elif r < 85:
        current_weather = "rain"
        intensity = randf_range(0.3, 0.8)
        wind_speed = randf_range(1, 6)
        temp_delta = -2.0 * intensity
    else:
        current_weather = "storm"
        intensity = randf_range(0.6, 1.0)
        wind_speed = randf_range(6, 12)
        temp_delta = -4.0 * intensity
    rpc_id(0, "rpc_notify_weather", current_weather, intensity, wind_speed, temp_delta)
    emit_signal("weather_changed", current_weather)

@rpc("any_peer", "call_remote")
func rpc_notify_weather(w, inten, wind, tdelta):
    current_weather = w
    intensity = inten
    wind_speed = wind
    temp_delta = tdelta
    emit_signal("weather_changed", current_weather)
