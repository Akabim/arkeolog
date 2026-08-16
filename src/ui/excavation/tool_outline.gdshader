shader_type canvas_item;

uniform bool enabled = false;
uniform vec4 outline_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float width : hint_range(0.0, 10.0) = 3.0;

void fragment() {
	vec4 col = texture(TEXTURE, UV);
	if (enabled) {
		if (col.a < 0.1) {
			vec2 size = TEXTURE_PIXEL_SIZE * width;
			float max_a = 0.0;
			max_a = max(max_a, texture(TEXTURE, UV + vec2(0.0, -size.y)).a);
			max_a = max(max_a, texture(TEXTURE, UV + vec2(0.0, size.y)).a);
			max_a = max(max_a, texture(TEXTURE, UV + vec2(-size.x, 0.0)).a);
			max_a = max(max_a, texture(TEXTURE, UV + vec2(size.x, 0.0)).a);
			max_a = max(max_a, texture(TEXTURE, UV + vec2(-size.x, -size.y)).a);
			max_a = max(max_a, texture(TEXTURE, UV + vec2(size.x, -size.y)).a);
			max_a = max(max_a, texture(TEXTURE, UV + vec2(-size.x, size.y)).a);
			max_a = max(max_a, texture(TEXTURE, UV + vec2(size.x, size.y)).a);

			if (max_a > 0.05) {
				COLOR = vec4(outline_color.rgb, max_a * outline_color.a);
			} else {
				COLOR = col;
			}
		} else {
			COLOR = col;
		}
	} else {
		COLOR = col;
	}
}
