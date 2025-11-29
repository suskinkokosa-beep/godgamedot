extends Node
class_name MobModelGenerator

static var model_cache := {}

static func create_mob_model(mob_type: String) -> Node3D:
        var root = Node3D.new()
        root.name = mob_type.capitalize() + "Model"
        
        var mesh_path = "res://assets/art_pack/models/animals/%s.obj" % mob_type
        var mesh: Mesh = null
        
        if model_cache.has(mob_type):
                mesh = model_cache[mob_type]
        elif ResourceLoader.exists(mesh_path):
                mesh = load(mesh_path)
                model_cache[mob_type] = mesh
        
        if mesh:
                var mesh_inst = MeshInstance3D.new()
                mesh_inst.mesh = mesh
                mesh_inst.name = "MeshInstance"
                
                var mat = _create_mob_material(mob_type)
                mesh_inst.material_override = mat
                
                _apply_mob_scale(mesh_inst, mob_type)
                root.add_child(mesh_inst)
        else:
                var procedural = _create_procedural_mob(mob_type)
                root.add_child(procedural)
        
        return root

static func _apply_mob_scale(mesh_inst: MeshInstance3D, mob_type: String):
        match mob_type:
                "wolf":
                        mesh_inst.scale = Vector3(0.8, 0.8, 0.8)
                "bear":
                        mesh_inst.scale = Vector3(1.5, 1.5, 1.5)
                "boar":
                        mesh_inst.scale = Vector3(0.9, 0.9, 0.9)
                "deer":
                        mesh_inst.scale = Vector3(1.0, 1.0, 1.0)
                _:
                        mesh_inst.scale = Vector3(1.0, 1.0, 1.0)

static func _create_mob_material(mob_type: String) -> StandardMaterial3D:
        var mat = StandardMaterial3D.new()
        mat.diffuse_mode = BaseMaterial3D.DIFFUSE_BURLEY
        mat.specular_mode = BaseMaterial3D.SPECULAR_SCHLICK_GGX
        mat.roughness = 0.85
        mat.metallic = 0.0
        
        match mob_type:
                "wolf":
                        mat.albedo_color = Color(0.4, 0.4, 0.42)
                "bear":
                        mat.albedo_color = Color(0.35, 0.25, 0.2)
                "boar":
                        mat.albedo_color = Color(0.45, 0.35, 0.3)
                "deer":
                        mat.albedo_color = Color(0.55, 0.4, 0.3)
                "rabbit":
                        mat.albedo_color = Color(0.6, 0.55, 0.5)
                "lion":
                        mat.albedo_color = Color(0.7, 0.55, 0.35)
                "spider":
                        mat.albedo_color = Color(0.15, 0.12, 0.1)
                        mat.roughness = 0.6
                "snake":
                        mat.albedo_color = Color(0.3, 0.35, 0.25)
                        mat.roughness = 0.5
                _:
                        mat.albedo_color = Color(0.5, 0.45, 0.4)
        
        return mat

static func _create_procedural_mob(mob_type: String) -> Node3D:
        var root = Node3D.new()
        root.name = "ProceduralMesh"
        
        var config = _get_mob_config(mob_type)
        
        var body = _create_body(config)
        root.add_child(body)
        
        if config.has("head"):
                var head = _create_head(config)
                root.add_child(head)
        
        if config.get("legs", 0) > 0:
                var legs = _create_legs(config)
                for leg in legs:
                        root.add_child(leg)
        
        if config.get("tail", false):
                var tail = _create_tail(config)
                root.add_child(tail)
        
        return root

static func _get_mob_config(mob_type: String) -> Dictionary:
        match mob_type:
                "wolf":
                        return {
                                "body_size": Vector3(0.4, 0.35, 0.9),
                                "body_color": Color(0.4, 0.4, 0.42),
                                "head": {"size": Vector3(0.25, 0.22, 0.3), "offset": Vector3(0, 0.1, 0.5)},
                                "legs": 4,
                                "leg_size": Vector3(0.08, 0.35, 0.08),
                                "tail": true,
                                "tail_size": Vector3(0.06, 0.06, 0.35)
                        }
                "bear":
                        return {
                                "body_size": Vector3(0.7, 0.6, 1.2),
                                "body_color": Color(0.35, 0.25, 0.2),
                                "head": {"size": Vector3(0.35, 0.3, 0.35), "offset": Vector3(0, 0.2, 0.65)},
                                "legs": 4,
                                "leg_size": Vector3(0.15, 0.5, 0.15),
                                "tail": false
                        }
                "boar":
                        return {
                                "body_size": Vector3(0.45, 0.4, 0.8),
                                "body_color": Color(0.45, 0.35, 0.3),
                                "head": {"size": Vector3(0.3, 0.25, 0.35), "offset": Vector3(0, 0.05, 0.45)},
                                "legs": 4,
                                "leg_size": Vector3(0.08, 0.3, 0.08),
                                "tail": true,
                                "tail_size": Vector3(0.03, 0.03, 0.12)
                        }
                "deer":
                        return {
                                "body_size": Vector3(0.35, 0.45, 0.9),
                                "body_color": Color(0.55, 0.4, 0.3),
                                "head": {"size": Vector3(0.18, 0.2, 0.3), "offset": Vector3(0, 0.35, 0.5)},
                                "legs": 4,
                                "leg_size": Vector3(0.06, 0.55, 0.06),
                                "tail": true,
                                "tail_size": Vector3(0.05, 0.05, 0.15)
                        }
                "rabbit":
                        return {
                                "body_size": Vector3(0.12, 0.12, 0.2),
                                "body_color": Color(0.6, 0.55, 0.5),
                                "head": {"size": Vector3(0.1, 0.1, 0.12), "offset": Vector3(0, 0.05, 0.12)},
                                "legs": 4,
                                "leg_size": Vector3(0.03, 0.1, 0.03),
                                "tail": true,
                                "tail_size": Vector3(0.04, 0.04, 0.05)
                        }
                "lion":
                        return {
                                "body_size": Vector3(0.5, 0.5, 1.1),
                                "body_color": Color(0.7, 0.55, 0.35),
                                "head": {"size": Vector3(0.35, 0.35, 0.35), "offset": Vector3(0, 0.15, 0.55)},
                                "legs": 4,
                                "leg_size": Vector3(0.1, 0.45, 0.1),
                                "tail": true,
                                "tail_size": Vector3(0.05, 0.05, 0.6)
                        }
                "spider":
                        return {
                                "body_size": Vector3(0.25, 0.15, 0.3),
                                "body_color": Color(0.15, 0.12, 0.1),
                                "head": {"size": Vector3(0.15, 0.12, 0.15), "offset": Vector3(0, 0, 0.2)},
                                "legs": 8,
                                "leg_size": Vector3(0.02, 0.25, 0.02),
                                "tail": false
                        }
                "snake":
                        return {
                                "body_size": Vector3(0.08, 0.08, 1.2),
                                "body_color": Color(0.3, 0.35, 0.25),
                                "head": {"size": Vector3(0.1, 0.06, 0.12), "offset": Vector3(0, 0, 0.6)},
                                "legs": 0,
                                "tail": false
                        }
                "hyena":
                        return {
                                "body_size": Vector3(0.4, 0.4, 0.9),
                                "body_color": Color(0.5, 0.45, 0.4),
                                "head": {"size": Vector3(0.25, 0.22, 0.28), "offset": Vector3(0, 0.1, 0.45)},
                                "legs": 4,
                                "leg_size": Vector3(0.08, 0.4, 0.08),
                                "tail": true,
                                "tail_size": Vector3(0.04, 0.04, 0.3)
                        }
                "elephant":
                        return {
                                "body_size": Vector3(1.2, 1.5, 2.0),
                                "body_color": Color(0.5, 0.5, 0.5),
                                "head": {"size": Vector3(0.6, 0.5, 0.5), "offset": Vector3(0, 0.3, 1.0)},
                                "legs": 4,
                                "leg_size": Vector3(0.25, 1.2, 0.25),
                                "tail": true,
                                "tail_size": Vector3(0.08, 0.08, 0.6)
                        }
                "zebra":
                        return {
                                "body_size": Vector3(0.4, 0.6, 1.2),
                                "body_color": Color(0.9, 0.9, 0.9),
                                "head": {"size": Vector3(0.2, 0.25, 0.35), "offset": Vector3(0, 0.4, 0.6)},
                                "legs": 4,
                                "leg_size": Vector3(0.07, 0.7, 0.07),
                                "tail": true,
                                "tail_size": Vector3(0.05, 0.05, 0.4)
                        }
                "croc":
                        return {
                                "body_size": Vector3(0.4, 0.3, 1.8),
                                "body_color": Color(0.3, 0.35, 0.25),
                                "head": {"size": Vector3(0.25, 0.15, 0.5), "offset": Vector3(0, 0.05, 0.9)},
                                "legs": 4,
                                "leg_size": Vector3(0.1, 0.2, 0.1),
                                "tail": true,
                                "tail_size": Vector3(0.15, 0.1, 0.8)
                        }
                "scorpion":
                        return {
                                "body_size": Vector3(0.2, 0.1, 0.35),
                                "body_color": Color(0.5, 0.4, 0.3),
                                "head": {"size": Vector3(0.12, 0.08, 0.12), "offset": Vector3(0, 0, 0.18)},
                                "legs": 8,
                                "leg_size": Vector3(0.02, 0.15, 0.02),
                                "tail": true,
                                "tail_size": Vector3(0.05, 0.05, 0.4)
                        }
                "goat":
                        return {
                                "body_size": Vector3(0.35, 0.4, 0.7),
                                "body_color": Color(0.6, 0.55, 0.5),
                                "head": {"size": Vector3(0.18, 0.18, 0.22), "offset": Vector3(0, 0.25, 0.35)},
                                "legs": 4,
                                "leg_size": Vector3(0.06, 0.45, 0.06),
                                "tail": true,
                                "tail_size": Vector3(0.04, 0.04, 0.1)
                        }
                "frog":
                        return {
                                "body_size": Vector3(0.12, 0.08, 0.15),
                                "body_color": Color(0.3, 0.5, 0.3),
                                "head": {"size": Vector3(0.1, 0.06, 0.08), "offset": Vector3(0, 0.02, 0.08)},
                                "legs": 4,
                                "leg_size": Vector3(0.03, 0.1, 0.03),
                                "tail": false
                        }
                "bandit":
                        return {
                                "body_size": Vector3(0.35, 0.5, 0.3),
                                "body_color": Color(0.5, 0.35, 0.3),
                                "head": {"size": Vector3(0.2, 0.22, 0.2), "offset": Vector3(0, 0.6, 0)},
                                "legs": 2,
                                "leg_size": Vector3(0.1, 0.8, 0.1),
                                "tail": false
                        }
                "zombie":
                        return {
                                "body_size": Vector3(0.35, 0.5, 0.3),
                                "body_color": Color(0.4, 0.5, 0.35),
                                "head": {"size": Vector3(0.2, 0.22, 0.2), "offset": Vector3(0, 0.55, 0)},
                                "legs": 2,
                                "leg_size": Vector3(0.1, 0.75, 0.1),
                                "tail": false
                        }
                _:
                        return {
                                "body_size": Vector3(0.4, 0.35, 0.6),
                                "body_color": Color(0.5, 0.45, 0.4),
                                "head": {"size": Vector3(0.2, 0.2, 0.25), "offset": Vector3(0, 0.1, 0.35)},
                                "legs": 4,
                                "leg_size": Vector3(0.08, 0.3, 0.08),
                                "tail": false
                        }

static func _create_body(config: Dictionary) -> MeshInstance3D:
        var mesh_inst = MeshInstance3D.new()
        mesh_inst.name = "Body"
        
        var capsule = CapsuleMesh.new()
        capsule.radius = config.body_size.x * 0.5
        capsule.height = config.body_size.z
        mesh_inst.mesh = capsule
        
        mesh_inst.rotation.x = PI / 2
        mesh_inst.position.y = config.body_size.y * 0.5
        
        var mat = StandardMaterial3D.new()
        mat.albedo_color = config.body_color
        mat.roughness = 0.85
        mat.diffuse_mode = BaseMaterial3D.DIFFUSE_BURLEY
        mesh_inst.material_override = mat
        
        return mesh_inst

static func _create_head(config: Dictionary) -> MeshInstance3D:
        var mesh_inst = MeshInstance3D.new()
        mesh_inst.name = "Head"
        
        var head_config = config.head
        var sphere = SphereMesh.new()
        sphere.radius = head_config.size.x
        sphere.height = head_config.size.y * 2
        mesh_inst.mesh = sphere
        
        mesh_inst.position = head_config.offset
        mesh_inst.position.y += config.body_size.y * 0.5
        
        var mat = StandardMaterial3D.new()
        mat.albedo_color = config.body_color
        mat.roughness = 0.85
        mat.diffuse_mode = BaseMaterial3D.DIFFUSE_BURLEY
        mesh_inst.material_override = mat
        
        return mesh_inst

static func _create_legs(config: Dictionary) -> Array:
        var legs := []
        var num_legs = config.legs
        var leg_size = config.leg_size
        var body_size = config.body_size
        
        if num_legs == 4:
                var positions = [
                        Vector3(-body_size.x * 0.4, 0, body_size.z * 0.3),
                        Vector3(body_size.x * 0.4, 0, body_size.z * 0.3),
                        Vector3(-body_size.x * 0.4, 0, -body_size.z * 0.3),
                        Vector3(body_size.x * 0.4, 0, -body_size.z * 0.3)
                ]
                
                for i in range(4):
                        var leg = _create_single_leg(leg_size, config.body_color)
                        leg.position = positions[i]
                        leg.position.y = leg_size.y * 0.5
                        legs.append(leg)
        elif num_legs == 8:
                for i in range(8):
                        var angle = (float(i) / 8.0) * TAU
                        var offset_x = cos(angle) * body_size.x * 0.6
                        var offset_z = sin(angle) * body_size.z * 0.4
                        
                        var leg = _create_single_leg(leg_size, config.body_color)
                        leg.position = Vector3(offset_x, leg_size.y * 0.3, offset_z)
                        leg.rotation.z = angle
                        legs.append(leg)
        
        return legs

static func _create_single_leg(size: Vector3, color: Color) -> MeshInstance3D:
        var mesh_inst = MeshInstance3D.new()
        mesh_inst.name = "Leg"
        
        var cylinder = CylinderMesh.new()
        cylinder.top_radius = size.x * 0.5
        cylinder.bottom_radius = size.x * 0.4
        cylinder.height = size.y
        mesh_inst.mesh = cylinder
        
        var mat = StandardMaterial3D.new()
        mat.albedo_color = color * 0.9
        mat.roughness = 0.85
        mesh_inst.material_override = mat
        
        return mesh_inst

static func _create_tail(config: Dictionary) -> MeshInstance3D:
        var mesh_inst = MeshInstance3D.new()
        mesh_inst.name = "Tail"
        
        var tail_size = config.get("tail_size", Vector3(0.05, 0.05, 0.3))
        
        var cylinder = CylinderMesh.new()
        cylinder.top_radius = tail_size.x * 0.3
        cylinder.bottom_radius = tail_size.x
        cylinder.height = tail_size.z
        mesh_inst.mesh = cylinder
        
        mesh_inst.rotation.x = PI / 2 + 0.3
        mesh_inst.position = Vector3(0, config.body_size.y * 0.5, -config.body_size.z * 0.5 - tail_size.z * 0.3)
        
        var mat = StandardMaterial3D.new()
        mat.albedo_color = config.body_color
        mat.roughness = 0.85
        mesh_inst.material_override = mat
        
        return mesh_inst
