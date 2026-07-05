extends Node2D

@export var is_lit: bool = false
@onready var visual: Node2D = $Visual

func _ready() -> void:
	queue_redraw()

func light_up() -> void:
	if not is_lit:
		is_lit = true
		queue_redraw()
		# Spawn small flame particles
		Global.play_sfx.emit("torch_light")

func _draw() -> void:
	var ink = Global.COLOR_INK
	var wood = Global.COLOR_DIRT.lightened(0.1)
	var flame_inner = Global.COLOR_CHEEKS
	var flame_outer = Color("#FF4500") # Orangy Red
	
	# Torch Handle Outline
	draw_line(Vector2(0, 0), Vector2(0, 16), ink, 4.0)
	# Torch Handle
	draw_line(Vector2(0, 0), Vector2(0, 16), wood, 2.0)
	
	# Sconce metal holder
	draw_rect(Rect2(-4, -2, 8, 4), ink)
	
	if is_lit:
		# Draw animating flame (using random offsets to flicker)
		var flicker_x = randf_range(-1.5, 1.5)
		var flicker_y = randf_range(-1.0, 1.0)
		
		# Outer Flame
		draw_circle(Vector2(flicker_x, -10 + flicker_y), 7.0, ink)
		draw_circle(Vector2(flicker_x, -10 + flicker_y), 5.0, flame_outer)
		
		# Inner Flame
		draw_circle(Vector2(flicker_x * 0.5, -8 + flicker_y * 0.5), 4.0, ink)
		draw_circle(Vector2(flicker_x * 0.5, -8 + flicker_y * 0.5), 2.5, flame_inner)

func _process(_delta: float) -> void:
	if is_lit:
		# Redraw to animate flame flicker
		queue_redraw()
