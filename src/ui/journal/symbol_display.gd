extends Control

var symbol_char: String = "ha"

func update_symbol(new_symbol: String) -> void:
	symbol_char = new_symbol
	queue_redraw()

func _draw() -> void:
	var ink = Global.COLOR_INK
	var fill = Global.COLOR_WHITE
	var gold = Global.COLOR_GOLD
	
	var r = Rect2(0, 0, size.x, size.y)
	
	# Draw background card
	draw_rect(r, ink)
	draw_rect(Rect2(r.position + Vector2.ONE*2, r.size - Vector2.ONE*4), fill)
	
	# Draw symbol in center of the card
	var center = r.get_center()
	var scale_factor = 2.8
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
			draw_line(center + Vector2(-20, -10), center + Vector2(20, -10), gold, 4.0)
			draw_line(center + Vector2(-15, 0), center + Vector2(15, 0), gold, 4.0)
			draw_line(center + Vector2(-20, 10), center + Vector2(20, 10), gold, 4.0)
			draw_line(center + Vector2(-20, -10), center + Vector2(20, -10), ink, 1.5)
			draw_line(center + Vector2(-15, 0), center + Vector2(15, 0), ink, 1.5)
			draw_line(center + Vector2(-20, 10), center + Vector2(20, 10), ink, 1.5)
			return
		"ka":
			draw_arc(center, 18.0, 0.0, 2*PI, 12, ink, 4.0)
			draw_arc(center, 18.0, 0.0, 2*PI, 12, gold, 2.0)
			draw_line(center + Vector2(-22, 0), center + Vector2(22, 0), ink, 4.0)
			draw_line(center + Vector2(-22, 0), center + Vector2(22, 0), gold, 2.0)
			draw_line(center + Vector2(0, -22), center + Vector2(0, 22), ink, 4.0)
			draw_line(center + Vector2(0, -22), center + Vector2(0, 22), gold, 2.0)
			return
			
	if glyph_points.size() > 0:
		var shifted_points = PackedVector2Array()
		for pt in glyph_points:
			shifted_points.append(center + pt * scale_factor)
		draw_polyline(shifted_points, ink, 5.0, true)
		draw_polyline(shifted_points, gold, 3.0, true)
