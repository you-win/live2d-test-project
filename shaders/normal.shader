shader_type canvas_item;
render_mode blend_mix;

// Vertex
varying vec2 v_tex_coord;
uniform mat4 u_matrix;

// Fragment
uniform sampler2D s_texture_0;
uniform vec4 u_base_color;

void vertex() {
	VERTEX = (u_matrix * vec4(VERTEX.x, VERTEX.y, 0, 0)).xy;
	UV.y = 1.0 - UV.y;
}

void fragment() {
	vec4 color = texture(s_texture_0, UV) * u_base_color;
	COLOR = vec4(color.rgb * color.a, color.a);
}
