extends Node2D

func _ready() -> void:
	queue_redraw()

func _process(_delta: float) -> void:
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
	draw_circle(Vector2(-10, 4), 9.0, ink)
	# Fill
	draw_circle(Vector2(-10, 4), 7.0, soil)
	# Buckle/Strap
	draw_rect(Rect2(-12, 1, 4, 6), ink)
	draw_rect(Rect2(-11, 2, 2, 4), gold)
	
	# 2. Cute Ears
	# Left Ear Outline
	draw_circle(Vector2(-12, -14), 8.0, ink)
	# Right Ear Outline
	draw_circle(Vector2(12, -14), 8.0, ink)
	# Left Ear Fill
	draw_circle(Vector2(-12, -14), 6.0, body_color)
	# Right Ear Fill
	draw_circle(Vector2(12, -14), 6.0, body_color)
	# Ear Inners (cheeky yellow highlights)
	draw_circle(Vector2(-12, -14), 3.0, cheek_color)
	draw_circle(Vector2(12, -14), 3.0, cheek_color)
	
	# 3. Main Body
	# Body Outline
	draw_circle(Vector2.ZERO, 20.0, ink)
	# Body Fill
	draw_circle(Vector2.ZERO, 18.0, body_color)
	
	# 4. Eyes (simple black beads, cozy and cute)
	draw_circle(Vector2(-7, -4), 2.5, ink)
	draw_circle(Vector2(7, -4), 2.5, ink)
	
	# 5. Rosy Cheeks
	draw_circle(Vector2(-12, 1), 3.5, cheek_color)
	draw_circle(Vector2(12, 1), 3.5, cheek_color)
	
	# 6. Cute Smile (drawn with a small thick line)
	# A tiny 'w' or simple line smile
	draw_arc(Vector2(0, -1), 2.5, 0, PI, 8, ink, 2.0, true)
	
	# 7. Tiny feet (drawn at the bottom)
	# Left foot
	draw_circle(Vector2(-10, 16), 5.0, ink)
	draw_circle(Vector2(-10, 16), 3.0, body_color)
	# Right foot
	draw_circle(Vector2(10, 16), 5.0, ink)
	draw_circle(Vector2(10, 16), 3.0, body_color)
