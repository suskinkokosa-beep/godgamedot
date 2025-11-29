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

var settings_manager = null

func _ready():
        settings_manager = get_node_or_null("/root/SettingsManager")
        _setup_ui()
        _load_current_settings()

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
        hide()
        var main_menu = get_parent().get_node_or_null("MainMenu")
        if main_menu:
                main_menu.show()
