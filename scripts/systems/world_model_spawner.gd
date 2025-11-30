extends Node

signal models_spawned(count: int)
signal spawn_progress(current: int, total: int)

var spawn_queue := []
var is_spawning := false
var spawned_models := {}

var spawn_settings := {
        "forest": {
                "tree_density": 0.15,
                "bush_density": 0.08,
                "rock_density": 0.03,
                "flower_density": 0.05,
                "mushroom_density": 0.02
        },
        "plains": {
                "tree_density": 0.02,
                "bush_density": 0.03,
                "rock_density": 0.01,
                "flower_density": 0.08,
                "mushroom_density": 0.01
        },
        "mountains": {
                "tree_density": 0.05,
                "bush_density": 0.02,
                "rock_density": 0.15,
                "flower_density": 0.01,
                "mushroom_density": 0.005
        },
        "swamp": {
                "tree_density": 0.08,
                "bush_density": 0.05,
                "rock_density": 0.02,
                "flower_density": 0.02,
                "mushroom_density": 0.08
        },
        "desert": {
                "tree_density": 0.01,
                "bush_density": 0.01,
                "rock_density": 0.08,
                "flower_density": 0.005,
                "mushroom_density": 0.0
        }
}

func _ready():
        print("[WorldModelSpawner] Ready - integrates with ModelLoader for 3D asset spawning")

func spawn_nature_in_area(area_center: Vector3, area_size: Vector2, biome: String = "forest", parent_node: Node3D = null) -> int:
        if not Engine.has_singleton("ModelLoader") and not has_node("/root/ModelLoader"):
                push_warning("ModelLoader not available")
                return 0
        
        var settings = spawn_settings.get(biome, spawn_settings["forest"])
        var spawned_count := 0
        var target_node = parent_node if parent_node else get_tree().current_scene
        
        if not target_node:
                return 0
        
        var area_half_x = area_size.x / 2.0
        var area_half_z = area_size.y / 2.0
        
        spawned_count += _spawn_category_in_area("tree", settings.tree_density, area_center, area_half_x, area_half_z, target_node)
        spawned_count += _spawn_category_in_area("bush", settings.bush_density, area_center, area_half_x, area_half_z, target_node)
        spawned_count += _spawn_category_in_area("rock", settings.rock_density, area_center, area_half_x, area_half_z, target_node)
        spawned_count += _spawn_category_in_area("flower", settings.flower_density, area_center, area_half_x, area_half_z, target_node)
        spawned_count += _spawn_category_in_area("mushroom", settings.mushroom_density, area_center, area_half_x, area_half_z, target_node)
        
        emit_signal("models_spawned", spawned_count)
        return spawned_count

func _spawn_category_in_area(category: String, density: float, center: Vector3, half_x: float, half_z: float, parent: Node3D) -> int:
        if density <= 0:
                return 0
        
        var model_loader = _get_model_loader()
        if not model_loader:
                return 0
        
        var models = model_loader.get_nature_by_category(category)
        if models.is_empty():
                return 0
        
        var area = half_x * 2 * half_z * 2
        var spawn_count = int(area * density)
        var spawned := 0
        
        for i in range(spawn_count):
                var random_x = randf_range(-half_x, half_x)
                var random_z = randf_range(-half_z, half_z)
                var pos = center + Vector3(random_x, 0, random_z)
                
                var model_id = models[randi() % models.size()]
                var instance = model_loader.load_model(model_id, "nature")
                
                if instance:
                        instance.position = pos
                        instance.rotation.y = randf() * TAU
                        
                        var scale_var = randf_range(0.8, 1.2)
                        instance.scale *= scale_var
                        
                        parent.add_child(instance)
                        spawned += 1
                        
                        var spawn_key = str(int(pos.x)) + "_" + str(int(pos.z))
                        if not spawned_models.has(spawn_key):
                                spawned_models[spawn_key] = []
                        spawned_models[spawn_key].append(instance)
        
        return spawned

func _get_model_loader():
        if has_node("/root/ModelLoader"):
                return get_node("/root/ModelLoader")
        return null

func _get_material_factory():
        if has_node("/root/MaterialFactory"):
                return get_node("/root/MaterialFactory")
        return null

func _get_texture_loader():
        if has_node("/root/TextureLoader"):
                return get_node("/root/TextureLoader")
        return null

func _apply_biome_materials(instance: Node3D, category: String, biome: String):
        var material_factory = _get_material_factory()
        if not material_factory:
                return
        
        var material: StandardMaterial3D = null
        
        match category:
                "tree":
                        var materials = material_factory.get_biome_tree_materials(biome)
                        if materials.has("bark") and materials.bark:
                                _apply_material_recursive(instance, materials.bark, "bark")
                        if materials.has("leaves") and materials.leaves:
                                _apply_material_recursive(instance, materials.leaves, "leaves")
                "bush":
                        material = material_factory.create_leaves_material("leaves_common")
                "rock":
                        material = material_factory.get_biome_rock_material(biome)
                "flower":
                        var texture_loader = _get_texture_loader()
                        if texture_loader:
                                material = texture_loader.create_material("flowers", "nature")
                "mushroom":
                        var texture_loader = _get_texture_loader()
                        if texture_loader:
                                material = texture_loader.create_material("mushrooms", "nature")
                "grass":
                        var texture_loader = _get_texture_loader()
                        if texture_loader:
                                material = texture_loader.create_material("grass", "nature")
        
        if material:
                material_factory.apply_material_to_node(instance, material)

func _apply_material_recursive(node: Node3D, material: StandardMaterial3D, part_name: String = ""):
        if node is MeshInstance3D:
                var mesh_name = node.name.to_lower()
                if part_name.is_empty() or part_name in mesh_name:
                        node.material_override = material
        
        for child in node.get_children():
                if child is Node3D:
                        _apply_material_recursive(child, material, part_name)

func spawn_prop_at_position(prop_id: String, position: Vector3, rotation_y: float = 0.0, parent: Node3D = null) -> Node3D:
        var model_loader = _get_model_loader()
        if not model_loader:
                return null
        
        var instance = model_loader.load_model(prop_id, "prop")
        if not instance:
                return null
        
        instance.position = position
        instance.rotation.y = rotation_y
        
        var target = parent if parent else get_tree().current_scene
        if target:
                target.add_child(instance)
        
        return instance

func spawn_building_at_position(building_id: String, position: Vector3, rotation_y: float = 0.0, parent: Node3D = null) -> Node3D:
        var model_loader = _get_model_loader()
        if not model_loader:
                return null
        
        var instance = model_loader.load_model(building_id, "building")
        if not instance:
                return null
        
        instance.position = position
        instance.rotation.y = rotation_y
        
        var target = parent if parent else get_tree().current_scene
        if target:
                target.add_child(instance)
        
        return instance

func spawn_creature_at_position(creature_id: String, position: Vector3, parent: Node3D = null) -> Node3D:
        var model_loader = _get_model_loader()
        if not model_loader:
                return null
        
        var instance = model_loader.load_model(creature_id, "creature")
        if not instance:
                return null
        
        instance.position = position
        instance.rotation.y = randf() * TAU
        
        var target = parent if parent else get_tree().current_scene
        if target:
                target.add_child(instance)
        
        return instance

func spawn_random_props_in_building(building_bounds: AABB, parent: Node3D, prop_count: int = 5) -> Array:
        var model_loader = _get_model_loader()
        if not model_loader:
                return []
        
        var spawned := []
        var furniture_props = model_loader.get_props_by_category("furniture")
        var container_props = model_loader.get_props_by_category("container")
        var light_props = model_loader.get_props_by_category("light")
        
        var all_props = furniture_props + container_props + light_props
        if all_props.is_empty():
                return []
        
        for i in range(prop_count):
                var prop_id = all_props[randi() % all_props.size()]
                var pos = Vector3(
                        randf_range(building_bounds.position.x, building_bounds.end.x),
                        building_bounds.position.y,
                        randf_range(building_bounds.position.z, building_bounds.end.z)
                )
                
                var instance = spawn_prop_at_position(prop_id, pos, randf() * TAU, parent)
                if instance:
                        spawned.append(instance)
        
        return spawned

func create_settlement_buildings(center: Vector3, settlement_size: int = 5, parent: Node3D = null) -> Array:
        var model_loader = _get_model_loader()
        if not model_loader:
                return []
        
        var buildings := []
        var floor_models = model_loader.get_buildings_by_category("floor")
        var door_models = model_loader.get_buildings_by_category("door")
        
        var spacing = 8.0
        var grid_size = int(sqrt(settlement_size)) + 1
        
        for i in range(settlement_size):
                var grid_x = i % grid_size
                var grid_z = i / grid_size
                var pos = center + Vector3(grid_x * spacing - (grid_size * spacing / 2), 0, grid_z * spacing - (grid_size * spacing / 2))
                
                if not floor_models.is_empty():
                        var floor_id = floor_models[randi() % floor_models.size()]
                        var floor_instance = spawn_building_at_position(floor_id, pos, 0, parent)
                        if floor_instance:
                                buildings.append(floor_instance)
                
                if not door_models.is_empty() and randf() > 0.5:
                        var door_id = door_models[randi() % door_models.size()]
                        var door_pos = pos + Vector3(0, 0, -2)
                        var door_instance = spawn_building_at_position(door_id, door_pos, 0, parent)
                        if door_instance:
                                buildings.append(door_instance)
        
        return buildings

func clear_spawned_models_in_area(center: Vector3, radius: float):
        var keys_to_remove := []
        
        for key in spawned_models:
                var parts = key.split("_")
                if parts.size() >= 2:
                        var pos = Vector3(float(parts[0]), 0, float(parts[1]))
                        if pos.distance_to(Vector3(center.x, 0, center.z)) <= radius:
                                for model in spawned_models[key]:
                                        if is_instance_valid(model):
                                                model.queue_free()
                                keys_to_remove.append(key)
        
        for key in keys_to_remove:
                spawned_models.erase(key)

func get_spawned_count() -> int:
        var count := 0
        for key in spawned_models:
                count += spawned_models[key].size()
        return count

func set_biome_settings(biome: String, settings: Dictionary):
        spawn_settings[biome] = settings

func spawn_decoration_cluster(cluster_type: String, center: Vector3, count: int = 10, radius: float = 5.0, parent: Node3D = null) -> Array:
        var model_loader = _get_model_loader()
        if not model_loader:
                return []
        
        var spawned := []
        var models: Array
        
        match cluster_type:
                "rocks":
                        models = model_loader.get_nature_by_category("rock")
                "flowers":
                        models = model_loader.get_nature_by_category("flower")
                "mushrooms":
                        models = model_loader.get_nature_by_category("mushroom")
                "trees":
                        models = model_loader.get_nature_by_category("tree")
                "bushes":
                        models = model_loader.get_nature_by_category("bush")
                _:
                        return []
        
        if models.is_empty():
                return []
        
        var target = parent if parent else get_tree().current_scene
        if not target:
                return []
        
        for i in range(count):
                var angle = randf() * TAU
                var dist = randf() * radius
                var offset = Vector3(cos(angle) * dist, 0, sin(angle) * dist)
                var pos = center + offset
                
                var model_id = models[randi() % models.size()]
                var instance = model_loader.load_model(model_id, "nature")
                
                if instance:
                        instance.position = pos
                        instance.rotation.y = randf() * TAU
                        instance.scale *= randf_range(0.7, 1.3)
                        target.add_child(instance)
                        spawned.append(instance)
        
        return spawned
