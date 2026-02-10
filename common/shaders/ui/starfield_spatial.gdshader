shader_type spatial;
render_mode unshaded, cull_front, depth_draw_always;

uniform float star_density = 0.035;
uniform float star_scale = 140.0;
uniform float drift_speed = 0.01;
uniform vec3 base_color = vec3(0.02, 0.03, 0.05);
uniform vec3 star_color = vec3(0.9, 0.95, 1.0);

float hash12(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

void fragment() {
	vec2 uv = UV;
	uv += vec2(drift_speed, -drift_speed * 0.6) * TIME;

	vec2 id = floor(uv * star_scale);
	vec2 gv = fract(uv * star_scale) - 0.5;

	float n = hash12(id);
	float star = step(1.0 - star_density, n);
	float radius = mix(0.02, 0.08, hash12(id + 1.7));
	float dist = length(gv);
	float glow = smoothstep(radius, 0.0, dist);
	float twinkle = 0.6 + 0.4 * sin(TIME * 2.0 + n * 6.28318);

	float intensity = star * glow * twinkle;
	ALBEDO = base_color + star_color * intensity;
}
