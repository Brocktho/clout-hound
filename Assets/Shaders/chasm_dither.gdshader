shader_type spatial;
render_mode unshaded, cull_back;

uniform vec3 top_color : source_color = vec3(0.12, 0.14, 0.16);
uniform vec3 bottom_color : source_color = vec3(0.02, 0.02, 0.03);
uniform vec2 half_size = vec2(5.0, 5.0);
uniform float bottom_depth = 12.0;
uniform float curve_power = 2.0;
uniform float dither_scale = 1.0;
uniform float dither_strength = 1.0;
uniform float banding_levels = 6.0;

varying float v_depth;

float bayer4x4(vec2 pos) {
	int x = int(mod(pos.x, 4.0));
	int y = int(mod(pos.y, 4.0));
	int index = x + y * 4;
	float value = 0.0;

	if (index == 0) {
		value = 0.0;
	} else if (index == 1) {
		value = 8.0;
	} else if (index == 2) {
		value = 2.0;
	} else if (index == 3) {
		value = 10.0;
	} else if (index == 4) {
		value = 12.0;
	} else if (index == 5) {
		value = 4.0;
	} else if (index == 6) {
		value = 14.0;
	} else if (index == 7) {
		value = 6.0;
	} else if (index == 8) {
		value = 3.0;
	} else if (index == 9) {
		value = 11.0;
	} else if (index == 10) {
		value = 1.0;
	} else if (index == 11) {
		value = 9.0;
	} else if (index == 12) {
		value = 15.0;
	} else if (index == 13) {
		value = 7.0;
	} else if (index == 14) {
		value = 13.0;
	} else {
		value = 5.0;
	}

	return value / 16.0;
}

void vertex() {
	vec2 size = max(half_size, vec2(0.001));
	vec2 norm = vec2(VERTEX.x / size.x, VERTEX.z / size.y);
	float dist = clamp(length(norm), 0.0, 1.0);
	float power = max(curve_power, 0.01);
	float curve = 1.0 - pow(dist, power);

	VERTEX.y -= bottom_depth * curve;
	v_depth = clamp(pow(dist, power), 0.0, 1.0);
}

void fragment() {
	vec3 base = mix(bottom_color, top_color, v_depth);
	float levels = max(banding_levels, 1.0);
	vec2 viewport = max(VIEWPORT_SIZE, vec2(1.0));
	vec2 pixel = SCREEN_UV * viewport;
	float threshold = bayer4x4(pixel * max(dither_scale, 0.01));
	vec3 quantized = floor(base * levels + threshold * dither_strength) / levels;
	ALBEDO = clamp(quantized, 0.0, 1.0);
}
