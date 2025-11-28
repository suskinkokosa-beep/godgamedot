extends Control

onready var grid = $Grid

func _ready():
    pass

func clear_grid():
    for c in grid.get_children():
        c.queue_free()

func populate(items):
    clear_grid()
    for it in items:
        var node = preload("res://scenes/ui/inv_item.tscn").instantiate()
        node.get_node("Count").text = str(it.count)
        node.set_meta("item_id", it.id)
        node.connect("pressed", Callable(self, "_on_item_pressed"), [node])
        grid.add_child(node)

func _on_item_pressed(node):
    var item_id = node.get_meta("item_id")
    # quick action: move to hotbar (slot 0) by emitting signal
    emit_signal("use_item_request", item_id)
