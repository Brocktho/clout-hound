shader_type spatial;

// The texture you baked in Blender
uniform sampler2D albedo_texture : source_color, filter_nearest;
// How much the vertices should "snap" (lower = more jitter)
uniform float jitter_intensity : hint_range(0.01, 1.0) = 0.5;

void vertex() {
	// 1. Move vertex to View Space
	vec4 v = MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
	// 2. Project it to Screen/Clip Space
	v = PROJECTION_MATRIX * v;
	
	// 3. The Jitter Logic
	// We determine a grid size based on jitter_intensity.
	// 200.0 is a good baseline for that "low-res" feel.
	float grid_size = 200.0 * (1.0 - jitter_intensity + 0.01);
	
	// Snap the X and Y coordinates to the grid
	v.xy /= v.w;
	v.xy = floor(v.xy * grid_size) / grid_size;
	v.xy *= v.w;
	
	// 4. Output the snapped position
	POSITION = v;
}

void fragment() {
	// Simply display your baked texture
	vec4 tex = texture(albedo_texture, UV);
	ALBEDO = tex.rgb;
}