extends Control

func _ready() -> void:
	queue_redraw()

func _draw() -> void:
	var ink = Global.COLOR_INK
	var white = Global.COLOR_WHITE
	var grass = Global.COLOR_BG_GRASS
	var stone = Global.COLOR_STONE
	var gold = Global.COLOR_GOLD
	
	# Polaroid frame dimensions (centered at 0,0 inside control parent)
	var frame_rect = Rect2(-110, -130, 220, 260)
	
	# 1. Main White Polaroid Board Outline
	draw_rect(frame_rect, ink)
	draw_rect(Rect2(frame_rect.position + Vector2.ONE*3, frame_rect.size - Vector2.ONE*6), white)
	
	# Shadow under-photo line
	draw_line(Vector2(-96, 72), Vector2(96, 72), ink.lightened(0.3), 1.0)
	
	# 2. Main Picture Area
	var pic_rect = Rect2(-96, -116, 192, 180)
	draw_rect(pic_rect, ink)
	# Grass fill
	draw_rect(Rect2(pic_rect.position + Vector2.ONE*2, pic_rect.size - Vector2.ONE*4), grass)
	
	# Restored Shrine Drawing inside the photo
	var center = pic_rect.get_center()
	
	# Draw flowing water stream (restored!)
	var water_color = Color("#4A90E2")
	var water_points = PackedVector2Array([
		Vector2(center.x - 24, pic_rect.position.y + 2),
		Vector2(center.x + 24, pic_rect.position.y + 2),
		Vector2(center.x + 16, pic_rect.end.y - 2),
		Vector2(center.x - 16, pic_rect.end.y - 2),
		Vector2(center.x - 24, pic_rect.position.y + 2)
	])
	draw_colored_polygon(water_points, water_color)
	draw_polyline(water_points, ink, 2.0)
	
	# Draw stone path blocks
	draw_circle(center + Vector2(-60, 40), 18.0, ink)
	draw_circle(center + Vector2(-60, 40), 15.0, stone)
	draw_circle(center + Vector2(60, 40), 18.0, ink)
	draw_circle(center + Vector2(60, 40), 15.0, stone)
	
	# Draw restored pillars
	var columns = [
		Vector2(center.x - 50, center.y - 40),
		Vector2(center.x + 50, center.y - 40)
	]
	for col in columns:
		# Draw outline
		draw_rect(Rect2(col.x - 12, col.y - 40, 24, 80), ink)
		draw_rect(Rect2(col.x - 10, col.y - 38, 20, 76), stone)
		# Pillar ridges
		draw_line(col + Vector2(-4, -30), col + Vector2(-4, 30), stone.darkened(0.2), 2.0)
		draw_line(col + Vector2(4, -30), col + Vector2(4, 30), stone.darkened(0.2), 2.0)
		
		# Lit torches on pillars
		var torch_pos = col + Vector2(0, -44)
		draw_line(torch_pos, torch_pos + Vector2(0, 10), ink, 3.5)
		draw_circle(torch_pos + Vector2(0, -6), 6.0, ink)
		draw_circle(torch_pos + Vector2(0, -6), 4.0, Color("#FF4500")) # orange fire
		draw_circle(torch_pos + Vector2(0, -4), 2.0, gold) # yellow center
		
	# Draw a cute little player character standing in front!
	var ply_pos = center + Vector2(0, 50)
	draw_circle(ply_pos, 10.0, ink)
	draw_circle(ply_pos, 8.5, white)
	# eyes
	draw_circle(ply_pos + Vector2(-3, -2), 1.5, ink)
	draw_circle(ply_pos + Vector2(3, -2), 1.5, ink)
	# cheeks
	draw_circle(ply_pos + Vector2(-6, 1), 1.8, Global.COLOR_CHEEKS)
	draw_circle(ply_pos + Vector2(6, 1), 1.8, Global.COLOR_CHEEKS)
	# smile
	draw_arc(ply_pos + Vector2(0, 0), 1.5, 0, PI, 6, ink, 1.0, true)
	
	# 3. Handwritten caption below the photo: "RESTORED!" in stylized pixel font strokes
	var txt_y = 104.0
	# Draw letter 'R'
	draw_line(Vector2(-45, txt_y), Vector2(-45, txt_y + 12), ink, 2.0)
	draw_line(Vector2(-45, txt_y), Vector2(-38, txt_y), ink, 2.0)
	draw_line(Vector2(-38, txt_y), Vector2(-38, txt_y + 6), ink, 2.0)
	draw_line(Vector2(-45, txt_y + 6), Vector2(-38, txt_y + 6), ink, 2.0)
	draw_line(Vector2(-43, txt_y + 6), Vector2(-38, txt_y + 12), ink, 2.0)
	
	# Draw letter 'E'
	draw_line(Vector2(-32, txt_y), Vector2(-32, txt_y + 12), ink, 2.0)
	draw_line(Vector2(-32, txt_y), Vector2(-26, txt_y), ink, 2.0)
	draw_line(Vector2(-32, txt_y + 6), Vector2(-28, txt_y + 6), ink, 2.0)
	draw_line(Vector2(-32, txt_y + 12), Vector2(-26, txt_y + 12), ink, 2.0)
	
	# Draw letter 'S'
	draw_line(Vector2(-20, txt_y), Vector2(-14, txt_y), ink, 2.0)
	draw_line(Vector2(-20, txt_y), Vector2(-20, txt_y + 6), ink, 2.0)
	draw_line(Vector2(-20, txt_y + 6), Vector2(-14, txt_y + 6), ink, 2.0)
	draw_line(Vector2(-14, txt_y + 6), Vector2(-14, txt_y + 12), ink, 2.0)
	draw_line(Vector2(-20, txt_y + 12), Vector2(-14, txt_y + 12), ink, 2.0)
	
	# Draw letter 'T'
	draw_line(Vector2(-8, txt_y), Vector2(0, txt_y), ink, 2.0)
	draw_line(Vector2(-4, txt_y), Vector2(-4, txt_y + 12), ink, 2.0)
	
	# Draw letter 'O'
	draw_line(Vector2(6, txt_y), Vector2(14, txt_y), ink, 2.0)
	draw_line(Vector2(6, txt_y + 12), Vector2(14, txt_y + 12), ink, 2.0)
	draw_line(Vector2(6, txt_y), Vector2(6, txt_y + 12), ink, 2.0)
	draw_line(Vector2(14, txt_y), Vector2(14, txt_y + 12), ink, 2.0)
	
	# Draw letter 'R'
	draw_line(Vector2(20, txt_y), Vector2(20, txt_y + 12), ink, 2.0)
	draw_line(Vector2(20, txt_y), Vector2(27, txt_y), ink, 2.0)
	draw_line(Vector2(27, txt_y), Vector2(27, txt_y + 6), ink, 2.0)
	draw_line(Vector2(20, txt_y + 6), Vector2(27, txt_y + 6), ink, 2.0)
	draw_line(Vector2(22, txt_y + 6), Vector2(27, txt_y + 12), ink, 2.0)
	
	# Draw letter 'E'
	draw_line(Vector2(32, txt_y), Vector2(32, txt_y + 12), ink, 2.0)
	draw_line(Vector2(32, txt_y), Vector2(38, txt_y), ink, 2.0)
	draw_line(Vector2(32, txt_y + 6), Vector2(36, txt_y + 6), ink, 2.0)
	draw_line(Vector2(32, txt_y + 12), Vector2(38, txt_y + 12), ink, 2.0)
	
	# Draw letter 'D'
	draw_line(Vector2(44, txt_y), Vector2(44, txt_y + 12), ink, 2.0)
	draw_line(Vector2(44, txt_y), Vector2(50, txt_y), ink, 2.0)
	draw_line(Vector2(44, txt_y + 12), Vector2(50, txt_y + 12), ink, 2.0)
	draw_line(Vector2(51, txt_y + 2), Vector2(51, txt_y + 10), ink, 2.0)
	
	# Draw exclamation '!'
	draw_line(Vector2(57, txt_y), Vector2(57, txt_y + 8), ink, 2.0)
	draw_circle(Vector2(57.5, txt_y + 11), 1.0, ink)
