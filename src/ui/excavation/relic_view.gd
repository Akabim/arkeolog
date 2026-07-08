extends Control

@onready var overlay = owner

func _ready() -> void:
	# Enable mouse input tracking
	mouse_filter = Control.MOUSE_FILTER_STOP
	gui_input.connect(_on_gui_input)

func _on_gui_input(event: InputEvent) -> void:
	var local_pos = get_local_mouse_position()
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			# Handle click input
			overlay.handle_view_input(local_pos, false)
	elif event is InputEventMouseMotion:
		# Handle dragging/swiping input
		overlay.handle_view_input(local_pos, true)

func _draw() -> void:
	# 1. Draw a clean dark backing fill
	draw_rect(Rect2(0, 0, size.x, size.y), Color("#0f172a")) # Dark slate blue
	# All layers use Rect2(0, 0, size.x, size.y) — same full-canvas from Clip Studio
	var canvas = Rect2(0, 0, size.x, size.y)
	
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
			var opacity = float(rock.clicks_left) / float(rock.max_clicks)
			var modulate_col = Color(1, 1, 1, opacity)
			if rock.full_canvas:
				draw_texture_rect(rock.texture, canvas, false, modulate_col)
			else:
				var tex_size = rock.texture.get_size()
				var mapped_center = Vector2(rock.center.x * (size.x/320.0), rock.center.y * (size.y/280.0))
				draw_texture(rock.texture, mapped_center - tex_size / 2, modulate_col)
