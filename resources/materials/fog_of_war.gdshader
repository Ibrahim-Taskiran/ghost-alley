shader_type spatial;
render_mode unshaded, depth_draw_never, cull_disabled;

uniform sampler2D fog_texture : filter_linear, repeat_disable;
uniform vec4 fog_color : source_color = vec4(0.08, 0.08, 0.1, 0.95);
uniform vec4 explored_color : source_color = vec4(0.05, 0.05, 0.08, 0.5);

void fragment() {
	// Sample the fog texture using UV coords
	vec4 mask = texture(fog_texture, UV);
	
	// mask.r = currently visible (1.0 = fully visible, 0.0 = not currently visible)
	// mask.g = explored (1.0 = explored, 0.0 = unexplored)
	
	float is_visible = mask.r;
	float is_explored = mask.g;
	
	vec4 final_color = fog_color;
	
	if (is_visible > 0.05) {
		// Currently visible - blend out the fog
		discard;
	} else if (is_explored > 0.05) {
		// Explored but out of sight - semi-transparent mist
		final_color = explored_color;
	} else {
		// Completely unexplored
		final_color = fog_color;
	}
	
	ALBEDO = final_color.rgb;
	ALPHA = final_color.a;
}
