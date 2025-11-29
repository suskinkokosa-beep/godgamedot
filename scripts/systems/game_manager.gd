extends Node

signal language_changed(new_lang)

var language := "en"
var is_server := false
var game_state := "init"
var mouse_sensitivity := 0.06

func _ready():
	var lang_path = "user://selected_lang.txt"
	if FileAccess.file_exists(lang_path):
		var txt = FileAccess.open(lang_path, FileAccess.READ)
		if txt:
			language = txt.get_as_text().strip_edges()
			txt.close()
	
	var sens_path = "user://mouse_sens.txt"
	if FileAccess.file_exists(sens_path):
		var txt = FileAccess.open(sens_path, FileAccess.READ)
		if txt:
			var val = txt.get_as_text().strip_edges()
			mouse_sensitivity = float(val)
			txt.close()
	
	emit_signal("language_changed", language)

func set_language(lang: String):
	language = lang
	var txt = FileAccess.open("user://selected_lang.txt", FileAccess.WRITE)
	if txt:
		txt.store_string(language)
		txt.close()
	emit_signal("language_changed", language)

func get_language():
	return language

func set_mouse_sensitivity(value: float):
	mouse_sensitivity = clamp(value, 0.01, 0.2)
	var txt = FileAccess.open("user://mouse_sens.txt", FileAccess.WRITE)
	if txt:
		txt.store_string(str(mouse_sensitivity))
		txt.close()

func start_server():
	var net = get_node_or_null("/root/Network")
	if net:
		net.host()
		is_server = true

func start_client(ip: String):
	var net = get_node_or_null("/root/Network")
	if net:
		net.join(ip)
		is_server = false

var day_length := 600.0
var time_of_day := 0.0

func _process(delta):
	time_of_day = fmod(time_of_day + delta, day_length)

func get_day_phase() -> float:
	return time_of_day / day_length

func is_night() -> bool:
	var phase = get_day_phase()
	return phase < 0.2 or phase > 0.8

var global_temperature := 15.0

func get_temperature() -> float:
	return global_temperature
