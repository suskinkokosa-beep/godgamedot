
extends TextureRect
signal dragged(from_idx, to_idx)

var idx := 0
var item = null

func set_item(data):
    item = data
    texture = preload("res://icons/" + data.icon + ".png") if data else null

func clear():
    item = null
    texture = null

func _gui_input(e):
    if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
        emit_signal("dragged", idx, idx) # simplified placeholder
