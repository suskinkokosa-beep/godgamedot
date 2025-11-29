extends Node

signal build_placed(item_id: String, position: Vector3, rotation: Vector3)
signal build_destroyed(structure: Node3D)
signal structure_damaged(structure: Node3D, damage: float, current_health: float)
signal structure_repaired(structure: Node3D, amount: float, current_health: float)

var preview_instance = null
var current_part := ""
var snap_size := 2.0
var is_building := false
var placed_structures := []
var structure_connections := {}

var snap_points := []
var nearby_snap_threshold := 0.5
var rotation_snap := PI / 4

var building_parts := {
        "wooden_foundation": {"scene": "foundation", "material": "wood", "health": 200, "cost": {"wood": 50}, "size": Vector3(4, 0.5, 4)},
        "wooden_wall": {"scene": "wall", "material": "wood", "health": 150, "cost": {"wood": 30}, "size": Vector3(4, 3, 0.2)},
        "wooden_floor": {"scene": "floor", "material": "wood", "health": 100, "cost": {"wood": 25}, "size": Vector3(4, 0.1, 4)},
        "wooden_door": {"scene": "door_frame", "material": "wood", "health": 100, "cost": {"wood": 40}, "size": Vector3(1.2, 2.2, 0.2)},
        "wooden_doorframe": {"scene": "doorframe", "material": "wood", "health": 120, "cost": {"wood": 35}, "size": Vector3(4, 3, 0.2)},
        "wooden_window": {"scene": "window", "material": "wood", "health": 80, "cost": {"wood": 25}, "size": Vector3(4, 3, 0.2)},
        "wooden_roof": {"scene": "roof", "material": "wood", "health": 120, "cost": {"wood": 35}, "size": Vector3(4, 0.5, 4)},
        "wooden_stairs": {"scene": "stairs", "material": "wood", "health": 100, "cost": {"wood": 40}, "size": Vector3(2, 3, 4)},
        "stone_foundation": {"scene": "foundation", "material": "stone", "health": 500, "cost": {"stone": 100}, "size": Vector3(4, 0.5, 4)},
        "stone_wall": {"scene": "wall", "material": "stone", "health": 400, "cost": {"stone": 60}, "size": Vector3(4, 3, 0.3)},
        "stone_floor": {"scene": "floor", "material": "stone", "health": 350, "cost": {"stone": 50}, "size": Vector3(4, 0.15, 4)},
        "metal_door": {"scene": "door_frame", "material": "metal", "health": 300, "cost": {"iron_ingot": 10}, "size": Vector3(1.2, 2.2, 0.1)},
        "armored_door": {"scene": "door_frame", "material": "steel", "health": 500, "cost": {"steel_ingot": 15}, "size": Vector3(1.2, 2.2, 0.1)},
        "metal_wall": {"scene": "wall", "material": "metal", "health": 600, "cost": {"iron_ingot": 15}, "size": Vector3(4, 3, 0.15)},
        "tool_cupboard": {"scene": "cupboard", "material": "wood", "health": 200, "cost": {"wood": 100, "iron_ingot": 2}, "size": Vector3(1, 1.5, 0.5)},
        "storage_box": {"scene": "box", "material": "wood", "health": 100, "cost": {"wood": 30}, "size": Vector3(1, 0.8, 0.5)},
        "large_storage": {"scene": "large_box", "material": "wood", "health": 150, "cost": {"wood": 100, "iron_ingot": 5}, "size": Vector3(2, 1.2, 1)},
        "workbench_1": {"scene": "workbench", "material": "wood", "health": 150, "cost": {"wood": 50, "stone": 20}, "size": Vector3(2, 1, 1)},
        "workbench_2": {"scene": "workbench", "material": "iron", "health": 250, "cost": {"wood": 100, "iron_ingot": 10}, "size": Vector3(2, 1, 1)},
        "workbench_3": {"scene": "workbench", "material": "steel", "health": 400, "cost": {"wood": 150, "steel_ingot": 20}, "size": Vector3(2, 1, 1)},
        "furnace": {"scene": "furnace", "material": "stone", "health": 300, "cost": {"stone": 50, "iron_ingot": 5}, "size": Vector3(1.5, 1.5, 1.5)},
        "campfire": {"scene": "campfire", "material": "stone", "health": 50, "cost": {"stone": 5, "wood": 10}, "size": Vector3(1, 0.3, 1)},
        "sleeping_bag": {"scene": "bed", "material": "cloth", "health": 30, "cost": {"plant_fiber": 30, "hide": 5}, "size": Vector3(0.8, 0.2, 2)},
        "bed": {"scene": "bed", "material": "wood", "health": 80, "cost": {"wood": 50, "hide": 10}, "size": Vector3(1, 0.5, 2)}
}

var material_colors := {
        "wood": Color(0.55, 0.35, 0.2),
        "stone": Color(0.5, 0.5, 0.5),
        "metal": Color(0.6, 0.6, 0.65),
        "iron": Color(0.55, 0.55, 0.6),
        "steel": Color(0.7, 0.7, 0.75),
        "cloth": Color(0.7, 0.6, 0.5)
}

func start_build(item_id: String):
        if not building_parts.has(item_id):
                return false
        current_part = item_id
        is_building = true
        _spawn_preview(item_id)
        return true

func cancel_build():
        if preview_instance:
                preview_instance.queue_free()
                preview_instance = null
        current_part = ""
        is_building = false

func _spawn_preview(item_id: String):
        if preview_instance:
                preview_instance.queue_free()
        
        var part_data = building_parts.get(item_id, {})
        var scene_name = part_data.get("scene", item_id)
        var scene_path = "res://scenes/building_parts/%s.tscn" % scene_name
        var scene = ResourceLoader.load(scene_path)
        
        if scene:
                preview_instance = scene.instantiate()
                add_child(preview_instance)
                _set_preview_material(preview_instance, Color(0, 1, 0, 0.4))
        else:
                preview_instance = _create_placeholder_preview()
                add_child(preview_instance)

func _create_placeholder_preview() -> Node3D:
        var node = Node3D.new()
        var mesh_inst = MeshInstance3D.new()
        var box = BoxMesh.new()
        box.size = Vector3(snap_size, 1, snap_size)
        mesh_inst.mesh = box
        var mat = StandardMaterial3D.new()
        mat.albedo_color = Color(0, 1, 0, 0.4)
        mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
        mesh_inst.material_override = mat
        node.add_child(mesh_inst)
        return node

func _set_preview_material(node: Node, color: Color):
        for child in node.get_children():
                if child is MeshInstance3D:
                        var mat = StandardMaterial3D.new()
                        mat.albedo_color = color
                        mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
                        child.material_override = mat
                _set_preview_material(child, color)

func update_preview(camera: Camera3D):
        if not preview_instance or not is_building:
                return
        
        var from = camera.global_position
        var to = from - camera.global_basis.z * 8.0
        var space = camera.get_world_3d().direct_space_state
        var query = PhysicsRayQueryParameters3D.create(from, to)
        var result = space.intersect_ray(query)
        
        if result:
                var pos = _snap_position(result.position)
                preview_instance.global_position = pos
                _check_valid_placement(pos)

func _snap_position(pos: Vector3) -> Vector3:
        return Vector3(
                round(pos.x / snap_size) * snap_size,
                round(pos.y / 1.0) * 1.0,
                round(pos.z / snap_size) * snap_size
        )

func _check_valid_placement(pos: Vector3) -> bool:
        var valid = true
        for s in placed_structures:
                if is_instance_valid(s) and s.global_position.distance_to(pos) < 0.5:
                        valid = false
                        break
        
        if valid:
                _set_preview_material(preview_instance, Color(0, 1, 0, 0.4))
        else:
                _set_preview_material(preview_instance, Color(1, 0, 0, 0.4))
        
        return valid

func confirm_build(player) -> bool:
        if not preview_instance or not is_building or current_part == "":
                return false
        
        var pos = preview_instance.global_position
        if not _check_valid_placement(pos):
                return false
        
        var inv = get_node_or_null("/root/Inventory")
        var part_data = building_parts.get(current_part, {})
        var cost = part_data.get("cost", {})
        
        for resource in cost.keys():
                if not inv or not inv.has_item(resource, cost[resource]):
                        return false
        
        for resource in cost.keys():
                inv.remove_item(resource, cost[resource])
        
        _place_structure(current_part, pos, preview_instance.rotation)
        
        var prog = get_node_or_null("/root/PlayerProgression")
        if prog and player:
                var pid = player.get("net_id") if player.has_method("get") and player.get("net_id") else 1
                prog.add_skill_xp(pid, "building", 5.0)
                prog.add_xp(pid, 2.0)
        
        return true

func _place_structure(item_id: String, pos: Vector3, rot: Vector3):
        var part_data = building_parts.get(item_id, {})
        var scene_name = part_data.get("scene", item_id)
        var scene_path = "res://scenes/building_parts/%s.tscn" % scene_name
        var scene = ResourceLoader.load(scene_path)
        
        var structure: Node3D
        if scene:
                structure = scene.instantiate()
        else:
                structure = _create_placeholder_structure(item_id)
        
        structure.global_position = pos
        structure.rotation = rot
        structure.set_meta("structure_type", item_id)
        structure.set_meta("health", part_data.get("health", 100))
        structure.set_meta("max_health", part_data.get("health", 100))
        
        var world = get_tree().root.get_node_or_null("GameWorld")
        if world:
                world.add_child(structure)
        else:
                add_child(structure)
        
        placed_structures.append(structure)
        emit_signal("build_placed", item_id, pos, rot)

func _create_placeholder_structure(item_id: String) -> StaticBody3D:
        var body = StaticBody3D.new()
        body.name = item_id
        
        var mesh_inst = MeshInstance3D.new()
        var box = BoxMesh.new()
        box.size = Vector3(snap_size, 2, snap_size)
        mesh_inst.mesh = box
        
        var mat = StandardMaterial3D.new()
        mat.albedo_color = Color(0.6, 0.4, 0.2)
        mesh_inst.material_override = mat
        body.add_child(mesh_inst)
        
        var col = CollisionShape3D.new()
        var shape = BoxShape3D.new()
        shape.size = Vector3(snap_size, 2, snap_size)
        col.shape = shape
        body.add_child(col)
        
        return body

func rotate_preview():
        if preview_instance:
                preview_instance.rotation.y += rotation_snap

func get_placed_structures() -> Array:
        return placed_structures

func damage_structure(structure: Node3D, damage: float, source: Node = null) -> bool:
        if not is_instance_valid(structure):
                return false
        
        var current_health = structure.get_meta("health", 100)
        var max_health = structure.get_meta("max_health", 100)
        
        current_health = max(0, current_health - damage)
        structure.set_meta("health", current_health)
        
        emit_signal("structure_damaged", structure, damage, current_health)
        
        _update_structure_visual(structure, current_health, max_health)
        
        if current_health <= 0:
                destroy_structure(structure)
                return true
        
        return false

func repair_structure(structure: Node3D, player: Node, amount: float = -1) -> bool:
        if not is_instance_valid(structure):
                return false
        
        var current_health = structure.get_meta("health", 100)
        var max_health = structure.get_meta("max_health", 100)
        
        if current_health >= max_health:
                return false
        
        var structure_type = structure.get_meta("structure_type", "")
        if structure_type == "":
                return false
        
        var part_data = building_parts.get(structure_type, {})
        var cost = part_data.get("cost", {})
        
        var repair_percent = 0.25 if amount < 0 else (amount / max_health)
        var repair_amount = max_health * repair_percent
        
        if current_health + repair_amount > max_health:
                repair_amount = max_health - current_health
                repair_percent = repair_amount / max_health
        
        var inv = get_node_or_null("/root/Inventory")
        if inv:
                for resource in cost.keys():
                        var needed = ceil(cost[resource] * repair_percent * 0.5)
                        if not inv.has_item(resource, int(needed)):
                                return false
                
                for resource in cost.keys():
                        var needed = ceil(cost[resource] * repair_percent * 0.5)
                        inv.remove_item(resource, int(needed))
        
        current_health += repair_amount
        structure.set_meta("health", current_health)
        
        emit_signal("structure_repaired", structure, repair_amount, current_health)
        
        _update_structure_visual(structure, current_health, max_health)
        
        return true

func _update_structure_visual(structure: Node3D, current_health: float, max_health: float):
        var health_percent = current_health / max_health
        
        var mesh_inst = structure.get_node_or_null("MeshInstance3D")
        if not mesh_inst:
                for child in structure.get_children():
                        if child is MeshInstance3D:
                                mesh_inst = child
                                break
        
        if mesh_inst and mesh_inst.material_override:
                var mat = mesh_inst.material_override
                if mat is StandardMaterial3D:
                        if health_percent < 0.3:
                                mat.albedo_color = mat.albedo_color.lerp(Color(0.3, 0.2, 0.1), 0.5)
                        elif health_percent < 0.6:
                                mat.albedo_color = mat.albedo_color.lerp(Color(0.5, 0.4, 0.3), 0.3)

func destroy_structure(structure: Node3D):
        if not is_instance_valid(structure):
                return
        
        var pos = structure.global_position
        
        var vfx = get_node_or_null("/root/VFXManager")
        if vfx and vfx.has_method("spawn_destruction_effect"):
                vfx.spawn_destruction_effect(pos)
        
        var audio = get_node_or_null("/root/AudioManager")
        if audio and audio.has_method("play_destruction"):
                var material = structure.get_meta("structure_type", "wood")
                audio.play_destruction(material, pos)
        
        placed_structures.erase(structure)
        
        emit_signal("build_destroyed", structure)
        
        structure.queue_free()

func get_structure_at(position: Vector3, radius: float = 2.0) -> Node3D:
        for structure in placed_structures:
                if is_instance_valid(structure):
                        if structure.global_position.distance_to(position) <= radius:
                                return structure
        return null

func get_nearby_structures(position: Vector3, radius: float) -> Array:
        var result := []
        for structure in placed_structures:
                if is_instance_valid(structure):
                        if structure.global_position.distance_to(position) <= radius:
                                result.append(structure)
        return result

func get_structure_info(structure: Node3D) -> Dictionary:
        if not is_instance_valid(structure):
                return {}
        
        var structure_type = structure.get_meta("structure_type", "unknown")
        var current_health = structure.get_meta("health", 0)
        var max_health = structure.get_meta("max_health", 100)
        
        var part_data = building_parts.get(structure_type, {})
        
        return {
                "type": structure_type,
                "health": current_health,
                "max_health": max_health,
                "health_percent": (current_health / max_health) * 100 if max_health > 0 else 0,
                "material": part_data.get("material", "unknown"),
                "position": structure.global_position
        }

func upgrade_structure(structure: Node3D, player: Node) -> bool:
        if not is_instance_valid(structure):
                return false
        
        var current_type = structure.get_meta("structure_type", "")
        
        var upgrade_paths := {
                "wooden_wall": "stone_wall",
                "wooden_foundation": "stone_foundation",
                "wooden_floor": "stone_floor",
                "stone_wall": "metal_wall",
                "metal_door": "armored_door",
                "workbench_1": "workbench_2",
                "workbench_2": "workbench_3"
        }
        
        if not upgrade_paths.has(current_type):
                return false
        
        var upgrade_to = upgrade_paths[current_type]
        var part_data = building_parts.get(upgrade_to, {})
        var cost = part_data.get("cost", {})
        
        var inv = get_node_or_null("/root/Inventory")
        if not inv:
                return false
        
        for resource in cost.keys():
                if not inv.has_item(resource, cost[resource]):
                        return false
        
        for resource in cost.keys():
                inv.remove_item(resource, cost[resource])
        
        var pos = structure.global_position
        var rot = structure.rotation
        
        structure.set_meta("structure_type", upgrade_to)
        structure.set_meta("health", part_data.get("health", 200))
        structure.set_meta("max_health", part_data.get("health", 200))
        
        var material = part_data.get("material", "stone")
        var color = material_colors.get(material, Color(0.5, 0.5, 0.5))
        
        var mesh_inst = structure.get_node_or_null("MeshInstance3D")
        if mesh_inst and mesh_inst.material_override:
                mesh_inst.material_override.albedo_color = color
        
        var vfx = get_node_or_null("/root/VFXManager")
        if vfx and vfx.has_method("spawn_upgrade_effect"):
                vfx.spawn_upgrade_effect(pos)
        
        return true
