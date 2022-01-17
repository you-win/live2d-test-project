shader_type canvas_item;
render_mode blend_mix;

uniform sampler2D u_tex_0;
uniform sampler2D u_tex_1;

varying vec2 v_mask_coord;

void vertex() {
	VERTEX.xy = vec2(VERTEX.x / 2.0 + .5, -VERTEX.y / 2.0 + .5);
}
