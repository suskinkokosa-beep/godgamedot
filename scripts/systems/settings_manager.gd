extends Node

signal settings_changed

var settings := {
        "graphics": {
                "quality_preset": "medium",
                "resolution_scale": 1.0,
                "vsync": true,
                "fps_limit": 60,
                "fullscreen": false,
                "shadows_enabled": true,
                "shadow_quality": 1,
                "bloom_enabled": true,
                "antialiasing": 0,
                "view_distance": 100.0,
                "grass_density": 0.5,
                "texture_quality": 1,
                "fog_enabled": true,
                "fog_density": 0.002
        },
        "audio": {
                "master_volume": 1.0,
                "music_volume": 0.7,
                "sfx_volume": 1.0,
                "ambient_volume": 0.5
        },
        "controls": {
                "mouse_sensitivity": 0.06,
                "invert_y": false,
                "toggle_crouch": false,
                "toggle_sprint": false,
                "fov": 70.0
        },
        "keybinds": {
                "move_forward": "W",
                "move_back": "S",
                "move_left": "A",
                "move_right": "D",
                "jump": "Space",
                "sprint": "Shift",
                "crouch": "Ctrl",
                "interact": "E",
                "inventory": "I",
                "attack": "LMB"
        }
}

const SETTINGS_PATH := "user://settings.cfg"

var quality_presets := {
        "low": {
                "resolution_scale": 0.5,
                "shadows_enabled": false,
                "shadow_quality": 0,
                "bloom_enabled": false,
                "antialiasing": 0,
                "view_distance": 50.0,
                "grass_density": 0.2,
                "texture_quality": 0,
                "fog_enabled": false,
                "fog_density": 0.001
        },
        "medium": {
                "resolution_scale": 0.75,
                "shadows_enabled": true,
                "shadow_quality": 1,
                "bloom_enabled": true,
                "antialiasing": 0,
                "view_distance": 100.0,
                "grass_density": 0.5,
                "texture_quality": 1,
                "fog_enabled": true,
                "fog_density": 0.002
        },
        "high": {
                "resolution_scale": 1.0,
                "shadows_enabled": true,
                "shadow_quality": 2,
                "bloom_enabled": true,
                "antialiasing": 1,
                "view_distance": 150.0,
                "grass_density": 0.8,
                "texture_quality": 2,
                "fog_enabled": true,
                "fog_density": 0.003
        },
        "ultra": {
                "resolution_scale": 1.0,
                "shadows_enabled": true,
                "shadow_quality": 3,
                "bloom_enabled": true,
                "antialiasing": 2,
                "view_distance": 200.0,
                "grass_density": 1.0,
                "texture_quality": 2,
                "fog_enabled": true,
                "fog_density": 0.004
        }
}

func _ready():
        load_settings()
        apply_all_settings()

func load_settings():
        var config = ConfigFile.new()
        var err = config.load(SETTINGS_PATH)
        if err != OK:
                save_settings()
                return
        
        for section in settings.keys():
                for key in settings[section].keys():
                        if config.has_section_key(section, key):
                                settings[section][key] = config.get_value(section, key)

func save_settings():
        var config = ConfigFile.new()
        for section in settings.keys():
                for key in settings[section].keys():
                        config.set_value(section, key, settings[section][key])
        config.save(SETTINGS_PATH)

func get_setting(section: String, key: String):
        if settings.has(section) and settings[section].has(key):
                return settings[section][key]
        return null

func set_setting(section: String, key: String, value):
        if settings.has(section):
                settings[section][key] = value
                emit_signal("settings_changed")

func apply_quality_preset(preset_name: String):
        if not quality_presets.has(preset_name):
                return
        
        var preset = quality_presets[preset_name]
        settings["graphics"]["quality_preset"] = preset_name
        
        for key in preset.keys():
                settings["graphics"][key] = preset[key]
        
        apply_graphics_settings()
        save_settings()
        emit_signal("settings_changed")

func apply_all_settings():
        apply_graphics_settings()
        apply_audio_settings()
        apply_control_settings()

func apply_graphics_settings():
        var gfx = settings["graphics"]
        
        if gfx["vsync"]:
                DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
        else:
                DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
        
        if gfx["fullscreen"]:
                DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
        else:
                DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
        
        Engine.max_fps = gfx["fps_limit"] if gfx["fps_limit"] > 0 else 0
        
        var vp = get_viewport()
        if vp:
                vp.scaling_3d_scale = gfx["resolution_scale"]
                
                match gfx["antialiasing"]:
                        0:
                                vp.msaa_3d = Viewport.MSAA_DISABLED
                        1:
                                vp.msaa_3d = Viewport.MSAA_2X
                        2:
                                vp.msaa_3d = Viewport.MSAA_4X
                        3:
                                vp.msaa_3d = Viewport.MSAA_8X
        
        var env = _get_world_environment()
        if env and env.environment:
                env.environment.glow_enabled = gfx["bloom_enabled"]
                env.environment.fog_enabled = gfx.get("fog_enabled", true)
                env.environment.fog_density = gfx.get("fog_density", 0.002)
                env.environment.adjustment_enabled = true

func apply_audio_settings():
        var audio = settings["audio"]
        
        var master_idx = AudioServer.get_bus_index("Master")
        if master_idx >= 0:
                AudioServer.set_bus_volume_db(master_idx, linear_to_db(audio["master_volume"]))
        
        var music_idx = AudioServer.get_bus_index("Music")
        if music_idx >= 0:
                AudioServer.set_bus_volume_db(music_idx, linear_to_db(audio["music_volume"]))
        
        var sfx_idx = AudioServer.get_bus_index("SFX")
        if sfx_idx >= 0:
                AudioServer.set_bus_volume_db(sfx_idx, linear_to_db(audio["sfx_volume"]))

func apply_control_settings():
        var controls = settings["controls"]
        
        var gm = get_node_or_null("/root/GameManager")
        if gm:
                gm.mouse_sensitivity = controls["mouse_sensitivity"]
        
        for player in get_tree().get_nodes_in_group("players"):
                if player.has_method("set_mouse_sensitivity"):
                        player.set_mouse_sensitivity(controls["mouse_sensitivity"])
                if player.has_method("set_fov") and player.camera:
                        player.camera.fov = controls["fov"]

func _get_world_environment() -> WorldEnvironment:
        var root = get_tree().current_scene
        if root:
                var env = root.find_child("WorldEnvironment", true, false)
                if env is WorldEnvironment:
                        return env
        return null

func get_graphics_info() -> Dictionary:
        return {
                "renderer": RenderingServer.get_video_adapter_name(),
                "api": RenderingServer.get_video_adapter_api_version()
        }

func estimate_performance() -> String:
        var gfx = settings["graphics"]
        var score = 0
        
        score += int(gfx["resolution_scale"] * 3)
        score += 1 if gfx["shadows_enabled"] else 0
        score += gfx["shadow_quality"]
        score += 2 if gfx["ssao_enabled"] else 0
        score += 1 if gfx["bloom_enabled"] else 0
        score += gfx["antialiasing"]
        score += int(gfx["view_distance"] / 50)
        
        if score <= 3:
                return "Отлично для слабых ПК"
        elif score <= 6:
                return "Хорошо для средних ПК"
        elif score <= 10:
                return "Требует мощный ПК"
        else:
                return "Очень требовательно"
