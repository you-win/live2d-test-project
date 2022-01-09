shader_type canvas_item;
render_mode blend_mix;

uniform sampler2D tex;

void fragment() {
	COLOR = texture(tex, UV);
}
