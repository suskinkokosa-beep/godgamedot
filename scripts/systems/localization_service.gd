extends Node

signal language_changed(new_lang: String)

var strings := {}
var current_lang := "ru"
var available_languages := ["ru", "en"]

var language_names := {
	"ru": "Русский",
	"en": "English"
}

func _ready():
	var settings = get_node_or_null("/root/SettingsManager")
	if settings:
		var saved_lang = settings.get_setting("language", "current")
		if saved_lang and saved_lang in available_languages:
			current_lang = saved_lang
	
	load_language(current_lang)
	_register_translations()

func _register_translations():
	for lang in available_languages:
		var path = "res://localization/%s.csv" % lang
		if ResourceLoader.exists(path.replace(".csv", ".translation")):
			var translation = load(path.replace(".csv", ".translation"))
			if translation:
				TranslationServer.add_translation(translation)

func load_language(lang: String):
	if lang not in available_languages:
		push_warning("Language not available: %s, falling back to ru" % lang)
		lang = "ru"
	
	current_lang = lang
	strings.clear()
	
	var path = "res://localization/%s.csv" % lang
	if not FileAccess.file_exists(path):
		push_error("Localization file not found: %s" % path)
		return
	
	var f = FileAccess.open(path, FileAccess.READ)
	if not f:
		push_error("Failed to open localization file: %s" % path)
		return
	
	var header = f.get_line()
	while not f.eof_reached():
		var line = f.get_line()
		if line.strip_edges() == "":
			continue
		
		var comma_idx = line.find(",")
		if comma_idx > 0:
			var key = line.substr(0, comma_idx).strip_edges()
			var txt = line.substr(comma_idx + 1).strip_edges()
			strings[key] = txt
	
	f.close()
	
	TranslationServer.set_locale(lang)
	
	emit_signal("language_changed", current_lang)
	
	var gm = get_node_or_null("/root/GameManager")
	if gm and gm.has_signal("language_changed"):
		gm.emit_signal("language_changed", current_lang)

func set_language(lang: String):
	if lang == current_lang:
		return
	
	load_language(lang)
	
	var settings = get_node_or_null("/root/SettingsManager")
	if settings:
		settings.set_language(lang)

func get_language() -> String:
	return current_lang

func get_available_languages() -> Array:
	return available_languages

func get_language_name(lang_code: String) -> String:
	return language_names.get(lang_code, lang_code)

func t(key: String, params = null) -> String:
	if strings.has(key):
		var s = strings[key]
		if params and typeof(params) == TYPE_DICTIONARY:
			for k in params.keys():
				s = s.replace("{" + str(k) + "}", str(params[k]))
		return s
	
	var tr_result = tr(key)
	if tr_result != key:
		if params and typeof(params) == TYPE_DICTIONARY:
			for k in params.keys():
				tr_result = tr_result.replace("{" + str(k) + "}", str(params[k]))
		return tr_result
	
	return key

func get_text(key: String, params = null) -> String:
	return t(key, params)

func has_key(key: String) -> bool:
	return strings.has(key)

func get_item_name(item_id: String) -> String:
	if strings.has(item_id):
		return strings[item_id]
	
	var formatted = item_id.replace("_", " ").capitalize()
	return formatted

func get_biome_name(biome_id: String) -> String:
	var key = "biome_" + biome_id
	if strings.has(key):
		return strings[key]
	return biome_id.replace("_", " ").capitalize()

func get_weather_name(weather_id: String) -> String:
	var key = "weather_" + weather_id
	if strings.has(key):
		return strings[key]
	return weather_id.replace("_", " ").capitalize()

func get_status_name(status_id: String) -> String:
	var key = "status_" + status_id
	if strings.has(key):
		return strings[key]
	return status_id.replace("_", " ").capitalize()

func format_number(number: float, decimals: int = 0) -> String:
	if decimals == 0:
		return str(int(number))
	return str(snapped(number, pow(10, -decimals)))

func format_time(seconds: float) -> String:
	var mins = int(seconds / 60)
	var secs = int(seconds) % 60
	return "%d:%02d" % [mins, secs]

func format_percentage(value: float, total: float) -> String:
	if total <= 0:
		return "0%"
	return "%d%%" % int((value / total) * 100)
