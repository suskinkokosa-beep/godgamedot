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
        var bg = ColorRect.new()
        bg.name = "BackgroundOverlay"
        bg.color = Color(0.08, 0.06, 0.05, 0.95)
        bg.set_anchors_preset(Control.PRESET_FULL_RECT)
        bg.z_index = -10
        add_child(bg)
        move_child(bg, 0)
        
        var title_label = get_node_or_null("VBoxContainer/TitleLabel")
        if not title_label:
                title_label = Label.new()
                title_label.name = "TitleLabel"
                title_label.text = "EPOCH SETTLEMENTS"
                title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
                title_label.add_theme_font_size_override("font_size", 48)
                title_label.add_theme_color_override("font_color", Color(0.9, 0.7, 0.4))
                title_label.add_theme_color_override("font_shadow_color", Color(0.2, 0.1, 0.05, 0.8))
                title_label.add_theme_constant_override("shadow_offset_x", 3)
                title_label.add_theme_constant_override("shadow_offset_y", 3)
                main_buttons.add_child(title_label)
                main_buttons.move_child(title_label, 0)
        
        var subtitle = Label.new()
        subtitle.name = "SubtitleLabel"
        subtitle.text = "Alpha v0.1"
        subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        subtitle.add_theme_font_size_override("font_size", 16)
        subtitle.add_theme_color_override("font_color", Color(0.6, 0.5, 0.4))
        main_buttons.add_child(subtitle)
        main_buttons.move_child(subtitle, 1)
        
        var spacer = Control.new()
        spacer.custom_minimum_size = Vector2(0, 40)
        main_buttons.add_child(spacer)
        main_buttons.move_child(spacer, 2)
        
        _style_buttons()

func _style_buttons():
        var button_style = StyleBoxFlat.new()
        button_style.bg_color = Color(0.2, 0.15, 0.1, 0.9)
        button_style.border_color = Color(0.5, 0.35, 0.2)
        button_style.set_border_width_all(2)
        button_style.set_corner_radius_all(4)
        button_style.set_content_margin_all(12)
        
        var hover_style = StyleBoxFlat.new()
        hover_style.bg_color = Color(0.3, 0.2, 0.15, 0.95)
        hover_style.border_color = Color(0.7, 0.5, 0.3)
        hover_style.set_border_width_all(2)
        hover_style.set_corner_radius_all(4)
        hover_style.set_content_margin_all(12)
        
        var pressed_style = StyleBoxFlat.new()
        pressed_style.bg_color = Color(0.15, 0.1, 0.08, 0.95)
        pressed_style.border_color = Color(0.4, 0.3, 0.2)
        pressed_style.set_border_width_all(2)
        pressed_style.set_corner_radius_all(4)
        pressed_style.set_content_margin_all(12)
        
        for button in main_buttons.get_children():
                if button is Button:
                        button.add_theme_stylebox_override("normal", button_style)
                        button.add_theme_stylebox_override("hover", hover_style)
                        button.add_theme_stylebox_override("pressed", pressed_style)
                        button.add_theme_color_override("font_color", Color(0.9, 0.85, 0.75))
                        button.add_theme_color_override("font_hover_color", Color(1.0, 0.9, 0.7))
                        button.add_theme_font_size_override("font_size", 20)
                        button.custom_minimum_size = Vector2(250, 50)

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
