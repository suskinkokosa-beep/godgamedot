extends Control

func _ready():
    $BtnEN.pressed.connect(_on_en)
    $BtnRU.pressed.connect(_on_ru)

func _on_en():
    var gm = get_node_or_null("/root/GameManager")
    if gm:
        gm.set_language("en")
    var loc = get_node_or_null("/root/LocalizationService")
    if loc:
        loc.load_language("en")

func _on_ru():
    var gm = get_node_or_null("/root/GameManager")
    if gm:
        gm.set_language("ru")
    var loc = get_node_or_null("/root/LocalizationService")
    if loc:
        loc.load_language("ru")
