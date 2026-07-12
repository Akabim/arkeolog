extends Node2D

var prompt_type: String = "hold" # "hold" or "click"

func _ready() -> void:
	z_index = 10
	queue_redraw()

func set_prompt_type(type: String) -> void:
	prompt_type = type
	queue_redraw()

func _draw() -> void:
	var ink = Global.COLOR_INK
	var bubble = Global.COLOR_WHITE
	
	# Speech bubble triangle pointing down
	var points = PackedVector2Array([
		Vector2(-4, -6),
		Vector2(0, 0),
		Vector2(4, -6),
		Vector2(-4, -6)
	])
	draw_colored_polygon(points, ink)
	
	# Speech bubble rounded rect outline
	draw_circle(Vector2(-10, -16), 10.0, ink)
	draw_circle(Vector2(10, -16), 10.0, ink)
	draw_rect(Rect2(-10, -26, 20, 20), ink)
	
	# Speech bubble rounded rect fill
	draw_circle(Vector2(-10, -16), 8.0, bubble)
	draw_circle(Vector2(10, -16), 8.0, bubble)
	draw_rect(Rect2(-10, -24, 20, 16), bubble)
	
	# Draw Mouse Icon inside the bubble
	# Mouse body outline
	draw_rect(Rect2(-5, -22, 10, 13), ink, false, 1.5)
	
	# Divider lines for buttons
	draw_line(Vector2(0, -22), Vector2(0, -16), ink, 1.0)
	draw_line(Vector2(-5, -16), Vector2(5, -16), ink, 1.0)
	
	# Highlight left button (filled)
	draw_rect(Rect2(-4.25, -21.25, 3.5, 4.5), ink)

