shader_type spatial;
render_mode blend_mix;

uniform mat4 u_matrix;

void vertex() {
	UV.y = 1.0 - UV.y;
}
