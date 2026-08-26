shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

uniform vec4 tile_color : source_color = vec4(0.58, 0.28, 0.25, 1.0);
uniform vec4 grout_color : source_color = vec4(0.72, 0.50, 0.43, 1.0);
uniform vec4 coral_chip : source_color = vec4(0.70, 0.32, 0.28, 1.0);
uniform vec4 mint_chip : source_color = vec4(0.31, 0.50, 0.46, 1.0);
uniform vec4 cream_chip : source_color = vec4(0.79, 0.69, 0.53, 1.0);

float hash21(vec2 value) {
	value = fract(value * vec2(123.34, 345.45));
	value += dot(value, value + 34.345);
	return fract(value.x * value.y);
}

void fragment() {
	vec2 tiled_uv = UV * vec2(28.0, 37.0);
	vec2 tile_cell = floor(tiled_uv);
	vec2 tile_local = fract(tiled_uv);
	float closest_edge = min(min(tile_local.x, 1.0 - tile_local.x), min(tile_local.y, 1.0 - tile_local.y));
	float grout = 1.0 - smoothstep(0.018, 0.045, closest_edge);

	float tile_variation = hash21(tile_cell) * 0.035 - 0.0175;
	vec3 surface_color = tile_color.rgb + tile_variation;

	vec2 chip_grid = floor(tiled_uv * 9.0);
	vec2 chip_local = fract(tiled_uv * 9.0) - 0.5;
	float chip_seed = hash21(chip_grid);
	float chip_radius = mix(0.045, 0.11, hash21(chip_grid + 7.3));
	float chip = (1.0 - smoothstep(chip_radius, chip_radius + 0.02, length(chip_local))) * step(0.91, chip_seed);
	vec3 chip_color = cream_chip.rgb;
	if (chip_seed < 0.84) {
		chip_color = coral_chip.rgb;
	} else if (chip_seed < 0.93) {
		chip_color = mint_chip.rgb;
	}
	surface_color = mix(surface_color, chip_color, chip * 0.62);
	surface_color = mix(surface_color, grout_color.rgb, grout);

	ALBEDO = surface_color;
	ROUGHNESS = 0.78;
	SPECULAR = 0.24;
}
