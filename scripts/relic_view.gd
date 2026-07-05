extends Control

@onready var overlay = get_parent().get_parent()

func _ready() -> void:
	# Enable mouse input tracking
	mouse_filter = Control.MOUSE_FILTER_STOP
	gui_input.connect(_on_gui_input)

func _on_gui_input(event: InputEvent) -> void:
	var local_pos = get_local_mouse_position()
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			overlay.handle_view_input(local_pos, false)
	elif event is InputEventMouseMotion:
		overlay.handle_view_input(local_pos, true)

func _draw() -> void:
	var ink = Global.COLOR_INK
	var dirt = Global.COLOR_DIRT
	var stone = Global.COLOR_STONE
	var gold = Global.COLOR_GOLD
	var highlight = Global.COLOR_WHITE
	
	# Dimensions of the central relic stone (drawn in center of 320x280 area)
	# control size will be 320x280
	var relic_rect = Rect2(60, 40, 200, 200)
	
	# 1. Dark dirt background behind relic
	draw_rect(Rect2(0, 0, size.x, size.y), dirt.darkened(0.4))
	
	# 2. Relic Stone Block
	draw_rect(relic_rect, ink)
	draw_rect(Rect2(relic_rect.position + Vector2.ONE*2, relic_rect.size - Vector2.ONE*4), stone)
	
	# Cracks and texture in the background stone
	draw_line(Vector2(80, 60), Vector2(100, 80), ink.lightened(0.2), 2.0)
	draw_line(Vector2(240, 200), Vector2(220, 220), ink.lightened(0.2), 2.0)
	
	# 3. Gold Hanacaraka Symbol (glow intensity depends on spray_amount)
	var sym = overlay.symbol_char
	var glyph_points = PackedVector2Array()
	var center = relic_rect.get_center()
	
	# Center is around (160, 140)
	# Translate and scale the glyph to fit the 200x200 panel
	var scale_factor = 4.5
	
	match sym:
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
			var gold_color = Color(gold.r, gold.g, gold.b, overlay.spray_amount)
			draw_line(center + Vector2(-36, -18), center + Vector2(36, -18), gold_color, 8.0)
			draw_line(center + Vector2(-27, 0), center + Vector2(27, 0), gold_color, 8.0)
			draw_line(center + Vector2(-36, 18), center + Vector2(36, 18), gold_color, 8.0)
		"ka":
			var gold_color = Color(gold.r, gold.g, gold.b, overlay.spray_amount)
			draw_arc(center, 30.0, 0.0, 2*PI, 18, gold_color, 8.0)
			draw_line(center + Vector2(-36, 0), center + Vector2(36, 0), gold_color, 8.0)
			draw_line(center + Vector2(0, -36), center + Vector2(0, 36), gold_color, 8.0)
	
	if glyph_points.size() > 0:
		# Scale and shift glyph points to central position
		var shifted_points = PackedVector2Array()
		for pt in glyph_points:
			shifted_points.append(center + pt * scale_factor)
			
		var outline_color = Color(ink.r, ink.g, ink.b, overlay.spray_amount)
		var gold_color = Color(gold.r, gold.g, gold.b, overlay.spray_amount)
		draw_polyline(shifted_points, outline_color, 12.0, true)
		draw_polyline(shifted_points, gold_color, 7.0, true)
		
	# 4. Grime/Dirty film overlay (fades as player sprays)
	if overlay.spray_amount < 1.0:
		var dirt_dark = dirt.darkened(0.2)
		var grime_color = Color(dirt_dark.r, dirt_dark.g, dirt_dark.b, 1.0 - overlay.spray_amount)
		draw_rect(Rect2(relic_rect.position + Vector2.ONE*4, relic_rect.size - Vector2.ONE*8), grime_color)
		
	# 5. Brush Dust Nodes (Step 2)
	for node in overlay.brush_nodes:
		if node.alpha > 0.0:
			var dirt_light = dirt.lightened(0.15)
			var d_color = Color(dirt_light.r, dirt_light.g, dirt_light.b, node.alpha)
			draw_circle(node.pos, node.size, d_color)
			# Draw minor outlines for dust
			draw_circle(node.pos, node.size - 2.0, d_color.darkened(0.1))
			
	# 6. Chisel chunks (Step 1)
	for chunk_pos in overlay.chisel_nodes:
		# Draw a small rocky polygon
		var points = PackedVector2Array([
			chunk_pos + Vector2(-15, -10),
			chunk_pos + Vector2(5, -18),
			chunk_pos + Vector2(18, -4),
			chunk_pos + Vector2(10, 16),
			chunk_pos + Vector2(-12, 12),
			chunk_pos + Vector2(-15, -10)
		])
		draw_colored_polygon(points, dirt.darkened(0.1))
		draw_polyline(points, ink, 2.0)
		
		# Draw pebble highlight
		var highlight_color = Color(highlight.r, highlight.g, highlight.b, 0.2)
		draw_line(chunk_pos + Vector2(-10, -5), chunk_pos + Vector2(0, -10), highlight_color, 2.0)

