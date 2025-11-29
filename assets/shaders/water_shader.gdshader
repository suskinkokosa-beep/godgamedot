shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled, diffuse_burley, specular_schlick_ggx;

uniform vec4 shallow_color : source_color = vec4(0.2, 0.5, 0.7, 0.6);
uniform vec4 deep_color : source_color = vec4(0.05, 0.2, 0.4, 0.9);
uniform float wave_speed : hint_range(0.0, 3.0) = 1.0;
uniform float wave_scale : hint_range(0.0, 100.0) = 20.0;
uniform float wave_height : hint_range(0.0, 1.0) = 0.15;
uniform float foam_amount : hint_range(0.0, 1.0) = 0.3;
uniform float refraction_strength : hint_range(0.0, 1.0) = 0.2;

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	
	float wave1 = sin(world_pos.x * wave_scale * 0.1 + TIME * wave_speed);
	float wave2 = sin(world_pos.z * wave_scale * 0.15 + TIME * wave_speed * 1.3);
	float wave3 = cos((world_pos.x + world_pos.z) * wave_scale * 0.05 + TIME * wave_speed * 0.8);
	
	VERTEX.y += (wave1 + wave2 + wave3) * wave_height * 0.33;
	
	float dx = cos(world_pos.x * wave_scale * 0.1 + TIME * wave_speed) * wave_height;
	float dz = cos(world_pos.z * wave_scale * 0.15 + TIME * wave_speed * 1.3) * wave_height;
	NORMAL = normalize(vec3(-dx * 0.5, 1.0, -dz * 0.5));
}

void fragment() {
	float depth_factor = clamp(length(world_pos.xz) * 0.01, 0.0, 1.0);
	vec3 water_color = mix(shallow_color.rgb, deep_color.rgb, depth_factor);
	float alpha = mix(shallow_color.a, deep_color.a, depth_factor);
	
	float fresnel = pow(1.0 - max(dot(NORMAL, VIEW), 0.0), 4.0);
	water_color = mix(water_color, vec3(0.8, 0.9, 1.0), fresnel * 0.4);
	
	float foam = smoothstep(0.6, 0.8, 
		sin(world_pos.x * 50.0 + TIME * 3.0) * 
		sin(world_pos.z * 50.0 + TIME * 2.5) + 0.5
	) * foam_amount;
	water_color = mix(water_color, vec3(1.0), foam);
	
	ALBEDO = water_color;
	ALPHA = alpha;
	ROUGHNESS = 0.05;
	METALLIC = 0.3;
	SPECULAR = 0.8;
}
