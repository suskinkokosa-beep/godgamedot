extends Control

@onready var health_bar = $StatsPanel/HealthContainer/HealthBar
@onready var health_label = $StatsPanel/HealthContainer/HealthLabel
@onready var stamina_bar = $StatsPanel/StaminaContainer/StaminaBar
@onready var stamina_label = $StatsPanel/StaminaContainer/StaminaLabel
@onready var hunger_bar = $StatsPanel/HungerContainer/HungerBar
@onready var hunger_label = $StatsPanel/HungerContainer/HungerLabel
@onready var thirst_bar = $StatsPanel/ThirstContainer/ThirstBar
@onready var thirst_label = $StatsPanel/ThirstContainer/ThirstLabel
@onready var blood_bar = $StatsPanel/BloodContainer/BloodBar
@onready var blood_label = $StatsPanel/BloodContainer/BloodLabel
@onready var sanity_bar = $StatsPanel/SanityContainer/SanityBar
@onready var sanity_label = $StatsPanel/SanityContainer/SanityLabel
@onready var temp_label = $StatsPanel/TempContainer/TempLabel
@onready var debuff_panel = $DebuffPanel
@onready var interact_prompt = $InteractPrompt
@onready var xp_notification = $XPNotification
@onready var level_label = $LevelLabel
@onready var jump_indicator = $JumpIndicator
@onready var crouch_indicator = $CrouchIndicator
@onready var fps_label = $FPSLabel
@onready var hotbar_panel = $HotbarPanel
@onready var minimap = $Minimap
@onready var inventory_window = $InventoryWindow
@onready var time_label = $TimeLabel

var day_night = null

var player = null
var xp_display_timer := 0.0
var inventory = null
var hotbar_slots := []
var is_inventory_open := false

func _ready():
        await get_tree().process_frame
        _find_player()
        inventory = get_node_or_null("/root/Inventory")
        
        if inventory:
                inventory.connect("hotbar_changed", Callable(self, "_update_hotbar"))
        
        _setup_hotbar_slots()
        
        if inventory_window:
                inventory_window.hide()
                is_inventory_open = false
                inventory_window.visibility_changed.connect(_on_inventory_visibility_changed)
        
        var prog = get_node_or_null("/root/PlayerProgression")
        if prog:
                prog.connect("xp_gained", Callable(self, "_on_xp_gained"))
                prog.connect("level_up", Callable(self, "_on_level_up"))
        
        day_night = get_node_or_null("/root/DayNightCycle")
        if day_night:
                day_night.connect("time_changed", Callable(self, "_on_time_changed"))
                _update_time_display()

func _on_inventory_visibility_changed():
        if inventory_window:
                is_inventory_open = inventory_window.visible
                if not is_inventory_open:
                        Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _setup_hotbar_slots():
        hotbar_slots.clear()
        for i in range(8):
                var slot = hotbar_panel.get_node_or_null("Slot" + str(i + 1))
                if slot:
                        hotbar_slots.append(slot)
        _update_hotbar()

func _input(event):
        if event.is_action_pressed("inventory"):
                toggle_inventory()
        elif event.is_action_pressed("ui_cancel"):
                if is_inventory_open:
                        close_inventory()
        
        if event is InputEventKey and event.pressed:
                if event.keycode == KEY_F5:
                        _quick_save()
                elif event.keycode == KEY_F9:
                        _quick_load()

func _quick_save():
        var save_mgr = get_node_or_null("/root/SaveManager")
        if save_mgr:
                var slot_name = "quicksave"
                if save_mgr.save_game(slot_name):
                        var notif = get_node_or_null("/root/NotificationSystem")
                        if notif:
                                notif.show_notification("Игра сохранена", "success")
                        else:
                                print("Игра сохранена: ", slot_name)

func _quick_load():
        var save_mgr = get_node_or_null("/root/SaveManager")
        if save_mgr and save_mgr.has_save("quicksave"):
                if save_mgr.load_game("quicksave"):
                        var notif = get_node_or_null("/root/NotificationSystem")
                        if notif:
                                notif.show_notification("Игра загружена", "success")
                        else:
                                print("Игра загружена: quicksave")

func toggle_inventory():
        is_inventory_open = not is_inventory_open
        if inventory_window:
                inventory_window.visible = is_inventory_open
        
        if is_inventory_open:
                Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
        else:
                Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func close_inventory():
        is_inventory_open = false
        if inventory_window:
                inventory_window.visible = false
        Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _find_player():
        var players = get_tree().get_nodes_in_group("players")
        if players.size() > 0:
                player = players[0]

func _process(delta):
        if not player:
                _find_player()
                return
        
        _update_stats()
        _update_debuffs()
        _update_xp_display(delta)
        _update_jump_indicator()
        _update_crouch_indicator()
        _update_fps()
        _update_hotbar_selection()

func _update_stats():
        if player.get("health") != null:
                var h = player.health
                var max_h = player.get("max_health") if player.get("max_health") else 100
                health_bar.max_value = max_h
                health_bar.value = h
                health_label.text = str(int(h))
                _color_bar(health_bar, h / max_h * 100)
        
        if player.get("stamina") != null:
                var s = player.stamina
                var max_s = player.get("max_stamina") if player.get("max_stamina") else 100
                stamina_bar.max_value = max_s
                stamina_bar.value = s
                stamina_label.text = str(int(s))
                _color_bar(stamina_bar, s / max_s * 100)
        
        if player.get("hunger") != null:
                var hu = player.hunger
                hunger_bar.value = hu
                hunger_label.text = str(int(hu))
                _color_bar(hunger_bar, hu)
        
        if player.get("thirst") != null:
                var th = player.thirst
                thirst_bar.value = th
                thirst_label.text = str(int(th))
                _color_bar(thirst_bar, th)
        
        if player.get("blood") != null:
                var bl = player.blood
                blood_bar.value = bl
                blood_label.text = str(int(bl))
                _color_blood_bar(blood_bar, bl)
        
        if player.get("sanity") != null:
                var sa = player.sanity
                sanity_bar.value = sa
                sanity_label.text = str(int(sa))
                _color_bar(sanity_bar, sa)
        
        if player.get("body_temperature") != null:
                var temp = player.body_temperature
                temp_label.text = "%.1f°C" % temp
                if temp < 35.0 or temp > 38.5:
                        temp_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
                else:
                        temp_label.add_theme_color_override("font_color", Color(1, 1, 1))

func _color_bar(bar: ProgressBar, value: float):
        if value < 25:
                bar.modulate = Color(1, 0.2, 0.2)
        elif value < 50:
                bar.modulate = Color(1, 0.7, 0.2)
        else:
                bar.modulate = Color(0.2, 0.8, 0.2)

func _color_blood_bar(bar: ProgressBar, value: float):
        if value < 30:
                bar.modulate = Color(0.8, 0.1, 0.1)
        elif value < 60:
                bar.modulate = Color(0.9, 0.3, 0.3)
        else:
                bar.modulate = Color(0.7, 0.2, 0.2)

func _update_debuffs():
        for child in debuff_panel.get_children():
                child.queue_free()
        
        if not player:
                return
        
        var debuffs = []
        
        if player.get("hunger") != null and player.hunger < 10:
                debuffs.append("starving")
        if player.get("thirst") != null and player.thirst < 10:
                debuffs.append("dehydrated")
        if player.get("blood") != null and player.blood < 50:
                debuffs.append("bleeding")
        if player.get("body_temperature") != null:
                if player.body_temperature < 35.0:
                        debuffs.append("freezing")
                elif player.body_temperature > 38.5:
                        debuffs.append("overheating")
        if player.get("stamina") != null and player.stamina < 10:
                debuffs.append("exhausted")
        if player.get("sanity") != null and player.sanity < 20:
                debuffs.append("insane")
        
        for debuff in debuffs:
                var icon = Label.new()
                icon.text = _get_debuff_icon(debuff)
                icon.tooltip_text = _get_debuff_name(debuff)
                icon.add_theme_font_size_override("font_size", 20)
                debuff_panel.add_child(icon)

func _get_debuff_icon(debuff: String) -> String:
        var icons := {
                "starving": "🍽️",
                "dehydrated": "🏜️",
                "freezing": "❄️",
                "overheating": "🔥",
                "bleeding": "🩸",
                "exhausted": "😴",
                "insane": "😵"
        }
        return icons.get(debuff, "⚠️")

func _get_debuff_name(debuff: String) -> String:
        var names := {
                "starving": "Голодание",
                "dehydrated": "Обезвоживание",
                "freezing": "Замерзание",
                "overheating": "Перегрев",
                "bleeding": "Кровотечение",
                "exhausted": "Истощение",
                "insane": "Безумие"
        }
        return names.get(debuff, debuff)

func show_interact_prompt(text: String = "[E] Взаимодействовать"):
        interact_prompt.text = text
        interact_prompt.visible = true

func hide_interact_prompt():
        interact_prompt.visible = false

func _on_xp_gained(player_id: int, amount: float):
        xp_notification.text = "+%.0f XP" % amount
        xp_notification.visible = true
        xp_notification.modulate = Color(1, 0.8, 0, 1)
        xp_display_timer = 2.0

func _on_level_up(player_id: int, new_level: int):
        level_label.text = "Уровень: %d" % new_level
        
        var popup = AcceptDialog.new()
        popup.dialog_text = "Поздравляем! Вы достигли уровня %d!" % new_level
        popup.title = "Новый уровень!"
        add_child(popup)
        popup.popup_centered()

func _update_xp_display(delta):
        if xp_display_timer > 0:
                xp_display_timer -= delta
                xp_notification.modulate.a = min(1.0, xp_display_timer)
                if xp_display_timer <= 0:
                        xp_notification.visible = false

func _update_jump_indicator():
        if not jump_indicator:
                return
        
        var jumps = 2
        var max_j = 2
        
        if player.has_method("get_jumps_remaining"):
                jumps = player.get_jumps_remaining()
        elif player.get("jumps_remaining") != null:
                jumps = player.jumps_remaining
        
        if player.get("max_jumps") != null:
                max_j = player.max_jumps
        
        var jump_icons = ""
        for i in range(max_j):
                if i < jumps:
                        jump_icons += "●"
                else:
                        jump_icons += "○"
        
        jump_indicator.text = jump_icons
        
        if jumps == 0:
                jump_indicator.modulate = Color(0.5, 0.5, 0.5)
        elif jumps == max_j:
                jump_indicator.modulate = Color(0.2, 0.8, 1.0)
        else:
                jump_indicator.modulate = Color(1.0, 0.8, 0.2)

func _update_crouch_indicator():
        if not crouch_indicator:
                return
        
        var is_crouching = false
        if player.has_method("get_is_crouching"):
                is_crouching = player.get_is_crouching()
        elif player.get("is_crouching") != null:
                is_crouching = player.is_crouching
        
        crouch_indicator.visible = is_crouching

func _update_fps():
        if fps_label:
                var fps = Engine.get_frames_per_second()
                fps_label.text = "FPS: %d" % fps
                
                if fps >= 55:
                        fps_label.add_theme_color_override("font_color", Color(0.5, 0.8, 0.5, 0.7))
                elif fps >= 30:
                        fps_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.5, 0.7))
                else:
                        fps_label.add_theme_color_override("font_color", Color(0.8, 0.5, 0.5, 0.7))

const HOTBAR_ICONS := {
        "wood": "🪵", "stone": "🪨", "stick": "🥢", "plant_fiber": "🌿",
        "iron_ore": "⬛", "copper_ore": "🔶", "gold_ore": "🟡", "silver_ore": "⬜",
        "iron_ingot": "🔩", "copper_ingot": "🟧", "steel_ingot": "⬛",
        "hide": "🦴", "bone": "🦴", "flint": "🔺", "cloth": "🧵", "leather": "🟤",
        "coal": "⚫", "herbs": "🌿", "mushroom": "🍄", "wheat": "🌾",
        "fish": "🐟", "meat": "🥩", "cooked_meat": "🍖", "cooked_fish": "🍣",
        "berries": "🫐", "stew": "🍲", "bread": "🍞", "carrot": "🥕",
        "water_bottle": "💧", "bandage": "🩹", "medkit": "🏥", "medicine": "💊",
        "stone_axe": "🪓", "stone_pickaxe": "⛏️", "stone_knife": "🔪",
        "iron_axe": "🪓", "iron_pickaxe": "⛏️", "steel_axe": "🪓", "steel_pickaxe": "⛏️",
        "hammer": "🔨", "repair_hammer": "🔧", "fishing_rod": "🎣",
        "wooden_spear": "🗡️", "iron_sword": "⚔️", "steel_sword": "⚔️",
        "bow": "🏹", "crossbow": "🏹", "arrow": "➡️", "bolt": "🔩",
        "torch": "🔥", "campfire": "🔥", "sleeping_bag": "🛏️",
        "workbench_1": "🔧", "furnace": "🔥", "storage_box": "📦"
}

func _update_hotbar():
        if not inventory or not inventory.has_method("get_hotbar"):
                return
        
        var hotbar = inventory.get_hotbar()
        if hotbar == null:
                return
        
        for i in range(min(hotbar.size(), hotbar_slots.size())):
                var slot = hotbar_slots[i]
                if slot == null:
                        continue
                var item = hotbar[i]
                var label = slot.get_node_or_null("Label")
                
                if label:
                        if item != null and item is Dictionary and item.has("id"):
                                var icon = HOTBAR_ICONS.get(item["id"], "📦")
                                label.text = icon
                                label.add_theme_font_size_override("font_size", 24)
                                if item.has("count") and item["count"] > 1:
                                        label.text += "\n" + str(item["count"])
                                        label.add_theme_font_size_override("font_size", 18)
                        else:
                                label.text = ""

func _update_hotbar_selection():
        if not inventory or not inventory.has_method("get_selected_hotbar_slot"):
                return
        
        var selected = inventory.get_selected_hotbar_slot()
        
        for i in range(hotbar_slots.size()):
                var slot = hotbar_slots[i]
                if slot == null:
                        continue
                if i == selected:
                        slot.modulate = Color(1, 1, 0.6, 1)
                else:
                        slot.modulate = Color(1, 1, 1, 0.8)

func _on_time_changed(hour: int, minute: int):
        _update_time_display()

func _update_time_display():
        if not time_label or not day_night:
                return
        
        var time_str = day_night.get_time_string()
        var day = day_night.get_day()
        var period = day_night.get_period()
        
        var period_ru := ""
        match period:
                "dawn": period_ru = "рассвет"
                "day": period_ru = "день"
                "dusk": period_ru = "сумерки"
                "night": period_ru = "ночь"
        
        time_label.text = "День %d  %s (%s)" % [day, time_str, period_ru]
        
        if period == "night" or period == "dusk":
                time_label.add_theme_color_override("font_color", Color(0.6, 0.7, 1, 0.9))
        else:
                time_label.add_theme_color_override("font_color", Color(1, 0.95, 0.8, 0.9))
