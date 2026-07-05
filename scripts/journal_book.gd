extends Control

func _ready() -> void:
	queue_redraw()

func _draw() -> void:
	var ink = Global.COLOR_INK
	var page = Color("#FFF8E7") # Cozy cream paper
	var cover = Color("#5C3A21") # Leather brown cover
	var gold = Global.COLOR_GOLD
	
	var r = Rect2(0, 0, size.x, size.y)
	
	# 1. Draw Leather Cover (slightly larger than pages)
	draw_rect(r, ink)
	draw_rect(Rect2(r.position + Vector2.ONE*3, r.size - Vector2.ONE*6), cover)
	
	# Cover stitch details (gold corner ornaments)
	var corner_size = 12.0
	draw_rect(Rect2(6, 6, corner_size, corner_size), gold)
	draw_rect(Rect2(size.x - 6 - corner_size, 6, corner_size, corner_size), gold)
	draw_rect(Rect2(6, size.y - 6 - corner_size, corner_size, corner_size), gold)
	draw_rect(Rect2(size.x - 6 - corner_size, size.y - 6 - corner_size, corner_size, corner_size), gold)
	
	# 2. Draw Left Page
	var left_rect = Rect2(16, 16, (size.x - 48) / 2, size.y - 32)
	draw_rect(left_rect, ink)
	draw_rect(Rect2(left_rect.position + Vector2.ONE*2, left_rect.size - Vector2.ONE*4), page)
	
	# Left page margins/lines
	for i in range(1, 10):
		var y_pos = left_rect.position.y + i * 22
		draw_line(Vector2(left_rect.position.x + 10, y_pos), Vector2(left_rect.end.x - 10, y_pos), page.darkened(0.1), 1.0)
		
	# 3. Draw Right Page
	var right_rect = Rect2(left_rect.end.x + 16, 16, left_rect.size.x, left_rect.size.y)
	draw_rect(right_rect, ink)
	draw_rect(Rect2(right_rect.position + Vector2.ONE*2, right_rect.size - Vector2.ONE*4), page)
	
	# Right page margin/lines
	for i in range(1, 10):
		var y_pos = right_rect.position.y + i * 22
		draw_line(Vector2(right_rect.position.x + 10, y_pos), Vector2(right_rect.end.x - 10, y_pos), page.darkened(0.1), 1.0)
		
	# 4. Book Spine / Ribbon Bookmark (drawn down the middle spine)
	var spine_center = size.x / 2
	# Red bookmark ribbon dangling down
	var ribbon_color = Color("#B22222")
	var ribbon_points = PackedVector2Array([
		Vector2(spine_center - 4, 16),
		Vector2(spine_center + 4, 16),
		Vector2(spine_center + 4, size.y - 8),
		Vector2(spine_center, size.y - 14),
		Vector2(spine_center - 4, size.y - 8),
		Vector2(spine_center - 4, 16)
	])
	draw_colored_polygon(ribbon_points, ribbon_color)
	draw_polyline(ribbon_points, ink, 1.5)
