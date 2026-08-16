shader_type canvas_item;

uniform float sway_speed : hint_range(0.1, 5.0) = 1.5;
uniform float sway_strength : hint_range(0.0, 20.0) = 4.0;
uniform float sway_offset : hint_range(0.0, 6.28) = 0.0;

void vertex() {
	VERTEX.x += sin(TIME * sway_speed + sway_offset) * sway_strength * (1.0 - UV.y);
}
