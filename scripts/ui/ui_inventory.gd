extends Control

signal use_item_request(item_id: String)
signal move_to_hotbar(item_id: String, slot: int)

@onready var grid = $Panel/MarginContainer/VBoxContainer/ScrollContainer/GridContainer
@onready var weight_label = $Panel/MarginContainer/VBoxContainer/TopBar/WeightLabel
@onready var close_button = $Panel/MarginContainer/VBoxContainer/TopBar/CloseButton

var inventory = null
var inv_item_scene = null

func _ready():
        inventory = get_node_or_null("/root/Inventory")
        
        if close_button:
                close_button.pressed.connect(_on_close_pressed)
        
        if ResourceLoader.exists("res://scenes/ui/inv_item.tscn"):
                inv_item_scene = load("res://scenes/ui/inv_item.tscn")
        
        if inventory:
                inventory.connect("inventory_changed", Callable(self, "refresh_inventory"))
        
        visibility_changed.connect(_on_visibility_changed)
        hide()

func _on_visibility_changed():
        if visible:
                refresh_inventory()

func _on_close_pressed():
        hide()
        Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func refresh_inventory():
        if not inventory:
                return
        
        clear_grid()
        
        var weight = inventory.total_weight()
        var max_w = inventory.max_weight
        weight_label.text = "Вес: %.1f / %.1f кг" % [weight, max_w]
        
        for slot in inventory.slots:
                if slot == null:
                        continue
                _add_item_to_grid(slot)

func clear_grid():
        for c in grid.get_children():
                c.queue_free()

func _add_item_to_grid(item: Dictionary):
        var item_panel = Panel.new()
        item_panel.custom_minimum_size = Vector2(80, 80)
        
        var vbox = VBoxContainer.new()
        vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
        vbox.add_theme_constant_override("separation", 2)
        item_panel.add_child(vbox)
        
        var name_label = Label.new()
        var info = inventory.get_item_info(item["id"])
        var item_name = info.get("name", item["id"])
        if item_name.length() > 10:
                item_name = item_name.substr(0, 10)
        name_label.text = item_name
        name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        name_label.add_theme_font_size_override("font_size", 11)
        vbox.add_child(name_label)
        
        var count_label = Label.new()
        count_label.text = "x" + str(item.get("count", 1))
        count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        count_label.add_theme_font_size_override("font_size", 12)
        vbox.add_child(count_label)
        
        var button = Button.new()
        button.text = "Исп."
        button.size_flags_vertical = Control.SIZE_SHRINK_END
        button.pressed.connect(_on_item_use.bind(item["id"]))
        vbox.add_child(button)
        
        item_panel.set_meta("item_id", item["id"])
        grid.add_child(item_panel)

func _on_item_use(item_id: String):
        if inventory and inventory.has_method("use_item"):
                inventory.use_item(item_id)
        emit_signal("use_item_request", item_id)
