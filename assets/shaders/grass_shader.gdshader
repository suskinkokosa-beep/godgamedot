shader_type spatial;
render_mode cull_disabled, depth_draw_opaque;

uniform vec4 top_color : source_color = vec4(0.3, 0.6, 0.2, 1.0);
uniform vec4 bottom_color : source_color = vec4(0.15, 0.3, 0.1, 1.0);
uniform float wind_strength : hint_range(0.0, 1.0) = 0.3;
uniform float wind_speed : hint_range(0.0, 5.0) = 1.5;
uniform float wind_scale : hint_range(0.0, 50.0) = 10.0;
uniform float sway_amount : hint_range(0.0, 2.0) = 0.5;

varying float height_factor;

void vertex() {
	height_factor = clamp(VERTEX.y * 2.0, 0.0, 1.0);
	
	float wind_offset = sin(TIME * wind_speed + VERTEX.x * wind_scale) * 
	                    cos(TIME * wind_speed * 0.7 + VERTEX.z * wind_scale * 0.8);
	
	float sway = wind_offset * wind_strength * height_factor * sway_amount;
	
	VERTEX.x += sway;
	VERTEX.z += sway * 0.5;
}

void fragment() {
	vec3 color = mix(bottom_color.rgb, top_color.rgb, height_factor);
	
	float fresnel = pow(1.0 - dot(NORMAL, VIEW), 2.0);
	color += vec3(0.1, 0.15, 0.05) * fresnel;
	
	ALBEDO = color;
	ROUGHNESS = 0.9;
	METALLIC = 0.0;
	
	float ao = mix(0.5, 1.0, height_factor);
	AO = ao;
	AO_LIGHT_AFFECT = 0.4;
}
