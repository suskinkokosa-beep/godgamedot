extends Node

signal build_placed(item_id, position, rotation)
signal build_destroyed(structure)

var preview_instance = null
var current_part := ""
var snap_size := 2.0
var is_building := false
var placed_structures := []

var building_parts := {
        "wooden_foundation": {"scene": "foundation", "material": "wood", "health": 200, "cost": {"wood": 50}},
        "wooden_wall": {"scene": "wall", "material": "wood", "health": 150, "cost": {"wood": 30}},
        "wooden_floor": {"scene": "floor", "material": "wood", "health": 100, "cost": {"wood": 25}},
        "wooden_door": {"scene": "door_frame", "material": "wood", "health": 100, "cost": {"wood": 40}},
        "stone_foundation": {"scene": "foundation", "material": "stone", "health": 500, "cost": {"stone": 100}},
        "stone_wall": {"scene": "wall", "material": "stone", "health": 400, "cost": {"stone": 60}},
        "metal_door": {"scene": "door_frame", "material": "metal", "health": 300, "cost": {"iron_ingot": 10}}
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
                preview_instance.rotation.y += PI / 2

func get_placed_structures() -> Array:
        return placed_structures
