extends Node3D

var world_streamer
var mob_spawner
var world_gen

func _ready():
        _setup_factions()
        call_deferred("_late_init")

func _late_init():
        world_gen = get_node_or_null("/root/WorldGenerator")
        world_streamer = get_node_or_null("/root/WorldStreamer")
        mob_spawner = get_node_or_null("/root/MobSpawner")
        
        _spawn_starting_area()

func _setup_factions():
        var fs = get_node_or_null("/root/FactionSystem")
        if fs:
                fs.create_faction("player")
                fs.create_faction("town")
                fs.create_faction("wild")
                fs.create_faction("bandits")
                fs.create_faction("monsters")
                fs.create_faction("neutral")
                
                fs.set_relation("player", "town", 50)
                fs.set_relation("player", "neutral", 0)
                fs.set_relation("player", "wild", -30)
                fs.set_relation("player", "bandits", -80)
                fs.set_relation("player", "monsters", -100)
                
                fs.set_relation("town", "wild", -20)
                fs.set_relation("town", "bandits", -100)
                fs.set_relation("town", "monsters", -100)
                fs.set_relation("town", "neutral", 20)
                
                fs.set_relation("bandits", "wild", -30)
                fs.set_relation("bandits", "monsters", -50)
                fs.set_relation("bandits", "neutral", -50)
                
                fs.set_relation("wild", "monsters", -20)
                fs.set_relation("wild", "neutral", 0)

func _spawn_starting_area():
        var npc_scene_path = "res://scenes/npcs/npc_citizen.tscn"
        if not ResourceLoader.exists(npc_scene_path):
                return
        
        var npc_scene = load(npc_scene_path)
        if not npc_scene:
                return
        
        var starting_positions = [
                Vector3(8, 1, 5),
                Vector3(-6, 1, 8),
                Vector3(5, 1, -7),
                Vector3(-8, 1, -5)
        ]
        
        for pos in starting_positions:
                var ground_y = 1.0
                if world_gen:
                        ground_y = world_gen.get_height_at(pos.x, pos.z) + 1.0
                
                var npc = npc_scene.instantiate()
                npc.position = Vector3(pos.x, ground_y, pos.z)
                
                if npc.has_method("set_faction"):
                        npc.set_faction("town")
                
                add_child(npc)

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
        var inventory_ui = get_node_or_null("CanvasLayer/InventoryUI")
        if inventory_ui:
                inventory_ui.visible = not inventory_ui.visible
                if inventory_ui.visible:
                        Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
                else:
                        Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _do_interact():
        var player = get_node_or_null("Player")
        if player and player.has_method("interact"):
                player.interact()

func get_world_info() -> Dictionary:
        var info := {
                "chunks_loaded": 0,
                "structures_loaded": 0,
                "mobs_spawned": 0
        }
        
        if world_streamer:
                info["chunks_loaded"] = world_streamer.get_loaded_chunk_count()
                info["structures_loaded"] = world_streamer.get_loaded_structure_count()
        
        if mob_spawner:
                info["mobs_spawned"] = mob_spawner.get_mob_count()
        
        return info
