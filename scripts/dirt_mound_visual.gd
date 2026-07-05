extends Node2D

func _ready() -> void:
	queue_redraw()

func _draw() -> void:
	var ink = Global.COLOR_INK
	var dirt = Global.COLOR_DIRT
	var stone = Global.COLOR_STONE
	
	# 1. Dirt Mound Outline (cluster of circles)
	draw_circle(Vector2(0, 4), 22.0, ink)
	draw_circle(Vector2(-14, 6), 16.0, ink)
	draw_circle(Vector2(14, 6), 16.0, ink)
	
	# Fills
	draw_circle(Vector2(0, 4), 20.0, dirt)
	draw_circle(Vector2(-14, 6), 14.0, dirt)
	draw_circle(Vector2(14, 6), 14.0, dirt)
	
	# 2. Rubble/Pebbles sticking out (ancient relic hints)
	# Stone 1 Outline
	draw_circle(Vector2(-6, -6), 6.0, ink)
	# Stone 2 Outline
	draw_circle(Vector2(8, -2), 7.0, ink)
	
	# Stone Fills
	draw_circle(Vector2(-6, -6), 4.5, stone)
	draw_circle(Vector2(8, -2), 5.5, stone)
	
	# Shading details (darker dirt strokes)
	draw_line(Vector2(-16, 12), Vector2(16, 12), ink, 2.0)
	draw_line(Vector2(-10, 10), Vector2(10, 10), dirt.darkened(0.2), 3.0)
