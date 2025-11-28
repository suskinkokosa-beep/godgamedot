extends Node
class_name LocalizationService

var strings = {}
var current_lang = "en"

func _ready():
    load_language(current_lang)

func load_language(lang:String):
    current_lang = lang
    strings.clear()
    var path = "res://localization/%s.csv" % lang
    var f = File.new()
    if not f.file_exists(path):
        push_error("Localization file not found: %s" % path)
        return
    f.open(path, File.READ)
    # skip header
    var header = f.get_line()
    while not f.eof_reached():
        var line = f.get_line()
        if line.strip() == "":
            continue
        var parts = line.split(",", false, 1)
        if parts.size() >= 2:
            var key = parts[0].strip()
            var txt = parts[1].strip()
            strings[key] = txt
    f.close()
    # notify game manager or UI via signal if present
    var gm = get_node_or_null("/root/GameManager")
    if gm:
        gm.emit_signal("language_changed", current_lang)

func t(key:String, params = null) -> String:
    if strings.has(key):
        var s = strings[key]
        if params and typeof(params) == TYPE_DICTIONARY:
            for k in params.keys():
                s = s.replace("{" + str(k) + "}", str(params[k]))
        return s
    return key
