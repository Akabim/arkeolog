extends Node2D

func _ready() -> void:
	queue_redraw()

func _draw() -> void:
	var ink = Global.COLOR_INK
	var trunk_color = Color("#5C3A21") # Leather brown
	var leaves_dark = Global.COLOR_OBSTACLES
	var leaves_light = Global.COLOR_BG_GRASS
	var highlight = Global.COLOR_WHITE
	
	# Dimensions of tree: centered at (0, 0)
	# Size: width 64, height 80
	
	# 1. Draw Trunk
	# Trunk Outline
	draw_rect(Rect2(-8, 8, 16, 32), ink)
	# Trunk Fill
	draw_rect(Rect2(-6, 10, 12, 30), trunk_color)
	# Trunk texture details
	draw_line(Vector2(-2, 14), Vector2(-2, 30), ink.lightened(0.2), 1.5)
	draw_line(Vector2(2, 20), Vector2(2, 36), ink.lightened(0.2), 1.5)
	
	# 2. Draw Foliage (overlapping circles, like a large cozy bush)
	# Outlines (drawn first, slightly larger)
	draw_circle(Vector2(0, -18), 26.0, ink)
	draw_circle(Vector2(-16, -6), 22.0, ink)
	draw_circle(Vector2(16, -6), 22.0, ink)
	draw_circle(Vector2(-12, -26), 20.0, ink)
	draw_circle(Vector2(12, -26), 20.0, ink)
	
	# Fills (Dark Green)
	draw_circle(Vector2(0, -18), 24.0, leaves_dark)
	draw_circle(Vector2(-16, -6), 20.0, leaves_dark)
	draw_circle(Vector2(16, -6), 20.0, leaves_dark)
	draw_circle(Vector2(-12, -26), 18.0, leaves_dark)
	draw_circle(Vector2(12, -26), 18.0, leaves_dark)
	
	# Foliage Highlights (Light Green)
	draw_circle(Vector2(-8, -12), 14.0, leaves_light)
	draw_circle(Vector2(8, -12), 14.0, leaves_light)
	draw_circle(Vector2(-4, -28), 12.0, leaves_light)
	draw_circle(Vector2(6, -28), 12.0, leaves_light)
	
	# White sun highlights
	var sun_highlight = Color(highlight.r, highlight.g, highlight.b, 0.3)
	draw_circle(Vector2(-6, -18), 4.0, sun_highlight)
	draw_circle(Vector2(4, -32), 3.0, sun_highlight)
