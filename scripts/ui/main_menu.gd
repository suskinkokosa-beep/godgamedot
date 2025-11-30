extends Control

@onready var multiplayer_panel = $MultiplayerPanel
@onready var settings_panel = $SettingsPanel
@onready var saves_panel = $SavesPanel
@onready var main_buttons = $VBoxContainer
@onready var ip_input = $MultiplayerPanel/VBox/IPInput
@onready var lang_option = $SettingsPanel/VBox/LangOption
@onready var sens_slider = $SettingsPanel/VBox/SensSlider
@onready var sens_value = $SettingsPanel/VBox/SensValue
@onready var slot_container = $SavesPanel/VBox/SlotContainer

var current_sensitivity := 0.06
var selected_save_slot := ""
var menu_tween: Tween

func _ready():
        Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
        _setup_language_options()
        _load_settings()
        sens_slider.value_changed.connect(_on_sens_changed)
        _apply_rust_theme()
        _animate_menu_entrance()

func _apply_rust_theme():
        _create_animated_background()
        _create_decorative_elements()
        
        var title_label = get_node_or_null("VBoxContainer/Title")
        if title_label:
                title_label.text = "EPOCH SETTLEMENTS"
                title_label.add_theme_font_size_override("font_size", 64)
                title_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.5))
                title_label.add_theme_color_override("font_shadow_color", Color(0.3, 0.15, 0.05, 0.9))
                title_label.add_theme_constant_override("shadow_offset_x", 4)
                title_label.add_theme_constant_override("shadow_offset_y", 4)
        
        var subtitle = get_node_or_null("VBoxContainer/Subtitle")
        if subtitle:
                subtitle.text = "Survival Settlement Builder"
                subtitle.add_theme_font_size_override("font_size", 20)
                subtitle.add_theme_color_override("font_color", Color(0.7, 0.6, 0.5))
        
        _style_buttons()
        _add_version_label()

func _create_animated_background():
        var bg = get_node_or_null("Background")
        if bg:
                bg.color = Color(0.02, 0.015, 0.01, 1.0)
        
        var gradient_overlay = ColorRect.new()
        gradient_overlay.name = "GradientOverlay"
        gradient_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
        gradient_overlay.color = Color(0.1, 0.06, 0.03, 0.6)
        gradient_overlay.z_index = -9
        add_child(gradient_overlay)
        move_child(gradient_overlay, 1)
        
        var vignette = ColorRect.new()
        vignette.name = "Vignette"
        vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
        vignette.z_index = -8
        
        var shader_code = """
shader_type canvas_item;
void fragment() {
        vec2 uv = UV - 0.5;
        float dist = length(uv);
        float vignette = 1.0 - smoothstep(0.3, 0.8, dist);
        COLOR = vec4(0.0, 0.0, 0.0, 1.0 - vignette * 0.7);
}
"""
        var shader = Shader.new()
        shader.code = shader_code
        var shader_mat = ShaderMaterial.new()
        shader_mat.shader = shader
        vignette.material = shader_mat
        add_child(vignette)
        move_child(vignette, 2)

func _create_decorative_elements():
        var particles_container = Control.new()
        particles_container.name = "ParticlesContainer"
        particles_container.set_anchors_preset(Control.PRESET_FULL_RECT)
        particles_container.z_index = -7
        particles_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
        add_child(particles_container)
        move_child(particles_container, 3)
        
        for i in range(30):
                var particle = ColorRect.new()
                particle.size = Vector2(randf_range(2, 6), randf_range(2, 6))
                particle.position = Vector2(randf_range(0, 1280), randf_range(0, 720))
                particle.color = Color(1.0, 0.7, 0.3, randf_range(0.1, 0.4))
                particle.mouse_filter = Control.MOUSE_FILTER_IGNORE
                particles_container.add_child(particle)
                
                var tween = create_tween().set_loops()
                tween.tween_property(particle, "position:y", particle.position.y - randf_range(50, 150), randf_range(3, 8))
                tween.tween_property(particle, "modulate:a", 0.0, 1.0)
                tween.tween_callback(func(): 
                        particle.position.y = randf_range(720, 800)
                        particle.modulate.a = 1.0
                )
        
        var border_left = ColorRect.new()
        border_left.name = "BorderLeft"
        border_left.size = Vector2(4, 720)
        border_left.position = Vector2(50, 0)
        border_left.color = Color(0.6, 0.4, 0.2, 0.3)
        border_left.mouse_filter = Control.MOUSE_FILTER_IGNORE
        add_child(border_left)
        
        var border_right = ColorRect.new()
        border_right.name = "BorderRight"
        border_right.size = Vector2(4, 720)
        border_right.position = Vector2(1230, 0)
        border_right.color = Color(0.6, 0.4, 0.2, 0.3)
        border_right.mouse_filter = Control.MOUSE_FILTER_IGNORE
        add_child(border_right)

func _add_version_label():
        var existing = get_node_or_null("VersionLabel")
        if existing:
                return
        
        var version = Label.new()
        version.name = "VersionLabel"
        version.text = "v0.1.0 Alpha"
        version.add_theme_font_size_override("font_size", 14)
        version.add_theme_color_override("font_color", Color(0.5, 0.4, 0.3, 0.7))
        version.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
        version.position = Vector2(-120, -30)
        add_child(version)

func _style_buttons():
        var button_style = StyleBoxFlat.new()
        button_style.bg_color = Color(0.12, 0.08, 0.05, 0.95)
        button_style.border_color = Color(0.6, 0.45, 0.25)
        button_style.set_border_width_all(3)
        button_style.set_corner_radius_all(8)
        button_style.set_content_margin_all(16)
        button_style.shadow_color = Color(0, 0, 0, 0.5)
        button_style.shadow_size = 4
        button_style.shadow_offset = Vector2(2, 2)
        
        var hover_style = StyleBoxFlat.new()
        hover_style.bg_color = Color(0.2, 0.14, 0.08, 0.98)
        hover_style.border_color = Color(1.0, 0.75, 0.4)
        hover_style.set_border_width_all(3)
        hover_style.set_corner_radius_all(8)
        hover_style.set_content_margin_all(16)
        hover_style.shadow_color = Color(1.0, 0.6, 0.2, 0.3)
        hover_style.shadow_size = 8
        hover_style.shadow_offset = Vector2(0, 0)
        
        var pressed_style = StyleBoxFlat.new()
        pressed_style.bg_color = Color(0.08, 0.05, 0.03, 0.98)
        pressed_style.border_color = Color(0.5, 0.35, 0.2)
        pressed_style.set_border_width_all(3)
        pressed_style.set_corner_radius_all(8)
        pressed_style.set_content_margin_all(16)
        
        for button in main_buttons.get_children():
                if button is Button:
                        button.add_theme_stylebox_override("normal", button_style.duplicate())
                        button.add_theme_stylebox_override("hover", hover_style.duplicate())
                        button.add_theme_stylebox_override("pressed", pressed_style.duplicate())
                        button.add_theme_color_override("font_color", Color(0.95, 0.88, 0.75))
                        button.add_theme_color_override("font_hover_color", Color(1.0, 0.95, 0.8))
                        button.add_theme_font_size_override("font_size", 22)
                        button.custom_minimum_size = Vector2(280, 55)
                        
                        button.mouse_entered.connect(_on_button_hover.bind(button))
                        button.mouse_exited.connect(_on_button_unhover.bind(button))

func _on_button_hover(button: Button):
        var tween = create_tween()
        tween.tween_property(button, "scale", Vector2(1.05, 1.05), 0.15).set_ease(Tween.EASE_OUT)

func _on_button_unhover(button: Button):
        var tween = create_tween()
        tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.15).set_ease(Tween.EASE_OUT)

var original_positions := {}

func _animate_menu_entrance():
        if menu_tween and menu_tween.is_running():
                menu_tween.kill()
        
        if original_positions.is_empty():
                for child in main_buttons.get_children():
                        original_positions[child.get_instance_id()] = child.position.x
        
        menu_tween = create_tween()
        menu_tween.set_ease(Tween.EASE_OUT)
        menu_tween.set_trans(Tween.TRANS_BACK)
        
        var delay = 0.0
        for child in main_buttons.get_children():
                var orig_x = original_positions.get(child.get_instance_id(), child.position.x)
                child.modulate.a = 0.0
                child.position.x = orig_x - 50
                
                menu_tween.parallel().tween_property(child, "modulate:a", 1.0, 0.4).set_delay(delay)
                menu_tween.parallel().tween_property(child, "position:x", orig_x, 0.4).set_delay(delay)
                delay += 0.08

func _setup_language_options():
        lang_option.clear()
        lang_option.add_item("English", 0)
        lang_option.add_item("Русский", 1)
        var gm = get_node_or_null("/root/GameManager")
        if gm:
                var lang = gm.get_language()
                if lang == "ru":
                        lang_option.select(1)
                else:
                        lang_option.select(0)

func _load_settings():
        var gm = get_node_or_null("/root/GameManager")
        if gm:
                var lang = gm.get_language()
                _update_ui_language(lang)
                if gm.get("mouse_sensitivity") != null:
                        current_sensitivity = gm.mouse_sensitivity
                        sens_slider.value = current_sensitivity
                        sens_value.text = str(snapped(current_sensitivity, 0.01))

func _on_sens_changed(value: float):
        current_sensitivity = value
        sens_value.text = str(snapped(value, 0.01))

func _update_ui_language(lang: String):
        if lang == "ru":
                $VBoxContainer/StartButton.text = "Начать игру"
                $VBoxContainer/MultiplayerButton.text = "Мультиплеер"
                $VBoxContainer/SettingsButton.text = "Настройки"
                $VBoxContainer/QuitButton.text = "Выход"
                $MultiplayerPanel/VBox/Title.text = "Мультиплеер"
                $MultiplayerPanel/VBox/HostButton.text = "Создать сервер"
                $MultiplayerPanel/VBox/JoinButton.text = "Подключиться"
                $MultiplayerPanel/VBox/BackButton.text = "Назад"
                $SettingsPanel/VBox/Title.text = "Настройки"
                $SettingsPanel/VBox/LangLabel.text = "Язык:"
                $SettingsPanel/VBox/SensLabel.text = "Чувствительность мыши:"
                $SettingsPanel/VBox/BackButton.text = "Назад"
        else:
                $VBoxContainer/StartButton.text = "Start Game"
                $VBoxContainer/MultiplayerButton.text = "Multiplayer"
                $VBoxContainer/SettingsButton.text = "Settings"
                $VBoxContainer/QuitButton.text = "Quit"
                $MultiplayerPanel/VBox/Title.text = "Multiplayer"
                $MultiplayerPanel/VBox/HostButton.text = "Host Server"
                $MultiplayerPanel/VBox/JoinButton.text = "Join Server"
                $MultiplayerPanel/VBox/BackButton.text = "Back"
                $SettingsPanel/VBox/Title.text = "Settings"
                $SettingsPanel/VBox/LangLabel.text = "Language:"
                $SettingsPanel/VBox/SensLabel.text = "Mouse Sensitivity:"
                $SettingsPanel/VBox/BackButton.text = "Back"

func _on_start_pressed():
        _save_settings()
        var gm = get_node_or_null("/root/GameManager")
        if gm and not gm.has_character_created():
                get_tree().change_scene_to_file("res://scenes/ui/character_creation.tscn")
        else:
                get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_multiplayer_pressed():
        main_buttons.visible = false
        multiplayer_panel.visible = true

var settings_instance = null

func _on_settings_pressed():
        if settings_instance and is_instance_valid(settings_instance):
                settings_instance.queue_free()
        
        var settings_scene = load("res://scenes/ui/settings_menu.tscn")
        if settings_scene:
                settings_instance = settings_scene.instantiate()
                add_child(settings_instance)
                main_buttons.visible = false
        else:
                settings_panel.visible = true
                main_buttons.visible = false

func show_main_buttons():
        main_buttons.visible = true
        if settings_instance and is_instance_valid(settings_instance):
                settings_instance.queue_free()
                settings_instance = null

func _on_quit_pressed():
        get_tree().quit()

func _on_host_pressed():
        _save_settings()
        var net = get_node_or_null("/root/Network")
        if net:
                net.host(7777)
        get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_join_pressed():
        _save_settings()
        var ip = ip_input.text if ip_input.text != "" else "127.0.0.1"
        var net = get_node_or_null("/root/Network")
        if net:
                net.join(ip, 7777)
        get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_mp_back_pressed():
        multiplayer_panel.visible = false
        main_buttons.visible = true

func _on_settings_back_pressed():
        _save_settings()
        settings_panel.visible = false
        main_buttons.visible = true

func _on_load_pressed():
        main_buttons.visible = false
        saves_panel.visible = true
        _refresh_save_slots()

func _on_saves_back_pressed():
        saves_panel.visible = false
        main_buttons.visible = true

func _refresh_save_slots():
        for child in slot_container.get_children():
                child.queue_free()
        
        var save_mgr = get_node_or_null("/root/SaveManager")
        if not save_mgr:
                var lbl = Label.new()
                lbl.text = "Система сохранений недоступна"
                lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
                slot_container.add_child(lbl)
                return
        
        var slots = save_mgr.get_save_slots()
        
        if slots.size() == 0:
                var lbl = Label.new()
                lbl.text = "Нет сохранений"
                lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
                slot_container.add_child(lbl)
                return
        
        for slot in slots:
                var slot_panel = _create_save_slot_ui(slot)
                slot_container.add_child(slot_panel)

func _create_save_slot_ui(slot: Dictionary) -> Control:
        var panel = PanelContainer.new()
        panel.custom_minimum_size = Vector2(0, 60)
        
        var hbox = HBoxContainer.new()
        hbox.add_theme_constant_override("separation", 10)
        panel.add_child(hbox)
        
        var info_vbox = VBoxContainer.new()
        info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        hbox.add_child(info_vbox)
        
        var name_label = Label.new()
        name_label.text = slot["name"]
        if slot.get("is_autosave", false):
                name_label.text += " (авто)"
        name_label.add_theme_font_size_override("font_size", 18)
        info_vbox.add_child(name_label)
        
        var date_label = Label.new()
        var save_mgr = get_node_or_null("/root/SaveManager")
        if save_mgr:
                date_label.text = save_mgr.get_formatted_date(slot.get("timestamp", 0))
        else:
                date_label.text = slot.get("date", "")
        date_label.add_theme_font_size_override("font_size", 14)
        date_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
        info_vbox.add_child(date_label)
        
        var level_label = Label.new()
        level_label.text = "Уровень: %d" % slot.get("level", 1)
        level_label.add_theme_font_size_override("font_size", 14)
        hbox.add_child(level_label)
        
        var load_btn = Button.new()
        load_btn.text = "Загрузить"
        load_btn.custom_minimum_size = Vector2(100, 0)
        load_btn.pressed.connect(_on_slot_load_pressed.bind(slot["name"]))
        hbox.add_child(load_btn)
        
        var delete_btn = Button.new()
        delete_btn.text = "Удалить"
        delete_btn.custom_minimum_size = Vector2(80, 0)
        delete_btn.pressed.connect(_on_slot_delete_pressed.bind(slot["name"]))
        hbox.add_child(delete_btn)
        
        return panel

func _on_slot_load_pressed(slot_name: String):
        var save_mgr = get_node_or_null("/root/SaveManager")
        if save_mgr:
                selected_save_slot = slot_name
                get_tree().change_scene_to_file("res://scenes/main.tscn")
                await get_tree().create_timer(0.5).timeout
                save_mgr.load_game(slot_name)

func _on_slot_delete_pressed(slot_name: String):
        var save_mgr = get_node_or_null("/root/SaveManager")
        if save_mgr:
                save_mgr.delete_save(slot_name)
                _refresh_save_slots()

func _save_settings():
        var gm = get_node_or_null("/root/GameManager")
        if gm:
                var lang = "en" if lang_option.selected == 0 else "ru"
                gm.set_language(lang)
                gm.mouse_sensitivity = current_sensitivity
                _update_ui_language(lang)
