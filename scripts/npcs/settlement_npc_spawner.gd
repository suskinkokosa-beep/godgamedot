extends Node

signal npc_spawned(npc: Node3D, settlement_id: int)
signal npc_despawned(npc: Node3D)

const CHARACTER_PATH = "res://assets/art_pack2/Characters/Base Characters/Godot/"
const NPC_SCENE_PATH = "res://scenes/npcs/npc.tscn"
const NPCAIBrainScript = preload("res://scripts/npcs/npc_ai_brain.gd")

var active_npcs := {}
var settlement_npcs := {}
var npc_pool := []
var max_npcs_per_settlement := 15
var spawn_radius := 50.0
var cached_character_scenes := {}

var character_models := [
        "Superhero_Male.gltf",
        "Superhero_Female.gltf"
]

var profession_colors := {
        "guard": Color(0.6, 0.2, 0.2),
        "trader": Color(0.2, 0.5, 0.2),
        "farmer": Color(0.5, 0.4, 0.2),
        "hunter": Color(0.3, 0.4, 0.3),
        "craftsman": Color(0.4, 0.3, 0.5),
        "miner": Color(0.35, 0.35, 0.4),
        "citizen": Color(0.5, 0.5, 0.5),
        "priest": Color(0.6, 0.6, 0.7),
        "soldier": Color(0.5, 0.25, 0.25)
}

var settlement_system = null
var settlement_builder = null
var name_generator = null

func _ready():
        settlement_system = get_node_or_null("/root/SettlementSystem")
        settlement_builder = get_node_or_null("/root/SettlementBuilder")
        name_generator = get_node_or_null("/root/NameGenerator")
        
        if settlement_builder:
                settlement_builder.connect("settlement_spawned", _on_settlement_spawned)

func _on_settlement_spawned(settlement_id: int, position: Vector3):
        if not settlement_system:
                return
        
        var settlement = settlement_system.get_settlement(settlement_id)
        if not settlement:
                return
        
        var building_data = settlement.get("building_data", [])
        spawn_npcs_for_settlement(settlement_id, position, building_data)

func spawn_npcs_for_settlement(settlement_id: int, center_pos: Vector3, building_data: Array):
        if settlement_npcs.has(settlement_id):
                return
        
        settlement_npcs[settlement_id] = []
        
        var total_capacity = 0
        for building in building_data:
                total_capacity += building.get("npc_capacity", 2)
        
        var npc_count = min(total_capacity, max_npcs_per_settlement)
        
        var profession_distribution = _calculate_profession_distribution(npc_count, building_data)
        
        var building_index = 0
        for prof_key in profession_distribution:
                var count = profession_distribution[prof_key]
                for i in range(count):
                        var spawn_pos = center_pos
                        
                        if building_index < building_data.size():
                                spawn_pos = center_pos + building_data[building_index].get("position", Vector3.ZERO)
                                spawn_pos += Vector3(randf_range(-2, 2), 0, randf_range(-2, 2))
                                building_index += 1
                        else:
                                spawn_pos += Vector3(randf_range(-20, 20), 0, randf_range(-20, 20))
                        
                        var npc = _spawn_npc(spawn_pos, prof_key, settlement_id)
                        if npc:
                                settlement_npcs[settlement_id].append(npc)
                                active_npcs[npc.get_instance_id()] = {
                                        "npc": npc,
                                        "settlement_id": settlement_id,
                                        "profession": prof_key
                                }
                                emit_signal("npc_spawned", npc, settlement_id)

func _calculate_profession_distribution(total_count: int, building_data: Array) -> Dictionary:
        var distribution := {}
        
        var has_blacksmith = false
        var has_tavern = false
        var has_shop = false
        var has_guard_tower = false
        
        for building in building_data:
                var b_type = building.get("type", "")
                if b_type == "blacksmith":
                        has_blacksmith = true
                elif b_type == "tavern":
                        has_tavern = true
                elif b_type == "shop":
                        has_shop = true
                elif b_type == "guard_tower":
                        has_guard_tower = true
        
        var guard_pct = 0.15 + (0.05 if has_guard_tower else 0.0)
        var trader_pct = 0.10 + (0.03 if has_shop else 0.0)
        var farmer_pct = 0.25
        var craftsman_pct = 0.10 + (0.05 if has_blacksmith else 0.0)
        var hunter_pct = 0.10
        
        var total_pct = guard_pct + trader_pct + farmer_pct + craftsman_pct + hunter_pct
        
        guard_pct /= total_pct
        trader_pct /= total_pct
        farmer_pct /= total_pct
        craftsman_pct /= total_pct
        hunter_pct /= total_pct
        
        var citizen_pct = 0.3
        var available_for_jobs = int(total_count * 0.7)
        var citizen_count = total_count - available_for_jobs
        
        distribution["guard"] = max(1, int(available_for_jobs * guard_pct))
        distribution["trader"] = max(1, int(available_for_jobs * trader_pct))
        distribution["farmer"] = int(available_for_jobs * farmer_pct)
        distribution["craftsman"] = int(available_for_jobs * craftsman_pct)
        distribution["hunter"] = int(available_for_jobs * hunter_pct)
        
        var assigned = 0
        for v in distribution.values():
                assigned += v
        
        distribution["citizen"] = max(0, total_count - assigned)
        
        return distribution

func _spawn_npc(position: Vector3, profession: String, settlement_id: int) -> Node3D:
        var npc_scene = load(NPC_SCENE_PATH) if ResourceLoader.exists(NPC_SCENE_PATH) else null
        var npc: CharacterBody3D
        
        if npc_scene:
                npc = npc_scene.instantiate()
        else:
                npc = _create_basic_npc()
        
        npc.global_position = position
        npc.add_to_group("npcs")
        
        var is_female = randf() > 0.5
        _setup_npc_model(npc, is_female, profession)
        
        var ai_brain = npc.get_node_or_null("NPCAIBrain")
        if not ai_brain:
                ai_brain = NPCAIBrainScript.new()
                ai_brain.name = "NPCAIBrain"
                npc.add_child(ai_brain)
        
        ai_brain.home_settlement_id = settlement_id
        ai_brain.profession = _get_profession_enum(profession)
        ai_brain.home_position = position
        
        if name_generator and name_generator.has_method("generate_npc_name"):
                ai_brain.npc_name = name_generator.generate_npc_name(is_female)
        else:
                ai_brain.npc_name = _generate_fallback_name(is_female)
        
        _add_name_label(npc, ai_brain.npc_name, profession)
        
        var world_root = get_tree().get_first_node_in_group("world_root")
        if world_root:
                world_root.add_child(npc)
        else:
                get_tree().current_scene.add_child(npc)
        
        return npc

func _create_basic_npc() -> CharacterBody3D:
        var npc = CharacterBody3D.new()
        npc.collision_layer = 4
        npc.collision_mask = 3
        
        var col = CollisionShape3D.new()
        var capsule = CapsuleShape3D.new()
        capsule.radius = 0.4
        capsule.height = 1.8
        col.shape = capsule
        col.position.y = 0.9
        npc.add_child(col)
        
        return npc

func _setup_npc_model(npc: CharacterBody3D, is_female: bool, profession: String):
        var model_file = "Superhero_Female.gltf" if is_female else "Superhero_Male.gltf"
        var model_path = CHARACTER_PATH + model_file
        
        var model: Node3D = null
        
        if cached_character_scenes.has(model_path):
                model = cached_character_scenes[model_path].duplicate()
        elif ResourceLoader.exists(model_path):
                var gltf_doc = GLTFDocument.new()
                var gltf_state = GLTFState.new()
                
                var err = gltf_doc.append_from_file(model_path, gltf_state)
                if err == OK:
                        var base_model = gltf_doc.generate_scene(gltf_state)
                        cached_character_scenes[model_path] = base_model
                        model = base_model.duplicate()
        
        if not model:
                model = _create_fallback_model()
        
        model.name = "CharacterModel"
        model.scale = Vector3(0.01, 0.01, 0.01)
        
        _apply_profession_color(model, profession)
        
        var old_model = npc.get_node_or_null("CharacterModel")
        if old_model:
                old_model.queue_free()
        
        npc.add_child(model)

func _create_fallback_model() -> Node3D:
        var model = Node3D.new()
        
        var body = MeshInstance3D.new()
        var capsule = CapsuleMesh.new()
        capsule.radius = 0.35
        capsule.height = 1.4
        body.mesh = capsule
        body.position.y = 0.9
        model.add_child(body)
        
        var head = MeshInstance3D.new()
        var sphere = SphereMesh.new()
        sphere.radius = 0.2
        head.mesh = sphere
        head.position.y = 1.75
        model.add_child(head)
        
        return model

func _apply_profession_color(model: Node3D, profession: String):
        var color = profession_colors.get(profession, Color(0.5, 0.5, 0.5))
        
        for child in model.get_children():
                if child is MeshInstance3D:
                        var mat = StandardMaterial3D.new()
                        mat.albedo_color = color
                        mat.roughness = 0.7
                        child.material_override = mat
                
                if child.get_child_count() > 0:
                        _apply_profession_color(child, profession)

func _add_name_label(npc: Node3D, npc_name: String, profession: String):
        var old_label = npc.get_node_or_null("NameLabel3D")
        if old_label:
                old_label.queue_free()
        
        var label = Label3D.new()
        label.name = "NameLabel3D"
        label.text = npc_name + "\n" + _get_profession_title(profession)
        label.position.y = 2.2
        label.font_size = 24
        label.outline_size = 4
        label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
        label.modulate = profession_colors.get(profession, Color.WHITE)
        label.no_depth_test = true
        
        npc.add_child(label)

func _get_profession_title(profession: String) -> String:
        var lang = "ru"
        var lang_selector = get_node_or_null("/root/LangSelector")
        if lang_selector:
                lang = lang_selector.current_language
        
        var titles_ru := {
                "guard": "Стражник",
                "trader": "Торговец",
                "farmer": "Фермер",
                "hunter": "Охотник",
                "craftsman": "Ремесленник",
                "miner": "Шахтёр",
                "citizen": "Житель",
                "priest": "Жрец",
                "soldier": "Солдат"
        }
        
        var titles_en := {
                "guard": "Guard",
                "trader": "Trader",
                "farmer": "Farmer",
                "hunter": "Hunter",
                "craftsman": "Craftsman",
                "miner": "Miner",
                "citizen": "Citizen",
                "priest": "Priest",
                "soldier": "Soldier"
        }
        
        if lang == "ru":
                return titles_ru.get(profession, "Житель")
        return titles_en.get(profession, "Citizen")

func _get_profession_enum(profession: String) -> int:
        match profession:
                "guard": return 1
                "trader": return 2
                "farmer": return 3
                "hunter": return 4
                "craftsman": return 5
                "miner": return 6
                "citizen": return 7
                "priest": return 8
                "soldier": return 9
        return 7

func _generate_fallback_name(is_female: bool) -> String:
        var male_names = ["Иван", "Пётр", "Алексей", "Дмитрий", "Николай", "Василий", "Григорий"]
        var female_names = ["Анна", "Мария", "Елена", "Ольга", "Наталья", "Екатерина", "Татьяна"]
        
        if is_female:
                return female_names[randi() % female_names.size()]
        return male_names[randi() % male_names.size()]

func despawn_settlement_npcs(settlement_id: int):
        if not settlement_npcs.has(settlement_id):
                return
        
        for npc in settlement_npcs[settlement_id]:
                if is_instance_valid(npc):
                        emit_signal("npc_despawned", npc)
                        active_npcs.erase(npc.get_instance_id())
                        npc.queue_free()
        
        settlement_npcs.erase(settlement_id)

func get_npcs_in_settlement(settlement_id: int) -> Array:
        if settlement_npcs.has(settlement_id):
                return settlement_npcs[settlement_id].filter(func(n): return is_instance_valid(n))
        return []

func get_npc_count() -> int:
        return active_npcs.size()

func get_nearby_npcs(position: Vector3, radius: float) -> Array:
        var nearby := []
        for npc_data in active_npcs.values():
                var npc = npc_data.npc
                if is_instance_valid(npc):
                        if npc.global_position.distance_to(position) <= radius:
                                nearby.append(npc)
        return nearby

func respawn_npc(settlement_id: int, profession: String = ""):
        if not settlement_system:
                return
        
        var settlement = settlement_system.get_settlement(settlement_id)
        if not settlement:
                return
        
        var center = settlement.get("position", Vector3.ZERO)
        var spawn_pos = center + Vector3(randf_range(-10, 10), 0, randf_range(-10, 10))
        
        if profession.is_empty():
                var professions = ["citizen", "farmer", "guard", "trader"]
                profession = professions[randi() % professions.size()]
        
        var npc = _spawn_npc(spawn_pos, profession, settlement_id)
        if npc:
                settlement_npcs[settlement_id].append(npc)
                active_npcs[npc.get_instance_id()] = {
                        "npc": npc,
                        "settlement_id": settlement_id,
                        "profession": profession
                }
                emit_signal("npc_spawned", npc, settlement_id)
