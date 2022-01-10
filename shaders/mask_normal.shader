shader_type canvas_item;
render_mode blend_mix;

varying vec4 v_clip_pos;

// Vertex
//uniform vec4 a_position; // Use VERTEX instead
//uniform vec2 a_tex_coord; // Use UV instead
uniform mat4 u_matrix;
uniform mat4 u_clip_matrix;

// Fragment
uniform sampler2D s_texture_0;
uniform sampler2D s_texture_1;
uniform vec4 u_channel_flag;
uniform vec4 u_base_color;

void vertex() {
	VERTEX = (u_matrix * vec4(VERTEX.x, VERTEX.y, 0, 0)).xy;
	v_clip_pos = (u_clip_matrix * vec4(VERTEX.x, VERTEX.y, 0, 0));
	UV.y = 1.0 - UV.y;
}

void fragment() {
	vec4 col_for_mask = texture(s_texture_0, UV) * u_base_color;
	col_for_mask.rgb *= col_for_mask.a;
	vec4 clip_mask = (1.0 - texture(s_texture_1, v_clip_pos.xy / v_clip_pos.w)) * u_channel_flag;
	float mask_val = clip_mask.r + clip_mask.g + clip_mask.b + clip_mask.a;
	col_for_mask *= mask_val;
	COLOR = col_for_mask;
}
