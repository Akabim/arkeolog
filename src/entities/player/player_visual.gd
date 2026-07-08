extends Node2D

func _ready() -> void:
	queue_redraw()

func _draw() -> void:
	# Colors from Global palette
	var ink = Global.COLOR_INK
	var body_color = Global.COLOR_WHITE
	var cheek_color = Global.COLOR_CHEEKS
	var gold = Global.COLOR_GOLD
	var soil = Global.COLOR_DIRT
	
	# 1. Archaeologist Backpack (drawn behind player body)
	# Outline
	draw_circle(Vector2(-17, 8), 15.0, ink)
	# Fill
	draw_circle(Vector2(-17, 8), 12.0, soil)
	# Buckle/Strap
	draw_rect(Rect2(-20, 3, 6, 10), ink)
	draw_rect(Rect2(-18.5, 5, 3, 6), gold)
	
	# 2. Cute Ears
	# Left Ear Outline
	draw_circle(Vector2(-20, -22), 13.0, ink)
	# Right Ear Outline
	draw_circle(Vector2(20, -22), 13.0, ink)
	# Left Ear Fill
	draw_circle(Vector2(-20, -22), 10.0, body_color)
	# Right Ear Fill
	draw_circle(Vector2(20, -22), 10.0, body_color)
	# Ear Inners (cheeky yellow highlights)
	draw_circle(Vector2(-20, -22), 5.0, cheek_color)
	draw_circle(Vector2(20, -22), 5.0, cheek_color)
	
	# 3. Main Body
	# Body Outline (centered at ZERO, scaled for 80x80 grid)
	draw_circle(Vector2.ZERO, 33.0, ink)
	# Body Fill
	draw_circle(Vector2.ZERO, 30.0, body_color)
	
	# 4. Eyes (simple black beads, cozy and cute)
	draw_circle(Vector2(-11, -7), 4.0, ink)
	draw_circle(Vector2(11, -7), 4.0, ink)
	
	# 5. Rosy Cheeks
	draw_circle(Vector2(-20, 1), 6.0, cheek_color)
	draw_circle(Vector2(20, 1), 6.0, cheek_color)
	
	# 6. Cute Smile (drawn with a small thick line)
	draw_arc(Vector2(0, -2), 4.5, 0, PI, 8, ink, 3.0, true)
	
	# 7. Tiny feet (drawn at the bottom)
	# Left foot
	draw_circle(Vector2(-16, 26), 8.0, ink)
	draw_circle(Vector2(-16, 26), 5.0, body_color)
	# Right foot
	draw_circle(Vector2(16, 26), 8.0, ink)
	draw_circle(Vector2(16, 26), 5.0, body_color)
