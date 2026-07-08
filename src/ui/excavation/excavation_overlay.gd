extends CanvasLayer

@onready var main_panel: Control = $Control/DeskPanel
@onready var label_instruction: Label = $Control/DeskPanel/ToolsContainer/NotePanel/InstructionLabel
@onready var btn_chisel = $Control/DeskPanel/ToolsContainer/BtnChisel
@onready var btn_brush = $Control/DeskPanel/ToolsContainer/BtnBrush
@onready var btn_spray = $Control/DeskPanel/ToolsContainer/BtnSpray
@onready var btn_kamus = $Control/DeskPanel/ToolsContainer/BtnKamus
@onready var btn_complete = $Control/DeskPanel/BtnComplete
@onready var relic_view = $Control/DeskPanel/TrayPanel/RelicView
@onready var chisel_particles = $Control/DeskPanel/TrayPanel/RelicView/ChiselParticles
@onready var brush_particles = $Control/DeskPanel/TrayPanel/RelicView/BrushParticles
@onready var spray_particles = $Control/DeskPanel/TrayPanel/RelicView/SprayParticles
@onready var sparkle_particles = $Control/DeskPanel/TrayPanel/RelicView/SparkleParticles

# Kamus (Dictionary) overlay
@onready var kamus_overlay = $Control/KamusOverlay
@onready var kamus_image = $Control/KamusOverlay/KamusPanel/KamusImage
@onready var btn_close_kamus = $Control/KamusOverlay/KamusPanel/BtnCloseKamus
var tex_kamus: Texture2D = null

# Game State
enum Tool { CHISEL, BRUSH, SPRAY }
var active_tool: Tool = Tool.CHISEL

var target_mound = null
var relic_id: String = ""
var symbol_char: String = "ha"
var relic_name: String = ""

# Preloaded assets fallback
var fallback_prasasti = preload("res://assets/textures/relics/Prasasti.png")
var fallback_tulisan = preload("res://assets/textures/relics/Tulisan.png")
var fallback_tanah = preload("res://assets/textures/relics/Tanah.png")
var fallback_batu1 = preload("res://assets/textures/relics/Batu 1.png")
var fallback_batu2 = preload("res://assets/textures/relics/Batu 2.png")
var fallback_batu3 = preload("res://assets/textures/relics/Batu 3.png")

# Active textures for the current relic
var tex_prasasti: Texture2D
var tex_tulisan: Texture2D
var tex_tanah: Texture2D

# Dynamic Image Data
var brush_image: Image
var brush_texture: ImageTexture
var total_dirt_pixels: int = 0
var erased_dirt_pixels: int = 0

var spray_image: Image
var spray_texture: ImageTexture
var tulisan_image: Image
var total_gold_pixels: int = 0
var revealed_gold_pixels: int = 0

# Rock configurations
class Rock:
	var texture: Texture2D
	var center: Vector2
	var clicks_left: int
	var max_clicks: int
	var full_canvas: bool
	var destroyed: bool = false
	
	func _init(tex: Texture2D, pos: Vector2, clicks: int, is_full: bool = true) -> void:
		texture = tex
		center = pos
		clicks_left = clicks
		max_clicks = clicks
		full_canvas = is_full

var rocks = []
var spray_amount: float = 0.0
var completed_steps = false

func _ready() -> void:
	visible = false
	btn_complete.visible = false
	btn_complete.pressed.connect(_on_complete_pressed)
	
	btn_chisel.pressed.connect(func(): set_tool(Tool.CHISEL))
	btn_brush.pressed.connect(func(): set_tool(Tool.BRUSH))
	btn_spray.pressed.connect(func(): set_tool(Tool.SPRAY))
	
	# Kamus button & overlay setup
	btn_kamus.pressed.connect(_toggle_kamus)
	btn_close_kamus.pressed.connect(_toggle_kamus)
	kamus_overlay.visible = false
	
	# Load kamus texture
	var kamus_path = "res://assets/textures/ui/kamus.jpg"
	if ResourceLoader.exists(kamus_path):
		tex_kamus = load(kamus_path)
		if kamus_image:
			kamus_image.texture = tex_kamus
	
	Global.excavation_started.connect(start_game)

func start_game(mound) -> void:
	target_mound = mound
	relic_id = mound.relic_id
	symbol_char = mound.symbol_char
	relic_name = mound.relic_name
	
	# Get RelicData Resource from global dictionary
	var relic_data: RelicData = Global.dictionary.get(relic_id)
	
	# Reset states
	active_tool = Tool.CHISEL
	completed_steps = false
	spray_amount = 0.0
	btn_complete.visible = false
	
	# Override active textures from Resource, or use preloaded fallbacks
	if relic_data:
		tex_prasasti = relic_data.base_texture if relic_data.base_texture else fallback_prasasti
		tex_tulisan = relic_data.writing_texture if relic_data.writing_texture else fallback_tulisan
		tex_tanah = relic_data.dirt_texture if relic_data.dirt_texture else fallback_tanah
	else:
		tex_prasasti = fallback_prasasti
		tex_tulisan = fallback_tulisan
		tex_tanah = fallback_tanah
	
	# Initialize Rocks from Resource, or use defaults
	rocks.clear()
	if relic_data and not relic_data.rocks.is_empty():
		for r_data in relic_data.rocks:
			if r_data and r_data.texture:
				rocks.append(Rock.new(r_data.texture, r_data.custom_position, r_data.max_clicks, r_data.full_canvas))
	else:
		rocks = [
			Rock.new(fallback_batu1, Vector2(90, 130), 3, true),
			Rock.new(fallback_batu2, Vector2(230, 90), 3, true),
			Rock.new(fallback_batu3, Vector2(190, 190), 3, true)
		]
	
	# Initialize Brush Layer (Soil)
	var base_tanah = tex_tanah.get_image()
	brush_image = base_tanah.duplicate()
	brush_texture = ImageTexture.create_from_image(brush_image)
	
	# Count total opaque pixels in Tanah
	total_dirt_pixels = 0
	erased_dirt_pixels = 0
	for x in range(brush_image.get_width()):
		for y in range(brush_image.get_height()):
			if brush_image.get_pixel(x, y).a > 0.05:
				total_dirt_pixels += 1
				
	# Initialize Spray Layer (Golden inscription)
	tulisan_image = tex_tulisan.get_image()
	spray_image = Image.create(tulisan_image.get_width(), tulisan_image.get_height(), false, Image.FORMAT_RGBA8)
	spray_texture = ImageTexture.create_from_image(spray_image)
	
	# Count total gold pixels to reveal
	total_gold_pixels = 0
	revealed_gold_pixels = 0
	for x in range(tulisan_image.get_width()):
		for y in range(tulisan_image.get_height()):
			if tulisan_image.get_pixel(x, y).a > 0.05:
				total_gold_pixels += 1
				
	# Ensure safe division
	if total_dirt_pixels == 0: total_dirt_pixels = 1
	if total_gold_pixels == 0: total_gold_pixels = 1
	
	# Turn off sparkles initially
	if sparkle_particles:
		sparkle_particles.emitting = false
		
	# Smooth fade-in and bounce-scale transition
	if main_panel:
		main_panel.modulate.a = 0.0
		main_panel.scale = Vector2(0.92, 0.92)
		main_panel.pivot_offset = Vector2(640, 360) # Center of 1280x720 screen
		
	visible = true
	relic_view.queue_redraw()
	
	if main_panel:
		var tween = create_tween().set_parallel(true)
		tween.tween_property(main_panel, "modulate:a", 1.0, 0.45).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(main_panel, "scale", Vector2.ONE, 0.45).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	
	update_ui()

func set_tool(tool_type: Tool) -> void:
	active_tool = tool_type
	Global.play_sfx.emit("tool_select")
	update_ui()

func _toggle_kamus() -> void:
	if kamus_overlay.visible:
		# Close kamus with fade-out
		var tween = create_tween()
		tween.tween_property(kamus_overlay, "modulate:a", 0.0, 0.25).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
		tween.tween_callback(func():
			kamus_overlay.visible = false
			kamus_overlay.modulate.a = 1.0
		)
	else:
		# Open kamus with fade-in
		kamus_overlay.modulate.a = 0.0
		kamus_overlay.visible = true
		var tween = create_tween()
		tween.tween_property(kamus_overlay, "modulate:a", 1.0, 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		Global.play_sfx.emit("book_open")

func update_ui() -> void:
	btn_chisel.button_pressed = (active_tool == Tool.CHISEL)
	btn_brush.button_pressed = (active_tool == Tool.BRUSH)
	btn_spray.button_pressed = (active_tool == Tool.SPRAY)
	
	# All buttons are always enabled for sandbox freedom!
	btn_chisel.disabled = completed_steps
	btn_brush.disabled = completed_steps
	btn_spray.disabled = completed_steps
	
	# Set helper text based on puzzle progress
	var chisel_done = is_chisel_complete()
	var brush_done = is_brush_complete()
	
	if not chisel_done:
		label_instruction.text = "Gunakan Pahat untuk memecah bongkahan batu besar (klik 3x langsung pada batu)!"
	elif not brush_done:
		label_instruction.text = "Gunakan Kuas untuk membersihkan sisa tanah cokelat hingga bersih!"
	elif not completed_steps:
		label_instruction.text = "Gunakan Semprotan Air untuk mengilapkan aksara emas!"
	else:
		label_instruction.text = "SELESAI! Relik kuno telah bersih sempurna."
		btn_chisel.disabled = true
		btn_brush.disabled = true
		btn_spray.disabled = true
		btn_complete.visible = true

func is_chisel_complete() -> bool:
	for r in rocks:
		if not r.destroyed:
			return false
	return true

func is_brush_complete() -> bool:
	var ratio = float(erased_dirt_pixels) / float(total_dirt_pixels)
	return ratio >= 0.96 # Requires 96% completeness for high-res clean-up

func _on_complete_pressed() -> void:
	# Close kamus if open
	if kamus_overlay and kamus_overlay.visible:
		kamus_overlay.visible = false
	
	var ctrl = $Control
	if ctrl:
		var tween = create_tween()
		tween.tween_property(ctrl, "modulate:a", 0.0, 0.35).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
		tween.tween_callback(func():
			visible = false
			ctrl.modulate.a = 1.0
			Global.change_state(Global.State.OVERWORLD)
			if target_mound:
				target_mound.complete_cleaning()
		)
	else:
		visible = false
		Global.change_state(Global.State.OVERWORLD)
		if target_mound:
			target_mound.complete_cleaning()

func handle_view_input(local_pos: Vector2, is_drag: bool) -> void:
	if completed_steps: return
	
	var tex_w = brush_image.get_width()
	var tex_h = brush_image.get_height()
	var map_scale = Vector2(float(tex_w)/320.0, float(tex_h)/280.0)
	var mapped_pos = Vector2(local_pos.x * map_scale.x, local_pos.y * map_scale.y)
	
	match active_tool:
		Tool.CHISEL:
			if not is_drag: # Click only
				# Pixel-perfect hit check on transparent rock layers
				var hit_rock = null
				for r in rocks:
					if not r.destroyed:
						var r_w = r.texture.get_width()
						var r_h = r.texture.get_height()
						var r_scale = Vector2(float(r_w)/320.0, float(r_h)/280.0)
						
						if r.full_canvas:
							var rx = int(local_pos.x * r_scale.x)
							var ry = int(local_pos.y * r_scale.y)
							if rx >= 0 and rx < r_w and ry >= 0 and ry < r_h:
								var img = r.texture.get_image()
								if img.get_pixel(rx, ry).a > 0.1:
									hit_rock = r
									break
						else:
							# Cropped sprite hit check centered at r.center
							var half_size = Vector2(r_w, r_h) / (2.0 * r_scale)
							var rect = Rect2(r.center - half_size, half_size * 2.0)
							if rect.has_point(local_pos):
								var rx = int((local_pos.x - rect.position.x) * r_scale.x)
								var ry = int((local_pos.y - rect.position.y) * r_scale.y)
								if rx >= 0 and rx < r_w and ry >= 0 and ry < r_h:
									var img = r.texture.get_image()
									if img.get_pixel(rx, ry).a > 0.1:
										hit_rock = r
										break
								
				if hit_rock:
					hit_rock.clicks_left -= 1
					
					# Emitting chisel rock shards
					if chisel_particles:
						chisel_particles.position = local_pos
						chisel_particles.restart()
						
					Global.camera_shake.emit(3.0, 0.1)
					Global.play_sfx.emit("chisel_clink")
					
					if hit_rock.clicks_left <= 0:
						hit_rock.destroyed = true
						# Emitting extra chisel debris shards
						if chisel_particles:
							chisel_particles.amount = 24
							chisel_particles.restart()
							chisel_particles.amount = 12 # reset back
						Global.camera_shake.emit(6.0, 0.2)
						Global.play_sfx.emit("step_complete")
						
					relic_view.queue_redraw()
					update_ui()
					
		Tool.BRUSH:
			if is_drag or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
				var changed = erase_brush_circle(mapped_pos, 25.0 * map_scale.x)
				if changed:
					if brush_particles and randf() < 0.25:
						brush_particles.position = local_pos
						brush_particles.restart()
					if randf() < 0.08:
						Global.play_sfx.emit("brush_sweep")
					relic_view.queue_redraw()
					update_ui()
						
		Tool.SPRAY:
			if is_drag or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
				var changed = reveal_spray_circle(mapped_pos, 20.0 * map_scale.x)
				if changed:
					if spray_particles:
						spray_particles.position = local_pos
						spray_particles.restart()
					if randf() < 0.12:
						Global.play_sfx.emit("spray_pssh")
					relic_view.queue_redraw()
					
					var ratio = float(revealed_gold_pixels) / float(total_gold_pixels)
					spray_amount = ratio
					if ratio >= 0.96:
						completed_steps = true
						Global.play_sfx.emit("chime_success")
						if sparkle_particles:
							sparkle_particles.emitting = true
					update_ui()

func erase_brush_circle(pos: Vector2, radius: float) -> bool:
	if not brush_image: return false
	
	var start_x = max(0, int(pos.x - radius))
	var end_x = min(brush_image.get_width(), int(pos.x + radius))
	var start_y = max(0, int(pos.y - radius))
	var end_y = min(brush_image.get_height(), int(pos.y + radius))
	
	var changed = false
	var inner_radius = radius * 0.5
	var outer_diff = radius - inner_radius
	
	for x in range(start_x, end_x):
		for y in range(start_y, end_y):
			var dx = x - pos.x
			var dy = y - pos.y
			var dist = sqrt(dx*dx + dy*dy)
			if dist <= radius:
				var col = brush_image.get_pixel(x, y)
				if col.a > 0.01:
					var target_alpha = 0.0
					if dist > inner_radius:
						var factor = (dist - inner_radius) / outer_diff
						target_alpha = col.a * factor
						
					if col.a > target_alpha:
						brush_image.set_pixel(x, y, Color(col.r, col.g, col.b, target_alpha))
						if col.a > 0.05 and target_alpha <= 0.05:
							erased_dirt_pixels += 1
						changed = true
					
	if changed:
		brush_texture.update(brush_image)
	return changed

func reveal_spray_circle(pos: Vector2, radius: float) -> bool:
	if not spray_image or not tulisan_image: return false
	
	var start_x = max(0, int(pos.x - radius))
	var end_x = min(spray_image.get_width(), int(pos.x + radius))
	var start_y = max(0, int(pos.y - radius))
	var end_y = min(spray_image.get_height(), int(pos.y + radius))
	
	var changed = false
	var inner_radius = radius * 0.5
	var outer_diff = radius - inner_radius
	
	for x in range(start_x, end_x):
		for y in range(start_y, end_y):
			var dx = x - pos.x
			var dy = y - pos.y
			var dist = sqrt(dx*dx + dy*dy)
			if dist <= radius:
				var gold_col = tulisan_image.get_pixel(x, y)
				if gold_col.a > 0.01:
					var target_alpha = gold_col.a
					if dist > inner_radius:
						var factor = 1.0 - (dist - inner_radius) / outer_diff
						target_alpha = gold_col.a * factor
						
					var current_col = spray_image.get_pixel(x, y)
					if current_col.a < target_alpha:
						spray_image.set_pixel(x, y, Color(gold_col.r, gold_col.g, gold_col.b, target_alpha))
						if current_col.a <= 0.05 and target_alpha > 0.05:
							revealed_gold_pixels += 1
						changed = true
						
	if changed:
		spray_texture.update(spray_image)
	return changed
