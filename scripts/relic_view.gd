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
			# Handle click input
			overlay.handle_view_input(local_pos, false)
	elif event is InputEventMouseMotion:
		# Handle dragging/swiping input
		overlay.handle_view_input(local_pos, true)

func _draw() -> void:
	# 1. Draw a clean dark backing fill
	draw_rect(Rect2(0, 0, size.x, size.y), Color("#0f172a")) # Dark slate blue
	
	# 2. Draw Layer 1: Base Stone Tablet (Prasasti)
	if overlay.tex_prasasti:
		draw_texture_rect(overlay.tex_prasasti, Rect2(0, 0, 320, 280), false)
		
	# 3. Draw Layer 2: Gold Inscription (Tulisan - revealed gradually via spray_texture)
	if overlay.spray_texture:
		draw_texture_rect(overlay.spray_texture, Rect2(0, 0, 320, 280), false)
		
	# 4. Draw Layer 3: Soft Dirt Layer (Tanah - erased gradually via brush_texture)
	if overlay.brush_texture:
		draw_texture_rect(overlay.brush_texture, Rect2(0, 0, 320, 280), false)
		
	# 5. Draw Layer 4: Hard Rocks (Batu 1, 2, 3 - each HP modulated by click health)
	for rock in overlay.rocks:
		if not rock.destroyed:
			var opacity = float(rock.clicks_left) / float(rock.max_clicks)
			var modulate_col = Color(1, 1, 1, opacity)
			var tex_size = rock.texture.get_size()
			
			if tex_size.x > 200:
				# Full size canvas layer
				draw_texture_rect(rock.texture, Rect2(0, 0, 320, 280), false, modulate_col)
			else:
				# Cropped sprite centered at rock position
				draw_texture(rock.texture, rock.center - tex_size / 2, modulate_col)
