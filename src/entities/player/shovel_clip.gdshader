shader_type canvas_item;

uniform float clip_amount : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec4 col = texture(TEXTURE, UV);
	if (clip_amount > 0.01 && UV.x < (0.12 + clip_amount * 0.25) && UV.y > (0.85 - clip_amount * 0.20)) {
		col.a = 0.0;
	}
	COLOR = col;
}
