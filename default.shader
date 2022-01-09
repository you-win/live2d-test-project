// NOTE: Shader automatically converted from Godot Engine 3.4.2.stable's CanvasItemMaterial.

shader_type canvas_item;
render_mode unshaded;

void fragment() {
	COLOR = texture(TEXTURE, UV);
}
