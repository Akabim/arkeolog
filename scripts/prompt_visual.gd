extends Node2D

func _ready() -> void:
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
	draw_circle(Vector2(-8, -14), 8.0, ink)
	draw_circle(Vector2(8, -14), 8.0, ink)
	draw_rect(Rect2(-8, -22, 16, 16), ink)
	
	# Speech bubble rounded rect fill
	draw_circle(Vector2(-8, -14), 6.0, bubble)
	draw_circle(Vector2(8, -14), 6.0, bubble)
	draw_rect(Rect2(-8, -20, 16, 12), bubble)
	
	# Draw letter 'E' in pixel art lines
	# Horizontal top
	draw_line(Vector2(-3, -18), Vector2(3, -18), ink, 2.0)
	# Horizontal mid
	draw_line(Vector2(-3, -14), Vector2(1, -14), ink, 2.0)
	# Horizontal bot
	draw_line(Vector2(-3, -10), Vector2(3, -10), ink, 2.0)
	# Vertical spine
	draw_line(Vector2(-3, -18), Vector2(-3, -10), ink, 2.0)
