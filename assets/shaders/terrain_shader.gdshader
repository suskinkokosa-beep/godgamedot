shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform sampler2D grass_albedo : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D grass_normal : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D dirt_albedo : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D dirt_normal : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D rock_albedo : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D rock_normal : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D sand_albedo : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D sand_normal : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D snow_albedo : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D snow_normal : hint_normal, filter_linear_mipmap, repeat_enable;

uniform float texture_scale : hint_range(0.01, 10.0) = 0.1;
uniform float slope_threshold : hint_range(0.0, 1.0) = 0.7;
uniform float slope_blend : hint_range(0.0, 0.5) = 0.15;
uniform float height_blend : hint_range(0.0, 1.0) = 0.3;

uniform float grass_roughness : hint_range(0.0, 1.0) = 0.85;
uniform float dirt_roughness : hint_range(0.0, 1.0) = 0.9;
uniform float rock_roughness : hint_range(0.0, 1.0) = 0.75;
uniform float sand_roughness : hint_range(0.0, 1.0) = 0.95;
uniform float snow_roughness : hint_range(0.0, 1.0) = 0.6;

uniform float ao_strength : hint_range(0.0, 1.0) = 0.3;
uniform float detail_strength : hint_range(0.0, 2.0) = 1.0;

varying vec3 world_pos;
varying vec3 world_normal;
varying float biome_grass;
varying float biome_sand;
varying float biome_snow;
varying float biome_rock;

vec3 triplanar_texture(sampler2D tex, vec3 pos, vec3 normal, float scale) {
	vec3 blend_weights = abs(normal);
	blend_weights = pow(blend_weights, vec3(4.0));
	blend_weights = blend_weights / (blend_weights.x + blend_weights.y + blend_weights.z);
	
	vec3 x_sample = texture(tex, pos.zy * scale).rgb;
	vec3 y_sample = texture(tex, pos.xz * scale).rgb;
	vec3 z_sample = texture(tex, pos.xy * scale).rgb;
	
	return x_sample * blend_weights.x + y_sample * blend_weights.y + z_sample * blend_weights.z;
}

vec3 triplanar_normal(sampler2D tex, vec3 pos, vec3 normal, float scale) {
	vec3 blend_weights = abs(normal);
	blend_weights = pow(blend_weights, vec3(4.0));
	blend_weights = blend_weights / (blend_weights.x + blend_weights.y + blend_weights.z);
	
	vec3 x_sample = texture(tex, pos.zy * scale).rgb * 2.0 - 1.0;
	vec3 y_sample = texture(tex, pos.xz * scale).rgb * 2.0 - 1.0;
	vec3 z_sample = texture(tex, pos.xy * scale).rgb * 2.0 - 1.0;
	
	vec3 x_normal = vec3(0.0, x_sample.y, -x_sample.x);
	vec3 y_normal = vec3(x_sample.x, 0.0, x_sample.y);
	vec3 z_normal = vec3(x_sample.x, -x_sample.y, 0.0);
	
	return normalize(
		x_normal * blend_weights.x + 
		y_normal * blend_weights.y + 
		z_normal * blend_weights.z + 
		normal
	);
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = (MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz;
	
	biome_grass = COLOR.r;
	biome_sand = COLOR.g;
	biome_snow = COLOR.b;
	biome_rock = 1.0 - (biome_grass + biome_sand + biome_snow);
	biome_rock = clamp(biome_rock, 0.0, 1.0);
}

void fragment() {
	vec3 normal = normalize(world_normal);
	float slope = 1.0 - normal.y;
	
	float slope_factor = smoothstep(slope_threshold - slope_blend, slope_threshold + slope_blend, slope);
	
	float detail_scale = texture_scale * 4.0;
	
	vec3 grass_col = triplanar_texture(grass_albedo, world_pos, normal, texture_scale);
	vec3 grass_nrm = triplanar_normal(grass_normal, world_pos, normal, texture_scale);
	
	vec3 dirt_col = triplanar_texture(dirt_albedo, world_pos, normal, texture_scale);
	vec3 dirt_nrm = triplanar_normal(dirt_normal, world_pos, normal, texture_scale);
	
	vec3 rock_col = triplanar_texture(rock_albedo, world_pos, normal, texture_scale);
	vec3 rock_nrm = triplanar_normal(rock_normal, world_pos, normal, texture_scale);
	
	vec3 sand_col = triplanar_texture(sand_albedo, world_pos, normal, texture_scale);
	vec3 sand_nrm = triplanar_normal(sand_normal, world_pos, normal, texture_scale);
	
	vec3 snow_col = triplanar_texture(snow_albedo, world_pos, normal, texture_scale);
	vec3 snow_nrm = triplanar_normal(snow_normal, world_pos, normal, texture_scale);
	
	vec3 base_color = vec3(0.0);
	vec3 base_normal = vec3(0.0, 0.0, 1.0);
	float base_roughness = 0.0;
	
	float total_weight = biome_grass + biome_sand + biome_snow + biome_rock;
	if (total_weight > 0.01) {
		float g = biome_grass / total_weight;
		float s = biome_sand / total_weight;
		float n = biome_snow / total_weight;
		float r = biome_rock / total_weight;
		
		base_color = grass_col * g + sand_col * s + snow_col * n + rock_col * r;
		base_normal = grass_nrm * g + sand_nrm * s + snow_nrm * n + rock_nrm * r;
		base_roughness = grass_roughness * g + sand_roughness * s + snow_roughness * n + rock_roughness * r;
	} else {
		base_color = grass_col;
		base_normal = grass_nrm;
		base_roughness = grass_roughness;
	}
	
	base_color = mix(base_color, rock_col, slope_factor);
	base_normal = mix(base_normal, rock_nrm, slope_factor);
	base_roughness = mix(base_roughness, rock_roughness, slope_factor);
	
	vec3 dirt_detail = triplanar_texture(dirt_albedo, world_pos, normal, detail_scale);
	base_color = mix(base_color, base_color * dirt_detail * 1.5, 0.15 * detail_strength);
	
	float ao = 1.0 - (slope * ao_strength);
	base_color *= ao;
	
	ALBEDO = base_color;
	NORMAL_MAP = base_normal * 0.5 + 0.5;
	ROUGHNESS = base_roughness;
	METALLIC = 0.0;
}
