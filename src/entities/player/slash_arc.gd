extends Node2D

func _ready() -> void:
	queue_redraw()

func _draw() -> void:
	var points = PackedVector2Array()
	var colors = PackedColorArray()
	
	var num_segments = 24
	var inner_r = 30.0
	var outer_r = 60.0
	
	# Sweep from -110 degrees to +110 degrees (broad front-facing sweep)
	var start_angle = -1.9
	var end_angle = 1.9
	
	for i in range(num_segments + 1):
		var t = float(i) / num_segments
		var angle = lerp(start_angle, end_angle, t)
		
		# Outer point
		var p_outer = Vector2(cos(angle), sin(angle)) * outer_r
		points.append(p_outer)
		
		# Opacity: bright in the middle of the sweep, fades out at start/end
		var alpha = sin(t * PI) * 0.75
		colors.append(Color(1.0, 1.0, 1.0, alpha))
		
	for i in range(num_segments, -1, -1):
		var t = float(i) / num_segments
		var angle = lerp(start_angle, end_angle, t)
		
		# Inner point
		var p_inner = Vector2(cos(angle), sin(angle)) * inner_r
		points.append(p_inner)
		
		var alpha = sin(t * PI) * 0.75
		colors.append(Color(1.0, 1.0, 1.0, alpha))
		
	draw_polygon(points, colors)
