extends Node
class_name TerrainMaterialGenerator

const _TerrainTextures = preload("res://scripts/world/terrain_textures.gd")

static var _cached_material: ShaderMaterial = null
static var _textures_generated := false

static func get_terrain_material() -> ShaderMaterial:
        if _cached_material != null:
                return _cached_material
        
        _cached_material = ShaderMaterial.new()
        
        var shader_path = "res://assets/shaders/terrain_shader.gdshader"
        if ResourceLoader.exists(shader_path):
                _cached_material.shader = load(shader_path)
        else:
                _cached_material.shader = _create_fallback_shader()
        
        _generate_and_assign_textures()
        
        _cached_material.set_shader_parameter("texture_scale", 0.08)
        _cached_material.set_shader_parameter("slope_threshold", 0.65)
        _cached_material.set_shader_parameter("slope_blend", 0.2)
        _cached_material.set_shader_parameter("ao_strength", 0.25)
        _cached_material.set_shader_parameter("detail_strength", 0.8)
        
        return _cached_material

static func _generate_and_assign_textures():
        if _textures_generated:
                return
        
        _cached_material.set_shader_parameter("grass_albedo", _TerrainTextures.create_grass_albedo())
        _cached_material.set_shader_parameter("grass_normal", _TerrainTextures.create_grass_normal())
        _cached_material.set_shader_parameter("dirt_albedo", _TerrainTextures.create_dirt_albedo())
        _cached_material.set_shader_parameter("dirt_normal", _TerrainTextures.create_dirt_normal())
        _cached_material.set_shader_parameter("rock_albedo", _TerrainTextures.create_rock_albedo())
        _cached_material.set_shader_parameter("rock_normal", _TerrainTextures.create_rock_normal())
        _cached_material.set_shader_parameter("sand_albedo", _TerrainTextures.create_sand_albedo())
        _cached_material.set_shader_parameter("sand_normal", _TerrainTextures.create_sand_normal())
        _cached_material.set_shader_parameter("snow_albedo", _TerrainTextures.create_snow_albedo())
        _cached_material.set_shader_parameter("snow_normal", _TerrainTextures.create_snow_normal())
        
        _textures_generated = true

static func _create_fallback_shader() -> Shader:
        var shader = Shader.new()
        shader.code = """
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

void fragment() {
        ALBEDO = COLOR.rgb;
        ROUGHNESS = 0.8;
        METALLIC = 0.0;
}
"""
        return shader

static func get_biome_vertex_color(biome: String) -> Color:
        match biome:
                "forest", "dense_forest", "birch_forest", "maple_forest":
                        return Color(1.0, 0.0, 0.0, 1.0)
                "plains", "meadow", "grassland":
                        return Color(0.9, 0.1, 0.0, 1.0)
                "desert", "dunes", "badlands":
                        return Color(0.0, 1.0, 0.0, 1.0)
                "tundra", "snow_plains", "glacier", "snow_mountain", "frozen_lake":
                        return Color(0.0, 0.0, 1.0, 1.0)
                "mountain", "rocky_mountain", "cliff":
                        return Color(0.0, 0.0, 0.0, 1.0)
                "swamp", "marsh", "bog":
                        return Color(0.5, 0.3, 0.0, 1.0)
                "taiga", "snowy_taiga":
                        return Color(0.7, 0.0, 0.3, 1.0)
                "savanna":
                        return Color(0.6, 0.4, 0.0, 1.0)
                "jungle", "rainforest":
                        return Color(0.8, 0.0, 0.0, 1.0)
                "beach":
                        return Color(0.1, 0.9, 0.0, 1.0)
                _:
                        return Color(0.7, 0.2, 0.0, 1.0)
