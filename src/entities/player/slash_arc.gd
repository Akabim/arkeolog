extends Node2D

func _ready() -> void:
	queue_redraw()

func _draw() -> void:
	var num_segments = 24
	var start_angle = -1.9
	var end_angle = 1.9
	
	# Layer 1: Outer Dark Shadow Arc (Dark Purple/Black)
	draw_arc_poly(start_angle, end_angle, num_segments, 25.0, 75.0, Color(0.04, 0.01, 0.08))
	
	# Layer 2: Glowing Violet-Magenta Energy Arc
	draw_arc_poly(start_angle, end_angle, num_segments, 35.0, 62.0, Color(0.65, 0.05, 0.85))
	
	# Layer 3: Sharp Lilac/White Cutting Edge Highlight
	draw_arc_poly(start_angle, end_angle, num_segments, 46.0, 52.0, Color(0.92, 0.82, 1.0))

# Helper function to draw an arc polygon with custom dimensions and base color
func draw_arc_poly(start_angle: float, end_angle: float, num_segments: int, inner_r: float, outer_r: float, base_color: Color) -> void:
	var points = PackedVector2Array()
	var colors = PackedColorArray()
	
	# Append outer arc points (from start to end)
	for i in range(num_segments + 1):
		var t = float(i) / num_segments
		var angle = lerp(start_angle, end_angle, t)
		var p_outer = Vector2(cos(angle), sin(angle)) * outer_r
		points.append(p_outer)
		
		# Fade opacity at the start and end of the sweep (sine curve)
		var alpha = sin(t * PI) * 0.8
		colors.append(Color(base_color.r, base_color.g, base_color.b, alpha))
		
	# Append inner arc points (from end to start)
	for i in range(num_segments, -1, -1):
		var t = float(i) / num_segments
		var angle = lerp(start_angle, end_angle, t)
		var p_inner = Vector2(cos(angle), sin(angle)) * inner_r
		points.append(p_inner)
		
		var alpha = sin(t * PI) * 0.8
		colors.append(Color(base_color.r, base_color.g, base_color.b, alpha))
		
	draw_polygon(points, colors)
