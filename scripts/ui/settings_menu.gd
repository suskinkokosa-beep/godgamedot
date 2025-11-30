extends Control

@onready var quality_dropdown = $VBoxContainer/TabContainer/Графика/ScrollContainer/VBoxContainer/QualityRow/QualityDropdown
@onready var resolution_slider = $VBoxContainer/TabContainer/Графика/ScrollContainer/VBoxContainer/ResolutionRow/ResolutionSlider
@onready var resolution_label = $VBoxContainer/TabContainer/Графика/ScrollContainer/VBoxContainer/ResolutionRow/ResolutionValue
@onready var vsync_check = $VBoxContainer/TabContainer/Графика/ScrollContainer/VBoxContainer/VsyncRow/VsyncCheck
@onready var fps_dropdown = $VBoxContainer/TabContainer/Графика/ScrollContainer/VBoxContainer/FPSRow/FPSDropdown
@onready var shadows_check = $VBoxContainer/TabContainer/Графика/ScrollContainer/VBoxContainer/ShadowsRow/ShadowsCheck
@onready var shadow_quality_dropdown = $VBoxContainer/TabContainer/Графика/ScrollContainer/VBoxContainer/ShadowQualityRow/ShadowQualityDropdown
@onready var bloom_check = $VBoxContainer/TabContainer/Графика/ScrollContainer/VBoxContainer/BloomRow/BloomCheck
@onready var fog_check = $VBoxContainer/TabContainer/Графика/ScrollContainer/VBoxContainer/FogRow/FogCheck
@onready var aa_dropdown = $VBoxContainer/TabContainer/Графика/ScrollContainer/VBoxContainer/AARow/AADropdown
@onready var view_distance_slider = $VBoxContainer/TabContainer/Графика/ScrollContainer/VBoxContainer/ViewDistanceRow/ViewDistanceSlider
@onready var view_distance_label = $VBoxContainer/TabContainer/Графика/ScrollContainer/VBoxContainer/ViewDistanceRow/ViewDistanceValue
@onready var performance_label = $VBoxContainer/TabContainer/Графика/ScrollContainer/VBoxContainer/PerformanceRow/PerformanceLabel

@onready var sensitivity_slider = $VBoxContainer/TabContainer/Управление/ScrollContainer/VBoxContainer/SensitivityRow/SensitivitySlider
@onready var sensitivity_label = $VBoxContainer/TabContainer/Управление/ScrollContainer/VBoxContainer/SensitivityRow/SensitivityValue
@onready var fov_slider = $VBoxContainer/TabContainer/Управление/ScrollContainer/VBoxContainer/FOVRow/FOVSlider
@onready var fov_label = $VBoxContainer/TabContainer/Управление/ScrollContainer/VBoxContainer/FOVRow/FOVValue
@onready var invert_y_check = $VBoxContainer/TabContainer/Управление/ScrollContainer/VBoxContainer/InvertYRow/InvertYCheck

@onready var master_slider = $VBoxContainer/TabContainer/Звук/ScrollContainer/VBoxContainer/MasterRow/MasterSlider
@onready var master_label = $VBoxContainer/TabContainer/Звук/ScrollContainer/VBoxContainer/MasterRow/MasterValue
@onready var music_slider = $VBoxContainer/TabContainer/Звук/ScrollContainer/VBoxContainer/MusicRow/MusicSlider
@onready var music_label = $VBoxContainer/TabContainer/Звук/ScrollContainer/VBoxContainer/MusicRow/MusicValue
@onready var sfx_slider = $VBoxContainer/TabContainer/Звук/ScrollContainer/VBoxContainer/SFXRow/SFXSlider
@onready var sfx_label = $VBoxContainer/TabContainer/Звук/ScrollContainer/VBoxContainer/SFXRow/SFXValue

@onready var language_dropdown = $VBoxContainer/TabContainer/Язык/ScrollContainer/VBoxContainer/LanguageRow/LanguageDropdown

@onready var keybind_buttons := {
        "forward": $"VBoxContainer/TabContainer/Управление/ScrollContainer/VBoxContainer/KeybindForward/Button",
        "back": $"VBoxContainer/TabContainer/Управление/ScrollContainer/VBoxContainer/KeybindBack/Button",
        "left": $"VBoxContainer/TabContainer/Управление/ScrollContainer/VBoxContainer/KeybindLeft/Button",
        "right": $"VBoxContainer/TabContainer/Управление/ScrollContainer/VBoxContainer/KeybindRight/Button",
        "jump": $"VBoxContainer/TabContainer/Управление/ScrollContainer/VBoxContainer/KeybindJump/Button",
        "sprint": $"VBoxContainer/TabContainer/Управление/ScrollContainer/VBoxContainer/KeybindSprint/Button",
        "crouch": $"VBoxContainer/TabContainer/Управление/ScrollContainer/VBoxContainer/KeybindCrouch/Button",
        "interact": $"VBoxContainer/TabContainer/Управление/ScrollContainer/VBoxContainer/KeybindInteract/Button",
        "inventory": $"VBoxContainer/TabContainer/Управление/ScrollContainer/VBoxContainer/KeybindInventory/Button",
        "attack": $"VBoxContainer/TabContainer/Управление/ScrollContainer/VBoxContainer/KeybindAttack/Button"
}

@onready var reset_keybinds_btn = $"VBoxContainer/TabContainer/Управление/ScrollContainer/VBoxContainer/ResetKeybinds"

var settings_manager = null
var waiting_for_key: String = ""
var current_keybinds := {
        "forward": KEY_W,
        "back": KEY_S,
        "left": KEY_A,
        "right": KEY_D,
        "jump": KEY_SPACE,
        "sprint": KEY_SHIFT,
        "crouch": KEY_CTRL,
        "interact": KEY_E,
        "inventory": KEY_I,
        "attack": MOUSE_BUTTON_LEFT
}

var key_names := {
        KEY_W: "W", KEY_A: "A", KEY_S: "S", KEY_D: "D",
        KEY_E: "E", KEY_F: "F", KEY_G: "G", KEY_H: "H",
        KEY_I: "I", KEY_J: "J", KEY_K: "K", KEY_L: "L",
        KEY_M: "M", KEY_N: "N", KEY_O: "O", KEY_P: "P",
        KEY_Q: "Q", KEY_R: "R", KEY_T: "T", KEY_U: "U",
        KEY_V: "V", KEY_X: "X", KEY_Y: "Y", KEY_Z: "Z",
        KEY_SPACE: "Пробел", KEY_SHIFT: "Shift", KEY_CTRL: "Ctrl",
        KEY_ALT: "Alt", KEY_TAB: "Tab", KEY_ESCAPE: "Esc",
        KEY_1: "1", KEY_2: "2", KEY_3: "3", KEY_4: "4",
        KEY_5: "5", KEY_6: "6", KEY_7: "7", KEY_8: "8",
        KEY_9: "9", KEY_0: "0",
        MOUSE_BUTTON_LEFT: "ЛКМ", MOUSE_BUTTON_RIGHT: "ПКМ", MOUSE_BUTTON_MIDDLE: "СКМ"
}

func _ready():
        settings_manager = get_node_or_null("/root/SettingsManager")
        _setup_ui()
        _setup_keybinds()
        _setup_language()
        _load_current_settings()

func _input(event: InputEvent):
        if waiting_for_key == "":
                return
        
        var new_key = -1
        if event is InputEventKey and event.pressed:
                new_key = event.keycode
        elif event is InputEventMouseButton and event.pressed:
                new_key = event.button_index
        
        if new_key != -1:
                current_keybinds[waiting_for_key] = new_key
                _apply_keybinds()
                _update_keybind_buttons()
                waiting_for_key = ""
                get_viewport().set_input_as_handled()

func _setup_keybinds():
        for action in keybind_buttons.keys():
                var btn = keybind_buttons[action]
                if btn:
                        btn.connect("pressed", _on_keybind_pressed.bind(action))
        
        if reset_keybinds_btn:
                reset_keybinds_btn.connect("pressed", _on_reset_keybinds)
        
        _update_keybind_buttons()

func _update_keybind_buttons():
        for action in keybind_buttons.keys():
                var btn = keybind_buttons[action]
                if btn:
                        var key = current_keybinds.get(action, -1)
                        if waiting_for_key == action:
                                btn.text = "..."
                        elif key_names.has(key):
                                btn.text = key_names[key]
                        else:
                                btn.text = "?"

func _on_keybind_pressed(action: String):
        waiting_for_key = action
        _update_keybind_buttons()

func _on_reset_keybinds():
        current_keybinds = {
                "forward": KEY_W,
                "back": KEY_S,
                "left": KEY_A,
                "right": KEY_D,
                "jump": KEY_SPACE,
                "sprint": KEY_SHIFT,
                "crouch": KEY_CTRL,
                "interact": KEY_E,
                "inventory": KEY_I,
                "attack": MOUSE_BUTTON_LEFT
        }
        _apply_keybinds()
        _update_keybind_buttons()

func _apply_keybinds():
        var action_map := {
                "forward": "move_forward",
                "back": "move_back",
                "left": "move_left",
                "right": "move_right",
                "jump": "jump",
                "sprint": "sprint",
                "crouch": "crouch",
                "interact": "interact",
                "inventory": "inventory",
                "attack": "attack"
        }
        
        for keybind_name in current_keybinds.keys():
                var action_name = action_map.get(keybind_name, keybind_name)
                var key_code = current_keybinds[keybind_name]
                
                if not InputMap.has_action(action_name):
                        continue
                
                InputMap.action_erase_events(action_name)
                
                var event: InputEvent
                if key_code >= MOUSE_BUTTON_LEFT and key_code <= MOUSE_BUTTON_XBUTTON2:
                        event = InputEventMouseButton.new()
                        event.button_index = key_code
                else:
                        event = InputEventKey.new()
                        event.keycode = key_code
                
                InputMap.action_add_event(action_name, event)
        
        if settings_manager:
                settings_manager.set_setting("controls", "keybinds", current_keybinds)
                settings_manager.save_settings()

func _setup_language():
        if language_dropdown:
                language_dropdown.clear()
                language_dropdown.add_item("Русский", 0)
                language_dropdown.add_item("English", 1)
                language_dropdown.connect("item_selected", _on_language_changed)
                
                var saved_lang = "ru"
                if settings_manager and settings_manager.settings.has("game"):
                        saved_lang = settings_manager.settings["game"].get("language", "ru")
                
                if saved_lang == "en":
                        language_dropdown.select(1)
                        TranslationServer.set_locale("en")
                else:
                        language_dropdown.select(0)
                        TranslationServer.set_locale("ru")

func _on_language_changed(idx: int):
        var locales = ["ru", "en"]
        if idx >= 0 and idx < locales.size():
                var new_locale = locales[idx]
                TranslationServer.set_locale(new_locale)
                
                var loc_service = get_node_or_null("/root/LocalizationService")
                if loc_service and loc_service.has_method("set_language"):
                        loc_service.set_language(new_locale)
                
                if settings_manager:
                        if not settings_manager.settings.has("game"):
                                settings_manager.settings["game"] = {}
                        settings_manager.settings["game"]["language"] = new_locale
                        settings_manager.save_settings()

func _setup_ui():
        if quality_dropdown:
                quality_dropdown.clear()
                quality_dropdown.add_item("Низкое", 0)
                quality_dropdown.add_item("Среднее", 1)
                quality_dropdown.add_item("Высокое", 2)
                quality_dropdown.add_item("Ультра", 3)
                quality_dropdown.connect("item_selected", _on_quality_changed)
        
        if fps_dropdown:
                fps_dropdown.clear()
                fps_dropdown.add_item("30", 0)
                fps_dropdown.add_item("60", 1)
                fps_dropdown.add_item("90", 2)
                fps_dropdown.add_item("120", 3)
                fps_dropdown.add_item("Без лимита", 4)
                fps_dropdown.connect("item_selected", _on_fps_changed)
        
        if shadow_quality_dropdown:
                shadow_quality_dropdown.clear()
                shadow_quality_dropdown.add_item("Низкое", 0)
                shadow_quality_dropdown.add_item("Среднее", 1)
                shadow_quality_dropdown.add_item("Высокое", 2)
                shadow_quality_dropdown.add_item("Ультра", 3)
                shadow_quality_dropdown.connect("item_selected", _on_shadow_quality_changed)
        
        if aa_dropdown:
                aa_dropdown.clear()
                aa_dropdown.add_item("Выкл", 0)
                aa_dropdown.add_item("MSAA 2x", 1)
                aa_dropdown.add_item("MSAA 4x", 2)
                aa_dropdown.add_item("MSAA 8x", 3)
                aa_dropdown.connect("item_selected", _on_aa_changed)
        
        if resolution_slider:
                resolution_slider.min_value = 0.25
                resolution_slider.max_value = 1.0
                resolution_slider.step = 0.05
                resolution_slider.connect("value_changed", _on_resolution_changed)
        
        if view_distance_slider:
                view_distance_slider.min_value = 25
                view_distance_slider.max_value = 300
                view_distance_slider.step = 25
                view_distance_slider.connect("value_changed", _on_view_distance_changed)
        
        if sensitivity_slider:
                sensitivity_slider.min_value = 0.01
                sensitivity_slider.max_value = 0.2
                sensitivity_slider.step = 0.01
                sensitivity_slider.connect("value_changed", _on_sensitivity_changed)
        
        if fov_slider:
                fov_slider.min_value = 50
                fov_slider.max_value = 110
                fov_slider.step = 5
                fov_slider.connect("value_changed", _on_fov_changed)
        
        if master_slider:
                master_slider.min_value = 0
                master_slider.max_value = 1.0
                master_slider.step = 0.05
                master_slider.connect("value_changed", _on_master_volume_changed)
        
        if music_slider:
                music_slider.min_value = 0
                music_slider.max_value = 1.0
                music_slider.step = 0.05
                music_slider.connect("value_changed", _on_music_volume_changed)
        
        if sfx_slider:
                sfx_slider.min_value = 0
                sfx_slider.max_value = 1.0
                sfx_slider.step = 0.05
                sfx_slider.connect("value_changed", _on_sfx_volume_changed)
        
        _connect_checkboxes()

func _connect_checkboxes():
        if vsync_check:
                vsync_check.connect("toggled", _on_vsync_toggled)
        if shadows_check:
                shadows_check.connect("toggled", _on_shadows_toggled)
        if bloom_check:
                bloom_check.connect("toggled", _on_bloom_toggled)
        if fog_check:
                fog_check.connect("toggled", _on_fog_toggled)
        if invert_y_check:
                invert_y_check.connect("toggled", _on_invert_y_toggled)

func _load_current_settings():
        if not settings_manager:
                _load_default_settings()
                return
        
        if not settings_manager.settings.has("graphics") or not settings_manager.settings.has("controls") or not settings_manager.settings.has("audio"):
                _load_default_settings()
                return
        
        var gfx = settings_manager.settings["graphics"]
        var controls = settings_manager.settings["controls"]
        var audio = settings_manager.settings["audio"]
        
        if quality_dropdown:
                var presets = ["low", "medium", "high", "ultra"]
                var idx = presets.find(gfx["quality_preset"])
                if idx >= 0:
                        quality_dropdown.select(idx)
        
        if resolution_slider:
                resolution_slider.value = gfx["resolution_scale"]
                _update_resolution_label(gfx["resolution_scale"])
        
        if vsync_check:
                vsync_check.button_pressed = gfx["vsync"]
        
        if fps_dropdown:
                var fps_values = [30, 60, 90, 120, 0]
                var idx = fps_values.find(gfx["fps_limit"])
                if idx >= 0:
                        fps_dropdown.select(idx)
        
        if shadows_check:
                shadows_check.button_pressed = gfx["shadows_enabled"]
        
        if shadow_quality_dropdown:
                shadow_quality_dropdown.select(gfx["shadow_quality"])
        
        if bloom_check:
                bloom_check.button_pressed = gfx["bloom_enabled"]
        
        if fog_check:
                fog_check.button_pressed = gfx.get("fog_enabled", true)
        
        if aa_dropdown:
                aa_dropdown.select(gfx["antialiasing"])
        
        if view_distance_slider:
                view_distance_slider.value = gfx["view_distance"]
                _update_view_distance_label(gfx["view_distance"])
        
        if sensitivity_slider:
                sensitivity_slider.value = controls["mouse_sensitivity"]
                _update_sensitivity_label(controls["mouse_sensitivity"])
        
        if fov_slider:
                fov_slider.value = controls["fov"]
                _update_fov_label(controls["fov"])
        
        if invert_y_check:
                invert_y_check.button_pressed = controls["invert_y"]
        
        if master_slider:
                master_slider.value = audio["master_volume"]
                _update_master_label(audio["master_volume"])
        
        if music_slider:
                music_slider.value = audio["music_volume"]
                _update_music_label(audio["music_volume"])
        
        if sfx_slider:
                sfx_slider.value = audio["sfx_volume"]
                _update_sfx_label(audio["sfx_volume"])
        
        _update_performance_label()

func _update_resolution_label(value: float):
        if resolution_label:
                resolution_label.text = "%d%%" % int(value * 100)

func _update_view_distance_label(value: float):
        if view_distance_label:
                view_distance_label.text = "%d м" % int(value)

func _update_sensitivity_label(value: float):
        if sensitivity_label:
                sensitivity_label.text = "%.2f" % value

func _update_fov_label(value: float):
        if fov_label:
                fov_label.text = "%d°" % int(value)

func _update_master_label(value: float):
        if master_label:
                master_label.text = "%d%%" % int(value * 100)

func _update_music_label(value: float):
        if music_label:
                music_label.text = "%d%%" % int(value * 100)

func _update_sfx_label(value: float):
        if sfx_label:
                sfx_label.text = "%d%%" % int(value * 100)

func _update_performance_label():
        if performance_label and settings_manager:
                performance_label.text = settings_manager.estimate_performance()

func _on_quality_changed(idx: int):
        var presets = ["low", "medium", "high", "ultra"]
        if idx >= 0 and idx < presets.size() and settings_manager:
                settings_manager.apply_quality_preset(presets[idx])
                _load_current_settings()

func _on_resolution_changed(value: float):
        _update_resolution_label(value)
        if settings_manager:
                settings_manager.set_setting("graphics", "resolution_scale", value)
                settings_manager.apply_graphics_settings()
                _update_performance_label()

func _on_fps_changed(idx: int):
        var fps_values = [30, 60, 90, 120, 0]
        if idx >= 0 and idx < fps_values.size() and settings_manager:
                settings_manager.set_setting("graphics", "fps_limit", fps_values[idx])
                settings_manager.apply_graphics_settings()

func _on_vsync_toggled(pressed: bool):
        if settings_manager:
                settings_manager.set_setting("graphics", "vsync", pressed)
                settings_manager.apply_graphics_settings()

func _on_shadows_toggled(pressed: bool):
        if settings_manager:
                settings_manager.set_setting("graphics", "shadows_enabled", pressed)
                settings_manager.apply_graphics_settings()
                _update_performance_label()

func _on_shadow_quality_changed(idx: int):
        if settings_manager:
                settings_manager.set_setting("graphics", "shadow_quality", idx)
                settings_manager.apply_graphics_settings()
                _update_performance_label()

func _on_bloom_toggled(pressed: bool):
        if settings_manager:
                settings_manager.set_setting("graphics", "bloom_enabled", pressed)
                settings_manager.apply_graphics_settings()

func _on_fog_toggled(pressed: bool):
        if settings_manager:
                settings_manager.set_setting("graphics", "fog_enabled", pressed)
                settings_manager.apply_graphics_settings()

func _on_aa_changed(idx: int):
        if settings_manager:
                settings_manager.set_setting("graphics", "antialiasing", idx)
                settings_manager.apply_graphics_settings()
                _update_performance_label()

func _on_view_distance_changed(value: float):
        _update_view_distance_label(value)
        if settings_manager:
                settings_manager.set_setting("graphics", "view_distance", value)
                _update_performance_label()

func _on_sensitivity_changed(value: float):
        _update_sensitivity_label(value)
        if settings_manager:
                settings_manager.set_setting("controls", "mouse_sensitivity", value)
                settings_manager.apply_control_settings()

func _on_fov_changed(value: float):
        _update_fov_label(value)
        if settings_manager:
                settings_manager.set_setting("controls", "fov", value)
                settings_manager.apply_control_settings()

func _on_invert_y_toggled(pressed: bool):
        if settings_manager:
                settings_manager.set_setting("controls", "invert_y", pressed)

func _on_master_volume_changed(value: float):
        _update_master_label(value)
        if settings_manager:
                settings_manager.set_setting("audio", "master_volume", value)
                settings_manager.apply_audio_settings()

func _on_music_volume_changed(value: float):
        _update_music_label(value)
        if settings_manager:
                settings_manager.set_setting("audio", "music_volume", value)
                settings_manager.apply_audio_settings()

func _on_sfx_volume_changed(value: float):
        _update_sfx_label(value)
        if settings_manager:
                settings_manager.set_setting("audio", "sfx_volume", value)
                settings_manager.apply_audio_settings()

func _on_apply_pressed():
        if settings_manager:
                settings_manager.save_settings()

func _on_back_pressed():
        if settings_manager:
                settings_manager.save_settings()
        
        var main_menu_scene = get_tree().current_scene
        if main_menu_scene and main_menu_scene.has_method("show_main_buttons"):
                main_menu_scene.show_main_buttons()
        elif main_menu_scene:
                var main_buttons = main_menu_scene.get_node_or_null("VBoxContainer")
                if main_buttons:
                        main_buttons.visible = true
        
        queue_free()

func _load_default_settings():
        if quality_dropdown:
                quality_dropdown.select(1)
        
        if resolution_slider:
                resolution_slider.value = 1.0
                _update_resolution_label(1.0)
        
        if vsync_check:
                vsync_check.button_pressed = true
        
        if fps_dropdown:
                fps_dropdown.select(1)
        
        if shadows_check:
                shadows_check.button_pressed = true
        
        if shadow_quality_dropdown:
                shadow_quality_dropdown.select(1)
        
        if bloom_check:
                bloom_check.button_pressed = true
        
        if fog_check:
                fog_check.button_pressed = true
        
        if aa_dropdown:
                aa_dropdown.select(1)
        
        if view_distance_slider:
                view_distance_slider.value = 100
                _update_view_distance_label(100)
        
        if sensitivity_slider:
                sensitivity_slider.value = 0.06
                _update_sensitivity_label(0.06)
        
        if fov_slider:
                fov_slider.value = 70
                _update_fov_label(70)
        
        if invert_y_check:
                invert_y_check.button_pressed = false
        
        if master_slider:
                master_slider.value = 1.0
                _update_master_label(1.0)
        
        if music_slider:
                music_slider.value = 0.7
                _update_music_label(0.7)
        
        if sfx_slider:
                sfx_slider.value = 1.0
                _update_sfx_label(1.0)
        
        if performance_label:
                performance_label.text = "Хорошо для средних ПК"
