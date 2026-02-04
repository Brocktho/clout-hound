shader_type spatial;
render_mode cull_front, unshaded;

uniform vec4 outline_color : source_color = vec4(0, 1, 0, 1);
uniform float outline_width = 1.0;

void vertex() {
	VERTEX += NORMAL * outline_width * 0.01;
}

void fragment() {
	ALBEDO = outline_color.rgb;
}
