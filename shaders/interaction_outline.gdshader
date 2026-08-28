shader_type canvas_item;
render_mode unshaded;

uniform vec4 outline_color : source_color = vec4(0.973, 0.827, 0.318, 1.0);
uniform float outline_width_pixels = 1.35;
uniform sampler2D mask_texture;

float mask_alpha(vec2 uv) {
	return texture(mask_texture, uv).a;
}

void fragment() {
	float center = mask_alpha(UV);
	vec2 texel = outline_width_pixels / vec2(textureSize(mask_texture, 0));
	float neighbour = 0.0;
	neighbour = max(neighbour, mask_alpha(UV + vec2(-texel.x, -texel.y)));
	neighbour = max(neighbour, mask_alpha(UV + vec2( 0.0,     -texel.y)));
	neighbour = max(neighbour, mask_alpha(UV + vec2( texel.x, -texel.y)));
	neighbour = max(neighbour, mask_alpha(UV + vec2(-texel.x,  0.0)));
	neighbour = max(neighbour, mask_alpha(UV + vec2( texel.x,  0.0)));
	neighbour = max(neighbour, mask_alpha(UV + vec2(-texel.x,  texel.y)));
	neighbour = max(neighbour, mask_alpha(UV + vec2( 0.0,      texel.y)));
	neighbour = max(neighbour, mask_alpha(UV + vec2( texel.x,  texel.y)));
	float outside_edge = (1.0 - step(0.01, center)) * step(0.01, neighbour);
	COLOR = vec4(outline_color.rgb, outline_color.a * outside_edge);
}
