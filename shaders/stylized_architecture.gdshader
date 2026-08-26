shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

uniform vec4 base_color : source_color = vec4(0.65, 0.52, 0.38, 1.0);
uniform float surface_roughness : hint_range(0.0, 1.0) = 0.86;
uniform float color_variation : hint_range(0.0, 0.08) = 0.018;

float hash21(vec2 value) {
	value = fract(value * vec2(123.34, 456.21));
	value += dot(value, value + 45.32);
	return fract(value.x * value.y);
}

void fragment() {
	vec2 grain_cell = floor(UV * vec2(48.0, 48.0));
	float grain = hash21(grain_cell) - 0.5;
	ALBEDO = base_color.rgb * (1.0 + grain * color_variation);
	ROUGHNESS = clamp(surface_roughness + grain * 0.035, 0.0, 1.0);
	SPECULAR = 0.22;
}
