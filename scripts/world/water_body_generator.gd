extends Node

var world_gen
var lakes := []
var rivers := []

const MIN_LAKE_SIZE := 15.0
const MAX_LAKE_SIZE := 80.0
const RIVER_WIDTH := 8.0

func _ready():
        world_gen = get_node_or_null("/root/WorldGenerator")

func generate_lake(center: Vector3, size: float, rng: RandomNumberGenerator) -> Node3D:
        var lake = Node3D.new()
        lake.name = "Lake"
        lake.position = center
        
        var water_mesh = MeshInstance3D.new()
        water_mesh.name = "WaterSurface"
        
        var plane = PlaneMesh.new()
        plane.size = Vector2(size, size * rng.randf_range(0.7, 1.3))
        plane.subdivide_width = 8
        plane.subdivide_depth = 8
        water_mesh.mesh = plane
        
        var sea_level = 0.0
        if world_gen:
                sea_level = world_gen.SEA_LEVEL
        
        water_mesh.position.y = sea_level
        
        var mat = StandardMaterial3D.new()
        mat.albedo_color = Color(0.15, 0.35, 0.55, 0.75)
        mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
        mat.metallic = 0.2
        mat.roughness = 0.1
        mat.cull_mode = BaseMaterial3D.CULL_DISABLED
        water_mesh.material_override = mat
        
        lake.add_child(water_mesh)
        
        var area = Area3D.new()
        area.name = "WaterArea"
        
        var col = CollisionShape3D.new()
        var box = BoxShape3D.new()
        box.size = Vector3(plane.size.x, 2.0, plane.size.y)
        col.shape = box
        col.position.y = sea_level - 1.0
        area.add_child(col)
        
        area.add_to_group("water")
        lake.add_child(area)
        
        lakes.append({"center": center, "size": size, "node": lake})
        
        return lake

func generate_river_segment(start: Vector3, end: Vector3, width: float) -> Node3D:
        var river = Node3D.new()
        river.name = "RiverSegment"
        
        var direction = end - start
        var length = direction.length()
        direction = direction.normalized()
        
        var center = (start + end) * 0.5
        river.position = center
        
        var water_mesh = MeshInstance3D.new()
        water_mesh.name = "WaterSurface"
        
        var plane = PlaneMesh.new()
        plane.size = Vector2(width, length)
        plane.subdivide_width = 2
        plane.subdivide_depth = int(length / 4.0)
        water_mesh.mesh = plane
        
        var sea_level = 0.0
        if world_gen:
                sea_level = world_gen.SEA_LEVEL
        
        water_mesh.position.y = sea_level - 0.5
        water_mesh.rotation.y = atan2(direction.x, direction.z)
        
        var mat = StandardMaterial3D.new()
        mat.albedo_color = Color(0.2, 0.4, 0.6, 0.7)
        mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
        mat.metallic = 0.15
        mat.roughness = 0.15
        mat.cull_mode = BaseMaterial3D.CULL_DISABLED
        water_mesh.material_override = mat
        
        river.add_child(water_mesh)
        
        var area = Area3D.new()
        area.name = "WaterArea"
        
        var col = CollisionShape3D.new()
        var box = BoxShape3D.new()
        box.size = Vector3(width, 1.5, length)
        col.shape = box
        col.position.y = sea_level - 0.75
        col.rotation.y = water_mesh.rotation.y
        area.add_child(col)
        
        area.add_to_group("water")
        river.add_child(area)
        
        return river

func get_lakes_in_area(center: Vector3, radius: float) -> Array:
        var result := []
        for lake_data in lakes:
                if lake_data["center"].distance_to(center) <= radius + lake_data["size"]:
                        result.append(lake_data)
        return result

func is_in_water(pos: Vector3) -> bool:
        for lake_data in lakes:
                var dist = Vector2(pos.x, pos.z).distance_to(Vector2(lake_data["center"].x, lake_data["center"].z))
                if dist <= lake_data["size"] * 0.5:
                        return true
        
        if world_gen:
                var biome = world_gen.get_biome_at(pos.x, pos.z)
                if world_gen.is_water_biome(biome):
                        return true
        
        return false

func get_water_depth(pos: Vector3) -> float:
        if not world_gen:
                return 0.0
        
        var height = world_gen.get_height_at(pos.x, pos.z)
        var sea_level = world_gen.SEA_LEVEL
        
        if height < sea_level:
                return sea_level - height
        
        return 0.0
