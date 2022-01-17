// https://github.com/renpy/renpy/blob/master/renpy/gl2/live2d.py#L88

shader_type spatial;
render_mode blend_mix;

uniform sampler2D u_tex_0;
uniform sampler2D u_tex_1;

varying vec2 v_mask_coord;

void vertex() {
	v_mask_coord = vec2(VERTEX.x / 2.0 + 0.5, VERTEX.y / 2.0 + 0.5);
}

void fragment() {
	vec4 color = texture(u_tex_0, UV);
	vec4 mask = texture(u_tex_1, v_mask_coord);
	ALBEDO = color.rgb * (1.0 - mask.a);
	ALPHA = (1.0 - mask.a);
}
