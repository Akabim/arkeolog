extends Control

@onready var overlay = owner
var hovered_rock = null

func _ready() -> void:
	# Enable mouse input tracking
	mouse_filter = Control.MOUSE_FILTER_STOP
	gui_input.connect(_on_gui_input)
	mouse_exited.connect(_on_mouse_exited)

func _on_mouse_exited() -> void:
	if hovered_rock != null:
		hovered_rock = null
		queue_redraw()

func _on_gui_input(event: InputEvent) -> void:
	var local_pos: Vector2 = get_local_mouse_position()
	
	if overlay and overlay.get("active_tool") != null and overlay.active_tool == overlay.Tool.CHISEL:
		var new_hover = overlay.get_rock_at_pos(local_pos) if overlay.has_method("get_rock_at_pos") else null
		if new_hover != hovered_rock:
			hovered_rock = new_hover
			queue_redraw()
	elif hovered_rock != null:
		hovered_rock = null
		queue_redraw()
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			# Handle click input
			overlay.handle_view_input(local_pos, false)
	elif event is InputEventMouseMotion:
		# Handle dragging/swiping input
		overlay.handle_view_input(local_pos, true)

func _draw() -> void:
	# All layers use Rect2(0, 0, size.x, size.y) — same full-canvas from Clip Studio
	var canvas := Rect2(0, 0, size.x, size.y)
	
	# 2. Draw Layer 1: Base Stone Tablet (Prasasti)
	if overlay.tex_prasasti:
		draw_texture_rect(overlay.tex_prasasti, canvas, false)
		
	# 3. Draw Layer 2: Gold Inscription (Tulisan - revealed gradually via spray_texture)
	if overlay.spray_texture:
		draw_texture_rect(overlay.spray_texture, canvas, false)
		
	# 4. Draw Layer 3: Soft Dirt Layer (Tanah - erased gradually via brush_texture)
	if overlay.brush_texture:
		draw_texture_rect(overlay.brush_texture, canvas, false)
		
	# 5. Draw Layer 4: Hard Rocks (Batu 1, 2, 3 - full-canvas or positioned sprites, HP-modulated)
	for rock in overlay.rocks:
		if not rock.destroyed:
			var opacity: float = float(rock.clicks_left) / float(rock.max_clicks)
			var is_hovered: bool = (overlay.active_tool == overlay.Tool.CHISEL and rock == hovered_rock)
			var modulate_col: Color = Color(0.55, 0.55, 0.55, opacity) if is_hovered else Color(1.0, 1.0, 1.0, opacity)
			if rock.full_canvas:
				draw_texture_rect(rock.texture, canvas, false, modulate_col)
			else:
				var tex_size: Vector2 = rock.texture.get_size()
				var mapped_center := Vector2(rock.center.x * (size.x / 320.0), rock.center.y * (size.y / 280.0))
				draw_texture(rock.texture, mapped_center - tex_size / 2.0, modulate_col)
