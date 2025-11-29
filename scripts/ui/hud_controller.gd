extends Control

@onready var health_bar = $StatsPanel/HealthContainer/HealthBar
@onready var health_label = $StatsPanel/HealthContainer/HealthLabel
@onready var stamina_bar = $StatsPanel/StaminaContainer/StaminaBar
@onready var stamina_label = $StatsPanel/StaminaContainer/StaminaLabel
@onready var hunger_bar = $StatsPanel/HungerContainer/HungerBar
@onready var hunger_label = $StatsPanel/HungerContainer/HungerLabel
@onready var thirst_bar = $StatsPanel/ThirstContainer/ThirstBar
@onready var thirst_label = $StatsPanel/ThirstContainer/ThirstLabel
@onready var sanity_bar = $StatsPanel/SanityContainer/SanityBar
@onready var sanity_label = $StatsPanel/SanityContainer/SanityLabel
@onready var temp_label = $StatsPanel/TempContainer/TempLabel
@onready var debuff_panel = $DebuffPanel
@onready var interact_prompt = $InteractPrompt
@onready var xp_notification = $XPNotification
@onready var level_label = $LevelLabel
@onready var jump_indicator = $JumpIndicator

var player = null
var xp_display_timer := 0.0

func _ready():
        await get_tree().process_frame
        _find_player()
        
        var prog = get_node_or_null("/root/PlayerProgression")
        if prog:
                prog.connect("xp_gained", Callable(self, "_on_xp_gained"))
                prog.connect("level_up", Callable(self, "_on_level_up"))

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

func _update_stats():
        if player.get("health") != null:
                var h = player.health
                health_bar.value = h
                health_label.text = str(int(h))
                _color_bar(health_bar, h)
        
        if player.get("stamina") != null:
                var s = player.stamina
                stamina_bar.value = s
                stamina_label.text = str(int(s))
                _color_bar(stamina_bar, s)
        
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
        var style = bar.get_theme_stylebox("fill")
        if style == null:
                return
        
        if value < 25:
                bar.modulate = Color(1, 0.2, 0.2)
        elif value < 50:
                bar.modulate = Color(1, 0.7, 0.2)
        else:
                bar.modulate = Color(0.2, 0.8, 0.2)

func _update_debuffs():
        for child in debuff_panel.get_children():
                child.queue_free()
        
        if not player or not player.get("active_debuffs"):
                return
        
        for debuff in player.active_debuffs:
                var icon = Label.new()
                icon.text = _get_debuff_icon(debuff)
                icon.tooltip_text = _get_debuff_name(debuff)
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
        
        if player.get("jumps_remaining") != null:
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
