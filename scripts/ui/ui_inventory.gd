extends Control

signal use_item_request(item_id: String)
signal move_to_hotbar(item_id: String, slot: int)
signal item_equipped(item_id: String)

@onready var grid = $Panel/MarginContainer/VBoxContainer/ScrollContainer/GridContainer
@onready var weight_label = $Panel/MarginContainer/VBoxContainer/TopBar/WeightLabel
@onready var close_button = $Panel/MarginContainer/VBoxContainer/TopBar/CloseButton
@onready var hotbar_container = $Panel/MarginContainer/VBoxContainer/HotbarArea/HotbarSlots

var inventory = null
var inv_item_scene = null
var dragged_item: Dictionary = {}
var drag_preview: Control = null
var hotbar_slots: Array = []

const ITEM_COLORS := {
        "resource": Color(0.6, 0.5, 0.4),
        "food": Color(0.7, 0.5, 0.3),
        "drink": Color(0.4, 0.6, 0.8),
        "medical": Color(0.9, 0.3, 0.3),
        "tool": Color(0.5, 0.5, 0.6),
        "weapon": Color(0.6, 0.4, 0.4),
        "armor": Color(0.4, 0.5, 0.6),
        "ammo": Color(0.5, 0.4, 0.3),
        "light": Color(0.8, 0.7, 0.3),
        "placeable": Color(0.4, 0.6, 0.4),
        "building": Color(0.5, 0.5, 0.4),
        "misc": Color(0.5, 0.5, 0.5)
}

const ITEM_ICONS := {
        "wood": "🪵",
        "stone": "🪨",
        "stick": "🥢",
        "plant_fiber": "🌿",
        "iron_ore": "⬛",
        "copper_ore": "🔶",
        "gold_ore": "🟡",
        "silver_ore": "⬜",
        "iron_ingot": "🔩",
        "copper_ingot": "🟧",
        "steel_ingot": "⬛",
        "silver_ingot": "⬜",
        "gold_ingot": "🟨",
        "hide": "🦴",
        "bone": "🦴",
        "flint": "🔺",
        "cloth": "🧵",
        "leather": "🟤",
        "rope": "〰️",
        "coal": "⚫",
        "sulfur": "🟡",
        "gunpowder": "💥",
        "herbs": "🌿",
        "mushroom": "🍄",
        "wheat": "🌾",
        "fish": "🐟",
        "meat": "🥩",
        "cooked_meat": "🍖",
        "cooked_fish": "🍣",
        "berries": "🫐",
        "berry_mix": "🍇",
        "stew": "🍲",
        "bread": "🍞",
        "grilled_vegetables": "🥗",
        "carrot": "🥕",
        "water_bottle": "💧",
        "bandage": "🩹",
        "medkit": "🏥",
        "medicine": "💊",
        "antidote": "💉",
        "blood_pack": "🩸",
        "splint": "🦴",
        "painkiller": "💊",
        "anti_rad": "☢️",
        "warm_potion": "🔥",
        "cooling_potion": "❄️",
        "stone_axe": "🪓",
        "stone_pickaxe": "⛏️",
        "stone_knife": "🔪",
        "iron_axe": "🪓",
        "iron_pickaxe": "⛏️",
        "steel_axe": "🪓",
        "steel_pickaxe": "⛏️",
        "hammer": "🔨",
        "repair_hammer": "🔧",
        "fishing_rod": "🎣",
        "wooden_spear": "🗡️",
        "iron_sword": "⚔️",
        "steel_sword": "⚔️",
        "bow": "🏹",
        "crossbow": "🏹",
        "arrow": "➡️",
        "iron_arrow": "➡️",
        "bolt": "🔩",
        "torch": "🔥",
        "campfire": "🔥",
        "sleeping_bag": "🛏️",
        "workbench_1": "🔧",
        "workbench_2": "🔧",
        "workbench_3": "🔧",
        "furnace": "🔥",
        "storage_box": "📦",
        "large_storage": "📦",
        "tool_cupboard": "🧰",
        "wooden_foundation": "🏠",
        "wooden_wall": "🧱",
        "wooden_floor": "🪵",
        "wooden_door": "🚪",
        "wooden_doorframe": "🚪",
        "wooden_window": "🪟",
        "wooden_roof": "🏠",
        "wooden_stairs": "🪜",
        "stone_foundation": "🏠",
        "stone_wall": "🧱",
        "stone_floor": "🪨",
        "metal_door": "🚪",
        "armored_door": "🚪",
        "leather_vest": "🦺",
        "leather_pants": "👖",
        "leather_boots": "👢",
        "leather_gloves": "🧤",
        "leather_helmet": "⛑️",
        "iron_armor_chest": "🛡️",
        "iron_armor_legs": "👖",
        "iron_helmet": "⛑️",
        "steel_armor_chest": "🛡️",
        "steel_armor_legs": "👖",
        "steel_helmet": "⛑️"
}

func _ready():
        inventory = get_node_or_null("/root/Inventory")
        
        if close_button:
                close_button.pressed.connect(_on_close_pressed)
        
        if ResourceLoader.exists("res://scenes/ui/inv_item.tscn"):
                inv_item_scene = load("res://scenes/ui/inv_item.tscn")
        
        if inventory:
                inventory.connect("inventory_changed", Callable(self, "refresh_inventory"))
                inventory.connect("hotbar_changed", Callable(self, "_update_hotbar_display"))
        
        visibility_changed.connect(_on_visibility_changed)
        
        _setup_hotbar_slots()
        hide()

func _setup_hotbar_slots():
        hotbar_slots.clear()
        if not hotbar_container:
                return
        
        for child in hotbar_container.get_children():
                child.queue_free()
        
        for i in range(8):
                var slot = _create_hotbar_slot(i)
                hotbar_container.add_child(slot)
                hotbar_slots.append(slot)

func _create_hotbar_slot(index: int) -> Panel:
        var slot = Panel.new()
        slot.name = "HotbarSlot" + str(index)
        slot.custom_minimum_size = Vector2(60, 60)
        
        var style = StyleBoxFlat.new()
        style.bg_color = Color(0.2, 0.2, 0.2, 0.8)
        style.border_width_left = 2
        style.border_width_right = 2
        style.border_width_top = 2
        style.border_width_bottom = 2
        style.border_color = Color(0.4, 0.4, 0.4)
        style.corner_radius_top_left = 4
        style.corner_radius_top_right = 4
        style.corner_radius_bottom_left = 4
        style.corner_radius_bottom_right = 4
        slot.add_theme_stylebox_override("panel", style)
        
        var number_label = Label.new()
        number_label.name = "NumberLabel"
        number_label.text = str(index + 1)
        number_label.position = Vector2(2, 0)
        number_label.add_theme_font_size_override("font_size", 10)
        number_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
        slot.add_child(number_label)
        
        var icon_container = CenterContainer.new()
        icon_container.name = "IconContainer"
        icon_container.set_anchors_preset(Control.PRESET_FULL_RECT)
        slot.add_child(icon_container)
        
        var icon_tex = TextureRect.new()
        icon_tex.name = "IconTexture"
        icon_tex.custom_minimum_size = Vector2(32, 32)
        icon_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        icon_container.add_child(icon_tex)
        
        var icon_label = Label.new()
        icon_label.name = "IconLabel"
        icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        icon_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
        icon_label.set_anchors_preset(Control.PRESET_FULL_RECT)
        icon_label.add_theme_font_size_override("font_size", 28)
        icon_label.visible = false
        slot.add_child(icon_label)
        
        var count_label = Label.new()
        count_label.name = "CountLabel"
        count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
        count_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
        count_label.set_anchors_preset(Control.PRESET_FULL_RECT)
        count_label.add_theme_font_size_override("font_size", 11)
        count_label.add_theme_color_override("font_color", Color(1, 1, 1))
        slot.add_child(count_label)
        
        slot.gui_input.connect(_on_hotbar_slot_input.bind(index))
        slot.mouse_entered.connect(_on_hotbar_slot_hover.bind(index, true))
        slot.mouse_exited.connect(_on_hotbar_slot_hover.bind(index, false))
        
        slot.set_meta("slot_index", index)
        
        return slot

func _on_hotbar_slot_input(event: InputEvent, slot_index: int):
        if event is InputEventMouseButton and event.pressed:
                if event.button_index == MOUSE_BUTTON_LEFT:
                        if not dragged_item.is_empty():
                                _drop_item_to_hotbar(slot_index)
                        else:
                                var item = inventory.get_hotbar_slot(slot_index)
                                if item != null:
                                        inventory.move_from_hotbar(slot_index)
                elif event.button_index == MOUSE_BUTTON_RIGHT:
                        var item = inventory.get_hotbar_slot(slot_index)
                        if item != null:
                                _use_hotbar_item(slot_index)

func _on_hotbar_slot_hover(slot_index: int, hovering: bool):
        if slot_index < hotbar_slots.size():
                var slot = hotbar_slots[slot_index]
                var style = slot.get_theme_stylebox("panel").duplicate()
                if style is StyleBoxFlat:
                        if hovering:
                                style.border_color = Color(0.8, 0.7, 0.3)
                        else:
                                style.border_color = Color(0.4, 0.4, 0.4)
                        slot.add_theme_stylebox_override("panel", style)

func _use_hotbar_item(slot_index: int):
        var players = get_tree().get_nodes_in_group("players")
        var player = players[0] if players.size() > 0 else null
        if inventory:
                var old_selected = inventory.get_selected_hotbar_slot()
                inventory.select_hotbar_slot(slot_index)
                inventory.use_selected_hotbar_item(player)
                inventory.select_hotbar_slot(old_selected)

func _on_visibility_changed():
        if visible:
                refresh_inventory()
                _update_hotbar_display()

func _on_close_pressed():
        hide()
        Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func refresh_inventory():
        if not inventory:
                return
        
        clear_grid()
        
        var weight = inventory.total_weight()
        var max_w = inventory.max_weight
        
        var prog = get_node_or_null("/root/PlayerProgression")
        if prog:
                var players = get_tree().get_nodes_in_group("players")
                if players.size() > 0:
                        var player = players[0]
                        max_w = prog.get_carry_capacity(player.net_id if player.get("net_id") != null else 1)
        
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
        item_panel.custom_minimum_size = Vector2(70, 85)
        
        var style = StyleBoxFlat.new()
        var info = inventory.get_item_info(item["id"])
        var item_type = info.get("type", "misc")
        var base_color = ITEM_COLORS.get(item_type, Color(0.5, 0.5, 0.5))
        style.bg_color = Color(base_color.r * 0.3, base_color.g * 0.3, base_color.b * 0.3, 0.9)
        style.border_width_left = 2
        style.border_width_right = 2
        style.border_width_top = 2
        style.border_width_bottom = 2
        style.border_color = base_color
        style.corner_radius_top_left = 4
        style.corner_radius_top_right = 4
        style.corner_radius_bottom_left = 4
        style.corner_radius_bottom_right = 4
        item_panel.add_theme_stylebox_override("panel", style)
        
        var vbox = VBoxContainer.new()
        vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
        vbox.add_theme_constant_override("separation", 1)
        item_panel.add_child(vbox)
        
        var icon_container = CenterContainer.new()
        icon_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
        vbox.add_child(icon_container)
        
        var icon_mgr = get_node_or_null("/root/IconManager")
        if icon_mgr:
                var tex_rect = TextureRect.new()
                tex_rect.texture = icon_mgr.get_icon_for_item(item["id"])
                tex_rect.custom_minimum_size = Vector2(32, 32)
                tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
                icon_container.add_child(tex_rect)
        else:
                var icon_label = Label.new()
                icon_label.text = ITEM_ICONS.get(item["id"], "📦")
                icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
                icon_label.add_theme_font_size_override("font_size", 28)
                icon_container.add_child(icon_label)
        
        var item_name = info.get("name", item["id"])
        if item_name.length() > 8:
                item_name = item_name.substr(0, 7) + "."
        
        var name_label = Label.new()
        name_label.text = item_name
        name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        name_label.add_theme_font_size_override("font_size", 10)
        vbox.add_child(name_label)
        
        var count_label = Label.new()
        count_label.text = "x" + str(item.get("count", 1))
        count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        count_label.add_theme_font_size_override("font_size", 11)
        count_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
        vbox.add_child(count_label)
        
        var button_container = HBoxContainer.new()
        button_container.alignment = BoxContainer.ALIGNMENT_CENTER
        vbox.add_child(button_container)
        
        var use_btn = Button.new()
        use_btn.text = "И"
        use_btn.tooltip_text = "Использовать"
        use_btn.custom_minimum_size = Vector2(25, 20)
        use_btn.add_theme_font_size_override("font_size", 10)
        use_btn.pressed.connect(_on_item_use.bind(item["id"]))
        button_container.add_child(use_btn)
        
        var equip_btn = Button.new()
        equip_btn.text = "Э"
        equip_btn.tooltip_text = "Экипировать / На пояс"
        equip_btn.custom_minimum_size = Vector2(25, 20)
        equip_btn.add_theme_font_size_override("font_size", 10)
        equip_btn.pressed.connect(_on_item_equip.bind(item["id"]))
        button_container.add_child(equip_btn)
        
        item_panel.set_meta("item_id", item["id"])
        item_panel.set_meta("item_data", item)
        
        item_panel.gui_input.connect(_on_item_panel_input.bind(item))
        item_panel.mouse_entered.connect(_on_item_hover.bind(item_panel, true))
        item_panel.mouse_exited.connect(_on_item_hover.bind(item_panel, false))
        
        grid.add_child(item_panel)

func _on_item_hover(panel: Panel, hovering: bool):
        var style = panel.get_theme_stylebox("panel").duplicate()
        if style is StyleBoxFlat:
                if hovering:
                        style.border_color = Color(1, 0.9, 0.5)
                else:
                        var info = inventory.get_item_info(panel.get_meta("item_id"))
                        var item_type = info.get("type", "misc")
                        style.border_color = ITEM_COLORS.get(item_type, Color(0.5, 0.5, 0.5))
                panel.add_theme_stylebox_override("panel", style)

func _on_item_panel_input(event: InputEvent, item: Dictionary):
        if event is InputEventMouseButton:
                if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
                        _start_drag(item)
                elif event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
                        _end_drag()

func _start_drag(item: Dictionary):
        dragged_item = item.duplicate()
        
        drag_preview = Panel.new()
        drag_preview.custom_minimum_size = Vector2(50, 50)
        drag_preview.modulate = Color(1, 1, 1, 0.7)
        
        var style = StyleBoxFlat.new()
        style.bg_color = Color(0.3, 0.3, 0.3, 0.9)
        style.border_color = Color(0.8, 0.7, 0.3)
        style.border_width_left = 2
        style.border_width_right = 2
        style.border_width_top = 2
        style.border_width_bottom = 2
        drag_preview.add_theme_stylebox_override("panel", style)
        
        var icon = Label.new()
        icon.text = ITEM_ICONS.get(item["id"], "📦")
        icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
        icon.set_anchors_preset(Control.PRESET_FULL_RECT)
        icon.add_theme_font_size_override("font_size", 24)
        drag_preview.add_child(icon)
        
        add_child(drag_preview)
        drag_preview.z_index = 100

func _end_drag():
        if drag_preview:
                drag_preview.queue_free()
                drag_preview = null
        dragged_item = {}

func _drop_item_to_hotbar(slot_index: int):
        if dragged_item.is_empty():
                return
        
        if inventory:
                inventory.move_to_hotbar(dragged_item["id"], slot_index)
        
        _end_drag()
        refresh_inventory()
        _update_hotbar_display()

func _process(_delta):
        if drag_preview and not dragged_item.is_empty():
                drag_preview.global_position = get_global_mouse_position() - drag_preview.size / 2

func _on_item_use(item_id: String):
        var players = get_tree().get_nodes_in_group("players")
        var player = players[0] if players.size() > 0 else null
        if inventory and inventory.has_method("use_item"):
                inventory.use_item(item_id, player)
        emit_signal("use_item_request", item_id)
        refresh_inventory()

func _on_item_equip(item_id: String):
        if not inventory:
                return
        
        var info = inventory.get_item_info(item_id)
        var item_type = info.get("type", "misc")
        
        if item_type == "armor" and info.has("slot"):
                var slot_name = info["slot"]
                for s in inventory.slots:
                        if s["id"] == item_id:
                                inventory.equip(slot_name, s)
                                emit_signal("item_equipped", item_id)
                                break
        else:
                for i in range(8):
                        if inventory.get_hotbar_slot(i) == null:
                                inventory.move_to_hotbar(item_id, i)
                                break
        
        refresh_inventory()
        _update_hotbar_display()

func _update_hotbar_display():
        if not inventory:
                return
        
        var hotbar = inventory.get_hotbar()
        var selected = inventory.get_selected_hotbar_slot()
        var icon_mgr = get_node_or_null("/root/IconManager")
        
        for i in range(min(hotbar.size(), hotbar_slots.size())):
                var slot = hotbar_slots[i]
                var item = hotbar[i]
                
                var icon_container = slot.get_node_or_null("IconContainer")
                var icon_tex = icon_container.get_node_or_null("IconTexture") if icon_container else null
                var icon_label = slot.get_node_or_null("IconLabel")
                var count_label = slot.get_node_or_null("CountLabel")
                
                if icon_tex:
                        icon_tex.texture = null
                        icon_tex.visible = false
                if icon_label:
                        icon_label.text = ""
                        icon_label.visible = false
                if count_label:
                        count_label.text = ""
                
                if item != null and item is Dictionary and item.has("id"):
                        if icon_tex and icon_mgr:
                                icon_tex.texture = icon_mgr.get_icon_for_item(item["id"])
                                icon_tex.visible = true
                        elif icon_label:
                                icon_label.text = ITEM_ICONS.get(item["id"], "📦")
                                icon_label.visible = true
                        
                        if count_label and item.has("count") and item["count"] > 1:
                                count_label.text = str(item["count"])
                
                var style = slot.get_theme_stylebox("panel").duplicate()
                if style is StyleBoxFlat:
                        if i == selected:
                                style.border_color = Color(1, 0.8, 0.2)
                                style.border_width_left = 3
                                style.border_width_right = 3
                                style.border_width_top = 3
                                style.border_width_bottom = 3
                        else:
                                style.border_color = Color(0.4, 0.4, 0.4)
                                style.border_width_left = 2
                                style.border_width_right = 2
                                style.border_width_top = 2
                                style.border_width_bottom = 2
                        slot.add_theme_stylebox_override("panel", style)

func _input(event):
        if not visible:
                return
        
        if event is InputEventMouseButton:
                if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
                        if not dragged_item.is_empty():
                                _end_drag()
