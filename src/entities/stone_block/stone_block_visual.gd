extends Node2D

var symbol_char: String = "ha"

func update_symbol(new_symbol: String) -> void:
	symbol_char = new_symbol
	queue_redraw()

func _draw() -> void:
	var ink = Global.COLOR_INK
	var stone = Global.COLOR_STONE
	var gold = Global.COLOR_GOLD
	var highlight = Global.COLOR_WHITE
	
	# 1. Main Stone Block Outline (chunky, rounded corners)
	draw_rect(Rect2(-18, -18, 36, 36), ink)
	
	# Main Stone Block Fill
	draw_rect(Rect2(-16, -16, 32, 32), stone)
	
	# Bevel/Highlight edges (top and left sides)
	draw_line(Vector2(-15, -15), Vector2(15, -15), highlight, 1.0)
	draw_line(Vector2(-15, -15), Vector2(-15, 15), highlight, 1.0)
	
	# Shading/Darker edges (bottom and right sides)
	draw_line(Vector2(-15, 15), Vector2(15, 15), ink, 1.0)
	draw_line(Vector2(15, -15), Vector2(15, 15), ink, 1.0)
	
	# Cracks/Texture details (to make it look ancient)
	draw_line(Vector2(-12, -8), Vector2(-8, -12), ink.lightened(0.2), 1.0)
	draw_line(Vector2(-8, -12), Vector2(-4, -12), ink.lightened(0.2), 1.0)
	draw_line(Vector2(10, 8), Vector2(14, 12), ink.lightened(0.2), 1.0)
	
	# 2. Engraved Hanacaraka Symbol (Gold)
	# Draw gold glyphs based on symbol_char
	var glyph_points = PackedVector2Array()
	
	match symbol_char:
		"ha":
			# An 'M' with rounded humps
			glyph_points = PackedVector2Array([
				Vector2(-8, 8),
				Vector2(-8, -4),
				Vector2(-4, -8),
				Vector2(0, -2),
				Vector2(4, -8),
				Vector2(8, -4),
				Vector2(8, 8)
			])
		"na":
			# A 'W' shape with a loop
			glyph_points = PackedVector2Array([
				Vector2(-8, -8),
				Vector2(-6, 8),
				Vector2(-2, -4),
				Vector2(2, 8),
				Vector2(6, -8),
				Vector2(8, 0)
			])
		"ca":
			# A spiral or eye-like shape
			glyph_points = PackedVector2Array([
				Vector2(-8, 0),
				Vector2(-4, -8),
				Vector2(4, -8),
				Vector2(8, 0),
				Vector2(4, 8),
				Vector2(-4, 8),
				Vector2(-2, 0),
				Vector2(2, 0)
			])
		"ra":
			# Parallel wavy horizontal lines
			draw_line(Vector2(-8, -4), Vector2(8, -4), gold, 2.0)
			draw_line(Vector2(-6, 0), Vector2(6, 0), gold, 2.0)
			draw_line(Vector2(-8, 4), Vector2(8, 4), gold, 2.0)
			return
		"ka":
			# Circle with a cross inside
			draw_arc(Vector2.ZERO, 7.0, 0.0, 2*PI, 12, gold, 2.0)
			draw_line(Vector2(-8, 0), Vector2(8, 0), gold, 2.0)
			draw_line(Vector2(0, -8), Vector2(0, 8), gold, 2.0)
			return
		_:
			# Default placeholder square/cross
			draw_rect(Rect2(-4, -4, 8, 8), gold)
			return
			
	# Draw the polyline glyph
	draw_polyline(glyph_points, ink, 3.5, true) # dark outline behind gold
	draw_polyline(glyph_points, gold, 2.0, true) # golden glyph itself
