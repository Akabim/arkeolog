extends Node2D

func _ready() -> void:
	queue_redraw()

func _draw() -> void:
	var ink = Global.COLOR_INK
	var fill = Global.COLOR_OBSTACLES
	var highlight = Global.COLOR_BG_GRASS
	
	# Draw a cluster of 3 circles to make a cozy, fluffy bush
	# Black Outlines (drawn first)
	draw_circle(Vector2(0, 4), 16.0, ink)
	draw_circle(Vector2(-10, -3), 13.0, ink)
	draw_circle(Vector2(10, -3), 13.0, ink)
	
	# Fills
	draw_circle(Vector2(0, 4), 14.0, fill)
	draw_circle(Vector2(-10, -3), 11.0, fill)
	draw_circle(Vector2(10, -3), 11.0, fill)
	
	# Highlights (leaf details inside)
	draw_circle(Vector2(-6, -6), 5.0, highlight)
	draw_circle(Vector2(4, -5), 6.0, highlight)
	draw_circle(Vector2(0, 4), 6.0, highlight)
	
	# Small details/outlines for highlights
	draw_circle(Vector2(-6, -6), 3.0, fill)
	draw_circle(Vector2(4, -5), 4.0, fill)
