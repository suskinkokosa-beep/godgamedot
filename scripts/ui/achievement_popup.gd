extends Control

signal popup_closed()

var popup_queue := []
var current_popup: Dictionary = {}
var is_showing := false
var display_time := 4.0
var current_timer := 0.0

var achievement_icons := {
        "first_kill": "X",
        "first_craft": "C",
        "first_build": "B",
        "explorer": "E",
        "survivor": "S",
        "trader": "$",
        "hunter": "H",
        "builder": "B",
        "gatherer": "G",
        "warrior": "W",
        "default": "*"
}

var rarity_colors := {
        "bronze": Color(0.8, 0.5, 0.2),
        "silver": Color(0.75, 0.75, 0.8),
        "gold": Color(1.0, 0.85, 0.3),
        "platinum": Color(0.9, 0.95, 1.0),
        "diamond": Color(0.6, 0.9, 1.0)
}

var panel: PanelContainer = null
var icon_label: Label = null
var title_label: Label = null
var desc_label: Label = null
var progress_bar: ProgressBar = null

var tween: Tween = null

func _ready():
        _setup_ui()
        hide()
        
        var quest = get_node_or_null("/root/QuestSystem")
        if quest:
                if quest.has_signal("achievement_unlocked"):
                        quest.achievement_unlocked.connect(_on_achievement_unlocked)

func _setup_ui():
        custom_minimum_size = Vector2(350, 100)
        anchors_preset = Control.PRESET_TOP_RIGHT
        position = Vector2(-370, 20)
        
        panel = get_node_or_null("Panel")
        if panel:
                icon_label = panel.get_node_or_null("IconLabel")
                title_label = panel.get_node_or_null("TitleLabel")
                desc_label = panel.get_node_or_null("DescLabel")
                progress_bar = panel.get_node_or_null("ProgressBar")
        
        if not panel:
                panel = PanelContainer.new()
                panel.name = "Panel"
                panel.custom_minimum_size = Vector2(350, 90)
                
                var style = StyleBoxFlat.new()
                style.bg_color = Color(0.15, 0.12, 0.1, 0.95)
                style.border_color = Color(0.6, 0.5, 0.3)
                style.set_border_width_all(2)
                style.set_corner_radius_all(8)
                style.set_content_margin_all(12)
                panel.add_theme_stylebox_override("panel", style)
                add_child(panel)
                
                var vbox = VBoxContainer.new()
                vbox.add_theme_constant_override("separation", 4)
                panel.add_child(vbox)
                
                var hbox = HBoxContainer.new()
                hbox.add_theme_constant_override("separation", 10)
                vbox.add_child(hbox)
                
                icon_label = Label.new()
                icon_label.name = "IconLabel"
                icon_label.add_theme_font_size_override("font_size", 32)
                icon_label.custom_minimum_size = Vector2(40, 40)
                hbox.add_child(icon_label)
                
                var text_vbox = VBoxContainer.new()
                text_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
                hbox.add_child(text_vbox)
                
                title_label = Label.new()
                title_label.name = "TitleLabel"
                title_label.add_theme_font_size_override("font_size", 18)
                title_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.7))
                text_vbox.add_child(title_label)
                
                desc_label = Label.new()
                desc_label.name = "DescLabel"
                desc_label.add_theme_font_size_override("font_size", 12)
                desc_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
                text_vbox.add_child(desc_label)
                
                progress_bar = ProgressBar.new()
                progress_bar.name = "ProgressBar"
                progress_bar.custom_minimum_size = Vector2(0, 8)
                progress_bar.show_percentage = false
                vbox.add_child(progress_bar)

func _process(delta):
        if is_showing:
                current_timer -= delta
                if current_timer <= 0:
                        _hide_popup()

func _on_achievement_unlocked(achievement_id: String, achievement_data: Dictionary):
        queue_achievement(achievement_id, achievement_data)

func queue_achievement(id: String, data: Dictionary):
        popup_queue.append({
                "id": id,
                "title": data.get("title", "Achievement Unlocked"),
                "description": data.get("description", ""),
                "icon": data.get("icon", "default"),
                "rarity": data.get("rarity", "bronze"),
                "progress": data.get("progress", 1.0),
                "xp_reward": data.get("xp_reward", 0)
        })
        
        if not is_showing:
                _show_next_popup()

func queue_progress_update(id: String, title: String, current: int, total: int):
        popup_queue.append({
                "id": id,
                "title": title,
                "description": str(current) + " / " + str(total),
                "icon": "default",
                "rarity": "bronze",
                "progress": float(current) / float(total),
                "is_progress": true
        })
        
        if not is_showing:
                _show_next_popup()

func _show_next_popup():
        if popup_queue.size() == 0:
                return
        
        current_popup = popup_queue.pop_front()
        is_showing = true
        current_timer = display_time
        
        if current_popup.get("is_progress", false):
                current_timer = 2.0
        
        _update_display()
        _animate_in()

func _update_display():
        if icon_label:
                icon_label.text = achievement_icons.get(current_popup.get("icon", "default"), "*")
                icon_label.add_theme_color_override("font_color", rarity_colors.get(current_popup.get("rarity", "bronze"), Color.WHITE))
        
        if title_label:
                title_label.text = current_popup.get("title", "Achievement")
        
        if desc_label:
                var desc = current_popup.get("description", "")
                var xp = current_popup.get("xp_reward", 0)
                if xp > 0:
                        desc += " (+%d XP)" % xp
                desc_label.text = desc
        
        if progress_bar:
                var progress = current_popup.get("progress", 1.0)
                progress_bar.value = progress * 100
                progress_bar.visible = progress < 1.0 or current_popup.get("is_progress", false)

func _animate_in():
        show()
        modulate.a = 0
        position.x = 400
        
        if tween and tween.is_running():
                tween.kill()
        
        tween = create_tween()
        tween.set_ease(Tween.EASE_OUT)
        tween.set_trans(Tween.TRANS_BACK)
        tween.parallel().tween_property(self, "modulate:a", 1.0, 0.3)
        tween.parallel().tween_property(self, "position:x", -370, 0.4)
        
        var audio = get_node_or_null("/root/AudioManager")
        if audio and not current_popup.get("is_progress", false):
                audio.play_event_sound("achievement")

func _hide_popup():
        if tween and tween.is_running():
                tween.kill()
        
        tween = create_tween()
        tween.set_ease(Tween.EASE_IN)
        tween.set_trans(Tween.TRANS_CUBIC)
        tween.parallel().tween_property(self, "modulate:a", 0.0, 0.3)
        tween.parallel().tween_property(self, "position:x", 400, 0.3)
        tween.tween_callback(_on_hide_complete)

func _on_hide_complete():
        hide()
        is_showing = false
        current_popup = {}
        emit_signal("popup_closed")
        
        if popup_queue.size() > 0:
                call_deferred("_show_next_popup")
