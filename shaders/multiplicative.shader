shader_type canvas_item;
render_mode blend_mul;

void fragment() {
	COLOR = texture(TEXTURE, UV);
}
