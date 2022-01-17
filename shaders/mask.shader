// https://github.com/renpy/renpy/blob/master/renpy/gl2/live2d.py#L88

shader_type canvas_item;
render_mode blend_mix;

uniform sampler2D u_tex_0;

varying vec2 v_mask_coord;

void vertex() {
	v_mask_coord = vec2(VERTEX.x / 2.0 + 0.5, -VERTEX.y / 2.0 + 0.5);
}

void fragment() {
	vec4 color = texture(TEXTURE, UV);
	vec4 mask = texture(u_tex_0, v_mask_coord);
	COLOR = color * mask.a;
}
