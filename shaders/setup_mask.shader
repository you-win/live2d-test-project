shader_type canvas_item;
render_mode blend_mix;

// Vertex
varying vec4 v_my_pos;
uniform mat4 u_clip_matrix;

// Fragment
uniform sampler2D s_texture_0;
uniform vec4 u_channel_flag;
uniform vec4 u_base_color;

void vertex() {
	VERTEX = (u_clip_matrix * vec4(VERTEX.x, VERTEX.y, 0, 0)).xy;
	v_my_pos = (u_clip_matrix * vec4(VERTEX.x, VERTEX.y, 0, 0));
	UV.y = 1.0 - UV.y;
}

void fragment() {
	float is_inside = 
		step(u_base_color.x, v_my_pos.x / v_my_pos.w) *
		step(u_base_color.y, v_my_pos.y / v_my_pos.w) *
		step(v_my_pos.x / v_my_pos.w, u_base_color.z) *
		step(v_my_pos.y / v_my_pos.w, u_base_color.w);
	COLOR = u_channel_flag * texture(s_texture_0, UV).a * is_inside;
}
