extends Node

signal sound_played(sound_name: String)

const SOUND_VOLUMES := {
        "footsteps": -10.0,
        "ui": -5.0,
        "combat": 0.0,
        "ambient": -15.0,
        "pickup": -8.0,
        "building": -5.0,
        "environment": -12.0,
        "weather": -18.0
}

var audio_pools := {}
var master_volume := 1.0
var sfx_volume := 1.0
var music_volume := 0.5

var current_music: AudioStreamPlayer = null
var footstep_timer := 0.0
var footstep_interval := 0.4

var sound_cache := {}

enum SurfaceType { GRASS, STONE, WOOD, SAND, WATER, METAL }

func _ready():
        _create_audio_pools()
        _preload_sounds()

func _create_audio_pools():
        for category in ["footsteps", "ui", "combat", "ambient", "pickup", "building", "environment", "weather"]:
                var pool = []
                for i in range(4):
                        var player = AudioStreamPlayer.new()
                        player.bus = "Master"
                        add_child(player)
                        pool.append(player)
                audio_pools[category] = pool

func _preload_sounds():
        pass

func _get_available_player(category: String) -> AudioStreamPlayer:
        if not audio_pools.has(category):
                return null
        
        for player in audio_pools[category]:
                if not player.playing:
                        return player
        
        return audio_pools[category][0]

func _create_procedural_sound(sound_type: String) -> AudioStreamWAV:
        var stream = AudioStreamWAV.new()
        stream.format = AudioStreamWAV.FORMAT_8_BITS
        stream.mix_rate = 22050
        stream.stereo = false
        
        var samples := PackedByteArray()
        var duration := 0.1
        var sample_count := int(22050 * duration)
        
        match sound_type:
                "click", "ui_click":
                        for i in range(sample_count):
                                var t = float(i) / 22050.0
                                var env = max(0, 1.0 - t * 20.0)
                                var wave = sin(t * 1200.0 * TAU) * env
                                samples.append(int((wave * 0.5 + 0.5) * 255))
                
                "hit", "hit_flesh":
                        for i in range(int(22050 * 0.15)):
                                var t = float(i) / 22050.0
                                var env = max(0, 1.0 - t * 8.0)
                                var noise = randf_range(-1, 1)
                                var wave = noise * env * 0.7
                                samples.append(int((wave * 0.5 + 0.5) * 255))
                
                "swing":
                        for i in range(int(22050 * 0.2)):
                                var t = float(i) / 22050.0
                                var env = sin(t * PI / 0.2)
                                var freq = 200 + t * 800
                                var wave = sin(t * freq * TAU) * env * 0.3
                                wave += randf_range(-0.1, 0.1) * env
                                samples.append(int((wave * 0.5 + 0.5) * 255))
                
                "footstep", "footstep_grass", "footstep_stone":
                        for i in range(int(22050 * 0.08)):
                                var t = float(i) / 22050.0
                                var env = max(0, 1.0 - t * 15.0)
                                var noise = randf_range(-1, 1)
                                var wave = noise * env * 0.4
                                samples.append(int((wave * 0.5 + 0.5) * 255))
                
                "pickup", "pickup_default", "pickup_resource":
                        for i in range(int(22050 * 0.12)):
                                var t = float(i) / 22050.0
                                var env = max(0, 1.0 - t * 10.0)
                                var freq = 600 + t * 400
                                var wave = sin(t * freq * TAU) * env * 0.4
                                samples.append(int((wave * 0.5 + 0.5) * 255))
                
                "success", "ui_success":
                        for i in range(int(22050 * 0.2)):
                                var t = float(i) / 22050.0
                                var env = max(0, 1.0 - t * 6.0)
                                var freq = 400 if t < 0.1 else 600
                                var wave = sin(t * freq * TAU) * env * 0.4
                                samples.append(int((wave * 0.5 + 0.5) * 255))
                
                "error", "ui_error":
                        for i in range(int(22050 * 0.15)):
                                var t = float(i) / 22050.0
                                var env = max(0, 1.0 - t * 8.0)
                                var wave = sin(t * 200 * TAU) * env * 0.5
                                samples.append(int((wave * 0.5 + 0.5) * 255))
                
                "craft", "ui_craft":
                        for i in range(int(22050 * 0.3)):
                                var t = float(i) / 22050.0
                                var env = max(0, 1.0 - t * 4.0)
                                var freq = 300 + sin(t * 30) * 100
                                var wave = sin(t * freq * TAU) * env * 0.35
                                wave += randf_range(-0.1, 0.1) * env * 0.5
                                samples.append(int((wave * 0.5 + 0.5) * 255))
                
                "build_place", "building_place":
                        for i in range(int(22050 * 0.25)):
                                var t = float(i) / 22050.0
                                var env = max(0, 1.0 - t * 5.0)
                                var noise = randf_range(-1, 1)
                                var thump = sin(t * 80 * TAU) * max(0, 1.0 - t * 15.0) * 0.6
                                var wave = (noise * 0.3 + thump) * env
                                samples.append(int((wave * 0.5 + 0.5) * 255))
                
                "build_hammer", "hammer_hit":
                        for i in range(int(22050 * 0.12)):
                                var t = float(i) / 22050.0
                                var env = max(0, 1.0 - t * 12.0)
                                var freq = 400 + randf_range(-50, 50)
                                var wave = sin(t * freq * TAU) * env * 0.5
                                wave += randf_range(-0.2, 0.2) * env
                                samples.append(int((wave * 0.5 + 0.5) * 255))
                
                "build_destroy", "destruction":
                        for i in range(int(22050 * 0.4)):
                                var t = float(i) / 22050.0
                                var env = max(0, 1.0 - t * 3.0)
                                var noise = randf_range(-1, 1)
                                var rumble = sin(t * 50 * TAU) * 0.4
                                var wave = (noise * 0.5 + rumble) * env
                                samples.append(int((wave * 0.5 + 0.5) * 255))
                
                "tree_fall":
                        for i in range(int(22050 * 0.8)):
                                var t = float(i) / 22050.0
                                var env = max(0, 1.0 - t * 1.5)
                                var freq = 150 - t * 100
                                var wave = sin(t * freq * TAU) * env * 0.4
                                wave += randf_range(-0.3, 0.3) * env * (1.0 - t)
                                samples.append(int((wave * 0.5 + 0.5) * 255))
                
                "rock_break":
                        for i in range(int(22050 * 0.3)):
                                var t = float(i) / 22050.0
                                var env = max(0, 1.0 - t * 4.0)
                                var noise = randf_range(-1, 1)
                                var crack = sin(t * 800 * TAU) * max(0, 1.0 - t * 20.0)
                                var wave = (noise * 0.4 + crack * 0.3) * env
                                samples.append(int((wave * 0.5 + 0.5) * 255))
                
                "water_splash":
                        for i in range(int(22050 * 0.3)):
                                var t = float(i) / 22050.0
                                var env = max(0, 1.0 - t * 4.0)
                                var noise = randf_range(-1, 1)
                                var bubble = sin(t * (200 + randf_range(0, 100)) * TAU) * 0.2
                                var wave = (noise * 0.3 + bubble) * env
                                samples.append(int((wave * 0.5 + 0.5) * 255))
                
                "fire_crackle":
                        for i in range(int(22050 * 0.15)):
                                var t = float(i) / 22050.0
                                var env = max(0, 1.0 - t * 8.0)
                                var noise = randf_range(-1, 1)
                                var crackle = randf() if randf() > 0.9 else 0.0
                                var wave = (noise * 0.2 + crackle * 0.5) * env
                                samples.append(int((wave * 0.5 + 0.5) * 255))
                
                "wind_gust":
                        for i in range(int(22050 * 0.5)):
                                var t = float(i) / 22050.0
                                var env = sin(t * PI / 0.5) * 0.3
                                var noise = randf_range(-1, 1)
                                var wave = noise * env
                                samples.append(int((wave * 0.5 + 0.5) * 255))
                
                "rain_drop":
                        for i in range(int(22050 * 0.05)):
                                var t = float(i) / 22050.0
                                var env = max(0, 1.0 - t * 25.0)
                                var freq = 1500 + randf_range(-200, 200)
                                var wave = sin(t * freq * TAU) * env * 0.3
                                samples.append(int((wave * 0.5 + 0.5) * 255))
                
                "thunder":
                        for i in range(int(22050 * 1.5)):
                                var t = float(i) / 22050.0
                                var env = max(0, 1.0 - t * 0.8)
                                var rumble = sin(t * 40 * TAU) * 0.5
                                var crack = sin(t * 200 * TAU) * max(0, 1.0 - t * 10.0) * 0.5
                                var noise = randf_range(-0.3, 0.3)
                                var wave = (rumble + crack + noise) * env
                                samples.append(int((wave * 0.5 + 0.5) * 255))
                
                "ambient_forest":
                        for i in range(int(22050 * 0.3)):
                                var t = float(i) / 22050.0
                                var env = sin(t * PI / 0.3) * 0.15
                                var bird = sin(t * (2000 + sin(t * 20) * 500) * TAU) * 0.3
                                var leaves = randf_range(-0.1, 0.1)
                                var wave = (bird * env + leaves)
                                samples.append(int((wave * 0.5 + 0.5) * 255))
                
                "death_sound":
                        for i in range(int(22050 * 0.6)):
                                var t = float(i) / 22050.0
                                var env = max(0, 1.0 - t * 2.0)
                                var freq = 300 - t * 200
                                var wave = sin(t * freq * TAU) * env * 0.5
                                wave += randf_range(-0.2, 0.2) * env
                                samples.append(int((wave * 0.5 + 0.5) * 255))
                
                "level_up":
                        for i in range(int(22050 * 0.5)):
                                var t = float(i) / 22050.0
                                var env = max(0, 1.0 - t * 2.5)
                                var freq1 = 400 + t * 400
                                var freq2 = 600 + t * 600
                                var wave = (sin(t * freq1 * TAU) + sin(t * freq2 * TAU) * 0.5) * env * 0.3
                                samples.append(int((wave * 0.5 + 0.5) * 255))
                
                "quest_complete":
                        for i in range(int(22050 * 0.4)):
                                var t = float(i) / 22050.0
                                var env = max(0, 1.0 - t * 3.0)
                                var n = int(t * 4) 
                                var freqs = [523.25, 659.25, 783.99, 1046.50]
                                var freq = freqs[min(n, 3)]
                                var wave = sin(t * freq * TAU) * env * 0.35
                                samples.append(int((wave * 0.5 + 0.5) * 255))
                
                "achievement":
                        for i in range(int(22050 * 0.6)):
                                var t = float(i) / 22050.0
                                var env = max(0, 1.0 - t * 2.0)
                                var shimmer = sin(t * 20) * 0.3
                                var freq = 800 + shimmer * 200
                                var wave = sin(t * freq * TAU) * env * 0.3
                                wave += sin(t * freq * 1.5 * TAU) * env * 0.15
                                samples.append(int((wave * 0.5 + 0.5) * 255))
                
                "loot_drop":
                        for i in range(int(22050 * 0.2)):
                                var t = float(i) / 22050.0
                                var env = max(0, 1.0 - t * 6.0)
                                var freq = 800 - t * 400
                                var wave = sin(t * freq * TAU) * env * 0.4
                                samples.append(int((wave * 0.5 + 0.5) * 255))
                
                "enemy_alert":
                        for i in range(int(22050 * 0.2)):
                                var t = float(i) / 22050.0
                                var env = max(0, 1.0 - t * 6.0)
                                var wave = sin(t * 600 * TAU) * env * 0.5
                                wave += sin(t * 900 * TAU) * env * 0.25
                                samples.append(int((wave * 0.5 + 0.5) * 255))
                
                _:
                        for i in range(sample_count):
                                var t = float(i) / 22050.0
                                var env = max(0, 1.0 - t * 15.0)
                                var wave = sin(t * 440 * TAU) * env * 0.3
                                samples.append(int((wave * 0.5 + 0.5) * 255))
        
        stream.data = samples
        return stream

func play_sound(sound_name: String, category: String = "sfx", pitch_variance: float = 0.1):
        var player = _get_available_player(category)
        if player == null:
                return
        
        var stream: AudioStream
        if sound_cache.has(sound_name):
                stream = sound_cache[sound_name]
        else:
                stream = _create_procedural_sound(sound_name)
                sound_cache[sound_name] = stream
        
        if stream:
                player.stream = stream
                player.volume_db = SOUND_VOLUMES.get(category, -5.0) + linear_to_db(sfx_volume * master_volume)
                player.pitch_scale = 1.0 + randf_range(-pitch_variance, pitch_variance)
                player.play()
                emit_signal("sound_played", sound_name)

func play_footstep(surface: SurfaceType = SurfaceType.GRASS, running: bool = false):
        var sound_name = "footstep_"
        match surface:
                SurfaceType.GRASS:
                        sound_name += "grass"
                SurfaceType.STONE:
                        sound_name += "stone"
                SurfaceType.WOOD:
                        sound_name += "wood"
                SurfaceType.SAND:
                        sound_name += "sand"
                SurfaceType.WATER:
                        sound_name += "water"
                SurfaceType.METAL:
                        sound_name += "metal"
        
        play_sound(sound_name, "footsteps", 0.15)

func play_attack_sound(weapon_type: String = "melee"):
        match weapon_type:
                "melee":
                        play_sound("swing", "combat", 0.1)
                "bow":
                        play_sound("bow_draw", "combat", 0.05)
                "crossbow":
                        play_sound("crossbow_load", "combat", 0.05)

func play_hit_sound(target_type: String = "flesh"):
        match target_type:
                "flesh":
                        play_sound("hit_flesh", "combat", 0.2)
                "wood":
                        play_sound("hit_wood", "combat", 0.15)
                "stone":
                        play_sound("hit_stone", "combat", 0.1)
                "metal":
                        play_sound("hit_metal", "combat", 0.1)

func play_pickup_sound(item_type: String = "misc"):
        match item_type:
                "resource":
                        play_sound("pickup_resource", "pickup", 0.1)
                "weapon", "tool":
                        play_sound("pickup_metal", "pickup", 0.1)
                "food", "drink":
                        play_sound("pickup_soft", "pickup", 0.1)
                _:
                        play_sound("pickup_default", "pickup", 0.1)

func play_ui_sound(action: String = "click"):
        match action:
                "click":
                        play_sound("ui_click", "ui", 0.05)
                "open":
                        play_sound("ui_open", "ui", 0.05)
                "close":
                        play_sound("ui_close", "ui", 0.05)
                "equip":
                        play_sound("ui_equip", "ui", 0.05)
                "error":
                        play_sound("ui_error", "ui", 0.0)
                "success":
                        play_sound("ui_success", "ui", 0.05)
                "craft":
                        play_sound("ui_craft", "ui", 0.1)

func set_master_volume(volume: float):
        master_volume = clamp(volume, 0.0, 1.0)

func set_sfx_volume(volume: float):
        sfx_volume = clamp(volume, 0.0, 1.0)

func set_music_volume(volume: float):
        music_volume = clamp(volume, 0.0, 1.0)
        if current_music:
                current_music.volume_db = linear_to_db(music_volume * master_volume)

func update_footsteps(delta: float, is_moving: bool, is_running: bool, surface: SurfaceType = SurfaceType.GRASS):
        if not is_moving:
                footstep_timer = 0.0
                return
        
        var interval = footstep_interval
        if is_running:
                interval *= 0.6
        
        footstep_timer += delta
        if footstep_timer >= interval:
                footstep_timer = 0.0
                play_footstep(surface, is_running)

func play_building_sound(action: String = "place"):
        match action:
                "place":
                        play_sound("build_place", "building", 0.1)
                "hammer":
                        play_sound("build_hammer", "building", 0.15)
                "destroy":
                        play_sound("build_destroy", "building", 0.1)
                "upgrade":
                        play_sound("build_hammer", "building", 0.1)
                        play_sound("ui_success", "ui", 0.05)

func play_gather_sound(resource_type: String = "wood"):
        match resource_type:
                "wood", "tree":
                        play_sound("hit_wood", "environment", 0.15)
                "stone", "rock", "ore":
                        play_sound("rock_break", "environment", 0.1)
                "plant", "fiber", "berry":
                        play_sound("pickup_soft", "pickup", 0.1)
                _:
                        play_sound("hit", "environment", 0.1)

func play_tree_fall():
        play_sound("tree_fall", "environment", 0.1)

func play_weather_sound(weather_type: String):
        match weather_type:
                "rain", "storm":
                        play_sound("rain_drop", "weather", 0.2)
                "thunder":
                        play_sound("thunder", "weather", 0.1)
                "wind":
                        play_sound("wind_gust", "weather", 0.1)

func play_ambient_sound(ambient_type: String = "forest"):
        match ambient_type:
                "forest":
                        play_sound("ambient_forest", "ambient", 0.1)
                "fire":
                        play_sound("fire_crackle", "ambient", 0.2)
                "water":
                        play_sound("water_splash", "ambient", 0.1)

func play_event_sound(event_type: String):
        match event_type:
                "death":
                        play_sound("death_sound", "combat", 0.0)
                "level_up":
                        play_sound("level_up", "ui", 0.0)
                "quest_complete":
                        play_sound("quest_complete", "ui", 0.0)
                "achievement":
                        play_sound("achievement", "ui", 0.0)
                "loot_drop":
                        play_sound("loot_drop", "pickup", 0.1)
                "enemy_alert":
                        play_sound("enemy_alert", "combat", 0.05)
