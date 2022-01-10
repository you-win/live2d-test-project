shader_type spatial;
render_mode blend_mix;

uniform sampler2D u_texture_0;
uniform vec4 u_base_color;

void fragment() {
	vec4 color = texture(u_texture_0, UV) * u_base_color;
	ALBEDO = color.rgb * color.a;
	ALPHA = color.a;
}
