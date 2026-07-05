extends Node2D

var symbol_char: String = "ha"
var is_solved: bool = false
var tolerance_radius: float = 16.0

func _draw() -> void:
	var ink = Global.COLOR_INK
	var gold = Global.COLOR_GOLD
	var stone = Global.COLOR_STONE
	
	var active_color = gold if is_solved else stone.darkened(0.2)
	
	# 1. Draw dashed tolerance circle (faint)
	var radius = tolerance_radius
	var circle_color = Color(gold.r, gold.g, gold.b, 0.3) if is_solved else Color(ink.r, ink.g, ink.b, 0.15)
	
	# Draw dashed circle programmatically
	var points = 16
	for i in range(points):
		var angle_start = (i * 2 * PI) / points
		var angle_end = ((i + 0.5) * 2 * PI) / points
		draw_arc(Vector2.ZERO, radius, angle_start, angle_end, 3, circle_color, 1.0)
		
	# 2. Draw etched socket corners
	var corner_size = 6.0
	var offset = 16.0
	# Top Left
	draw_line(Vector2(-offset, -offset), Vector2(-offset + corner_size, -offset), active_color, 2.0)
	draw_line(Vector2(-offset, -offset), Vector2(-offset, -offset + corner_size), active_color, 2.0)
	# Top Right
	draw_line(Vector2(offset, -offset), Vector2(offset - corner_size, -offset), active_color, 2.0)
	draw_line(Vector2(offset, -offset), Vector2(offset, -offset + corner_size), active_color, 2.0)
	# Bottom Left
	draw_line(Vector2(-offset, offset), Vector2(-offset + corner_size, offset), active_color, 2.0)
	draw_line(Vector2(-offset, offset), Vector2(-offset, offset - corner_size), active_color, 2.0)
	# Bottom Right
	draw_line(Vector2(offset, offset), Vector2(offset - corner_size, offset), active_color, 2.0)
	draw_line(Vector2(offset, offset), Vector2(offset, offset - corner_size), active_color, 2.0)
	
	# Faint background shading
	var shadow_color = Color(active_color.r, active_color.g, active_color.b, 0.05)
	draw_rect(Rect2(-15, -15, 30, 30), shadow_color)
	
	# 3. Draw Faint Hanacaraka symbol etching
	var glyph_points = PackedVector2Array()
	match symbol_char:
		"ha":
			glyph_points = PackedVector2Array([
				Vector2(-8, 8), Vector2(-8, -4), Vector2(-4, -8),
				Vector2(0, -2), Vector2(4, -8), Vector2(8, -4), Vector2(8, 8)
			])
		"na":
			glyph_points = PackedVector2Array([
				Vector2(-8, -8), Vector2(-6, 8), Vector2(-2, -4),
				Vector2(2, 8), Vector2(6, -8), Vector2(8, 0)
			])
		"ca":
			glyph_points = PackedVector2Array([
				Vector2(-8, 0), Vector2(-4, -8), Vector2(4, -8), Vector2(8, 0),
				Vector2(4, 8), Vector2(-4, 8), Vector2(-2, 0), Vector2(2, 0)
			])
		"ra":
			draw_line(Vector2(-8, -4), Vector2(8, -4), active_color, 1.5)
			draw_line(Vector2(-6, 0), Vector2(6, 0), active_color, 1.5)
			draw_line(Vector2(-8, 4), Vector2(8, 4), active_color, 1.5)
			return
		"ka":
			draw_arc(Vector2.ZERO, 7.0, 0.0, 2*PI, 12, active_color, 1.5)
			draw_line(Vector2(-8, 0), Vector2(8, 0), active_color, 1.5)
			draw_line(Vector2(0, -8), Vector2(0, 8), active_color, 1.5)
			return
		_:
			draw_rect(Rect2(-4, -4, 8, 8), active_color)
			return
			
	draw_polyline(glyph_points, active_color, 1.5, true)
