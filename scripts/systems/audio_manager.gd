extends Node

signal sound_played(sound_name: String)

const SOUND_VOLUMES := {
	"footsteps": -10.0,
	"ui": -5.0,
	"combat": 0.0,
	"ambient": -15.0,
	"pickup": -8.0
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
	for category in ["footsteps", "ui", "combat", "ambient", "pickup"]:
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
