extends Node
class_name GameManager

# Global game manager: holds game state, language, server/client flags, boot sequence

signal language_changed(new_lang)

var language := "en"
var is_server := false
var game_state := "init"

func _ready():
    # load saved language or default
    var lang_path = "res://localization/selected_lang.txt"
    if ResourceLoader.exists(lang_path):
        var txt = File.new()
        if txt.file_exists(lang_path):
            txt.open(lang_path, File.READ)
            language = txt.get_as_text().strip()
            txt.close()
    emit_signal("language_changed", language)

func set_language(lang:String):
    language = lang
    var txt = File.new()
    txt.open("res://localization/selected_lang.txt", File.WRITE)
    txt.store_string(language)
    txt.close()
    emit_signal("language_changed", language)

func get_language():
    return language

func start_server():
    var net = get_node_or_null("/root/Network")
    if net:
        net.host()
        is_server = true

func start_client(ip:String):
    var net = get_node_or_null("/root/Network")
    if net:
        net.join(ip)
        is_server = false

# Day/Night and environment time
var day_length := 600.0 # seconds per full day cycle
var time_of_day := 0.0 # 0..day_length

func _process(delta):
    time_of_day = (time_of_day + delta) % day_length

func get_day_phase() -> float:
    # returns 0..1 where 0 = midnight, 0.5 = noon
    return time_of_day / day_length

func is_night() -> bool:
    var phase = get_day_phase()
    return phase < 0.2 or phase > 0.8

# Temperature baseline per biome (can be overridden by WeatherSystem)
var global_temperature := 15.0 # degrees Celsius default

func get_temperature() -> float:
    return global_temperature
