shader_type spatial;
render_mode unshaded, cull_front, depth_draw_opaque;

uniform vec4 outline_color : source_color = vec4(0.035, 0.028, 0.025, 1.0);
uniform float outline_width = 0.014;
uniform float wobble = 0.10;

float hash31(vec3 p) {
    return fract(sin(dot(p, vec3(12.9898, 78.233, 37.719))) * 43758.5453);
}

void vertex() {
    float n = hash31(floor(VERTEX * 18.0));
    float width = outline_width * mix(1.0 - wobble, 1.0 + wobble, n);
    VERTEX += NORMAL * width;
}

void fragment() {
    if (IN_SHADOW_PASS) {
        discard;
    }
    ALBEDO = outline_color.rgb;
    ALPHA = outline_color.a;
}
