extends Node3D

var npc_scene_path = "res://scenes/npcs/npc_citizen.tscn"
var mob_scene_path = "res://scenes/mobs/mob_basic.tscn"

var spawned_npcs = []
var spawned_mobs = []

func _ready():
	_setup_biomes()
	_setup_spawn_tables()
	_setup_factions()
	call_deferred("_spawn_initial_npcs")
	call_deferred("_spawn_initial_mobs")

func _setup_biomes():
	var bs = get_node_or_null("/root/BiomeSystem")
	if bs:
		bs.add_biome("spawn_town", Vector3(0, 0, 0), 50.0, 18.0)
		bs.add_biome("forest", Vector3(100, 0, 0), 80.0, 15.0)
		bs.add_biome("plains", Vector3(-80, 0, 50), 60.0, 20.0)
		bs.add_biome("desert", Vector3(0, 0, 150), 70.0, 35.0)
		bs.add_biome("tundra", Vector3(0, 0, -120), 60.0, -5.0)

func _setup_spawn_tables():
	var st = get_node_or_null("/root/SpawnTable")
	if st:
		st.register_table("forest", [
			{"scene": "res://scenes/props/wolf.tscn", "weight": 30},
			{"scene": "res://scenes/props/boar.tscn", "weight": 40},
			{"scene": "res://scenes/props/bear.tscn", "weight": 10}
		])
		st.register_table("plains", [
			{"scene": "res://scenes/props/boar.tscn", "weight": 50},
			{"scene": "res://scenes/mobs/mob_basic.tscn", "weight": 30}
		])
		st.register_table("desert", [
			{"scene": "res://scenes/mobs/mob_basic.tscn", "weight": 60}
		])
		st.register_table("tundra", [
			{"scene": "res://scenes/props/wolf.tscn", "weight": 50},
			{"scene": "res://scenes/props/bear.tscn", "weight": 30}
		])

func _setup_factions():
	var fs = get_node_or_null("/root/FactionSystem")
	if fs:
		fs.create_faction("player")
		fs.create_faction("town")
		fs.create_faction("wild")
		fs.create_faction("bandits")
		fs.set_relation("player", "town", 1)
		fs.set_relation("player", "wild", -1)
		fs.set_relation("player", "bandits", -1)
		fs.set_relation("town", "wild", -1)
		fs.set_relation("town", "bandits", -1)

func _spawn_initial_npcs():
	var npc_positions = [
		Vector3(5, 1, 5),
		Vector3(-8, 1, 3),
		Vector3(3, 1, -6),
		Vector3(-5, 1, -4)
	]
	for pos in npc_positions:
		_spawn_npc(pos)

func _spawn_npc(pos: Vector3):
	var scene = ResourceLoader.load(npc_scene_path)
	if scene:
		var npc = scene.instantiate()
		npc.position = pos
		add_child(npc)
		spawned_npcs.append(npc)

func _spawn_initial_mobs():
	var mob_positions = [
		Vector3(30, 1, 20),
		Vector3(-25, 1, 35),
		Vector3(40, 1, -15),
		Vector3(-35, 1, -30)
	]
	for pos in mob_positions:
		_spawn_mob(pos)

func _spawn_mob(pos: Vector3):
	var scene = ResourceLoader.load(mob_scene_path)
	if scene:
		var mob = scene.instantiate()
		mob.position = pos
		add_child(mob)
		spawned_mobs.append(mob)

func _input(event):
	if event.is_action_pressed("escape"):
		_show_pause_menu()
	if event.is_action_pressed("inventory"):
		_toggle_inventory()
	if event.is_action_pressed("interact"):
		_do_interact()

func _show_pause_menu():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")

func _toggle_inventory():
	pass

func _do_interact():
	var player = get_node_or_null("Player")
	if player and player.has_method("interact"):
		player.interact()
